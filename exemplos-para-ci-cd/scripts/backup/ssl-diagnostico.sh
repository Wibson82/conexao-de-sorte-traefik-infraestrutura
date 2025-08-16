#!/bin/bash

# 🔍 DIAGNÓSTICO COMPLETO SSL/TLS - Conexão de Sorte
# ✅ Script para identificar e resolver problemas de certificado SSL

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
DOMAIN="conexaodesorte.com.br"
WWW_DOMAIN="www.conexaodesorte.com.br"
TRAEFIK_CONTAINER="conexao-traefik"
COMPOSE_FILE="deploy/docker-compose.prod.yml"

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# Funções de log
log_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║$(printf "%66s" | tr ' ' ' ')║${NC}"
    echo -e "${PURPLE}║$(printf "%*s" $(((66-${#1})/2)) "")${1}$(printf "%*s" $(((66-${#1})/2)) "")║${NC}"
    echo -e "${PURPLE}║$(printf "%66s" | tr ' ' ' ')║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
}

log_section() {
    echo -e "\n${CYAN}🔍 $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Banner principal
log_header "DIAGNÓSTICO SSL/TLS - CONEXÃO DE SORTE"

# ===== TESTE 1: VERIFICAR FERRAMENTAS NECESSÁRIAS =====
log_section "Verificando Ferramentas Necessárias"

log_test "Verificando Docker..."
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    log_pass "Docker instalado: v$DOCKER_VERSION"
else
    log_fail "Docker não encontrado"
fi

log_test "Verificando Docker Compose..."
if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
    log_pass "Docker Compose disponível"
else
    log_fail "Docker Compose não encontrado"
fi

log_test "Verificando dig..."
if command_exists dig; then
    log_pass "dig disponível"
else
    log_warn "dig não encontrado - usando nslookup como fallback"
fi

log_test "Verificando curl..."
if command_exists curl; then
    log_pass "curl disponível"
else
    log_fail "curl não encontrado"
fi

log_test "Verificando openssl..."
if command_exists openssl; then
    OPENSSL_VERSION=$(openssl version | cut -d' ' -f2)
    log_pass "OpenSSL disponível: $OPENSSL_VERSION"
else
    log_fail "OpenSSL não encontrado"
fi

# ===== TESTE 2: VERIFICAR DNS =====
log_section "Verificando Configuração DNS"

log_test "Resolvendo $DOMAIN..."
if command_exists dig; then
    DNS_RESULT=$(dig +short $DOMAIN A)
    if [[ -n "$DNS_RESULT" ]]; then
        log_pass "$DOMAIN resolve para: $DNS_RESULT"
        SERVER_IP="$DNS_RESULT"
    else
        log_fail "$DOMAIN não resolve"
        SERVER_IP=""
    fi
else
    DNS_RESULT=$(nslookup $DOMAIN | grep -A1 "Name:" | tail -1 | awk '{print $2}' || echo "")
    if [[ -n "$DNS_RESULT" ]]; then
        log_pass "$DOMAIN resolve para: $DNS_RESULT"
        SERVER_IP="$DNS_RESULT"
    else
        log_fail "$DOMAIN não resolve"
        SERVER_IP=""
    fi
fi

log_test "Resolvendo $WWW_DOMAIN..."
if command_exists dig; then
    WWW_DNS_RESULT=$(dig +short $WWW_DOMAIN A)
    if [[ -n "$WWW_DNS_RESULT" ]]; then
        log_pass "$WWW_DOMAIN resolve para: $WWW_DNS_RESULT"
    else
        log_warn "$WWW_DOMAIN não resolve"
    fi
else
    WWW_DNS_RESULT=$(nslookup $WWW_DOMAIN | grep -A1 "Name:" | tail -1 | awk '{print $2}' || echo "")
    if [[ -n "$WWW_DNS_RESULT" ]]; then
        log_pass "$WWW_DOMAIN resolve para: $WWW_DNS_RESULT"
    else
        log_warn "$WWW_DOMAIN não resolve"
    fi
fi

# Verificar se DNS aponta para o servidor atual
if [[ -n "$SERVER_IP" ]]; then
    log_test "Verificando se DNS aponta para este servidor..."
    LOCAL_IP=$(hostname -I | awk '{print $1}' || echo "")
    if [[ "$SERVER_IP" == "$LOCAL_IP" ]]; then
        log_pass "DNS aponta para este servidor ($LOCAL_IP)"
    else
        log_warn "DNS aponta para $SERVER_IP, mas servidor local é $LOCAL_IP"
    fi
fi

# ===== TESTE 3: VERIFICAR CONTAINERS =====
log_section "Verificando Status dos Containers"

log_test "Verificando se Traefik está rodando..."
if docker ps | grep -q "$TRAEFIK_CONTAINER"; then
    TRAEFIK_STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$TRAEFIK_CONTAINER" | awk '{print $2}')
    log_pass "Traefik está rodando: $TRAEFIK_STATUS"
else
    log_fail "Traefik não está rodando"
fi

log_test "Verificando portas do Traefik..."
TRAEFIK_PORTS=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep "$TRAEFIK_CONTAINER" | cut -d$'\t' -f2 || echo "")
if [[ "$TRAEFIK_PORTS" == *"80->80"* && "$TRAEFIK_PORTS" == *"443->443"* ]]; then
    log_pass "Portas 80 e 443 estão mapeadas"
else
    log_fail "Portas 80 e/ou 443 não estão mapeadas corretamente"
    log_info "Portas atuais: $TRAEFIK_PORTS"
fi

# ===== TESTE 4: VERIFICAR CONECTIVIDADE =====
log_section "Verificando Conectividade"

log_test "Testando conectividade HTTP (porta 80)..."
if curl -s --connect-timeout 10 "http://$DOMAIN" >/dev/null; then
    log_pass "Conectividade HTTP OK"
else
    log_fail "Falha na conectividade HTTP"
fi

log_test "Testando conectividade HTTPS (porta 443)..."
if curl -s --connect-timeout 10 -k "https://$DOMAIN" >/dev/null; then
    log_pass "Conectividade HTTPS OK (certificado ignorado)"
else
    log_fail "Falha na conectividade HTTPS"
fi

# ===== TESTE 5: VERIFICAR CERTIFICADOS =====
log_section "Verificando Certificados SSL"

log_test "Verificando certificado atual..."
CERT_INFO=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -text 2>/dev/null || echo "")
if [[ -n "$CERT_INFO" ]]; then
    CERT_ISSUER=$(echo "$CERT_INFO" | grep "Issuer:" | head -1)
    CERT_SUBJECT=$(echo "$CERT_INFO" | grep "Subject:" | head -1)
    CERT_VALIDITY=$(echo "$CERT_INFO" | grep -A2 "Validity" | tail -2)
    
    log_info "Emissor: $CERT_ISSUER"
    log_info "Assunto: $CERT_SUBJECT"
    log_info "Validade: $CERT_VALIDITY"
    
    if [[ "$CERT_ISSUER" == *"Let's Encrypt"* ]]; then
        log_pass "Certificado Let's Encrypt encontrado"
    else
        log_warn "Certificado não é do Let's Encrypt"
    fi
else
    log_fail "Não foi possível obter informações do certificado"
fi

# ===== TESTE 6: VERIFICAR LOGS DO TRAEFIK =====
log_section "Verificando Logs do Traefik"

log_test "Verificando logs de ACME/Let's Encrypt..."
ACME_LOGS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | grep -i "acme\|letsencrypt\|certificate" | tail -10 || echo "")
if [[ -n "$ACME_LOGS" ]]; then
    log_info "Últimos logs ACME:"
    echo "$ACME_LOGS" | while read -r line; do
        echo "  $line"
    done
else
    log_warn "Nenhum log ACME encontrado"
fi

log_test "Verificando erros nos logs..."
ERROR_LOGS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | grep -i "error\|fail" | tail -5 || echo "")
if [[ -n "$ERROR_LOGS" ]]; then
    log_warn "Erros encontrados nos logs:"
    echo "$ERROR_LOGS" | while read -r line; do
        echo "  $line"
    done
else
    log_pass "Nenhum erro crítico encontrado nos logs"
fi

# ===== RESUMO FINAL =====
log_section "Resumo do Diagnóstico"

echo -e "${GREEN}✅ Testes Aprovados: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Testes Falharam: $TESTS_FAILED${NC}"
echo -e "${YELLOW}⚠️  Avisos: $WARNINGS${NC}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "\n${RED}🚨 PROBLEMAS ENCONTRADOS - Veja as sugestões abaixo${NC}"
else
    echo -e "\n${GREEN}🎉 DIAGNÓSTICO CONCLUÍDO - Sistema parece estar funcionando${NC}"
fi

# ===== SUGESTÕES DE CORREÇÃO =====
if [[ $TESTS_FAILED -gt 0 || $WARNINGS -gt 0 ]]; then
    log_section "Sugestões de Correção"

    echo -e "${YELLOW}💡 SOLUÇÕES RECOMENDADAS:${NC}"
    echo ""

    echo -e "${CYAN}1. Verificar/Corrigir DNS:${NC}"
    echo "   • Certifique-se que $DOMAIN aponta para o IP correto do servidor"
    echo "   • Configure também $WWW_DOMAIN se necessário"
    echo "   • Aguarde propagação DNS (pode levar até 24h)"
    echo ""

    echo -e "${CYAN}2. Reiniciar Traefik e forçar renovação SSL:${NC}"
    echo "   docker exec $TRAEFIK_CONTAINER rm -f /certs/acme.json"
    echo "   docker restart $TRAEFIK_CONTAINER"
    echo "   # Aguarde 2-5 minutos para Let's Encrypt processar"
    echo ""

    echo -e "${CYAN}3. Verificar configuração do Traefik:${NC}"
    echo "   docker logs $TRAEFIK_CONTAINER | grep -i acme"
    echo "   docker exec $TRAEFIK_CONTAINER ls -la /certs/"
    echo ""

    echo -e "${CYAN}4. Testar conectividade manualmente:${NC}"
    echo "   curl -v http://$DOMAIN"
    echo "   curl -v -k https://$DOMAIN"
    echo "   openssl s_client -connect $DOMAIN:443 -servername $DOMAIN"
    echo ""

    echo -e "${CYAN}5. Verificar firewall/portas:${NC}"
    echo "   sudo ufw status"
    echo "   sudo netstat -tlnp | grep ':80\\|:443'"
    echo ""

    echo -e "${CYAN}6. Recriar stack completa (último recurso):${NC}"
    echo "   docker-compose -f $COMPOSE_FILE down"
    echo "   docker volume rm conexao_traefik_certs"
    echo "   docker-compose -f $COMPOSE_FILE up -d"
    echo ""
fi

# ===== COMANDOS ÚTEIS =====
log_section "Comandos Úteis para Monitoramento"

echo -e "${YELLOW}🔧 COMANDOS DE MONITORAMENTO:${NC}"
echo ""

echo -e "${CYAN}Logs em tempo real:${NC}"
echo "   docker logs -f $TRAEFIK_CONTAINER"
echo ""

echo -e "${CYAN}Status dos containers:${NC}"
echo "   docker ps"
echo "   docker-compose -f $COMPOSE_FILE ps"
echo ""

echo -e "${CYAN}Verificar certificados:${NC}"
echo "   docker exec $TRAEFIK_CONTAINER ls -la /certs/"
echo "   docker exec $TRAEFIK_CONTAINER cat /certs/acme.json | jq ."
echo ""

echo -e "${CYAN}Testar SSL:${NC}"
echo "   curl -I https://$DOMAIN"
echo "   openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null"
echo ""

echo -e "${CYAN}Dashboard do Traefik (local):${NC}"
echo "   http://localhost:8080"
echo ""

# ===== INFORMAÇÕES ADICIONAIS =====
log_section "Informações do Sistema"

echo -e "${BLUE}📊 INFORMAÇÕES DO SISTEMA:${NC}"
echo ""

echo -e "${CYAN}Sistema Operacional:${NC}"
uname -a || echo "Não disponível"
echo ""

echo -e "${CYAN}Uso de Disco:${NC}"
df -h / || echo "Não disponível"
echo ""

echo -e "${CYAN}Memória:${NC}"
free -h || echo "Não disponível"
echo ""

echo -e "${CYAN}Containers Docker:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "Não disponível"
echo ""

echo -e "${CYAN}Volumes Docker:${NC}"
docker volume ls | grep conexao || echo "Nenhum volume encontrado"
echo ""

# ===== FOOTER =====
echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    DIAGNÓSTICO CONCLUÍDO                        ║${NC}"
echo -e "${PURPLE}║                                                                  ║${NC}"
echo -e "${PURPLE}║  Para mais ajuda, consulte: docs/SOLUCOES_FRONTEND_SSL.md       ║${NC}"
echo -e "${PURPLE}║  Ou execute: ./scripts/ssl-fix.sh (script de correção automática)║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}🏁 Diagnóstico SSL/TLS concluído!${NC}"
echo -e "${BLUE}📝 Execute este script novamente após aplicar as correções.${NC}\n"
