#!/bin/bash

# Script de teste de conectividade do Traefik para CI/CD
# Executa testes específicos para identificar problemas de roteamento

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Variáveis de configuração
DOMAINS=("conexaodesorte.com.br" "www.conexaodesorte.com.br")
TIMEOUT=30
RETRY_COUNT=3

log_header "TESTE DE CONECTIVIDADE TRAEFIK - CI/CD"

# 1. Verificar se o Traefik está rodando
log_header "1. VERIFICAÇÃO DO TRAEFIK"
if docker ps --format "table {{.Names}}" | grep -q "traefik"; then
    TRAEFIK_STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep traefik)
    log_success "Traefik está rodando: $TRAEFIK_STATUS"
else
    log_error "Traefik não está rodando"
    exit 1
fi

# 2. Verificar logs do Traefik para erros
log_header "2. LOGS DO TRAEFIK"
log_info "Últimas 10 linhas dos logs do Traefik:"
docker logs traefik --tail 10 || log_error "Não foi possível obter logs do Traefik"

# 3. Verificar se a API do Traefik está respondendo
log_header "3. API DO TRAEFIK"
if curl -s --connect-timeout 10 http://localhost:8080/api/http/routers >/dev/null 2>&1; then
    log_success "API do Traefik está respondendo"

    # Verificar rotas configuradas
    log_info "Rotas configuradas:"
    ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "Erro ao obter rotas")
    echo "$ROUTES"
else
    log_error "API do Traefik não está respondendo"
fi

# 4. Verificar serviços do Traefik
log_header "4. SERVIÇOS DO TRAEFIK"
if curl -s --connect-timeout 10 http://localhost:8080/api/http/services >/dev/null 2>&1; then
    log_success "Serviços do Traefik estão configurados"

    # Verificar serviços
    log_info "Serviços configurados:"
    SERVICES=$(curl -s http://localhost:8080/api/http/services 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "Erro ao obter serviços")
    echo "$SERVICES"
else
    log_error "Não foi possível obter serviços do Traefik"
fi

# 5. Verificar conflito de porta 3000
log_header "5. VERIFICAÇÃO DE CONFLITO DE PORTA"
log_info "Verificando uso da porta 3000:"
PORT_3000_USAGE=$(netstat -tuln 2>/dev/null | grep ":3000 " || echo "Porta 3000 não está em uso")
echo "$PORT_3000_USAGE"

if echo "$PORT_3000_USAGE" | grep -q "3000"; then
            log_warning "Porta 3000 está em uso - verificar se é o Frontend (Grafana agora usa porta 3001)"
    log_info "Processos usando porta 3000:"
    netstat -tulnp 2>/dev/null | grep ":3000 " || true
fi

# 6. Verificar conectividade local dos serviços
log_header "6. CONECTIVIDADE LOCAL"

# Testar frontend na porta 3000
log_info "Testando frontend na porta 3000..."
if curl -s --connect-timeout 10 --max-time 30 http://localhost:3000 >/dev/null 2>&1; then
    log_success "Frontend está respondendo na porta 3000"
else
    log_error "Frontend não está respondendo na porta 3000"
fi

# Testar backend na porta 8080
log_info "Testando backend na porta 8080..."
if curl -s --connect-timeout 10 --max-time 30 http://localhost:8080/actuator/health >/dev/null 2>&1; then
    log_success "Backend está respondendo na porta 8080"
else
    log_error "Backend não está respondendo na porta 8080"
fi

# 7. Testar conectividade externa
log_header "7. TESTE DE CONECTIVIDADE EXTERNA"

for domain in "${DOMAINS[@]}"; do
    log_info "Testando domínio: $domain"

    # Teste HTTP
    log_info "  - Testando HTTP..."
    HTTP_STATUS=$(curl -I --connect-timeout $TIMEOUT --max-time $TIMEOUT "http://$domain" 2>/dev/null | head -1 || echo "HTTP falhou")
    if echo "$HTTP_STATUS" | grep -q "HTTP"; then
        log_success "  HTTP OK: $HTTP_STATUS"
    else
        log_error "  HTTP falhou: $HTTP_STATUS"
    fi

    # Teste HTTPS
    log_info "  - Testando HTTPS..."
    HTTPS_STATUS=$(curl -I --connect-timeout $TIMEOUT --max-time $TIMEOUT "https://$domain" 2>/dev/null | head -1 || echo "HTTPS falhou")
    if echo "$HTTPS_STATUS" | grep -q "HTTP"; then
        log_success "  HTTPS OK: $HTTPS_STATUS"
    else
        log_error "  HTTPS falhou: $HTTPS_STATUS"
    fi

    # Teste API backend
    log_info "  - Testando API backend..."
    API_STATUS=$(curl -I --connect-timeout $TIMEOUT --max-time $TIMEOUT "https://$domain/rest/actuator/health" 2>/dev/null | head -1 || echo "API falhou")
    if echo "$API_STATUS" | grep -q "HTTP"; then
        log_success "  API OK: $API_STATUS"
    else
        log_error "  API falhou: $API_STATUS"
    fi
done

# 8. Verificar certificados SSL
log_header "8. VERIFICAÇÃO SSL"
for domain in "${DOMAINS[@]}"; do
    log_info "Verificando certificado para $domain..."
    if echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates >/dev/null 2>&1; then
        log_success "Certificado SSL válido para $domain"
        echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates || true
    else
        log_error "Problema com certificado SSL para $domain"
    fi
done

# 9. Verificar configuração do Traefik
log_header "9. CONFIGURAÇÃO DO TRAEFIK"
if [ -f "/etc/traefik/traefik.yml" ]; then
    log_success "Arquivo de configuração encontrado"
    log_info "Verificando configuração básica:"
    head -20 /etc/traefik/traefik.yml || true
else
    log_error "Arquivo de configuração não encontrado"
fi

# 10. Verificar arquivos de configuração dinâmica
log_header "10. CONFIGURAÇÕES DINÂMICAS"
if [ -d "/etc/traefik/conf.d" ]; then
    log_success "Diretório de configurações dinâmicas encontrado"
    log_info "Arquivos de configuração:"
    ls -la /etc/traefik/conf.d/ || true
else
    log_error "Diretório de configurações dinâmicas não encontrado"
fi

# 11. Verificar rede Docker
log_header "11. REDE DOCKER"
log_info "Verificando se containers estão na mesma rede:"
docker network ls || true

log_info "Containers na rede bridge:"
docker network inspect bridge 2>/dev/null | jq '.[0].Containers' 2>/dev/null || docker network inspect bridge 2>/dev/null || true

# 12. Verificar status dos containers
log_header "12. STATUS DOS CONTAINERS"
log_info "Status de todos os containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

# 13. Teste de resolução DNS
log_header "13. RESOLUÇÃO DNS"
for domain in "${DOMAINS[@]}"; do
    log_info "Verificando DNS para $domain..."
    if nslookup "$domain" >/dev/null 2>&1; then
        log_success "DNS OK para $domain"
        nslookup "$domain" | grep "Address:" | head -1 || true
    else
        log_error "Problema com DNS para $domain"
    fi
done

# 14. Verificar firewall
log_header "14. FIREWALL"
log_info "Status do firewall:"
ufw status 2>/dev/null || iptables -L 2>/dev/null | head -10 || log_warning "Não foi possível verificar firewall"

# 15. Teste de conectividade de rede
log_header "15. CONECTIVIDADE DE REDE"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log_success "Conectividade de rede OK"
else
    log_error "Problema de conectividade de rede"
fi

# 16. Resumo e recomendações
log_header "16. RESUMO E RECOMENDAÇÕES"

echo ""
log_info "Resumo dos testes:"

# Contar sucessos e falhas
SUCCESS_COUNT=0
ERROR_COUNT=0

# Verificar se Traefik está rodando
if docker ps --format "table {{.Names}}" | grep -q "traefik"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# Verificar se API responde
if curl -s --connect-timeout 5 http://localhost:8080/api/http/routers >/dev/null 2>&1; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
else
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# Verificar conectividade externa
for domain in "${DOMAINS[@]}"; do
    if curl -I --connect-timeout 10 "https://$domain" >/dev/null 2>&1; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

log_info "Testes bem-sucedidos: $SUCCESS_COUNT"
log_info "Testes com falha: $ERROR_COUNT"

echo ""
if [ $ERROR_COUNT -gt 0 ]; then
    log_error "Problemas detectados! Recomendações:"
    echo "1. Execute: ./scripts/cleanup-traefik-before-deploy.sh"
    echo "2. Execute: ./scripts/fix-traefik-urgent.sh"
    echo "3. Verifique logs: docker logs traefik --tail 100"
    echo "4. Reinicie Traefik: docker restart traefik"
    exit 1
else
    log_success "Todos os testes passaram! Traefik está funcionando corretamente."
fi

log_header "TESTE CONCLUÍDO"
