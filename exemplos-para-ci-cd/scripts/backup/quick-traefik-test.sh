#!/bin/bash

# Script de teste rápido do Traefik para CI/CD
# Testa os problemas mais comuns de forma rápida

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🔍 TESTE RÁPIDO TRAEFIK - CI/CD"

# 1. Traefik rodando?
if docker ps --format "table {{.Names}}" | grep -q "traefik"; then
    log_success "Traefik está rodando"
else
    log_error "Traefik não está rodando"
    exit 1
fi

# 2. API do Traefik respondendo?
if curl -s --connect-timeout 5 http://localhost:8080/api/http/routers >/dev/null 2>&1; then
    log_success "API do Traefik OK"
else
    log_error "API do Traefik não responde"
fi

# 3. Conflito de porta 3000?
if netstat -tuln 2>/dev/null | grep -q ":3000 "; then
    log_warning "Porta 3000 em uso - verificar se é o Frontend (Grafana agora usa porta 3001)"
    netstat -tulnp 2>/dev/null | grep ":3000 " || true
else
    log_success "Porta 3000 livre"
fi

# 4. Frontend respondendo?
if curl -s --connect-timeout 10 http://localhost:3000 >/dev/null 2>&1; then
    log_success "Frontend OK (porta 3000)"
else
    log_error "Frontend não responde (porta 3000)"
fi

# 5. Backend respondendo?
if curl -s --connect-timeout 10 http://localhost:8080/actuator/health >/dev/null 2>&1; then
    log_success "Backend OK (porta 8080)"
else
    log_error "Backend não responde (porta 8080)"
fi

# 6. Domínios externos?
for domain in "conexaodesorte.com.br" "www.conexaodesorte.com.br"; do
    if curl -I --connect-timeout 10 "https://$domain" >/dev/null 2>&1; then
        log_success "$domain OK"
    else
        log_error "$domain falhou"
    fi
done

# 7. API externa?
if curl -I --connect-timeout 10 "https://conexaodesorte.com.br/rest/actuator/health" >/dev/null 2>&1; then
    log_success "API externa OK"
else
    log_error "API externa falhou"
fi

echo ""
echo "📊 RESUMO:"
echo "Execute './scripts/fix-port-3000-conflict.sh' se houver conflito de porta"
echo "Execute './scripts/fix-traefik-urgent.sh' se houver problemas gerais"
echo "Execute './scripts/diagnose-traefik-issues.sh' para diagnóstico completo"
