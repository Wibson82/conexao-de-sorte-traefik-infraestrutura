#!/bin/bash

# 🔧 SINCRONIZAÇÃO FRONTEND - Conexão de Sorte
# ✅ Sincroniza configurações entre backend e frontend

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
FRONTEND_IMAGE="facilita/conexao-de-sorte-frontend:latest"
BACKEND_API_PATH="/rest"

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar ambiente
check_environment() {
    log_step "Verificando ambiente..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não encontrado - execute no VPS"
        exit 1
    fi
    
    log_success "Ambiente verificado"
}

# Parar frontend atual
stop_current_frontend() {
    log_step "Parando frontend atual..."
    
    docker stop conexao-frontend 2>/dev/null || true
    docker rm conexao-frontend 2>/dev/null || true
    
    log_success "Frontend atual removido"
}

# Garantir rede Docker
ensure_network() {
    log_step "Garantindo rede Docker..."
    
    if ! docker network ls | grep -q conexao-network; then
        docker network create conexao-network
        log_success "Rede conexao-network criada"
    else
        log_info "Rede conexao-network já existe"
    fi
}

# Iniciar frontend com configuração sincronizada
start_synchronized_frontend() {
    log_step "Iniciando frontend com configuração sincronizada..."
    
    # Pull da imagem mais recente
    log_info "Baixando imagem mais recente..."
    docker pull $FRONTEND_IMAGE
    
    # Iniciar frontend com configuração correta
    log_info "Iniciando container frontend..."
    docker run -d \
        --name conexao-frontend \
        --network conexao-network \
        --restart unless-stopped \
        -e NODE_ENV=production \
        -e VITE_API_URL=$BACKEND_API_PATH \
        -e VITE_API_BASE_URL=$BACKEND_API_PATH \
        -e VITE_FORCE_HTTPS=true \
        -e VITE_ADMIN_URL=/admin \
        -e TZ=America/Sao_Paulo \
        --label "traefik.enable=true" \
        --label "traefik.docker.network=conexao-network" \
        --label "traefik.http.routers.frontend-http.rule=Host(\`$DOMAIN\`) || Host(\`$WWW_DOMAIN\`)" \
        --label "traefik.http.routers.frontend-http.entrypoints=web" \
        --label "traefik.http.routers.frontend-http.priority=1" \
        --label "traefik.http.routers.frontend-https.rule=Host(\`$DOMAIN\`) || Host(\`$WWW_DOMAIN\`)" \
        --label "traefik.http.routers.frontend-https.entrypoints=websecure" \
        --label "traefik.http.routers.frontend-https.tls=true" \
        --label "traefik.http.routers.frontend-https.priority=1" \
        --label "traefik.http.services.frontend.loadbalancer.server.port=3000" \
        --label "traefik.http.middlewares.frontend-gzip.compress=true" \
        --label "traefik.http.routers.frontend-http.middlewares=frontend-gzip" \
        --label "traefik.http.routers.frontend-https.middlewares=frontend-gzip" \
        $FRONTEND_IMAGE
    
    # Aguardar inicialização
    sleep 15
    
    if docker ps | grep -q conexao-frontend; then
        log_success "Frontend iniciado com configuração sincronizada"
    else
        log_error "Falha ao iniciar frontend"
        docker logs conexao-frontend --tail 10 2>/dev/null || echo "Sem logs disponíveis"
        return 1
    fi
}

# Testar conectividade
test_connectivity() {
    log_step "Testando conectividade..."
    
    # Aguardar propagação
    sleep 20
    
    # Teste interno do container
    log_info "Testando frontend internamente..."
    if docker exec conexao-frontend wget --quiet --spider http://localhost:3000 2>/dev/null; then
        log_success "Frontend respondendo internamente na porta 3000"
    else
        log_warn "Frontend não responde internamente"
    fi
    
    # Teste via localhost no VPS
    log_info "Testando via localhost no VPS..."
    if curl -f http://localhost 2>/dev/null | head -1; then
        log_success "Frontend acessível via localhost"
    else
        log_warn "Frontend não acessível via localhost"
    fi
    
    # Teste externo HTTP
    log_info "Testando frontend externo HTTP..."
    if curl -f http://$DOMAIN 2>/dev/null | head -1; then
        log_success "Frontend funcionando externamente via HTTP"
    else
        log_warn "Frontend não acessível externamente via HTTP"
    fi
    
    # Teste externo HTTPS (pode falhar com certificado)
    log_info "Testando frontend externo HTTPS..."
    if curl -f -k https://$DOMAIN 2>/dev/null | head -1; then
        log_success "Frontend funcionando externamente via HTTPS"
    else
        log_warn "Frontend não acessível externamente via HTTPS (normal se certificado inválido)"
    fi
}

# Verificar logs
check_logs() {
    log_step "Verificando logs do frontend..."
    
    echo -e "${BLUE}📋 Últimos logs do frontend:${NC}"
    docker logs conexao-frontend --tail 10 2>/dev/null || echo "Sem logs disponíveis"
    
    echo -e "\n${BLUE}📊 Status do container:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|conexao-frontend)" || echo "Container não encontrado"
}

# Mostrar configuração final
show_final_config() {
    log_header "CONFIGURAÇÃO FINAL"
    
    echo -e "${BLUE}🔧 Configurações aplicadas:${NC}"
    echo -e "  • Imagem: ${CYAN}$FRONTEND_IMAGE${NC}"
    echo -e "  • Porta interna: ${CYAN}3000${NC}"
    echo -e "  • API URL: ${CYAN}$BACKEND_API_PATH${NC}"
    echo -e "  • Domínios: ${CYAN}$DOMAIN, $WWW_DOMAIN${NC}"
    
    echo -e "\n${BLUE}🌐 URLs para testar:${NC}"
    echo -e "  • Frontend HTTP: ${CYAN}http://$DOMAIN${NC}"
    echo -e "  • Frontend HTTPS: ${CYAN}https://$DOMAIN${NC}"
    echo -e "  • Backend API: ${CYAN}http://$DOMAIN$BACKEND_API_PATH/actuator/health${NC}"
    
    echo -e "\n${BLUE}🛠️  Comandos úteis:${NC}"
    echo -e "  • Logs frontend: ${CYAN}docker logs -f conexao-frontend${NC}"
    echo -e "  • Status containers: ${CYAN}docker ps${NC}"
    echo -e "  • Reiniciar frontend: ${CYAN}docker restart conexao-frontend${NC}"
}

# EXECUÇÃO PRINCIPAL
main() {
    log_header "SINCRONIZAÇÃO FRONTEND - BACKEND"
    
    echo -e "${YELLOW}⚠️  Esta operação irá recriar o frontend com configuração sincronizada.${NC}"
    echo -e "${BLUE}ℹ️  Pressione Ctrl+C para cancelar ou Enter para continuar...${NC}"
    read -r
    
    check_environment
    stop_current_frontend
    ensure_network
    start_synchronized_frontend
    test_connectivity
    check_logs
    show_final_config
    
    echo -e "\n${GREEN}🎉 Sincronização concluída!${NC}"
    echo -e "${CYAN}🌐 Teste agora: http://$DOMAIN${NC}\n"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
