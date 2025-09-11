#!/bin/bash

# ============================================================================
# 🔍 VALIDADOR DE SECRETS NO AZURE KEY VAULT
# ============================================================================
# 
# Script para validar se todos os secrets necessários existem no Azure Key Vault
# e criar os que estão faltando baseado na lista fornecida pelo usuário
#
# Uso: ./validate-keyvault-secrets.sh
# ============================================================================

set -euo pipefail

# Configurações
VAULT_NAME="kv-conexao-de-sorte"

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

# Função para salvar secret
save_secret_to_vault() {
    local secret_name="$1"
    local secret_value="$2"
    local description="$3"
    
    if printf "%s" "$secret_value" | az keyvault secret set \
        --vault-name "$VAULT_NAME" \
        --name "$secret_name" \
        --description "$description" \
        --file /dev/stdin >/dev/null 2>&1; then
        log_success "Secret $secret_name criado"
        return 0
    else
        log_error "Falha ao criar secret $secret_name"
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
    log_info "🔍 Validando secrets no Azure Key Vault: $VAULT_NAME"
    
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
    
    # Lista completa de secrets baseada no fornecido pelo usuário
    declare -A expected_secrets=(
        # Alerting e Webhooks
        ["conexao-de-sorte-alerting-webhook-secret"]="Webhook para alertas"
        
        # API e Rate Limiting
        ["conexao-de-sorte-api-rate-limit-key"]="Chave para rate limiting API"
        ["conexao-de-sorte-auth-service-url"]="URL do serviço de autenticação"
        
        # Backup e Encryption
        ["conexao-de-sorte-backup-encryption-key"]="Chave de criptografia para backups"
        ["conexao-de-sorte-encryption-backup-key"]="Chave backup de criptografia"
        ["conexao-de-sorte-encryption-master-key"]="Chave mestre de criptografia"
        ["conexao-de-sorte-encryption-master-password"]="Senha mestre de criptografia"
        
        # CORS
        ["conexao-de-sorte-cors-allow-credentials"]="Configuração CORS allow credentials"
        ["conexao-de-sorte-cors-allowed-origins"]="Origens permitidas CORS"
        
        # Database
        ["conexao-de-sorte-database-host"]="Host do banco de dados"
        ["conexao-de-sorte-database-jdbc-url"]="URL JDBC do banco"
        ["conexao-de-sorte-database-password"]="Senha do banco de dados"
        ["conexao-de-sorte-database-port"]="Porta do banco de dados"
        ["conexao-de-sorte-database-proxysql-password"]="Senha ProxySQL"
        ["conexao-de-sorte-database-r2dbc-url"]="URL R2DBC do banco"
        ["conexao-de-sorte-database-url"]="URL do banco de dados"
        ["conexao-de-sorte-database-username"]="Usuário do banco de dados"
        ["conexao-de-sorte-db-host"]="Host DB alternativo"
        ["conexao-de-sorte-db-password"]="Senha DB alternativa"
        ["conexao-de-sorte-db-port"]="Porta DB alternativa"
        ["conexao-de-sorte-db-username"]="Usuário DB alternativo"
        
        # JWT
        ["conexao-de-sorte-jwt-issuer"]="Emissor JWT"
        ["conexao-de-sorte-jwt-jwks-uri"]="URI JWKS"
        ["conexao-de-sorte-jwt-key-id"]="ID da chave JWT"
        ["conexao-de-sorte-jwt-privateKey"]="Chave privada JWT"
        ["conexao-de-sorte-jwt-publicKey"]="Chave pública JWT"
        ["conexao-de-sorte-jwt-secret"]="Secret JWT"
        ["conexao-de-sorte-jwt-signing-key"]="Chave de assinatura JWT"
        ["conexao-de-sorte-jwt-verification-key"]="Chave de verificação JWT"
        
        # Kafka
        ["conexao-de-sorte-kafka-cluster-id"]="ID do cluster Kafka"
        
        # Monitoring
        ["conexao-de-sorte-monitoring-token"]="Token de monitoramento"
        
        # RabbitMQ
        ["conexao-de-sorte-rabbitmq-host"]="Host RabbitMQ"
        ["conexao-de-sorte-rabbitmq-password"]="Senha RabbitMQ"
        ["conexao-de-sorte-rabbitmq-port"]="Porta RabbitMQ"
        ["conexao-de-sorte-rabbitmq-username"]="Usuário RabbitMQ"
        ["conexao-de-sorte-rabbitmq-vhost"]="VHost RabbitMQ"
        
        # Redis
        ["conexao-de-sorte-redis-database"]="Database Redis"
        ["conexao-de-sorte-redis-host"]="Host Redis"
        ["conexao-de-sorte-redis-password"]="Senha Redis"
        ["conexao-de-sorte-redis-port"]="Porta Redis"
        
        # Recovery e Session
        ["conexao-de-sorte-recovery-token"]="Token de recuperação"
        ["conexao-de-sorte-session-secret"]="Secret de sessão"
        
        # Server
        ["conexao-de-sorte-server-port"]="Porta do servidor"
        
        # SSL
        ["conexao-de-sorte-ssl-enabled"]="SSL habilitado"
        ["conexao-de-sorte-ssl-keystore-password"]="Senha keystore SSL"
        ["conexao-de-sorte-ssl-keystore-path"]="Caminho keystore SSL"
    )
    
    log_info "📋 Verificando ${#expected_secrets[@]} secrets..."
    
    local missing_count=0
    local existing_count=0
    declare -a missing_secrets=()
    
    # Verificar cada secret
    for secret_name in "${!expected_secrets[@]}"; do
        if secret_exists "$secret_name"; then
            existing_count=$((existing_count + 1))
        else
            missing_count=$((missing_count + 1))
            missing_secrets+=("$secret_name")
            log_warning "Secret faltante: $secret_name"
        fi
    done
    
    log_info "📊 Resultado da verificação:"
    log_success "Secrets existentes: $existing_count/${#expected_secrets[@]}"
    if [[ $missing_count -gt 0 ]]; then
        log_warning "Secrets faltantes: $missing_count"
        
        # Perguntar se deve criar os secrets faltantes
        echo
        log_info "🔧 Deseja criar os secrets faltantes automaticamente? (y/N)"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log_info "🔧 Criando secrets faltantes..."
            
            for secret_name in "${missing_secrets[@]}"; do
                description="${expected_secrets[$secret_name]}"
                
                # Gerar valor apropriado baseado no nome do secret
                case "$secret_name" in
                    *password*|*secret*|*key*|*token*)
                        value=$(generate_secure_password 32)
                        ;;
                    *url*|*host*)
                        value=""
                        case "$secret_name" in
                            *database-url*|*db-host*)
                                value="localhost"
                                ;;
                            *jwt-jwks-uri*)
                                value="https://conexaodesorte.com.br/.well-known/jwks.json"
                                ;;
                            *auth-service-url*)
                                value="https://auth.conexaodesorte.com.br"
                                ;;
                            *rabbitmq-host*|*redis-host*)
                                value="localhost"
                                ;;
                        esac
                        ;;
                    *port*)
                        value="8080"
                        case "$secret_name" in
                            *redis-port*)
                                value="6379"
                                ;;
                            *rabbitmq-port*)
                                value="5672"
                                ;;
                            *database-port*|*db-port*)
                                value="3306"
                                ;;
                            *server-port*)
                                value="8080"
                                ;;
                        esac
                        ;;
                    *database*|*redis-database*)
                        value="0"
                        ;;
                    *username*)
                        value="conexao_user"
                        ;;
                    *enabled*)
                        value="true"
                        ;;
                    *issuer*)
                        value="https://auth.conexaodesorte.com.br"
                        ;;
                    *origins*)
                        value="https://conexaodesorte.com.br,https://www.conexaodesorte.com.br"
                        ;;
                    *credentials*)
                        value="true"
                        ;;
                    *vhost*)
                        value="/"
                        ;;
                    *cluster-id*)
                        value=$(generate_secure_password 16)
                        ;;
                    *)
                        value=$(generate_secure_password 32)
                        ;;
                esac
                
                save_secret_to_vault "$secret_name" "$value" "$description"
                unset value
            done
            
            log_success "🎉 Todos os secrets foram criados!"
        else
            log_info "ℹ️  Secrets não foram criados. Lista de faltantes salva em missing_secrets.txt"
            printf '%s\n' "${missing_secrets[@]}" > missing_secrets.txt
        fi
    else
        log_success "🎉 Todos os secrets necessários existem no Key Vault!"
    fi
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi