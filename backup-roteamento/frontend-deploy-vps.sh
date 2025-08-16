#!/bin/bash

# Script de deploy para VPS Ubuntu - Conexão de Sorte Frontend
# Este script deve ser executado no VPS Ubuntu

set -euo pipefail  # Parar execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Configurações
DOCKER_USERNAME="${DOCKER_USERNAME:-facilita}"
TAG="${TAG:-latest}"
COMMIT_SHA="${COMMIT_SHA:-manual-deploy}"

log "🚀 Iniciando deploy do Conexão de Sorte Frontend - Commit: $COMMIT_SHA"

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado!"
    exit 1
fi

# Garantir rede Docker
log "🌐 Garantindo rede Docker..."
docker network create conexao-network 2>/dev/null || true

# Fazer backup do container atual (se existir)
if docker ps -a | grep -q "conexao-frontend"; then
    log "💾 Fazendo backup do container atual..."
    docker commit conexao-frontend conexao-frontend:backup-$(date +%Y%m%d-%H%M%S) || warning "Falha ao criar backup"
fi

# Parar container frontend antigo
log "⏹️ Parando container frontend antigo..."
docker stop conexao-frontend 2>/dev/null || warning "Nenhum container estava rodando"
docker rm conexao-frontend 2>/dev/null || warning "Nenhum container para remover"

# Fazer pull da nova imagem
log "📥 Baixando nova imagem Docker..."
docker pull $DOCKER_USERNAME/conexao-de-sorte-frontend:$TAG

# Verificar se a imagem foi baixada
if ! docker images | grep -q "$DOCKER_USERNAME/conexao-de-sorte-frontend"; then
    error "Falha ao baixar a imagem Docker"
    exit 1
fi

# Iniciar Frontend
log "🚀 Iniciando Frontend..."
docker run -d \
  --name conexao-frontend \
  --network conexao-network \
  --restart unless-stopped \
  -e NODE_ENV=production \
  -e VITE_API_URL=/rest \
  -e VITE_API_BASE_URL=/rest \
  -e VITE_FORCE_HTTPS=true \
  -e VITE_ADMIN_URL=/admin \
  -e TZ=America/Sao_Paulo \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.frontend-http.rule=Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)" \
  --label "traefik.http.routers.frontend-http.entrypoints=web" \
  --label "traefik.http.routers.frontend-http.priority=1" \
  --label "traefik.http.routers.frontend-https.rule=Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)" \
  --label "traefik.http.routers.frontend-https.entrypoints=websecure" \
  --label "traefik.http.routers.frontend-https.tls=true" \
  --label "traefik.http.routers.frontend-https.priority=1" \
  --label "traefik.http.services.frontend.loadbalancer.server.port=3000" \
  $DOCKER_USERNAME/conexao-de-sorte-frontend:$TAG

# Aguardar container iniciar
log "⏳ Aguardando container iniciar..."
sleep 15

# Verificar se o container está rodando
if docker ps | grep -q "conexao-frontend"; then
    log "✅ Container iniciado com sucesso!"
else
    error "Falha ao iniciar o container"
    info "Logs do container:"
    docker logs conexao-frontend --tail=50
    exit 1
fi

# Verificar saúde do container
log "🔍 Verificando saúde do container..."
for i in {1..30}; do
    if docker exec conexao-frontend wget --quiet --spider http://localhost:3000/health 2>/dev/null; then
        log "✅ Container está saudável!"
        break
    fi
    if [ $i -eq 30 ]; then
        warning "Container pode não estar totalmente saudável"
        docker logs conexao-frontend --tail=20
    fi
    sleep 2
done

# Limpeza de imagens antigas
log "🧹 Limpando imagens Docker não utilizadas..."
docker image prune -f

# Mostrar status final
log "📊 Status final do container:"
docker ps | grep conexao-frontend || warning "Container não encontrado"

log "🎉 Deploy concluído com sucesso!"
log "🌐 Aplicação disponível em: https://conexaodesorte.com.br"

# Mostrar logs recentes
info "📝 Logs recentes:"
docker logs conexao-frontend --tail=10 2>/dev/null || warning "Não foi possível obter logs"
