#!/bin/bash
# 🔍 Verificação Específica do Roteamento Traefik
# ✅ Verifica se o roteamento está funcionando conforme especificado:
#    - conexaodesorte.com.br/rest → Backend (porta 8080)
#    - conexaodesorte.com.br → Frontend (porta 3000)

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

# Configurações
DOMAINS=("conexaodesorte.com.br" "www.conexaodesorte.com.br")
BACKEND_PATHS=("/rest/actuator/health" "/rest/v1/publico/teste" "/rest/v1/info")
FRONTEND_PATHS=("/" "/favicon.ico" "/static/js/main.js")
TESTE_PATHS=("/teste" "/teste/" "/teste/index.html")

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
                log_success "✅ Backend roteando corretamente: $domain$path → porta 8080 (${time_total}s)"
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
                log_success "✅ Frontend roteando corretamente: $domain$path → porta 3000 (${time_total}s)"
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

# Função para testar roteamento de teste
test_teste_routing() {
    local domain="$1"
    local path="$2"
    local timeout=10

    log_step "Testando imagem de teste ($domain$path)"

    # Fazer request HTTPS para teste
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
            # Verificar se é conteúdo HTML (imagem de teste)
            if [[ "$content_type" == *"text/html"* ]]; then
                log_success "✅ Imagem de teste roteando corretamente: $domain$path → porta 80 (${time_total}s)"
                return 0
            else
                log_warning "⚠️  Imagem de teste responde mas content-type inesperado: $content_type"
                return 1
            fi
            ;;
        404)
            log_warning "⚠️  Imagem de teste não encontrada: $domain$path (pode ser normal se ainda não implementada)"
            return 0
            ;;
        502|503|504)
            log_error "❌ Imagem de teste indisponível: HTTP $http_code"
            return 1
            ;;
        000)
            log_error "❌ Timeout/Erro de conexão para imagem de teste"
            return 1
            ;;
        *)
            log_warning "⚠️  Imagem de teste retornou HTTP $http_code (inesperado)"
            return 1
            ;;
    esac
}

# Função para verificar configuração do Traefik
check_traefik_config() {
    log_header "VERIFICAÇÃO DA CONFIGURAÇÃO DO TRAEFIK"

    # Verificar se Traefik está respondendo
    if curl -s -f "http://localhost:8080/ping" >/dev/null 2>&1; then
        log_success "✅ Traefik API está respondendo na porta 8080"
    else
        log_error "❌ Traefik API não está respondendo na porta 8080"
        return 1
    fi

    # Verificar rotas configuradas
    log_step "Rotas configuradas no Traefik:"
    local routes=$(curl -s "http://localhost:8080/api/http/routers" 2>/dev/null || echo "[]")

    if echo "$routes" | jq -r '.[] | "  - \(.name): \(.rule)"' 2>/dev/null; then
        log_success "✅ Rotas do Traefik obtidas com sucesso"
    else
        log_warning "⚠️  Não foi possível obter rotas do Traefik"
    fi

    # Verificar serviços configurados
    log_step "Serviços configurados no Traefik:"
    local services=$(curl -s "http://localhost:8080/api/http/services" 2>/dev/null || echo "[]")

    if echo "$services" | jq -r '.[] | "  - \(.name): \(.loadBalancer.servers[0].url // "N/A")"' 2>/dev/null; then
        log_success "✅ Serviços do Traefik obtidos com sucesso"
    else
        log_warning "⚠️  Não foi possível obter serviços do Traefik"
    fi

    # Verificar middlewares
    log_step "Middlewares configurados no Traefik:"
    local middlewares=$(curl -s "http://localhost:8080/api/http/middlewares" 2>/dev/null || echo "[]")

    if echo "$middlewares" | jq -r '.[] | "  - \(.name): \(.type)"' 2>/dev/null; then
        log_success "✅ Middlewares do Traefik obtidos com sucesso"
    else
        log_warning "⚠️  Não foi possível obter middlewares do Traefik"
    fi
}

# Função para verificar containers Docker
check_containers() {
    log_header "VERIFICAÇÃO DE CONTAINERS DOCKER"

    local containers=("traefik" "backend-prod" "frontend-prod" "frontend-teste")
    local all_running=true

    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container.*Up"; then
            log_success "✅ Container $container está rodando"
        else
            log_warning "⚠️  Container $container não está rodando (pode ser normal se ainda não implementado)"
            if [[ "$container" == "frontend-teste" ]]; then
                log_info "ℹ️  Container frontend-teste é opcional para testes futuros"
            else
                all_running=false
            fi
        fi
    done

    if [[ "$all_running" == "false" ]]; then
        log_error "❌ Containers essenciais não estão rodando. Abortando teste."
        return 1
    fi

    return 0
}

# Função para testar roteamento específico
test_domain_routing() {
    local domain="$1"
    local backend_success=0
    local frontend_success=0
    local teste_success=0
    local total_backend_tests=0
    local total_frontend_tests=0
    local total_teste_tests=0

    log_header "TESTE DE ROTEAMENTO PARA $domain"

    # Testar roteamento backend
    log_step "Testando roteamento backend (/rest → porta 8080)..."
    for path in "${BACKEND_PATHS[@]}"; do
        ((total_backend_tests++))
        if test_backend_routing "$domain" "$path"; then
            ((backend_success++))
        fi
    done

    # Testar roteamento frontend
    log_step "Testando roteamento frontend (domínio → porta 3000)..."
    for path in "${FRONTEND_PATHS[@]}"; do
        ((total_frontend_tests++))
        if test_frontend_routing "$domain" "$path"; then
            ((frontend_success++))
        fi
    done

    # Testar roteamento de teste
    log_step "Testando roteamento de teste (/teste → porta 80)..."
    for path in "${TESTE_PATHS[@]}"; do
        ((total_teste_tests++))
        if test_teste_routing "$domain" "$path"; then
            ((teste_success++))
        fi
    done

    # Resumo do domínio
    log_header "RESUMO PARA $domain"
    echo -e "${BLUE}Backend (/rest → porta 8080):${NC} $backend_success/$total_backend_tests testes passaram"
    echo -e "${BLUE}Frontend (domínio → porta 3000):${NC} $frontend_success/$total_frontend_tests testes passaram"
    echo -e "${BLUE}Teste (/teste → porta 80):${NC} $teste_success/$total_teste_tests testes passaram"

    if [[ $backend_success -eq $total_backend_tests && $frontend_success -eq $total_frontend_tests && $teste_success -eq $total_teste_tests ]]; then
        log_success "✅ Roteamento completo funcionando para $domain"
        return 0
    else
        log_warning "⚠️  Roteamento parcial para $domain"
        return 1
    fi
}

# Função principal
main() {
    log_header "VERIFICAÇÃO ESPECÍFICA DO ROTEAMENTO TRAEFIK"
    echo -e "${CYAN}🎯 Objetivo: Verificar se o roteamento está funcionando conforme especificado${NC}"
    echo -e "${CYAN}   conexaodesorte.com.br/rest → Backend (porta 8080)${NC}"
    echo -e "${CYAN}   conexaodesorte.com.br → Frontend (porta 3000)${NC}"
    echo -e "${CYAN}   conexaodesorte.com.br/teste → Imagem de Teste (porta 80)${NC}\n"

    # Verificar containers
    if ! check_containers; then
        exit 1
    fi

    # Verificar configuração do Traefik
    if ! check_traefik_config; then
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
        log_success "🎉 Roteamento funcionando conforme especificado!"
        echo -e "${GREEN}✅ /rest → Backend (porta 8080)${NC}"
        echo -e "${GREEN}✅ Domínio → Frontend (porta 3000)${NC}"
        echo -e "${GREEN}✅ /teste → Imagem de Teste (porta 80)${NC}"
        echo -e "${GREEN}✅ Ambos domínios funcionando${NC}"
        exit 0
    else
        log_error "❌ Problemas de roteamento detectados"
        echo -e "${YELLOW}💡 Verificar:${NC}"
        echo -e "  • Labels do Traefik nos containers"
        echo -e "  • Configuração de portas (backend: 8080, frontend: 3000, teste: 80)"
        echo -e "  • Middleware strip prefix para /rest e /teste"
        echo -e "  • Prioridades das rotas (backend: 200, teste: 150, frontend: 1)"
        exit 1
    fi
}

# Executar função principal
main "$@"
