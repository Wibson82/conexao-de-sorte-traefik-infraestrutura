#!/bin/bash

# 🔐 Script para sincronizar secrets do Azure Key Vault com Docker Swarm
# ✅ Sincroniza secrets do Azure Key Vault para o Docker Swarm local
# ✅ Usa nomes padronizados para os secrets

set -euo pipefail

# Configurações (ajuste para o seu ambiente)
KEYVAULT_NAME="${KEYVAULT_NAME:-my-keyvault}"
RESOURCE_GROUP="${RESOURCE_GROUP:-my-resource-group}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Sincronizando Secrets do Azure Key Vault para Docker Swarm${NC}"
echo -e "${BLUE}📍 Key Vault: ${KEYVAULT_NAME}${NC}"
echo ""

# Função para obter secret do Azure Key Vault
get_keyvault_secret() {
    local secret_name=$1
    local secret_value
    
    echo -e "${YELLOW}📦 Obtendo secret: ${secret_name}${NC}"
    
    secret_value=$(az keyvault secret show \
        --name "${secret_name}" \
        --vault-name "${KEYVAULT_NAME}" \
        --query value \
        --output tsv 2>/dev/null)
    
    if [ -z "$secret_value" ]; then
        echo -e "${RED}❌ Erro: Secret '${secret_name}' não encontrado no Key Vault${NC}"
        return 1
    fi
    
    echo "$secret_value"
}

# Função para criar secret no Docker Swarm
create_docker_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo -e "${YELLOW}🐳 Criando Docker secret: ${secret_name}${NC}"
    
    # Remove secret existente se houver
    if docker secret ls --format "{{.Name}}" | grep -q "^${secret_name}$"; then
        echo -e "${YELLOW}🗑️  Removendo secret existente: ${secret_name}${NC}"
        docker secret rm "${secret_name}" || true
    fi
    
    # Cria novo secret
    echo -n "${secret_value}" | docker secret create "${secret_name}" - 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Secret '${secret_name}' criado com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro ao criar secret '${secret_name}'${NC}"
        return 1
    fi
}

# Função principal
main() {
    echo -e "${BLUE}🚀 Iniciando sincronização de secrets...${NC}"
    echo ""
    
    # Verificar se o Docker Swarm está ativo
    if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
        echo -e "${RED}❌ Docker Swarm não está ativo! Execute: docker swarm init${NC}"
        exit 1
    fi
    
    # Verificar se o Azure CLI está logado
    if ! az account show >/dev/null 2>&1; then
        echo -e "${RED}❌ Azure CLI não está logado! Execute: az login${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker Swarm e Azure CLI estão prontos${NC}"
    echo ""
    
    # Secrets do Azure Key Vault para sincronizar (nomes padronizados)
    declare -A secrets_map=(
        ["AZURE_CLIENT_ID"]="AZURE-CLIENT-ID"
        ["AZURE_CLIENT_SECRET"]="AZURE-CLIENT-SECRET"
        ["AZURE_TENANT_ID"]="AZURE-TENANT-ID"
        ["mysql_root_password"]="<db-root-secret>"
        ["mysql_password"]="<db-password-secret>"
    )
    
    # Processar cada secret
    local success_count=0
    local total_count=${#secrets_map[@]}
    
    for docker_secret_name in "${!secrets_map[@]}"; do
        local keyvault_secret_name="${secrets_map[$docker_secret_name]}"
        
        echo -e "${BLUE}📋 Processando: ${keyvault_secret_name} → ${docker_secret_name}${NC}"
        
        # Obter valor do Key Vault
        local secret_value
        if secret_value=$(get_keyvault_secret "$keyvault_secret_name"); then
            # Criar secret no Docker Swarm
            if create_docker_secret "$docker_secret_name" "$secret_value"; then
                ((success_count++))
            fi
        fi
        
        echo ""
    done
    
    # Relatório final
    echo -e "${BLUE}📊 RELATÓRIO FINAL${NC}"
    echo -e "${GREEN}✅ Secrets sincronizados: ${success_count}/${total_count}${NC}"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 Todos os secrets foram sincronizados com sucesso!${NC}"
        echo ""
        echo -e "${BLUE}🐳 Secrets Docker Swarm disponíveis:${NC}"
        docker secret ls --format "table {{.Name}}\t{{.CreatedAt}}"
        echo ""
        echo -e "${GREEN}🚀 Pronto para deploy do stack!${NC}"
        echo -e "${YELLOW}💡 Execute: docker stack deploy -c docker-stack.yml $PROJECT_NAME${NC}"
    else
        echo -e "${RED}❌ Alguns secrets falharam. Verifique os logs acima.${NC}"
        exit 1
    fi
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
