#!/bin/bash
set -euo pipefail

# =============================================================================
# SCRIPT DE INICIALIZAÇÃO MYSQL PARA DOCKER
# =============================================================================

echo "🗄️ [$(date)] Configurando MySQL para Docker Compose..."

# Verificar variáveis de ambiente essenciais
if [[ -z "${MYSQL_ROOT_PASSWORD:-}" ]]; then
    echo "❌ [$(date)] MYSQL_ROOT_PASSWORD não está definida"
    exit 1
fi

if [[ -z "${CONEXAO_DE_SORTE_DATABASE_USERNAME:-}" ]]; then
    echo "⚠️ [$(date)] CONEXAO_DE_SORTE_DATABASE_USERNAME não definida, usando 'app_user_conexao'"
    export CONEXAO_DE_SORTE_DATABASE_USERNAME="app_user_conexao"
fi

if [[ -z "${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-}" ]]; then
    echo "❌ [$(date)] CONEXAO_DE_SORTE_DATABASE_PASSWORD não está definida"
    exit 1
fi

echo "✅ [$(date)] Variáveis de ambiente configuradas:"
echo "   - MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:0:3}***"
echo "   - DATABASE_USERNAME: $CONEXAO_DE_SORTE_DATABASE_USERNAME"
echo "   - DATABASE_PASSWORD: ${CONEXAO_DE_SORTE_DATABASE_PASSWORD:0:3}***"

# Executar MySQL normalmente
echo "🚀 [$(date)] Iniciando MySQL..."
exec docker-entrypoint.sh mysqld
