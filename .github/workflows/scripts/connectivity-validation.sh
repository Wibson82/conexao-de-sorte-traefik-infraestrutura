#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🌐 TRAEFIK CONNECTIVITY VALIDATION SCRIPT
# =============================================================================
# Validates network connectivity and service health for Traefik infrastructure

echo "🌐 Iniciando validação de conectividade do Traefik..."

STACK_NAME=${STACK_NAME:-conexao-traefik}
TIMEOUT=${TIMEOUT:-300}
CHECK_INTERVAL=${CHECK_INTERVAL:-10}

# =============================================================================
# Helper Functions
# =============================================================================
log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️  $1"
}

log_error() {
    echo "❌ $1"
}

wait_for_condition() {
    local condition_cmd="$1"
    local description="$2"
    local timeout="$3"
    local interval="${4:-5}"

    local elapsed=0
    log_info "Aguardando: $description..."

    while [ $elapsed -lt $timeout ]; do
        if eval "$condition_cmd" >/dev/null 2>&1; then
            log_success "$description - OK ($elapsed segundos)"
            return 0
        fi

        echo "⏳ $description... ($elapsed/$timeout segundos)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    log_error "$description - TIMEOUT após $timeout segundos"
    return 1
}

# =============================================================================
# Pre-deployment Checks
# =============================================================================
echo ""
echo "🔍 [1/6] Verificações pré-deploy..."

# Check Docker Swarm
if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
    log_success "Docker Swarm ativo"
else
    log_error "Docker Swarm não está ativo"
    exit 1
fi

# Check network
if docker network ls | grep -q "conexao-network-swarm"; then
    log_success "Rede conexao-network-swarm existe"
else
    log_warning "Criando rede conexao-network-swarm..."
    docker network create --driver overlay conexao-network-swarm || {
        log_error "Falha ao criar rede"
        exit 1
    }
fi

# =============================================================================
# Service Deployment Validation
# =============================================================================
echo ""
echo "🚀 [2/6] Validação do deploy do serviço..."

# Wait for service to be created
wait_for_condition \
    "docker service ls --filter name=${STACK_NAME}_traefik --format '{{.Name}}' | grep -q traefik" \
    "Serviço ${STACK_NAME}_traefik criado" \
    60

# Wait for service to reach desired state
wait_for_condition \
    "docker service ls --filter name=${STACK_NAME}_traefik --format '{{.Replicas}}' | grep -q '1/1'" \
    "Serviço ${STACK_NAME}_traefik em estado 1/1" \
    $TIMEOUT \
    $CHECK_INTERVAL

# =============================================================================
# Container Health Validation
# =============================================================================
echo ""
echo "🏥 [3/6] Validação de saúde do container..."

# Get container ID
CONTAINER_ID=""
for i in {1..30}; do
    CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=${STACK_NAME}_traefik" --format "{{.ID}}" | head -1 || echo "")
    if [ -n "$CONTAINER_ID" ]; then
        break
    fi
    echo "⏳ Aguardando container... ($i/30)"
    sleep 2
done

if [ -z "$CONTAINER_ID" ]; then
    log_error "Container Traefik não encontrado"
    exit 1
fi

log_success "Container Traefik encontrado: $CONTAINER_ID"

# Wait for container to be healthy
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "healthy"; then
    wait_for_condition \
        "docker inspect $CONTAINER_ID --format='{{.State.Health.Status}}' | grep -q healthy" \
        "Container Traefik saudável" \
        120 \
        5
fi

# =============================================================================
# Network Connectivity Tests
# =============================================================================
echo ""
echo "🌐 [4/6] Testes de conectividade de rede..."

# Test container network connectivity
log_info "Verificando redes do container..."
NETWORKS=$(docker inspect $CONTAINER_ID --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}')
log_info "Redes conectadas: $NETWORKS"

# Test Traefik API endpoint
log_info "Testando endpoint da API do Traefik..."
if docker exec $CONTAINER_ID wget -q --spider http://localhost:8080/api/rawdata 2>/dev/null; then
    log_success "API do Traefik acessível"
else
    log_warning "API do Traefik não acessível (pode estar desabilitada)"
fi

# Test ping endpoint
log_info "Testando endpoint de ping..."
if docker exec $CONTAINER_ID wget -q --spider http://localhost:8080/ping 2>/dev/null; then
    log_success "Ping endpoint OK"
else
    log_error "Ping endpoint falhou"
    exit 1
fi

# =============================================================================
# Port Accessibility Tests
# =============================================================================
echo ""
echo "🔌 [5/6] Testes de acessibilidade das portas..."

# Test HTTP port (80)
if netstat -tuln | grep -q ":80 "; then
    log_success "Porta 80 (HTTP) acessível"
else
    log_error "Porta 80 (HTTP) não acessível"
    exit 1
fi

# Test HTTPS port (443)
if netstat -tuln | grep -q ":443 "; then
    log_success "Porta 443 (HTTPS) acessível"
else
    log_error "Porta 443 (HTTPS) não acessível"
    exit 1
fi

# =============================================================================
# Service Discovery Tests
# =============================================================================
echo ""
echo "🔍 [6/6] Testes de descoberta de serviços..."

# Test Docker provider
log_info "Testando descoberta de serviços Docker..."
if docker exec $CONTAINER_ID wget -q --spider http://localhost:8080/api/providers/docker 2>/dev/null; then
    log_success "Provider Docker ativo"
else
    log_warning "Provider Docker pode não estar acessível"
fi

# =============================================================================
# Final Status Report
# =============================================================================
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "📊 RELATÓRIO FINAL DE CONECTIVIDADE"
echo "════════════════════════════════════════════════════════════════════"

# Service status
SERVICE_STATUS=$(docker service ls --filter name=${STACK_NAME}_traefik --format "{{.Replicas}}")
log_info "Status do serviço: $SERVICE_STATUS"

# Container status
CONTAINER_STATUS=$(docker ps --filter id=$CONTAINER_ID --format "{{.Status}}")
log_info "Status do container: $CONTAINER_STATUS"

# Final logs sample
echo ""
log_info "Últimos logs do serviço:"
docker service logs ${STACK_NAME}_traefik --tail 10 2>/dev/null || echo "Logs não disponíveis"

echo ""
log_success "🎉 Validação de conectividade concluída com sucesso!"
echo ""
echo "🌍 Endpoints disponíveis:"
echo "  - HTTP: http://localhost:80"
echo "  - HTTPS: https://localhost:443"
echo "  - API: http://localhost:8080 (se habilitada)"
echo ""