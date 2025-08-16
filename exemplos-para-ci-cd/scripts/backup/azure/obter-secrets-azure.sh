#!/bin/bash

# 🔐 Script para obter secrets do Azure Key Vault
# ✅ Usado pelo init container azure-secrets no docker-compose.prod.yml
# ✅ Conecta ao Azure Key Vault e obtém secrets sensíveis
# ✅ Zero dependência de arquivos .env para secrets

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SECRETS_DIR="/secrets"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5

# Required environment variables
readonly REQUIRED_VARS=(
    "AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET" 
    "AZURE_TENANT_ID"
    "AZURE_KEYVAULT_NAME"
)

# Secrets mapping: KEY_VAULT_SECRET_NAME -> OUTPUT_FILE
# Ajuste os nomes de acordo com seu Key Vault
declare -A SECRETS_MAP=(
    ["<db-password-secret>"]="mysql_password"
    ["<db-root-secret>"]="mysql_root_password"
    ["<db-user-secret>"]="mysql_username"
    ["<db-url-secret>"]="mysql_url"
)

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] 🔐 Azure Key Vault:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ Azure Key Vault:${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  Azure Key Vault:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ Azure Key Vault:${NC} $1" >&2
}

# Check required environment variables
check_environment() {
    log "Verificando variáveis de ambiente..."
    
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variável de ambiente obrigatória não definida: $var"
            return 1
        fi
    done
    
    log_success "Todas as variáveis de ambiente estão definidas"
}

# Login to Azure
azure_login() {
    log "Fazendo login no Azure..."
    
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        if az login --service-principal \
            --username "$AZURE_CLIENT_ID" \
            --password "$AZURE_CLIENT_SECRET" \
            --tenant "$AZURE_TENANT_ID" \
            --output none 2>/dev/null; then
            log_success "Login no Azure realizado com sucesso"
            return 0
        fi
        
        log_warn "Tentativa $attempt/$MAX_RETRIES de login falhou. Aguardando ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        ((attempt++))
    done
    
    log_error "Falha no login após $MAX_RETRIES tentativas"
    return 1
}

# Get secret from Key Vault
get_secret() {
    local secret_name="$1"
    local output_file="$2"
    local output_path="$SECRETS_DIR/$output_file"
    
    log "Obtendo secret: $secret_name -> $output_file"
    
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        if az keyvault secret show \
            --vault-name "$AZURE_KEYVAULT_NAME" \
            --name "$secret_name" \
            --query "value" \
            --output tsv > "$output_path" 2>/dev/null; then
            
            # Verify secret was retrieved and is not empty
            if [[ -s "$output_path" ]]; then
                local size=$(wc -c < "$output_path")
                chmod 600 "$output_path"
                log_success "Secret obtido: $secret_name ($size bytes)"
                return 0
            else
                log_warn "Secret $secret_name está vazio"
                rm -f "$output_path"
            fi
        fi
        
        log_warn "Tentativa $attempt/$MAX_RETRIES para $secret_name falhou. Aguardando ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        ((attempt++))
    done
    
    log_error "Falha ao obter secret $secret_name após $MAX_RETRIES tentativas"
    return 1
}

# Get all secrets
get_all_secrets() {
    log "Obtendo todos os secrets do MySQL..."
    
    # Create secrets directory
    mkdir -p "$SECRETS_DIR"
    
    local failed_secrets=()
    local success_count=0
    
    for secret_name in "${!SECRETS_MAP[@]}"; do
        local output_file="${SECRETS_MAP[$secret_name]}"
        
        if get_secret "$secret_name" "$output_file"; then
            ((success_count++))
        else
            failed_secrets+=("$secret_name")
        fi
    done
    
    log "Resultado: $success_count/${#SECRETS_MAP[@]} secrets obtidos com sucesso"
    
    if [[ ${#failed_secrets[@]} -gt 0 ]]; then
        log_error "Secrets que falharam: ${failed_secrets[*]}"
        return 1
    fi
    
    log_success "Todos os secrets foram obtidos com sucesso!"
}

# Verify secrets
verify_secrets() {
    log "Verificando integridade dos secrets..."
    
    local verification_failed=false
    
    for secret_name in "${!SECRETS_MAP[@]}"; do
        local output_file="${SECRETS_MAP[$secret_name]}"
        local output_path="$SECRETS_DIR/$output_file"
        
        if [[ ! -f "$output_path" ]]; then
            log_error "Arquivo de secret não encontrado: $output_path"
            verification_failed=true
        elif [[ ! -s "$output_path" ]]; then
            log_error "Arquivo de secret está vazio: $output_path"
            verification_failed=true
        else
            local size=$(wc -c < "$output_path")
            local perms=$(stat -c "%a" "$output_path" 2>/dev/null || stat -f "%OLp" "$output_path")
            log "Secret OK: $output_file ($size bytes, perms: $perms)"
        fi
    done
    
    if [[ "$verification_failed" == "true" ]]; then
        log_error "Verificação de secrets falhou"
        return 1
    fi
    
    log_success "Verificação de secrets concluída com sucesso"
}

# Cleanup on exit
cleanup() {
    log "Fazendo logout do Azure..."
    az logout 2>/dev/null || true
}

# Main execution
main() {
    log "🚀 Iniciando obtenção de secrets do Azure Key Vault..."
    
    # Set cleanup trap
    trap cleanup EXIT
    
    # Execute steps
    check_environment || exit 1
    azure_login || exit 1
    get_all_secrets || exit 1
    verify_secrets || exit 1
    
    log_success "🎯 Processo concluído com sucesso!"
    log "📊 Secrets disponíveis em: $SECRETS_DIR"
    log "🔐 Arquivos criados:"
    ls -la "$SECRETS_DIR"/ 2>/dev/null || true
}

# Execute if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
