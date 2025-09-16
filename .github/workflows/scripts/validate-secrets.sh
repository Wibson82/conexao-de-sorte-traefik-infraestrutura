#!/bin/bash
# =============================================================================
# 🔐 SCRIPT DE VALIDAÇÃO DE SECRETS - TRAEFIK INFRASTRUCTURE
# =============================================================================
# Consolida todas as verificações de secrets em um único script reutilizável
# Compatível com OIDC e Docker Swarm
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    local level=$1
    shift
    case $level in
        "INFO")  echo -e "${BLUE}ℹ️  $*${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $*${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $*${NC}" ;;
        "ERROR") echo -e "${RED}❌ $*${NC}" ;;
    esac
}

# Função para validar secrets críticos
validate_critical_secrets() {
    log "INFO" "Validando Docker Secrets críticos para Traefik (OIDC-Only)..."
    
    # Lista de secrets críticos para Traefik (nomenclatura UPPERCASE dos Docker Secrets)
    local CRITICAL_SECRETS=(
        "CORS_ALLOWED_ORIGINS"
        "SSL_ENABLED"
        "SSL_KEYSTORE_PASSWORD"
        "JWT_VERIFICATION_KEY"
    )
    
    local MISSING_CRITICAL=""
    
    log "INFO" "Verificando secrets CRÍTICOS:"
    for secret in "${CRITICAL_SECRETS[@]}"; do
        if docker secret inspect "$secret" >/dev/null 2>&1; then
            log "SUCCESS" "$secret: Disponível"
        else
            log "ERROR" "$secret: CRÍTICO AUSENTE"
            MISSING_CRITICAL="$MISSING_CRITICAL $secret"
        fi
    done
    
    if [[ -n "$MISSING_CRITICAL" ]]; then
        log "ERROR" "ERRO CRÍTICO: Secrets obrigatórios ausentes:$MISSING_CRITICAL"
        log "ERROR" "🔧 SOLUÇÃO: Execute infraestrutura-core pipeline para sincronizar todos os secrets"
        log "ERROR" "📋 Aguarde infraestrutura-core sincronizar antes de prosseguir com Traefik"
        return 1
    else
        log "SUCCESS" "Todos os secrets críticos para Traefik estão disponíveis"
        return 0
    fi
}

# Função para validar secrets opcionais
validate_optional_secrets() {
    log "INFO" "Verificando secrets OPCIONAIS:"
    
    local OPTIONAL_SECRETS=(
        "CORS_ALLOW_CREDENTIALS"
        "SSL_KEYSTORE_PATH"
        "JWT_SIGNING_KEY"
    )
    
    for secret in "${OPTIONAL_SECRETS[@]}"; do
        if docker secret inspect "$secret" >/dev/null 2>&1; then
            log "SUCCESS" "$secret: Disponível (opcional)"
        else
            log "WARNING" "$secret: Ausente (opcional)"
        fi
    done
}

# Função para validar variáveis Azure Key Vault
validate_azure_keyvault() {
    log "INFO" "Validando configurações Azure Key Vault..."
    
    local AZURE_VARS=(
        "AZURE_CLIENT_ID"
        "AZURE_TENANT_ID"
        "AZURE_KEYVAULT_ENDPOINT"
    )
    
    local MISSING_AZURE=""
    
    for var in "${AZURE_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log "ERROR" "$var: Variável Azure Key Vault ausente"
            MISSING_AZURE="$MISSING_AZURE $var"
        else
            log "SUCCESS" "$var: Configurado"
        fi
    done
    
    if [[ -n "$MISSING_AZURE" ]]; then
        log "ERROR" "ERRO: Variáveis Azure Key Vault ausentes:$MISSING_AZURE"
        log "ERROR" "🔧 Configure as variáveis no arquivo .env ou via secrets do runner"
        return 1
    else
        log "SUCCESS" "Todas as variáveis Azure Key Vault estão configuradas"
        return 0
    fi
}

# Função principal
main() {
    log "INFO" "🔐 Iniciando validação completa de secrets para Traefik..."
    echo ""
    
    local exit_code=0
    
    # Validar secrets críticos
    if ! validate_critical_secrets; then
        exit_code=1
    fi
    
    echo ""
    
    # Validar secrets opcionais (não falha o build)
    validate_optional_secrets
    
    echo ""
    
    # Validar Azure Key Vault
    if ! validate_azure_keyvault; then
        exit_code=1
    fi
    
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        log "SUCCESS" "🎉 Validação de secrets concluída com sucesso!"
        log "INFO" "✅ Traefik está pronto para deploy seguro"
    else
        log "ERROR" "💥 Validação de secrets falhou!"
        log "ERROR" "🚫 Deploy do Traefik não pode prosseguir"
    fi
    
    return $exit_code
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi