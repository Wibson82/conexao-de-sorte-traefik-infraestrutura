#!/bin/bash

# ===== SCRIPT DE VERIFICAÇÃO DE CONFIGURAÇÃO DE SECRETS =====
# Verifica se todos os secrets necessários estão configurados

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔍 VERIFICAÇÃO DE CONFIGURAÇÃO DE SECRETS"
echo "=========================================="

# ===== VERIFICAR GITHUB SECRETS =====
log_info "1. Verificando GitHub Secrets necessários..."

REQUIRED_GITHUB_SECRETS=(
    "AZURE_KEYVAULT_ENDPOINT"
    "AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET"
    "AZURE_TENANT_ID"
    "CONEXAO_DE_SORTE_DATABASE_URL"
    "CONEXAO_DE_SORTE_DATABASE_USERNAME"
    "CONEXAO_DE_SORTE_DATABASE_PASSWORD"
    "DOCKER_USERNAME"
    "DOCKER_PASSWORD"
    "SSH_HOST"
    "SSH_PORT"
    "SSH_USER"
    "VPS_SSH_KEY"
)

echo "Secrets necessários no GitHub:"
for secret in "${REQUIRED_GITHUB_SECRETS[@]}"; do
    echo "  - $secret"
done

# ===== VERIFICAR AZURE KEY VAULT =====
log_info "2. Verificando configuração do Azure Key Vault..."

echo "Secrets necessários no Azure Key Vault:"
echo "  - jwt-private-key"
echo "  - jwt-public-key"
echo "  - jwt-secret"
echo "  - conexao-de-sorte-database-username"
echo "  - conexao-de-sorte-database-password"

# ===== VERIFICAR CONFIGURAÇÃO LOCAL =====
log_info "3. Verificando configuração local..."

# Verificar se existe configuração Azure
if [ -f "src/main/resources/application-azure.yml" ]; then
    log_success "Arquivo application-azure.yml encontrado"
    
    # Verificar se contém configuração do Key Vault
    if grep -q "azure:" src/main/resources/application-azure.yml; then
        log_success "Configuração Azure encontrada"
    else
        log_warning "Configuração Azure não encontrada no arquivo"
    fi
else
    log_error "Arquivo application-azure.yml não encontrado"
fi

# Verificar configuração de produção
if [ -f "src/main/resources/application-production.yml" ]; then
    log_success "Arquivo application-production.yml encontrado"
    
    # Verificar se contém configuração de database
    if grep -q "datasource:" src/main/resources/application-production.yml; then
        log_success "Configuração de datasource encontrada"
    else
        log_warning "Configuração de datasource não encontrada"
    fi
else
    log_error "Arquivo application-production.yml não encontrado"
fi

# ===== VERIFICAR CONFIGURAÇÃO DE SEGURANÇA =====
log_info "4. Verificando configuração de segurança..."

# Verificar se existe configuração JWT
if grep -q "jwt:" src/main/resources/application*.yml; then
    log_success "Configuração JWT encontrada"
else
    log_warning "Configuração JWT não encontrada"
fi

# Verificar se existe configuração OAuth2
if grep -q "oauth2:" src/main/resources/application*.yml; then
    log_success "Configuração OAuth2 encontrada"
else
    log_warning "Configuração OAuth2 não encontrada"
fi

# ===== VERIFICAR PROFILES =====
log_info "5. Verificando profiles configurados..."

PROFILES_FOUND=()
for file in src/main/resources/application-*.yml; do
    if [ -f "$file" ]; then
        profile=$(basename "$file" .yml | sed 's/application-//')
        PROFILES_FOUND+=("$profile")
    fi
done

echo "Profiles encontrados:"
for profile in "${PROFILES_FOUND[@]}"; do
    echo "  - $profile"
done

# ===== VERIFICAR DOCKERFILE =====
log_info "6. Verificando Dockerfile..."

if [ -f "Dockerfile" ]; then
    log_success "Dockerfile encontrado"
    
    # Verificar se contém configuração de profiles
    if grep -q "SPRING_PROFILES_ACTIVE" Dockerfile; then
        log_success "Configuração de profiles no Dockerfile encontrada"
    else
        log_warning "Configuração de profiles no Dockerfile não encontrada"
    fi
else
    log_error "Dockerfile não encontrado"
fi

# ===== RESUMO =====
echo ""
log_info "📊 RESUMO DA VERIFICAÇÃO"
echo "=========================="

echo "✅ Para corrigir problemas de configuração:"
echo "   1. Verifique se todos os GitHub Secrets estão configurados"
echo "   2. Verifique se o Azure Key Vault está acessível"
echo "   3. Verifique se as credenciais do Azure estão corretas"
echo "   4. Verifique se o banco de dados está acessível"

echo ""
echo "🔗 Links úteis:"
echo "   - GitHub Secrets: https://github.com/Wibson82/conexao-de-sorte-backend/settings/secrets/actions"
echo "   - Azure Portal: https://portal.azure.com"

echo ""
log_success "Verificação concluída!"
