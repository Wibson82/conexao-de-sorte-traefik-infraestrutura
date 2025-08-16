#!/bin/bash

# 🔍 TROUBLESHOOTING: Azure Key Vault Init Container
# ✅ Execute este script no servidor para debug detalhado

set -euo pipefail

echo "🔍 TROUBLESHOOTING: Azure Key Vault Init Container"
echo "=================================================="

# 1. Verificar se o container falhou
echo "📊 Status dos containers:"
docker compose -f docker-compose.prod.yml ps

# 2. Verificar logs detalhados do init container
echo ""
echo "📋 Logs do init container azure-secrets:"
echo "========================================"
docker compose -f docker-compose.prod.yml logs azure-secrets

# 3. Verificar se as variáveis de ambiente estão corretas
echo ""
echo "🔍 Variáveis de ambiente do arquivo .env:"
echo "========================================="
if [[ -f ".env" ]]; then
    echo "✅ Arquivo .env encontrado"
    grep -E "AZURE_" .env | while read line; do
        var_name=$(echo "$line" | cut -d'=' -f1)
        var_value=$(echo "$line" | cut -d'=' -f2)
        echo "   $var_name: ${var_value:0:20}..."
    done
else
    echo "❌ Arquivo .env não encontrado"
fi

# 4. Teste manual do Azure CLI (se disponível)
echo ""
echo "🧪 Teste manual Azure CLI:"
echo "=========================="
if command -v az > /dev/null 2>&1; then
    echo "✅ Azure CLI disponível no host"
    
    # Carregar variáveis
    set -a
    source .env 2>/dev/null || true
    set +a
    
    echo "🔑 Testando login..."
    if az login --service-principal \
        --username "$AZURE_CLIENT_ID" \
        --password "$AZURE_CLIENT_SECRET" \
        --tenant "$AZURE_TENANT_ID" \
        --output none 2>/dev/null; then
        echo "✅ Login no Azure funciona"
        
        echo "🗝️ Testando acesso ao Key Vault..."
        if az keyvault secret list --vault-name "$AZURE_KEYVAULT_NAME" --output none 2>/dev/null; then
            echo "✅ Acesso ao Key Vault funciona"
            
            echo "🔍 Secrets disponíveis:"
            az keyvault secret list --vault-name "$AZURE_KEYVAULT_NAME" --query "[].name" -o table
            
            echo "🔐 Testando secrets específicos:"
            for secret in "<db-password-secret>" "<db-root-secret>"; do
                if az keyvault secret show --vault-name "$AZURE_KEYVAULT_NAME" --name "$secret" --query "name" -o tsv > /dev/null 2>&1; then
                    echo "   ✅ $secret: EXISTE"
                else
                    echo "   ❌ $secret: NÃO EXISTE"
                fi
            done
        else
            echo "❌ Falha no acesso ao Key Vault"
        fi
        
        # Logout
        az logout 2>/dev/null || true
    else
        echo "❌ Falha no login do Azure"
    fi
else
    echo "⚠️ Azure CLI não disponível no host"
fi

# 5. Verificar volumes
echo ""
echo "📁 Volumes Docker:"
echo "=================="
docker volume ls | grep -E "(mysql_secrets|mysql_data)" || echo "⚠️ Volumes não encontrados"

# 6. Sugestões de correção
echo ""
echo "💡 SUGESTÕES DE CORREÇÃO:"
echo "========================"
echo "1. Verificar se GitHub Actions Secrets estão corretos"
echo "2. Verificar se Service Principal tem permissão no Key Vault"
echo "3. Verificar se os nomes dos secrets estão corretos"
echo "4. Re-executar: docker compose -f docker-compose.prod.yml up azure-secrets"
echo "5. Verificar conectividade de rede com Azure"

echo ""
echo "🔧 COMANDOS ÚTEIS:"
echo "=================="
echo "# Ver logs em tempo real:"
echo "docker compose -f docker-compose.prod.yml logs -f azure-secrets"
echo ""
echo "# Executar apenas o init container:"
echo "docker compose -f docker-compose.prod.yml up azure-secrets"
echo ""
echo "# Limpar e recriar:"
echo "docker compose -f docker-compose.prod.yml down && docker compose -f docker-compose.prod.yml up azure-secrets"

echo ""
echo "🏁 Troubleshooting concluído!"
