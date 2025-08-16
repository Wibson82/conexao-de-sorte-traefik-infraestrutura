#!/bin/bash
set -euo pipefail

# Script de healthcheck para MySQL em Docker Compose
# Verifica se o MySQL está respondendo corretamente

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_ROOT_PASSWORD_FILE="/run/secrets/mysql_root_password"

if [[ ! -f "$MYSQL_ROOT_PASSWORD_FILE" ]]; then
    echo "❌ Secret mysql_root_password não encontrado em $MYSQL_ROOT_PASSWORD_FILE"
    exit 1
fi
MYSQL_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)

if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; then
    echo "✅ MySQL está respondendo corretamente"
    exit 0
else
    echo "❌ MySQL não está respondendo"
    exit 1
fi 