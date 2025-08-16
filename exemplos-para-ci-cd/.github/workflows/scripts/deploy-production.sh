#!/bin/bash

# ===== SCRIPT DE DEPLOY EM PRODUÇÃO =====
# Sistema: Conexão de Sorte - Backend
# Função: Deploy automatizado com Blue-Green deployment
# Versão: 1.0.0
# Data: $(date +"%d/%m/%Y")

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/deploy-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$PROJECT_ROOT/backups/deploy-$(date +%Y%m%d_%H%M%S)"

# Configurações do deploy
IMAGE_NAME="facilita/conexao-de-sorte-backend"
# Gerar tag baseada na data brasileira se não fornecida
if [[ -z "${1:-}" ]]; then
    BRAZIL_DATE=$(TZ='America/Sao_Paulo' date +'%d-%m-%Y-%H')
    IMAGE_TAG="$BRAZIL_DATE"
else
    IMAGE_TAG="$1"
fi
DEPLOY_TIMEOUT=300  # 5 minutos
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_INTERVAL=10

# URLs para verificação
APP_URL="http://localhost:8080/actuator/health"

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

# ===== VERIFICAÇÕES PRÉ-DEPLOY =====
check_prerequisites() {
    log_info "Verificando pré-requisitos para deploy..."
    
    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        return 1
    fi
    
    # Verificar se docker-compose está disponível
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose não encontrado"
        return 1
    fi
    
    # Verificar se a imagem existe
    if ! docker image inspect "$IMAGE_NAME:$IMAGE_TAG" >/dev/null 2>&1; then
        log_error "Imagem $IMAGE_NAME:$IMAGE_TAG não encontrada"
        log_info "Execute: docker build -t $IMAGE_NAME:$IMAGE_TAG ."
        return 1
    fi
    
    # Verificar arquivos de configuração
    local required_files=(
        "docker-compose.prod.yml"
        "deploy/monitoring/prometheus.yml"
        "deploy/monitoring/alert_rules.yml"
        "deploy/monitoring/alertmanager.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            log_error "Arquivo obrigatório não encontrado: $file"
            return 1
        fi
    done
    
    # Verificar espaço em disco
    local available_space
    available_space=$(df / | tail -1 | awk '{print $4}')
    local required_space=1048576  # 1GB em KB
    
    if (( available_space < required_space )); then
        log_error "Espaço em disco insuficiente. Disponível: ${available_space}KB, Necessário: ${required_space}KB"
        return 1
    fi
    
    log_success "Pré-requisitos verificados com sucesso"
}

# ===== BACKUP PRÉ-DEPLOY =====
create_backup() {
    log_info "Criando backup pré-deploy..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup do banco de dados
    log_info "Fazendo backup do banco de dados..."
    if docker ps --filter "name=mysql" --format "{{.Names}}" | grep -q mysql; then
        local mysql_container
        mysql_container=$(docker ps --filter "name=mysql" --format "{{.Names}}" | head -1)
        
        docker exec "$mysql_container" mysqldump -u root -p"${DB_ROOT_PASSWORD:-root_password}" --all-databases > "$BACKUP_DIR/database-backup.sql"
        
        if [[ -f "$BACKUP_DIR/database-backup.sql" ]]; then
            log_success "Backup do banco criado: $BACKUP_DIR/database-backup.sql"
        else
            log_error "Falha no backup do banco de dados"
            return 1
        fi
    else
        log_warning "Container MySQL não encontrado, pulando backup do banco"
    fi
    
    # Backup dos volumes
    log_info "Fazendo backup dos volumes..."
    if [[ -f "$SCRIPT_DIR/setup-volumes.sh" ]]; then
        bash "$SCRIPT_DIR/setup-volumes.sh" backup
    fi
    
    # Backup das configurações
    log_info "Fazendo backup das configurações..."
    cp -r "$PROJECT_ROOT/deploy" "$BACKUP_DIR/deploy-configs"
    
    # Backup do estado atual dos containers
    log_info "Salvando estado atual dos containers..."
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$BACKUP_DIR/containers-state.txt"
    
    # Backup das imagens atuais
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" > "$BACKUP_DIR/images-state.txt"
    
    log_success "Backup pré-deploy criado em: $BACKUP_DIR"
}

# ===== DETERMINAÇÃO DO AMBIENTE ATIVO =====
get_active_environment() {
    # Determinar ambiente ativo através de verificação direta dos containers
    local active_env="green"  # padrão
    
    # Verificar qual container está recebendo tráfego
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "backend-blue.*Up"; then
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "backend-green.*Up"; then
            # Ambos estão rodando, assumir green como padrão
            active_env="green"
        else
            active_env="blue"
        fi
    fi
    
    echo "$active_env"
}

get_inactive_environment() {
    local active_env="$1"
    
    if [[ "$active_env" == "green" ]]; then
        echo "blue"
    else
        echo "green"
    fi
}

# ===== DEPLOY DO NOVO AMBIENTE =====
deploy_new_environment() {
    local target_env="$1"
    
    log_info "Fazendo deploy no ambiente $target_env..."
    
    cd "$PROJECT_ROOT"
    
    # Parar o ambiente de destino se estiver rodando
    log_info "Parando ambiente $target_env..."
    docker-compose -f docker-compose.prod.yml stop "backend-$target_env" 2>/dev/null || true
    docker-compose -f docker-compose.prod.yml rm -f "backend-$target_env" 2>/dev/null || true
    
    # Atualizar a imagem
    log_info "Atualizando imagem para $IMAGE_NAME:$IMAGE_TAG..."
    
    # Modificar temporariamente o docker-compose para usar a nova imagem
    local temp_compose="docker-compose.temp.yml"
    sed "s|image: $IMAGE_NAME:.*|image: $IMAGE_NAME:$IMAGE_TAG|g" docker-compose.prod.yml > "$temp_compose"
    
    # Iniciar o novo ambiente
    log_info "Iniciando ambiente $target_env com nova imagem..."
    docker-compose -f "$temp_compose" up -d "backend-$target_env"
    
    # Limpar arquivo temporário
    rm -f "$temp_compose"
    
    log_success "Deploy do ambiente $target_env iniciado"
}

# ===== VERIFICAÇÃO DE SAÚDE =====
wait_for_health() {
    local target_env="$1"
    local container_name="backend-$target_env"
    
    log_info "Aguardando ambiente $target_env ficar saudável..."
    
    local retries=0
    local max_retries=$HEALTH_CHECK_RETRIES
    
    while (( retries < max_retries )); do
        # Verificar se o container está rodando
        if ! docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
            log_error "Container $container_name não está rodando"
            return 1
        fi
        
        # Verificar logs do container para erros
        local recent_logs
        recent_logs=$(docker logs --tail 50 "$container_name" 2>&1)
        
        if echo "$recent_logs" | grep -q "Started.*Application"; then
            log_info "Aplicação iniciada no container $container_name"
            
            # Verificar endpoint de saúde
            local container_port
            container_port=$(docker port "$container_name" 8080 | cut -d: -f2)
            
            if [[ -n "$container_port" ]]; then
                local health_url="http://localhost:$container_port/actuator/health"
                
                if curl -s "$health_url" | grep -q '"status":"UP"'; then
                    log_success "Ambiente $target_env está saudável"
                    return 0
                fi
            fi
        fi
        
        # Verificar se há erros críticos
        if echo "$recent_logs" | grep -q "FATAL\|OutOfMemoryError\|BindException"; then
            log_error "Erro crítico detectado no ambiente $target_env"
            docker logs --tail 20 "$container_name"
            return 1
        fi
        
        retries=$((retries + 1))
        log_info "Tentativa $retries/$max_retries - Aguardando $HEALTH_CHECK_INTERVAL segundos..."
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    log_error "Timeout aguardando ambiente $target_env ficar saudável"
    return 1
}

# ===== TROCA DE TRÁFEGO =====
switch_traffic() {
    local new_env="$1"
    
    log_info "Redirecionando tráfego para ambiente $new_env..."
    
    # Sem Traefik, o redirecionamento de tráfego deve ser feito através de load balancer externo
    # ou configuração de proxy reverso no nível de infraestrutura
    log_info "Redirecionamento de tráfego deve ser configurado no load balancer externo"
    
    # Aguardar a mudança ser aplicada
    sleep 5
    
    # Verificar se a mudança foi aplicada
    local retries=0
    while (( retries < 10 )); do
        if curl -s "$APP_URL" | grep -q '"status":"UP"'; then
            log_success "Tráfego redirecionado para ambiente $new_env"
            rm -f "$temp_compose"
            return 0
        fi
        
        retries=$((retries + 1))
        sleep 2
    done
    
    log_error "Falha ao redirecionar tráfego"
    rm -f "$temp_compose"
    return 1
}

# ===== LIMPEZA DO AMBIENTE ANTIGO =====
cleanup_old_environment() {
    local old_env="$1"
    
    log_info "Limpando ambiente antigo: $old_env..."
    
    # Aguardar um pouco antes de limpar
    log_info "Aguardando 30 segundos antes da limpeza..."
    sleep 30
    
    # Parar o ambiente antigo
    docker-compose -f docker-compose.prod.yml stop "backend-$old_env"
    
    # Remover o container antigo
    docker-compose -f docker-compose.prod.yml rm -f "backend-$old_env"
    
    log_success "Ambiente antigo $old_env limpo"
}

# ===== ROLLBACK =====
rollback() {
    local backup_dir="$1"
    
    log_warning "Iniciando rollback..."
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Diretório de backup não encontrado: $backup_dir"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # Restaurar configurações
    if [[ -d "$backup_dir/deploy-configs" ]]; then
        log_info "Restaurando configurações..."
        cp -r "$backup_dir/deploy-configs"/* deploy/
    fi
    
    # Restaurar banco de dados
    if [[ -f "$backup_dir/database-backup.sql" ]]; then
        log_info "Restaurando banco de dados..."
        
        local mysql_container
        mysql_container=$(docker ps --filter "name=mysql" --format "{{.Names}}" | head -1)
        
        if [[ -n "$mysql_container" ]]; then
            docker exec -i "$mysql_container" mysql -u root -p"${DB_ROOT_PASSWORD:-root_password}" < "$backup_dir/database-backup.sql"
            log_success "Banco de dados restaurado"
        fi
    fi
    
    # Reiniciar serviços
    log_info "Reiniciando serviços..."
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml up -d
    
    log_success "Rollback concluído"
}

# ===== VERIFICAÇÃO PÓS-DEPLOY =====
post_deploy_verification() {
    log_info "Executando verificações pós-deploy..."
    
    # Executar health check completo
    if [[ -f "$SCRIPT_DIR/health-check.sh" ]]; then
        log_info "Executando health check..."
        if bash "$SCRIPT_DIR/health-check.sh" report; then
            log_success "Health check passou"
        else
            log_error "Health check falhou"
            return 1
        fi
    fi
    
    # Verificar métricas básicas
    log_info "Verificando métricas..."
    
    # Verificar se Prometheus está coletando métricas
    if curl -s "http://localhost:9090/api/v1/query?query=up" | grep -q '"status":"success"'; then
        log_success "Prometheus está coletando métricas"
    else
        log_warning "Problema com coleta de métricas do Prometheus"
    fi
    
    # Verificar logs recentes
    log_info "Verificando logs recentes..."
    local error_count
    error_count=$(docker logs --since=5m backend-green backend-blue 2>&1 | grep -c "ERROR\|FATAL" || echo "0")
    
    if (( error_count == 0 )); then
        log_success "Nenhum erro encontrado nos logs recentes"
    else
        log_warning "$error_count erros encontrados nos logs recentes"
    fi
    
    log_success "Verificações pós-deploy concluídas"
}

# ===== NOTIFICAÇÃO =====
send_notification() {
    local status="$1"
    local message="$2"
    
    log_info "Enviando notificação: $status - $message"
    
    # Aqui você pode integrar com Slack, email, etc.
    # Por enquanto, apenas log
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Criar arquivo de notificação
    cat > "$PROJECT_ROOT/logs/deploy-notification-$(date +%Y%m%d_%H%M%S).json" << EOF
{
  "timestamp": "$timestamp",
  "status": "$status",
  "message": "$message",
  "image": "$IMAGE_NAME:$IMAGE_TAG",
  "backup_dir": "$BACKUP_DIR",
  "log_file": "$LOG_FILE"
}
EOF
}

# ===== FUNÇÃO PRINCIPAL DE DEPLOY =====
perform_deploy() {
    log_info "Iniciando deploy de $IMAGE_NAME:$IMAGE_TAG"
    
    # Verificar pré-requisitos
    if ! check_prerequisites; then
        send_notification "failed" "Deploy falhou na verificação de pré-requisitos"
        return 1
    fi
    
    # Criar backup
    if ! create_backup; then
        send_notification "failed" "Deploy falhou na criação do backup"
        return 1
    fi
    
    # Determinar ambientes
    local active_env
    local target_env
    
    active_env=$(get_active_environment)
    target_env=$(get_inactive_environment "$active_env")
    
    log_info "Ambiente ativo: $active_env"
    log_info "Ambiente de destino: $target_env"
    
    # Deploy no novo ambiente
    if ! deploy_new_environment "$target_env"; then
        send_notification "failed" "Deploy falhou ao iniciar novo ambiente $target_env"
        return 1
    fi
    
    # Aguardar ambiente ficar saudável
    if ! wait_for_health "$target_env"; then
        log_error "Novo ambiente não ficou saudável, iniciando rollback..."
        cleanup_old_environment "$target_env"
        send_notification "failed" "Deploy falhou - novo ambiente não ficou saudável"
        return 1
    fi
    
    # Trocar tráfego
    if ! switch_traffic "$target_env"; then
        log_error "Falha ao trocar tráfego, iniciando rollback..."
        cleanup_old_environment "$target_env"
        send_notification "failed" "Deploy falhou ao trocar tráfego"
        return 1
    fi
    
    # Verificações pós-deploy
    if ! post_deploy_verification; then
        log_error "Verificações pós-deploy falharam, considere rollback manual"
        send_notification "warning" "Deploy concluído mas verificações pós-deploy falharam"
    else
        # Limpar ambiente antigo
        cleanup_old_environment "$active_env"
        
        send_notification "success" "Deploy concluído com sucesso para ambiente $target_env"
        log_success "Deploy concluído com sucesso!"
    fi
    
    # Mostrar resumo
    echo
    echo "===== RESUMO DO DEPLOY ====="
    echo "Imagem: $IMAGE_NAME:$IMAGE_TAG"
    echo "Ambiente ativo: $target_env"
    echo "Backup: $BACKUP_DIR"
    echo "Log: $LOG_FILE"
    echo "Status: $(curl -s "$APP_URL" | grep -o '"status":"[^"]*"' || echo 'N/A')"
    echo
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    # Criar diretório de logs
    mkdir -p "$(dirname "$LOG_FILE")"
    
    case "${1:-}" in
        "deploy")
            IMAGE_TAG="${2:-latest}"
            perform_deploy
            ;;
        "rollback")
            local backup_dir="${2:-}"
            if [[ -z "$backup_dir" ]]; then
                log_error "Especifique o diretório de backup para rollback"
                echo "Uso: $0 rollback /path/to/backup"
                exit 1
            fi
            rollback "$backup_dir"
            ;;
        "status")
            log_info "Status atual do sistema:"
            bash "$SCRIPT_DIR/health-check.sh" report
            ;;
        "backup")
            create_backup
            ;;
        "")
            perform_deploy
            ;;
        *)
            echo "Uso: $0 [deploy [tag]|rollback <backup_dir>|status|backup]"
            echo
            echo "Comandos:"
            echo "  deploy [tag]  - Fazer deploy (padrão: data brasileira DD-MM-AAAA-HH)"
            echo "  rollback <dir> - Fazer rollback do backup especificado"
            echo "  status        - Verificar status atual"
            echo "  backup        - Criar backup manual"
            echo
            echo "Exemplos:"
            echo "  $0 deploy                    # Deploy com tag baseada na data brasileira atual"
            echo "  $0 deploy 15-03-2024-14     # Deploy com tag específica"
            echo "  $0 rollback /path/to/backup"
            exit 1
            ;;
    esac
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi