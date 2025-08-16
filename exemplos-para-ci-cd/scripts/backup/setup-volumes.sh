#!/bin/bash

# ===== SCRIPT DE CONFIGURAÇÃO DE VOLUMES =====
# Sistema: Conexão de Sorte - Backend
# Função: Criar e configurar volumes externos Docker
# Versão: 1.0.0
# Data: $(date +"%d/%m/%Y")

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/setup-volumes.log"

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

# ===== VERIFICAÇÕES INICIAIS =====
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando. Inicie o Docker e tente novamente."
        exit 1
    fi
    
    # Verificar se docker-compose está disponível
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose não encontrado. Instale o docker-compose."
        exit 1
    fi
    
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_success "Pré-requisitos verificados com sucesso"
}

# ===== CRIAÇÃO DE VOLUMES =====
create_volume() {
    local volume_name="$1"
    local description="$2"
    
    log_info "Criando volume: $volume_name ($description)"
    
    # Verificar se o volume já existe
    if docker volume inspect "$volume_name" >/dev/null 2>&1; then
        log_warning "Volume $volume_name já existe. Pulando criação."
        return 0
    fi
    
    # Criar o volume
    if docker volume create "$volume_name" >/dev/null 2>&1; then
        log_success "Volume $volume_name criado com sucesso"
        
        # Verificar informações do volume
        local volume_info
        volume_info=$(docker volume inspect "$volume_name" --format '{{.Mountpoint}}')
        log_info "Mountpoint: $volume_info"
    else
        log_error "Falha ao criar volume $volume_name"
        return 1
    fi
}

# ===== CONFIGURAÇÃO DE PERMISSÕES =====
setup_volume_permissions() {
    local volume_name="$1"
    local user_id="$2"
    local group_id="$3"
    
    log_info "Configurando permissões para volume: $volume_name"
    
    # Obter mountpoint do volume
    local mountpoint
    mountpoint=$(docker volume inspect "$volume_name" --format '{{.Mountpoint}}')
    
    if [[ -z "$mountpoint" ]]; then
        log_error "Não foi possível obter mountpoint do volume $volume_name"
        return 1
    fi
    
    # Configurar permissões (requer sudo)
    if [[ $EUID -eq 0 ]]; then
        chown "$user_id:$group_id" "$mountpoint" 2>/dev/null || true
        chmod 755 "$mountpoint" 2>/dev/null || true
        log_success "Permissões configuradas para $volume_name"
    else
        log_warning "Execute como root para configurar permissões do volume $volume_name"
    fi
}

# ===== VOLUMES DO PROJETO =====
setup_project_volumes() {
    log_info "Configurando volumes do projeto Conexão de Sorte..."
    
    # MySQL Data
    create_volume "mysql_data" "Dados do banco MySQL"
    setup_volume_permissions "mysql_data" "999" "999"  # MySQL user
    
    # Prometheus Data
    create_volume "prometheus_data" "Dados do Prometheus"
    setup_volume_permissions "prometheus_data" "65534" "65534"  # nobody user
    
    # Grafana Data
    create_volume "grafana_data" "Dados do Grafana"
    setup_volume_permissions "grafana_data" "472" "472"  # grafana user
    
    # Alertmanager Data
    create_volume "alertmanager_data" "Dados do Alertmanager"
    setup_volume_permissions "alertmanager_data" "65534" "65534"  # nobody user
    
    # SonarQube Data
    create_volume "sonarqube_data" "Dados do SonarQube"
    setup_volume_permissions "sonarqube_data" "1000" "1000"  # sonarqube user
    
    # SonarQube Extensions
    create_volume "sonarqube_extensions" "Extensões do SonarQube"
    setup_volume_permissions "sonarqube_extensions" "1000" "1000"
    
    # SonarQube Logs
    create_volume "sonarqube_logs" "Logs do SonarQube"
    setup_volume_permissions "sonarqube_logs" "1000" "1000"
    
    log_success "Todos os volumes do projeto foram configurados"
}

# ===== VERIFICAÇÃO DE VOLUMES =====
verify_volumes() {
    log_info "Verificando volumes criados..."
    
    local volumes=(
        "mysql_data"
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
        "sonarqube_data"
        "sonarqube_extensions"
        "sonarqube_logs"
    )
    
    local all_ok=true
    
    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            local mountpoint
            mountpoint=$(docker volume inspect "$volume" --format '{{.Mountpoint}}')
            log_success "✓ $volume - $mountpoint"
        else
            log_error "✗ $volume - NÃO ENCONTRADO"
            all_ok=false
        fi
    done
    
    if $all_ok; then
        log_success "Todos os volumes foram verificados com sucesso"
    else
        log_error "Alguns volumes não foram encontrados"
        return 1
    fi
}

# ===== LIMPEZA DE VOLUMES =====
cleanup_volumes() {
    log_warning "ATENÇÃO: Esta operação irá remover TODOS os volumes do projeto!"
    log_warning "Todos os dados serão perdidos permanentemente!"
    
    read -p "Tem certeza que deseja continuar? (digite 'CONFIRMAR' para prosseguir): " confirmation
    
    if [[ "$confirmation" != "CONFIRMAR" ]]; then
        log_info "Operação cancelada pelo usuário"
        return 0
    fi
    
    local volumes=(
        "mysql_data"
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
        "sonarqube_data"
        "sonarqube_extensions"
        "sonarqube_logs"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            log_info "Removendo volume: $volume"
            if docker volume rm "$volume" >/dev/null 2>&1; then
                log_success "Volume $volume removido"
            else
                log_error "Falha ao remover volume $volume"
            fi
        else
            log_warning "Volume $volume não encontrado"
        fi
    done
    
    log_success "Limpeza de volumes concluída"
}

# ===== BACKUP DE VOLUMES =====
backup_volumes() {
    local backup_dir="$PROJECT_ROOT/backups/volumes/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "Criando backup dos volumes em: $backup_dir"
    
    local volumes=(
        "mysql_data"
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
        "sonarqube_data"
        "sonarqube_extensions"
        "sonarqube_logs"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            log_info "Fazendo backup do volume: $volume"
            
            # Criar backup usando container temporário
            docker run --rm \
                -v "$volume:/source:ro" \
                -v "$backup_dir:/backup" \
                alpine:latest \
                tar czf "/backup/${volume}.tar.gz" -C /source .
            
            if [[ -f "$backup_dir/${volume}.tar.gz" ]]; then
                log_success "Backup do volume $volume criado"
            else
                log_error "Falha no backup do volume $volume"
            fi
        else
            log_warning "Volume $volume não encontrado para backup"
        fi
    done
    
    log_success "Backup dos volumes concluído em: $backup_dir"
}

# ===== RESTAURAÇÃO DE VOLUMES =====
restore_volumes() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Diretório de backup não encontrado: $backup_dir"
        return 1
    fi
    
    log_info "Restaurando volumes do backup: $backup_dir"
    
    local volumes=(
        "mysql_data"
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
        "sonarqube_data"
        "sonarqube_extensions"
        "sonarqube_logs"
    )
    
    for volume in "${volumes[@]}"; do
        local backup_file="$backup_dir/${volume}.tar.gz"
        
        if [[ -f "$backup_file" ]]; then
            log_info "Restaurando volume: $volume"
            
            # Criar volume se não existir
            if ! docker volume inspect "$volume" >/dev/null 2>&1; then
                docker volume create "$volume"
            fi
            
            # Restaurar usando container temporário
            docker run --rm \
                -v "$volume:/target" \
                -v "$backup_dir:/backup:ro" \
                alpine:latest \
                sh -c "cd /target && tar xzf /backup/${volume}.tar.gz"
            
            log_success "Volume $volume restaurado"
        else
            log_warning "Backup não encontrado para volume: $volume"
        fi
    done
    
    log_success "Restauração dos volumes concluída"
}

# ===== INFORMAÇÕES DOS VOLUMES =====
show_volume_info() {
    log_info "Informações dos volumes do projeto:"
    
    local volumes=(
        "mysql_data"
        "prometheus_data"
        "grafana_data"
        "alertmanager_data"
        "sonarqube_data"
        "sonarqube_extensions"
        "sonarqube_logs"
    )
    
    printf "\n%-20s %-10s %-50s\n" "VOLUME" "STATUS" "MOUNTPOINT"
    printf "%-20s %-10s %-50s\n" "------" "------" "---------"
    
    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            local mountpoint
            mountpoint=$(docker volume inspect "$volume" --format '{{.Mountpoint}}')
            printf "%-20s %-10s %-50s\n" "$volume" "EXISTS" "$mountpoint"
        else
            printf "%-20s %-10s %-50s\n" "$volume" "MISSING" "N/A"
        fi
    done
    
    echo
}

# ===== MENU PRINCIPAL =====
show_menu() {
    echo
    echo "===== GERENCIAMENTO DE VOLUMES - CONEXÃO DE SORTE ====="
    echo "1. Criar todos os volumes"
    echo "2. Verificar volumes existentes"
    echo "3. Mostrar informações dos volumes"
    echo "4. Fazer backup dos volumes"
    echo "5. Restaurar volumes do backup"
    echo "6. Limpar todos os volumes (PERIGOSO)"
    echo "7. Sair"
    echo
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    log_info "Iniciando script de configuração de volumes"
    
    check_prerequisites
    
    # Se argumentos foram passados, executar diretamente
    case "${1:-}" in
        "create")
            setup_project_volumes
            verify_volumes
            ;;
        "verify")
            verify_volumes
            ;;
        "info")
            show_volume_info
            ;;
        "backup")
            backup_volumes
            ;;
        "restore")
            if [[ -n "${2:-}" ]]; then
                restore_volumes "$2"
            else
                log_error "Especifique o diretório de backup: $0 restore /path/to/backup"
                exit 1
            fi
            ;;
        "cleanup")
            cleanup_volumes
            ;;
        "")
            # Menu interativo
            while true; do
                show_menu
                read -p "Escolha uma opção (1-7): " choice
                
                case $choice in
                    1)
                        setup_project_volumes
                        verify_volumes
                        ;;
                    2)
                        verify_volumes
                        ;;
                    3)
                        show_volume_info
                        ;;
                    4)
                        backup_volumes
                        ;;
                    5)
                        read -p "Digite o caminho do diretório de backup: " backup_path
                        restore_volumes "$backup_path"
                        ;;
                    6)
                        cleanup_volumes
                        ;;
                    7)
                        log_info "Saindo..."
                        exit 0
                        ;;
                    *)
                        log_error "Opção inválida. Tente novamente."
                        ;;
                esac
                
                echo
                read -p "Pressione Enter para continuar..."
            done
            ;;
        *)
            echo "Uso: $0 [create|verify|info|backup|restore <backup_dir>|cleanup]"
            echo
            echo "Comandos:"
            echo "  create    - Criar todos os volumes"
            echo "  verify    - Verificar volumes existentes"
            echo "  info      - Mostrar informações dos volumes"
            echo "  backup    - Fazer backup dos volumes"
            echo "  restore   - Restaurar volumes do backup"
            echo "  cleanup   - Limpar todos os volumes (PERIGOSO)"
            echo
            echo "Sem argumentos: Executar menu interativo"
            exit 1
            ;;
    esac
    
    log_success "Script de configuração de volumes concluído"
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi