#!/bin/bash

# ============================================================================
# 🔍 VERIFICADOR E CRIADOR DE SECRETS REDIS
# ============================================================================
# 
# Script para verificar e criar secrets do Redis no Azure Key Vault
# usando os secrets já existentes ou criando novos seguros
#
# Uso: ./check-and-create-redis-secrets.sh
# ============================================================================

set -euo pipefail

# Configurações
VAULT_NAME="kv-conexao-de-sorte"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Função para gerar senha segura
generate_secure_password() {
    local length=${1:-32}
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${length}
}

# Função para salvar secret no Azure Key Vault
save_secret_to_vault() {
    local secret_name="$1"
    local secret_value="$2"
    local description="$3"
    
    log_info "Salvando secret: $secret_name"
    
    if printf "%s" "$secret_value" | az keyvault secret set \
        --vault-name "$VAULT_NAME" \
        --name "$secret_name" \
        --description "$description" \
        --file /dev/stdin >/dev/null 2>&1; then
        log_success "Secret $secret_name configurado"
        return 0
    else
        log_error "Falha ao configurar secret $secret_name"
        return 1
    fi
}

# Função para verificar se secret existe
secret_exists() {
    local secret_name="$1"
    az keyvault secret show --vault-name "$VAULT_NAME" --name "$secret_name" >/dev/null 2>&1
}

# Função principal
main() {
    log_info "🔍 Verificando secrets do Redis no Azure Key Vault..."
    
    # Verificar dependências
    if ! command -v az >/dev/null 2>&1; then
        log_error "Azure CLI não encontrado"
        exit 1
    fi
    
    # Verificar autenticação Azure
    if ! az account show >/dev/null 2>&1; then
        log_error "Não autenticado no Azure. Execute: az login"
        exit 1
    fi
    
    # Verificar acesso ao Key Vault
    if ! az keyvault show --name "$VAULT_NAME" >/dev/null 2>&1; then
        log_error "Não foi possível acessar o Key Vault: $VAULT_NAME"
        exit 1
    fi
    
    # Lista de secrets do Redis necessários
    declare -A redis_secrets=(
        ["conexao-de-sorte-redis-password"]="Senha para autenticação Redis"
        ["conexao-de-sorte-redis-host"]="Host do Redis"
        ["conexao-de-sorte-redis-port"]="Porta do Redis" 
        ["conexao-de-sorte-redis-database"]="Database Redis"
    )
    
    # Verificar e criar secrets conforme necessário
    for secret_name in "${!redis_secrets[@]}"; do
        description="${redis_secrets[$secret_name]}"
        
        if secret_exists "$secret_name"; then
            log_success "Secret $secret_name já existe"
        else
            log_warning "Secret $secret_name não existe, criando..."
            
            case "$secret_name" in
                *password*)
                    # Gerar senha segura para Redis
                    password=$(generate_secure_password 32)
                    save_secret_to_vault "$secret_name" "$password" "$description"
                    unset password
                    ;;
                *host*)
                    # Host padrão para Docker Swarm
                    save_secret_to_vault "$secret_name" "conexao-redis" "$description"
                    ;;
                *port*)
                    # Porta padrão do Redis
                    save_secret_to_vault "$secret_name" "6379" "$description"
                    ;;
                *database*)
                    # Database padrão
                    save_secret_to_vault "$secret_name" "0" "$description"
                    ;;
            esac
        fi
    done
    
    # Verificar outros secrets Redis relacionados
    log_info "🔍 Verificando secrets relacionados..."
    
    # Secrets opcionais que podem existir
    declare -A optional_secrets=(
        ["conexao-de-sorte-session-secret"]="Secret para sessões"
    )
    
    for secret_name in "${!optional_secrets[@]}"; do
        description="${optional_secrets[$secret_name]}"
        
        if ! secret_exists "$secret_name"; then
            log_info "Criando secret opcional: $secret_name"
            session_secret=$(generate_secure_password 64)
            save_secret_to_vault "$secret_name" "$session_secret" "$description"
            unset session_secret
        else
            log_success "Secret opcional $secret_name já existe"
        fi
    done
    
    log_success "🎉 Verificação e criação de secrets Redis concluída!"
    
    # Mostrar resumo
    log_info "📋 Status dos secrets Redis:"
    for secret_name in "${!redis_secrets[@]}"; do
        if secret_exists "$secret_name"; then
            echo "   ✅ $secret_name"
        else
            echo "   ❌ $secret_name"
        fi
    done
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi