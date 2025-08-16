#!/bin/bash

# =============================================================================
# LIMPEZA DE CONTAINERS E IMAGENS ANTIGAS
# =============================================================================
# Este script limpa containers parados e imagens antigas
# mantendo apenas as 2 versões mais recentes de cada serviço
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

log_info "🧹 Iniciando limpeza de containers e imagens antigas..."

# =============================================================================
# REMOVER CONTAINERS PARADOS
# =============================================================================
log_info "🛑 Removendo containers parados..."

# Listar containers parados
STOPPED_CONTAINERS=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | grep -E "(backend-prod|backend-teste)" || echo "")

if [[ -n "$STOPPED_CONTAINERS" ]]; then
    echo "📋 Containers parados encontrados:"
    echo "$STOPPED_CONTAINERS"
    
    # Remover containers parados
    echo "$STOPPED_CONTAINERS" | xargs -r docker rm
    log_success "Containers parados removidos"
else
    log_info "Nenhum container parado encontrado"
fi

# =============================================================================
# LIMPAR IMAGENS ANTIGAS - BACKEND PRODUÇÃO
# =============================================================================
log_info "🧹 Limpando imagens antigas do backend de produção..."

# Listar imagens do backend de produção (ordenadas por data, mais recentes primeiro)
PROD_IMAGES=$(docker images facilita/conexao-de-sorte-backend --format "{{.Repository}}:{{.Tag}}" | grep -v "latest" | head -10 || echo "")

if [[ -n "$PROD_IMAGES" ]]; then
    echo "📋 Imagens de produção encontradas:"
    echo "$PROD_IMAGES"
    
    # Manter apenas as 2 mais recentes
    OLD_PROD_IMAGES=$(echo "$PROD_IMAGES" | tail -n +3 || echo "")
    
    if [[ -n "$OLD_PROD_IMAGES" ]]; then
        echo "🗑️ Removendo imagens antigas de produção:"
        echo "$OLD_PROD_IMAGES"
        echo "$OLD_PROD_IMAGES" | xargs -r docker rmi 2>/dev/null || true
        log_success "Imagens antigas de produção removidas"
    else
        log_info "Apenas 2 ou menos imagens de produção - nada para remover"
    fi
else
    log_info "Nenhuma imagem de produção encontrada"
fi

# =============================================================================
# LIMPAR IMAGENS ANTIGAS - BACKEND TESTE
# =============================================================================
log_info "🧹 Limpando imagens antigas do backend de teste..."

# Listar imagens do backend de teste (ordenadas por data, mais recentes primeiro)
TEST_IMAGES=$(docker images facilita/conexao-de-sorte-backend-teste --format "{{.Repository}}:{{.Tag}}" | grep -v "latest" | head -10 || echo "")

if [[ -n "$TEST_IMAGES" ]]; then
    echo "📋 Imagens de teste encontradas:"
    echo "$TEST_IMAGES"
    
    # Manter apenas as 2 mais recentes
    OLD_TEST_IMAGES=$(echo "$TEST_IMAGES" | tail -n +3 || echo "")
    
    if [[ -n "$OLD_TEST_IMAGES" ]]; then
        echo "🗑️ Removendo imagens antigas de teste:"
        echo "$OLD_TEST_IMAGES"
        echo "$OLD_TEST_IMAGES" | xargs -r docker rmi 2>/dev/null || true
        log_success "Imagens antigas de teste removidas"
    else
        log_info "Apenas 2 ou menos imagens de teste - nada para remover"
    fi
else
    log_info "Nenhuma imagem de teste encontrada"
fi

# =============================================================================
# LIMPAR IMAGENS ÓRFÃS
# =============================================================================
log_info "🧹 Limpando imagens órfãs (dangling)..."

DANGLING_IMAGES=$(docker images -f "dangling=true" -q || echo "")

if [[ -n "$DANGLING_IMAGES" ]]; then
    echo "🗑️ Removendo imagens órfãs:"
    echo "$DANGLING_IMAGES" | xargs -r docker rmi 2>/dev/null || true
    log_success "Imagens órfãs removidas"
else
    log_info "Nenhuma imagem órfã encontrada"
fi

# =============================================================================
# RESUMO DA LIMPEZA
# =============================================================================
log_success "🎉 Limpeza concluída!"

echo ""
echo "📊 RESUMO DA LIMPEZA:"
echo "===================="
echo ""

# Status atual dos containers
echo "🐳 Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | head -10

echo ""
echo "📦 Imagens restantes:"

# Imagens de produção
REMAINING_PROD=$(docker images facilita/conexao-de-sorte-backend --format "{{.Repository}}:{{.Tag}}" | wc -l || echo "0")
echo "   Backend Produção: $REMAINING_PROD imagens"

# Imagens de teste
REMAINING_TEST=$(docker images facilita/conexao-de-sorte-backend-teste --format "{{.Repository}}:{{.Tag}}" | wc -l || echo "0")
echo "   Backend Teste: $REMAINING_TEST imagens"

# Espaço liberado
echo ""
echo "💾 Espaço em disco:"
df -h / | tail -1 | awk '{print "   Uso do disco: " $5 " (" $3 " usado de " $2 ")"}'

echo ""
echo "💡 RECOMENDAÇÕES:"
echo "   - Execute este script regularmente para manter o sistema limpo"
echo "   - Mantenha sempre apenas 2-3 versões mais recentes de cada imagem"
echo "   - Monitore o uso de disco para evitar problemas de espaço"

log_success "✅ Limpeza concluída com sucesso!"
