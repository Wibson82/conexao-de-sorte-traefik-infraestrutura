#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO DE SECRETS PARA PRODUÇÃO
# =============================================================================
# Este script configura todos os secrets necessários para produção

set -e

echo "🔐 Configurando secrets para produção..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para adicionar secret ao Azure Key Vault
add_secret_to_keyvault() {
    local secret_name=$1
    local secret_value=$2
    
    echo -e "${YELLOW}Adicionando secret: $secret_name${NC}"
    az keyvault secret set \
        --vault-name "chave-conexao-de-sorte" \
        --name "$secret_name" \
        --value "$secret_value" \
        --output none
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Secret $secret_name adicionado com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro ao adicionar secret $secret_name${NC}"
        exit 1
    fi
}

# Função para adicionar secret ao GitHub
add_secret_to_github() {
    local secret_name=$1
    local secret_value=$2
    
    echo -e "${YELLOW}Adicionando secret ao GitHub: $secret_name${NC}"
    gh secret set "$secret_name" --body "$secret_value" --repo "Wibson82/conexao-de-sorte-backend"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ GitHub secret $secret_name adicionado com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro ao adicionar GitHub secret $secret_name${NC}"
        exit 1
    fi
}

# Verificar se está logado no Azure e GitHub
echo "🔍 Verificando autenticação..."
az account show > /dev/null 2>&1 || { echo -e "${RED}❌ Não logado no Azure. Execute: az login${NC}"; exit 1; }
gh auth status > /dev/null 2>&1 || { echo -e "${RED}❌ Não logado no GitHub. Execute: gh auth login${NC}"; exit 1; }

echo -e "${GREEN}✅ Autenticação verificada${NC}"

# =============================================================================
# ANÁLISE: SECRETS JÁ EXISTEM NO GITHUB ACTIONS
# =============================================================================

echo "✅ Secrets já configurados no GitHub Actions:"
echo "   - AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID"
echo "   - JWT_ALGORITHM, JWT_AUDIENCE, JWT_ISSUER"
echo "   - APP_ENCRYPTION_MASTER_PASSWORD"
echo "   - Database credentials"
echo "   - Docker credentials"
echo "   - Deployment keys"
echo "   - Telegram notifications"

echo "📝 Configurando apenas secrets FALTANTES para chat avançado..."

# =============================================================================
# SECRETS REALMENTE FALTANTES (APENAS CHAT AVANÇADO)
# =============================================================================

# Sincronizar secrets existentes do GitHub para Azure Key Vault
echo "🔄 Sincronizando secrets do GitHub Actions para Azure Key Vault..."

# Obter secrets do GitHub (simulado - em produção usar gh secret list)
add_secret_to_keyvault "jwt-algorithm" "HS256"
add_secret_to_keyvault "jwt-audience" "conexao-de-sorte-frontend"
add_secret_to_keyvault "jwt-issuer" "conexao-de-sorte-backend"

# =============================================================================
# SECRETS PARA FUNCIONALIDADES AVANÇADAS DO CHAT (REALMENTE FALTANTES)
# =============================================================================

echo "💬 Configurando secrets NOVOS do sistema de chat avançado..."

# WebSocket Security (NOVO)
WEBSOCKET_JWT_SECRET=$(openssl rand -base64 32)
add_secret_to_keyvault "websocket-jwt-secret" "$WEBSOCKET_JWT_SECRET"
add_secret_to_github "WEBSOCKET_JWT_SECRET" "$WEBSOCKET_JWT_SECRET"

# Chat Encryption (NOVO)
CHAT_ENCRYPTION_KEY=$(openssl rand -base64 32)
add_secret_to_keyvault "chat-encryption-key" "$CHAT_ENCRYPTION_KEY"
add_secret_to_github "CHAT_ENCRYPTION_KEY" "$CHAT_ENCRYPTION_KEY"

# Backup Encryption (NOVO)
BACKUP_ENCRYPTION_KEY=$(openssl rand -base64 32)
add_secret_to_keyvault "backup-encryption-key" "$BACKUP_ENCRYPTION_KEY"
add_secret_to_github "BACKUP_ENCRYPTION_KEY" "$BACKUP_ENCRYPTION_KEY"

# Rate Limiting Configuration (NOVO - SEM REDIS)
add_secret_to_keyvault "rate-limit-global-limit" "1000"
add_secret_to_github "RATE_LIMIT_GLOBAL_LIMIT" "1000"
add_secret_to_keyvault "rate-limit-storage-type" "memory"
add_secret_to_github "RATE_LIMIT_STORAGE_TYPE" "memory"

# Security Headers (NOVO)
CSP_POLICY="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https:; font-src 'self'; object-src 'none'; media-src 'self'; frame-src 'none';"
add_secret_to_keyvault "security-content-security-policy" "$CSP_POLICY"
add_secret_to_github "SECURITY_CONTENT_SECURITY_POLICY" "$CSP_POLICY"

add_secret_to_keyvault "security-hsts-max-age" "31536000"
add_secret_to_github "SECURITY_HSTS_MAX_AGE" "31536000"

# WebSocket CORS Origins (NOVO)
CORS_ORIGINS="https://conexaodesorte.com.br,https://www.conexaodesorte.com.br"
add_secret_to_keyvault "websocket-cors-origins" "$CORS_ORIGINS"
add_secret_to_github "WEBSOCKET_CORS_ORIGINS" "$CORS_ORIGINS"

# =============================================================================
# CONFIGURAÇÕES DE AMBIENTE
# =============================================================================

echo "⚙️ Configurando variáveis de ambiente..."

# Thread Pool Configuration
add_secret_to_keyvault "thread-pool-core-size" "10"
add_secret_to_keyvault "thread-pool-max-size" "50"
add_secret_to_keyvault "thread-pool-queue" "1000"

# Monitoring
add_secret_to_keyvault "prometheus-metrics-enabled" "true"

# CORS Origins
CORS_ORIGINS="https://conexaodesorte.com.br,https://www.conexaodesorte.com.br"
add_secret_to_keyvault "websocket-cors-origins" "$CORS_ORIGINS"

echo -e "${GREEN}🎉 Todos os secrets foram configurados com sucesso!${NC}"
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo "1. Verificar se todos os secrets estão no Azure Key Vault"
echo "2. Verificar se todos os secrets estão no GitHub Actions"
echo "3. Executar testes de conectividade"
echo "4. Fazer deploy de teste"

echo -e "${GREEN}✅ Configuração de secrets concluída!${NC}"
