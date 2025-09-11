#!/bin/bash

# ============================================================================
# 🔧 CONFIGURADOR DINÂMICO DE AUTENTICAÇÃO TRAEFIK
# ============================================================================
# 
# Script para configurar middlewares de autenticação do Traefik
# usando secrets do Azure Key Vault de forma segura
#
# Uso: ./configure-dynamic-auth.sh
# ============================================================================

set -euo pipefail

# Configurações
VAULT_NAME="kv-conexao-de-sorte"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DYNAMIC_DIR="$SCRIPT_DIR/../traefik/dynamic"
TEMP_DIR="/tmp/traefik-auth-$$"

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

# Função para gerar hash bcrypt
generate_bcrypt_hash() {
    local password="$1"
    if command -v htpasswd >/dev/null 2>&1; then
        echo "$password" | htpasswd -bnBC 10 "" /dev/stdin | cut -d: -f2
    else
        log_error "htpasswd não encontrado"
        exit 1
    fi
}

# Função para recuperar secret do Azure Key Vault
get_secret_from_vault() {
    local secret_name="$1"
    az keyvault secret show --vault-name "$VAULT_NAME" --name "$secret_name" --query value -o tsv 2>/dev/null || {
        log_error "Falha ao recuperar secret: $secret_name"
        return 1
    }
}

# Função principal
main() {
    log_info "🔧 Configurando autenticação dinâmica do Traefik..."
    
    # Verificar dependências
    for cmd in az htpasswd; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd não encontrado"
            exit 1
        fi
    done
    
    # Verificar autenticação Azure
    if ! az account show >/dev/null 2>&1; then
        log_error "Não autenticado no Azure. Execute: az login"
        exit 1
    fi
    
    # Criar diretório temporário seguro
    mkdir -p "$TEMP_DIR"
    chmod 700 "$TEMP_DIR"
    trap "rm -rf '$TEMP_DIR'" EXIT
    
    log_info "Recuperando secrets do Azure Key Vault..."
    
    # Recuperar senhas do Key Vault
    declare -A passwords
    passwords["admin"]=$(get_secret_from_vault "conexao-de-sorte-traefik-admin-password")
    passwords["crypto"]=$(get_secret_from_vault "conexao-de-sorte-traefik-crypto-password") 
    passwords["audit"]=$(get_secret_from_vault "conexao-de-sorte-traefik-audit-password")
    passwords["dashboard"]=$(get_secret_from_vault "conexao-de-sorte-traefik-dashboard-password")
    
    log_info "Gerando hashes bcrypt seguros..."
    
    # Gerar hashes bcrypt
    declare -A hashes
    for user in "${!passwords[@]}"; do
        log_info "Gerando hash para usuário: $user"
        hashes["$user"]=$(generate_bcrypt_hash "${passwords[$user]}")
        # Limpar senha da memória
        unset passwords["$user"]
    done
    
    log_info "Criando arquivo de configuração dinâmica..."
    
    # Criar arquivo temporário com as configurações de auth
    cat > "$TEMP_DIR/auth-config.yml" <<EOF
http:
  middlewares:
    # Autenticação específica para serviços críticos
    crypto-auth:
      basicAuth:
        users:
          - "crypto:${hashes[crypto]}"
    
    audit-auth:
      basicAuth:
        users:
          - "audit:${hashes[audit]}"
    
    admin-auth:
      basicAuth:
        users:
          - "admin:${hashes[admin]}"
    
    dashboard-auth:
      basicAuth:
        users:
          - "traefik:${hashes[dashboard]}"
EOF
    
    # Backup do arquivo original
    if [[ -f "$DYNAMIC_DIR/middlewares.yml" ]]; then
        cp "$DYNAMIC_DIR/middlewares.yml" "$DYNAMIC_DIR/middlewares.yml.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backup criado: middlewares.yml.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Atualizar middlewares.yml mantendo outras configurações
    log_info "Atualizando configuração de middlewares..."
    
    # Usar awk para substituir apenas as seções de auth
    awk '
    BEGIN { in_auth_section = 0; skip_until_next_middleware = 0 }
    
    # Início de seções de autenticação que devem ser removidas
    /^[[:space:]]*crypto-auth:$|^[[:space:]]*audit-auth:$|^[[:space:]]*admin-auth:$|^[[:space:]]*dashboard-auth:$/ {
        in_auth_section = 1
        skip_until_next_middleware = 1
        next
    }
    
    # Próximo middleware (não-auth) - parar de pular linhas
    /^[[:space:]]*[a-zA-Z][a-zA-Z0-9_-]*:$/ && skip_until_next_middleware == 1 && !/^[[:space:]]*crypto-auth:$|^[[:space:]]*audit-auth:$|^[[:space:]]*admin-auth:$|^[[:space:]]*dashboard-auth:$/ {
        skip_until_next_middleware = 0
        in_auth_section = 0
    }
    
    # Inserir configurações de auth antes do primeiro middleware não-auth
    /^[[:space:]]*security-headers:$/ && !inserted_auth {
        # Ler e inserir arquivo de auth
        while ((getline line < "'"$TEMP_DIR/auth-config.yml"'") > 0) {
            if (line !~ /^http:$/ && line !~ /^[[:space:]]*middlewares:$/) {
                print line
            }
        }
        close("'"$TEMP_DIR/auth-config.yml"'")
        print ""
        inserted_auth = 1
    }
    
    # Imprimir linhas normais (não-auth ou fora de seção auth)
    !skip_until_next_middleware { print }
    ' "$DYNAMIC_DIR/middlewares.yml" > "$TEMP_DIR/middlewares_new.yml"
    
    # Verificar se o arquivo foi gerado corretamente
    if [[ -s "$TEMP_DIR/middlewares_new.yml" ]]; then
        mv "$TEMP_DIR/middlewares_new.yml" "$DYNAMIC_DIR/middlewares.yml"
        log_success "Configuração de autenticação atualizada com sucesso"
    else
        log_error "Falha ao gerar nova configuração"
        exit 1
    fi
    
    # Limpar hashes da memória
    for user in "${!hashes[@]}"; do
        unset hashes["$user"]
    done
    
    log_success "🎉 Autenticação dinâmica configurada com sucesso!"
    log_info "📋 Middlewares configurados:"
    echo "   - admin-auth (usuário: admin)"
    echo "   - crypto-auth (usuário: crypto)"
    echo "   - audit-auth (usuário: audit)"
    echo "   - dashboard-auth (usuário: traefik)"
    log_warning "🔐 As senhas estão armazenadas no Azure Key Vault: $VAULT_NAME"
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi