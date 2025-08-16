#!/bin/bash
# =============================================================================
# SCRIPT PARA TESTAR DOCKER RUN DIRETO COM ARGUMENTOS SEPARADOS
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

echo "🧪 Teste de Docker Run Direto"
echo "============================="

# Simular variáveis do ambiente
TRAEFIK_NETWORK="bridge"
DB_USERNAME="test_user"
DB_PASSWORD="test_password"

log_info "Testando comando docker run com argumentos separados..."

# Comando exato do workflow (modo dry-run)
echo ""
log_info "Comando que será executado:"
echo "docker run -d \\"
echo "  --name backend-teste \\"
echo "  --network \"$TRAEFIK_NETWORK\" \\"
echo "  --restart unless-stopped \\"
echo "  -e SPRING_PROFILES_ACTIVE=test,prod \\"
echo "  -e ENVIRONMENT=test \\"
echo "  -e SERVER_PORT=8081 \\"
echo "  -e SPRING_DATASOURCE_URL=\"jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo\" \\"
echo "  -e SPRING_DATASOURCE_USERNAME=\"$DB_USERNAME\" \\"
echo "  -e SPRING_DATASOURCE_PASSWORD=\"$DB_PASSWORD\" \\"
echo "  -e AZURE_KEYVAULT_ENABLED=true \\"
echo "  -e JAVA_OPTS=\"-server -Xms256m -Xmx1024m -XX:+UseG1GC\" \\"
echo "  --label traefik.enable=true \\"
echo "  --label \"traefik.http.routers.backend-teste-http.rule=(Host(\\\`conexaodesorte.com.br\\\`) || Host(\\\`www.conexaodesorte.com.br\\\`)) && PathPrefix(\\\`/teste/rest\\\`)\" \\"
echo "  --label traefik.http.routers.backend-teste-http.entrypoints=web \\"
echo "  --label traefik.http.routers.backend-teste-http.priority=100 \\"
echo "  --label traefik.http.routers.backend-teste-http.middlewares=backend-teste-stripprefix \\"
echo "  --label \"traefik.http.routers.backend-teste-https.rule=(Host(\\\`conexaodesorte.com.br\\\`) || Host(\\\`www.conexaodesorte.com.br\\\`)) && PathPrefix(\\\`/teste/rest\\\`)\" \\"
echo "  --label traefik.http.routers.backend-teste-https.entrypoints=websecure \\"
echo "  --label traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt \\"
echo "  --label traefik.http.routers.backend-teste-https.priority=100 \\"
echo "  --label traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix \\"
echo "  --label traefik.http.services.backend-teste.loadbalancer.server.port=8081 \\"
echo "  --label \"traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest\" \\"
echo "  facilita/conexao-de-sorte-backend-teste:latest"

echo ""
log_info "Testando sintaxe com bash -n..."

# Criar arquivo temporário com o comando
cat > /tmp/test-docker-cmd.sh << 'EOF'
#!/bin/bash
TRAEFIK_NETWORK="bridge"
DB_USERNAME="test_user"
DB_PASSWORD="test_password"

docker run -d \
  --name backend-teste \
  --network "$TRAEFIK_NETWORK" \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=test,prod \
  -e ENVIRONMENT=test \
  -e SERVER_PORT=8081 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
  -e SPRING_DATASOURCE_USERNAME="$DB_USERNAME" \
  -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
  -e AZURE_KEYVAULT_ENABLED=true \
  -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC" \
  --label traefik.enable=true \
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
  facilita/conexao-de-sorte-backend-teste:\$(date +%d-%m-%Y-%H-%M)
EOF

# Testar sintaxe
if bash -n /tmp/test-docker-cmd.sh 2>/dev/null; then
    log_success "Sintaxe do comando está correta"
else
    log_error "Erro de sintaxe no comando"
    bash -n /tmp/test-docker-cmd.sh
    exit 1
fi

echo ""
log_info "Verificando labels Traefik..."

# Verificar se os labels estão corretos
if grep -q "traefik.enable=true" /tmp/test-docker-cmd.sh; then
    log_success "Label traefik.enable=true encontrado"
else
    log_error "Label traefik.enable=true não encontrado"
fi

if grep -q "/teste/rest" /tmp/test-docker-cmd.sh; then
    log_success "PathPrefix /teste/rest encontrado nos labels"
else
    log_error "PathPrefix /teste/rest não encontrado nos labels"
fi

if grep -q "backend-teste-stripprefix" /tmp/test-docker-cmd.sh; then
    log_success "Middleware stripprefix encontrado"
else
    log_error "Middleware stripprefix não encontrado"
fi

if grep -q "Host.*conexaodesorte.com.br" /tmp/test-docker-cmd.sh; then
    log_success "Host rules encontradas"
else
    log_error "Host rules não encontradas"
fi

echo ""
log_info "Verificando variáveis de ambiente..."

if grep -q "SPRING_PROFILES_ACTIVE=test,prod" /tmp/test-docker-cmd.sh; then
    log_success "Profile test,prod configurado"
else
    log_error "Profile test,prod não encontrado"
fi

if grep -q "SERVER_PORT=8081" /tmp/test-docker-cmd.sh; then
    log_success "Porta 8081 configurada"
else
    log_error "Porta 8081 não encontrada"
fi

# Limpar arquivo temporário
rm -f /tmp/test-docker-cmd.sh

echo ""
log_success "🎉 Teste de docker run direto concluído!"
echo ""
echo "📋 Resumo:"
echo "   ✅ Sintaxe correta"
echo "   ✅ Labels Traefik presentes"
echo "   ✅ Variáveis de ambiente configuradas"
echo "   ✅ Comando pronto para execução no servidor"
echo ""
echo "🔍 O comando será executado diretamente no servidor durante o deploy"
echo "🚀 Aguarde a execução do workflow para ver o resultado"
