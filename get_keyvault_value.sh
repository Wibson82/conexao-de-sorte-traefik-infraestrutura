#!/bin/bash
# Script para simular o que o workflow faz
echo "Simulando o workflow..."
echo "AZURE_KEYVAULT_NAME do GitHub Secrets: ${AZURE_KEYVAULT_NAME:-NÃO DEFINIDO}"
echo "Verificando se o Key Vault existe..."
if [[ -n "${AZURE_KEYVAULT_NAME:-}" ]]; then
    echo "Tentando acessar: $AZURE_KEYVAULT_NAME"
    if az keyvault show --name "$AZURE_KEYVAULT_NAME" --query name -o tsv >/dev/null 2>&1; then
        echo "✅ Key Vault $AZURE_KEYVAULT_NAME existe"
    else
        echo "❌ Key Vault $AZURE_KEYVAULT_NAME NÃO existe ou não é acessível"
    fi
else
    echo "❌ AZURE_KEYVAULT_NAME não está definido"
fi
