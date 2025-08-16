#!/bin/bash

# 🔍 SCRIPT PARA DEBUG DOS LOGS DE PRODUÇÃO
# Facilita a visualização e análise dos logs do backend em produção

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
CONTAINER_NAME="conexao-backend-green"
LOG_LINES=500

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Função para verificar se container existe
check_container() {
    if ! docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_error "Container ${CONTAINER_NAME} não encontrado!"
        echo "Containers disponíveis:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
        exit 1
    fi
}

# Função para mostrar status do container
show_container_status() {
    log_header "STATUS DO CONTAINER"
    
    local status=$(docker inspect --format='{{.State.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "not_found")
    local started=$(docker inspect --format='{{.State.StartedAt}}' ${CONTAINER_NAME} 2>/dev/null || echo "unknown")
    local image=$(docker inspect --format='{{.Config.Image}}' ${CONTAINER_NAME} 2>/dev/null || echo "unknown")
    
    echo "Container: ${CONTAINER_NAME}"
    echo "Status: ${status}"
    echo "Iniciado em: ${started}"
    echo "Imagem: ${image}"
    
    if [[ "$status" == "running" ]]; then
        log_success "Container está rodando"
    else
        log_warn "Container não está rodando (status: ${status})"
    fi
}

# Função para mostrar variáveis de ambiente
show_environment() {
    log_header "VARIÁVEIS DE AMBIENTE"
    
    log_step "Verificando configurações importantes..."
    
    docker exec ${CONTAINER_NAME} env | grep -E "(SPRING_PROFILES_ACTIVE|ENVIRONMENT|JAVA_OPTS|TZ)" | sort || {
        log_warn "Não foi possível acessar variáveis de ambiente do container"
    }
}

# Função para mostrar logs gerais
show_general_logs() {
    log_header "LOGS GERAIS (Últimas ${LOG_LINES} linhas)"
    
    docker logs --tail ${LOG_LINES} ${CONTAINER_NAME} 2>&1 | tail -50
}

# Função para mostrar logs de schedulers
show_scheduler_logs() {
    log_header "LOGS DE SCHEDULERS"
    
    log_step "Procurando por logs de agendamento..."
    
    # Buscar logs relacionados a schedulers
    docker logs ${CONTAINER_NAME} 2>&1 | grep -i -E "(scheduler|agendamento|🎯|🔍)" | tail -20 || {
        log_warn "Nenhum log de scheduler encontrado"
        log_info "Isso pode indicar que os schedulers não estão executando"
    }
}

# Função para mostrar logs de erro
show_error_logs() {
    log_header "LOGS DE ERRO"
    
    log_step "Procurando por erros..."
    
    # Buscar logs de erro
    docker logs ${CONTAINER_NAME} 2>&1 | grep -i -E "(error|exception|failed|❌)" | tail -20 || {
        log_success "Nenhum erro recente encontrado"
    }
}

# Função para mostrar logs de inicialização
show_startup_logs() {
    log_header "LOGS DE INICIALIZAÇÃO"
    
    log_step "Verificando inicialização da aplicação..."
    
    # Buscar logs de inicialização
    docker logs ${CONTAINER_NAME} 2>&1 | grep -E "(Iniciando aplicação|Started Application|🚀|✅)" | tail -10 || {
        log_warn "Logs de inicialização não encontrados"
    }
}

# Função para mostrar logs de extração
show_extraction_logs() {
    log_header "LOGS DE EXTRAÇÃO DO JOGO DO BICHO"
    
    log_step "Procurando por logs de extração..."
    
    # Buscar logs de extração
    docker logs ${CONTAINER_NAME} 2>&1 | grep -i -E "(extração|resultado|jogo.*bicho|horário.*liberado)" | tail -15 || {
        log_warn "Nenhum log de extração encontrado"
        log_info "Verifique se os schedulers estão habilitados"
    }
}

# Função para monitoramento em tempo real
monitor_logs() {
    log_header "MONITORAMENTO EM TEMPO REAL"
    
    log_info "Pressione Ctrl+C para parar o monitoramento"
    log_info "Filtrando logs importantes..."
    
    # Monitorar logs em tempo real com filtros
    docker logs -f ${CONTAINER_NAME} 2>&1 | grep --line-buffered -E "(🎯|🔍|❌|⚠️|✅|ERROR|WARN|scheduler|agendamento|extração)"
}

# Função para análise completa
full_analysis() {
    log_header "ANÁLISE COMPLETA DOS LOGS"
    
    check_container
    show_container_status
    show_environment
    show_startup_logs
    show_scheduler_logs
    show_extraction_logs
    show_error_logs
    
    log_header "RESUMO DA ANÁLISE"
    
    # Verificar problemas comuns
    local issues=0
    
    # Verificar se está em modo desenvolvimento
    if docker logs ${CONTAINER_NAME} 2>&1 | grep -q "DESENVOLVIMENTO"; then
        log_warn "Aplicação rodando em modo DESENVOLVIMENTO em produção"
        ((issues++))
    fi
    
    # Verificar se schedulers estão ativos
    if ! docker logs ${CONTAINER_NAME} 2>&1 | grep -q "🎯.*SCHEDULER"; then
        log_warn "Nenhum scheduler ativo encontrado nos logs"
        ((issues++))
    fi
    
    # Verificar erros recentes
    if docker logs ${CONTAINER_NAME} 2>&1 | tail -100 | grep -q -i "error\|exception"; then
        log_warn "Erros encontrados nos logs recentes"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "Nenhum problema crítico identificado"
    else
        log_warn "Encontrados ${issues} problemas que precisam de atenção"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "🔍 Script de Debug dos Logs de Produção"
    echo ""
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  status      - Mostrar status do container"
    echo "  env         - Mostrar variáveis de ambiente"
    echo "  general     - Mostrar logs gerais"
    echo "  scheduler   - Mostrar logs de schedulers"
    echo "  extraction  - Mostrar logs de extração"
    echo "  errors      - Mostrar logs de erro"
    echo "  startup     - Mostrar logs de inicialização"
    echo "  monitor     - Monitorar logs em tempo real"
    echo "  full        - Análise completa (padrão)"
    echo "  help        - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                    # Análise completa"
    echo "  $0 scheduler          # Apenas logs de schedulers"
    echo "  $0 monitor            # Monitoramento em tempo real"
}

# Função principal
main() {
    local command=${1:-full}
    
    case $command in
        status)
            check_container
            show_container_status
            ;;
        env)
            check_container
            show_environment
            ;;
        general)
            check_container
            show_general_logs
            ;;
        scheduler)
            check_container
            show_scheduler_logs
            ;;
        extraction)
            check_container
            show_extraction_logs
            ;;
        errors)
            check_container
            show_error_logs
            ;;
        startup)
            check_container
            show_startup_logs
            ;;
        monitor)
            check_container
            monitor_logs
            ;;
        full)
            full_analysis
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Opção inválida: $command"
            show_help
            exit 1
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
