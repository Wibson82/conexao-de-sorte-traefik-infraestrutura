#!/bin/bash

# =============================================================================
# SCRIPT DE INICIALIZAÇÃO - AMBIENTE DE DESENVOLVIMENTO COM AZURE KEY VAULT
# =============================================================================
# Este script configura e inicia o ambiente de desenvolvimento usando
# os secrets do GitHub para conectar ao Azure Key Vault

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Diretório do projeto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se Azure CLI está instalado e logado
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI não está instalado. Execute: brew install azure-cli"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Não está logado no Azure. Execute: az login"
        exit 1
    fi
    
    # Verificar se GitHub CLI está instalado e logado
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI não está instalado. Execute: brew install gh"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "Não está logado no GitHub. Execute: gh auth login"
        exit 1
    fi
    
    # Verificar se Maven está instalado
    if ! command -v mvn &> /dev/null; then
        log_error "Maven não está instalado. Execute: brew install maven"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Obter secrets do GitHub
get_github_secrets() {
    log_info "Obtendo secrets do GitHub..."
    
    local repo="Wibson82/conexao-de-sorte-backend"
    
    # Verificar se consegue acessar o repositório
    if ! gh secret list --repo "$repo" &> /dev/null; then
        log_error "Não foi possível acessar os secrets do repositório $repo"
        log_error "Verifique se você tem permissões adequadas"
        exit 1
    fi
    
    # Obter valores dos secrets (apenas para verificação - não exibir valores)
    local secrets=("AZURE_TENANT_ID" "AZURE_CLIENT_ID" "AZURE_CLIENT_SECRET")
    
    for secret in "${secrets[@]}"; do
        if gh secret list --repo "$repo" --json name | jq -r '.[].name' | grep -q "^$secret$"; then
            log_success "Secret $secret encontrado"
        else
            log_error "Secret $secret não encontrado no repositório"
            exit 1
        fi
    done
    
    log_success "Todos os secrets necessários estão disponíveis"
}

# Configurar variáveis de ambiente
setup_environment() {
    log_info "Configurando variáveis de ambiente..."
    
    # Carregar arquivo .env.dev se existir
    if [[ -f ".env.dev" ]]; then
        log_info "Carregando configurações de .env.dev..."
        set -a  # automatically export all variables
        source .env.dev
        set +a
        log_success "Configurações carregadas de .env.dev"
    else
        log_warning "Arquivo .env.dev não encontrado"
    fi
    
    # Definir variáveis específicas para desenvolvimento
    export SPRING_PROFILES_ACTIVE="dev,macos"
    export AZURE_KEYVAULT_ENABLED="true"
    export AZURE_KEYVAULT_FALLBACK_ENABLED="true"
    
    log_success "Variáveis de ambiente configuradas"
}

# Verificar conectividade com Azure Key Vault
test_azure_connectivity() {
    log_info "Testando conectividade com Azure Key Vault..."
    
    local vault_name="chave-conexao-de-sorte"
    
    if az keyvault secret list --vault-name "$vault_name" --query '[0].name' -o tsv &> /dev/null; then
        log_success "Conectividade com Azure Key Vault confirmada"
    else
        log_warning "Não foi possível conectar ao Azure Key Vault"
        log_warning "A aplicação usará fallback local se configurado"
    fi
}

# Compilar aplicação
build_application() {
    log_info "Compilando aplicação..."
    
    if mvn clean compile -q; then
        log_success "Aplicação compilada com sucesso"
    else
        log_error "Falha na compilação da aplicação"
        exit 1
    fi
}

# Iniciar aplicação
start_application() {
    log_info "Iniciando aplicação em modo desenvolvimento..."
    
    log_info "Configurações ativas:"
    echo "  - Profile: ${SPRING_PROFILES_ACTIVE:-dev}"
    echo "  - Porta: ${SERVER_PORT:-8080}"
    echo "  - Azure Key Vault: ${AZURE_KEYVAULT_ENABLED:-false}"
    echo "  - Fallback: ${AZURE_KEYVAULT_FALLBACK_ENABLED:-true}"
    echo
    
    log_info "Iniciando servidor..."
    log_info "Acesse: http://localhost:${SERVER_PORT:-8080}"
    log_info "Swagger: http://localhost:${SERVER_PORT:-8080}/swagger-ui.html"
    log_info "Health: http://localhost:${SERVER_PORT:-8080}/actuator/health"
    echo
    log_info "Para parar a aplicação, pressione Ctrl+C"
    echo
    
    # Iniciar aplicação
    mvn spring-boot:run -Dspring-boot.run.profiles="${SPRING_PROFILES_ACTIVE:-dev}"
}

# Função principal
main() {
    echo "===================================================================="
    echo "🚀 INICIANDO AMBIENTE DE DESENVOLVIMENTO - CONEXÃO DE SORTE"
    echo "===================================================================="
    echo
    
    check_prerequisites
    get_github_secrets
    setup_environment
    test_azure_connectivity
    build_application
    start_application
}

# Tratamento de sinais
trap 'log_info "Parando aplicação..."; exit 0' SIGINT SIGTERM

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi