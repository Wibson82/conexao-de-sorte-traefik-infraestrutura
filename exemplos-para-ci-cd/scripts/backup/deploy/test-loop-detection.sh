#!/bin/bash

# ============================================================================
# 🧪 TESTE DO SISTEMA DE DETECÇÃO DE LOOPS INFINITOS
# ============================================================================
# Este script testa o sistema de detecção de loops infinitos criando
# cenários controlados para validar se a detecção funciona corretamente.
# ============================================================================

set -euo pipefail

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

# Função para criar container de teste que falha
create_failing_container() {
    local container_name="$1"
    local failure_type="$2"
    
    log "🧪 Criando container de teste: $container_name (tipo: $failure_type)"
    
    # Remover container se existir
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    
    case "$failure_type" in
        "restart_loop")
            # Container que falha e reinicia continuamente
            docker run -d \
              --name "$container_name" \
              --restart unless-stopped \
              --health-cmd='exit 1' \
              --health-interval=5s \
              --health-timeout=3s \
              --health-retries=2 \
              --health-start-period=10s \
              alpine:latest sh -c 'echo "Iniciando..."; sleep 5; echo "Falhando..."; exit 1'
            ;;
        "infinite_logs")
            # Container que gera logs infinitos com padrões de erro
            docker run -d \
              --name "$container_name" \
              --restart unless-stopped \
              alpine:latest sh -c 'while true; do echo "ERROR: OutOfMemoryError occurred"; echo "ERROR: Failed to start application"; sleep 1; done'
            ;;
        "healthy")
            # Container saudável para teste de controle
            docker run -d \
              --name "$container_name" \
              --restart unless-stopped \
              --health-cmd='echo "healthy"' \
              --health-interval=10s \
              --health-timeout=5s \
              --health-retries=3 \
              --health-start-period=15s \
              alpine:latest sh -c 'echo "Aplicação iniciada com sucesso"; while true; do sleep 30; done'
            ;;
        *)
            error "Tipo de falha desconhecido: $failure_type"
            return 1
            ;;
    esac
    
    sleep 2
    log "✅ Container $container_name criado"
}

# Teste 1: Container com restart loop
test_restart_loop_detection() {
    log "🧪 TESTE 1: Detecção de restart loop"
    
    local test_container="test-restart-loop"
    create_failing_container "$test_container" "restart_loop"
    
    # Aguardar alguns restarts
    log "⏳ Aguardando restarts acontecerem..."
    sleep 30
    
    # Testar detecção
    log "🔍 Testando detecção de restart loop..."
    if ./scripts/deploy/detect-infinite-loops.sh "$test_container" 2 60 5 20; then
        error "❌ FALHA: Detecção deveria ter falhado para restart loop!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 1
    else
        success "✅ SUCESSO: Restart loop detectado corretamente!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 0
    fi
}

# Teste 2: Container com logs infinitos
test_infinite_logs_detection() {
    log "🧪 TESTE 2: Detecção de logs infinitos com padrões de erro"
    
    local test_container="test-infinite-logs"
    create_failing_container "$test_container" "infinite_logs"
    
    # Aguardar logs serem gerados
    log "⏳ Aguardando logs serem gerados..."
    sleep 15
    
    # Testar detecção
    log "🔍 Testando detecção de padrões de loop em logs..."
    if ./scripts/deploy/detect-infinite-loops.sh "$test_container" 10 60 5 50; then
        error "❌ FALHA: Detecção deveria ter falhado para logs infinitos!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 1
    else
        success "✅ SUCESSO: Padrões de loop em logs detectados corretamente!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 0
    fi
}

# Teste 3: Container saudável (controle)
test_healthy_container() {
    log "🧪 TESTE 3: Container saudável (teste de controle)"
    
    local test_container="test-healthy"
    create_failing_container "$test_container" "healthy"
    
    # Aguardar inicialização
    log "⏳ Aguardando inicialização..."
    sleep 20
    
    # Testar detecção
    log "🔍 Testando detecção em container saudável..."
    if ./scripts/deploy/detect-infinite-loops.sh "$test_container" 5 120 10 30; then
        success "✅ SUCESSO: Container saudável passou na detecção!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 0
    else
        error "❌ FALHA: Container saudável deveria ter passado na detecção!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 1
    fi
}

# Teste 4: Timeout da detecção
test_detection_timeout() {
    log "🧪 TESTE 4: Timeout da detecção"
    
    local test_container="test-timeout"
    create_failing_container "$test_container" "infinite_logs"
    
    # Testar com timeout muito baixo
    log "🔍 Testando timeout da detecção (5 segundos)..."
    if timeout 10 ./scripts/deploy/detect-infinite-loops.sh "$test_container" 10 5 2 20; then
        error "❌ FALHA: Detecção deveria ter dado timeout!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 1
    else
        success "✅ SUCESSO: Timeout da detecção funcionou corretamente!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        return 0
    fi
}

# Teste 5: Rollback automático
test_auto_rollback() {
    log "🧪 TESTE 5: Rollback automático"
    
    # Criar uma imagem "boa" primeiro
    log "📦 Criando imagem de backup para teste..."
    docker run -d \
      --name backup-container \
      --restart unless-stopped \
      alpine:latest sh -c 'echo "Backup container"; while true; do sleep 30; done'
    
    # Commitar como imagem de backup
    docker commit backup-container facilita/conexao-de-sorte-backend-teste:backup-test
    docker stop backup-container
    docker rm backup-container
    
    # Criar container com problema
    local test_container="test-rollback"
    create_failing_container "$test_container" "restart_loop"
    
    # Aguardar falhas
    sleep 20
    
    # Testar rollback
    log "🔄 Testando rollback automático..."
    if ./scripts/deploy/auto-rollback.sh "$test_container" "teste" "backup-test"; then
        success "✅ SUCESSO: Rollback automático funcionou!"
        
        # Verificar se novo container está rodando
        if docker ps --format '{{.Names}}' | grep -q "^$test_container$"; then
            success "✅ Container foi recriado após rollback"
        else
            warning "⚠️ Container não foi recriado (pode ser esperado)"
        fi
        
        # Limpeza
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        docker rmi facilita/conexao-de-sorte-backend-teste:backup-test 2>/dev/null || true
        return 0
    else
        error "❌ FALHA: Rollback automático falhou!"
        docker stop "$test_container" 2>/dev/null || true
        docker rm "$test_container" 2>/dev/null || true
        docker rmi facilita/conexao-de-sorte-backend-teste:backup-test 2>/dev/null || true
        return 1
    fi
}

# Função principal
main() {
    log "🚀 Iniciando testes do sistema de detecção de loops infinitos..."
    
    # Verificar se scripts existem
    if [[ ! -f "scripts/deploy/detect-infinite-loops.sh" ]]; then
        error "Script detect-infinite-loops.sh não encontrado!"
        exit 1
    fi
    
    if [[ ! -f "scripts/deploy/auto-rollback.sh" ]]; then
        error "Script auto-rollback.sh não encontrado!"
        exit 1
    fi
    
    # Tornar scripts executáveis
    chmod +x scripts/deploy/detect-infinite-loops.sh
    chmod +x scripts/deploy/auto-rollback.sh
    
    local tests_passed=0
    local tests_total=5
    
    # Executar testes
    log "📋 Executando $tests_total testes..."
    
    if test_restart_loop_detection; then
        ((tests_passed++))
    fi
    
    if test_infinite_logs_detection; then
        ((tests_passed++))
    fi
    
    if test_healthy_container; then
        ((tests_passed++))
    fi
    
    if test_detection_timeout; then
        ((tests_passed++))
    fi
    
    if test_auto_rollback; then
        ((tests_passed++))
    fi
    
    # Relatório final
    log "📊 RELATÓRIO FINAL DOS TESTES"
    log "   Testes executados: $tests_total"
    log "   Testes aprovados: $tests_passed"
    log "   Taxa de sucesso: $((tests_passed * 100 / tests_total))%"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        success "🎉 TODOS OS TESTES PASSARAM!"
        success "✅ Sistema de detecção de loops infinitos está funcionando corretamente!"
        exit 0
    else
        error "❌ ALGUNS TESTES FALHARAM!"
        error "   Falhas: $((tests_total - tests_passed))/$tests_total"
        exit 1
    fi
}

# Verificar se script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
