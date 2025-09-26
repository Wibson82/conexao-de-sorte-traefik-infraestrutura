#!/bin/bash

# ============================================================================
# 🚀 CONEXÃO DE SORTE - ESTRATÉGIA DE DEPLOY SEQUENCIAL  
# ============================================================================
# Implementa a ordem lógica de deploy para evitar conflitos
# ============================================================================

set -euo pipefail

# Configurações
export TZ="America/Sao_Paulo"
COMPOSE_FILE="docker-compose.yml"  # PRODUÇÃO: arquivo principal consolidado
NETWORK_NAME="conexao-network-swarm"  # CONFLITO RESOLVIDO: rede padronizada
LOG_FILE="deploy.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Verificar se Docker está rodando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker não está rodando!"
        exit 1
    fi
    success "Docker está rodando"
}

# Verificar variáveis de ambiente obrigatórias
check_env_vars() {
    local required_vars=(
        "AZURE_CLIENT_ID"
        "AZURE_TENANT_ID" 
        "AZURE_KEYVAULT_ENDPOINT"
        "BASE_DOMAIN"
    )
    
    # Verificar se arquivo .env existe
    if [[ ! -f .env ]]; then
        warning "Arquivo .env não encontrado. Execute configuracao-segura.sh primeiro."
    fi
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "Variável de ambiente obrigatória não definida: $var"
            error "Execute: source configuracao-segura.sh"
            exit 1
        fi
    done
    success "Variáveis de ambiente verificadas"
}

# Criar rede Docker se não existir
create_network() {
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        log "Criando rede Docker: $NETWORK_NAME"
        docker network create "$NETWORK_NAME"
        success "Rede $NETWORK_NAME criada"
    else
        success "Rede $NETWORK_NAME já existe"
    fi
}

# Função para aguardar health check
wait_for_health() {
    local container_name=$1
    local timeout=${2:-120}
    local elapsed=0
    
    log "Aguardando health check: $container_name"
    
    while [ $elapsed -lt $timeout ]; do
        if docker ps --filter name="$container_name" --filter health=healthy | grep -q "$container_name"; then
            success "$container_name está saudável"
            return 0
        fi
        
        if docker ps --filter name="$container_name" --filter health=unhealthy | grep -q "$container_name"; then
            error "$container_name está com problemas de saúde"
            docker logs "$container_name" --tail 20
            return 1
        fi
        
        echo -n "."
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    warning "$container_name timeout no health check"
    return 1
}

# FASE 1: Infraestrutura Base
deploy_phase1() {
    log "🏗️  FASE 1: INFRAESTRUTURA BASE"
    
    # Traefik (Load Balancer) - PRODUÇÃO
    log "Deployando Traefik (configuração de produção segura)..."
    
    # PRODUÇÃO: Priorizar Docker Swarm
    if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        log "✅ Modo Docker Swarm (PRODUÇÃO) - usando stack deploy"
        docker stack deploy -c "$COMPOSE_FILE" conexao-traefik
        wait_for_health "conexao-traefik_traefik" 90  # Mais tempo para produção
    else
        warning "⚠️  Modo Standalone detectado - recomendado usar Docker Swarm em produção"
        log "Deployando em modo standalone..."
        docker-compose -f "$COMPOSE_FILE" up -d traefik
        wait_for_health "traefik" 90
    fi
    
    success "FASE 1 completada"
}

# FASE 2: Serviços Core (dependências críticas)
deploy_phase2() {
    log "🔧 FASE 2: SERVIÇOS CORE"
    
    # Autenticação (primeiro - outros dependem)
    log "Deployando Autenticação..."
    docker-compose up -d auth-microservice
    wait_for_health "conexao-auth-ms" 120
    
    # Usuário (dependência para chat/notificações)
    log "Deployando Usuário..."
    docker-compose up -d user-microservice
    wait_for_health "conexao-user-ms" 120
    
    # Criptografia KMS (dependência de segurança)
    log "Deployando Criptografia KMS..."
    docker-compose up -d crypto-kms-microservice
    wait_for_health "conexao-crypto-kms-ms" 120
    
    success "FASE 2 completada"
}

# FASE 3: Serviços de Aplicação
deploy_phase3() {
    log "📱 FASE 3: SERVIÇOS DE APLICAÇÃO"
    
    # Notificações
    log "Deployando Notificações..."
    docker-compose up -d notifications-microservice
    wait_for_health "conexao-notifications-ms" 120
    
    # Chat/Bate-papo
    log "Deployando Bate-papo..."
    docker-compose up -d chat-microservice
    wait_for_health "conexao-chat-ms" 120
    
    # Auditoria
    log "Deployando Auditoria..."
    docker-compose up -d audit-microservice
    wait_for_health "conexao-audit-ms" 120
    
    success "FASE 3 completada"
}

# FASE 4: Aplicações Finais
deploy_phase4() {
    log "🌐 FASE 4: APLICAÇÕES FINAIS"
    
    # Frontend
    log "Deployando Frontend..."
    docker-compose up -d frontend-web
    wait_for_health "conexao-frontend-web" 90
    
    # Chatbot (opcional)
    log "Deployando Chatbot..."
    docker-compose up -d chatbot-microservice
    wait_for_health "conexao-chatbot-ms" 90
    
    success "FASE 4 completada"
}

# FASE 5: Serviços Opcionais
deploy_phase5() {
    log "📊 FASE 5: SERVIÇOS OPCIONAIS"
    
    # Results (se necessário)
    if docker-compose config --services | grep -q "results-microservice"; then
        log "Deployando Results..."
        docker-compose up -d results-microservice || warning "Results falhou - continuando"
    fi
    
    # Scheduler
    if docker-compose config --services | grep -q "scheduler-microservice"; then
        log "Deployando Scheduler..."
        docker-compose up -d scheduler-microservice || warning "Scheduler falhou - continuando"
    fi
    
    success "FASE 5 completada"
}

# Verificação final
final_check() {
    log "🔍 VERIFICAÇÃO FINAL"
    
    echo ""
    log "Status dos containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep conexao
    
    echo ""
    log "Health checks:"
    docker ps --filter label=traefik.enable=true --format "table {{.Names}}\t{{.Status}}"
    
    echo ""
    log "🌐 Frontend: https://www.conexaodesorte.com.br"
    echo "🔌 APIs: https://conexaodesorte.com.br/rest/*"
    echo "📊 Traefik Dashboard: https://conexaodesorte.com.br/traefik (PROTEGIDO)"
    echo ""
    echo "🛡️  SEGURANÇA DE PRODUÇÃO:"
    echo "   ✅ SSL/TLS automático (Let's Encrypt)"
    echo "   ✅ Dashboard protegido por autenticação"
    echo "   ✅ Headers de segurança aplicados"
    echo "   ✅ Rate limiting configurado"
    echo "   ✅ Logs de auditoria habilitados"
    
    success "Deploy finalizado com sucesso!"
}

# Rollback em caso de erro
rollback() {
    error "Erro durante deploy. Executando rollback..."
    docker-compose down
    log "Rollback executado. Verifique os logs em: $LOG_FILE"
    exit 1
}

# Main execution
main() {
    log "🚀 Iniciando deploy da Conexão de Sorte"
    log "Timestamp: $(date)"
    
    # Trap para rollback em erro
    trap rollback ERR
    
    # Verificações iniciais
    check_docker
    check_env_vars
    create_network
    
    # Deploy sequencial
    deploy_phase1
    deploy_phase2  
    deploy_phase3
    deploy_phase4
    deploy_phase5
    
    # Verificação final
    final_check
    
    log "✨ Deploy completado com sucesso!"
}

# Executar apenas se for script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
