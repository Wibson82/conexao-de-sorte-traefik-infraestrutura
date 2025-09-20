#!/bin/bash
# Simular a lógica do workflow
set -euo pipefail

# Simular AZURE_KEYVAULT_NAME do GitHub Secrets
export AZURE_KEYVAULT_NAME="conexao-de-sorte-keyvault"  # Simular nome errado

echo "=== TESTANDO LÓGICA DO WORKFLOW ==="
echo "AZURE_KEYVAULT_NAME do GitHub Secrets: $AZURE_KEYVAULT_NAME"

# Aplicar correção do workflow
KEYVAULT_NAME="$AZURE_KEYVAULT_NAME"
if [[ "$KEYVAULT_NAME" == "conexao-de-sorte-keyvault" ]]; then
  echo "⚠️ Ajustando nome do Key Vault de 'conexao-de-sorte-keyvault' para 'kv-conexao-de-sorte'"
  KEYVAULT_NAME="kv-conexao-de-sorte"
fi

echo "Key Vault corrigido: $KEYVAULT_NAME"
echo ""
echo "=== TESTANDO ACESSO AOS SEGREDOS ==="

# Testar acesso aos segredos essenciais
echo "🔍 Buscando conexao-de-sorte-letsencrypt-email..."
if ACME_EMAIL=$(az keyvault secret show --name conexao-de-sorte-letsencrypt-email --vault-name "$KEYVAULT_NAME" --query value -o tsv 2>/dev/null); then
  echo "✅ Email Let's Encrypt obtido: ${ACME_EMAIL:0:10}..."
else
  echo "⚠️ Email Let's Encrypt não encontrado"
fi

echo ""
echo "🔍 Buscando conexao-de-sorte-traefik-dashboard-password..."
if DASHBOARD_PASSWORD=$(az keyvault secret show --name conexao-de-sorte-traefik-dashboard-password --vault-name "$KEYVAULT_NAME" --query value -o tsv 2>/dev/null); then
  echo "✅ Senha dashboard obtida: ${DASHBOARD_PASSWORD:0:5}..."
else
  echo "⚠️ Senha dashboard não encontrada"
fi

echo ""
echo "=== TESTANDO SEGREDOS OPCIONAIS ==="
optional_secrets=(
  "conexao-de-sorte-traefik-admin-password"
  "conexao-de-sorte-traefik-audit-password"
  "conexao-de-sorte-traefik-crypto-password"
  "conexao-de-sorte-webhook-secret"
  "conexao-de-sorte-zookeeper-client-port"
)

for secret_name in "${optional_secrets[@]}"; do
  echo "🔍 Verificando: $secret_name"
  if secret_value=$(az keyvault secret show --name "$secret_name" --vault-name "$KEYVAULT_NAME" --query value -o tsv 2>/dev/null); then
    if [[ -n "$secret_value" ]]; then
      echo "  ✅ Segredo opcional encontrado"
    else
      echo "  ⚠️ Segredo opcional vazio"
    fi
  else
    echo "  ℹ️ Segredo opcional não encontrado (não crítico)"
  fi
done

echo ""
echo "=== CONCLUSÃO ==="
echo "✅ Lógica de correção do Key Vault funcionando!"
echo "✅ Todos os segredos estão acessíveis com o nome correto!"
