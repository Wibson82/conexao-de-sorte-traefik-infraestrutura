#!/bin/bash

# 🔍 Script de Verificação de Rotas Traefik
# Verifica o status do Traefik e todas as rotas configuradas

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se Docker está rodando
check_docker() {
    log_info "Verificando Docker..."
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando ou não acessível"
        exit 1
    fi
    log_success "Docker está rodando"
}

# Verificar containers
check_containers() {
    log_info "Verificando status dos containers..."
    echo ""
    echo "📊 Status dos containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|backend|traefik|frontend)" || log_warning "Nenhum container encontrado"
    echo ""
}

# Verificar redes Docker
check_networks() {
    log_info "Verificando redes Docker..."
    echo ""
    echo "🌐 Redes Docker:"
    docker network ls | grep -E "(NETWORK|traefik|conexao)" || log_warning "Nenhuma rede específica encontrada"
    echo ""
}

# Verificar Traefik
check_traefik() {
    log_info "Verificando Traefik..."
    
    if ! docker ps | grep -q "traefik.*Up"; then
        log_error "Traefik não está rodando!"
        return 1
    fi
    
    log_success "Traefik está rodando"
    
    # Verificar API do Traefik
    if curl -s http://localhost:8080/api/overview >/dev/null 2>&1; then
        log_success "API do Traefik acessível"
    else
        log_warning "API do Traefik não acessível em localhost:8080"
    fi
}

# Verificar routers do Traefik
check_traefik_routers() {
    log_info "Verificando routers do Traefik..."
    
    if ! curl -s http://localhost:8080/api/http/routers >/dev/null 2>&1; then
        log_warning "Não foi possível acessar API de routers do Traefik"
        return 1
    fi
    
    echo ""
    echo "🔀 Routers configurados:"
    
    # Extrair informações dos routers
    local routers_json
    routers_json=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
    
    if command -v jq >/dev/null 2>&1; then
        echo "$routers_json" | jq -r '.[] | "\(.name): \(.rule) (Priority: \(.priority // "default"))"' 2>/dev/null || {
            log_warning "Erro ao processar JSON dos routers"
            echo "Raw response:"
            echo "$routers_json" | head -20
        }
    else
        log_warning "jq não instalado. Mostrando resposta raw:"
        echo "$routers_json" | head -20
    fi
    echo ""
}

# Verificar services do Traefik
check_traefik_services() {
    log_info "Verificando services do Traefik..."
    
    if ! curl -s http://localhost:8080/api/http/services >/dev/null 2>&1; then
        log_warning "Não foi possível acessar API de services do Traefik"
        return 1
    fi
    
    echo ""
    echo "🔧 Services configurados:"
    
    local services_json
    services_json=$(curl -s http://localhost:8080/api/http/services 2>/dev/null || echo "[]")
    
    if command -v jq >/dev/null 2>&1; then
        echo "$services_json" | jq -r '.[] | "\(.name): \(.loadBalancer.servers[0].url // "No URL")"' 2>/dev/null || {
            log_warning "Erro ao processar JSON dos services"
            echo "Raw response:"
            echo "$services_json" | head -20
        }
    else
        log_warning "jq não instalado. Mostrando resposta raw:"
        echo "$services_json" | head -20
    fi
    echo ""
}

# Testar endpoints
test_endpoints() {
    log_info "Testando endpoints..."
    echo ""
    
    # Array de endpoints para testar
    declare -a endpoints=(
        "https://conexaodesorte.com.br|Frontend"
        "https://conexaodesorte.com.br/rest/actuator/health|Backend Produção Health"
        "https://conexaodesorte.com.br/rest/v1/resultados/publico/ultimo/09|Backend Produção API"
        "https://conexaodesorte.com.br/teste/actuator/health|Backend Teste Health"
        "https://conexaodesorte.com.br/teste/v1/resultados/publico/ultimo/09|Backend Teste API"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        IFS='|' read -r url description <<< "$endpoint_info"
        
        echo -n "🧪 Testando $description: "
        
        if curl -f -s --max-time 10 "$url" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ OK${NC}"
        else
            echo -e "${RED}❌ FALHOU${NC}"
            
            # Tentar diagnóstico adicional
            local status_code
            status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
            echo "   Status Code: $status_code"
        fi
    done
    echo ""
}

# Verificar logs dos containers
check_container_logs() {
    log_info "Verificando logs dos containers (últimas 10 linhas)..."
    echo ""
    
    local containers=("traefik" "backend-prod" "backend-teste" "frontend-prod")
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            echo "📋 Logs do $container:"
            docker logs "$container" --tail 10 2>/dev/null || log_warning "Não foi possível obter logs do $container"
            echo ""
        else
            log_warning "Container $container não encontrado"
        fi
    done
}

# Função para reiniciar Traefik
restart_traefik() {
    log_warning "Reiniciando Traefik..."
    
    # Parar Traefik atual
    docker stop traefik 2>/dev/null || true
    docker rm traefik 2>/dev/null || true
    
    # Garantir rede
    docker network create traefik-network 2>/dev/null || true
    
    # Reiniciar Traefik
    docker run -d \
        --name traefik \
        --network traefik-network \
        --restart unless-stopped \
        -p 80:80 \
        -p 443:443 \
        -p 8080:8080 \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v traefik_certs:/certs \
        --label "traefik.enable=true" \
        --label "traefik.http.routers.traefik.rule=Host(\`localhost\`)" \
        --label "traefik.http.routers.traefik.entrypoints=web" \
        --label "traefik.http.services.traefik.loadbalancer.server.port=8080" \
        traefik:v3.0 \
        --api.dashboard=true \
        --api.insecure=true \
        --providers.docker=true \
        --providers.docker.exposedbydefault=false \
        --providers.docker.network=traefik-network \
        --entrypoints.web.address=:80 \
        --entrypoints.websecure.address=:443 \
        --certificatesresolvers.letsencrypt.acme.httpchallenge=true \
        --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web \
        --certificatesresolvers.letsencrypt.acme.email=wibson82@hotmail.com \
        --certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json \
        --log.level=INFO
    
    log_success "Traefik reiniciado. Aguardando inicialização..."
    sleep 15
}

# Função principal
main() {
    echo "🔍 Verificação de Rotas Traefik - Conexão de Sorte"
    echo "=================================================="
    echo ""
    
    # Verificações básicas
    check_docker
    check_containers
    check_networks
    
    # Verificações do Traefik
    if ! check_traefik; then
        echo ""
        read -p "Traefik não está rodando. Deseja reiniciá-lo? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            restart_traefik
            check_traefik
        else
            log_error "Traefik não está funcionando. Abortando verificações."
            exit 1
        fi
    fi
    
    check_traefik_routers
    check_traefik_services
    
    # Testes de conectividade
    test_endpoints
    
    # Logs (opcional)
    echo ""
    read -p "Deseja ver os logs dos containers? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        check_container_logs
    fi
    
    echo ""
    log_success "Verificação concluída!"
    echo ""
    echo "📊 Resumo:"
    echo "- Acesse o dashboard do Traefik: http://localhost:8080"
    echo "- Frontend: https://conexaodesorte.com.br"
    echo "- Backend Produção: https://conexaodesorte.com.br/rest"
    echo "- Backend Teste: https://conexaodesorte.com.br/teste"
}

# Verificar argumentos
case "${1:-}" in
    --restart-traefik)
        restart_traefik
        ;;
    --test-only)
        test_endpoints
        ;;
    --logs-only)
        check_container_logs
        ;;
    *)
        main
        ;;
esac
