#!/bin/bash
# =============================================================================
# TESTE LOCAL - ROTEAMENTO CENTRALIZADO
# =============================================================================
# Script para testar a implementação consolidada localmente

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configurações
COMPOSE_FILE="docker-compose.proxy.yml"
ENV_FILE=".env"
NETWORK_NAME="conexao-network"

main() {
    echo "🚀 Testando Roteamento Centralizado - Conexão de Sorte"
    echo "================================================="
    
    # Verificações pré-requisitos
    check_prerequisites
    
    # Setup ambiente
    setup_environment
    
    # Criar rede externa se não existir
    create_network
    
    # Iniciar serviços
    start_services
    
    # Executar testes
    run_tests
    
    # Exibir status
    show_status
    
    echo ""
    echo "✅ Teste concluído! Verifique os resultados acima."
    echo "🌐 Dashboard Traefik: http://localhost:8090"
    echo "📊 Prometheus: http://localhost:9090"
    echo "📈 Grafana: http://localhost:3001 (admin/admin123)"
}

check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi
    
    # Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose não encontrado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    # Arquivo compose
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Arquivo $COMPOSE_FILE não encontrado."
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

setup_environment() {
    log_info "Configurando ambiente..."
    
    # Criar .env se não existir
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning ".env não encontrado, criando a partir do exemplo..."
        cp .env.example "$ENV_FILE"
        
        # Configurações para teste local
        cat >> "$ENV_FILE" << EOF

# Configurações de teste local
ENVIRONMENT=test
HTTP_PORT=8080
HTTPS_PORT=8443
DASHBOARD_PORT=8090
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
DOMAIN=localhost
EOF
    fi
    
    log_success "Ambiente configurado"
}

create_network() {
    log_info "Verificando rede $NETWORK_NAME..."
    
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        log_info "Criando rede $NETWORK_NAME..."
        docker network create "$NETWORK_NAME" || true
        log_success "Rede $NETWORK_NAME criada"
    else
        log_success "Rede $NETWORK_NAME já existe"
    fi
}

start_services() {
    log_info "Iniciando serviços..."
    
    # Parar serviços existentes
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    
    # Iniciar serviços
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Aguardar serviços ficarem prontos
    log_info "Aguardando serviços ficarem prontos..."
    sleep 30
    
    log_success "Serviços iniciados"
}

run_tests() {
    log_info "Executando testes..."
    
    # Teste 1: Traefik Dashboard
    test_endpoint "http://localhost:8090/ping" "Traefik Ping"
    
    # Teste 2: Prometheus
    test_endpoint "http://localhost:9090/-/healthy" "Prometheus Health"
    
    # Teste 3: Grafana
    test_endpoint "http://localhost:3001/api/health" "Grafana Health"
    
    # Teste 4: Métricas do Traefik
    test_endpoint "http://localhost:8090/metrics" "Traefik Metrics"
    
    log_success "Testes de conectividade concluídos"
}

test_endpoint() {
    local url=$1
    local name=$2
    
    log_info "Testando $name: $url"
    
    if curl -s -f "$url" > /dev/null; then
        log_success "$name ✅"
    else
        log_error "$name ❌"
    fi
}

show_status() {
    log_info "Status dos containers:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo ""
    log_info "Logs recentes do Traefik:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=5 traefik
}

# Função de limpeza
cleanup() {
    log_warning "Parando serviços..."
    docker-compose -f "$COMPOSE_FILE" down
}

# Trap para limpeza em caso de interrupção
trap cleanup EXIT

# Executar função principal
main "$@"