#!/bin/bash

# Script Automático para Configurar Segredos no Azure Key Vault
# Configura apenas os segredos essenciais: email e senha do dashboard

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Configurador Automático de Segredos do Azure Key Vault${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# Configurações automáticas
LETSENCRYPT_EMAIL="facilitaservicos.tec@gmail.com"
KEYVAULT_NAME="kv-conexao-de-sorte"  # Usando o Key Vault existente

# Função para gerar senha segura
generate_secure_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Função para criar segredo com segurança
create_secret_safe() {
    local vault_name=$1
    local secret_name=$2
    local secret_value=$3
    local description=$4
    
    echo -e "${YELLOW}🔍 Processando segredo: $secret_name${NC}"
    
    # Criar/atualizar segredo
    echo -e "${YELLOW}📝 Configurando segredo...${NC}"
    if az keyvault secret set \
        --vault-name "$vault_name" \
        --name "$secret_name" \
        --value "$secret_value" \
        --description "$description" \
        --output none; then
        echo -e "${GREEN}✅ Segredo configurado com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro ao criar segredo${NC}"
        return 1
    fi
}

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI não está instalada${NC}"
    echo -e "${YELLOW}ℹ️ Instale com: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI está instalada${NC}"

# Verificar login no Azure
echo -e "${YELLOW}🔍 Verificando login no Azure...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Você precisa estar logado no Azure${NC}"
    echo -e "${YELLOW}🔄 Execute: az login${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Logado no Azure${NC}"

# Verificar Key Vault
echo -e "${YELLOW}🔍 Verificando Key Vault: $KEYVAULT_NAME${NC}"
if ! az keyvault show --name "$KEYVAULT_NAME" --query name &>/dev/null; then
    echo -e "${RED}❌ Key Vault não encontrado: $KEYVAULT_NAME${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Key Vault encontrado: $KEYVAULT_NAME${NC}"

# Configurar segredos essenciais
echo ""
echo -e "${BLUE}🔑 Configurando Segredos Essenciais${NC}"
echo -e "${BLUE}=================================${NC}"

# 1. Email Let's Encrypt
echo ""
echo -e "${YELLOW}📧 Configurando email Let's Encrypt...${NC}"
echo -e "${YELLOW}📧 Email: $LETSENCRYPT_EMAIL${NC}"
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-letsencrypt-email" "$LETSENCRYPT_EMAIL" "Email para registro Let's Encrypt (SSL automático)"

# 2. Senha do Dashboard (gerar automaticamente)
echo ""
echo -e "${YELLOW}🔐 Gerando senha segura para o dashboard...${NC}"
DASHBOARD_PASSWORD=$(generate_secure_password 24)
echo -e "${YELLOW}ℹ️ Senha gerada (não será exibida por segurança)${NC}"
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-traefik-dashboard-password" "$DASHBOARD_PASSWORD" "Senha de acesso ao dashboard Traefik"

# Resumo final
echo ""
echo -e "${BLUE}📊 Resumo da Configuração${NC}"
echo -e "${BLUE}=======================${NC}"
echo -e "${GREEN}✅ Configuração concluída com sucesso!${NC}"
echo ""
echo -e "${YELLOW}📋 Segredos configurados no Key Vault: $KEYVAULT_NAME${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-letsencrypt-email: $LETSENCRYPT_EMAIL${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-traefik-dashboard-password: [SENHA GERADA - NÃO EXIBIDA]${NC}"
echo ""
echo -e "${GREEN}🚀 O pipeline CI/CD agora deve funcionar corretamente!${NC}"
echo -e "${GREEN}   Configure os segredos do GitHub Actions e execute o workflow.${NC}"

# Verificar permissões
echo ""
echo -e "${YELLOW}🔍 Verificando permissões do Key Vault...${NC}"
echo -e "${YELLOW}Subscription atual: $(az account show --query name -o tsv)${NC}"
echo -e "${YELLOW}Tenant ID: $(az account show --query tenantId -o tsv)${NC}"
echo -e "${YELLOW}User/Service Principal: $(az account show --query user.name -o tsv 2>/dev/null || echo 'Service Principal')${NC}"

echo -e "${GREEN}✅ Script concluído!${NC}"