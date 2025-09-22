#!/bin/bash
# =============================================================================
# 🏥 HEALTH AGGREGATOR - Script de Consolidação de Health Checks
# =============================================================================
#
# Script que consolida health checks de todos os microserviços e infraestrutura
# para exposição via Traefik endpoints.
#
# Uso: ./health-aggregator.sh [overall|infrastructure|backend|service_name]
# =============================================================================

set -euo pipefail

# Allow callers (ex.: embedded HTTP server) to suppress header output
SUPPRESS_HEADERS="${SUPPRESS_HEADERS:-0}"

# -----------------------------------------------------------------------------
# 📋 CONFIGURAÇÃO
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TIMEOUT=5

# Network name for Docker Swarm
NETWORK_NAME="conexao-network-swarm"

# Service definitions
declare -A INFRASTRUCTURE_SERVICES=(
    ["mysql"]="conexao-mysql:3306"
    ["redis"]="conexao-redis:6379"
    ["rabbitmq"]="conexao-rabbitmq:15672"
    ["kafka"]="conexao-kafka:9092"
    ["zookeeper"]="conexao-zookeeper:2181"
    ["traefik"]="conexao-traefik:8080"
)

declare -A BACKEND_SERVICES=(
    ["gateway"]="conexao-gateway_gateway:8088"
    ["resultados"]="conexao-resultados:8083"
    ["autenticacao"]="conexao-autenticacao:8081"
    ["usuario"]="conexao-usuario:8084"
    ["scheduler"]="conexao-scheduler:8085"
    ["notificacoes"]="conexao-notificacoes:8082"
    ["financeiro"]="conexao-financeiro:8087"
    ["observabilidade"]="conexao-observabilidade:8088"
    ["auditoria"]="conexao-auditoria:8089"
    ["batepapo"]="conexao-batepapo:8090"
    ["criptografia"]="conexao-criptografia:8091"
    ["chatbot"]="conexao-chatbot:8092"
)

# -----------------------------------------------------------------------------
# 🔧 HELPER FUNCTIONS
# -----------------------------------------------------------------------------

# Check if a service is healthy
check_service_health() {
    local service_name="$1"
    local service_url="$2"
    local health_path="${3:-/actuator/health}"

    # Try to check health endpoint
    if timeout "$TIMEOUT" curl -f -s "http://${service_url}${health_path}" >/dev/null 2>&1; then
        echo "healthy"
        return 0
    fi

    # If health endpoint fails, check if container is running
    if docker ps --filter "name=${service_name}" --format "{{.Names}}" | grep -q "${service_name}"; then
        container_status=$(docker ps --filter "name=${service_name}" --format "{{.Status}}")
        if [[ "$container_status" =~ ^Up.*healthy ]]; then
            echo "healthy"
            return 0
        elif [[ "$container_status" =~ ^Up ]]; then
            echo "starting"
            return 1
        fi
    fi

    echo "down"
    return 2
}

# Generate JSON response
generate_json() {
    local status="$1"
    shift
    local -A data=()

    # Parse key=value pairs
    for pair in "$@"; do
        if [[ "$pair" =~ ^([^=]+)=(.*)$ ]]; then
            data["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        fi
    done

    # Build JSON
    local json='{'
    json+="\"timestamp\":\"$TIMESTAMP\","
    json+="\"status\":\"$status\","

    for key in "${!data[@]}"; do
        json+="\"$key\":\"${data[$key]}\","
    done

    # Remove trailing comma and close
    json="${json%,}}"
    echo "$json"
}

# -----------------------------------------------------------------------------
# 🏥 HEALTH CHECK FUNCTIONS
# -----------------------------------------------------------------------------

# Check overall system health
check_overall_health() {
    local total_services=0
    local healthy_services=0
    local starting_services=0
    local down_services=0

    # Check infrastructure
    for service in "${!INFRASTRUCTURE_SERVICES[@]}"; do
        total_services=$((total_services + 1))
        case $(check_service_health "$service" "${INFRASTRUCTURE_SERVICES[$service]}" "/health") in
            "healthy") healthy_services=$((healthy_services + 1)) ;;
            "starting") starting_services=$((starting_services + 1)) ;;
            "down") down_services=$((down_services + 1)) ;;
        esac
    done

    # Check backend services
    for service in "${!BACKEND_SERVICES[@]}"; do
        total_services=$((total_services + 1))
        case $(check_service_health "$service" "${BACKEND_SERVICES[$service]}") in
            "healthy") healthy_services=$((healthy_services + 1)) ;;
            "starting") starting_services=$((starting_services + 1)) ;;
            "down") down_services=$((down_services + 1)) ;;
        esac
    done

    # Determine overall status
    local overall_status="healthy"
    if [[ $down_services -gt 0 ]]; then
        if [[ $healthy_services -eq 0 ]]; then
            overall_status="critical"
        else
            overall_status="degraded"
        fi
    elif [[ $starting_services -gt 0 ]]; then
        overall_status="starting"
    fi

    generate_json "$overall_status" \
        "services=$total_services" \
        "healthy=$healthy_services" \
        "starting=$starting_services" \
        "down=$down_services" \
        "uptime_threshold=80"
}

# Check infrastructure health
check_infrastructure_health() {
    local -A results=()
    local healthy_count=0
    local total_count=0

    for service in "${!INFRASTRUCTURE_SERVICES[@]}"; do
        total_count=$((total_count + 1))
        local status=$(check_service_health "$service" "${INFRASTRUCTURE_SERVICES[$service]}" "/health")
        results["$service"]="$status"

        if [[ "$status" == "healthy" ]]; then
            healthy_count=$((healthy_count + 1))
        fi
    done

    # Determine overall infrastructure status
    local overall_status="healthy"
    if [[ $healthy_count -eq 0 ]]; then
        overall_status="critical"
    elif [[ $healthy_count -lt $total_count ]]; then
        overall_status="degraded"
    fi

    # Build result pairs
    local pairs=("services=$total_count" "healthy=$healthy_count")
    for service in "${!results[@]}"; do
        pairs+=("$service=${results[$service]}")
    done

    generate_json "$overall_status" "${pairs[@]}"
}

# Check backend services health
check_backend_health() {
    local -A results=()
    local healthy_count=0
    local total_count=0

    for service in "${!BACKEND_SERVICES[@]}"; do
        total_count=$((total_count + 1))
        local status=$(check_service_health "$service" "${BACKEND_SERVICES[$service]}")
        results["$service"]="$status"

        if [[ "$status" == "healthy" ]]; then
            healthy_count=$((healthy_count + 1))
        fi
    done

    # Determine overall backend status
    local overall_status="healthy"
    if [[ $healthy_count -eq 0 ]]; then
        overall_status="critical"
    elif [[ $healthy_count -lt $((total_count / 2)) ]]; then
        overall_status="degraded"
    fi

    # Build result pairs
    local pairs=("services=$total_count" "healthy=$healthy_count")
    for service in "${!results[@]}"; do
        pairs+=("$service=${results[$service]}")
    done

    generate_json "$overall_status" "${pairs[@]}"
}

# Check individual service health
check_individual_service() {
    local service_name="$1"
    local service_url=""
    local health_path="/actuator/health"

    # Find service in infrastructure or backend
    if [[ -n "${INFRASTRUCTURE_SERVICES[$service_name]:-}" ]]; then
        service_url="${INFRASTRUCTURE_SERVICES[$service_name]}"
        health_path="/health"
    elif [[ -n "${BACKEND_SERVICES[$service_name]:-}" ]]; then
        service_url="${BACKEND_SERVICES[$service_name]}"
    else
        generate_json "not_found" "error=Service '$service_name' not found"
        return 1
    fi

    local status=$(check_service_health "$service_name" "$service_url" "$health_path")

    # Get additional info if available
    local uptime="unknown"
    local version="unknown"

    if docker ps --filter "name=${service_name}" --format "{{.Status}}" | grep -q "Up"; then
        uptime=$(docker ps --filter "name=${service_name}" --format "{{.Status}}" | sed 's/Up //' | awk '{print $1}')
    fi

    generate_json "$status" \
        "service=$service_name" \
        "uptime=$uptime" \
        "version=$version" \
        "url=$service_url"
}

# -----------------------------------------------------------------------------
# 🚀 MAIN FUNCTION
# -----------------------------------------------------------------------------

main() {
    local check_type="${1:-overall}"

    # Set appropriate headers unless explicitly suppressed
    if [[ "$SUPPRESS_HEADERS" != "1" ]]; then
        echo "Content-Type: application/json"
        echo "Cache-Control: no-cache, no-store, must-revalidate"
        echo "X-Health-Monitor: traefik-central"
        echo ""
    fi

    case "$check_type" in
        "overall")
            check_overall_health
            ;;
        "infrastructure")
            check_infrastructure_health
            ;;
        "backend")
            check_backend_health
            ;;
        *)
            # Assume it's a service name
            check_individual_service "$check_type"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# 🏃‍♂️ EXECUTION
# -----------------------------------------------------------------------------

# Handle CGI environment if running via web server
if [[ -n "${REQUEST_URI:-}" ]]; then
    # Extract service name from path
    if [[ "$REQUEST_URI" =~ /health/service/([^/?]+) ]]; then
        main "${BASH_REMATCH[1]}"
    elif [[ "$REQUEST_URI" =~ /health/([^/?]+) ]]; then
        main "${BASH_REMATCH[1]}"
    else
        main "overall"
    fi
else
    # Command line execution
    main "$@"
fi
