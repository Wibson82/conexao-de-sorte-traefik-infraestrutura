#!/bin/bash

# ============================================================================
# SCRIPT DE GESTÃO DE SEGREDOS E CONFIGURAÇÕES SENSÍVEIS
# ============================================================================
# Gerencia rotação de senhas, validação de segredos e auditoria de acesso
# Implementa práticas de segurança para LGPD e compliance
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configurações
SECRETS_DIR="${SECRETS_DIR:-/run/secrets}"
BACKUP_DIR="${BACKUP_DIR:-/backup/secrets}"
AUDIT_LOG="${AUDIT_LOG:-/var/log/secrets-audit.log}"
KV_NAME="${AZURE_KEYVAULT_NAME:-}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-conexao-mysql}"

# Função de ajuda
show_help() {
    echo "
╔══════════════════════════════════════════════════════════════════╗
║                    GESTÃO DE SEGREDOS                           ║
╚══════════════════════════════════════════════════════════════════╝

Uso: $0 [COMANDO] [OPÇÕES]

COMANDOS DISPONÍVEIS:
  rotate-mysql        - Rotacionar senha do MySQL
  rotate-jwt          - Rotacionar chave JWT
  validate-secrets    - Validar todos os segredos
  audit-access        - Auditar acesso aos segredos
  sync-keyvault       - Sincronizar com Azure Key Vault
  check-expiry        - Verificar segredos próximos ao vencimento
  generate-password   - Gerar senha segura
  backup-secrets      - Backup de segredos locais
  help                - Mostrar esta ajuda

EXEMPLOS:
  $0 rotate-mysql                 # Rotacionar senha MySQL
  $0 validate-secrets             # Validar todos os segredos
  $0 generate-password 32         # Gerar senha de 32 caracteres
  $0 audit-access                 # Relatório de auditoria
"
}

# Função para registrar auditoria
audit_log() {
    local action="$1"
    local resource="$2"
    local status="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user=$(whoami)
    
    echo "[$timestamp] USER=$user ACTION=$action RESOURCE=$resource STATUS=$status" >> "$AUDIT_LOG"
}

# Gerar senha segura
generate_password() {
    local length="${1:-32}"
    
    if ! command -v openssl >/dev/null 2>&1; then
        log_error "OpenSSL não encontrado"
        return 1
    fi
    
    # Gerar senha com caracteres seguros
    local password=$(openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-${length})
    
    # Garantir que tenha pelo menos um número e um caractere especial
    if [[ ! "$password" =~ [0-9] ]] || [[ ! "$password" =~ [A-Z] ]] || [[ ! "$password" =~ [a-z] ]]; then
        # Regenerar se não atender critérios
        password=$(openssl rand -base64 48 | tr -d "=+/" | head -c${length})
    fi
    
    echo "$password"
    audit_log "GENERATE_PASSWORD" "length=$length" "SUCCESS"
}

# Rotacionar senha do MySQL
rotate_mysql_password() {
    log_info "🔄 Iniciando rotação da senha MySQL..."
    
    local new_password=$(generate_password 32)
    local mysql_root_password_file="$SECRETS_DIR/mysql_root_password"
    local mysql_password_file="$SECRETS_DIR/mysql_password"
    
    if [[ ! -f "$mysql_root_password_file" ]]; then
        log_error "Arquivo de senha root não encontrado: $mysql_root_password_file"
        audit_log "ROTATE_MYSQL" "mysql_root_password" "FAILED"
        return 1
    fi
    
    local current_root_password=$(cat "$mysql_root_password_file")
    
    # Testar conexão atual
    if ! docker exec "$MYSQL_CONTAINER" mysql -u root -p"$current_root_password" -e "SELECT 1;" >/dev/null 2>&1; then
        log_error "Falha na conexão MySQL com senha atual"
        audit_log "ROTATE_MYSQL" "connection_test" "FAILED"
        return 1
    fi
    
    # Backup da senha atual
    mkdir -p "$BACKUP_DIR"
    cp "$mysql_root_password_file" "$BACKUP_DIR/mysql_root_password.$(date +%Y%m%d_%H%M%S).bak"
    
    # Atualizar senha no MySQL
    log_info "Atualizando senha no MySQL..."
    if docker exec "$MYSQL_CONTAINER" mysql -u root -p"$current_root_password" \
        -e "ALTER USER 'root'@'%' IDENTIFIED BY '$new_password'; FLUSH PRIVILEGES;"; then
        
        # Atualizar arquivo de senha
        echo "$new_password" > "$mysql_root_password_file"
        echo "$new_password" > "$mysql_password_file"
        chmod 600 "$mysql_root_password_file" "$mysql_password_file"
        
        # Testar nova senha
        if docker exec "$MYSQL_CONTAINER" mysql -u root -p"$new_password" -e "SELECT 1;" >/dev/null 2>&1; then
            log_success "🔄 Senha MySQL rotacionada com sucesso"
            audit_log "ROTATE_MYSQL" "mysql_root_password" "SUCCESS"
            
            # Sincronizar com Key Vault se disponível
            if [[ -n "$KV_NAME" ]] && command -v az >/dev/null 2>&1; then
                sync_secret_to_keyvault "mysql-root-password" "$new_password"
            fi
        else
            log_error "Falha ao validar nova senha"
            audit_log "ROTATE_MYSQL" "validation" "FAILED"
            return 1
        fi
    else
        log_error "Falha ao atualizar senha no MySQL"
        audit_log "ROTATE_MYSQL" "mysql_update" "FAILED"
        return 1
    fi
}

# Rotacionar chave JWT
rotate_jwt_secret() {
    log_info "🔑 Iniciando rotação da chave JWT..."
    
    local jwt_secret_file="$SECRETS_DIR/jwt_secret"
    local new_secret=$(generate_password 64)
    
    # Backup da chave atual
    if [[ -f "$jwt_secret_file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$jwt_secret_file" "$BACKUP_DIR/jwt_secret.$(date +%Y%m%d_%H%M%S).bak"
    fi
    
    # Atualizar chave JWT
    echo "$new_secret" > "$jwt_secret_file"
    chmod 600 "$jwt_secret_file"
    
    log_success "🔑 Chave JWT rotacionada com sucesso"
    audit_log "ROTATE_JWT" "jwt_secret" "SUCCESS"
    
    # Sincronizar com Key Vault se disponível
    if [[ -n "$KV_NAME" ]] && command -v az >/dev/null 2>&1; then
        sync_secret_to_keyvault "jwt-secret" "$new_secret"
    fi
    
    log_warning "⚠️ ATENÇÃO: Reinicie a aplicação para aplicar a nova chave JWT"
}

# Sincronizar segredo com Azure Key Vault
sync_secret_to_keyvault() {
    local secret_name="$1"
    local secret_value="$2"
    
    if [[ -z "$KV_NAME" ]]; then
        log_warning "Azure Key Vault não configurado"
        return 0
    fi
    
    if ! az account show >/dev/null 2>&1; then
        log_warning "Azure CLI não autenticado"
        return 0
    fi
    
    log_info "Sincronizando $secret_name com Key Vault..."
    
    if az keyvault secret set --vault-name "$KV_NAME" --name "$secret_name" --value "$secret_value" >/dev/null 2>&1; then
        log_success "Segredo $secret_name sincronizado com Key Vault"
        audit_log "SYNC_KEYVAULT" "$secret_name" "SUCCESS"
    else
        log_error "Falha ao sincronizar $secret_name com Key Vault"
        audit_log "SYNC_KEYVAULT" "$secret_name" "FAILED"
    fi
}

# Validar todos os segredos
validate_secrets() {
    log_info "🔍 Validando segredos..."
    
    local errors=0
    
    # Verificar arquivos de segredos obrigatórios
    local required_secrets=(
        "mysql_root_password"
        "mysql_password"
        "jwt_secret"
    )
    
    for secret in "${required_secrets[@]}"; do
        local secret_file="$SECRETS_DIR/$secret"
        
        if [[ ! -f "$secret_file" ]]; then
            log_error "Segredo obrigatório não encontrado: $secret"
            ((errors++))
            audit_log "VALIDATE_SECRETS" "$secret" "MISSING"
        elif [[ ! -r "$secret_file" ]]; then
            log_error "Segredo não legível: $secret"
            ((errors++))
            audit_log "VALIDATE_SECRETS" "$secret" "UNREADABLE"
        else
            local permissions=$(stat -c "%a" "$secret_file" 2>/dev/null || stat -f "%A" "$secret_file" 2>/dev/null)
            if [[ "$permissions" != "600" ]]; then
                log_warning "Permissões inseguras em $secret: $permissions (deveria ser 600)"
                chmod 600 "$secret_file"
                log_info "Permissões corrigidas para $secret"
            fi
            
            local content=$(cat "$secret_file")
            if [[ ${#content} -lt 8 ]]; then
                log_warning "Segredo $secret muito curto (${#content} caracteres)"
            fi
            
            log_success "Segredo $secret válido"
            audit_log "VALIDATE_SECRETS" "$secret" "VALID"
        fi
    done
    
    # Testar conexão MySQL
    if [[ -f "$SECRETS_DIR/mysql_root_password" ]]; then
        local mysql_password=$(cat "$SECRETS_DIR/mysql_root_password")
        if docker exec "$MYSQL_CONTAINER" mysql -u root -p"$mysql_password" -e "SELECT 1;" >/dev/null 2>&1; then
            log_success "Conexão MySQL válida"
            audit_log "VALIDATE_SECRETS" "mysql_connection" "SUCCESS"
        else
            log_error "Falha na conexão MySQL"
            ((errors++))
            audit_log "VALIDATE_SECRETS" "mysql_connection" "FAILED"
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "🔍 Todos os segredos são válidos"
    else
        log_error "🔍 Encontrados $errors problemas com segredos"
        return 1
    fi
}

# Verificar segredos próximos ao vencimento
check_expiry() {
    log_info "⏰ Verificando vencimento de segredos..."
    
    if [[ -z "$KV_NAME" ]] || ! command -v az >/dev/null 2>&1; then
        log_warning "Azure Key Vault não disponível para verificação de vencimento"
        return 0
    fi
    
    if ! az account show >/dev/null 2>&1; then
        log_warning "Azure CLI não autenticado"
        return 0
    fi
    
    local expiring_count=0
    local current_date=$(date +%s)
    local warning_days=30
    local warning_threshold=$((current_date + (warning_days * 24 * 3600)))
    
    for secret in $(az keyvault secret list --vault-name "$KV_NAME" --query "[].name" -o tsv); do
        local expiry=$(az keyvault secret show --vault-name "$KV_NAME" --name "$secret" --query "attributes.expires" -o tsv)
        
        if [[ "$expiry" != "null" ]] && [[ -n "$expiry" ]]; then
            local expiry_timestamp=$(date -d "$expiry" +%s 2>/dev/null || echo "0")
            
            if [[ $expiry_timestamp -lt $warning_threshold ]] && [[ $expiry_timestamp -gt $current_date ]]; then
                local days_until_expiry=$(( (expiry_timestamp - current_date) / 86400 ))
                log_warning "Segredo $secret expira em $days_until_expiry dias ($expiry)"
                ((expiring_count++))
                audit_log "CHECK_EXPIRY" "$secret" "EXPIRING_${days_until_expiry}_DAYS"
            fi
        fi
    done
    
    if [[ $expiring_count -eq 0 ]]; then
        log_success "⏰ Nenhum segredo próximo ao vencimento"
    else
        log_warning "⏰ $expiring_count segredos próximos ao vencimento"
    fi
}

# Relatório de auditoria
audit_access() {
    log_info "📊 Gerando relatório de auditoria..."
    
    if [[ ! -f "$AUDIT_LOG" ]]; then
        log_warning "Log de auditoria não encontrado: $AUDIT_LOG"
        return 0
    fi
    
    echo ""
    echo "📊 RELATÓRIO DE AUDITORIA - ÚLTIMAS 24 HORAS"
    echo "═══════════════════════════════════════════════"
    
    local yesterday=$(date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d' 2>/dev/null)
    local today=$(date '+%Y-%m-%d')
    
    # Ações por tipo
    echo "
🔍 Ações por tipo:"
    grep -E "($yesterday|$today)" "$AUDIT_LOG" | awk '{print $3}' | sort | uniq -c | sort -nr
    
    # Usuários mais ativos
    echo "
👥 Usuários mais ativos:"
    grep -E "($yesterday|$today)" "$AUDIT_LOG" | awk '{print $2}' | sort | uniq -c | sort -nr
    
    # Falhas de segurança
    echo "
❌ Falhas de segurança:"
    grep -E "($yesterday|$today)" "$AUDIT_LOG" | grep "FAILED" | wc -l | xargs echo "Total de falhas:"
    
    # Últimas 10 ações
    echo "
📝 Últimas 10 ações:"
    tail -10 "$AUDIT_LOG" | while read line; do
        echo "  $line"
    done
    
    audit_log "AUDIT_ACCESS" "report_generated" "SUCCESS"
}

# Backup de segredos locais
backup_secrets() {
    log_info "💾 Fazendo backup de segredos locais..."
    
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
    
    local backup_file="$BACKUP_DIR/secrets-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if tar -czf "$backup_file" -C "$SECRETS_DIR" . 2>/dev/null; then
        chmod 600 "$backup_file"
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "💾 Backup criado: $backup_file ($size)"
        audit_log "BACKUP_SECRETS" "local_backup" "SUCCESS"
    else
        log_error "Falha ao criar backup de segredos"
        audit_log "BACKUP_SECRETS" "local_backup" "FAILED"
        return 1
    fi
}

# Sincronizar todos os segredos com Key Vault
sync_all_keyvault() {
    log_info "🔄 Sincronizando todos os segredos com Key Vault..."
    
    if [[ -z "$KV_NAME" ]]; then
        log_error "Azure Key Vault não configurado"
        return 1
    fi
    
    local synced=0
    local failed=0
    
    # Sincronizar segredos principais
    local secrets_map=(
        "mysql_root_password:mysql-root-password"
        "mysql_password:mysql-password"
        "jwt_secret:jwt-secret"
    )
    
    for mapping in "${secrets_map[@]}"; do
        local local_name=$(echo "$mapping" | cut -d: -f1)
        local kv_name=$(echo "$mapping" | cut -d: -f2)
        local secret_file="$SECRETS_DIR/$local_name"
        
        if [[ -f "$secret_file" ]]; then
            local secret_value=$(cat "$secret_file")
            if sync_secret_to_keyvault "$kv_name" "$secret_value"; then
                ((synced++))
            else
                ((failed++))
            fi
        else
            log_warning "Segredo local não encontrado: $local_name"
            ((failed++))
        fi
    done
    
    log_info "🔄 Sincronização concluída: $synced sucessos, $failed falhas"
}

# Processar comando
case "${1:-help}" in
    rotate-mysql)
        rotate_mysql_password
        ;;
    rotate-jwt)
        rotate_jwt_secret
        ;;
    validate-secrets)
        validate_secrets
        ;;
    audit-access)
        audit_access
        ;;
    sync-keyvault)
        sync_all_keyvault
        ;;
    check-expiry)
        check_expiry
        ;;
    generate-password)
        generate_password "${2:-32}"
        ;;
    backup-secrets)
        backup_secrets
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Comando inválido: $1"
        show_help
        exit 1
        ;;
esac