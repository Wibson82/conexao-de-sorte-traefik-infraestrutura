#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🔒 TRAEFIK SECURITY VALIDATION SCRIPT
# =============================================================================
# Validates critical security configurations for Traefik infrastructure

echo "🔒 Iniciando validação de segurança do Traefik..."

SCORE=0
TOTAL=8
CRITICAL_FAILURES=0

# =============================================================================
# Helper Functions
# =============================================================================
check_passed() {
    local description="$1"
    echo "✅ $description"
    SCORE=$((SCORE + 1))
}

check_failed() {
    local description="$1"
    local is_critical="${2:-false}"
    echo "❌ $description"
    if [ "$is_critical" = "true" ]; then
        CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
    fi
}

check_warning() {
    local description="$1"
    echo "⚠️  $description"
}

# =============================================================================
# Security Checks
# =============================================================================

echo ""
echo "📋 Executando verificações de segurança..."

# 1. HTTPS Configuration
echo ""
echo "🔐 [1/8] Verificando configuração HTTPS..."
if grep -q "websecure" traefik/traefik.yml && grep -q "443" traefik/traefik.yml; then
    check_passed "HTTPS configurado corretamente"
else
    check_failed "HTTPS não configurado adequadamente" true
fi

# 2. Let's Encrypt Configuration
echo ""
echo "🔐 [2/8] Verificando Let's Encrypt..."
if grep -q "letsencrypt" traefik/traefik.yml && grep -q "httpChallenge" traefik/traefik.yml; then
    check_passed "Let's Encrypt configurado"
else
    check_failed "Let's Encrypt não configurado" true
fi

# 3. Security Headers
echo ""
echo "🔐 [3/8] Verificando Security Headers..."
if [ -f "traefik/dynamic/security-headers.yml" ] && grep -q "Strict-Transport-Security" traefik/dynamic/security-headers.yml; then
    check_passed "Security Headers configurados"
else
    check_failed "Security Headers inadequados" true
fi

# 4. Rate Limiting
echo ""
echo "🔐 [4/8] Verificando Rate Limiting..."
if [ -f "traefik/dynamic/middlewares.yml" ] && grep -q "rateLimit" traefik/dynamic/middlewares.yml; then
    check_passed "Rate Limiting configurado"
else
    check_failed "Rate Limiting não configurado"
fi

# 5. TLS Minimum Version
echo ""
echo "🔐 [5/8] Verificando versão mínima TLS..."
if [ -f "traefik/dynamic/tls.yml" ] && grep -q "VersionTLS12" traefik/dynamic/tls.yml; then
    check_passed "TLS versão mínima configurada (TLS 1.2+)"
else
    check_failed "TLS versão mínima não configurada"
fi

# 6. Access Logs
echo ""
echo "🔐 [6/8] Verificando logs de acesso..."
if grep -q "accessLog" traefik/traefik.yml; then
    check_passed "Logs de acesso habilitados"
else
    check_failed "Logs de acesso não habilitados"
fi

# 7. Dashboard Security
echo ""
echo "🔐 [7/8] Verificando segurança do dashboard..."
if grep -q "insecure.*false" traefik/traefik.yml || ! grep -q "insecure.*true" traefik/traefik.yml; then
    check_passed "Dashboard seguro (não inseguro)"
else
    check_failed "Dashboard inseguro detectado" true
fi

# 8. Container Healthcheck
echo ""
echo "🔐 [8/8] Verificando healthcheck do container..."
if grep -q "healthcheck" docker-compose.yml; then
    check_passed "Healthcheck configurado"
else
    check_failed "Healthcheck não configurado"
fi

# =============================================================================
# Results Summary
# =============================================================================
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "📊 RESULTADO DA VALIDAÇÃO DE SEGURANÇA"
echo "════════════════════════════════════════════════════════════════════"

PERCENTAGE=$(( SCORE * 100 / TOTAL ))
echo "🎯 Score de Segurança: $SCORE/$TOTAL ($PERCENTAGE%)"

if [ $CRITICAL_FAILURES -gt 0 ]; then
    echo "🚨 FALHAS CRÍTICAS: $CRITICAL_FAILURES"
    echo ""
    echo "❌ DEPLOY BLOQUEADO: Corrija as falhas críticas antes de prosseguir"
    exit 1
elif [ $SCORE -lt 6 ]; then
    echo "⚠️  Score de segurança baixo ($PERCENTAGE%)"
    echo ""
    echo "🔶 DEPLOY COM ALERTA: Considere melhorar as configurações de segurança"
    exit 2
else
    echo "✅ SEGURANÇA APROVADA: Configurações adequadas para produção"
    echo ""
    echo "🎉 Deploy autorizado com score de segurança: $PERCENTAGE%"
fi

echo ""
echo "💡 Para melhorar o score de segurança:"
echo "   - Configure todos os middlewares de segurança"
echo "   - Habilite logs de acesso para auditoria"
echo "   - Implemente rate limiting robusto"
echo "   - Configure healthchecks adequados"
echo ""