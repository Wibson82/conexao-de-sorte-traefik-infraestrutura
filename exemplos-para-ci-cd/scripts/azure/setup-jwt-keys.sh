#!/bin/bash

# =============================================================================
# SCRIPT: Setup JWT Keys no Azure Key Vault
# =============================================================================
# Objetivo: Criar e configurar chaves JWT RSA-4096 no Azure Key Vault
# Uso: ./scripts/azure/setup-jwt-keys.sh
# =============================================================================

set -euo pipefail

# Configurações
VAULT_NAME="chave-conexao-de-sorte"
KEY_SIZE=4096
TEMP_DIR="/tmp/jwt-keys-$$"
MASTER_PASSWORD="${APP_ENCRYPTION_MASTER_PASSWORD:-}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Setup JWT Keys no Azure Key Vault${NC}"
echo "=================================="

# Verificar se Azure CLI está logado
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}❌ Azure CLI não está logado${NC}"
    echo "Execute: az login"
    exit 1
fi

# Verificar se o Key Vault existe
if ! az keyvault show --name "$VAULT_NAME" >/dev/null 2>&1; then
    echo -e "${RED}❌ Key Vault '$VAULT_NAME' não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI logado e Key Vault encontrado${NC}"

# Criar diretório temporário
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}🔑 Gerando par de chaves RSA-$KEY_SIZE...${NC}"

# Gerar chave privada RSA
openssl genrsa -out "$TEMP_DIR/jwt-private-key.pem" $KEY_SIZE

# Extrair chave pública
openssl rsa -in "$TEMP_DIR/jwt-private-key.pem" -pubout -out "$TEMP_DIR/jwt-public-key.pem"

# Gerar ID único para a chave
KEY_ID="conexao-sorte-$(date +%Y%m%d-%H%M%S)"

echo -e "${GREEN}✅ Chaves geradas com sucesso${NC}"
echo "   - Chave privada: RSA-$KEY_SIZE"
echo "   - ID da chave: $KEY_ID"

# Verificar se master password está disponível para criptografia
if [[ -n "$MASTER_PASSWORD" ]]; then
    echo -e "${BLUE}🔒 Criptografando chave privada...${NC}"
    
    # Criptografar chave privada usando AES-256-CBC
    openssl enc -aes-256-cbc -salt -in "$TEMP_DIR/jwt-private-key.pem" \
        -out "$TEMP_DIR/jwt-private-key-encrypted.pem" \
        -pass "pass:$MASTER_PASSWORD"
    
    PRIVATE_KEY_CONTENT=$(cat "$TEMP_DIR/jwt-private-key-encrypted.pem" | base64 -w 0)
    echo -e "${GREEN}✅ Chave privada criptografada${NC}"
else
    echo -e "${YELLOW}⚠️ APP_ENCRYPTION_MASTER_PASSWORD não definido - salvando chave sem criptografia${NC}"
    PRIVATE_KEY_CONTENT=$(cat "$TEMP_DIR/jwt-private-key.pem")
fi

PUBLIC_KEY_CONTENT=$(cat "$TEMP_DIR/jwt-public-key.pem")

echo -e "${BLUE}☁️ Salvando chaves no Azure Key Vault...${NC}"

# Salvar chave privada
az keyvault secret set \
    --vault-name "$VAULT_NAME" \
    --name "jwt-private-key" \
    --value "$PRIVATE_KEY_CONTENT" \
    --description "JWT RSA-$KEY_SIZE Private Key ($(date))" \
    >/dev/null

# Salvar chave pública
az keyvault secret set \
    --vault-name "$VAULT_NAME" \
    --name "jwt-public-key" \
    --value "$PUBLIC_KEY_CONTENT" \
    --description "JWT RSA-$KEY_SIZE Public Key ($(date))" \
    >/dev/null

# Salvar ID da chave
az keyvault secret set \
    --vault-name "$VAULT_NAME" \
    --name "jwt-key-id" \
    --value "$KEY_ID" \
    --description "JWT Key ID ($(date))" \
    >/dev/null

# Salvar secret JWT (opcional)
JWT_SECRET=$(openssl rand -base64 64)
az keyvault secret set \
    --vault-name "$VAULT_NAME" \
    --name "jwt-secret" \
    --value "$JWT_SECRET" \
    --description "JWT Secret ($(date))" \
    >/dev/null

echo -e "${GREEN}✅ Chaves salvas no Azure Key Vault com sucesso!${NC}"
echo ""
echo -e "${BLUE}📋 Resumo:${NC}"
echo "   - Vault: $VAULT_NAME"
echo "   - Chave privada: jwt-private-key"
echo "   - Chave pública: jwt-public-key"
echo "   - ID da chave: jwt-key-id ($KEY_ID)"
echo "   - JWT Secret: jwt-secret"
echo "   - Criptografia: $([ -n "$MASTER_PASSWORD" ] && echo "AES-256-CBC" || echo "Não aplicada")"
echo ""
echo -e "${GREEN}🚀 Pronto! As chaves JWT estão configuradas no Azure Key Vault.${NC}"
echo -e "${YELLOW}💡 Reinicie a aplicação para carregar as novas chaves.${NC}"
