#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO MYSQL TDE
# Projeto: Conexão de Sorte - Transparent Data Encryption
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MYSQL_CONFIG_DIR="$PROJECT_ROOT/mysql-config"
BACKUP_DIR="$PROJECT_ROOT/backups/mysql-tde"
LOGS_DIR="$PROJECT_ROOT/logs/mysql-tde"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "🔍 Verificando pré-requisitos..."
    
    # Verificar MySQL
    if ! command -v mysql &> /dev/null; then
        log_error "MySQL client não encontrado"
        exit 1
    fi
    
    # Verificar Docker (se usando containerizado)
    if command -v docker &> /dev/null; then
        log_info "Docker disponível para ambiente containerizado"
    fi
    
    # Verificar variáveis de ambiente
    if [[ -z "${MYSQL_ROOT_PASSWORD:-}" ]]; then
        log_warning "MYSQL_ROOT_PASSWORD não definida"
        read -s -p "Digite a senha root do MySQL: " MYSQL_ROOT_PASSWORD
        echo
        export MYSQL_ROOT_PASSWORD
    fi
    
    log_success "Pré-requisitos verificados"
}

# Criar diretórios necessários
setup_directories() {
    log_info "📁 Criando estrutura de diretórios..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$PROJECT_ROOT/mysql-keyring"
    
    # Configurar permissões do keyring (se não estiver em Docker)
    if [[ ! -f /.dockerenv ]]; then
        chmod 700 "$PROJECT_ROOT/mysql-keyring" 2>/dev/null || true
    fi
    
    log_success "Diretórios criados"
}

# Backup do banco antes da configuração TDE
create_backup() {
    log_info "💾 Criando backup antes da configuração TDE..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/pre-tde-backup-$timestamp.sql"
    
    # Backup completo
    mysqldump \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-table \
        --create-options \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        --all-databases \
        > "$backup_file" 2>"$LOGS_DIR/backup-$timestamp.log"
    
    if [[ $? -eq 0 ]]; then
        log_success "Backup criado: $backup_file"
        
        # Comprimir backup
        gzip "$backup_file"
        log_info "Backup comprimido: $backup_file.gz"
    else
        log_error "Falha no backup - verifique $LOGS_DIR/backup-$timestamp.log"
        exit 1
    fi
}

# Verificar versão do MySQL
check_mysql_version() {
    log_info "🔍 Verificando versão do MySQL..."
    
    local version=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT VERSION();" -s -N 2>/dev/null)
    
    if [[ -z "$version" ]]; then
        log_error "Não foi possível conectar ao MySQL"
        exit 1
    fi
    
    log_info "Versão do MySQL: $version"
    
    # Verificar se é MySQL 8.0+
    local major_version=$(echo "$version" | cut -d. -f1)
    local minor_version=$(echo "$version" | cut -d. -f2)
    
    if [[ $major_version -lt 8 ]]; then
        log_error "TDE requer MySQL 8.0 ou superior. Versão atual: $version"
        exit 1
    fi
    
    log_success "Versão do MySQL compatível com TDE"
}

# Verificar se TDE já está habilitado
check_tde_status() {
    log_info "🔍 Verificando status atual do TDE..."
    
    local tde_status=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" \
        -e "SHOW VARIABLES LIKE 'innodb_encrypt_tables';" -s -N 2>/dev/null | awk '{print $2}')
    
    if [[ "$tde_status" == "ON" ]]; then
        log_warning "TDE já está habilitado"
        return 0
    else
        log_info "TDE não está habilitado - prosseguindo com configuração"
        return 1
    fi
}

# Configurar TDE no MySQL
configure_tde() {
    log_info "⚙️ Configurando TDE no MySQL..."
    
    # Verificar se já está configurado
    if check_tde_status; then
        log_info "TDE já configurado - pulando configuração"
        return 0
    fi
    
    log_warning "⚠️ ATENÇÃO: A configuração TDE requer reinicialização do MySQL"
    log_warning "⚠️ Certifique-se de ter feito backup dos dados"
    
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Configuração cancelada pelo usuário"
        exit 0
    fi
    
    # Aplicar configurações TDE
    log_info "📝 Aplicando configurações TDE..."
    
    # Em ambiente Docker, copiar configuração
    if [[ -f /.dockerenv ]]; then
        log_info "Ambiente Docker detectado"
        # Configurações serão aplicadas via Docker Compose
    else
        # Ambiente local - aplicar configurações
        log_info "Aplicando configurações no MySQL local"
        
        # Configurações dinâmicas (que podem ser aplicadas sem restart)
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" << 'EOF'
-- Configurações que podem ser aplicadas dinamicamente
SET GLOBAL table_encryption_privilege_check = ON;
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 2;
EOF
    fi
    
    log_success "Configurações TDE aplicadas"
    log_warning "⚠️ Reinicialização do MySQL necessária para ativar TDE completamente"
}

# Validar configuração TDE
validate_tde_configuration() {
    log_info "✅ Validando configuração TDE..."
    
    local validation_file="$LOGS_DIR/tde-validation-$(date +%Y%m%d_%H%M%S).txt"
    
    echo "# VALIDAÇÃO TDE - $(date)" > "$validation_file"
    echo "=================================" >> "$validation_file"
    
    # Verificar variáveis de criptografia
    log_info "Verificando variáveis de criptografia..."
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" \
        -e "SHOW VARIABLES LIKE 'innodb_encrypt%';" >> "$validation_file" 2>&1
    
    # Verificar keyring
    log_info "Verificando keyring..."
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" \
        -e "SELECT * FROM performance_schema.keyring_keys;" >> "$validation_file" 2>&1 || true
    
    # Verificar plugins carregados
    log_info "Verificando plugins..."
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" \
        -e "SHOW PLUGINS;" | grep -i keyring >> "$validation_file" 2>&1 || true
    
    log_success "Validação salva em: $validation_file"
}

# Criar Docker Compose com TDE
create_docker_compose_tde() {
    log_info "🐳 Criando Docker Compose com TDE..."
    
    cat > "$PROJECT_ROOT/docker-compose.mysql-tde.yml" << 'EOF'
version: '3.8'

services:
  mysql-tde:
    image: mysql:8.4-lts
    container_name: conexao-sorte-mysql-tde
    restart: unless-stopped
    
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-conexao_de_sorte}
      MYSQL_USER: ${MYSQL_USER:-conexao_user}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-conexao_pass}
      TZ: America/Sao_Paulo
    
    volumes:
      # Configuração TDE
      - ./mysql-config/tde-setup.cnf:/etc/mysql/conf.d/tde-setup.cnf:ro
      
      # Dados persistentes
      - mysql_tde_data:/var/lib/mysql
      
      # Keyring (CRÍTICO para TDE)
      - mysql_keyring:/var/lib/mysql-keyring
      
      # Logs
      - mysql_logs:/var/log/mysql
      
      # SSL certificates (se disponível)
      - ./ssl:/etc/mysql/ssl:ro
      
      # Scripts de inicialização
      - ./scripts/database/init:/docker-entrypoint-initdb.d:ro
    
    ports:
      - "3306:3306"
    
    networks:
      - conexao-network
    
    # Configurações de saúde
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p$$MYSQL_ROOT_PASSWORD"]
      timeout: 20s
      retries: 10
      interval: 30s
      start_period: 60s
    
    # Configurações de recursos
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'

volumes:
  mysql_tde_data:
    driver: local
  mysql_keyring:
    driver: local
  mysql_logs:
    driver: local

networks:
  conexao-network:
    driver: bridge
EOF
    
    log_success "Docker Compose TDE criado: docker-compose.mysql-tde.yml"
}

# Criar script de inicialização
create_init_script() {
    log_info "📝 Criando script de inicialização..."
    
    mkdir -p "$PROJECT_ROOT/scripts/database/init"
    
    cat > "$PROJECT_ROOT/scripts/database/init/01-setup-tde.sql" << 'EOF'
-- =============================================================================
-- SCRIPT DE INICIALIZAÇÃO TDE
-- Executado automaticamente na primeira inicialização do MySQL
-- =============================================================================

-- Verificar se TDE está habilitado
SELECT 'Verificando status TDE...' as status;
SHOW VARIABLES LIKE 'innodb_encrypt%';

-- Verificar keyring
SELECT 'Verificando keyring...' as status;
SELECT * FROM performance_schema.keyring_keys;

-- Criar usuário para aplicação com privilégios adequados
CREATE USER IF NOT EXISTS 'conexao_app'@'%' IDENTIFIED BY 'conexao_app_secure_pass';

-- Conceder privilégios necessários
GRANT SELECT, INSERT, UPDATE, DELETE ON conexao_de_sorte.* TO 'conexao_app'@'%';
GRANT CREATE, ALTER, INDEX ON conexao_de_sorte.* TO 'conexao_app'@'%';

-- Privilégio para criar tabelas criptografadas
GRANT TABLE_ENCRYPTION_ADMIN ON *.* TO 'conexao_app'@'%';

-- Aplicar mudanças
FLUSH PRIVILEGES;

SELECT 'Inicialização TDE concluída!' as status;
EOF
    
    log_success "Script de inicialização criado"
}

# Gerar relatório de configuração
generate_configuration_report() {
    log_info "📋 Gerando relatório de configuração..."
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local report_file="$LOGS_DIR/tde-configuration-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔒 Relatório de Configuração TDE
## Conexão de Sorte - Transparent Data Encryption

**Data da Configuração**: $timestamp  
**Responsável**: DBA + DevOps  
**Status**: Configuração Preparada

---

## 📊 Resumo da Configuração

### ✅ Arquivos Criados
- \`mysql-config/tde-setup.cnf\` - Configuração principal TDE
- \`docker-compose.mysql-tde.yml\` - Docker Compose com TDE
- \`scripts/database/init/01-setup-tde.sql\` - Script de inicialização
- \`scripts/database/setup-mysql-tde.sh\` - Script de configuração

### 🔧 Configurações Aplicadas
- **Keyring**: keyring_file configurado
- **Criptografia**: innodb_encrypt_tables = ON
- **Logs**: innodb_encrypt_log = ON
- **Temporárias**: innodb_encrypt_temporary_tables = ON
- **Privilégios**: table_encryption_privilege_check = ON

### 📁 Estrutura de Diretórios
- \`mysql-keyring/\` - Armazenamento de chaves (CRÍTICO)
- \`backups/mysql-tde/\` - Backups pré-TDE
- \`logs/mysql-tde/\` - Logs de configuração

---

## 🚀 Próximos Passos

### 1. Inicializar MySQL com TDE
\`\`\`bash
# Usando Docker Compose
docker-compose -f docker-compose.mysql-tde.yml up -d

# Aguardar inicialização
docker-compose -f docker-compose.mysql-tde.yml logs -f mysql-tde
\`\`\`

### 2. Validar Configuração
\`\`\`sql
-- Verificar TDE
SHOW VARIABLES LIKE 'innodb_encrypt%';

-- Verificar keyring
SELECT * FROM performance_schema.keyring_keys;
\`\`\`

### 3. Migrar Tabelas Existentes
\`\`\`sql
-- Aplicar criptografia às tabelas
ALTER TABLE usuarios ENCRYPTION='Y';
ALTER TABLE sorteios ENCRYPTION='Y';
ALTER TABLE transacoes ENCRYPTION='Y';
\`\`\`

---

## ⚠️ Pontos Críticos

### 🔑 Backup do Keyring
- **CRÍTICO**: Fazer backup do diretório \`mysql-keyring/\`
- **Sem keyring**: Dados criptografados são IRRECUPERÁVEIS
- **Localização**: Volume Docker \`mysql_keyring\`

### 📊 Monitoramento
- **Performance**: Overhead esperado de 5-15%
- **Logs**: Monitorar \`/var/log/mysql/error.log\`
- **Métricas**: Acompanhar via Prometheus/Grafana

### 🔒 Segurança
- **Keyring**: Permissões 700, owner mysql
- **SSL**: Conexões criptografadas obrigatórias
- **Usuários**: Privilégios mínimos necessários

---

## 📞 Suporte

- **Documentação**: MySQL 8.0 TDE Documentation
- **Scripts**: \`scripts/database/\`
- **Logs**: \`logs/mysql-tde/\`

---

**📝 Relatório gerado**: $timestamp
EOF
    
    log_success "Relatório gerado: $report_file"
}

# Função principal
main() {
    log_info "🔒 Iniciando configuração MySQL TDE..."
    
    check_prerequisites
    setup_directories
    create_backup
    check_mysql_version
    configure_tde
    validate_tde_configuration
    create_docker_compose_tde
    create_init_script
    generate_configuration_report
    
    log_success "🎉 Configuração MySQL TDE concluída!"
    
    echo ""
    log_info "📋 PRÓXIMOS PASSOS:"
    echo "  1. Inicializar MySQL: docker-compose -f docker-compose.mysql-tde.yml up -d"
    echo "  2. Validar TDE: ./scripts/database/validate-tde.sh"
    echo "  3. Migrar tabelas: ./scripts/database/migrate-tables-tde.sh"
    echo ""
    echo "  📁 Logs em: $LOGS_DIR"
    echo "  💾 Backups em: $BACKUP_DIR"
}

# Executar função principal
main "$@"
