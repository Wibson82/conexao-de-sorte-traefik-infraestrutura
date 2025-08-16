#!/bin/bash
# =============================================================================
# CRIAÇÃO MANUAL DO CONTAINER BACKEND-TESTE
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

echo "🚀 CRIAÇÃO DO CONTAINER BACKEND-TESTE"
echo "====================================="

# Verificar se já existe
if docker ps -a | grep -q backend-teste; then
    log_warning "Container backend-teste já existe - removendo..."
    docker stop backend-teste 2>/dev/null || true
    docker rm backend-teste 2>/dev/null || true
fi

# Verificar rede
log_info "Verificando rede conexao-network..."
if docker network ls | grep -q "conexao-network"; then
    log_success "Rede conexao-network existe"
else
    log_info "Criando rede conexao-network..."
    docker network create conexao-network
fi

# Verificar se Traefik está na rede
log_info "Conectando Traefik à rede conexao-network..."
docker network connect conexao-network traefik 2>/dev/null || log_info "Traefik já conectado"

# Obter credenciais do banco (usar as mesmas do backend-prod)
log_info "Obtendo credenciais do banco de dados..."
DB_USERNAME=$(docker inspect backend-prod --format '{{range .Config.Env}}{{if contains . "SPRING_DATASOURCE_USERNAME="}}{{.}}{{end}}{{end}}' | cut -d'=' -f2)
DB_PASSWORD=$(docker inspect backend-prod --format '{{range .Config.Env}}{{if contains . "SPRING_DATASOURCE_PASSWORD="}}{{.}}{{end}}{{end}}' | cut -d'=' -f2)

if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
    log_error "Não foi possível obter credenciais do banco"
    log_info "Usando credenciais padrão..."
    DB_USERNAME="root"
    DB_PASSWORD="password"
fi

log_success "Credenciais obtidas: $DB_USERNAME"

# Obter tag mais recente da imagem de teste
log_info "Verificando imagem mais recente..."
IMAGE_TAG=$(date +%d-%m-%Y-%H-%M)
IMAGE_NAME="facilita/conexao-de-sorte-backend-teste:$IMAGE_TAG"

# Verificar se imagem existe no Docker Hub
log_info "Verificando se imagem $IMAGE_NAME existe..."
if docker pull "$IMAGE_NAME" 2>/dev/null; then
    log_success "Imagem $IMAGE_NAME encontrada"
else
    log_warning "Imagem $IMAGE_NAME não encontrada, usando latest..."
    IMAGE_NAME="facilita/conexao-de-sorte-backend-teste:latest"
    if ! docker pull "$IMAGE_NAME" 2>/dev/null; then
        log_error "Nenhuma imagem de teste encontrada"
        log_info "Usando imagem de produção como fallback..."
        IMAGE_NAME="facilita/conexao-de-sorte-backend:latest"
        docker pull "$IMAGE_NAME"
    fi
fi

# Criar container backend-teste
log_info "Criando container backend-teste..."
echo "📋 Imagem: $IMAGE_NAME"
echo "📋 Rede: conexao-network"
echo "📋 Porta: 8081"

docker run -d \
  --name backend-teste \
  --network conexao-network \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=prod,azure \
  -e ENVIRONMENT=prod \
  -e SERVER_PORT=8081 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
  -e SPRING_DATASOURCE_USERNAME="$DB_USERNAME" \
  -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
  -e AZURE_KEYVAULT_ENABLED=true \
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
  "$IMAGE_NAME"

log_success "Container backend-teste criado"

# Aguardar inicialização
log_info "Aguardando inicialização (60 segundos)..."
sleep 60

# Verificar se está rodando
if docker ps | grep -q backend-teste; then
    log_success "Container backend-teste está rodando"
    
    # Verificar health check
    log_info "Testando health check..."
    for i in {1..10}; do
        if curl -f http://localhost:8081/actuator/health >/dev/null 2>&1; then
            log_success "Health check OK"
            echo "📋 Response:"
            curl -s http://localhost:8081/actuator/health | head -3
            break
        else
            echo "Tentativa $i/10..."
            sleep 5
        fi
        
        if [ $i -eq 10 ]; then
            log_warning "Health check falhou - verificando logs..."
            docker logs backend-teste --tail 20
        fi
    done
    
    # Verificar roteadores Traefik
    log_info "Verificando roteadores Traefik..."
    sleep 10
    
    if curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "backend-teste"; then
        log_success "Roteadores backend-teste detectados pelo Traefik"
        echo "📋 Roteadores encontrados:"
        curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -E "(backend-teste|name|rule)" | head -5
    else
        log_warning "Roteadores backend-teste não detectados ainda"
        log_info "Aguardando mais 30 segundos..."
        sleep 30
        
        if curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "backend-teste"; then
            log_success "Roteadores backend-teste agora detectados"
        else
            log_error "Roteadores backend-teste não foram detectados"
            log_info "Verificando labels do container..."
            docker inspect backend-teste --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}: {{$value}}{{"\n"}}{{end}}{{end}}' | head -5
        fi
    fi
    
else
    log_error "Container backend-teste não está rodando"
    docker logs backend-teste --tail 30
    exit 1
fi

echo ""
log_success "🎉 BACKEND-TESTE CRIADO COM SUCESSO!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Aguardar 2-3 minutos para Traefik detectar completamente"
echo "   2. Testar endpoints:"
echo "      • Health: https://conexaodesorte.com.br/teste/rest/actuator/health"
echo "      • API: https://conexaodesorte.com.br/teste/rest/v1/resultados/publico/ultimo/federal"
echo "      • Com www: https://www.conexaodesorte.com.br/teste/rest/v1/resultados/publico/ultimo/federal"
echo "   3. Verificar logs se houver problemas: docker logs backend-teste"

echo ""
echo "📊 STATUS ATUAL:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "(NAMES|backend-teste|traefik)"
