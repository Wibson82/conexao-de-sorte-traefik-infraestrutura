#!/bin/bash

# Script de Diagnóstico para Segredos do GitHub Actions
# Este script ajuda a identificar problemas com os segredos do Azure OIDC

set -euo pipefail

echo "🔍 Diagnóstico de Segredos do GitHub Actions para Azure OIDC"
echo "================================================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funções auxiliares
check_secret() {
    local secret_name=$1
    local secret_value=${2:-}
    
    if [[ -n "$secret_value" ]]; then
        echo -e "${GREEN}✅ $secret_name: Configurado${NC}"
        return 0
    else
        echo -e "${RED}❌ $secret_name: Ausente${NC}"
        return 1
    fi
}

validate_guid() {
    local value=$1
    local name=$2
    
    if [[ "$value" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        echo -e "${GREEN}✅ $name é um GUID válido${NC}"
        return 0
    else
        echo -e "${RED}❌ $name não é um GUID válido: $value${NC}"
        return 1
    fi
}

# Verificar variáveis de ambiente
echo -e "\n${YELLOW}📋 Verificando Segredos do GitHub Actions:${NC}"
echo "------------------------------------------------"

# Verificar cada segredo obrigatório
AZURE_CLIENT_ID=${AZURE_CLIENT_ID:-}
AZURE_TENANT_ID=${AZURE_TENANT_ID:-}
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
AZURE_KEYVAULT_NAME=${AZURE_KEYVAULT_NAME:-}
AZURE_KEYVAULT_ENDPOINT=${AZURE_KEYVAULT_ENDPOINT:-}

errors=0

check_secret "AZURE_CLIENT_ID" "$AZURE_CLIENT_ID" || ((errors++))
check_secret "AZURE_TENANT_ID" "$AZURE_TENANT_ID" || ((errors++))
check_secret "AZURE_SUBSCRIPTION_ID" "$AZURE_SUBSCRIPTION_ID" || ((errors++))
check_secret "AZURE_KEYVAULT_NAME" "$AZURE_KEYVAULT_NAME" || ((errors++))

# AZURE_KEYVAULT_ENDPOINT é opcional
if [[ -n "$AZURE_KEYVAULT_ENDPOINT" ]]; then
    echo -e "${GREEN}✅ AZURE_KEYVAULT_ENDPOINT: Configurado (opcional)${NC}"
else
    echo -e "${YELLOW}ℹ️ AZURE_KEYVAULT_ENDPOINT: Não configurado (opcional)${NC}"
fi

echo -e "\n${YELLOW}🔐 Validando Formatos dos Segredos:${NC}"
echo "------------------------------------------------"

# Validar GUIDs
if [[ -n "$AZURE_CLIENT_ID" ]]; then
    validate_guid "$AZURE_CLIENT_ID" "AZURE_CLIENT_ID" || ((errors++))
fi

if [[ -n "$AZURE_TENANT_ID" ]]; then
    validate_guid "$AZURE_TENANT_ID" "AZURE_TENANT_ID" || ((errors++))
fi

if [[ -n "$AZURE_SUBSCRIPTION_ID" ]]; then
    validate_guid "$AZURE_SUBSCRIPTION_ID" "AZURE_SUBSCRIPTION_ID" || ((errors++))
fi

# Validar Key Vault Name
if [[ -n "$AZURE_KEYVAULT_NAME" ]]; then
    if [[ "$AZURE_KEYVAULT_NAME" =~ ^[a-zA-Z0-9-]{3,24}$ ]] && [[ ! "$AZURE_KEYVAULT_NAME" =~ ^- ]] && [[ ! "$AZURE_KEYVAULT_NAME" =~ -$ ]]; then
        echo -e "${GREEN}✅ AZURE_KEYVAULT_NAME tem formato válido${NC}"
    else
        echo -e "${RED}❌ AZURE_KEYVAULT_NAME tem formato inválido: $AZURE_KEYVAULT_NAME${NC}"
        echo -e "${YELLOW}ℹ️ Deve ter 3-24 caracteres, apenas letras, números e hífens, sem começar/terminar com hífen${NC}"
        ((errors++))
    fi
fi

# Testar conectividade com Azure (se possível)
echo -e "\n${YELLOW}☁️ Testando Conectividade com Azure:${NC}"
echo "------------------------------------------------"

if command -v az &> /dev/null; then
    echo -e "${GREEN}✅ Azure CLI está instalado${NC}"
    
    # Testar login (se credenciais estiverem disponíveis)
    if [[ -n "$AZURE_CLIENT_ID" ]] && [[ -n "$AZURE_TENANT_ID" ]] && [[ -n "$AZURE_SUBSCRIPTION_ID" ]]; then
        echo -e "${YELLOW}🔄 Testando login com Azure CLI...${NC}"
        
        # Tentar login (pode falhar sem credenciais completas)
        if az login --service-principal -u "$AZURE_CLIENT_ID" --tenant "$AZURE_TENANT_ID" --allow-no-subscriptions &> /dev/null 2>&1; then
            echo -e "${GREEN}✅ Login Azure realizado com sucesso${NC}"
            
            # Testar acesso ao Key Vault
            if [[ -n "$AZURE_KEYVAULT_NAME" ]]; then
                echo -e "${YELLOW}🔄 Testando acesso ao Key Vault...${NC}"
                if az keyvault secret list --vault-name "$AZURE_KEYVAULT_NAME" &> /dev/null 2>&1; then
                    echo -e "${GREEN}✅ Acesso ao Key Vault concedido${NC}"
                    
                    # Verificar segredos específicos
                    echo -e "${YELLOW}🔄 Verificando segredos essenciais...${NC}"
                    if az keyvault secret show --name conexao-de-sorte-letsencrypt-email --vault-name "$AZURE_KEYVAULT_NAME" &> /dev/null 2>&1; then
                        echo -e "${GREEN}✅ Secret 'conexao-de-sorte-letsencrypt-email' encontrado${NC}"
                    else
                        echo -e "${RED}❌ Secret 'conexao-de-sorte-letsencrypt-email' não encontrado${NC}"
                        ((errors++))
                    fi
                    
                    if az keyvault secret show --name conexao-de-sorte-traefik-dashboard-password --vault-name "$AZURE_KEYVAULT_NAME" &> /dev/null 2>&1; then
                        echo -e "${GREEN}✅ Secret 'conexao-de-sorte-traefik-dashboard-password' encontrado${NC}"
                    else
                        echo -e "${RED}❌ Secret 'conexao-de-sorte-traefik-dashboard-password' não encontrado${NC}"
                        ((errors++))
                    fi
                    
                else
                    echo -e "${RED}❌ Sem acesso ao Key Vault: $AZURE_KEYVAULT_NAME${NC}"
                    echo -e "${YELLOW}ℹ️ Verifique as permissões RBAC do App Registration${NC}"
                    ((errors++))
                fi
            fi
            
            # Logout
            az logout &> /dev/null 2>&1
            
        else
            echo -e "${RED}❌ Login Azure falhou${NC}"
            echo -e "${YELLOW}ℹ️ Verifique as credenciais e configurações do App Registration${NC}"
            ((errors++))
        fi
    else
        echo -e "${YELLOW}ℹ️ Credenciais incompletas para testar login${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Azure CLI não está instalada${NC}"
    echo -e "${YELLOW}ℹ️ Instale com: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
fi

# Resumo final
echo -e "\n${YELLOW}📊 Resumo do Diagnóstico:${NC}"
echo "------------------------------------------------"

if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}🎉 Todos os segredos estão configurados corretamente!${NC}"
    echo -e "${GREEN}✅ O pipeline deve funcionar sem problemas${NC}"
else
    echo -e "${RED}❌ Foram encontrados $errors problemas${NC}"
    echo -e "${YELLOW}ℹ️ Corrija os problemas acima antes de executar o pipeline${NC}"
fi

echo -e "\n${YELLOW}💡 Próximos Passos:${NC}"
echo "------------------------------------------------"
if [[ $errors -gt 0 ]]; then
    echo -e "${YELLOW}1. Configure os segredos ausentes no GitHub:${NC}"
    echo -e "   Repository Settings > Secrets and variables > Actions > New repository secret"
    echo -e ""
    echo -e "${YELLOW}2. Verifique a documentação:${NC}"
    echo -e "   cat VERIFICACAO-SECRETS-GITHUB.md"
    echo -e ""
    echo -e "${YELLOW}3. Teste novamente:${NC}"
    echo -e "   ./diagnostico-secrets.sh"
else
    echo -e "${GREEN}✅ Seu pipeline está pronto para executar!${NC}"
    echo -e "${GREEN}🚀 O deploy funcionará com SSL automático e dashboard seguro${NC}"
fi

exit $errors