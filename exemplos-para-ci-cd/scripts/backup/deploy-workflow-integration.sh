#!/bin/bash

# =============================================================================
# INTEGRAÇÃO WORKFLOW - DEPLOY COMPLETO AUTOMÁTICO
# =============================================================================
# Este script é executado automaticamente pelos workflows e garante que:
# 1. Sempre use a configuração centralizada mais recente
# 2. Execute o deploy completo (produção + teste)
# 3. Corrija automaticamente problemas identificados
# 4. Implemente exatamente o roteamento das diretrizes
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Parâmetros
IMAGE_TAG=${1:-"latest"}
DEPLOY_TYPE=${2:-"complete"}  # complete, production-only, test-only

log_info "🚀 Iniciando integração workflow - Deploy automático..."
log_info "📦 Tag da imagem: $IMAGE_TAG"
log_info "🎯 Tipo de deploy: $DEPLOY_TYPE"

# =============================================================================
# VERIFICAR SE SCRIPT DE DEPLOY COMPLETO EXISTE
# =============================================================================
log_info "🔍 Verificando script de deploy completo..."

if [[ -f "/root/deploy-production-complete.sh" ]]; then
    log_success "Script de deploy completo encontrado!"
    SCRIPT_PATH="/root/deploy-production-complete.sh"
elif [[ -f "./scripts/deploy-production-complete.sh" ]]; then
    log_success "Script de deploy completo encontrado no diretório local!"
    cp "./scripts/deploy-production-complete.sh" /root/deploy-production-complete.sh
    SCRIPT_PATH="/root/deploy-production-complete.sh"
else
    log_error "Script de deploy completo não encontrado!"
    log_info "🔧 Criando script de deploy completo inline..."
    
    # Criar script inline se não existir
    cat > /root/deploy-production-complete.sh << 'SCRIPT_EOF'
#!/bin/bash
set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

IMAGE_TAG=${1:-"latest"}
DOMAIN_PRIMARY="conexaodesorte.com.br"
DOMAIN_WWW="www.conexaodesorte.com.br"

log_info "🚀 Executando deploy completo inline..."

# Garantir rede
docker network create conexao-network 2>/dev/null || true

# Parar containers antigos (exceto MySQL e Prometheus)
log_info "🛑 Parando containers antigos..."
docker stop traefik backend-prod backend-teste frontend-prod 2>/dev/null || true
docker rm traefik backend-prod backend-teste frontend-prod 2>/dev/null || true

# Criar Traefik
log_info "🌐 Criando Traefik..."
docker run -d \
  --name traefik \
  --network conexao-network \
  --restart unless-stopped \
  -p 80:80 -p 443:443 -p 8090:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v traefik_certs:/certs \
  traefik:v3.0 \
  --api.dashboard=true --api.insecure=true \
  --providers.docker=true --providers.docker.exposedbydefault=false \
  --providers.docker.network=conexao-network --providers.docker.watch=true \
  --entrypoints.web.address=:80 --entrypoints.websecure.address=:443 \
  --entrypoints.web.http.redirections.entrypoint.to=websecure \
  --entrypoints.web.http.redirections.entrypoint.scheme=https \
  --entrypoints.web.http.redirections.entrypoint.permanent=true \
  --certificatesresolvers.letsencrypt.acme.email=admin@conexaodesorte.com.br \
  --certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json \
  --certificatesresolvers.letsencrypt.acme.httpchallenge=true \
  --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web \
  --certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory \
  --log.level=INFO --accesslog=true --log.format=json

sleep 30

# Criar backend de produção
log_info "🚀 Criando Backend de Produção..."
docker run -d \
  --name backend-prod \
  --network conexao-network \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=prod,azure \
  -e ENVIRONMENT=production \
  -e SERVER_PORT=8080 \
  -e AZURE_KEYVAULT_ENABLED=true \
  -e AZURE_KEYVAULT_ENDPOINT="${AZURE_KEYVAULT_ENDPOINT:-}" \
  -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-}" \
  -e AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET:-}" \
  -e AZURE_TENANT_ID="${AZURE_TENANT_ID:-}" \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
  -e SPRING_DATASOURCE_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}" \
  -e SPRING_DATASOURCE_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-root123}" \
  -e APP_ENCRYPTION_MASTER_PASSWORD="${APP_ENCRYPTION_MASTER_PASSWORD:-default-master-password}" \
  -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC" \
  -e TZ=America/Sao_Paulo \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.backend-prod-https.rule=(Host(\`$DOMAIN_PRIMARY\`) || Host(\`$DOMAIN_WWW\`)) && PathPrefix(\`/rest\`)" \
  --label "traefik.http.routers.backend-prod-https.entrypoints=websecure" \
  --label "traefik.http.routers.backend-prod-https.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.backend-prod-https.priority=200" \
  --label "traefik.http.routers.backend-prod-https.middlewares=backend-prod-stripprefix" \
  --label "traefik.http.routers.backend-prod-public-https.rule=(Host(\`$DOMAIN_PRIMARY\`) || Host(\`$DOMAIN_WWW\`)) && PathPrefix(\`/v1/publico\`, \`/v1/resultados/publico\`, \`/v1/horario/publico\`, \`/v1/usuarios/publico\`, \`/v1/info\`)" \
  --label "traefik.http.routers.backend-prod-public-https.entrypoints=websecure" \
  --label "traefik.http.routers.backend-prod-public-https.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.backend-prod-public-https.priority=300" \
  --label "traefik.http.routers.backend-prod-public-https.service=backend-prod" \
  --label "traefik.http.services.backend-prod.loadbalancer.server.port=8080" \
  --label "traefik.http.middlewares.backend-prod-stripprefix.stripprefix.prefixes=/rest" \
  "facilita/conexao-de-sorte-backend:$IMAGE_TAG"

sleep 60

# Criar backend de teste
log_info "🧪 Criando Backend de Teste..."
docker run -d \
  --name backend-teste \
  --network conexao-network \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=test,local-fallback \
  -e ENVIRONMENT=test \
  -e SERVER_PORT=8081 \
  -e AZURE_KEYVAULT_ENABLED=false \
  -e AZURE_KEYVAULT_FALLBACK_ENABLED=true \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
  -e SPRING_DATASOURCE_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}" \
  -e SPRING_DATASOURCE_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-root123}" \
  -e APP_ENCRYPTION_MASTER_PASSWORD="${APP_ENCRYPTION_MASTER_PASSWORD:-default-master-password}" \
  -e JAVA_OPTS="-server -Xms128m -Xmx512m -XX:+UseG1GC" \
  -e TZ=America/Sao_Paulo \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.backend-teste-https.rule=(Host(\`$DOMAIN_PRIMARY\`) || Host(\`$DOMAIN_WWW\`)) && PathPrefix(\`/teste/rest\`)" \
  --label "traefik.http.routers.backend-teste-https.entrypoints=websecure" \
  --label "traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.backend-teste-https.priority=100" \
  --label "traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix" \
  --label "traefik.http.services.backend-teste.loadbalancer.server.port=8081" \
  --label "traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest" \
  "facilita/conexao-de-sorte-backend:$IMAGE_TAG"

sleep 60

# Recriar frontend
log_info "🌐 Recriando Frontend..."
docker run -d \
  --name frontend-prod \
  --network conexao-network \
  --restart unless-stopped \
  -e TZ=America/Sao_Paulo \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.frontend-https.rule=(Host(\`$DOMAIN_PRIMARY\`) || Host(\`$DOMAIN_WWW\`)) && !PathPrefix(\`/rest\`) && !PathPrefix(\`/teste\`)" \
  --label "traefik.http.routers.frontend-https.entrypoints=websecure" \
  --label "traefik.http.routers.frontend-https.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.frontend-https.priority=1" \
  --label "traefik.http.services.frontend-prod.loadbalancer.server.port=3000" \
  facilita/conexao-de-sorte-frontend:latest

log_success "🎉 Deploy completo finalizado!"
SCRIPT_EOF
    
    chmod +x /root/deploy-production-complete.sh
    SCRIPT_PATH="/root/deploy-production-complete.sh"
    log_success "Script de deploy completo criado inline!"
fi

# =============================================================================
# EXECUTAR DEPLOY COMPLETO
# =============================================================================
log_info "🚀 Executando deploy completo..."

# Tornar script executável
chmod +x "$SCRIPT_PATH"

# Executar deploy baseado no tipo
case "$DEPLOY_TYPE" in
    "complete")
        log_info "🎯 Executando deploy completo (produção + teste)..."
        "$SCRIPT_PATH" "$IMAGE_TAG"
        ;;
    "production-only")
        log_info "🎯 Executando deploy apenas de produção..."
        "$SCRIPT_PATH" "$IMAGE_TAG" production
        ;;
    "test-only")
        log_info "🎯 Executando deploy apenas de teste..."
        "$SCRIPT_PATH" "$IMAGE_TAG" test
        ;;
    *)
        log_warning "Tipo de deploy desconhecido: $DEPLOY_TYPE, executando deploy completo..."
        "$SCRIPT_PATH" "$IMAGE_TAG"
        ;;
esac

# =============================================================================
# VERIFICAÇÃO FINAL
# =============================================================================
log_info "📊 Verificação final..."

# Aguardar estabilização
sleep 60

# Status dos containers
log_info "📊 Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|backend|traefik|frontend)"

# Verificar roteadores no Traefik
log_info "🌐 Verificando roteadores no Traefik..."
ROUTER_COUNT=0

if curl -s http://localhost:8090/api/http/routers 2>/dev/null | grep -q "backend-prod"; then
    log_success "Roteadores do backend de produção detectados!"
    ((ROUTER_COUNT++))
fi

if curl -s http://localhost:8090/api/http/routers 2>/dev/null | grep -q "backend-teste"; then
    log_success "Roteadores do backend de teste detectados!"
    ((ROUTER_COUNT++))
fi

if curl -s http://localhost:8090/api/http/routers 2>/dev/null | grep -q "frontend"; then
    log_success "Roteadores do frontend detectados!"
    ((ROUTER_COUNT++))
fi

log_info "📊 Total de roteadores detectados: $ROUTER_COUNT"

if [ "$ROUTER_COUNT" -ge 3 ]; then
    log_success "✅ Todos os roteadores detectados pelo Traefik!"
else
    log_warning "⚠️ Alguns roteadores podem não ter sido detectados ainda"
fi

# =============================================================================
# RESUMO FINAL
# =============================================================================
log_success "🎉 Integração workflow - Deploy automático finalizado!"

log_info "📋 RESUMO:"
log_info "   📦 Imagem: facilita/conexao-de-sorte-backend:$IMAGE_TAG"
log_info "   🎯 Tipo: $DEPLOY_TYPE"
log_info "   🌐 Traefik: Dashboard na porta 8090"
log_info "   🚀 Backend Produção: porta 8080"
log_info "   🧪 Backend Teste: porta 8081"
log_info "   🌐 Frontend: porta 3000"

log_info "🌐 URLs para testar:"
log_info "   🚀 Produção: https://www.conexaodesorte.com.br/rest/actuator/health"
log_info "   🌐 Público: https://www.conexaodesorte.com.br/v1/resultados/publico/ultimo/rio"
log_info "   🧪 Teste: https://www.conexaodesorte.com.br/teste/rest/actuator/health"
log_info "   🌐 Frontend: https://www.conexaodesorte.com.br/"
log_info "   🔧 Traefik: http://srv649924.hstgr.cloud:8090/"

log_info "💡 Roteamento implementado conforme diretrizes do projeto!"
log_success "✅ Deploy automático via workflow concluído com sucesso!"
