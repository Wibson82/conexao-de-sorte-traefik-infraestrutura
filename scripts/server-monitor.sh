#!/bin/bash

# =============================================================================
# 📊 SERVIDOR MONITOR - SISTEMA COMPLETO DE LOGS E STATUS
# =============================================================================
# Monitora todos os containers dos projetos backend e infraestrutura
# Gera logs detalhados em JSON para API /rest/v1/log-servidor
# =============================================================================

# Configurações
LOG_DIR="/app/logs"
LOG_FILE="$LOG_DIR/server-monitor.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Criar diretório se não existir
mkdir -p "$LOG_DIR"

# Função para verificar se container está saudável
check_container_health() {
    local container_name="$1"
    local health_status="unknown"
    local container_state="not_found"
    local restart_count=0
    local uptime="unknown"
    local logs_errors=""

    # Verificar se container existe
    if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
        # Status do container
        container_state=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "error")

        # Health check status (se disponível)
        health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$container_name" 2>/dev/null || echo "unknown")

        # Restart count
        restart_count=$(docker inspect --format='{{.RestartCount}}' "$container_name" 2>/dev/null || echo "0")

        # Uptime calculation
        started_at=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" 2>/dev/null)
        if [[ -n "$started_at" && "$started_at" != "0001-01-01T00:00:00Z" ]]; then
            start_epoch=$(date -d "$started_at" +%s 2>/dev/null || echo "0")
            current_epoch=$(date +%s)
            uptime_seconds=$((current_epoch - start_epoch))
            uptime="${uptime_seconds}s"
        fi

        # Últimas 10 linhas de log com erros
        logs_errors=$(docker logs "$container_name" --tail=50 2>&1 | grep -i "error\|exception\|failed\|fatal" | tail -10 | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
    fi

    # Retornar JSON
    cat <<EOF
{
    "name": "$container_name",
    "state": "$container_state",
    "health": "$health_status",
    "restart_count": $restart_count,
    "uptime": "$uptime",
    "errors": $logs_errors,
    "checked_at": "$TIMESTAMP"
}
EOF
}

# Função para verificar todos os projetos
monitor_all_projects() {
    echo "{"
    echo "  \"timestamp\": \"$TIMESTAMP\","
    echo "  \"monitoring\": {"
    echo "    \"backend_projects\": ["

    # Lista de projetos backend
    backend_projects=(
        "conexao-gateway"
        "conexao-autenticacao"
        "conexao-resultados"
        "conexao-scheduler"
        "conexao-notificacoes"
        "conexao-batepapo"
        "conexao-chatbot"
        "conexao-observabilidade"
        "conexao-financeiro"
        "conexao-auditoria-compliance"
        "conexao-criptografia-kms"
    )

    for i in "${!backend_projects[@]}"; do
        check_container_health "${backend_projects[i]}"
        if [[ $i -lt $((${#backend_projects[@]} - 1)) ]]; then
            echo ","
        fi
    done

    echo "    ],"
    echo "    \"infrastructure_projects\": ["

    # Lista de projetos de infraestrutura
    infra_projects=(
        "conexao-mysql"
        "conexao-redis"
        "conexao-kafka"
        "conexao-zookeeper"
        "conexao-rabbitmq"
        "conexao-traefik"
        "conexao-jaeger"
    )

    for i in "${!infra_projects[@]}"; do
        check_container_health "${infra_projects[i]}"
        if [[ $i -lt $((${#infra_projects[@]} - 1)) ]]; then
            echo ","
        fi
    done

    echo "    ]"
    echo "  },"
    echo "  \"summary\": {"

    # Calcular estatísticas gerais
    total_containers=$((${#backend_projects[@]} + ${#infra_projects[@]}))
    running_containers=$(docker ps --format "{{.Names}}" | grep -c "^conexao-" || echo "0")
    unhealthy_containers=$(docker ps --format "{{.Names}}" | xargs -r -I {} docker inspect --format='{{.Name}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-check{{end}}' {} 2>/dev/null | grep -c "unhealthy" || echo "0")

    echo "    \"total_expected\": $total_containers,"
    echo "    \"running\": $running_containers,"
    echo "    \"unhealthy\": $unhealthy_containers,"
    echo "    \"success_rate\": $(echo "scale=2; $running_containers * 100 / $total_containers" | bc -l 2>/dev/null || echo "0"),"
    echo "    \"system_status\": \"$(if [[ $running_containers -eq $total_containers ]] && [[ $unhealthy_containers -eq 0 ]]; then echo "healthy"; else echo "degraded"; fi)\","
    echo "    \"auth_required\": $(if [[ $running_containers -eq $total_containers ]] && [[ $unhealthy_containers -eq 0 ]]; then echo "true"; else echo "false"; fi)"
    echo "  },"
    echo "  \"docker_info\": {"
    echo "    \"swarm_mode\": \"$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo 'inactive')\","
    echo "    \"node_role\": \"$(docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null && echo 'manager' || echo 'worker')\","
    echo "    \"total_containers\": $(docker ps -a -q | wc -l),"
    echo "    \"running_containers\": $(docker ps -q | wc -l)"
    echo "  }"
    echo "}"
}

# Executar monitoramento e salvar
monitor_all_projects > "$LOG_FILE.tmp"
mv "$LOG_FILE.tmp" "$LOG_FILE"

# Log de execução
echo "[$(date)] Monitor executado, arquivo salvo: $LOG_FILE" >> "$LOG_DIR/monitor-execution.log"