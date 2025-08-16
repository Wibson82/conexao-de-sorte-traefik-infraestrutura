#!/bin/bash

# =============================================================================
# SCRIPT DE VERIFICAÇÃO DE SAÚDE DO AZURE KEY VAULT
# =============================================================================
# Verifica se o Azure Key Vault está funcionando corretamente e se há
# problemas de permissões que possam impedir o funcionamento da aplicação.
# =============================================================================

set -euo pipefail

# Configurações
CONTAINER_NAME="${1:-backend-teste}"
MAX_WAIT_SECONDS=300
CHECK_INTERVAL=10
AZURE_ERRORS_FOUND=false

echo "🔍 [$(date)] Verificando saúde do Azure Key Vault..."
echo "📦 Container: $CONTAINER_NAME"

# Função para verificar logs do container
check_azure_logs() {
    local container="$1"
    local logs
    
    if ! logs=$(docker logs "$container" 2>&1); then
        echo "❌ [$(date)] Erro ao obter logs do container $container"
        return 1
    fi
    
    # Verificar erros críticos do Azure Key Vault
    if echo "$logs" | grep -q "Status code 403.*Forbidden"; then
        echo "🚫 [$(date)] ERRO CRÍTICO: Service Principal sem permissão de escrita no Azure Key Vault"
        echo "🔧 [$(date)] SOLUÇÃO: Conceder role 'Key Vault Secrets Officer' ao Service Principal"
        echo "📋 [$(date)] Service Principal ID: b8a756de-d867-4bfc-95cb-b20a4a8c35ef"
        echo "🏢 [$(date)] Key Vault: chave-conexao-de-sorte"
        echo ""
        echo "📋 [$(date)] COMANDO PARA CORRIGIR:"
        echo "az role assignment create \\"
        echo "  --assignee 'b8a756de-d867-4bfc-95cb-b20a4a8c35ef' \\"
        echo "  --role 'Key Vault Secrets Officer' \\"
        echo "  --scope '/subscriptions/ae1add23-6db8-40a9-8a2d-b88996ef3128/resourcegroups/grupo-servicoes-conexao-de-sorte/providers/microsoft.keyvault/vaults/chave-conexao-de-sorte'"
        echo ""
        AZURE_ERRORS_FOUND=true
    fi
    
    if echo "$logs" | grep -q "Last unit does not have enough valid bits"; then
        echo "🔐 [$(date)] ERRO: Chaves JWT corrompidas - senha de criptografia pode ter mudado"
        echo "🔧 [$(date)] SOLUÇÃO: Verificar variável APP_ENCRYPTION_MASTER_PASSWORD"
        echo "💡 [$(date)] As chaves serão regeneradas automaticamente após correção"
        echo ""
        AZURE_ERRORS_FOUND=true
    fi
    
    if echo "$logs" | grep -q "PRODUÇÃO BLOQUEADA.*Azure Key Vault"; then
        echo "🛑 [$(date)] APLICAÇÃO BLOQUEADA: Azure Key Vault obrigatório em produção"
        echo "⚡ [$(date)] AÇÃO URGENTE: Corrigir permissões Azure Key Vault"
        echo ""
        AZURE_ERRORS_FOUND=true
    fi
    
    if echo "$logs" | grep -q "SecretClient do Azure Key Vault não disponível"; then
        echo "🔌 [$(date)] ERRO: SecretClient não conectado ao Azure Key Vault"
        echo "🔧 [$(date)] SOLUÇÃO: Verificar credenciais Azure (CLIENT_ID, CLIENT_SECRET, TENANT_ID)"
        echo ""
        AZURE_ERRORS_FOUND=true
    fi
    
    # Verificar sucessos
    if echo "$logs" | grep -q "✅ SecretClient do Azure Key Vault injetado com sucesso"; then
        echo "✅ [$(date)] SecretClient conectado com sucesso"
    fi
    
    if echo "$logs" | grep -q "✅ Teste de escrita bem-sucedido"; then
        echo "✅ [$(date)] Permissões de escrita Azure Key Vault OK"
    fi
    
    if echo "$logs" | grep -q "✅ Chaves JWT geradas e armazenadas no Azure Key Vault"; then
        echo "✅ [$(date)] Chaves JWT armazenadas no Azure Key Vault com sucesso"
    fi
}

# Função para aguardar container ficar disponível
wait_for_container() {
    local container="$1"
    local elapsed=0
    
    echo "⏳ [$(date)] Aguardando container $container ficar disponível..."
    
    while [ $elapsed -lt $MAX_WAIT_SECONDS ]; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            echo "✅ [$(date)] Container $container encontrado"
            return 0
        fi
        
        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
        echo "⏳ [$(date)] Aguardando... ($elapsed/${MAX_WAIT_SECONDS}s)"
    done
    
    echo "❌ [$(date)] Timeout: Container $container não encontrado após ${MAX_WAIT_SECONDS}s"
    return 1
}

# Função principal
main() {
    echo "🚀 [$(date)] Iniciando verificação de saúde do Azure Key Vault..."
    
    # Aguardar container
    if ! wait_for_container "$CONTAINER_NAME"; then
        echo "❌ [$(date)] Container não encontrado - abortando verificação"
        exit 1
    fi
    
    # Aguardar um pouco para aplicação inicializar
    echo "⏳ [$(date)] Aguardando aplicação inicializar..."
    sleep 30
    
    # Verificar logs
    check_azure_logs "$CONTAINER_NAME"
    
    # Resultado final
    if [ "$AZURE_ERRORS_FOUND" = true ]; then
        echo ""
        echo "❌ [$(date)] PROBLEMAS ENCONTRADOS NO AZURE KEY VAULT"
        echo "⚡ [$(date)] AÇÃO NECESSÁRIA: Corrigir problemas listados acima"
        echo "🔄 [$(date)] Após correção, reiniciar aplicação"
        echo ""
        
        # Definir output para GitHub Actions
        echo "azure_errors=true" >> $GITHUB_OUTPUT
        echo "azure_status=failed" >> $GITHUB_OUTPUT
        
        exit 1
    else
        echo ""
        echo "✅ [$(date)] Azure Key Vault funcionando corretamente"
        echo "🔐 [$(date)] Aplicação segura e operacional"
        echo ""
        
        # Definir output para GitHub Actions
        echo "azure_errors=false" >> $GITHUB_OUTPUT
        echo "azure_status=success" >> $GITHUB_OUTPUT
        
        exit 0
    fi
}

# Executar função principal
main "$@"
