#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO - VARIÁVEIS AZURE PARA DESENVOLVIMENTO
# =============================================================================
# Este script obtém os secrets do GitHub e configura as variáveis de ambiente
# necessárias para conectar ao Azure Key Vault em desenvolvimento

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

# Configurações
REPO="Wibson82/conexao-de-sorte-backend"
ENV_FILE=".env.dev.local"

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI não está instalado. Execute: brew install gh"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "Não está logado no GitHub. Execute: gh auth login"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Obter secrets do GitHub e criar arquivo de ambiente
setup_azure_secrets() {
    log_info "Obtendo secrets do Azure do GitHub..."
    
    # Verificar acesso ao repositório
    if ! gh secret list --repo "$REPO" &> /dev/null; then
        log_error "Não foi possível acessar os secrets do repositório $REPO"
        exit 1
    fi
    
    # Lista de secrets necessários
    local azure_secrets=(
        "AZURE_TENANT_ID"
        "AZURE_CLIENT_ID"
        "AZURE_CLIENT_SECRET"
        "AZURE_KEYVAULT_ENDPOINT"
        "AZURE_KEYVAULT_NAME"
    )
    
    # Verificar se todos os secrets existem
    local missing_secrets=()
    for secret in "${azure_secrets[@]}"; do
        if ! gh secret list --repo "$REPO" --json name | jq -r '.[].name' | grep -q "^$secret$"; then
            missing_secrets+=("$secret")
        fi
    done
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        log_error "Secrets não encontrados: ${missing_secrets[*]}"
        exit 1
    fi
    
    log_success "Todos os secrets do Azure encontrados"
    
    # Criar arquivo de ambiente local
    log_info "Criando arquivo $ENV_FILE..."
    
    cat > "$ENV_FILE" << 'EOF'
# =============================================================================
# VARIÁVEIS DE AMBIENTE AZURE - DESENVOLVIMENTO LOCAL
# =============================================================================
# Este arquivo contém as variáveis do Azure obtidas dos GitHub Secrets
# IMPORTANTE: Este arquivo é gerado automaticamente e não deve ser commitado

# Secrets do Azure obtidos do GitHub
EOF
    
    # Adicionar instruções para obter os valores
    cat >> "$ENV_FILE" << EOF
# Para obter os valores dos secrets, execute:
# gh secret list --repo $REPO

# Defina manualmente as variáveis abaixo com os valores dos GitHub Secrets:
# (Os valores não podem ser obtidos automaticamente por segurança)

# AZURE_TENANT_ID=<valor do GitHub Secret AZURE_TENANT_ID>
# AZURE_CLIENT_ID=<valor do GitHub Secret AZURE_CLIENT_ID>
# AZURE_CLIENT_SECRET=<valor do GitHub Secret AZURE_CLIENT_SECRET>

# Configurações do Key Vault (obtidas dos secrets)
AZURE_KEYVAULT_ENDPOINT=https://chave-conexao-de-sorte.vault.azure.net/
AZURE_KEYVAULT_NAME=chave-conexao-de-sorte
AZURE_KEYVAULT_ENABLED=true
AZURE_KEYVAULT_FALLBACK_ENABLED=true

# Para usar este arquivo:
# 1. Descomente e preencha as variáveis AZURE_* acima
# 2. Execute: source $ENV_FILE
# 3. Inicie a aplicação normalmente
EOF
    
    log_success "Arquivo $ENV_FILE criado"
    
    # Adicionar ao .gitignore se não estiver
    if ! grep -q "$ENV_FILE" .gitignore 2>/dev/null; then
        echo "$ENV_FILE" >> .gitignore
        log_success "$ENV_FILE adicionado ao .gitignore"
    fi
}

# Mostrar instruções
show_instructions() {
    echo
    echo "===================================================================="
    echo "📋 INSTRUÇÕES PARA CONFIGURAR AZURE KEY VAULT"
    echo "===================================================================="
    echo
    echo "1. Edite o arquivo $ENV_FILE e preencha as variáveis AZURE_*"
    echo "   com os valores dos GitHub Secrets"
    echo
    echo "2. Para obter os valores dos secrets (apenas nomes):"
    echo "   gh secret list --repo $REPO"
    echo
    echo "3. Para usar as configurações:"
    echo "   source $ENV_FILE"
    echo
    echo "4. Para iniciar a aplicação:"
    echo "   ./scripts/start-dev-with-azure.sh"
    echo
    echo "5. Ou manualmente:"
    echo "   mvn spring-boot:run -Dspring-boot.run.profiles=dev,macos"
    echo
    echo "===================================================================="
    echo "🔒 SEGURANÇA: Os valores dos secrets não são exibidos por segurança"
    echo "===================================================================="
    echo
}

# Função principal
main() {
    echo "===================================================================="
    echo "🔧 CONFIGURAÇÃO DE SECRETS AZURE - DESENVOLVIMENTO"
    echo "===================================================================="
    echo
    
    check_prerequisites
    setup_azure_secrets
    show_instructions
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi