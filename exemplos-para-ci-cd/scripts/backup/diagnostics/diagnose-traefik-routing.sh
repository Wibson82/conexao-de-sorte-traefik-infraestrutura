#!/bin/bash
# =============================================================================
# DIAGNÓSTICO DE ROTEAMENTO TRAEFIK - AMBIENTE DE TESTE
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔍 DIAGNÓSTICO DE ROTEAMENTO TRAEFIK"
echo "===================================="

# 1. Verificar containers
log_info "1. Verificando containers..."
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|backend-teste|traefik)"

# 2. Verificar redes
log_info "2. Verificando redes Docker..."
echo ""
echo "Rede conexao-network:"
docker network inspect conexao-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || log_error "Rede conexao-network não encontrada"

# 3. Verificar roteadores Traefik
log_info "3. Verificando roteadores Traefik..."
echo ""
echo "Roteadores HTTP:"
curl -s http://localhost:8080/api/http/routers 2>/dev/null | jq -r '.[] | select(.name | contains("backend-teste")) | "\(.name): \(.rule)"' 2>/dev/null || {
    log_warning "jq não disponível, usando grep:"
    curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -E "(backend-teste|name|rule)" || log_error "Falha ao acessar API do Traefik"
}

# 4. Verificar serviços Traefik
log_info "4. Verificando serviços Traefik..."
echo ""
echo "Serviços:"
curl -s http://localhost:8080/api/http/services 2>/dev/null | jq -r '.[] | select(.name | contains("backend-teste")) | "\(.name): \(.loadBalancer.servers[0].url)"' 2>/dev/null || {
    log_warning "jq não disponível, usando grep:"
    curl -s http://localhost:8080/api/http/services 2>/dev/null | grep -E "(backend-teste|loadBalancer)" || log_error "Falha ao acessar serviços do Traefik"
}

# 5. Verificar middlewares
log_info "5. Verificando middlewares Traefik..."
echo ""
curl -s http://localhost:8080/api/http/middlewares 2>/dev/null | jq -r '.[] | select(.name | contains("backend-teste")) | "\(.name): \(.stripPrefix.prefixes)"' 2>/dev/null || {
    log_warning "jq não disponível, usando grep:"
    curl -s http://localhost:8080/api/http/middlewares 2>/dev/null | grep -E "(backend-teste|stripPrefix)" || log_error "Nenhum middleware de teste encontrado"
}

# 6. Testar conectividade direta
log_info "6. Testando conectividade direta com backend-teste..."
echo ""
if curl -f --connect-timeout 5 http://localhost:8081/actuator/health > /dev/null 2>&1; then
    log_success "Backend-teste responde diretamente na porta 8081"
    echo "Response:"
    curl -s http://localhost:8081/actuator/health | jq . 2>/dev/null || curl -s http://localhost:8081/actuator/health
else
    log_error "Backend-teste NÃO responde na porta 8081"
fi

# 7. Testar via Traefik
log_info "7. Testando via Traefik..."
echo ""
echo "Testando: http://localhost/teste/rest/actuator/health"
if curl -f --connect-timeout 5 http://localhost/teste/rest/actuator/health > /dev/null 2>&1; then
    log_success "Traefik roteia corretamente para /teste/rest"
    echo "Response:"
    curl -s http://localhost/teste/rest/actuator/health | jq . 2>/dev/null || curl -s http://localhost/teste/rest/actuator/health
else
    log_error "Traefik NÃO roteia para /teste/rest"
    echo "Resposta do Traefik:"
    curl -s http://localhost/teste/rest/actuator/health || echo "Sem resposta"
fi

# 8. Verificar logs do Traefik
log_info "8. Verificando logs do Traefik (últimas 10 linhas)..."
echo ""
docker logs traefik --tail 10 2>/dev/null || log_error "Falha ao acessar logs do Traefik"

# 9. Verificar labels do container backend-teste
log_info "9. Verificando labels do container backend-teste..."
echo ""
docker inspect backend-teste --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}: {{$value}}{{"\n"}}{{end}}{{end}}' 2>/dev/null || log_error "Container backend-teste não encontrado"

echo ""
log_info "🔍 Diagnóstico concluído!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Se backend-teste responde diretamente mas Traefik não roteia:"
echo "      → Problema nos labels Traefik"
echo "   2. Se backend-teste não responde diretamente:"
echo "      → Problema no container ou rede"
echo "   3. Se roteadores não aparecem na API:"
echo "      → Labels não foram aplicados corretamente"
