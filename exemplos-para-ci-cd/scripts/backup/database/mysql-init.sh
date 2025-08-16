#!/bin/bash
set -euo pipefail

echo "🗄️ [$(date)] Configurando MySQL para Docker Compose..."

# Verificar se os arquivos de secrets existem
if [[ ! -f "/run/secrets/mysql_root_password" ]]; then
    echo "❌ [$(date)] Secret mysql_root_password não encontrado em /run/secrets/mysql_root_password"
    exit 1
fi
if [[ ! -f "/run/secrets/mysql_password" ]]; then
    echo "❌ [$(date)] Secret mysql_password não encontrado em /run/secrets/mysql_password"
    exit 1
fi

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

# Exibir variáveis para debug
echo "✅ [$(date)] Secrets configurados:"
echo "   - mysql_root_password: ${MYSQL_ROOT_PASSWORD:0:3}***"
echo "   - mysql_password: ${MYSQL_PASSWORD:0:3}***"
echo "   - MYSQL_USER: $MYSQL_USER"

# Executar MySQL normalmente
exec docker-entrypoint.sh mysqld
