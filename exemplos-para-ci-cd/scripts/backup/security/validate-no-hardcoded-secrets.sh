#!/bin/bash

# Script para validar que não há segredos hardcoded no projeto
# Autor: Sistema de Segurança Automatizado
# Data: 29/07/2025

set -e

# Cores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
ERRORS=0
WARNINGS=0
CHECKS=0

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; ((WARNINGS++)); }
log_error() { echo -e "${RED}❌ $1${NC}"; ((ERRORS++)); }
log_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

log_header "VALIDAÇÃO DE SEGREDOS HARDCODED"

# 1. Verificar senhas hardcoded
log_info "1. Verificando senhas hardcoded..."
((CHECKS++))

HARDCODED_PASSWORDS=$(grep -r -n -E "(password|senha)\s*[:=]\s*[\"'][^\"']{3,}[\"']" \
  src/ scripts/ --include="*.java" --include="*.yml" --include="*.properties" --include="*.sh" \
  | grep -v -E "(test|example|placeholder|\$\{|\#)" || true)

if [[ -n "$HARDCODED_PASSWORDS" ]]; then
    log_error "Senhas hardcoded encontradas:"
    echo "$HARDCODED_PASSWORDS"
else
    log_success "Nenhuma senha hardcoded encontrada"
fi

# 2. Verificar chaves JWT hardcoded
log_info "2. Verificando chaves JWT hardcoded..."
((CHECKS++))

HARDCODED_JWT=$(grep -r -n -E "(jwt|secret|key)\s*[:=]\s*[\"'][^\"']{10,}[\"']" \
  src/ --include="*.java" --include="*.yml" --include="*.properties" \
  | grep -v -E "(test|example|placeholder|\$\{|\#|not-for-production)" || true)

if [[ -n "$HARDCODED_JWT" ]]; then
    log_error "Chaves JWT hardcoded encontradas:"
    echo "$HARDCODED_JWT"
else
    log_success "Nenhuma chave JWT hardcoded encontrada"
fi

# 3. Verificar tokens/API keys hardcoded
log_info "3. Verificando tokens/API keys hardcoded..."
((CHECKS++))

HARDCODED_TOKENS=$(grep -r -n -E "(token|api[_-]?key)\s*[:=]\s*[\"'][^\"']{10,}[\"']" \
  src/ scripts/ --include="*.java" --include="*.yml" --include="*.properties" --include="*.sh" \
  | grep -v -E "(test|example|placeholder|\$\{|\#)" || true)

if [[ -n "$HARDCODED_TOKENS" ]]; then
    log_error "Tokens/API keys hardcoded encontrados:"
    echo "$HARDCODED_TOKENS"
else
    log_success "Nenhum token/API key hardcoded encontrado"
fi

# 4. Verificar URLs com credenciais
log_info "4. Verificando URLs com credenciais..."
((CHECKS++))

URLS_WITH_CREDS=$(grep -r -n -E "(https?://[^:]+:[^@]+@|jdbc:[^:]+://[^:]+:[^@]+@)" \
  src/ scripts/ --include="*.java" --include="*.yml" --include="*.properties" --include="*.sh" \
  | grep -v -E "(test|example|placeholder|\$\{|\#)" || true)

if [[ -n "$URLS_WITH_CREDS" ]]; then
    log_error "URLs com credenciais encontradas:"
    echo "$URLS_WITH_CREDS"
else
    log_success "Nenhuma URL com credenciais encontrada"
fi

# 5. Verificar master passwords hardcoded
log_info "5. Verificando master passwords hardcoded..."
((CHECKS++))

MASTER_PASSWORDS=$(grep -r -n -E "master[_-]?password\s*[:=]\s*[\"'][^\"']{3,}[\"']" \
  src/ --include="*.java" --include="*.yml" --include="*.properties" \
  | grep -v -E "(test|example|placeholder|\$\{|\#)" || true)

if [[ -n "$MASTER_PASSWORDS" ]]; then
    log_error "Master passwords hardcoded encontrados:"
    echo "$MASTER_PASSWORDS"
else
    log_success "Nenhum master password hardcoded encontrado"
fi

# 6. Verificar configurações específicas problemáticas
log_info "6. Verificando configurações específicas..."
((CHECKS++))

# Verificar se ainda há valores de fallback inseguros
INSECURE_FALLBACKS=$(grep -r -n -E "(ci-secret-key|ci-master-password|default-jwt-secret)" \
  src/ --include="*.yml" --include="*.properties" || true)

if [[ -n "$INSECURE_FALLBACKS" ]]; then
    log_error "Fallbacks inseguros encontrados:"
    echo "$INSECURE_FALLBACKS"
else
    log_success "Nenhum fallback inseguro encontrado"
fi

# 7. Verificar se variáveis de ambiente estão sendo usadas corretamente
log_info "7. Verificando uso de variáveis de ambiente..."
((CHECKS++))

# Contar quantas configurações usam variáveis de ambiente
ENV_VAR_COUNT=$(grep -r -c -E "\$\{[A-Z_]+[:\}]" src/ --include="*.yml" --include="*.properties" | \
  awk -F: '{sum += $2} END {print sum}' || echo "0")

if [[ "$ENV_VAR_COUNT" -gt 50 ]]; then
    log_success "Bom uso de variáveis de ambiente ($ENV_VAR_COUNT configurações)"
else
    log_warning "Poucas variáveis de ambiente detectadas ($ENV_VAR_COUNT). Verifique se todas as configurações sensíveis usam variáveis de ambiente"
fi

# 8. Verificar arquivos de configuração críticos
log_info "8. Verificando arquivos de configuração críticos..."
((CHECKS++))

CRITICAL_FILES=(
    "src/main/resources/application.yml"
    "src/main/resources/application-azure.yml"
    "src/main/resources/application-ci.yml"
    "src/main/resources/application-test.yml"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        # Verificar se o arquivo não contém valores hardcoded óbvios
        HARDCODED_IN_FILE=$(grep -n -E "(password|secret|key)\s*:\s*[\"']?[a-zA-Z0-9]{8,}[\"']?\s*$" "$file" | \
          grep -v -E "(\$\{|#|test|example)" || true)
        
        if [[ -n "$HARDCODED_IN_FILE" ]]; then
            log_error "Possíveis valores hardcoded em $file:"
            echo "$HARDCODED_IN_FILE"
        else
            log_success "Arquivo $file parece seguro"
        fi
    else
        log_warning "Arquivo $file não encontrado"
    fi
done

# 9. Verificar scripts de deployment
log_info "9. Verificando scripts de deployment..."
((CHECKS++))

DEPLOYMENT_SCRIPTS=$(find scripts/ -name "*.sh" -type f | head -10)
SCRIPT_ISSUES=0

for script in $DEPLOYMENT_SCRIPTS; do
    if [[ -f "$script" ]]; then
        # Verificar se scripts usam variáveis de ambiente em vez de valores hardcoded
        HARDCODED_IN_SCRIPT=$(grep -n -E "(PASSWORD|SECRET|KEY)\s*=\s*[\"'][^\"']{3,}[\"']" "$script" | \
          grep -v -E "(\$\{|\$[A-Z_]|#|test|example)" || true)
        
        if [[ -n "$HARDCODED_IN_SCRIPT" ]]; then
            log_error "Possíveis valores hardcoded em $script:"
            echo "$HARDCODED_IN_SCRIPT"
            ((SCRIPT_ISSUES++))
        fi
    fi
done

if [[ "$SCRIPT_ISSUES" -eq 0 ]]; then
    log_success "Scripts de deployment parecem seguros"
fi

# 10. Resumo final
log_header "RESUMO DA VALIDAÇÃO"
echo ""
log_info "Verificações realizadas: $CHECKS"

if [[ "$ERRORS" -eq 0 ]]; then
    log_success "✅ NENHUM SEGREDO HARDCODED CRÍTICO ENCONTRADO"
else
    log_error "❌ $ERRORS PROBLEMAS CRÍTICOS ENCONTRADOS"
fi

if [[ "$WARNINGS" -gt 0 ]]; then
    log_warning "⚠️ $WARNINGS AVISOS ENCONTRADOS"
fi

echo ""
log_info "📋 RECOMENDAÇÕES DE SEGURANÇA:"
echo "  1. Sempre usar variáveis de ambiente para valores sensíveis"
echo "  2. Configurar GitHub Secrets para CI/CD"
echo "  3. Usar Azure Key Vault para produção"
echo "  4. Nunca commitar arquivos com credenciais"
echo "  5. Executar este script antes de cada commit"

echo ""
if [[ "$ERRORS" -eq 0 ]]; then
    log_success "🔒 PROJETO APROVADO NA VALIDAÇÃO DE SEGURANÇA"
    exit 0
else
    log_error "🚨 PROJETO REPROVADO - CORRIJA OS PROBLEMAS ANTES DE CONTINUAR"
    exit 1
fi
