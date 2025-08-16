#!/bin/bash

# ============================================================================
# SCRIPT DE MONITORAMENTO DE SEGURANÇA
# ============================================================================
# Monitora logs de segurança, detecta tentativas de invasão e gera alertas
# Implementa monitoramento contínuo para compliance LGPD
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_alert() { echo -e "${RED}[ALERT]${NC} $1"; }

# Configurações
LOG_DIR="${LOG_DIR:-/var/log}"
SECURITY_LOG="$LOG_DIR/security-monitor.log"
ALERT_LOG="$LOG_DIR/security-alerts.log"
APP_LOG_DIR="${APP_LOG_DIR:-/app/logs}"
NGINX_LOG_DIR="${NGINX_LOG_DIR:-/var/log/nginx}"
MYSQL_LOG_DIR="${MYSQL_LOG_DIR:-/var/log/mysql}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
MAX_FAILED_LOGINS="${MAX_FAILED_LOGINS:-5}"
MONITOR_INTERVAL="${MONITOR_INTERVAL:-60}"

# Função de ajuda
show_help() {
    echo "
╔══════════════════════════════════════════════════════════════════╗
║                  MONITORAMENTO DE SEGURANÇA                     ║
╚══════════════════════════════════════════════════════════════════╝

Uso: $0 [COMANDO] [OPÇÕES]

COMANDOS DISPONÍVEIS:
  monitor             - Iniciar monitoramento contínuo
  check-logs          - Verificar logs uma vez
  check-failed-logins - Verificar tentativas de login falhadas
  check-sql-injection - Detectar tentativas de SQL injection
  check-suspicious    - Detectar atividade suspeita
  generate-report     - Gerar relatório de segurança
  test-alerts         - Testar sistema de alertas
  cleanup-logs        - Limpar logs antigos
  help                - Mostrar esta ajuda

EXEMPLOS:
  $0 monitor                      # Monitoramento contínuo
  $0 check-logs                   # Verificação única
  $0 generate-report              # Relatório de segurança
  $0 test-alerts                  # Testar alertas
"
}

# Função para registrar eventos de segurança
security_log() {
    local level="$1"
    local event="$2"
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $event: $details" >> "$SECURITY_LOG"
    
    if [[ "$level" == "ALERT" ]]; then
        echo "[$timestamp] $event: $details" >> "$ALERT_LOG"
        send_alert "$event" "$details"
    fi
}

# Enviar alertas
send_alert() {
    local event="$1"
    local details="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log local
    log_alert "$event: $details"
    
    # Email (se configurado)
    if [[ -n "$ALERT_EMAIL" ]] && command -v mail >/dev/null 2>&1; then
        echo "ALERTA DE SEGURANÇA - $timestamp\n\nEvento: $event\nDetalhes: $details" | \
            mail -s "[SEGURANÇA] $event" "$ALERT_EMAIL"
    fi
    
    # Slack (se configurado)
    if [[ -n "$SLACK_WEBHOOK" ]] && command -v curl >/dev/null 2>&1; then
        local payload=$(cat <<EOF
{
    "text": "🚨 ALERTA DE SEGURANÇA",
    "attachments": [
        {
            "color": "danger",
            "fields": [
                {
                    "title": "Evento",
                    "value": "$event",
                    "short": true
                },
                {
                    "title": "Timestamp",
                    "value": "$timestamp",
                    "short": true
                },
                {
                    "title": "Detalhes",
                    "value": "$details",
                    "short": false
                }
            ]
        }
    ]
}
EOF
        )
        
        curl -X POST -H 'Content-type: application/json' \
            --data "$payload" "$SLACK_WEBHOOK" >/dev/null 2>&1 || true
    fi
}

# Verificar tentativas de login falhadas
check_failed_logins() {
    log_info "🔍 Verificando tentativas de login falhadas..."
    
    local failed_count=0
    local suspicious_ips=()
    
    # Verificar logs da aplicação
    if [[ -d "$APP_LOG_DIR" ]]; then
        local app_logs=$(find "$APP_LOG_DIR" -name "*.log" -mtime -1 2>/dev/null || true)
        
        for log_file in $app_logs; do
            if [[ -f "$log_file" ]]; then
                # Procurar por padrões de falha de autenticação
                local failures=$(grep -i "authentication failed\|login failed\|invalid credentials\|unauthorized" "$log_file" 2>/dev/null | wc -l)
                failed_count=$((failed_count + failures))
                
                # Extrair IPs suspeitos
                grep -i "authentication failed\|login failed" "$log_file" 2>/dev/null | \
                    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | \
                    while read count ip; do
                        if [[ $count -gt $MAX_FAILED_LOGINS ]]; then
                            suspicious_ips+=("$ip:$count")
                        fi
                    done
            fi
        done
    fi
    
    # Verificar logs do Nginx
    if [[ -d "$NGINX_LOG_DIR" ]]; then
        local nginx_logs=$(find "$NGINX_LOG_DIR" -name "*access.log" -o -name "*error.log" -mtime -1 2>/dev/null || true)
        
        for log_file in $nginx_logs; do
            if [[ -f "$log_file" ]]; then
                # Verificar códigos de erro 401, 403
                local auth_failures=$(grep -E '" (401|403) ' "$log_file" 2>/dev/null | wc -l)
                failed_count=$((failed_count + auth_failures))
                
                # IPs com muitos 401/403
                grep -E '" (401|403) ' "$log_file" 2>/dev/null | \
                    awk '{print $1}' | sort | uniq -c | \
                    while read count ip; do
                        if [[ $count -gt $MAX_FAILED_LOGINS ]]; then
                            suspicious_ips+=("$ip:$count")
                        fi
                    done
            fi
        done
    fi
    
    # Reportar resultados
    if [[ $failed_count -gt 0 ]]; then
        security_log "WARNING" "FAILED_LOGINS" "$failed_count tentativas de login falhadas nas últimas 24h"
        
        if [[ ${#suspicious_ips[@]} -gt 0 ]]; then
            for ip_info in "${suspicious_ips[@]}"; do
                local ip=$(echo "$ip_info" | cut -d: -f1)
                local count=$(echo "$ip_info" | cut -d: -f2)
                security_log "ALERT" "SUSPICIOUS_IP" "IP $ip com $count tentativas de login falhadas"
            done
        fi
    else
        security_log "INFO" "FAILED_LOGINS" "Nenhuma tentativa de login falhada detectada"
    fi
    
    log_success "Verificação de logins concluída: $failed_count falhas detectadas"
}

# Detectar tentativas de SQL injection
check_sql_injection() {
    log_info "🛡️ Verificando tentativas de SQL injection..."
    
    local injection_patterns=(
        "union.*select"
        "drop.*table"
        "insert.*into"
        "delete.*from"
        "update.*set"
        "exec.*xp_"
        "sp_executesql"
        "'.*or.*'.*=.*'"
        "'.*and.*'.*=.*'"
        "1.*=.*1"
        "1.*or.*1"
        "sleep\\("
        "benchmark\\("
        "waitfor.*delay"
    )
    
    local injection_count=0
    local suspicious_requests=()
    
    # Verificar logs do Nginx
    if [[ -d "$NGINX_LOG_DIR" ]]; then
        local nginx_logs=$(find "$NGINX_LOG_DIR" -name "*access.log" -mtime -1 2>/dev/null || true)
        
        for log_file in $nginx_logs; do
            if [[ -f "$log_file" ]]; then
                for pattern in "${injection_patterns[@]}"; do
                    local matches=$(grep -iE "$pattern" "$log_file" 2>/dev/null | wc -l)
                    injection_count=$((injection_count + matches))
                    
                    if [[ $matches -gt 0 ]]; then
                        # Extrair IPs e requests suspeitos
                        grep -iE "$pattern" "$log_file" 2>/dev/null | \
                            awk '{print $1 " - " $7}' | head -5 | \
                            while read request; do
                                suspicious_requests+=("$request")
                            done
                    fi
                done
            fi
        done
    fi
    
    # Verificar logs da aplicação
    if [[ -d "$APP_LOG_DIR" ]]; then
        local app_logs=$(find "$APP_LOG_DIR" -name "*.log" -mtime -1 2>/dev/null || true)
        
        for log_file in $app_logs; do
            if [[ -f "$log_file" ]]; then
                for pattern in "${injection_patterns[@]}"; do
                    local matches=$(grep -iE "$pattern" "$log_file" 2>/dev/null | wc -l)
                    injection_count=$((injection_count + matches))
                done
            fi
        done
    fi
    
    # Reportar resultados
    if [[ $injection_count -gt 0 ]]; then
        security_log "ALERT" "SQL_INJECTION" "$injection_count tentativas de SQL injection detectadas"
        
        for request in "${suspicious_requests[@]}"; do
            security_log "ALERT" "SUSPICIOUS_REQUEST" "$request"
        done
    else
        security_log "INFO" "SQL_INJECTION" "Nenhuma tentativa de SQL injection detectada"
    fi
    
    log_success "Verificação de SQL injection concluída: $injection_count tentativas detectadas"
}

# Detectar atividade suspeita
check_suspicious_activity() {
    log_info "🕵️ Verificando atividade suspeita..."
    
    local suspicious_count=0
    
    # Padrões suspeitos
    local suspicious_patterns=(
        "../"
        "..\\\\" 
        "/etc/passwd"
        "/etc/shadow"
        "cmd.exe"
        "powershell"
        "<script"
        "javascript:"
        "eval\\("
        "base64_decode"
        "system\\("
        "exec\\("
        "shell_exec"
    )
    
    # Verificar logs do Nginx
    if [[ -d "$NGINX_LOG_DIR" ]]; then
        local nginx_logs=$(find "$NGINX_LOG_DIR" -name "*access.log" -mtime -1 2>/dev/null || true)
        
        for log_file in $nginx_logs; do
            if [[ -f "$log_file" ]]; then
                for pattern in "${suspicious_patterns[@]}"; do
                    local matches=$(grep -iE "$pattern" "$log_file" 2>/dev/null | wc -l)
                    suspicious_count=$((suspicious_count + matches))
                done
                
                # Verificar user agents suspeitos
                local bot_requests=$(grep -iE "bot|crawler|scanner|nikto|sqlmap|nmap" "$log_file" 2>/dev/null | wc -l)
                suspicious_count=$((suspicious_count + bot_requests))
                
                # Verificar requests muito grandes
                local large_requests=$(awk 'length($0) > 1000' "$log_file" 2>/dev/null | wc -l)
                suspicious_count=$((suspicious_count + large_requests))
            fi
        done
    fi
    
    # Verificar conexões de rede suspeitas
    if command -v netstat >/dev/null 2>&1; then
        local external_connections=$(netstat -tn 2>/dev/null | grep ESTABLISHED | \
            awk '{print $5}' | cut -d: -f1 | grep -v "127.0.0.1\|::1" | sort | uniq | wc -l)
        
        if [[ $external_connections -gt 50 ]]; then
            security_log "WARNING" "HIGH_CONNECTIONS" "$external_connections conexões externas ativas"
        fi
    fi
    
    # Verificar uso de CPU e memória
    if command -v top >/dev/null 2>&1; then
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
        
        if (( $(echo "$cpu_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
            security_log "WARNING" "HIGH_CPU" "Uso de CPU: ${cpu_usage}%"
        fi
        
        if (( $(echo "$mem_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
            security_log "WARNING" "HIGH_MEMORY" "Uso de memória: ${mem_usage}%"
        fi
    fi
    
    # Reportar resultados
    if [[ $suspicious_count -gt 0 ]]; then
        security_log "WARNING" "SUSPICIOUS_ACTIVITY" "$suspicious_count atividades suspeitas detectadas"
    else
        security_log "INFO" "SUSPICIOUS_ACTIVITY" "Nenhuma atividade suspeita detectada"
    fi
    
    log_success "Verificação de atividade suspeita concluída: $suspicious_count eventos detectados"
}

# Verificar integridade de arquivos críticos
check_file_integrity() {
    log_info "🔒 Verificando integridade de arquivos críticos..."
    
    local critical_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/hosts"
        "/etc/ssh/sshd_config"
        "/app/application.yml"
        "/app/application.properties"
    )
    
    local integrity_issues=0
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            # Verificar permissões
            local permissions=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
            local owner=$(stat -c "%U" "$file" 2>/dev/null || stat -f "%Su" "$file" 2>/dev/null)
            
            # Verificar modificações recentes
            local modified=$(find "$file" -mtime -1 2>/dev/null | wc -l)
            
            if [[ $modified -gt 0 ]]; then
                security_log "WARNING" "FILE_MODIFIED" "Arquivo crítico modificado: $file"
                ((integrity_issues++))
            fi
            
            # Verificar permissões específicas
            case "$file" in
                "/etc/shadow")
                    if [[ "$permissions" != "640" ]] && [[ "$permissions" != "600" ]]; then
                        security_log "ALERT" "INSECURE_PERMISSIONS" "$file tem permissões inseguras: $permissions"
                        ((integrity_issues++))
                    fi
                    ;;
                "/etc/passwd")
                    if [[ "$permissions" != "644" ]]; then
                        security_log "WARNING" "UNUSUAL_PERMISSIONS" "$file tem permissões incomuns: $permissions"
                    fi
                    ;;
            esac
        fi
    done
    
    if [[ $integrity_issues -eq 0 ]]; then
        security_log "INFO" "FILE_INTEGRITY" "Integridade de arquivos críticos OK"
    else
        security_log "WARNING" "FILE_INTEGRITY" "$integrity_issues problemas de integridade detectados"
    fi
    
    log_success "Verificação de integridade concluída: $integrity_issues problemas detectados"
}

# Verificação completa de logs
check_logs() {
    log_info "🔍 Iniciando verificação completa de segurança..."
    
    check_failed_logins
    check_sql_injection
    check_suspicious_activity
    check_file_integrity
    
    log_success "🔍 Verificação completa de segurança concluída"
}

# Gerar relatório de segurança
generate_report() {
    log_info "📊 Gerando relatório de segurança..."
    
    local report_file="$LOG_DIR/security-report-$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
╔══════════════════════════════════════════════════════════════════╗
║                    RELATÓRIO DE SEGURANÇA                       ║
║                    $(date '+%Y-%m-%d %H:%M:%S')                    ║
╚══════════════════════════════════════════════════════════════════╝

🔍 RESUMO EXECUTIVO
═══════════════════
EOF
    
    # Estatísticas dos últimos 7 dias
    if [[ -f "$SECURITY_LOG" ]]; then
        local alerts_count=$(grep -c "\[ALERT\]" "$SECURITY_LOG" 2>/dev/null || echo "0")
        local warnings_count=$(grep -c "\[WARNING\]" "$SECURITY_LOG" 2>/dev/null || echo "0")
        local total_events=$(wc -l < "$SECURITY_LOG" 2>/dev/null || echo "0")
        
        cat >> "$report_file" << EOF
Total de eventos de segurança: $total_events
Alertas críticos: $alerts_count
Avisos: $warnings_count

🚨 ALERTAS RECENTES (Últimas 24h)
═══════════════════════════════
EOF
        
        local yesterday=$(date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d' 2>/dev/null)
        grep -E "($yesterday|$(date '+%Y-%m-%d'))" "$SECURITY_LOG" | grep "\[ALERT\]" | tail -10 >> "$report_file" 2>/dev/null || echo "Nenhum alerta recente" >> "$report_file"
        
        cat >> "$report_file" << EOF

⚠️ AVISOS RECENTES (Últimas 24h)
═══════════════════════════════
EOF
        
        grep -E "($yesterday|$(date '+%Y-%m-%d'))" "$SECURITY_LOG" | grep "\[WARNING\]" | tail -10 >> "$report_file" 2>/dev/null || echo "Nenhum aviso recente" >> "$report_file"
    fi
    
    # Estatísticas de sistema
    cat >> "$report_file" << EOF

💻 STATUS DO SISTEMA
═══════════════════
EOF
    
    if command -v uptime >/dev/null 2>&1; then
        echo "Uptime: $(uptime)" >> "$report_file"
    fi
    
    if command -v df >/dev/null 2>&1; then
        echo "\nEspaço em disco:" >> "$report_file"
        df -h | head -5 >> "$report_file"
    fi
    
    if command -v free >/dev/null 2>&1; then
        echo "\nMemória:" >> "$report_file"
        free -h >> "$report_file"
    fi
    
    # Processos suspeitos
    cat >> "$report_file" << EOF

🔍 PROCESSOS ATIVOS
═══════════════════
EOF
    
    if command -v ps >/dev/null 2>&1; then
        ps aux --sort=-%cpu | head -10 >> "$report_file" 2>/dev/null || ps aux | head -10 >> "$report_file"
    fi
    
    # Conexões de rede
    cat >> "$report_file" << EOF

🌐 CONEXÕES DE REDE
═══════════════════
EOF
    
    if command -v netstat >/dev/null 2>&1; then
        netstat -tn | grep ESTABLISHED | wc -l | xargs echo "Conexões ativas:" >> "$report_file"
        echo "\nTop 10 IPs conectados:" >> "$report_file"
        netstat -tn | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 >> "$report_file" 2>/dev/null || echo "Nenhuma conexão" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

📝 RECOMENDAÇÕES
═══════════════
- Revisar alertas críticos imediatamente
- Monitorar IPs suspeitos
- Verificar logs de aplicação regularmente
- Manter sistema atualizado
- Implementar rate limiting se necessário

═══════════════════════════════════════════════════════════════════
Relatório gerado em: $(date '+%Y-%m-%d %H:%M:%S')
═══════════════════════════════════════════════════════════════════
EOF
    
    chmod 600 "$report_file"
    log_success "📊 Relatório gerado: $report_file"
    
    # Enviar relatório por email se configurado
    if [[ -n "$ALERT_EMAIL" ]] && command -v mail >/dev/null 2>&1; then
        mail -s "Relatório de Segurança - $(date '+%Y-%m-%d')" "$ALERT_EMAIL" < "$report_file"
        log_info "📧 Relatório enviado por email"
    fi
}

# Monitoramento contínuo
monitor() {
    log_info "🚀 Iniciando monitoramento contínuo de segurança..."
    log_info "Intervalo: ${MONITOR_INTERVAL}s | Logs: $LOG_DIR"
    
    # Criar diretórios necessários
    mkdir -p "$LOG_DIR"
    touch "$SECURITY_LOG" "$ALERT_LOG"
    
    # Loop de monitoramento
    while true; do
        log_info "🔄 Executando verificação de segurança..."
        
        check_logs
        
        log_info "⏰ Próxima verificação em ${MONITOR_INTERVAL}s"
        sleep "$MONITOR_INTERVAL"
    done
}

# Testar sistema de alertas
test_alerts() {
    log_info "🧪 Testando sistema de alertas..."
    
    security_log "ALERT" "TEST_ALERT" "Este é um teste do sistema de alertas"
    
    log_success "🧪 Teste de alerta enviado"
}

# Limpar logs antigos
cleanup_logs() {
    log_info "🧹 Limpando logs antigos..."
    
    local cleaned=0
    
    # Limpar logs de segurança (>30 dias)
    if [[ -f "$SECURITY_LOG" ]]; then
        local backup_file="$SECURITY_LOG.$(date +%Y%m%d).bak"
        cp "$SECURITY_LOG" "$backup_file"
        
        # Manter apenas últimos 30 dias
        local cutoff_date=$(date -d "30 days ago" '+%Y-%m-%d' 2>/dev/null || date -v-30d '+%Y-%m-%d' 2>/dev/null)
        grep -E "($cutoff_date|$(date '+%Y-%m-%d'))" "$SECURITY_LOG" > "$SECURITY_LOG.tmp" 2>/dev/null || true
        mv "$SECURITY_LOG.tmp" "$SECURITY_LOG" 2>/dev/null || true
        
        ((cleaned++))
    fi
    
    # Limpar logs de alerta (>7 dias)
    if [[ -f "$ALERT_LOG" ]]; then
        local cutoff_date=$(date -d "7 days ago" '+%Y-%m-%d' 2>/dev/null || date -v-7d '+%Y-%m-%d' 2>/dev/null)
        grep -E "($cutoff_date|$(date '+%Y-%m-%d'))" "$ALERT_LOG" > "$ALERT_LOG.tmp" 2>/dev/null || true
        mv "$ALERT_LOG.tmp" "$ALERT_LOG" 2>/dev/null || true
        
        ((cleaned++))
    fi
    
    # Limpar relatórios antigos (>90 dias)
    find "$LOG_DIR" -name "security-report-*.txt" -mtime +90 -delete 2>/dev/null || true
    
    log_success "🧹 Limpeza concluída: $cleaned logs processados"
}

# Processar comando
case "${1:-help}" in
    monitor)
        monitor
        ;;
    check-logs)
        check_logs
        ;;
    check-failed-logins)
        check_failed_logins
        ;;
    check-sql-injection)
        check_sql_injection
        ;;
    check-suspicious)
        check_suspicious_activity
        ;;
    generate-report)
        generate_report
        ;;
    test-alerts)
        test_alerts
        ;;
    cleanup-logs)
        cleanup_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Comando inválido: $1"
        show_help
        exit 1
        ;;
esac