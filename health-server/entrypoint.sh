#!/bin/bash

# =============================================================================
# 🚀 LOG SERVER ENTRYPOINT - INICIALIZAÇÃO COMPLETA
# =============================================================================

set -e

echo "🚀 Iniciando Log Server..."

# Configurar crontab para monitoramento automático
echo "📊 Configurando crontab para monitoramento automático..."
echo "* * * * * /app/scripts/cronjob-monitor.sh" > /tmp/crontab
crontab /tmp/crontab
rm /tmp/crontab

echo "✅ Crontab configurado: execução a cada minuto"

# Executar monitoramento inicial
echo "📈 Executando monitoramento inicial..."
/app/scripts/server-monitor.sh || echo "⚠️ Primeiro monitoramento pode falhar - containers ainda inicializando"

# Iniciar cron em background
echo "⏰ Iniciando cron daemon..."
crond -L /app/logs/cron.log

# Aguardar um momento para o cron estabilizar
sleep 2

# Iniciar servidor web
echo "🌐 Iniciando servidor HTTP na porta 9090..."
echo "📊 Endpoint: http://localhost:9090/rest/v1/log-servidor"
echo "🏥 Health: http://localhost:9090/health"

exec python3 /app/health-server/log-server.py