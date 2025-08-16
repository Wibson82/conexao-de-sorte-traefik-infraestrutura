#!/bin/bash

# =============================================================================
# SCRIPT DE VALIDAÇÃO DE CONFIGURAÇÕES - CONEXÃO DE SORTE
# =============================================================================
# Valida se as configurações de desenvolvimento e produção estão corretas
# após a refatoração realizada

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se um arquivo existe
check_file() {
    if [[ -f "$1" ]]; then
        log_success "Arquivo encontrado: $1"
        return 0
    else
        log_error "Arquivo não encontrado: $1"
        return 1
    fi
}

# Função para verificar se uma string está presente em um arquivo
check_string_in_file() {
    local file="$1"
    local string="$2"
    local description="$3"
    
    if grep -q "$string" "$file" 2>/dev/null; then
        log_success "$description encontrado em $file"
        return 0
    else
        log_error "$description NÃO encontrado em $file"
        return 1
    fi
}

# Função para verificar se uma string NÃO está presente em um arquivo
check_string_not_in_file() {
    local file="$1"
    local string="$2"
    local description="$3"
    
    if ! grep -q "$string" "$file" 2>/dev/null; then
        log_success "$description NÃO encontrado em $file (correto)"
        return 0
    else
        log_error "$description encontrado em $file (INCORRETO)"
        return 1
    fi
}

# Função para verificar configurações de desenvolvimento
validate_dev_config() {
    log_info "Validando configurações de desenvolvimento..."
    
    local errors=0
    
    # Verificar arquivos de desenvolvimento
    check_file "src/main/resources/application-dev.yml" || ((errors++))
    check_file "src/main/resources/application-local-fallback.yml" || ((errors++))
    
    # Verificar configurações permissivas em desenvolvimento
    check_string_in_file "src/main/resources/application-dev.yml" "localhost:3000" "CORS localhost em dev" || ((errors++))
    check_string_in_file "src/main/resources/application-dev.yml" "AZURE_KEYVAULT_ENABLED=false" "Azure desabilitado em dev" || ((errors++))
    check_string_in_file "src/main/resources/application-dev.yml" "modo-seguranca-estrito: false" "Modo segurança relaxado em dev" || ((errors++))
    
    # Verificar que URLs de produção NÃO estão em dev
    check_string_not_in_file "src/main/resources/application-dev.yml" "conexaodesorte.com.br" "URLs de produção em dev" || ((errors++))
    
    # Verificar Docker Compose de desenvolvimento
    check_file "docker-compose.dev.yml" || ((errors++))
    check_string_in_file "docker-compose.dev.yml" "SPRING_PROFILES_ACTIVE=dev" "Perfil dev no Docker Compose" || ((errors++))
    check_string_in_file "docker-compose.dev.yml" "AZURE_KEYVAULT_ENABLED=false" "Azure desabilitado no Docker Compose dev" || ((errors++))
    
    return $errors
}

# Função para verificar configurações de produção
validate_prod_config() {
    log_info "Validando configurações de produção..."
    
    local errors=0
    
    # Verificar arquivos de produção
    check_file "src/main/resources/application-production.yml" || ((errors++))
    check_file "deploy/docker-compose.prod.yml" || ((errors++))
    
    # Verificar configurações restritivas em produção
    check_string_in_file "src/main/resources/application-production.yml" "conexaodesorte.com.br" "CORS produção em prod" || ((errors++))
    check_string_in_file "src/main/resources/application-production.yml" "AZURE_KEYVAULT_ENABLED=true" "Azure habilitado em prod" || ((errors++))
    check_string_in_file "src/main/resources/application-production.yml" "modo-seguranca-estrito: true" "Modo segurança estrito em prod" || ((errors++))
    check_string_in_file "src/main/resources/application-production.yml" "auditoria.enabled: true" "Auditoria habilitada em prod" || ((errors++))
    
    # Verificar que URLs de desenvolvimento NÃO estão em produção
    check_string_not_in_file "src/main/resources/application-production.yml" "localhost:3000" "URLs de desenvolvimento em prod" || ((errors++))
    
    # Verificar Docker Compose de produção
    check_string_in_file "deploy/docker-compose.prod.yml" "SPRING_PROFILES_ACTIVE=production,azure" "Perfil prod+azure no Docker Compose" || ((errors++))
    check_string_in_file "deploy/docker-compose.prod.yml" "AZURE_KEYVAULT_ENABLED=true" "Azure habilitado no Docker Compose prod" || ((errors++))
    check_string_in_file "deploy/docker-compose.prod.yml" "AZURE_KEYVAULT_FALLBACK_ENABLED=true" "Fallback habilitado no Docker Compose prod" || ((errors++))
    
    return $errors
}

# Função para verificar configurações Azure
validate_azure_config() {
    log_info "Validando configurações Azure..."
    
    local errors=0
    
    # Verificar arquivos Azure
    check_file "src/main/resources/application-azure.yml" || ((errors++))
    
    # Verificar configurações Azure
    check_string_in_file "src/main/resources/application-azure.yml" "fallback.enabled: true" "Fallback Azure habilitado" || ((errors++))
    check_string_in_file "src/main/resources/application-azure.yml" "use-default-credential: true" "DefaultAzureCredential configurado" || ((errors++))
    
    # Verificar fallback local
    check_file "src/main/resources/application-local-fallback.yml" || ((errors++))
    check_string_in_file "src/main/resources/application-local-fallback.yml" "AZURE_KEYVAULT_ENABLED=false" "Azure desabilitado no fallback" || ((errors++))
    
    return $errors
}

# Função para verificar configurações principais
validate_main_config() {
    log_info "Validando configuração principal..."
    
    local errors=0
    
    # Verificar arquivo principal
    check_file "src/main/resources/application.yml" || ((errors++))
    
    # Verificar que configurações de produção NÃO estão no arquivo principal
    check_string_not_in_file "src/main/resources/application.yml" "conexaodesorte.com.br" "URLs de produção no arquivo principal" || ((errors++))
    check_string_not_in_file "src/main/resources/application.yml" "auditoria.enabled: true" "Auditoria habilitada no arquivo principal" || ((errors++))
    check_string_not_in_file "src/main/resources/application.yml" "gdpr.compliance.enabled: true" "GDPR habilitado no arquivo principal" || ((errors++))
    
    # Verificar configurações padrão seguras
    check_string_in_file "src/main/resources/application.yml" "AZURE_KEYVAULT_ENABLED:false" "Azure desabilitado por padrão" || ((errors++))
    check_string_in_file "src/main/resources/application.yml" "AUDITORIA_ENABLED:false" "Auditoria desabilitada por padrão" || ((errors++))
    check_string_in_file "src/main/resources/application.yml" "GDPR_COMPLIANCE_ENABLED:false" "GDPR desabilitado por padrão" || ((errors++))
    
    return $errors
}

# Função para verificar estrutura de arquivos
validate_file_structure() {
    log_info "Validando estrutura de arquivos..."
    
    local errors=0
    
    # Verificar arquivos essenciais
    local essential_files=(
        "src/main/resources/application.yml"
        "src/main/resources/application-common.yml"
        "src/main/resources/application-dev.yml"
        "src/main/resources/application-production.yml"
        "src/main/resources/application-azure.yml"
        "src/main/resources/application-local-fallback.yml"
        "src/main/resources/application-os-specific.yml"
        "docker-compose.dev.yml"
        "deploy/docker-compose.prod.yml"
    )
    
    for file in "${essential_files[@]}"; do
        check_file "$file" || ((errors++))
    done
    
    return $errors
}

# Função principal
main() {
    log_info "🔧 Iniciando validação de configurações..."
    log_info "📋 Verificando se a refatoração foi aplicada corretamente"
    echo
    
    local total_errors=0
    
    # Validar estrutura de arquivos
    validate_file_structure
    total_errors=$((total_errors + $?))
    echo
    
    # Validar configuração principal
    validate_main_config
    total_errors=$((total_errors + $?))
    echo
    
    # Validar configurações de desenvolvimento
    validate_dev_config
    total_errors=$((total_errors + $?))
    echo
    
    # Validar configurações de produção
    validate_prod_config
    total_errors=$((total_errors + $?))
    echo
    
    # Validar configurações Azure
    validate_azure_config
    total_errors=$((total_errors + $?))
    echo
    
    # Resultado final
    if [[ $total_errors -eq 0 ]]; then
        log_success "🎉 Todas as validações passaram com sucesso!"
        log_success "✅ A refatoração foi aplicada corretamente"
        log_success "✅ Configurações de desenvolvimento e produção estão separadas"
        log_success "✅ Azure Key Vault configurado com fallback"
        echo
        log_info "📝 Próximos passos:"
        log_info "   1. Testar em ambiente de desenvolvimento"
        log_info "   2. Validar em ambiente de produção"
        log_info "   3. Monitorar logs de fallback"
        exit 0
    else
        log_error "❌ Encontrados $total_errors erro(s) na validação"
        log_error "🔧 Corrija os problemas antes de prosseguir"
        exit 1
    fi
}

# Executar função principal
main "$@" 