#!/bin/bash
# Testar qual Key Vault está configurado
KEYVAULT_NAME="${AZURE_KEYVAULT_NAME:-kv-conexao-de-sorte}"
echo "Key Vault configurado: $KEYVAULT_NAME"
echo "Verificando se existe..."
if az keyvault show --name "$KEYVAULT_NAME" --query name -o tsv >/dev/null 2>&1; then
    echo "✅ Key Vault $KEYVAULT_NAME existe e é acessível"
else
    echo "❌ Key Vault $KEYVAULT_NAME não existe ou não é acessível"
fi
