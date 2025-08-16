#!/bin/bash
# =============================================================================
# CORREÇÃO DE LABELS TRAEFIK - AMBIENTE DE TESTE
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

echo "🔧 CORREÇÃO DE LABELS TRAEFIK - BACKEND-TESTE"
echo "============================================="

# Verificar se container existe
if ! docker ps | grep -q backend-teste; then
    log_error "Container backend-teste não está rodando"
    exit 1
fi

# Obter informações do container
CONTAINER_ID=$(docker ps --filter "name=backend-teste" --format "{{.ID}}")
IMAGE_NAME=$(docker ps --filter "name=backend-teste" --format "{{.Image}}")

log_info "Container encontrado: $CONTAINER_ID"
log_info "Imagem: $IMAGE_NAME"

# Parar container atual
log_info "Parando container backend-teste atual..."
docker stop backend-teste
docker rm backend-teste

# Recriar container com labels corretos
log_info "Recriando container com labels Traefik corretos..."

docker run -d \
  --name backend-teste \
  --network conexao-network \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=prod,azure \
  -e ENVIRONMENT=prod \
  -e SERVER_PORT=8081 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
  -e SPRING_DATASOURCE_USERNAME="${DB_USERNAME:-root}" \
  -e SPRING_DATASOURCE_PASSWORD="${DB_PASSWORD:-password}" \
  -e AZURE_KEYVAULT_ENABLED=true \
  -e AZURE_KEYVAULT_ENDPOINT="${AZURE_KEYVAULT_ENDPOINT:-}" \
  -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-}" \
  -e AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET:-}" \
  -e AZURE_TENANT_ID="${AZURE_TENANT_ID:-}" \
  -e APP_ENCRYPTION_MASTER_PASSWORD="${APP_ENCRYPTION_MASTER_PASSWORD:-}" \
  -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC" \
  --label traefik.enable=true \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.backend-teste-http.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)" \
  --label traefik.http.routers.backend-teste-http.entrypoints=web \
  --label traefik.http.routers.backend-teste-http.priority=100 \
  --label traefik.http.routers.backend-teste-http.middlewares=backend-teste-stripprefix \
  --label "traefik.http.routers.backend-teste-https.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)" \
  --label traefik.http.routers.backend-teste-https.entrypoints=websecure \
  --label traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt \
  --label traefik.http.routers.backend-teste-https.priority=100 \
  --label traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix \
  --label traefik.http.services.backend-teste.loadbalancer.server.port=8081 \
  --label "traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest" \
  $IMAGE_NAME

log_success "Container backend-teste recriado com labels corretos"

# Aguardar inicialização
log_info "Aguardando inicialização do container..."
sleep 30

# Verificar se está funcionando
if docker ps | grep -q backend-teste; then
    log_success "Container backend-teste está rodando"
    
    # Testar health check
    log_info "Testando health check..."
    for i in {1..10}; do
        if curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
            log_success "Health check OK"
            break
        else
            echo "Tentativa $i/10..."
            sleep 5
        fi
    done
    
    # Verificar roteadores Traefik
    log_info "Verificando roteadores Traefik..."
    sleep 10
    curl -s http://localhost:8080/api/http/routers | grep -E "(backend-teste|name|rule)" || log_warning "Roteadores não encontrados ainda"
    
else
    log_error "Container não está rodando"
    docker logs backend-teste --tail 20
fi

echo ""
log_info "🔧 Correção concluída!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Aguardar alguns minutos para Traefik detectar o container"
echo "   2. Testar: curl http://localhost/teste/rest/actuator/health"
echo "   3. Testar: https://conexaodesorte.com.br/teste/rest/v1/resultados/publico/ultimo/federal"
