#!/bin/bash

# 🔍 VERIFICAÇÃO MIGRAÇÃO FRONTEND - Coolify → VPS
# ✅ Verifica se frontend foi migrado corretamente

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
EXPECTED_API_PATH="/rest"
FRONTEND_IMAGE="facilita/conexao-de-sorte-frontend:latest"

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar se está no VPS
check_environment() {
    log_step "Verificando ambiente..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não encontrado - execute no VPS"
        exit 1
    fi
    
    log_success "Ambiente verificado"
}

# Verificar container frontend
check_frontend_container() {
    log_step "Verificando container frontend..."
    
    if docker ps | grep -q conexao-frontend; then
        log_success "Container frontend está rodando"
        
        # Verificar imagem
        local image=$(docker inspect conexao-frontend --format='{{.Config.Image}}' 2>/dev/null || echo "unknown")
        log_info "Imagem atual: $image"
        
        # Verificar porta
        local port=$(docker port conexao-frontend 2>/dev/null | grep "3000/tcp" || echo "")
        if [[ -n "$port" ]]; then
            log_success "Porta 3000 exposta corretamente"
        else
            log_warn "Porta 3000 não encontrada"
        fi
        
        # Verificar rede
        local network=$(docker inspect conexao-frontend --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
        if echo "$network" | grep -q "conexao-network"; then
            log_success "Container na rede conexao-network"
        else
            log_error "Container NÃO está na rede conexao-network: $network"
        fi
        
    else
        log_error "Container frontend não está rodando"
        return 1
    fi
}

# Verificar variáveis de ambiente
check_environment_variables() {
    log_step "Verificando variáveis de ambiente do frontend..."
    
    if docker ps | grep -q conexao-frontend; then
        # Verificar VITE_API_URL
        local api_url=$(docker exec conexao-frontend env 2>/dev/null | grep "VITE_API_URL" || echo "")
        if echo "$api_url" | grep -q "$EXPECTED_API_PATH"; then
            log_success "VITE_API_URL configurado corretamente: $api_url"
        else
            log_error "VITE_API_URL incorreto ou não encontrado: $api_url"
            log_info "Esperado: VITE_API_URL=$EXPECTED_API_PATH"
        fi
        
        # Verificar NODE_ENV
        local node_env=$(docker exec conexao-frontend env 2>/dev/null | grep "NODE_ENV" || echo "")
        if echo "$node_env" | grep -q "production"; then
            log_success "NODE_ENV configurado para produção: $node_env"
        else
            log_warn "NODE_ENV não encontrado ou não é production: $node_env"
        fi
        
        # Listar todas as variáveis VITE_
        log_info "Todas as variáveis VITE_ encontradas:"
        docker exec conexao-frontend env 2>/dev/null | grep "VITE_" || echo "Nenhuma variável VITE_ encontrada"
        
    else
        log_error "Container frontend não está rodando"
        return 1
    fi
}

# Verificar labels Traefik
check_traefik_labels() {
    log_step "Verificando labels Traefik..."
    
    if docker ps | grep -q conexao-frontend; then
        # Verificar se Traefik está habilitado
        local traefik_enabled=$(docker inspect conexao-frontend --format='{{index .Config.Labels "traefik.enable"}}' 2>/dev/null || echo "")
        if [[ "$traefik_enabled" == "true" ]]; then
            log_success "Traefik habilitado no frontend"
        else
            log_error "Traefik NÃO está habilitado: $traefik_enabled"
        fi
        
        # Verificar rede Traefik
        local traefik_network=$(docker inspect conexao-frontend --format='{{index .Config.Labels "traefik.docker.network"}}' 2>/dev/null || echo "")
        if [[ "$traefik_network" == "conexao-network" ]]; then
            log_success "Rede Traefik configurada corretamente: $traefik_network"
        else
            log_error "Rede Traefik incorreta: $traefik_network (esperado: conexao-network)"
        fi
        
        # Verificar porta do serviço
        local service_port=$(docker inspect conexao-frontend --format='{{index .Config.Labels "traefik.http.services.frontend.loadbalancer.server.port"}}' 2>/dev/null || echo "")
        if [[ "$service_port" == "3000" ]]; then
            log_success "Porta do serviço configurada corretamente: $service_port"
        else
            log_error "Porta do serviço incorreta: $service_port (esperado: 3000)"
        fi
        
        # Verificar regra de roteamento
        local http_rule=$(docker inspect conexao-frontend --format='{{index .Config.Labels "traefik.http.routers.frontend-http.rule"}}' 2>/dev/null || echo "")
        if echo "$http_rule" | grep -q "$DOMAIN"; then
            log_success "Regra de roteamento HTTP configurada: $http_rule"
        else
            log_warn "Regra de roteamento HTTP não encontrada ou incorreta: $http_rule"
        fi
        
    else
        log_error "Container frontend não está rodando"
        return 1
    fi
}

# Testar conectividade interna
test_internal_connectivity() {
    log_step "Testando conectividade interna..."
    
    if docker ps | grep -q conexao-frontend; then
        # Teste interno na porta 3000
        if docker exec conexao-frontend wget --quiet --spider http://localhost:3000 2>/dev/null; then
            log_success "Frontend respondendo internamente na porta 3000"
        else
            log_error "Frontend NÃO responde internamente na porta 3000"
        fi
        
        # Verificar se serve está rodando
        local serve_process=$(docker exec conexao-frontend ps aux 2>/dev/null | grep "serve" | grep -v grep || echo "")
        if [[ -n "$serve_process" ]]; then
            log_success "Processo 'serve' está rodando"
            log_info "Processo: $(echo "$serve_process" | head -1)"
        else
            log_error "Processo 'serve' NÃO está rodando"
        fi
        
    else
        log_error "Container frontend não está rodando"
        return 1
    fi
}

# Testar conectividade externa
test_external_connectivity() {
    log_step "Testando conectividade externa..."
    
    # Teste HTTP
    log_info "Testando HTTP..."
    if curl -f --connect-timeout 10 "http://$DOMAIN" > /dev/null 2>&1; then
        log_success "Frontend acessível via HTTP"
    else
        log_warn "Frontend não acessível via HTTP (pode ser problema de DNS/rede)"
    fi
    
    # Teste HTTPS
    log_info "Testando HTTPS..."
    if curl -f -k --connect-timeout 10 "https://$DOMAIN" > /dev/null 2>&1; then
        log_success "Frontend acessível via HTTPS"
    else
        log_warn "Frontend não acessível via HTTPS (normal se certificado inválido)"
    fi
    
    # Teste da API
    log_info "Testando API backend..."
    if curl -f --connect-timeout 10 "http://$DOMAIN$EXPECTED_API_PATH/actuator/health" > /dev/null 2>&1; then
        log_success "Backend API acessível via $EXPECTED_API_PATH"
    else
        log_error "Backend API NÃO acessível via $EXPECTED_API_PATH"
    fi
}

# Verificar logs do frontend
check_frontend_logs() {
    log_step "Verificando logs do frontend..."
    
    if docker ps | grep -q conexao-frontend; then
        echo -e "${BLUE}📋 Últimos 10 logs do frontend:${NC}"
        docker logs conexao-frontend --tail 10 2>/dev/null || echo "Sem logs disponíveis"
        
        # Verificar se há erros nos logs
        local error_count=$(docker logs conexao-frontend 2>&1 | grep -i "error" | wc -l || echo "0")
        if [[ "$error_count" -eq 0 ]]; then
            log_success "Nenhum erro encontrado nos logs"
        else
            log_warn "$error_count erros encontrados nos logs"
        fi
        
    else
        log_error "Container frontend não está rodando"
        return 1
    fi
}

# Verificar imagem Docker Hub
check_docker_image() {
    log_step "Verificando imagem no Docker Hub..."
    
    # Pull da imagem mais recente para verificar
    log_info "Verificando imagem mais recente..."
    if docker pull $FRONTEND_IMAGE > /dev/null 2>&1; then
        log_success "Imagem disponível no Docker Hub"
        
        # Verificar quando foi criada
        local image_created=$(docker inspect $FRONTEND_IMAGE --format='{{.Created}}' 2>/dev/null | cut -d'T' -f1 || echo "unknown")
        log_info "Imagem criada em: $image_created"
        
    else
        log_error "Falha ao baixar imagem do Docker Hub"
    fi
}

# Mostrar resumo final
show_summary() {
    log_header "RESUMO DA VERIFICAÇÃO"
    
    echo -e "${BLUE}🎯 Status da Migração:${NC}"
    
    # Verificar se migração foi bem-sucedida
    local migration_ok=true
    
    # Verificações críticas
    if ! docker ps | grep -q conexao-frontend; then
        echo -e "  ${RED}❌ Container frontend não está rodando${NC}"
        migration_ok=false
    fi
    
    if docker exec conexao-frontend env 2>/dev/null | grep "VITE_API_URL" | grep -q "$EXPECTED_API_PATH"; then
        echo -e "  ${GREEN}✅ API URL configurada corretamente ($EXPECTED_API_PATH)${NC}"
    else
        echo -e "  ${RED}❌ API URL incorreta (deve ser $EXPECTED_API_PATH)${NC}"
        migration_ok=false
    fi
    
    if docker inspect conexao-frontend --format='{{index .Config.Labels "traefik.http.services.frontend.loadbalancer.server.port"}}' 2>/dev/null | grep -q "3000"; then
        echo -e "  ${GREEN}✅ Porta 3000 configurada corretamente${NC}"
    else
        echo -e "  ${RED}❌ Porta não configurada para 3000${NC}"
        migration_ok=false
    fi
    
    if docker inspect conexao-frontend --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null | grep -q "conexao-network"; then
        echo -e "  ${GREEN}✅ Rede conexao-network configurada${NC}"
    else
        echo -e "  ${RED}❌ Rede conexao-network não configurada${NC}"
        migration_ok=false
    fi
    
    echo -e "\n${BLUE}🌐 URLs para testar:${NC}"
    echo -e "  Frontend: ${CYAN}http://$DOMAIN${NC}"
    echo -e "  Backend: ${CYAN}http://$DOMAIN$EXPECTED_API_PATH/actuator/health${NC}"
    
    if [[ "$migration_ok" == "true" ]]; then
        echo -e "\n${GREEN}🎉 MIGRAÇÃO BEM-SUCEDIDA!${NC}"
        echo -e "${BLUE}💡 Frontend migrado com sucesso do Coolify para VPS${NC}"
    else
        echo -e "\n${RED}⚠️ MIGRAÇÃO INCOMPLETA${NC}"
        echo -e "${YELLOW}💡 Verifique os problemas acima e execute correções${NC}"
    fi
}

# EXECUÇÃO PRINCIPAL
main() {
    log_header "VERIFICAÇÃO MIGRAÇÃO FRONTEND"
    
    check_environment
    check_frontend_container
    check_environment_variables
    check_traefik_labels
    test_internal_connectivity
    test_external_connectivity
    check_frontend_logs
    check_docker_image
    show_summary
    
    echo -e "\n${GREEN}🔍 Verificação concluída!${NC}\n"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
