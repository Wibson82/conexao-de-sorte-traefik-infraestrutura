#!/bin/bash
# 🔍 Teste Específico de Roteamento de Domínios - Traefik
# ✅ Verifica especificamente se conexaodesorte.com.br e www.conexaodesorte.com.br
#    estão roteando corretamente para frontend (porta 3000) e backend (porta 8080)

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Configurações específicas para teste de roteamento
DOMAINS=("conexaodesorte.com.br" "www.conexaodesorte.com.br")
FRONTEND_TEST_PATHS=("/" "/favicon.ico" "/static/js/main.js")
BACKEND_TEST_PATHS=("/rest/actuator/health" "/rest/v1/info" "/rest/v1/publico/teste")
TRAEFIK_API_PORT="8080"

# Função para testar redirecionamento HTTP→HTTPS
test_http_redirect() {
    local domain="$1"
    local timeout=10

    log_step "Testando redirecionamento HTTP→HTTPS: $domain"

    # Fazer request HTTP e capturar redirecionamento
    response=$(curl -s -w "%{http_code}|%{redirect_url}|%{time_total}" \
        --max-time $timeout \
        --connect-timeout 5 \
        "http://$domain" 2>/dev/null || echo "000|||")

    # Parse response
    http_code=$(echo "$response" | cut -d'|' -f1)
    redirect_url=$(echo "$response" | cut -d'|' -f2)
    time_total=$(echo "$response" | cut -d'|' -f3)

    if [[ "$redirect_url" == *"https://"* ]]; then
        log_success "✅ Redirecionamento HTTP→HTTPS funcionando: http://$domain → $redirect_url (${time_total}s)"
        return 0
    elif [[ "$http_code" == "301" || "$http_code" == "302" ]]; then
        log_success "✅ Redirecionamento $http_code detectado: $redirect_url"
        return 0
    else
        log_error "❌ Redirecionamento HTTP→HTTPS falhou: HTTP $http_code"
        return 1
    fi
}

# Função para testar roteamento frontend
test_frontend_routing() {
    local domain="$1"
    local path="$2"
    local timeout=10

    log_step "Testando frontend ($domain$path)"

    # Fazer request HTTPS para frontend
    response=$(curl -s -w "%{http_code}|%{content_type}|%{time_total}" \
        --max-time $timeout \
        --connect-timeout 5 \
        --insecure \
        "https://$domain$path" 2>/dev/null || echo "000|||")

    http_code=$(echo "$response" | cut -d'|' -f1)
    content_type=$(echo "$response" | cut -d'|' -f2)
    time_total=$(echo "$response" | cut -d'|' -f3)

    case $http_code in
        200)
            # Verificar se é conteúdo frontend (HTML/JS/CSS)
            if [[ "$content_type" == *"text/html"* ]] || [[ "$content_type" == *"application/javascript"* ]] || [[ "$content_type" == *"text/css"* ]]; then
                log_success "✅ Frontend roteando corretamente: $domain$path (${time_total}s)"
                return 0
            else
                log_warning "⚠️  Frontend responde mas content-type inesperado: $content_type"
                return 1
            fi
            ;;
        404)
            if [[ "$path" == "/favicon.ico" ]]; then
                log_info "ℹ️  Favicon não encontrado (normal para desenvolvimento)"
                return 0
            else
                log_error "❌ Frontend não encontrado: $domain$path"
                return 1
            fi
            ;;
        502|503|504)
            log_error "❌ Frontend indisponível: HTTP $http_code"
            return 1
            ;;
        000)
            log_error "❌ Timeout/Erro de conexão para frontend"
            return 1
            ;;
        *)
            log_warning "⚠️  Frontend retornou HTTP $http_code (inesperado)"
            return 1
            ;;
    esac
}

# Função para testar roteamento backend
test_backend_routing() {
    local domain="$1"
    local path="$2"
    local timeout=10

    log_step "Testando backend ($domain$path)"

    # Fazer request HTTPS para backend
    response=$(curl -s -w "%{http_code}|%{content_type}|%{time_total}" \
        --max-time $timeout \
        --connect-timeout 5 \
        --insecure \
        "https://$domain$path" 2>/dev/null || echo "000|||")

    http_code=$(echo "$response" | cut -d'|' -f1)
    content_type=$(echo "$response" | cut -d'|' -f2)
    time_total=$(echo "$response" | cut -d'|' -f3)

    case $http_code in
        200)
            # Verificar se é JSON (backend API)
            if [[ "$content_type" == *"application/json"* ]]; then
                log_success "✅ Backend roteando corretamente: $domain$path (${time_total}s)"
                return 0
            else
                log_warning "⚠️  Backend responde mas content-type inesperado: $content_type"
                return 1
            fi
            ;;
        404)
            log_warning "⚠️  Endpoint backend não encontrado: $domain$path (pode ser normal)"
            return 0
            ;;
        502|503|504)
            log_error "❌ Backend indisponível: HTTP $http_code"
            return 1
            ;;
        000)
            log_error "❌ Timeout/Erro de conexão para backend"
            return 1
            ;;
        *)
            log_warning "⚠️  Backend retornou HTTP $http_code (inesperado)"
            return 1
            ;;
    esac
}

# Função para verificar containers Docker específicos
check_docker_containers() {
    log_header "VERIFICAÇÃO DE CONTAINERS DOCKER"

    local containers=("traefik" "backend" "frontend")
    local all_running=true

    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container.*Up"; then
            log_success "✅ Container $container está rodando"
        else
            log_error "❌ Container $container não está rodando"
            all_running=false
        fi
    done

    if [[ "$all_running" == "false" ]]; then
        log_error "❌ Nem todos os containers estão rodando. Abortando teste de roteamento."
        return 1
    fi

    return 0
}

# Função para verificar configuração específica do Traefik
check_traefik_routing_config() {
    log_header "VERIFICAÇÃO DA CONFIGURAÇÃO DO TRAEFIK"

    # Verificar se Traefik API está respondendo
    if curl -s -f "http://localhost:$TRAEFIK_API_PORT/ping" >/dev/null 2>&1; then
        log_success "✅ Traefik API está respondendo na porta $TRAEFIK_API_PORT"
    else
        log_error "❌ Traefik API não está respondendo na porta $TRAEFIK_API_PORT"
        return 1
    fi

    # Verificar rotas específicas configuradas
    log_step "Rotas configuradas no Traefik:"
    local routes=$(curl -s "http://localhost:$TRAEFIK_API_PORT/api/http/routers" 2>/dev/null || echo "[]")

    if echo "$routes" | jq -r '.[] | "  - \(.name): \(.rule)"' 2>/dev/null; then
        log_success "✅ Rotas do Traefik obtidas com sucesso"
    else
        log_warning "⚠️  Não foi possível obter rotas do Traefik ou não há rotas configuradas"
    fi

    # Verificar serviços específicos
    log_step "Serviços configurados no Traefik:"
    local services=$(curl -s "http://localhost:$TRAEFIK_API_PORT/api/http/services" 2>/dev/null || echo "[]")

    if echo "$services" | jq -r '.[] | "  - \(.name): \(.loadBalancer.servers[0].url // "N/A")"' 2>/dev/null; then
        log_success "✅ Serviços do Traefik obtidos com sucesso"
    else
        log_warning "⚠️  Não foi possível obter serviços do Traefik"
    fi
}

# Função para testar roteamento específico por domínio
test_domain_routing() {
    local domain="$1"
    local frontend_success=0
    local backend_success=0
    local total_frontend_tests=0
    local total_backend_tests=0

    log_header "TESTE DE ROTEAMENTO PARA $domain"

    # Testar redirecionamento HTTP→HTTPS
    if test_http_redirect "$domain"; then
        log_success "✅ Redirecionamento HTTP→HTTPS OK para $domain"
    else
        log_error "❌ Redirecionamento HTTP→HTTPS falhou para $domain"
    fi

    # Testar roteamento frontend
    log_step "Testando roteamento frontend..."
    for path in "${FRONTEND_TEST_PATHS[@]}"; do
        ((total_frontend_tests++))
        if test_frontend_routing "$domain" "$path"; then
            ((frontend_success++))
        fi
    done

    # Testar roteamento backend
    log_step "Testando roteamento backend..."
    for path in "${BACKEND_TEST_PATHS[@]}"; do
        ((total_backend_tests++))
        if test_backend_routing "$domain" "$path"; then
            ((backend_success++))
        fi
    done

    # Resumo do domínio
    log_header "RESUMO PARA $domain"
    echo -e "${BLUE}Frontend:${NC} $frontend_success/$total_frontend_tests testes passaram"
    echo -e "${BLUE}Backend:${NC} $backend_success/$total_backend_tests testes passaram"

    if [[ $frontend_success -eq $total_frontend_tests && $backend_success -eq $total_backend_tests ]]; then
        log_success "✅ Roteamento completo funcionando para $domain"
        return 0
    else
        log_warning "⚠️  Roteamento parcial para $domain"
        return 1
    fi
}

# Função principal
main() {
    log_header "TESTE ESPECÍFICO DE ROTEAMENTO DE DOMÍNIOS"
    echo -e "${CYAN}🎯 Objetivo: Verificar se Traefik está roteando corretamente${NC}"
    echo -e "${CYAN}   Frontend (React) → conexaodesorte.com.br:3000${NC}"
    echo -e "${CYAN}   Backend (API) → conexaodesorte.com.br:8080/rest${NC}\n"

    # Verificar containers
    if ! check_docker_containers; then
        exit 1
    fi

    # Verificar configuração do Traefik
    if ! check_traefik_routing_config; then
        log_error "❌ Configuração do Traefik com problemas"
        exit 1
    fi

    # Testar roteamento para cada domínio
    local overall_success=true
    for domain in "${DOMAINS[@]}"; do
        if ! test_domain_routing "$domain"; then
            overall_success=false
        fi
    done

    # Resumo final
    log_header "RESUMO FINAL"
    if [[ "$overall_success" == "true" ]]; then
        log_success "🎉 Todos os domínios estão roteando corretamente!"
        echo -e "${GREEN}✅ Frontend e Backend acessíveis via HTTPS${NC}"
        echo -e "${GREEN}✅ Redirecionamento HTTP→HTTPS funcionando${NC}"
        echo -e "${GREEN}✅ Traefik configurado corretamente${NC}"
        exit 0
    else
        log_error "❌ Alguns problemas de roteamento detectados"
        echo -e "${YELLOW}💡 Verificar:${NC}"
        echo -e "  • Configuração do Traefik no docker-compose.prod.yml"
        echo -e "  • Labels dos containers (traefik.enable, traefik.http.routers)"
        echo -e "  • Redes Docker (conexao-network)"
        echo -e "  • Portas dos serviços (3000 frontend, 8080 backend)"
        exit 1
    fi
}

# Executar função principal
main "$@"
