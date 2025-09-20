#!/usr/bin/env bash
# Script para criar segredos essenciais do Traefik Infrastructure no Azure Key Vault
# Uso: ./setup-keyvault-secrets.sh [KEY_VAULT_NAME] [EMAIL]

set -Eeuo pipefail
IFS=$'\n\t'

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    log_error "Azure CLI não está instalada. Por favor, instale a Azure CLI primeiro."
    exit 1
fi

# Verificar se está logado
if ! az account show &> /dev/null; then
    log_error "Você não está logado no Azure. Execute: az login"
    exit 1
fi

# Obter parâmetros
KEY_VAULT_NAME="${1:-}"
EMAIL="${2:-}"

# Se não fornecido, tentar obter da variável de ambiente
if [[ -z "$KEY_VAULT_NAME" ]]; then
    KEY_VAULT_NAME="${AZURE_KEYVAULT_NAME:-}"
fi

# Validar parâmetros
if [[ -z "$KEY_VAULT_NAME" ]]; then
    echo "Uso: $0 [KEY_VAULT_NAME] [EMAIL]"
    echo "Ou defina AZURE_KEYVAULT_NAME como variável de ambiente"
    exit 1
fi

if [[ -z "$EMAIL" ]]; then
    read -p "Digite o email para Let's Encrypt: " EMAIL
    if [[ -z "$EMAIL" ]]; then
        log_error "Email é obrigatório"
        exit 1
    fi
fi

# Validar email
if ! [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    log_error "Email inválido: $EMAIL"
    exit 1
fi

log_info "Configurando segredos do Traefik Infrastructure no Key Vault: $KEY_VAULT_NAME"
log_info "Email para Let's Encrypt: $EMAIL"
echo

# Verificar se o Key Vault existe
log_step "Verificando se o Key Vault existe..."
if ! az keyvault show --name "$KEY_VAULT_NAME" &>/dev/null; then
    log_error "Key Vault não encontrado: $KEY_VAULT_NAME"
    exit 1
fi
log_info "✅ Key Vault encontrado"

# Função para criar ou atualizar segredo
create_secret() {
    local name="$1"
    local value="$2"
    local description="$3"
    
    log_step "Criando/Atualizando segredo: $name"
    
    if az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "$name" \
        --value "$value" \
        --description "$description" &>/dev/null; then
        log_info "✅ Segredo criado/atualizado: $name"
        return 0
    else
        log_error "❌ Falha ao criar segredo: $name"
        return 1
    fi
}

# 1. Criar segredo do email Let's Encrypt
log_step "1. Criando segredo do email Let's Encrypt..."
create_secret \
    "conexao-de-sorte-letsencrypt-email" \
    "$EMAIL" \
    "Email para registro Let's Encrypt no Traefik Infrastructure"

# 2. Criar segredo da senha do dashboard
log_step "2. Criando senha segura para o dashboard Traefik..."
DASHBOARD_PASSWORD=$(openssl rand -base64 32)
create_secret \
    "conexao-de-sorte-traefik-dashboard-password" \
    "$DASHBOARD_PASSWORD" \
    "Senha do dashboard Traefik Infrastructure (gerada automaticamente)"

# 3. Criar segredos opcionais (se não existirem)
echo
log_info "📋 Verificando e criando segredos opcionais..."

# SSL Cert Password (opcional)
if ! az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "conexao-de-sorte-ssl-cert-password" &>/dev/null; then
    log_step "Criando senha SSL opcional..."
    SSL_PASSWORD=$(openssl rand -base64 24)
    create_secret \
        "conexao-de-sorte-ssl-cert-password" \
        "$SSL_PASSWORD" \
        "Senha para certificados SSL (opcional)"
else
    log_info "✅ Senha SSL já existe (opcional)"
fi

# Admin Password (opcional)
if ! az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "conexao-de-sorte-traefik-admin-password" &>/dev/null; then
    log_step "Criando senha admin opcional..."
    ADMIN_PASSWORD=$(openssl rand -base64 24)
    create_secret \
        "conexao-de-sorte-traefik-admin-password" \
        "$ADMIN_PASSWORD" \
        "Senha admin Traefik (opcional)"
else
    log_info "✅ Senha admin já existe (opcional)"
fi

# Audit Password (opcional)
if ! az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "conexao-de-sorte-traefik-audit-password" &>/dev/null; then
    log_step "Criando senha de auditoria opcional..."
    AUDIT_PASSWORD=$(openssl rand -base64 24)
    create_secret \
        "conexao-de-sorte-traefik-audit-password" \
        "$AUDIT_PASSWORD" \
        "Senha de auditoria Traefik (opcional)"
else
    log_info "✅ Senha de auditoria já existe (opcional)"
fi

# Crypto Password (opcional)
if ! az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "conexao-de-sorte-traefik-crypto-password" &>/dev/null; then
    log_step "Criando senha criptográfica opcional..."
    CRYPTO_PASSWORD=$(openssl rand -base64 24)
    create_secret \
        "conexao-de-sorte-traefik-crypto-password" \
        "$CRYPTO_PASSWORD" \
        "Senha criptográfica Traefik (opcional)"
else
    log_info "✅ Senha criptográfica já existe (opcional)"
fi

echo
log_step "Verificando todos os segredos criados..."
echo

# Listar todos os segredos do Traefik
log_info "📊 Segredos do Traefik Infrastructure no Key Vault:"
az keyvault secret list --vault-name "$KEY_VAULT_NAME" --query "[].name" -o tsv | grep "conexao-de-sorte-traefik\\|conexao-de-sorte-letsencrypt" | sort

echo
log_info "✅ Configuração concluída!"
echo
echo "📋 Resumo:"
echo "- ✅ Email Let's Encrypt: $EMAIL"
echo "- ✅ Senha do dashboard: [GERADA AUTOMATICAMENTE]"
echo "- ✅ Segredos opcionais: Criados se não existissem"
echo
echo "🔑 A senha do dashboard foi gerada automaticamente."
echo "📋 Para visualizar: az keyvault secret show --vault-name $KEY_VAULT_NAME --name conexao-de-sorte-traefik-dashboard-password --query value -o tsv"
echo
echo "🚀 Próximo passo: Execute o pipeline CI/CD!"
echo "   Actions > CI/CD Pipeline > Run workflow"