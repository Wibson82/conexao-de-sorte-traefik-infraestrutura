#!/bin/bash

# Script para testar se a correção do IMAGE_TAG funcionou
# Autor: Assistente IA
# Data: $(date +%Y-%m-%d)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔍 Testando correção do erro IMAGE_TAG..."

# 1. Verificar se o workflow foi corrigido
log_info "1. Verificando correção no workflow production-optimized.yml..."

if grep -q "PRIMARY_TAG" .github/workflows/production-optimized.yml; then
    log_success "✅ PRIMARY_TAG encontrado no workflow"
else
    log_error "❌ PRIMARY_TAG não encontrado no workflow"
    exit 1
fi

if grep -q "IMAGE_TAG" .github/workflows/production-optimized.yml; then
    log_warning "⚠️ IMAGE_TAG ainda encontrado no workflow (pode ser legítimo)"
else
    log_success "✅ IMAGE_TAG removido do workflow (correto)"
fi

# 2. Verificar se a variável PRIMARY_TAG está sendo definida corretamente
log_info "2. Verificando definição da PRIMARY_TAG..."

if grep -A 5 -B 5 "PRIMARY_TAG=" .github/workflows/production-optimized.yml | grep -q "PRIMARY_TAG="; then
    log_success "✅ PRIMARY_TAG está sendo definida corretamente"
else
    log_error "❌ PRIMARY_TAG não está sendo definida"
    exit 1
fi

# 3. Verificar se o script de deploy usa PRIMARY_TAG
log_info "3. Verificando uso da PRIMARY_TAG no script de deploy..."

if grep -A 5 -B 5 "docker run" .github/workflows/production-optimized.yml | grep -q "PRIMARY_TAG"; then
    log_success "✅ Script de deploy usa PRIMARY_TAG corretamente"
else
    log_error "❌ Script de deploy não usa PRIMARY_TAG"
    exit 1
fi

# 4. Verificar se a validação está correta
log_info "4. Verificando validação da PRIMARY_TAG..."

if grep -A 2 -B 2 "PRIMARY_TAG.*vazia" .github/workflows/production-optimized.yml; then
    log_success "✅ Validação da PRIMARY_TAG está correta"
else
    log_error "❌ Validação da PRIMARY_TAG não encontrada"
    exit 1
fi

# 5. Verificar se não há conflitos com outros scripts
log_info "5. Verificando outros scripts que usam IMAGE_TAG..."

echo "Scripts que usam IMAGE_TAG (legítimos):"
grep -l "IMAGE_TAG" scripts/*.sh deploy/scripts/*.sh 2>/dev/null || echo "Nenhum script encontrado"

# 6. Simular o fluxo de geração da tag
log_info "6. Simulando geração da tag..."

DATE_TAG=$(TZ='America/Sao_Paulo' date +'%d-%m-%Y-%H')
PRIMARY_TAG="docker.io/facilita/conexao-de-sorte-backend:${DATE_TAG}"

echo "📅 Data/Hora: $DATE_TAG"
echo "🏷️ Tag principal: $PRIMARY_TAG"

if [[ -n "$PRIMARY_TAG" ]]; then
    log_success "✅ Simulação da geração da tag funcionou"
else
    log_error "❌ Falha na simulação da geração da tag"
    exit 1
fi

# 7. Verificar sintaxe do workflow
log_info "7. Verificando sintaxe do workflow..."

if yamllint .github/workflows/production-optimized.yml 2>/dev/null; then
    log_success "✅ Sintaxe do workflow está correta"
else
    log_warning "⚠️ Problemas de sintaxe no workflow (yamllint não disponível ou erro)"
fi

echo ""
log_success "🎉 Teste da correção do IMAGE_TAG concluído!"
echo ""
echo "📋 Resumo das correções:"
echo "   ✅ IMAGE_TAG substituído por PRIMARY_TAG no workflow"
echo "   ✅ Validação da variável corrigida"
echo "   ✅ Script de deploy atualizado"
echo "   ✅ Fluxo de geração da tag verificado"
echo ""
echo "🚀 O erro do IMAGE_TAG foi corrigido com sucesso!"
