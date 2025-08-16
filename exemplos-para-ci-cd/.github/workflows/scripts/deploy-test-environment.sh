#!/bin/bash
# =============================================================================
# SCRIPT DE DEPLOY SELETIVO DO AMBIENTE DE TESTE
# =============================================================================
# Este script realiza deploy APENAS do ambiente de teste (backend-teste)
# sem afetar os serviços de produção (frontend, backend-green, mysql)
# 
# Uso: ./deploy-test-environment.sh [COMMIT_SHA]
# =============================================================================

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_COMPOSE_TEST="$PROJECT_ROOT/docker-compose.test.yml"
ENV_TEST_FILE="$PROJECT_ROOT/.env.test"

# Parâmetros
COMMIT_SHA="${1:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
# RESTART_TRAEFIK removido - não mais necessário

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNÇÕES AUXILIARES =====
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

# ===== VALIDAÇÕES PRÉ-DEPLOY =====
validate_prerequisites() {
    log_info "Validando pré-requisitos para deploy de teste..."
    
    # Verificar se docker-compose.test.yml existe
    if [[ ! -f "$DOCKER_COMPOSE_TEST" ]]; then
        log_error "Arquivo docker-compose.test.yml não encontrado em: $DOCKER_COMPOSE_TEST"
        exit 1
    fi
    
    # Verificar se rede conexao-network existe
    if ! docker network ls | grep -q conexao-network; then
        log_error "Rede 'conexao-network' não encontrada. Execute primeiro o ambiente de produção."
        exit 1
    fi
    
    # Verificar se MySQL de produção está rodando
    if ! docker ps | grep -q conexao-mysql; then
        log_error "MySQL de produção não está rodando. Necessário para ambiente de teste."
        exit 1
    fi
    
    # Verificação do Traefik removida - não mais necessário
    
    log_success "Pré-requisitos validados"
}

# ===== DEPLOY DO AMBIENTE DE TESTE =====
deploy_test_environment() {
    log_info "Iniciando deploy do ambiente de TESTE - Commit: $COMMIT_SHA"
    
    # Parar apenas containers de TESTE seguindo padrões de nomenclatura
    log_info "Parando containers de teste antigos..."

    # Verificar containers existentes com padrão conexao-*-test
    EXISTING_TEST_CONTAINERS=$(docker ps -a --filter "name=conexao-" --format "{{.Names}}" | grep -E "(test|teste)" || echo "")

    if [[ -n "$EXISTING_TEST_CONTAINERS" ]]; then
        log_info "Containers de teste encontrados: $EXISTING_TEST_CONTAINERS"
        for container in $EXISTING_TEST_CONTAINERS; do
            log_info "Parando container: $container"
            docker stop $container 2>/dev/null || true
            docker rm $container 2>/dev/null || true
        done
        log_success "Containers de teste removidos"
    else
        log_info "Nenhum container de teste anterior encontrado"
    fi
    
    # Reinicialização do Traefik removida - não mais necessário
    
    # Criar arquivo .env.test temporário se não existir
    if [[ ! -f "$ENV_TEST_FILE" ]]; then
        log_info "Criando arquivo .env.test..."
        cat > "$ENV_TEST_FILE" << 'ENVEOF'
BACKEND_TEST_TAG=latest
CONEXAO_DE_SORTE_DATABASE_USERNAME=${CONEXAO_DE_SORTE_DATABASE_USERNAME}
CONEXAO_DE_SORTE_DATABASE_PASSWORD=${CONEXAO_DE_SORTE_DATABASE_PASSWORD}
AZURE_KEYVAULT_ENABLED=true
AZURE_KEYVAULT_ENDPOINT=${AZURE_KEYVAULT_ENDPOINT}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
APP_ENCRYPTION_MASTER_PASSWORD=${APP_ENCRYPTION_MASTER_PASSWORD}
ENVEOF
    fi
    
    # Deploy do backend de TESTE usando docker-compose
    log_info "Iniciando Backend de TESTE..."
    cd "$PROJECT_ROOT"
    docker-compose -f "$DOCKER_COMPOSE_TEST" --env-file "$ENV_TEST_FILE" up -d backend-teste
    
    log_info "Aguardando backend de teste inicializar..."
    sleep 45
    
    # Verificar se backend de teste está saudável
    log_info "Verificando saúde do backend de teste..."
    for i in {1..10}; do
        if curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
            log_success "Backend de teste está saudável"
            break
        else
            log_info "Tentativa $i/10 - aguardando backend..."
            sleep 10
        fi
        
        if [[ $i -eq 10 ]]; then
            log_error "Backend de teste não ficou saudável após 10 tentativas"
            exit 1
        fi
    done
    
    log_success "Deploy de TESTE concluído com sucesso!"
}

# ===== VALIDAÇÃO PÓS-DEPLOY =====
validate_test_deployment() {
    log_info "Validando deployment de teste..."
    
    # Verificar se container está rodando
    if ! docker ps | grep -q conexao-backend-test; then
        log_error "Container conexao-backend-test não está rodando"
        exit 1
    fi
    
    # Testar endpoint diretamente
    log_info "Testando endpoint direto do container..."
    if curl -f --connect-timeout 10 http://localhost:8081/actuator/health > /dev/null 2>&1; then
        log_success "Backend de teste (conexao-backend-test) responde diretamente na porta 8081"
    else
        log_error "Backend de teste (conexao-backend-test) não responde"
        exit 1
    fi
    
    log_success "Validação concluída"
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    echo "🧪 Deploy Seletivo do Ambiente de Teste"
    echo "========================================"
    echo "Commit: $COMMIT_SHA"
    # Configuração do Traefik removida
    echo ""
    
    validate_prerequisites
    deploy_test_environment
    validate_test_deployment
    
    echo ""
    log_success "🎉 Deploy de teste concluído com sucesso!"
    echo ""
    echo "📋 URLs de teste disponíveis:"
    echo "   - Health Check: http://localhost:8081/actuator/health"
    echo "   - Direto: http://localhost:8081/actuator/health"
    echo "   - Swagger: http://localhost:8081/swagger-ui.html"
    echo ""
    echo "🔍 Para verificar logs:"
    echo "   docker logs conexao-backend-test -f"
    echo ""
    echo "🛑 Para parar o ambiente de teste:"
    echo "   docker stop conexao-backend-test"
}

# Executar função principal
main "$@"
