#!/bin/bash

# ============================================================================
# 🔐 GERADOR SEGURO DE SECRETS PARA AZURE KEY VAULT
# ============================================================================
# 
# Script para gerar senhas robustas seguindo boas práticas de segurança
# e armazenar no Azure Key Vault de forma segura
#
# Uso: ./generate-secure-secrets.sh
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
NC='\033[0m' # No Color

# Logging
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

# Função para gerar senha segura
generate_secure_password() {
    local length=${1:-32}
    # Gera senha com letras maiúsculas, minúsculas, números e símbolos especiais
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${length}
}

# Função para gerar hash bcrypt
generate_bcrypt_hash() {
    local password="$1"
    # Usa htpasswd para gerar hash bcrypt
    if command -v htpasswd >/dev/null 2>&1; then
        echo "$password" | htpasswd -bnBC 10 "" /dev/stdin | cut -d: -f2
    else
        log_error "htpasswd não encontrado. Instale: apt-get install apache2-utils (Ubuntu) ou brew install httpd (macOS)"
        exit 1
    fi
}

# Função para salvar secret no Azure Key Vault
save_secret_to_vault() {
    local secret_name="$1"
    local secret_value="$2"
    local description="$3"
    
    log_info "Salvando secret: $secret_name"
    
    # Verifica se já existe
    if az keyvault secret show --vault-name "$VAULT_NAME" --name "$secret_name" >/dev/null 2>&1; then
        log_warning "Secret $secret_name já existe. Atualizando..."
    fi
    
    # Salva no Key Vault (não expõe o valor nos logs)
    if printf "%s" "$secret_value" | az keyvault secret set \
        --vault-name "$VAULT_NAME" \
        --name "$secret_name" \
        --description "$description" \
        --file /dev/stdin >/dev/null 2>&1; then
        log_success "Secret $secret_name salvo com sucesso"
    else
        log_error "Falha ao salvar secret $secret_name"
        return 1
    fi
}

# Função principal
main() {
    log_info "🔐 Iniciando geração de secrets seguros para Traefik..."
    
    # Verificar dependências
    if ! command -v az >/dev/null 2>&1; then
        log_error "Azure CLI não encontrado. Instale: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command -v openssl >/dev/null 2>&1; then
        log_error "OpenSSL não encontrado"
        exit 1
    fi
    
    # Verificar autenticação Azure
    if ! az account show >/dev/null 2>&1; then
        log_error "Não autenticado no Azure. Execute: az login"
        exit 1
    fi
    
    log_info "Verificando acesso ao Key Vault: $VAULT_NAME"
    if ! az keyvault show --name "$VAULT_NAME" >/dev/null 2>&1; then
        log_error "Não foi possível acessar o Key Vault: $VAULT_NAME"
        exit 1
    fi
    
    # Secrets do Traefik que precisam ser criados
    declare -A traefik_secrets=(
        ["conexao-de-sorte-traefik-admin-password"]="Senha do administrador Traefik"
        ["conexao-de-sorte-traefik-crypto-password"]="Senha para serviços crypto"
        ["conexao-de-sorte-traefik-audit-password"]="Senha para serviços de auditoria"
        ["conexao-de-sorte-traefik-dashboard-password"]="Senha para dashboard Traefik"
    )
    
    # Gerar e salvar secrets
    for secret_name in "${!traefik_secrets[@]}"; do
        description="${traefik_secrets[$secret_name]}"
        
        # Gerar senha segura
        password=$(generate_secure_password 32)
        
        # Salvar no Key Vault
        save_secret_to_vault "$secret_name" "$password" "$description"
        
        # Limpar da memória
        unset password
    done
    
    log_success "🎉 Todos os secrets foram gerados e salvos no Azure Key Vault"
    log_info "📋 Secrets criados:"
    for secret_name in "${!traefik_secrets[@]}"; do
        echo "   - $secret_name"
    done
    
    log_info "🔍 Para verificar: az keyvault secret list --vault-name $VAULT_NAME"
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi