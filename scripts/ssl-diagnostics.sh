#!/bin/bash
# =============================================================================
# 🔍 SSL/TLS DIAGNOSTICS AND TROUBLESHOOTING SCRIPT
# =============================================================================
# Script para diagnosticar e resolver problemas de SSL/TLS do Traefik
#
# Uso: ./ssl-diagnostics.sh [domain]
# Exemplo: ./ssl-diagnostics.sh conexaodesorte.com.br
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DOMAIN="${1:-conexaodesorte.com.br}"
WWW_DOMAIN="www.${DOMAIN}"
ACME_FILE="/letsencrypt/acme.json"
TRAEFIK_CONTAINER="traefik-microservices"

echo -e "${BLUE}🔍 DIAGNÓSTICO SSL/TLS PARA ${DOMAIN}${NC}"
echo "============================================="

# Função para logging
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Verificar se o Traefik está rodando
echo -e "\n${BLUE}1. VERIFICANDO CONTAINER TRAEFIK${NC}"
if docker ps | grep -q "${TRAEFIK_CONTAINER}"; then
    log_success "Container Traefik está rodando"
    TRAEFIK_STATUS=$(docker inspect "${TRAEFIK_CONTAINER}" --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    log_info "Status de saúde: ${TRAEFIK_STATUS}"
else
    log_error "Container Traefik não está rodando!"
    echo "Execute: docker-compose up -d traefik"
    exit 1
fi

# 2. Verificar rede Docker
echo -e "\n${BLUE}2. VERIFICANDO REDE DOCKER${NC}"
if docker network ls | grep -q "conexao-network-swarm"; then
    log_success "Rede conexao-network-swarm existe"
else
    log_warning "Rede conexao-network-swarm não encontrada"
    echo "Criando rede..."
    docker network create --driver overlay --attachable conexao-network-swarm || true
fi

# 3. Verificar configuração DNS
echo -e "\n${BLUE}3. VERIFICANDO DNS${NC}"
for domain in "${DOMAIN}" "${WWW_DOMAIN}"; do
    IP=$(dig +short "${domain}" @8.8.8.8 | head -1)
    if [[ -n "$IP" ]]; then
        log_success "${domain} -> ${IP}"
    else
        log_error "DNS não resolvido para ${domain}"
    fi
done

# 4. Verificar portas
echo -e "\n${BLUE}4. VERIFICANDO PORTAS${NC}"
for port in 80 443; do
    if netstat -tuln | grep -q ":${port} "; then
        log_success "Porta ${port} está aberta"
    else
        log_error "Porta ${port} não está disponível"
    fi
done

# 5. Verificar certificados Let's Encrypt
echo -e "\n${BLUE}5. VERIFICANDO CERTIFICADOS${NC}"
if docker exec "${TRAEFIK_CONTAINER}" test -f "${ACME_FILE}" 2>/dev/null; then
    CERT_COUNT=$(docker exec "${TRAEFIK_CONTAINER}" cat "${ACME_FILE}" | jq '.letsencrypt.Certificates | length' 2>/dev/null || echo "0")
    log_info "Arquivo ACME encontrado com ${CERT_COUNT} certificados"

    # Verificar se há certificados para nosso domínio
    if docker exec "${TRAEFIK_CONTAINER}" cat "${ACME_FILE}" | jq -r '.letsencrypt.Certificates[].domain.main' 2>/dev/null | grep -q "${DOMAIN}"; then
        log_success "Certificado encontrado para ${DOMAIN}"
    else
        log_warning "Nenhum certificado encontrado para ${DOMAIN}"
    fi
else
    log_warning "Arquivo ACME não encontrado"
fi

# 6. Testar conectividade SSL
echo -e "\n${BLUE}6. TESTANDO CONECTIVIDADE SSL${NC}"
for domain in "${DOMAIN}" "${WWW_DOMAIN}"; do
    echo "Testando ${domain}..."

    # Teste básico de conectividade
    if timeout 10 openssl s_client -connect "${domain}:443" -servername "${domain}" </dev/null >/dev/null 2>&1; then
        log_success "SSL conectando em ${domain}"

        # Verificar detalhes do certificado
        CERT_EXPIRY=$(echo | timeout 10 openssl s_client -connect "${domain}:443" -servername "${domain}" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [[ -n "$CERT_EXPIRY" ]]; then
            log_info "Certificado expira em: ${CERT_EXPIRY}"
        fi
    else
        log_error "Falha na conexão SSL para ${domain}"
    fi
done

# 7. Verificar configuração Traefik
echo -e "\n${BLUE}7. VERIFICANDO CONFIGURAÇÃO TRAEFIK${NC}"
if docker exec "${TRAEFIK_CONTAINER}" cat /etc/traefik/traefik.yml >/dev/null 2>&1; then
    log_success "Arquivo traefik.yml acessível"
else
    log_error "Não foi possível acessar traefik.yml"
fi

# Verificar arquivos dinâmicos
DYNAMIC_FILES=$(docker exec "${TRAEFIK_CONTAINER}" find /etc/traefik/dynamic -name "*.yml" 2>/dev/null | wc -l)
log_info "Encontrados ${DYNAMIC_FILES} arquivos de configuração dinâmica"

# 8. Verificar logs do Traefik
echo -e "\n${BLUE}8. ÚLTIMOS LOGS DO TRAEFIK${NC}"
echo "Últimas 10 linhas dos logs:"
docker logs "${TRAEFIK_CONTAINER}" --tail 10 2>/dev/null | while read line; do
    if echo "$line" | grep -i error >/dev/null; then
        echo -e "${RED}$line${NC}"
    elif echo "$line" | grep -i warn >/dev/null; then
        echo -e "${YELLOW}$line${NC}"
    else
        echo "$line"
    fi
done

# 9. Teste de requisição HTTP/HTTPS
echo -e "\n${BLUE}9. TESTANDO REQUISIÇÕES${NC}"
for protocol in http https; do
    for domain in "${DOMAIN}" "${WWW_DOMAIN}"; do
        URL="${protocol}://${domain}/"
        echo "Testando: ${URL}"

        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "${URL}" 2>/dev/null || echo "000")
        case "${HTTP_CODE}" in
            200|301|302|308)
                log_success "HTTP ${HTTP_CODE} - OK"
                ;;
            000)
                log_error "Falha na conexão"
                ;;
            *)
                log_warning "HTTP ${HTTP_CODE}"
                ;;
        esac
    done
done

# 10. Verificações finais e recomendações
echo -e "\n${BLUE}10. RECOMENDAÇÕES${NC}"
echo "=========================="

# Verificar se frontend está rodando
if docker ps | grep -q "conexao-frontend"; then
    log_success "Container frontend está rodando"
else
    log_warning "Container frontend não encontrado"
    echo "Execute: docker-compose up -d frontend"
fi

# Verificar redirecionamentos
echo -e "\n${YELLOW}📋 COMANDOS ÚTEIS PARA DEBUG:${NC}"
echo "- Ver logs completos: docker logs ${TRAEFIK_CONTAINER}"
echo "- Recarregar Traefik: docker-compose restart traefik"
echo "- Forçar renovação SSL: docker exec ${TRAEFIK_CONTAINER} traefik certificate renewal"
echo "- Verificar rotas: curl -H 'Host: ${DOMAIN}' http://localhost/"
echo "- Limpar certificados: sudo rm ${ACME_FILE} && docker-compose restart traefik"

echo -e "\n${GREEN}🎯 DIAGNÓSTICO CONCLUÍDO!${NC}"

# 11. Auto-fix para problemas comuns
echo -e "\n${BLUE}11. AUTO-CORREÇÃO${NC}"
read -p "Deseja tentar corrigir problemas automaticamente? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Executando correções automáticas..."

    # Recriar rede se necessário
    if ! docker network ls | grep -q "conexao-network-swarm"; then
        log_info "Criando rede conexao-network-swarm..."
        docker network create --driver overlay --attachable conexao-network-swarm || true
    fi

    # Reiniciar Traefik
    log_info "Reiniciando Traefik..."
    docker-compose restart traefik

    # Aguardar alguns segundos
    sleep 5

    # Testar novamente
    log_info "Testando conectividade após correções..."
    if timeout 10 curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/" | grep -q "200\|301\|302"; then
        log_success "Correções aplicadas com sucesso!"
    else
        log_warning "Ainda há problemas. Verifique os logs manualmente."
    fi
fi

echo -e "\n${GREEN}✨ Script finalizado!${NC}"