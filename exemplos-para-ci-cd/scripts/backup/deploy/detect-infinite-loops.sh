#!/bin/bash

# ============================================================================
# 🔍 DETECTOR DE LOOPS INFINITOS - DEPLOY WORKFLOW
# ============================================================================
# Este script detecta loops infinitos durante o deploy e inicialização
# da aplicação, evitando que o workflow reporte sucesso incorretamente.
# ============================================================================

set -euo pipefail

# Configurações
CONTAINER_NAME="${1:-backend-prod}"
MAX_RESTART_COUNT="${2:-5}"
MAX_WAIT_TIME="${3:-600}"  # 10 minutos
HEALTH_CHECK_INTERVAL="${4:-10}"
LOG_ANALYSIS_LINES="${5:-100}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Função para detectar loops de restart
detect_restart_loop() {
    local container_name="$1"
    local max_restarts="$2"
    
    log "🔍 Verificando loops de restart para container: $container_name"
    
    if ! docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name"; then
        error "Container $container_name não encontrado!"
        return 1
    fi
    
    # Obter contagem de restarts
    local restart_count
    restart_count=$(docker inspect "$container_name" --format='{{.RestartCount}}' 2>/dev/null || echo "0")
    
    log "📊 Contagem atual de restarts: $restart_count"
    
    if [[ "$restart_count" -gt "$max_restarts" ]]; then
        error "🚨 LOOP INFINITO DETECTADO!"
        error "   Container: $container_name"
        error "   Restarts: $restart_count (máximo permitido: $max_restarts)"
        error "   Status: $(docker ps -a --format '{{.Status}}' --filter name="$container_name")"
        return 1
    fi
    
    return 0
}

# Função para analisar logs em busca de padrões de loop
analyze_logs_for_loops() {
    local container_name="$1"
    local lines="$2"
    
    log "📋 Analisando logs para detectar padrões de loop..."
    
    if ! docker logs "$container_name" --tail "$lines" 2>/dev/null | head -1 >/dev/null; then
        warning "Não foi possível obter logs do container $container_name"
        return 0
    fi
    
    local logs
    logs=$(docker logs "$container_name" --tail "$lines" 2>&1)
    
    # Padrões que indicam loops infinitos
    local error_patterns=(
        "OutOfMemoryError"
        "StackOverflowError"
        "Failed to start"
        "Application run failed"
        "BeanCreationException"
        "CircularDependencyException"
        "Infinite recursion"
        "Maximum call stack size exceeded"
        "Too many open files"
        "Connection refused"
        "Port already in use"
    )
    
    local loop_indicators=0
    
    for pattern in "${error_patterns[@]}"; do
        local count
        count=$(echo "$logs" | grep -c "$pattern" || echo "0")
        if [[ "$count" -gt 3 ]]; then
            warning "🔄 Padrão de loop detectado: '$pattern' aparece $count vezes"
            ((loop_indicators++))
        fi
    done
    
    # Verificar se há muitas repetições da mesma mensagem
    local repeated_lines
    repeated_lines=$(echo "$logs" | sort | uniq -c | sort -nr | head -5)
    
    while IFS= read -r line; do
        local count
        count=$(echo "$line" | awk '{print $1}')
        if [[ "$count" -gt 10 ]]; then
            local message
            message=$(echo "$line" | cut -d' ' -f2-)
            warning "🔄 Mensagem repetitiva detectada ($count vezes): $message"
            ((loop_indicators++))
        fi
    done <<< "$repeated_lines"
    
    if [[ "$loop_indicators" -gt 2 ]]; then
        error "🚨 MÚLTIPLOS INDICADORES DE LOOP DETECTADOS!"
        error "   Indicadores encontrados: $loop_indicators"
        return 1
    fi
    
    return 0
}

# Função para verificar saúde da aplicação com timeout
check_application_health() {
    local container_name="$1"
    local max_wait="$2"
    local check_interval="$3"
    
    log "🏥 Verificando saúde da aplicação..."
    
    local start_time
    start_time=$(date +%s)
    local consecutive_failures=0
    local max_consecutive_failures=5
    
    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [[ "$elapsed" -gt "$max_wait" ]]; then
            error "⏰ TIMEOUT: Aplicação não ficou saudável em $max_wait segundos"
            return 1
        fi
        
        # Verificar se container ainda está rodando
        if ! docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
            error "💀 Container $container_name parou de rodar!"
            return 1
        fi
        
        # Verificar health check do Docker
        local health_status
        health_status=$(docker inspect "$container_name" --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
        
        case "$health_status" in
            "healthy")
                success "✅ Aplicação está saudável!"
                return 0
                ;;
            "unhealthy")
                ((consecutive_failures++))
                warning "❌ Health check falhou ($consecutive_failures/$max_consecutive_failures)"
                
                if [[ "$consecutive_failures" -ge "$max_consecutive_failures" ]]; then
                    error "🚨 MUITAS FALHAS CONSECUTIVAS DE HEALTH CHECK!"
                    return 1
                fi
                ;;
            "starting")
                log "🔄 Aplicação ainda inicializando... (${elapsed}s/${max_wait}s)"
                consecutive_failures=0
                ;;
            "none")
                log "ℹ️ Health check não configurado, verificando status do container..."
                local container_status
                container_status=$(docker ps --format '{{.Status}}' --filter name="$container_name")
                if echo "$container_status" | grep -q "Up"; then
                    log "✅ Container está rodando"
                else
                    warning "⚠️ Container com status: $container_status"
                fi
                ;;
        esac
        
        sleep "$check_interval"
    done
}

# Função principal
main() {
    log "🚀 Iniciando detecção de loops infinitos..."
    log "   Container: $CONTAINER_NAME"
    log "   Max restarts: $MAX_RESTART_COUNT"
    log "   Max wait time: $MAX_WAIT_TIME segundos"
    log "   Health check interval: $HEALTH_CHECK_INTERVAL segundos"
    
    # Aguardar container aparecer (máximo 60 segundos)
    local wait_count=0
    while ! docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; do
        if [[ "$wait_count" -gt 12 ]]; then
            error "Container $CONTAINER_NAME não foi criado em 60 segundos"
            exit 1
        fi
        log "⏳ Aguardando container $CONTAINER_NAME ser criado..."
        sleep 5
        ((wait_count++))
    done
    
    # Aguardar um pouco para o container começar a rodar
    sleep 10
    
    # Verificar loops de restart
    if ! detect_restart_loop "$CONTAINER_NAME" "$MAX_RESTART_COUNT"; then
        exit 1
    fi
    
    # Analisar logs para padrões de loop
    if ! analyze_logs_for_loops "$CONTAINER_NAME" "$LOG_ANALYSIS_LINES"; then
        exit 1
    fi
    
    # Verificar saúde da aplicação
    if ! check_application_health "$CONTAINER_NAME" "$MAX_WAIT_TIME" "$HEALTH_CHECK_INTERVAL"; then
        exit 1
    fi
    
    success "🎉 Nenhum loop infinito detectado! Aplicação está funcionando corretamente."
    return 0
}

# Verificar se script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
