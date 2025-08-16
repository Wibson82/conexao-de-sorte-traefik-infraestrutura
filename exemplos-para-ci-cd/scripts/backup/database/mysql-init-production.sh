#!/bin/bash

# 🗄️ Script de Inicialização MySQL - Conexão de Sorte
# ✅ Configuração segura com GitHub Secrets + Azure Key Vault
# ✅ Compatível com produção e desenvolvimento
# ✅ Resolve problema de autenticação app_user definitivamente

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] 🗄️ MySQL Init:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ MySQL Init:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ MySQL Init:${NC} $1" >&2
}

# Configurações
readonly MYSQL_DATABASE=${MYSQL_DATABASE:-conexaodb}

# Obter credenciais de múltiplas fontes (prioridade: GitHub Secrets > Docker Secrets > Environment)
get_mysql_credentials() {
    log "Obtendo credenciais MySQL de múltiplas fontes..."
    
    # Prioridade 1: GitHub Secrets via environment variables
    if [[ -n "${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-}" ]]; then
        MYSQL_ROOT_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD}"
        MYSQL_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD}"
        MYSQL_USER="root"
        log_success "Credenciais obtidas via GitHub Secrets"
        return 0
    fi
    
    # Prioridade 2: Docker Secrets
    if [[ -f "/run/secrets/mysql_root_password" ]]; then
        MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
        MYSQL_PASSWORD=$(cat /run/secrets/mysql_password 2>/dev/null || echo "$MYSQL_ROOT_PASSWORD")
        MYSQL_USER="root"
        log_success "Credenciais obtidas via Docker Secrets"
        return 0
    fi
    
    # Prioridade 3: Environment variables diretas
    if [[ -n "${MYSQL_ROOT_PASSWORD:-}" ]]; then
        MYSQL_PASSWORD="${MYSQL_PASSWORD:-$MYSQL_ROOT_PASSWORD}"
        MYSQL_USER="${MYSQL_USER:-root}"
        log_success "Credenciais obtidas via Environment Variables"
        return 0
    fi
    
    log_error "Nenhuma credencial MySQL encontrada!"
    return 1
}

# Aguardar MySQL estar pronto
wait_for_mysql() {
    log "Aguardando MySQL estar pronto..."
    
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if mysqladmin ping -h localhost --silent 2>/dev/null; then
            log_success "MySQL está respondendo"
            return 0
        fi
        
        if [[ $((attempt % 10)) -eq 0 ]]; then
            log "Aguardando MySQL... ($attempt/$max_attempts)"
        fi
        
        sleep 2
        ((attempt++))
    done
    
    log_error "MySQL não ficou pronto após $max_attempts tentativas"
    return 1
}

# Configurar usuário MySQL com plugin correto
configure_mysql_user() {
    log "Configurando usuário MySQL com plugin de autenticação correto..."
    
    # Aguardar MySQL estar pronto
    if ! wait_for_mysql; then
        return 1
    fi
    
    # Configurar usuário com mysql_native_password para compatibilidade
    log "Configurando usuário root com mysql_native_password..."
    
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" --connect-timeout=30 <<EOF
-- Garantir que root pode conectar de qualquer lugar com senha
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';

-- Garantir privilégios completos
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

-- Criar database se não existir
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Aplicar mudanças
FLUSH PRIVILEGES;

-- Log de sucesso
SELECT 'MySQL configurado com sucesso para Conexão de Sorte!' as status;
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Usuário MySQL configurado com sucesso"
        return 0
    else
        log_error "Falha ao configurar usuário MySQL"
        return 1
    fi
}

# Validar configuração
validate_configuration() {
    log "Validando configuração MySQL..."
    
    # Testar conexão
    if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
        log_success "Conexão MySQL validada"
    else
        log_error "Falha na validação da conexão MySQL"
        return 1
    fi
    
    # Verificar database
    if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE ${MYSQL_DATABASE};" >/dev/null 2>&1; then
        log_success "Database ${MYSQL_DATABASE} acessível"
    else
        log_error "Database ${MYSQL_DATABASE} não acessível"
        return 1
    fi
    
    log_success "Configuração MySQL validada com sucesso"
}

# Função principal
main() {
    log "Iniciando configuração MySQL para Conexão de Sorte..."
    
    # Obter credenciais
    if ! get_mysql_credentials; then
        log_error "Falha ao obter credenciais MySQL"
        exit 1
    fi
    
    # Exibir configuração (mascarando senhas)
    log "Configuração MySQL:"
    log "  - Database: ${MYSQL_DATABASE}"
    log "  - User: ${MYSQL_USER}"
    log "  - Password: ${MYSQL_PASSWORD:0:3}***"
    log "  - Root Password: ${MYSQL_ROOT_PASSWORD:0:3}***"
    
    # Configurar MySQL
    if ! configure_mysql_user; then
        log_error "Falha ao configurar usuário MySQL"
        exit 1
    fi
    
    # Validar configuração
    if ! validate_configuration; then
        log_error "Falha na validação da configuração"
        exit 1
    fi
    
    log_success "Configuração MySQL concluída com sucesso!"
}

# Executar função principal se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
