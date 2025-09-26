#!/bin/bash

# =============================================================================
# 🚀 LOG SERVER ENTRYPOINT - INICIALIZAÇÃO COMPLETA
# =============================================================================

set -e

echo "🚀 Iniciando Log Server..."

# Executar monitoramento inicial
echo "📈 Executando monitoramento inicial..."
/app/scripts/server-monitor.sh || echo "⚠️ Primeiro monitoramento pode falhar - containers ainda inicializando"

# Função para loop de monitoramento em background
monitor_loop() {
    while true; do
        sleep 30
        echo "📊 $(date): Executando monitoramento automático..."
        /app/scripts/server-monitor.sh || echo "⚠️ Erro no monitoramento - continuando..."
    done
}

# Iniciar loop de monitoramento em background
echo "⏰ Iniciando monitoramento automático a cada 30 segundos..."
monitor_loop &

# Aguardar um momento para estabilizar
sleep 2

# Iniciar servidor web
echo "🌐 Iniciando servidor HTTP na porta 9090..."
echo "📊 Endpoint: http://localhost:9090/rest/v1/log-servidor"
echo "🏥 Health: http://localhost:9090/health"

exec python3 /app/health-server/log-server.py