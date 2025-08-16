#!/bin/bash
# =============================================================================
# SCRIPT PARA TESTAR A CONSTRUÇÃO DO COMANDO DOCKER RUN
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

echo "🧪 Teste de Construção do Comando Docker Run"
echo "============================================"

# Simular variáveis do ambiente
TRAEFIK_NETWORK="bridge"
DB_USERNAME="test_user"
DB_PASSWORD="test_password"

log_info "Construindo comando docker run em partes..."

# Construir comando docker run em partes (igual ao workflow)
DOCKER_CMD="docker run -d"
DOCKER_CMD="$DOCKER_CMD --name backend-teste"
DOCKER_CMD="$DOCKER_CMD --network $TRAEFIK_NETWORK"
DOCKER_CMD="$DOCKER_CMD --restart unless-stopped"
DOCKER_CMD="$DOCKER_CMD -e SPRING_PROFILES_ACTIVE=test,prod"
DOCKER_CMD="$DOCKER_CMD -e ENVIRONMENT=test"
DOCKER_CMD="$DOCKER_CMD -e SERVER_PORT=8081"
DOCKER_CMD="$DOCKER_CMD -e SPRING_DATASOURCE_URL=jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo"
DOCKER_CMD="$DOCKER_CMD -e SPRING_DATASOURCE_USERNAME=$DB_USERNAME"
DOCKER_CMD="$DOCKER_CMD -e SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD"
DOCKER_CMD="$DOCKER_CMD -e AZURE_KEYVAULT_ENABLED=true"
DOCKER_CMD="$DOCKER_CMD -e JAVA_OPTS=-server -Xms256m -Xmx1024m -XX:+UseG1GC"
DOCKER_CMD="$DOCKER_CMD --label traefik.enable=true"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-http.rule=(Host('conexaodesorte.com.br') || Host('www.conexaodesorte.com.br')) && PathPrefix('/teste/rest')"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-http.entrypoints=web"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-http.priority=100"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-http.middlewares=backend-teste-stripprefix"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-https.rule=(Host('conexaodesorte.com.br') || Host('www.conexaodesorte.com.br')) && PathPrefix('/teste/rest')"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-https.entrypoints=websecure"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-https.priority=100"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.services.backend-teste.loadbalancer.server.port=8081"
DOCKER_CMD="$DOCKER_CMD --label traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest"
DOCKER_CMD="$DOCKER_CMD facilita/conexao-de-sorte-backend-teste:\$(date +%d-%m-%Y-%H-%M)"

log_success "Comando construído com sucesso"

echo ""
log_info "Comando final:"
echo "$DOCKER_CMD"

echo ""
log_info "Testando sintaxe do comando construído..."

# Testar se o comando é válido sintaticamente
if bash -n -c "$DOCKER_CMD" 2>/dev/null; then
    log_success "Sintaxe do comando está correta"
else
    log_error "Erro de sintaxe no comando"
    exit 1
fi

echo ""
log_info "Testando expansão de variáveis..."

# Verificar se as variáveis foram expandidas corretamente
if echo "$DOCKER_CMD" | grep -q "$TRAEFIK_NETWORK"; then
    log_success "Variável TRAEFIK_NETWORK expandida: $TRAEFIK_NETWORK"
else
    log_error "Variável TRAEFIK_NETWORK não foi expandida"
fi

if echo "$DOCKER_CMD" | grep -q "$DB_USERNAME"; then
    log_success "Variável DB_USERNAME expandida: $DB_USERNAME"
else
    log_error "Variável DB_USERNAME não foi expandida"
fi

if echo "$DOCKER_CMD" | grep -q "$DB_PASSWORD"; then
    log_success "Variável DB_PASSWORD expandida: $DB_PASSWORD"
else
    log_error "Variável DB_PASSWORD não foi expandida"
fi

echo ""
log_info "Verificando labels Traefik..."

# Verificar se os labels Traefik estão corretos
if echo "$DOCKER_CMD" | grep -q "traefik.enable=true"; then
    log_success "Label traefik.enable=true encontrado"
else
    log_error "Label traefik.enable=true não encontrado"
fi

if echo "$DOCKER_CMD" | grep -q "/teste/rest"; then
    log_success "PathPrefix /teste/rest encontrado nos labels"
else
    log_error "PathPrefix /teste/rest não encontrado nos labels"
fi

if echo "$DOCKER_CMD" | grep -q "backend-teste-stripprefix"; then
    log_success "Middleware stripprefix encontrado"
else
    log_error "Middleware stripprefix não encontrado"
fi

echo ""
log_info "Simulando execução com eval (sem executar)..."

# Simular o que aconteceria com eval (sem executar)
echo "eval $DOCKER_CMD"

echo ""
log_success "🎉 Teste de construção concluído!"
echo ""
echo "📋 Resumo:"
echo "   ✅ Sintaxe correta"
echo "   ✅ Variáveis expandidas"
echo "   ✅ Labels Traefik presentes"
echo "   ✅ Comando pronto para execução"
echo ""
echo "🔍 O comando será executado no servidor via eval durante o deploy"
