#!/bin/bash

# 🔍 DIAGNÓSTICO RÁPIDO - Status dos Serviços
# ✅ Verifica status atual sem fazer alterações

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

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar containers
check_containers() {
    log_header "STATUS DOS CONTAINERS"
    
    echo -e "${BLUE}📊 Containers em execução:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(conexao-|NAMES)" || echo "Nenhum container conexao- encontrado"
    
    echo -e "\n${BLUE}📊 Todos os containers conexao-:${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "(conexao-|NAMES)" || echo "Nenhum container conexao- encontrado"
}

# Testar conectividade
test_connectivity() {
    log_header "TESTE DE CONECTIVIDADE"
    
    # Backend API
    log_info "Testando Backend API..."
    if curl -s --connect-timeout 5 "http://$DOMAIN/rest/actuator/health" | grep -q "UP"; then
        log_success "Backend API funcionando: http://$DOMAIN/rest/actuator/health"
    else
        log_error "Backend API com problemas"
    fi
    
    # Frontend HTTP
    log_info "Testando Frontend HTTP..."
    local http_response=$(curl -s --connect-timeout 5 "http://$DOMAIN" 2>/dev/null || echo "")
    if echo "$http_response" | grep -q "html\|HTML\|<!DOCTYPE"; then
        log_success "Frontend HTTP funcionando: http://$DOMAIN"
    else
        log_error "Frontend HTTP com problemas"
        echo -e "${CYAN}Resposta recebida:${NC}"
        echo "$http_response" | head -3
    fi
    
    # Frontend HTTPS
    log_info "Testando Frontend HTTPS..."
    if curl -s --connect-timeout 5 "https://$DOMAIN" >/dev/null 2>&1; then
        log_success "Frontend HTTPS funcionando: https://$DOMAIN"
    else
        log_warn "Frontend HTTPS indisponível (pode ser rate limit)"
    fi
    
    # WWW variants
    log_info "Testando variantes WWW..."
    if curl -s --connect-timeout 5 "http://$WWW_DOMAIN" >/dev/null 2>&1; then
        log_success "WWW HTTP funcionando: http://$WWW_DOMAIN"
    else
        log_warn "WWW HTTP com problemas"
    fi
}

# Verificar certificados SSL
check_ssl() {
    log_header "STATUS SSL/TLS"
    
    # Verificar certificado atual
    log_info "Verificando certificado SSL..."
    local cert_info=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -issuer -dates 2>/dev/null || echo "Erro ao obter certificado")
    
    if [[ "$cert_info" == *"Let's Encrypt"* ]]; then
        log_success "Certificado Let's Encrypt encontrado"
        echo -e "${CYAN}$cert_info${NC}"
    else
        log_warn "Certificado Let's Encrypt não encontrado ou inválido"
        echo -e "${CYAN}$cert_info${NC}"
    fi
    
    # Verificar acme.json no Traefik
    if docker exec conexao-traefik test -f /certs/acme.json 2>/dev/null; then
        local cert_count=$(docker exec conexao-traefik cat /certs/acme.json 2>/dev/null | grep -c "\"certificate\":" || echo "0")
        log_info "Certificados no acme.json: $cert_count"
    else
        log_warn "Arquivo acme.json não encontrado no Traefik"
    fi
}

# Verificar logs recentes
check_logs() {
    log_header "LOGS RECENTES"
    
    # Logs do Traefik
    if docker ps | grep -q conexao-traefik; then
        echo -e "${BLUE}🔍 Últimos logs do Traefik:${NC}"
        docker logs --tail=5 conexao-traefik 2>&1 | head -5
    fi
    
    # Logs do Frontend
    if docker ps | grep -q conexao-frontend; then
        echo -e "\n${BLUE}🔍 Últimos logs do Frontend:${NC}"
        docker logs --tail=5 conexao-frontend 2>&1 | head -5
    else
        log_warn "Container frontend não está rodando"
    fi
    
    # Logs do Backend
    if docker ps | grep -q conexao-backend-green; then
        echo -e "\n${BLUE}🔍 Últimos logs do Backend:${NC}"
        docker logs --tail=5 conexao-backend-green 2>&1 | head -5
    fi
}

# Verificar redes Docker
check_networks() {
    log_header "REDES DOCKER"
    
    echo -e "${BLUE}🌐 Redes disponíveis:${NC}"
    docker network ls | grep -E "(conexao|traefik)" || echo "Nenhuma rede conexao/traefik encontrada"
    
    # Verificar containers na rede
    if docker network ls | grep -q conexao-network; then
        echo -e "\n${BLUE}🔗 Containers na rede conexao-network:${NC}"
        docker network inspect conexao-network --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "Erro ao inspecionar rede"
    fi
}

# Mostrar resumo e recomendações
show_recommendations() {
    log_header "RESUMO E RECOMENDAÇÕES"
    
    echo -e "${BLUE}🎯 Problemas identificados:${NC}"
    
    # Verificar se frontend está rodando
    if ! docker ps | grep -q conexao-frontend; then
        echo -e "  ${RED}• Frontend container não está rodando${NC}"
        echo -e "    ${CYAN}Solução: Execute ./scripts/fix-frontend-ssl.sh${NC}"
    fi
    
    # Verificar se HTTPS funciona
    if ! curl -s --connect-timeout 5 "https://$DOMAIN" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}• HTTPS indisponível (possível rate limit)${NC}"
        echo -e "    ${CYAN}Solução: Aguardar ou usar certificado auto-assinado${NC}"
    fi
    
    # Verificar se HTTP funciona
    if ! curl -s --connect-timeout 5 "http://$DOMAIN" | grep -q "html\|HTML"; then
        echo -e "  ${RED}• Frontend HTTP não está funcionando${NC}"
        echo -e "    ${CYAN}Solução: Execute ./scripts/fix-frontend-ssl.sh${NC}"
    fi
    
    echo -e "\n${BLUE}🛠️  Comandos úteis:${NC}"
    echo -e "  Corrigir frontend: ${CYAN}./scripts/fix-frontend-ssl.sh${NC}"
    echo -e "  Logs em tempo real: ${CYAN}docker logs -f conexao-frontend${NC}"
    echo -e "  Reiniciar Traefik: ${CYAN}docker restart conexao-traefik${NC}"
    echo -e "  Status completo: ${CYAN}docker ps${NC}"
    
    echo -e "\n${BLUE}🌐 URLs para testar:${NC}"
    echo -e "  Frontend: ${CYAN}http://$DOMAIN${NC}"
    echo -e "  Backend: ${CYAN}http://$DOMAIN/rest/actuator/health${NC}"
    echo -e "  Traefik Dashboard: ${CYAN}http://localhost:8080${NC} (se disponível)"
}

# EXECUÇÃO PRINCIPAL
main() {
    log_header "DIAGNÓSTICO RÁPIDO - CONEXÃO DE SORTE"
    
    check_containers
    test_connectivity
    check_ssl
    check_logs
    check_networks
    show_recommendations
    
    echo -e "\n${GREEN}🔍 Diagnóstico concluído!${NC}"
    echo -e "${BLUE}💡 Execute ./scripts/fix-frontend-ssl.sh para corrigir problemas do frontend${NC}\n"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
