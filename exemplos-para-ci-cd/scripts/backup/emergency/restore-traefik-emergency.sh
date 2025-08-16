#!/bin/bash
# =============================================================================
# RECUPERAÇÃO DE EMERGÊNCIA - RESTAURAR TRAEFIK COM CONFIGURAÇÕES FUNCIONAIS
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

echo "🚨 RECUPERAÇÃO DE EMERGÊNCIA - TRAEFIK"
echo "====================================="

log_error "PROBLEMA: Traefik perdeu configurações após atualização"
log_info "SOLUÇÃO: Restaurar Traefik com configurações funcionais"

# 1. Parar Traefik atual
log_info "1. Parando Traefik atual..."
docker stop traefik 2>/dev/null || true
docker rm traefik 2>/dev/null || true

# 2. Verificar containers que precisam de roteamento
log_info "2. Verificando containers que precisam de roteamento..."
echo "Containers encontrados:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "(frontend-prod|backend-prod|backend-teste)"

# 3. Garantir rede conexao-network
log_info "3. Garantindo rede conexao-network..."
docker network create conexao-network 2>/dev/null || log_info "Rede já existe"

# 4. Conectar todos os containers à rede
log_info "4. Conectando containers à rede conexao-network..."
for container in frontend-prod backend-prod backend-teste conexao-mysql; do
    if docker ps | grep -q "$container"; then
        docker network connect conexao-network "$container" 2>/dev/null || log_info "$container já conectado"
        log_success "$container conectado à rede"
    else
        log_warning "$container não está rodando"
    fi
done

# 5. Recriar Traefik com configuração funcional
log_info "5. Recriando Traefik com configuração funcional..."

# Verificar se diretório de configuração existe
if [ ! -d "/root/traefik" ]; then
    log_warning "Diretório /root/traefik não existe, criando..."
    mkdir -p /root/traefik
fi

# Criar configuração básica do Traefik se não existir
if [ ! -f "/root/traefik/traefik.yml" ]; then
    log_info "Criando configuração básica do Traefik..."
    cat > /root/traefik/traefik.yml << 'EOF'
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: conexao-network

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@conexaodesorte.com.br
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

log:
  level: INFO
EOF
    log_success "Configuração básica criada"
fi

# Garantir diretório Let's Encrypt
mkdir -p /root/letsencrypt
chmod 600 /root/letsencrypt/acme.json 2>/dev/null || touch /root/letsencrypt/acme.json && chmod 600 /root/letsencrypt/acme.json

# Recriar Traefik
log_info "Iniciando Traefik com configuração restaurada..."
docker run -d \
  --name traefik \
  --restart unless-stopped \
  --network conexao-network \
  -p 80:80 \
  -p 443:443 \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /root/traefik:/etc/traefik:ro \
  -v /root/letsencrypt:/letsencrypt \
  traefik:v3.0

log_success "Traefik recriado com sucesso"

# 6. Aguardar inicialização
log_info "6. Aguardando Traefik inicializar..."
sleep 30

# 7. Verificar se Traefik está funcionando
if docker ps | grep -q traefik; then
    log_success "Traefik está rodando"
    
    # Testar API
    if curl -f http://localhost:8080/api/http/routers >/dev/null 2>&1; then
        log_success "API do Traefik acessível"
    else
        log_error "API do Traefik não acessível"
    fi
else
    log_error "Traefik não está rodando"
    docker logs traefik --tail 20
    exit 1
fi

# 8. Recriar containers com labels corretos se necessário
log_info "8. Verificando e corrigindo labels dos containers..."

# Frontend
if docker ps | grep -q frontend-prod; then
    FRONTEND_LABELS=$(docker inspect frontend-prod --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}{{"\n"}}{{end}}{{end}}' | wc -l)
    if [ "$FRONTEND_LABELS" -eq 0 ]; then
        log_warning "Frontend sem labels Traefik - recriando..."
        
        docker stop frontend-prod
        docker rm frontend-prod
        
        docker run -d \
          --name frontend-prod \
          --network conexao-network \
          --restart unless-stopped \
          --label traefik.enable=true \
          --label "traefik.docker.network=conexao-network" \
          --label "traefik.http.routers.frontend-http.rule=Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)" \
          --label traefik.http.routers.frontend-http.entrypoints=web \
          --label traefik.http.routers.frontend-http.priority=1 \
          --label "traefik.http.routers.frontend-https.rule=Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)" \
          --label traefik.http.routers.frontend-https.entrypoints=websecure \
          --label traefik.http.routers.frontend-https.tls.certresolver=letsencrypt \
          --label traefik.http.routers.frontend-https.priority=1 \
          --label traefik.http.services.frontend.loadbalancer.server.port=3000 \
          facilita/conexao-de-sorte-frontend:latest
        
        log_success "Frontend recriado com labels"
    else
        log_success "Frontend já tem labels Traefik"
    fi
fi

# Backend Produção
if docker ps | grep -q backend-prod; then
    BACKEND_PROD_LABELS=$(docker inspect backend-prod --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}{{"\n"}}{{end}}{{end}}' | wc -l)
    if [ "$BACKEND_PROD_LABELS" -eq 0 ]; then
        log_warning "Backend-prod sem labels Traefik - recriando..."
        
        # Obter imagem atual
        BACKEND_PROD_IMAGE=$(docker inspect backend-prod --format '{{.Config.Image}}')
        
        docker stop backend-prod
        docker rm backend-prod
        
        docker run -d \
          --name backend-prod \
          --network conexao-network \
          --restart unless-stopped \
          --label traefik.enable=true \
          --label "traefik.docker.network=conexao-network" \
          --label "traefik.http.routers.backend-prod-http.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/rest\`)" \
          --label traefik.http.routers.backend-prod-http.entrypoints=web \
          --label traefik.http.routers.backend-prod-http.priority=50 \
          --label traefik.http.routers.backend-prod-http.middlewares=backend-prod-stripprefix \
          --label "traefik.http.routers.backend-prod-https.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/rest\`)" \
          --label traefik.http.routers.backend-prod-https.entrypoints=websecure \
          --label traefik.http.routers.backend-prod-https.tls.certresolver=letsencrypt \
          --label traefik.http.routers.backend-prod-https.priority=50 \
          --label traefik.http.routers.backend-prod-https.middlewares=backend-prod-stripprefix \
          --label traefik.http.services.backend-prod.loadbalancer.server.port=8080 \
          --label "traefik.http.middlewares.backend-prod-stripprefix.stripprefix.prefixes=/rest" \
          $BACKEND_PROD_IMAGE
        
        log_success "Backend-prod recriado com labels"
    else
        log_success "Backend-prod já tem labels Traefik"
    fi
fi

# 9. Aguardar detecção pelo Traefik
log_info "9. Aguardando Traefik detectar containers (60 segundos)..."
sleep 60

# 10. Verificar roteadores
log_info "10. Verificando roteadores criados..."
ROUTER_COUNT=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -c "frontend\|backend" || echo "0")
log_info "Roteadores encontrados: $ROUTER_COUNT"

if [ "$ROUTER_COUNT" -gt 0 ]; then
    log_success "Roteadores detectados pelo Traefik"
    echo "Roteadores principais:"
    curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -E "(name|rule)" | head -10
else
    log_warning "Nenhum roteador detectado ainda - pode precisar de mais tempo"
fi

echo ""
log_success "🎉 RECUPERAÇÃO DE EMERGÊNCIA CONCLUÍDA!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Aguardar 2-3 minutos para estabilização completa"
echo "   2. Testar endpoints:"
echo "      • Frontend: https://conexaodesorte.com.br"
echo "      • Backend Prod: https://conexaodesorte.com.br/rest/actuator/health"
echo "      • Backend Teste: https://conexaodesorte.com.br/teste/rest/actuator/health"
echo "   3. Se algum não funcionar, aguardar mais tempo ou executar novamente"
