#!/bin/bash

# Script Local para Configurar Segredos no Azure Key Vault
# Este script configura os segredos necessários para o pipeline CI/CD

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Configurador de Segredos do Azure Key Vault${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Função para gerar senha segura
generate_secure_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Função para criar/mostrar segredo com segurança
create_secret_safe() {
    local vault_name=$1
    local secret_name=$2
    local secret_value=$3
    local description=$4
    
    echo -e "${YELLOW}🔍 Verificando segredo: $secret_name${NC}"
    
    # Verificar se o segredo já existe
    if az keyvault secret show --name "$secret_name" --vault-name "$vault_name" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Segredo já existe. Deseja sobrescrever? (s/N): ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}⏭️  Pulando segredo existente${NC}"
            return 0
        fi
    fi
    
    # Criar/atualizar segredo
    echo -e "${YELLOW}📝 Criando/Atualizando segredo: $secret_name${NC}"
    if az keyvault secret set \
        --vault-name "$vault_name" \
        --name "$secret_name" \
        --value "$secret_value" \
        --description "$description" \
        --output none; then
        echo -e "${GREEN}✅ Segredo criado/atualizado com sucesso${NC}"
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
    echo -e "${YELLOW}🔄 Faça login no Azure:${NC}"
    az login
fi
echo -e "${GREEN}✅ Logado no Azure${NC}"

# Mostrar subscription atual
echo -e "${YELLOW}📊 Subscription atual:${NC}"
az account show --query "{Name:name, ID:id, Tenant:tenantId}" --output table

# Obter informações do Key Vault
echo ""
echo -e "${BLUE}🏦 Configuração do Key Vault${NC}"
echo -e "${BLUE}=========================${NC}"

# Listar Key Vaults disponíveis
echo -e "${YELLOW}📋 Key Vaults disponíveis na subscription atual:${NC}"
az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" --output table

echo ""
echo -e "${YELLOW}🔤 Digite o nome do Key Vault que deseja usar:${NC}"
read -r KEYVAULT_NAME

# Verificar se o Key Vault existe
echo -e "${YELLOW}🔍 Verificando se o Key Vault existe...${NC}"
if ! az keyvault show --name "$KEYVAULT_NAME" --query name &>/dev/null; then
    echo -e "${RED}❌ Key Vault não encontrado: $KEYVAULT_NAME${NC}"
    echo -e "${YELLOW}ℹ️ Crie um Key Vault primeiro ou escolha um existente${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Key Vault encontrado: $KEYVAULT_NAME${NC}"

# Obter email para Let's Encrypt
echo ""
echo -e "${BLUE}📧 Configuração do Email Let's Encrypt${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${YELLOW}📧 Digite o email para Let's Encrypt (será usado para SSL):${NC}"
echo -e "${YELLOW}ℹ️ Será configurado como: facilitaservicos.tec@gmail.com${NC}"
echo -e "${YELLOW}Pressione ENTER para usar o valor padrão ou digite outro email:${NC}"
read -r EMAIL_INPUT

if [[ -z "$EMAIL_INPUT" ]]; then
    LETSENCRYPT_EMAIL="facilitaservicos.tec@gmail.com"
else
    LETSENCRYPT_EMAIL="$EMAIL_INPUT"
fi

echo -e "${GREEN}✅ Email configurado: $LETSENCRYPT_EMAIL${NC}"

# Configurar segredos
echo ""
echo -e "${BLUE}🔑 Configurando Segredos no Key Vault${NC}"
echo -e "${BLUE}=====================================${NC}"

# 1. Email Let's Encrypt
echo ""
echo -e "${YELLOW}🔐 Configurando email Let's Encrypt...${NC}"
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-letsencrypt-email" "$LETSENCRYPT_EMAIL" "Email para registro Let's Encrypt (SSL automático)"

# 2. Senha do Dashboard (gerar automaticamente)
echo ""
echo -e "${YELLOW}🔐 Gerando senha segura para o dashboard...${NC}"
DASHBOARD_PASSWORD=$(generate_secure_password 24)
echo -e "${YELLOW}ℹ️ Senha gerada (será mascarada no log)${NC}"
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-traefik-dashboard-password" "$DASHBOARD_PASSWORD" "Senha de acesso ao dashboard Traefik"

# 3. Outros segredos essenciais (gerar automaticamente)
echo ""
echo -e "${YELLOW}🔐 Gerando outros segredos essenciais...${NC}"

# Senhas adicionais para serviços
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-traefik-admin-password" "$(generate_secure_password 24)" "Senha de administrador do Traefik"
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-traefik-audit-password" "$(generate_secure_password 24)" "Senha de auditoria do Traefik" 
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-traefik-crypto-password" "$(generate_secure_password 24)" "Senha criptográfica do Traefik"
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-webhook-secret" "$(generate_secure_password 32)" "Secret para webhooks"

# Porta do Zookeeper (valor padrão)
create_secret_safe "$KEYVAULT_NAME" "conexao-de-sorte-zookeeper-client-port" "2181" "Porta de cliente do Zookeeper"

# Resumo final
echo ""
echo -e "${BLUE}📊 Resumo da Configuração${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "${GREEN}✅ Configuração concluída com sucesso!${NC}"
echo ""
echo -e "${YELLOW}📋 Segredos configurados no Key Vault: $KEYVAULT_NAME${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-letsencrypt-email: $LETSENCRYPT_EMAIL${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-traefik-dashboard-password: [SENHA GERADA]${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-traefik-admin-password: [SENHA GERADA]${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-traefik-audit-password: [SENHA GERADA]${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-traefik-crypto-password: [SENHA GERADA]${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-webhook-secret: [SENHA GERADA]${NC}"
echo -e "${YELLOW}   • conexao-de-sorte-zookeeper-client-port: 2181${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE: As senhas geradas não são exibidas por segurança.${NC}"
echo -e "${YELLOW}ℹ️ Elas estão armazenadas com segurança no Key Vault e serão acessadas${NC}"
echo -e "${YELLOW}   pelo pipeline CI/CD durante o deploy.${NC}"
echo ""
echo -e "${GREEN}🚀 O pipeline CI/CD agora deve funcionar corretamente!${NC}"
echo -e "${GREEN}   Configure os segredos do GitHub Actions e execute o workflow.${NC}"

# Verificar permissões (opcional)
echo ""
echo -e "${YELLOW}🔍 Deseja verificar as permissões do Key Vault? (s/N): ${NC}"
read -r check_permissions

if [[ "$check_permissions" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}🔍 Verificando permissões do Key Vault...${NC}"
    echo -e "${YELLOW}App Registration atual: $(az account show --query user.name -o tsv 2>/dev/null || echo 'N/A')${NC}"
    echo -e "${YELLOW}Verifique se tem as permissões necessárias no Key Vault.${NC}"
fi

echo -e "${GREEN}✅ Script concluído!${NC}"