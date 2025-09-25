#!/bin/bash

# =============================================================================
# 📊 CRONJOB MONITOR - EXECUÇÃO AUTOMÁTICA DO MONITORAMENTO
# =============================================================================
# Script para execução via crontab a cada minuto
# Executa o monitoramento e mantém logs atualizados
# =============================================================================

# Configurações
SCRIPT_DIR="/app/scripts"
LOG_DIR="/app/logs"
MONITOR_SCRIPT="$SCRIPT_DIR/server-monitor.sh"

# Criar diretório se não existir
mkdir -p "$LOG_DIR"

# Log de execução do cron
CRON_LOG="$LOG_DIR/cron-monitor.log"

# Função de log com timestamp
log_message() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1" >> "$CRON_LOG"
}

# Verificar se o script de monitoramento existe
if [[ ! -x "$MONITOR_SCRIPT" ]]; then
    log_message "ERROR: Monitor script não encontrado ou não executável: $MONITOR_SCRIPT"
    exit 1
fi

# Executar monitoramento
log_message "INFO: Iniciando execução do monitoramento..."

if "$MONITOR_SCRIPT"; then
    log_message "SUCCESS: Monitoramento executado com sucesso"
else
    log_message "ERROR: Falha na execução do monitoramento (exit code: $?)"
    exit 1
fi

# Manter apenas as últimas 1000 linhas do log do cron
tail -1000 "$CRON_LOG" > "$CRON_LOG.tmp" && mv "$CRON_LOG.tmp" "$CRON_LOG"

# Verificar idade do arquivo de monitoramento
MONITOR_FILE="$LOG_DIR/server-monitor.json"
if [[ -f "$MONITOR_FILE" ]]; then
    # Verificar se o arquivo foi modificado nos últimos 5 minutos
    if [[ $(find "$MONITOR_FILE" -mmin -5 | wc -l) -eq 0 ]]; then
        log_message "WARNING: Arquivo de monitoramento está desatualizado (> 5 minutos)"
    fi
fi

log_message "INFO: Cronjob concluído"