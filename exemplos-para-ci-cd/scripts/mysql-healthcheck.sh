#!/bin/bash
set -euo pipefail

# =============================================================================
# SCRIPT DE HEALTHCHECK MYSQL CONSOLIDADO
# =============================================================================

# Configurações
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD:-12345678AbcD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-conexao_sorte}"

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Verificar se o MySQL está respondendo
log "🔍 Verificando conectividade MySQL..."

if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
    log "✅ MySQL está respondendo"
    
    # Verificar se o database existe
    if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $MYSQL_DATABASE;" 2>/dev/null; then
        log "✅ Database '$MYSQL_DATABASE' acessível"
        exit 0
    else
        log "❌ Database '$MYSQL_DATABASE' não acessível"
        exit 1
    fi
else
    log "❌ MySQL não está respondendo"
    exit 1
fi
