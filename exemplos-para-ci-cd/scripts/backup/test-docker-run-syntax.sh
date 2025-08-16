#!/bin/bash
# =============================================================================
# SCRIPT PARA TESTAR A SINTAXE DO COMANDO DOCKER RUN
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

echo "🧪 Teste de Sintaxe do Comando Docker Run"
echo "========================================"

# Simular variáveis do ambiente
TRAEFIK_NETWORK="bridge"
DB_USERNAME="test_user"
DB_PASSWORD="test_password"

log_info "Testando sintaxe do comando docker run..."

# Comando exato do workflow (sem executar)
DOCKER_CMD='docker run -d --name backend-teste --network "$TRAEFIK_NETWORK" --restart unless-stopped -e SPRING_PROFILES_ACTIVE=test,prod -e ENVIRONMENT=test -e SERVER_PORT=8081 -e SPRING_DATASOURCE_URL=jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo -e SPRING_DATASOURCE_USERNAME="$DB_USERNAME" -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" -e AZURE_KEYVAULT_ENABLED=true -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC" --label "traefik.enable=true" --label "traefik.http.routers.backend-teste-http.rule=(Host(`conexaodesorte.com.br`) || Host(`www.conexaodesorte.com.br`)) && PathPrefix(`/teste/rest`)" --label "traefik.http.routers.backend-teste-http.entrypoints=web" --label "traefik.http.routers.backend-teste-http.priority=100" --label "traefik.http.routers.backend-teste-http.middlewares=backend-teste-stripprefix" --label "traefik.http.routers.backend-teste-https.rule=(Host(`conexaodesorte.com.br`) || Host(`www.conexaodesorte.com.br`)) && PathPrefix(`/teste/rest`)" --label "traefik.http.routers.backend-teste-https.entrypoints=websecure" --label "traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt" --label "traefik.http.routers.backend-teste-https.priority=100" --label "traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix" --label "traefik.http.services.backend-teste.loadbalancer.server.port=8081" --label "traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest" facilita/conexao-de-sorte-backend-teste:latest'

# Testar se o comando é válido sintaticamente
if bash -n -c "$DOCKER_CMD" 2>/dev/null; then
    log_success "Sintaxe do comando está correta"
else
    log_error "Erro de sintaxe no comando"
    exit 1
fi

# Mostrar o comando formatado para debug
echo ""
log_info "Comando que será executado:"
echo "docker run -d \\"
echo "  --name backend-teste \\"
echo "  --network \"$TRAEFIK_NETWORK\" \\"
echo "  --restart unless-stopped \\"
echo "  -e SPRING_PROFILES_ACTIVE=test,prod \\"
echo "  -e ENVIRONMENT=test \\"
echo "  -e SERVER_PORT=8081 \\"
echo "  -e SPRING_DATASOURCE_URL=jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo \\"
echo "  -e SPRING_DATASOURCE_USERNAME=\"$DB_USERNAME\" \\"
echo "  -e SPRING_DATASOURCE_PASSWORD=\"$DB_PASSWORD\" \\"
echo "  -e AZURE_KEYVAULT_ENABLED=true \\"
echo "  -e JAVA_OPTS=\"-server -Xms256m -Xmx1024m -XX:+UseG1GC\" \\"
echo "  --label \"traefik.enable=true\" \\"
echo "  --label \"traefik.http.routers.backend-teste-http.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)\" \\"
echo "  --label \"traefik.http.routers.backend-teste-http.entrypoints=web\" \\"
echo "  --label \"traefik.http.routers.backend-teste-http.priority=100\" \\"
echo "  --label \"traefik.http.routers.backend-teste-http.middlewares=backend-teste-stripprefix\" \\"
echo "  --label \"traefik.http.routers.backend-teste-https.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)\" \\"
echo "  --label \"traefik.http.routers.backend-teste-https.entrypoints=websecure\" \\"
echo "  --label \"traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt\" \\"
echo "  --label \"traefik.http.routers.backend-teste-https.priority=100\" \\"
echo "  --label \"traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix\" \\"
echo "  --label \"traefik.http.services.backend-teste.loadbalancer.server.port=8081\" \\"
echo "  --label \"traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest\" \\"
echo "  facilita/conexao-de-sorte-backend-teste:\$(date +%d-%m-%Y-%H-%M)"

echo ""
log_info "Verificando se a imagem existe no Docker Hub..."
TEST_TAG=$(date +%d-%m-%Y-%H-%M)
if curl -s "https://hub.docker.com/v2/repositories/facilita/conexao-de-sorte-backend-teste/tags/" | grep -q "$TEST_TAG"; then
    log_success "Imagem facilita/conexao-de-sorte-backend-teste:$TEST_TAG existe no Docker Hub"
else
    log_warning "Imagem facilita/conexao-de-sorte-backend-teste:$TEST_TAG pode não existir no Docker Hub"
    log_info "Verificando se existe localmente..."
    if docker images | grep -q "facilita/conexao-de-sorte-backend-teste"; then
        log_success "Imagem existe localmente"
    else
        log_warning "Imagem não existe localmente - será baixada durante o deploy"
    fi
fi

echo ""
log_success "🎉 Teste de sintaxe concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. O comando docker run está sintaticamente correto"
echo "   2. Aguarde a execução do workflow para ver se funciona no servidor"
echo "   3. Monitore os logs do container backend-teste após o deploy"
echo ""
echo "🔍 Para monitorar no servidor:"
echo "   docker logs backend-teste -f"
echo "   docker ps | grep backend-teste"
echo "   curl -f http://localhost:8081/actuator/health"
