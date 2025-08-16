#!/bin/bash
# 🚀 Deploy Manual - Production-Ready com Blue-Green
# ✅ Script de backup para quando CI/CD falhar

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# ===== VERIFICAÇÕES INICIAIS =====
check_requirements() {
    log_info "Verificando requisitos..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado!"
        exit 1
    fi
    
    # Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não encontrado!"
        exit 1
    fi
    
    # Arquivo de configuração
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Arquivo docker-compose.prod.yml não encontrado em: $COMPOSE_FILE"
        exit 1
    fi
    
    log_success "Todos os requisitos atendidos"
}

# ===== CONFIGURAR VARIÁVEIS DE AMBIENTE =====
setup_environment() {
    log_info "Configurando variáveis de ambiente..."
    
    # Verificar se .env existe
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        log_warning "Arquivo .env não encontrado. Criando template..."
        
        cat > "$PROJECT_DIR/.env" << EOF
# ===== CONFIGURAÇÕES DE PRODUÇÃO =====
IMAGE_TAG=latest

# Azure Key Vault
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
AZURE_TENANT_ID=your-tenant-id
AZURE_KEYVAULT_ENDPOINT=https://your-keyvault.vault.azure.net/

# MySQL
MYSQL_ROOT_PASSWORD=your-root-password
MYSQL_APP_PASSWORD=your-app-password

# Grafana
GRAFANA_PASSWORD=admin123
EOF
        
        log_error "Configure o arquivo .env antes de continuar!"
        log_info "Arquivo criado em: $PROJECT_DIR/.env"
        exit 1
    fi
    
    # Carregar variáveis
    source "$PROJECT_DIR/.env"
    
    # Verificar variáveis obrigatórias
    required_vars=(
        "AZURE_CLIENT_ID"
        "AZURE_CLIENT_SECRET" 
        "AZURE_TENANT_ID"
        "AZURE_KEYVAULT_ENDPOINT"
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_APP_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variável $var não configurada no .env"
            exit 1
        fi
    done
    
    log_success "Variáveis de ambiente configuradas"
}

# ===== BACKUP DOS DADOS =====
backup_data() {
    log_info "Fazendo backup dos dados..."
    
    BACKUP_DIR="$PROJECT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup do MySQL se estiver rodando
    if docker ps --format "table {{.Names}}" | grep -q "conexao-mysql"; then
        log_info "Fazendo backup do MySQL..."
        docker exec conexao-mysql mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > "$BACKUP_DIR/mysql_backup.sql"
        log_success "Backup do MySQL salvo em: $BACKUP_DIR/mysql_backup.sql"
    fi
    
    # Backup dos volumes
    if docker volume ls | grep -q "conexao_mysql_data"; then
        log_info "Fazendo backup dos volumes..."
        docker run --rm -v conexao_mysql_data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/mysql_volume.tar.gz -C /data .
        log_success "Backup dos volumes salvo"
    fi
}

# ===== DEPLOY BLUE-GREEN =====
deploy_blue_green() {
    log_info "Iniciando deploy Blue-Green..."
    
    cd "$PROJECT_DIR"
    
    # Determinar instância ativa
    ACTIVE_COLOR="green"
    INACTIVE_COLOR="blue"
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "conexao-backend-blue.*Up"; then
        if ! docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "conexao-backend-green.*Up"; then
            ACTIVE_COLOR="blue"
            INACTIVE_COLOR="green"
        fi
    fi
    
    log_info "Instância ativa: $ACTIVE_COLOR"
    log_info "Deploy na instância: $INACTIVE_COLOR"
    
    # Pull das imagens
    log_info "Baixando imagens..."
    docker-compose -f docker-compose.prod.yml pull
    
    # Subir infraestrutura (MySQL, Traefik, Monitoring)
    log_info "Iniciando infraestrutura..."

    # Iniciar MySQL apenas se não estiver rodando
    if ! docker ps | grep -q "conexao-mysql"; then
        log_info "Iniciando MySQL..."
        docker-compose -f docker-compose.prod.yml up -d mysql
    else
        log_success "MySQL já está rodando."
    fi

    # Iniciar outros serviços
    docker-compose -f docker-compose.prod.yml up -d traefik prometheus grafana
    
    # Aguardar MySQL
    log_info "Aguardando MySQL inicializar..."
    for i in {1..30}; do
        if docker exec conexao-mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" &> /dev/null; then
            log_success "MySQL inicializado!"
            break
        fi
        log_info "Aguardando MySQL... ($i/30)"
        sleep 5
    done
    
    # Deploy da nova instância
    log_info "Fazendo deploy da instância $INACTIVE_COLOR..."
    docker-compose -f docker-compose.prod.yml up -d backend-$INACTIVE_COLOR
    
    # Health check da nova instância
    log_info "Verificando saúde da nova instância..."
    for i in {1..60}; do
        if docker exec conexao-backend-$INACTIVE_COLOR curl -f http://localhost:8080/actuator/health/readiness &> /dev/null; then
            log_success "Nova instância saudável!"
            break
        fi
        log_info "Aguardando health check... ($i/60)"
        sleep 10
    done
    
    # Verificar se passou no health check
    if ! docker exec conexao-backend-$INACTIVE_COLOR curl -f http://localhost:8080/actuator/health/readiness &> /dev/null; then
        log_error "Health check falhou! Abortando deploy."
        return 1
    fi
    
    # Switch do tráfego
    log_info "Fazendo switch do tráfego..."
    
    # Desabilitar instância antiga no Traefik
    docker-compose -f docker-compose.prod.yml stop backend-$ACTIVE_COLOR
    
    # Aguardar propagação
    sleep 10
    
    # Teste final
    log_info "Testando endpoint público..."
    for i in {1..10}; do
        if curl -f https://conexaodesorte.com.br/rest/actuator/health &> /dev/null; then
            log_success "Deploy concluído com sucesso!"
            
            # Remover instância antiga
            log_info "Removendo instância antiga..."
            docker-compose -f docker-compose.prod.yml rm -f backend-$ACTIVE_COLOR
            
            return 0
        fi
        log_info "Testando endpoint... ($i/10)"
        sleep 5
    done
    
    log_error "Teste final falhou! Fazendo rollback..."
    
    # Rollback
    docker-compose -f docker-compose.prod.yml up -d backend-$ACTIVE_COLOR
    docker-compose -f docker-compose.prod.yml stop backend-$INACTIVE_COLOR
    
    return 1
}

# ===== MONITORAMENTO =====
show_status() {
    log_info "Status dos serviços:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    log_info "Logs recentes:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=20
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    log_info "🚀 Iniciando deploy manual Production-Ready"
    
    check_requirements
    setup_environment
    backup_data
    
    if deploy_blue_green; then
        log_success "🎉 Deploy concluído com sucesso!"
        show_status
    else
        log_error "💥 Deploy falhou!"
        show_status
        exit 1
    fi
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
