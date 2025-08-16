#!/bin/bash
# =============================================================================
# SCRIPT DE GERENCIAMENTO DO AMBIENTE DE TESTE
# =============================================================================
# Este script facilita o gerenciamento do ambiente de teste com comandos
# simples para build, start, stop, logs e cleanup

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.test.yml"
ENV_FILE="$PROJECT_ROOT/.env.test"
LOG_FILE="$PROJECT_ROOT/logs/test-environment.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNÇÕES DE LOG =====
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

# ===== FUNÇÕES DE VERIFICAÇÃO =====
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "Docker Compose não encontrado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    # Verificar arquivos necessários
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        log_error "Arquivo docker-compose.test.yml não encontrado: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning "Arquivo .env.test não encontrado. Usando valores padrão."
    fi
    
    log_success "Pré-requisitos verificados"
}

# ===== FUNÇÕES PRINCIPAIS =====
build_images() {
    log_info "Construindo imagens do ambiente de teste..."
    
    cd "$PROJECT_ROOT"
    
    # Gerar tag baseada na data brasileira
    local brazil_date
    brazil_date=$(TZ='America/Sao_Paulo' date +'%d-%m-%Y-%H-%M')
    
    # Exportar variável para o docker-compose
    export BACKEND_TEST_TAG="$brazil_date"
    
    # Build da imagem
    if docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" build --no-cache; then
        log_success "Imagens construídas com sucesso"
        log_info "Tag da imagem de teste: $BACKEND_TEST_TAG"
    else
        log_error "Falha ao construir imagens"
        exit 1
    fi
}

start_environment() {
    log_info "Iniciando ambiente de teste..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar se já está rodando
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
        log_warning "Ambiente de teste já está rodando"
        show_status
        return 0
    fi
    
    # Iniciar serviços
    if docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" up -d; then
        log_success "Ambiente de teste iniciado"
        
        # Aguardar serviços ficarem saudáveis
        log_info "Aguardando serviços ficarem saudáveis..."
        sleep 30
        
        # Verificar status
        show_status
        show_urls
    else
        log_error "Falha ao iniciar ambiente de teste"
        exit 1
    fi
}

stop_environment() {
    log_info "Parando ambiente de teste..."
    
    cd "$PROJECT_ROOT"
    
    if docker-compose -f "$DOCKER_COMPOSE_FILE" down; then
        log_success "Ambiente de teste parado"
    else
        log_error "Falha ao parar ambiente de teste"
        exit 1
    fi
}

restart_environment() {
    log_info "Reiniciando ambiente de teste..."
    stop_environment
    sleep 5
    start_environment
}

show_status() {
    log_info "Status do ambiente de teste:"
    
    cd "$PROJECT_ROOT"
    
    echo ""
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
    echo ""
    
    # Verificar health checks
    local containers=("backend-teste")
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            local status
            status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            
            case $status in
                "healthy")
                    log_success "$container: Saudável"
                    ;;
                "unhealthy")
                    log_error "$container: Não saudável"
                    ;;
                "starting")
                    log_warning "$container: Iniciando..."
                    ;;
                "no-healthcheck")
                    log_info "$container: Sem health check"
                    ;;
                *)
                    log_warning "$container: Status desconhecido ($status)"
                    ;;
            esac
        else
            log_error "$container: Não está rodando"
        fi
    done
}

show_urls() {
    log_info "URLs do ambiente de teste:"
    echo ""
    echo -e "${GREEN}Backend (API):${NC}     http://localhost:8081 (conectado à infraestrutura de produção)"
    echo -e "${GREEN}Health Check:${NC}     http://localhost:8081/actuator/health"
    echo -e "${GREEN}Swagger UI:${NC}       http://localhost:8081/swagger-ui.html"
    echo -e "${GREEN}Actuator:${NC}         http://localhost:8081/actuator"
    echo -e "${YELLOW}⚠️  ATENÇÃO:${NC}       Backend de teste usando dados de PRODUÇÃO"
    echo ""
}

show_logs() {
    local service="${1:-backend-teste}"
    
    log_info "Mostrando logs do serviço: $service"
    
    cd "$PROJECT_ROOT"
    
    if [[ "$service" == "all" ]]; then
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f
    else
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f "$service"
    fi
}

cleanup_environment() {
    log_info "Limpando ambiente de teste..."
    
    cd "$PROJECT_ROOT"
    
    # Parar e remover containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" down -v --remove-orphans
    
    # Remover imagens de teste
    log_info "Removendo imagens de teste..."
    docker images | grep "facilita/conexao-de-sorte-backend-teste" | awk '{print $3}' | xargs -r docker rmi -f
    
    # Remover volumes de teste
    log_info "Removendo volumes de teste..."
    docker volume ls | grep "conexao.*test" | awk '{print $2}' | xargs -r docker volume rm
    
    # Remover rede de teste
    log_info "Removendo rede de teste..."
    docker network ls | grep "conexao-test-network" | awk '{print $2}' | xargs -r docker network rm
    
    log_success "Limpeza concluída"
}

run_tests() {
    log_info "Executando testes no ambiente de teste..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar se o ambiente está rodando
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
        log_error "Ambiente de teste não está rodando. Execute 'start' primeiro."
        exit 1
    fi
    
    # Executar testes dentro do container
    log_info "Executando testes unitários..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec backend-teste bash -c "cd /app && java -jar app.jar --spring.profiles.active=test --spring.main.web-application-type=none --spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.web.servlet.WebMvcAutoConfiguration"
}

# ===== FUNÇÃO DE AJUDA =====
show_help() {
    echo "Uso: $0 [COMANDO] [OPÇÕES]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  build       - Construir imagens do ambiente de teste"
    echo "  start       - Iniciar ambiente de teste"
    echo "  stop        - Parar ambiente de teste"
    echo "  restart     - Reiniciar ambiente de teste"
    echo "  status      - Mostrar status dos serviços"
    echo "  logs [SVC]  - Mostrar logs (padrão: backend-teste, use 'all' para todos)"
    echo "  urls        - Mostrar URLs de acesso"
    echo "  test        - Executar testes no ambiente"
    echo "  cleanup     - Limpar completamente o ambiente de teste"
    echo "  help        - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 build                    # Construir imagens"
    echo "  $0 start                    # Iniciar ambiente"
    echo "  $0 logs backend-teste       # Ver logs do backend"
    echo "  $0 logs all                 # Ver logs de todos os serviços"
    echo "  $0 cleanup                  # Limpar tudo"
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    # Criar diretório de logs
    mkdir -p "$(dirname "$LOG_FILE")"
    
    local command="${1:-help}"
    
    case "$command" in
        "build")
            check_prerequisites
            build_images
            ;;
        "start")
            check_prerequisites
            start_environment
            ;;
        "stop")
            stop_environment
            ;;
        "restart")
            check_prerequisites
            restart_environment
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "${2:-backend-teste}"
            ;;
        "urls")
            show_urls
            ;;
        "test")
            run_tests
            ;;
        "cleanup")
            cleanup_environment
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Comando desconhecido: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi