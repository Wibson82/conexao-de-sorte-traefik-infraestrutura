#!/bin/bash

# =============================================================================
# DEPLOY COMPLETO DE PRODUÇÃO - SEGUINDO DIRETRIZES DO PROJETO
# =============================================================================
# Este script implementa o deploy completo seguindo exatamente as diretrizes:
# 1. Backend de produção na porta 8080
# 2. Backend de teste na porta 8081  
# 3. Traefik com configuração centralizada
# 4. Roteamento conforme especificado nas diretrizes
# 5. Sequência correta: Traefik → Backend Prod → Backend Teste
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
DOMAIN_PRIMARY="conexaodesorte.com.br"
DOMAIN_WWW="www.conexaodesorte.com.br"

log_info "🚀 Iniciando deploy completo de produção..."
log_info "📦 Tag da imagem: $IMAGE_TAG"
log_info "🌐 Domínios: $DOMAIN_PRIMARY, $DOMAIN_WWW"

# =============================================================================
# FASE 1: PREPARAÇÃO DA INFRAESTRUTURA
# =============================================================================
log_info "🏗️ FASE 1: Preparando infraestrutura..."

# Garantir rede
log_info "🌐 Garantindo rede conexao-network..."
docker network create conexao-network 2>/dev/null || true

# Parar containers antigos (exceto MySQL e Prometheus)
log_info "🛑 Parando containers antigos..."
docker stop traefik backend-prod backend-teste frontend-prod 2>/dev/null || true
docker rm traefik backend-prod backend-teste frontend-prod 2>/dev/null || true

# =============================================================================
# FASE 2: CONFIGURAR TRAEFIK (CONFIGURAÇÃO CENTRALIZADA)
# =============================================================================
log_info "🌐 FASE 2: Configurando Traefik com configuração centralizada..."

log_info "🔧 Criando Traefik com configuração das diretrizes..."
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
  --log.level=INFO --accesslog=true --log.format=json \
  --accesslog.format=json --accesslog.fields.defaultmode=keep \
  --accesslog.fields.headers.defaultmode=keep \
  --serverstransport.insecureskipverify=false \
  --global.sendanonymoususage=false

log_success "Traefik criado com configuração centralizada!"

# Aguardar Traefik inicializar
log_info "⏳ Aguardando Traefik inicializar..."
sleep 30

# Verificar API do Traefik
for i in {1..10}; do
    if curl -f http://localhost:8090/api/http/routers 2>/dev/null >/dev/null; then
        log_success "API do Traefik disponível na porta 8090!"
        break
    fi
    log_info "Tentativa $i/10 - aguardando API do Traefik..."
    sleep 5
done

# =============================================================================
# FASE 3: DEPLOY BACKEND DE PRODUÇÃO (PRIORIDADE)
# =============================================================================
log_info "🚀 FASE 3: Deploy do Backend de Produção..."

# Pull da imagem de produção
log_info "📦 Fazendo pull da imagem de produção..."
docker pull "facilita/conexao-de-sorte-backend:$IMAGE_TAG" || {
    log_error "Falha ao fazer pull da imagem de produção"
    exit 1
}

# Criar backend de produção com labels das diretrizes
log_info "🚀 Criando Backend de Produção (porta 8080)..."
docker run -d \
  --name backend-prod \
  --network conexao-network \
  --restart unless-stopped \
  --health-cmd='curl -f http://localhost:8080/actuator/health || exit 1' \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
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

log_success "Backend de Produção criado!"

# Aguardar inicialização do backend de produção
log_info "⏳ Aguardando Backend de Produção inicializar..."
sleep 60

# Verificar backend de produção
for i in {1..15}; do
    if docker exec backend-prod curl -f http://localhost:8080/actuator/health 2>/dev/null; then
        log_success "Backend de Produção respondendo!"
        break
    fi
    log_info "Tentativa $i/15 - aguardando backend de produção..."
    sleep 10
done

# =============================================================================
# FASE 4: DEPLOY BACKEND DE TESTE
# =============================================================================
log_info "🧪 FASE 4: Deploy do Backend de Teste..."

# Criar backend de teste com labels das diretrizes
log_info "🧪 Criando Backend de Teste (porta 8081)..."
docker run -d \
  --name backend-teste \
  --network conexao-network \
  --restart unless-stopped \
  --health-cmd='curl -f http://localhost:8081/actuator/health || exit 1' \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
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

log_success "Backend de Teste criado!"

# Aguardar inicialização do backend de teste
log_info "⏳ Aguardando Backend de Teste inicializar..."
sleep 60

# =============================================================================
# FASE 5: RECRIAR FRONTEND COM LABELS CORRETOS
# =============================================================================
log_info "🌐 FASE 5: Recriando Frontend com labels corretos..."

# Recriar frontend com labels das diretrizes
log_info "🌐 Recriando Frontend com labels das diretrizes..."
docker run -d \
  --name frontend-prod \
  --network conexao-network \
  --restart unless-stopped \
  --health-cmd='curl -f http://localhost:3000/ || exit 1' \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  -e TZ=America/Sao_Paulo \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.frontend-https.rule=(Host(\`$DOMAIN_PRIMARY\`) || Host(\`$DOMAIN_WWW\`)) && !PathPrefix(\`/rest\`) && !PathPrefix(\`/teste\`)" \
  --label "traefik.http.routers.frontend-https.entrypoints=websecure" \
  --label "traefik.http.routers.frontend-https.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.frontend-https.priority=1" \
  --label "traefik.http.services.frontend-prod.loadbalancer.server.port=3000" \
  facilita/conexao-de-sorte-frontend:latest

log_success "Frontend recriado com labels corretos!"

# =============================================================================
# FASE 6: VERIFICAÇÃO FINAL
# =============================================================================
log_info "📊 FASE 6: Verificação final..."

# Aguardar estabilização completa
log_info "⏳ Aguardando estabilização completa..."
sleep 60

# Status dos containers
log_info "📊 Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|backend|traefik|frontend)"

# Verificar roteadores no Traefik
log_info "🌐 Verificando roteadores no Traefik..."
if curl -s http://localhost:8090/api/http/routers | grep -q "backend-prod"; then
    log_success "Roteadores do backend de produção detectados!"
else
    log_warning "Roteadores do backend de produção não detectados ainda"
fi

if curl -s http://localhost:8090/api/http/routers | grep -q "backend-teste"; then
    log_success "Roteadores do backend de teste detectados!"
else
    log_warning "Roteadores do backend de teste não detectados ainda"
fi

if curl -s http://localhost:8090/api/http/routers | grep -q "frontend"; then
    log_success "Roteadores do frontend detectados!"
else
    log_warning "Roteadores do frontend não detectados ainda"
fi

# =============================================================================
# RESUMO FINAL
# =============================================================================
log_success "🎉 Deploy completo de produção finalizado!"

log_info "📋 RESUMO DO DEPLOY:"
log_info "   🌐 Traefik: Dashboard na porta 8090"
log_info "   🚀 Backend Produção: porta 8080"
log_info "   🧪 Backend Teste: porta 8081"
log_info "   🌐 Frontend: porta 3000"

log_info "🌐 URLs para testar (aguarde alguns minutos para propagação):"
log_info "   🚀 Produção API: https://$DOMAIN_WWW/rest/actuator/health"
log_info "   🌐 Produção Público: https://$DOMAIN_WWW/v1/resultados/publico/ultimo/rio"
log_info "   🧪 Teste API: https://$DOMAIN_WWW/teste/rest/actuator/health"
log_info "   🌐 Frontend: https://$DOMAIN_WWW/"
log_info "   🔧 Traefik Dashboard: http://srv649924.hstgr.cloud:8090/"

log_info "💡 Roteamento implementado conforme diretrizes do projeto:"
log_info "   [300] Backend Prod (Público): /v1/publico, /v1/resultados/publico, etc"
log_info "   [200] Backend Prod (API): /rest → backend-prod:8080"
log_info "   [100] Backend Teste: /teste/rest → backend-teste:8081"
log_info "   [1]   Frontend: / (catch-all - exceto /rest e /teste)"
