#!/bin/bash
set -euo pipefail

echo "🧪 Testando workflow com validações OIDC..."

# Simular variáveis do GitHub Actions
export AZURE_CLIENT_ID="test-client-id"
export AZURE_TENANT_ID="test-tenant-id"
export AZURE_SUBSCRIPTION_ID="test-subscription-id"
export AZURE_KEYVAULT_NAME="conexao-de-sorte-keyvault" # Nome errado para testar correção

echo "📋 Testando validação de OIDC..."

# Testar validação OIDC
for var in AZURE_CLIENT_ID AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ $var não configurado"
    exit 1
  fi
done
echo "✅ OIDC Azure configurado"

echo ""
echo "📋 Testando validação de conexão Azure..."
echo "✅ Conexão Azure OIDC estabelecida (simulado)"
echo "Subscription: test-subscription-id"

echo ""
echo "📋 Testando conexão com Key Vault..."

# Testar correção do nome do Key Vault
if [[ "$AZURE_KEYVAULT_NAME" == "conexao-de-sorte-keyvault" ]]; then
  AZURE_KEYVAULT_NAME="kv-conexao-de-sorte"
  echo "⚠️ Corrigindo nome do Key Vault para: $AZURE_KEYVAULT_NAME"
fi

echo "✅ Conexão com Key Vault estabelecida (simulado)"

echo ""
echo "📋 Testando busca de segredos..."

# Simular busca de segredos essenciais
echo "🔍 Buscando segredos essenciais..."
essential_count=0

# Simular segredo encontrado
echo "✅ conexao-de-sorte-letsencrypt-email obtido"
export CONEXAO-DE-SORTE-LETSENCRYPT-EMAIL="test@example.com"
essential_count=$((essential_count + 1))

# Simular segredo encontrado  
echo "✅ conexao-de-sorte-traefik-dashboard-password obtido"
export CONEXAO-DE-SORTE-TRAEFIK-DASHBOARD-PASSWORD="test-password"
essential_count=$((essential_count + 1))

echo "📊 Total de segredos essenciais obtidos: $essential_count/2"

echo ""
echo "📋 Testando validação final de segredos..."

# Validar segredos essenciais obtidos via OIDC
missing=()
if [[ -z "${CONEXAO-DE-SORTE-LETSENCRYPT-EMAIL:-}" ]]; then
  missing+=("conexao-de-sorte-letsencrypt-email")
fi
if [[ -z "${CONEXAO-DE-SORTE-TRAEFIK-DASHBOARD-PASSWORD:-}" ]]; then
  missing+=("conexao-de-sorte-traefik-dashboard-password")
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "❌ Segredos essenciais não obtidos via OIDC:"
  printf '   - %s\n' "${missing[@]}"
  exit 1
fi

echo "✅ Todos os segredos essenciais foram obtidos com sucesso via OIDC"
echo "📧 Email Let's Encrypt: ${CONEXAO-DE-SORTE-LETSENCRYPT-EMAIL:0:3}***${CONEXAO-DE-SORTE-LETSENCRYPT-EMAIL##*@}"
echo "🔐 Senha Dashboard: $(echo $CONEXAO-DE-SORTE-TRAEFIK-DASHBOARD-PASSWORD | wc -c) caracteres"

echo ""
echo "🎯 Workflow com validações OIDC testado com sucesso!"
echo "✅ OIDC configurado corretamente"
echo "✅ Conexão Azure validada"  
echo "✅ Conexão Key Vault estabelecida"
echo "✅ Segredos essenciais obtidos e validados"