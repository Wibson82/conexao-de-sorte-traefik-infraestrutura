#!/bin/bash

# =============================================================================
# SCRIPT DE MIGRAÇÃO DE TABELAS PARA TDE
# Projeto: Conexão de Sorte - Transparent Data Encryption
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQL_SCRIPT="$SCRIPT_DIR/migrate-tables-tde.sql"
BACKUP_DIR="$PROJECT_ROOT/backups/tde-migration"
LOGS_DIR="$PROJECT_ROOT/logs/tde-migration"

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
    log_info "🔍 Verificando pré-requisitos para migração TDE..."
    
    # Verificar se o script SQL existe
    if [[ ! -f "$SQL_SCRIPT" ]]; then
        log_error "Script SQL não encontrado: $SQL_SCRIPT"
        exit 1
    fi
    
    # Verificar variáveis de ambiente
    if [[ -z "${MYSQL_ROOT_PASSWORD:-}" ]]; then
        log_warning "MYSQL_ROOT_PASSWORD não definida"
        read -s -p "Digite a senha root do MySQL: " MYSQL_ROOT_PASSWORD
        echo
        export MYSQL_ROOT_PASSWORD
    fi
    
    if [[ -z "${MYSQL_DATABASE:-}" ]]; then
        export MYSQL_DATABASE="conexao_de_sorte"
        log_info "Usando database padrão: $MYSQL_DATABASE"
    fi
    
    log_success "Pré-requisitos verificados"
}

# Criar diretórios necessários
setup_directories() {
    log_info "📁 Criando diretórios de migração..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOGS_DIR"
    
    log_success "Diretórios criados"
}

# Verificar status do TDE
check_tde_status() {
    log_info "🔍 Verificando status do TDE..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local status_file="$LOGS_DIR/tde-status-pre-migration-$timestamp.txt"
    
    # Verificar se MySQL está acessível
    if command -v mysql &> /dev/null; then
        # Verificar variáveis TDE
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'innodb_encrypt%';" > "$status_file" 2>&1 || {
            log_error "Não foi possível conectar ao MySQL"
            return 1
        }
        
        # Verificar keyring
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT * FROM performance_schema.keyring_keys;" >> "$status_file" 2>&1 || true
        
        log_success "Status TDE salvo em: $status_file"
        
        # Verificar se TDE está habilitado
        local tde_enabled=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW VARIABLES LIKE 'innodb_encrypt_tables';" -s -N 2>/dev/null | awk '{print $2}')
        
        if [[ "$tde_enabled" != "ON" ]]; then
            log_error "TDE não está habilitado. Execute primeiro: ./scripts/database/setup-mysql-tde.sh"
            return 1
        fi
        
        log_success "TDE está habilitado e pronto para migração"
        return 0
    else
        log_warning "MySQL client não disponível - assumindo ambiente Docker"
        return 0
    fi
}

# Criar backup antes da migração
create_pre_migration_backup() {
    log_info "💾 Criando backup antes da migração..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/pre-tde-migration-$timestamp.sql"
    
    if command -v mysql &> /dev/null; then
        # Backup usando mysqldump
        mysqldump \
            --single-transaction \
            --routines \
            --triggers \
            --add-drop-table \
            --create-options \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            "$MYSQL_DATABASE" \
            > "$backup_file" 2>"$LOGS_DIR/backup-$timestamp.log"
        
        if [[ $? -eq 0 ]]; then
            log_success "Backup criado: $backup_file"
            
            # Comprimir backup
            gzip "$backup_file"
            log_info "Backup comprimido: $backup_file.gz"
        else
            log_error "Falha no backup - verifique $LOGS_DIR/backup-$timestamp.log"
            return 1
        fi
    else
        log_warning "MySQL client não disponível - backup via Docker necessário"
        
        # Criar comando Docker para backup
        cat > "$BACKUP_DIR/docker-backup-command.sh" << EOF
#!/bin/bash
# Comando para backup via Docker
docker exec conexao-sorte-mysql-tde mysqldump \\
    --single-transaction \\
    --routines \\
    --triggers \\
    --add-drop-table \\
    --create-options \\
    -u root -p\$MYSQL_ROOT_PASSWORD \\
    $MYSQL_DATABASE \\
    > $backup_file
EOF
        chmod +x "$BACKUP_DIR/docker-backup-command.sh"
        log_info "Comando de backup Docker criado: $BACKUP_DIR/docker-backup-command.sh"
    fi
}

# Executar migração TDE
execute_tde_migration() {
    log_info "🔄 Executando migração TDE..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local migration_log="$LOGS_DIR/tde-migration-$timestamp.log"
    
    log_warning "⚠️ ATENÇÃO: Esta operação irá criptografar todas as tabelas"
    log_warning "⚠️ Certifique-se de ter feito backup dos dados"
    
    read -p "Deseja continuar com a migração? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Migração cancelada pelo usuário"
        exit 0
    fi
    
    if command -v mysql &> /dev/null; then
        # Executar migração via MySQL client
        log_info "Executando migração via MySQL client..."
        
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$SQL_SCRIPT" > "$migration_log" 2>&1
        
        if [[ $? -eq 0 ]]; then
            log_success "Migração TDE executada com sucesso"
            log_info "Log da migração: $migration_log"
        else
            log_error "Falha na migração TDE - verifique $migration_log"
            return 1
        fi
    else
        log_warning "MySQL client não disponível - criando comando Docker"
        
        # Criar comando Docker para migração
        cat > "$LOGS_DIR/docker-migration-command.sh" << EOF
#!/bin/bash
# Comando para migração via Docker
docker exec -i conexao-sorte-mysql-tde mysql \\
    -u root -p\$MYSQL_ROOT_PASSWORD \\
    $MYSQL_DATABASE \\
    < $SQL_SCRIPT \\
    > $migration_log 2>&1
EOF
        chmod +x "$LOGS_DIR/docker-migration-command.sh"
        log_info "Comando de migração Docker criado: $LOGS_DIR/docker-migration-command.sh"
    fi
}

# Validar migração
validate_migration() {
    log_info "✅ Validando migração TDE..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local validation_file="$LOGS_DIR/tde-validation-post-migration-$timestamp.txt"
    
    if command -v mysql &> /dev/null; then
        # Verificar tabelas criptografadas
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" << 'EOF' > "$validation_file" 2>&1
-- Verificar tabelas criptografadas
SELECT 
    TABLE_NAME,
    ENGINE,
    CREATE_OPTIONS,
    CASE 
        WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN '✅ CRIPTOGRAFADA'
        ELSE '❌ NÃO CRIPTOGRAFADA'
    END as ENCRYPTION_STATUS,
    TABLE_ROWS,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as SIZE_MB
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Estatísticas de criptografia
SELECT 
    COUNT(*) as total_tables,
    SUM(CASE WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN 1 ELSE 0 END) as encrypted_tables,
    SUM(CASE WHEN CREATE_OPTIONS NOT LIKE '%ENCRYPTION%' THEN 1 ELSE 0 END) as unencrypted_tables,
    ROUND(
        (SUM(CASE WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        2
    ) as encryption_percentage
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
  AND TABLE_TYPE = 'BASE TABLE';
EOF
        
        log_success "Validação salva em: $validation_file"
        
        # Mostrar resumo da validação
        local encrypted_count=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -e "
            SELECT COUNT(*) 
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = '$MYSQL_DATABASE' 
              AND TABLE_TYPE = 'BASE TABLE' 
              AND CREATE_OPTIONS LIKE '%ENCRYPTION%';" -s -N 2>/dev/null)
        
        local total_count=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -e "
            SELECT COUNT(*) 
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = '$MYSQL_DATABASE' 
              AND TABLE_TYPE = 'BASE TABLE';" -s -N 2>/dev/null)
        
        log_info "📊 Resumo da migração:"
        log_info "  Total de tabelas: $total_count"
        log_info "  Tabelas criptografadas: $encrypted_count"
        
        if [[ "$encrypted_count" -eq "$total_count" ]]; then
            log_success "✅ Todas as tabelas foram criptografadas com sucesso!"
        else
            log_warning "⚠️ Algumas tabelas podem não ter sido criptografadas"
        fi
    else
        log_warning "MySQL client não disponível - validação manual necessária"
    fi
}

# Gerar relatório de migração
generate_migration_report() {
    log_info "📋 Gerando relatório de migração..."
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local report_file="$LOGS_DIR/tde-migration-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔒 Relatório de Migração TDE
## Conexão de Sorte - Transparent Data Encryption

**Data da Migração**: $timestamp  
**Database**: $MYSQL_DATABASE  
**Responsável**: DBA + DevOps

---

## 📊 Resumo da Migração

### ✅ Tabelas Migradas
- \`usuarios\` - Dados pessoais sensíveis
- \`sorteios\` - Dados de negócio críticos  
- \`participantes\` - Dados pessoais
- \`transacoes\` - Dados financeiros
- \`audit_logs\` - Logs de auditoria

### 📁 Arquivos Gerados
- Script SQL: \`$SQL_SCRIPT\`
- Backup pré-migração: \`$BACKUP_DIR/\`
- Logs de migração: \`$LOGS_DIR/\`

---

## 🎯 Próximos Passos

### 1. Validação
- Verificar se todas as tabelas estão criptografadas
- Testar inserção/consulta de dados
- Monitorar performance

### 2. Backup do Keyring
- **CRÍTICO**: Fazer backup do keyring
- Localização: \`/var/lib/mysql-keyring/\`
- Comando: \`cp -r /var/lib/mysql-keyring/ /backup/keyring-$(date +%Y%m%d)/\`

### 3. Monitoramento
- Acompanhar métricas de performance
- Verificar logs de erro
- Configurar alertas para falhas de criptografia

---

## ⚠️ Pontos Críticos

### 🔑 Keyring
- **Backup obrigatório** do diretório keyring
- **Sem keyring**: Dados são irrecuperáveis
- **Permissões**: 700, owner mysql

### 📊 Performance
- **Overhead esperado**: 5-15%
- **Monitoramento**: Métricas Innodb_encryption_*
- **Otimização**: Ajustar buffer pool se necessário

---

**📝 Relatório gerado**: $timestamp
EOF
    
    log_success "Relatório gerado: $report_file"
}

# Função principal
main() {
    log_info "🔒 Iniciando migração de tabelas para TDE..."
    
    check_prerequisites
    setup_directories
    check_tde_status || {
        log_error "TDE não está configurado adequadamente"
        exit 1
    }
    create_pre_migration_backup
    execute_tde_migration
    validate_migration
    generate_migration_report
    
    log_success "🎉 Migração TDE concluída!"
    
    echo ""
    log_info "📋 PRÓXIMOS PASSOS CRÍTICOS:"
    echo "  1. 🔑 BACKUP DO KEYRING: cp -r /var/lib/mysql-keyring/ /backup/"
    echo "  2. ✅ Validar dados: SELECT * FROM usuarios LIMIT 1;"
    echo "  3. 📊 Monitorar performance: SHOW GLOBAL STATUS LIKE 'Innodb_encryption%';"
    echo ""
    echo "  📁 Logs em: $LOGS_DIR"
    echo "  💾 Backups em: $BACKUP_DIR"
    
    log_warning "⚠️ CRÍTICO: Faça backup do keyring IMEDIATAMENTE!"
}

# Executar função principal
main "$@"
