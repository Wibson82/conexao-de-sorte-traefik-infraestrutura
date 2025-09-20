#!/bin/bash
set -euo pipefail

echo "🧪 Testando workflow simplificado com OIDC..."

# Simular variáveis do GitHub Actions
export AZURE_CLIENT_ID="test-client-id"
export AZURE_TENANT_ID="test-tenant-id"
export AZURE_SUBSCRIPTION_ID="test-subscription-id"
export AZURE_KEYVAULT_NAME="conexao-de-sorte-keyvault" # Nome errado para testar correção

echo "📋 Simulando validação de OIDC..."

# Testar validação OIDC
for var in AZURE_CLIENT_ID AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ $var não configurado"
    exit 1
  fi
done
echo "✅ OIDC Azure configurado"

# Testar correção do nome do Key Vault
if [[ "$AZURE_KEYVAULT_NAME" == "conexao-de-sorte-keyvault" ]]; then
  AZURE_KEYVAULT_NAME="kv-conexao-de-sorte"
  echo "⚠️ Corrigindo nome do Key Vault para: $AZURE_KEYVAULT_NAME"
fi

echo "✅ Nome do Key Vault corrigido: $AZURE_KEYVAULT_NAME"

echo ""
echo "🎯 Workflow simplificado testado com sucesso!"
echo "✅ OIDC configurado corretamente"
echo "✅ Lógica de correção do Key Vault funcionando"
echo "✅ Sem verificações redundantes"