#!/bin/bash

# ===== AUTOMATED MICROSERVICES DEPLOYMENT =====
# Deploy microservices in order of priority with health checks

set -e

echo "🚀 Starting automated microservices deployment..."

# Configuration
PROJECT_DIR="/opt/conexao-microservices"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
HEALTH_CHECK_TIMEOUT=120
HEALTH_CHECK_INTERVAL=10

# Deployment order by priority (critical first)
declare -a DEPLOYMENT_ORDER=(
    "traefik:Traefik Load Balancer:8080:/dashboard/"
    "auth-microservice:Authentication Service:8080:/actuator/health"
    "results-microservice:Results Service:8081:/actuator/health"
    "notifications-microservice:Notifications Service:8083:/actuator/health"
    "chat-microservice:Chat Service:8082:/actuator/health"
    "audit-microservice:Audit Service:8084:/actuator/health"
    "observability-microservice:Observability Service:8085:/actuator/health"
    "scheduler-microservice:Scheduler Service:8086:/actuator/health"
    "crypto-microservice:Cryptography Service:8087:/actuator/health"
    "frontend-web:Frontend Web:3000:/"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

# Health check function
check_health() {
    local service_name="$1"
    local port="$2"
    local health_path="$3"
    local max_attempts=$((HEALTH_CHECK_TIMEOUT / HEALTH_CHECK_INTERVAL))
    local attempt=1
    
    log "Checking health for $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "http://localhost:$port$health_path" > /dev/null 2>&1; then
            success "$service_name is healthy (attempt $attempt/$max_attempts)"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            error "$service_name health check failed after $max_attempts attempts"
            return 1
        fi
        
        warning "$service_name not ready, attempt $attempt/$max_attempts (waiting ${HEALTH_CHECK_INTERVAL}s)"
        sleep $HEALTH_CHECK_INTERVAL
        ((attempt++))
    done
}

# HTTPS health check function (for external access)
check_https_health() {
    local service_name="$1"
    local domain="$2"
    local health_path="$3"
    local max_attempts=10
    local attempt=1
    
    log "Checking HTTPS health for $service_name at https://$domain$health_path..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s -k "https://$domain$health_path" > /dev/null 2>&1; then
            success "$service_name is accessible via HTTPS (attempt $attempt/$max_attempts)"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            warning "$service_name HTTPS health check failed after $max_attempts attempts (may need DNS propagation)"
            return 1
        fi
        
        sleep 10
        ((attempt++))
    done
}

# Deployment function
deploy_service() {
    local service_info="$1"
    IFS=':' read -r service_name description port health_path <<< "$service_info"
    
    echo ""
    echo "=========================================="
    log "Deploying: $description ($service_name)"
    echo "=========================================="
    
    # Check if service is already running
    if docker compose -f "$COMPOSE_FILE" ps "$service_name" | grep -q "Up"; then
        warning "$service_name is already running, performing rolling update..."
        
        # Backup current version
        docker tag "$service_name:current" "$service_name:backup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
        
        # Pull latest image
        log "Pulling latest image for $service_name..."
        if ! docker compose -f "$COMPOSE_FILE" pull "$service_name"; then
            error "Failed to pull image for $service_name"
            return 1
        fi
        
        # Rolling update
        log "Performing rolling update for $service_name..."
        if ! docker compose -f "$COMPOSE_FILE" up -d "$service_name" --no-deps; then
            error "Failed to update $service_name"
            return 1
        fi
    else
        # Fresh deployment
        log "Starting fresh deployment of $service_name..."
        if ! docker compose -f "$COMPOSE_FILE" up -d "$service_name" --no-deps; then
            error "Failed to start $service_name"
            return 1
        fi
    fi
    
    # Health check
    if ! check_health "$service_name" "$port" "$health_path"; then
        error "Health check failed for $service_name"
        
        # Attempt rollback if backup exists
        if docker images | grep -q "$service_name:backup-"; then
            warning "Attempting rollback for $service_name..."
            docker tag "$service_name:backup-$(date +%Y%m%d)" "$service_name:current" 2>/dev/null || true
            docker compose -f "$COMPOSE_FILE" up -d "$service_name" --no-deps
        fi
        
        return 1
    fi
    
    success "$description deployed successfully!"
    
    # Additional HTTPS check for external services
    case $service_name in
        "auth-microservice")
            check_https_health "$service_name" "auth.conexaodesorte.com.br" "/actuator/health"
            ;;
        "results-microservice")
            check_https_health "$service_name" "results.conexaodesorte.com.br" "/actuator/health"
            ;;
        "chat-microservice")
            check_https_health "$service_name" "chat.conexaodesorte.com.br" "/actuator/health"
            ;;
        "notifications-microservice")
            check_https_health "$service_name" "notifications.conexaodesorte.com.br" "/actuator/health"
            ;;
    esac
    
    return 0
}

# Pre-deployment checks
pre_deployment_checks() {
    log "Running pre-deployment checks..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        error "Docker is not running or not accessible"
        exit 1
    fi
    success "Docker is running"
    
    # Check if Docker Compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    success "Docker Compose file found"
    
    # Check if network exists
    if ! docker network ls | grep -q "conexao-network"; then
        log "Creating Docker network..."
        docker network create conexao-network --driver bridge --subnet 172.20.0.0/16
        success "Docker network created"
    else
        success "Docker network exists"
    fi
    
    # Check available disk space
    available_space=$(df "$PROJECT_DIR" | awk 'NR==2{print $4}')
    if [ "$available_space" -lt 5000000 ]; then  # 5GB in KB
        warning "Low disk space available: $(($available_space / 1024 / 1024))GB"
    else
        success "Sufficient disk space available"
    fi
    
    # Check if SSL certificates exist
    if [ -f "/opt/conexao-microservices/letsencrypt/acme.json" ] || [ -f "/opt/conexao-microservices/letsencrypt/conexaodesorte.com.br.crt" ]; then
        success "SSL certificates found"
    else
        warning "SSL certificates not found - HTTPS may not work"
    fi
    
    echo ""
}

# Post-deployment validation
post_deployment_validation() {
    log "Running post-deployment validation..."
    
    echo ""
    log "Service Status Summary:"
    echo "========================"
    
    for service_info in "${DEPLOYMENT_ORDER[@]}"; do
        IFS=':' read -r service_name description port health_path <<< "$service_info"
        
        if docker compose -f "$COMPOSE_FILE" ps "$service_name" | grep -q "Up"; then
            if curl -f -s "http://localhost:$port$health_path" > /dev/null 2>&1; then
                success "$description - Running and Healthy"
            else
                warning "$description - Running but Health Check Failed"
            fi
        else
            error "$description - Not Running"
        fi
    done
    
    echo ""
    log "Checking resource usage..."
    
    # Check memory usage
    memory_usage=$(docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" | grep -E "(auth-microservice|results-microservice|chat-microservice)" | head -5)
    echo "$memory_usage"
    
    # Check port bindings
    log "Port bindings:"
    docker compose -f "$COMPOSE_FILE" ps --format "table {{.Service}}\t{{.Ports}}" | head -10
    
    echo ""
    log "Testing external endpoints..."
    
    # Test main endpoints
    endpoints=(
        "https://www.conexaodesorte.com.br"
        "https://auth.conexaodesorte.com.br/actuator/health"
        "https://results.conexaodesorte.com.br/actuator/health"
        "https://chat.conexaodesorte.com.br/actuator/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f -s -k --max-time 10 "$endpoint" > /dev/null 2>&1; then
            success "External endpoint accessible: $endpoint"
        else
            warning "External endpoint not accessible: $endpoint (may need DNS propagation)"
        fi
    done
}

# Cleanup old resources
cleanup_resources() {
    log "Cleaning up old resources..."
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes (be careful with this)
    # docker volume prune -f
    
    # Remove old backup images older than 7 days
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}" | \
    grep "backup-" | \
    awk '{if ($3 < "'$(date -d '7 days ago' '+%Y-%m-%d')'") print $1":"$2}' | \
    xargs -r docker rmi
    
    success "Cleanup completed"
}

# Main deployment process
main() {
    echo "🚀 Conexão de Sorte - Microservices Deployment"
    echo "==============================================="
    echo "Timestamp: $(date)"
    echo "Target: Production Environment"
    echo "Strategy: Rolling Deployment with Health Checks"
    echo ""
    
    # Pre-deployment checks
    pre_deployment_checks
    
    # Deploy services in priority order
    local failed_services=()
    local successful_services=()
    
    for service_info in "${DEPLOYMENT_ORDER[@]}"; do
        if deploy_service "$service_info"; then
            IFS=':' read -r service_name _ _ _ <<< "$service_info"
            successful_services+=("$service_name")
        else
            IFS=':' read -r service_name _ _ _ <<< "$service_info"
            failed_services+=("$service_name")
            warning "Continuing deployment despite $service_name failure..."
        fi
        
        # Brief pause between services
        sleep 5
    done
    
    echo ""
    echo "=========================================="
    log "Deployment Summary"
    echo "=========================================="
    
    if [ ${#successful_services[@]} -gt 0 ]; then
        success "Successfully deployed services:"
        printf '%s\n' "${successful_services[@]}" | sed 's/^/  ✅ /'
    fi
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        error "Failed to deploy services:"
        printf '%s\n' "${failed_services[@]}" | sed 's/^/  ❌ /'
    fi
    
    echo ""
    
    # Post-deployment validation
    post_deployment_validation
    
    # Cleanup
    cleanup_resources
    
    echo ""
    if [ ${#failed_services[@]} -eq 0 ]; then
        success "🎉 All microservices deployed successfully!"
        echo ""
        echo "🌐 Your services are now available at:"
        echo "  • Frontend:      https://www.conexaodesorte.com.br"
        echo "  • Authentication: https://auth.conexaodesorte.com.br"
        echo "  • Results:       https://results.conexaodesorte.com.br"
        echo "  • Chat:          https://chat.conexaodesorte.com.br"
        echo "  • Notifications: https://notifications.conexaodesorte.com.br"
        echo "  • Audit:         https://audit.conexaodesorte.com.br"
        echo "  • Monitoring:    https://monitoring.conexaodesorte.com.br"
        echo "  • Scheduler:     https://scheduler.conexaodesorte.com.br"
        echo "  • Cryptography:  https://crypto.conexaodesorte.com.br"
        echo "  • Traefik:       https://traefik.conexaodesorte.com.br"
        echo ""
        echo "📊 Monitoring:"
        echo "  • Health checks: /actuator/health on each service"
        echo "  • Metrics:       /actuator/metrics on each service"
        echo "  • Logs:          docker compose logs [service-name]"
        
        exit 0
    else
        error "🚨 Deployment completed with ${#failed_services[@]} failures"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "  • Check logs: docker compose logs [service-name]"
        echo "  • Check health: curl http://localhost:[port]/actuator/health"
        echo "  • Check resources: docker stats"
        echo "  • Retry failed services: ./deploy-microservices.sh"
        
        exit 1
    fi
}

# Handle script interruption
trap 'echo ""; error "Deployment interrupted by user"; exit 1' INT TERM

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    warning "Running as root - consider using a dedicated deployment user"
fi

# Change to project directory
cd "$PROJECT_DIR" || {
    error "Failed to change to project directory: $PROJECT_DIR"
    exit 1
}

# Run main function
main "$@"