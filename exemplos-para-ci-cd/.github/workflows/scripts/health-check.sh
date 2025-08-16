#!/bin/bash

# ===== SCRIPT DE MONITORAMENTO DE SAÚDE DO SISTEMA =====
# Sistema: Conexão de Sorte - Backend
# Função: Verificar saúde dos serviços e recursos do sistema
# Versão: 1.0.0
# Data: $(date +"%d/%m/%Y")

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/health-check.log"
REPORT_FILE="$PROJECT_ROOT/logs/health-report-$(date +%Y%m%d_%H%M%S).json"

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
LOAD_THRESHOLD=2.0

# URLs para verificação
APP_URL="http://localhost:8080/actuator/health"
PROMETHEUS_URL="http://localhost:9090/-/healthy"
GRAFANA_URL="http://localhost:3000/api/health"
ALERTMANAGER_URL="http://localhost:9093/-/healthy"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNÇÕES AUXILIARES =====
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# ===== VERIFICAÇÕES DE SISTEMA =====
check_system_resources() {
    log_info "Verificando recursos do sistema..."
    
    local status="healthy"
    local issues=()
    
    # CPU Usage
    local cpu_usage
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' || echo "0")
    else
        cpu_usage="0"
    fi
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        log_warning "CPU usage alto: ${cpu_usage}%"
        status="warning"
        issues+=("high_cpu")
    else
        log_success "CPU usage normal: ${cpu_usage}%"
    fi
    
    # Memory Usage
    local memory_usage
    if command -v vm_stat >/dev/null 2>&1; then
        local pages_free pages_active pages_inactive pages_speculative pages_wired page_size
        pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        pages_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        pages_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
        pages_speculative=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | sed 's/\.//')
        pages_wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
        page_size=$(vm_stat | grep "page size" | awk '{print $8}')
        
        local total_pages=$((pages_free + pages_active + pages_inactive + pages_speculative + pages_wired))
        local used_pages=$((pages_active + pages_inactive + pages_speculative + pages_wired))
        memory_usage=$((used_pages * 100 / total_pages))
    else
        memory_usage="0"
    fi
    
    if (( memory_usage > MEMORY_THRESHOLD )); then
        log_warning "Memory usage alto: ${memory_usage}%"
        status="warning"
        issues+=("high_memory")
    else
        log_success "Memory usage normal: ${memory_usage}%"
    fi
    
    # Disk Usage
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if (( disk_usage > DISK_THRESHOLD )); then
        log_error "Disk usage crítico: ${disk_usage}%"
        status="critical"
        issues+=("high_disk")
    elif (( disk_usage > 75 )); then
        log_warning "Disk usage alto: ${disk_usage}%"
        status="warning"
        issues+=("moderate_disk")
    else
        log_success "Disk usage normal: ${disk_usage}%"
    fi
    
    # Load Average
    local load_avg
    load_avg=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l) )); then
        log_warning "Load average alto: $load_avg"
        status="warning"
        issues+=("high_load")
    else
        log_success "Load average normal: $load_avg"
    fi
    
    # Retornar resultado
    echo "{\"status\": \"$status\", \"cpu_usage\": $cpu_usage, \"memory_usage\": $memory_usage, \"disk_usage\": $disk_usage, \"load_avg\": \"$load_avg\", \"issues\": [$(printf '\"%s\",' "${issues[@]}" | sed 's/,$//')]}"
}

# ===== VERIFICAÇÕES DE SERVIÇOS DOCKER =====
check_docker_services() {
    log_info "Verificando serviços Docker..."
    
    local status="healthy"
    local services_status=()
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não encontrado"
        echo "{\"status\": \"critical\", \"error\": \"docker_not_found\"}"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        echo "{\"status\": \"critical\", \"error\": \"docker_not_running\"}"
        return 1
    fi
    
    # Verificar serviços específicos
    local services=(
        "mysql"
        "backend-green"
        "backend-blue"
    
        "prometheus"
        "grafana"
        "alertmanager"
    )
    
    for service in "${services[@]}"; do
        local container_status
        container_status=$(docker ps --filter "name=$service" --format "{{.Status}}" | head -1)
        
        if [[ -n "$container_status" ]]; then
            if [[ "$container_status" == *"Up"* ]]; then
                log_success "Serviço $service está rodando"
                services_status+=("{\"name\": \"$service\", \"status\": \"running\", \"details\": \"$container_status\"}")
            else
                log_warning "Serviço $service com problema: $container_status"
                status="warning"
                services_status+=("{\"name\": \"$service\", \"status\": \"unhealthy\", \"details\": \"$container_status\"}")
            fi
        else
            log_error "Serviço $service não encontrado"
            status="critical"
            services_status+=("{\"name\": \"$service\", \"status\": \"not_found\", \"details\": \"container not found\"}")
        fi
    done
    
    echo "{\"status\": \"$status\", \"services\": [$(IFS=,; echo "${services_status[*]}")]}"
}

# ===== VERIFICAÇÕES DE ENDPOINTS =====
check_endpoints() {
    log_info "Verificando endpoints de saúde..."
    
    local status="healthy"
    local endpoints_status=()
    
    # Definir endpoints para verificar
    local -A endpoints=(
        ["application"]="$APP_URL"
        ["prometheus"]="$PROMETHEUS_URL"
        ["grafana"]="$GRAFANA_URL"
        ["alertmanager"]="$ALERTMANAGER_URL"
    )
    
    for name in "${!endpoints[@]}"; do
        local url="${endpoints[$name]}"
        local response_code
        local response_time
        
        log_info "Verificando $name: $url"
        
        # Fazer requisição com timeout
        if response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null); then
            response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$url" 2>/dev/null)
            
            if [[ "$response_code" == "200" ]]; then
                log_success "$name está saudável (${response_code}, ${response_time}s)"
                endpoints_status+=("{\"name\": \"$name\", \"status\": \"healthy\", \"response_code\": $response_code, \"response_time\": $response_time}")
            else
                log_warning "$name retornou código $response_code"
                status="warning"
                endpoints_status+=("{\"name\": \"$name\", \"status\": \"unhealthy\", \"response_code\": $response_code, \"response_time\": $response_time}")
            fi
        else
            log_error "$name não está acessível"
            status="critical"
            endpoints_status+=("{\"name\": \"$name\", \"status\": \"unreachable\", \"response_code\": 0, \"response_time\": 0}")
        fi
    done
    
    echo "{\"status\": \"$status\", \"endpoints\": [$(IFS=,; echo "${endpoints_status[*]}")]}"
}

# ===== VERIFICAÇÕES DE BANCO DE DADOS =====
check_database() {
    log_info "Verificando banco de dados..."
    
    local status="healthy"
    local db_status="{}"
    
    # Verificar se container MySQL está rodando
    local mysql_container
    mysql_container=$(docker ps --filter "name=mysql" --format "{{.Names}}" | head -1)
    
    if [[ -z "$mysql_container" ]]; then
        log_error "Container MySQL não encontrado"
        echo "{\"status\": \"critical\", \"error\": \"mysql_container_not_found\"}"
        return 1
    fi
    
    # Verificar conectividade
    if docker exec "$mysql_container" mysqladmin ping -h localhost --silent 2>/dev/null; then
        log_success "MySQL está respondendo"
        
        # Obter estatísticas do MySQL
        local connections processes
        connections=$(docker exec "$mysql_container" mysql -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1 | awk '{print $2}' || echo "0")
        processes=$(docker exec "$mysql_container" mysql -e "SHOW PROCESSLIST;" 2>/dev/null | wc -l || echo "0")
        
        # Verificar espaço em disco do banco
        local db_size
        db_size=$(docker exec "$mysql_container" mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' FROM information_schema.tables;" 2>/dev/null | tail -1 || echo "0")
        
        db_status="{\"connections\": $connections, \"processes\": $processes, \"size_mb\": $db_size}"
        
        # Verificar se há muitas conexões
        if (( connections > 50 )); then
            log_warning "Muitas conexões MySQL: $connections"
            status="warning"
        fi
        
    else
        log_error "MySQL não está respondendo"
        status="critical"
        db_status="{\"error\": \"mysql_not_responding\"}"
    fi
    
    echo "{\"status\": \"$status\", \"database\": $db_status}"
}

# ===== VERIFICAÇÕES DE VOLUMES =====
check_volumes() {
    log_info "Verificando volumes Docker..."
    
    local status="healthy"
    local volumes_status=()
    
    local volumes=(
        "mysql_data"
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            local mountpoint
            mountpoint=$(docker volume inspect "$volume" --format '{{.Mountpoint}}')
            
            # Verificar se o mountpoint existe e é acessível
            if [[ -d "$mountpoint" ]]; then
                log_success "Volume $volume está OK"
                volumes_status+=("{\"name\": \"$volume\", \"status\": \"healthy\", \"mountpoint\": \"$mountpoint\"}")
            else
                log_warning "Volume $volume: mountpoint não acessível"
                status="warning"
                volumes_status+=("{\"name\": \"$volume\", \"status\": \"mountpoint_issue\", \"mountpoint\": \"$mountpoint\"}")
            fi
        else
            log_error "Volume $volume não encontrado"
            status="critical"
            volumes_status+=("{\"name\": \"$volume\", \"status\": \"not_found\", \"mountpoint\": \"\"}")
        fi
    done
    
    echo "{\"status\": \"$status\", \"volumes\": [$(IFS=,; echo "${volumes_status[*]}")]}"
}

# ===== VERIFICAÇÕES DE LOGS =====
check_logs() {
    log_info "Verificando logs do sistema..."
    
    local status="healthy"
    local log_issues=()
    
    # Verificar logs de erro recentes (última hora)
    local error_count
    error_count=$(find "$PROJECT_ROOT/logs" -name "*.log" -mmin -60 -exec grep -l "ERROR\|FATAL" {} \; 2>/dev/null | wc -l || echo "0")
    
    if (( error_count > 0 )); then
        log_warning "$error_count arquivos de log com erros na última hora"
        status="warning"
        log_issues+=("recent_errors")
    fi
    
    # Verificar tamanho dos logs
    local large_logs
    large_logs=$(find "$PROJECT_ROOT/logs" -name "*.log" -size +100M 2>/dev/null | wc -l || echo "0")
    
    if (( large_logs > 0 )); then
        log_warning "$large_logs arquivos de log grandes (>100MB)"
        status="warning"
        log_issues+=("large_logs")
    fi
    
    # Verificar logs do Docker
    local containers_with_errors
    containers_with_errors=$(docker ps --format "{{.Names}}" | xargs -I {} sh -c 'docker logs --since=1h {} 2>&1 | grep -q "ERROR\|FATAL" && echo {}' | wc -l || echo "0")
    
    if (( containers_with_errors > 0 )); then
        log_warning "$containers_with_errors containers com erros nos logs"
        status="warning"
        log_issues+=("container_errors")
    fi
    
    echo "{\"status\": \"$status\", \"error_files\": $error_count, \"large_logs\": $large_logs, \"containers_with_errors\": $containers_with_errors, \"issues\": [$(printf '\"%s\",' "${log_issues[@]}" | sed 's/,$//')]}"
}

# ===== VERIFICAÇÕES DE SEGURANÇA =====
check_security() {
    log_info "Verificando aspectos de segurança..."
    
    local status="healthy"
    local security_issues=()
    
    # Verificar se há containers rodando como root
    local root_containers
    root_containers=$(docker ps --format "{{.Names}}" | xargs -I {} docker exec {} whoami 2>/dev/null | grep -c "root" || echo "0")
    
    if (( root_containers > 0 )); then
        log_warning "$root_containers containers rodando como root"
        status="warning"
        security_issues+=("root_containers")
    fi
    
    # Verificar portas expostas
    local exposed_ports
    exposed_ports=$(docker ps --format "{{.Ports}}" | grep -o "0.0.0.0:[0-9]*" | wc -l || echo "0")
    
    if (( exposed_ports > 10 )); then
        log_warning "Muitas portas expostas: $exposed_ports"
        status="warning"
        security_issues+=("many_exposed_ports")
    fi
    
    # Verificar se há arquivos .env expostos
    local exposed_env_files
    exposed_env_files=$(find "$PROJECT_ROOT" -name "*.env" -type f 2>/dev/null | wc -l || echo "0")
    
    if (( exposed_env_files > 0 )); then
        log_warning "$exposed_env_files arquivos .env encontrados"
        status="warning"
        security_issues+=("env_files_present")
    fi
    
    echo "{\"status\": \"$status\", \"root_containers\": $root_containers, \"exposed_ports\": $exposed_ports, \"env_files\": $exposed_env_files, \"issues\": [$(printf '\"%s\",' "${security_issues[@]}" | sed 's/,$//')]}"
}

# ===== GERAÇÃO DE RELATÓRIO =====
generate_report() {
    log_info "Gerando relatório de saúde..."
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Executar todas as verificações
    local system_check
    local docker_check
    local endpoints_check
    local database_check
    local volumes_check
    local logs_check
    local security_check
    
    system_check=$(check_system_resources)
    docker_check=$(check_docker_services)
    endpoints_check=$(check_endpoints)
    database_check=$(check_database)
    volumes_check=$(check_volumes)
    logs_check=$(check_logs)
    security_check=$(check_security)
    
    # Determinar status geral
    local overall_status="healthy"
    
    if echo "$system_check $docker_check $endpoints_check $database_check $volumes_check $logs_check $security_check" | grep -q '"critical"'; then
        overall_status="critical"
    elif echo "$system_check $docker_check $endpoints_check $database_check $volumes_check $logs_check $security_check" | grep -q '"warning"'; then
        overall_status="warning"
    fi
    
    # Gerar relatório JSON
    cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$timestamp",
  "overall_status": "$overall_status",
  "checks": {
    "system": $system_check,
    "docker": $docker_check,
    "endpoints": $endpoints_check,
    "database": $database_check,
    "volumes": $volumes_check,
    "logs": $logs_check,
    "security": $security_check
  },
  "metadata": {
    "hostname": "$(hostname)",
    "script_version": "1.0.0",
    "check_duration": "$(date +%s)"
  }
}
EOF
    
    log_success "Relatório gerado: $REPORT_FILE"
    
    # Mostrar resumo
    echo
    echo "===== RESUMO DO HEALTH CHECK ====="
    echo "Status Geral: $overall_status"
    echo "Timestamp: $timestamp"
    echo "Relatório: $REPORT_FILE"
    echo
    
    # Retornar código de saída baseado no status
    case "$overall_status" in
        "healthy")
            return 0
            ;;
        "warning")
            return 1
            ;;
        "critical")
            return 2
            ;;
    esac
}

# ===== MONITORAMENTO CONTÍNUO =====
continuous_monitoring() {
    local interval="${1:-60}"  # Intervalo em segundos (padrão: 60s)
    
    log_info "Iniciando monitoramento contínuo (intervalo: ${interval}s)"
    log_info "Pressione Ctrl+C para parar"
    
    while true; do
        echo
        log_info "Executando verificação de saúde..."
        
        if generate_report; then
            log_success "Sistema saudável"
        else
            local exit_code=$?
            if [[ $exit_code -eq 1 ]]; then
                log_warning "Sistema com avisos"
            else
                log_error "Sistema com problemas críticos"
            fi
        fi
        
        log_info "Próxima verificação em ${interval}s..."
        sleep "$interval"
    done
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    # Criar diretório de logs
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_info "Iniciando health check do sistema"
    
    case "${1:-}" in
        "system")
            check_system_resources
            ;;
        "docker")
            check_docker_services
            ;;
        "endpoints")
            check_endpoints
            ;;
        "database")
            check_database
            ;;
        "volumes")
            check_volumes
            ;;
        "logs")
            check_logs
            ;;
        "security")
            check_security
            ;;
        "monitor")
            continuous_monitoring "${2:-60}"
            ;;
        "report")
            generate_report
            ;;
        "")
            generate_report
            ;;
        *)
            echo "Uso: $0 [system|docker|endpoints|database|volumes|logs|security|monitor [interval]|report]"
            echo
            echo "Comandos:"
            echo "  system     - Verificar recursos do sistema"
            echo "  docker     - Verificar serviços Docker"
            echo "  endpoints  - Verificar endpoints de saúde"
            echo "  database   - Verificar banco de dados"
            echo "  volumes    - Verificar volumes Docker"
            echo "  logs       - Verificar logs do sistema"
            echo "  security   - Verificar aspectos de segurança"
            echo "  monitor    - Monitoramento contínuo"
            echo "  report     - Gerar relatório completo"
            echo
            echo "Sem argumentos: Executar relatório completo"
            exit 1
            ;;
    esac
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi