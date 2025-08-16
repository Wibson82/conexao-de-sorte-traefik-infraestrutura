#!/bin/bash
# =============================================================================
# CORREÇÃO DE CONFIGURAÇÃO AZURE KEY VAULT - AMBIENTE DE TESTE
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔧 CORREÇÃO DE CONFIGURAÇÃO AZURE KEY VAULT"
echo "==========================================="

# 1. Verificar variáveis de ambiente atuais
log_info "1. Verificando variáveis de ambiente do Azure..."
echo ""
docker exec backend-teste env | grep -E "(AZURE|APP_)" | sort || log_warning "Nenhuma variável Azure encontrada"

# 2. Verificar conectividade com Azure Key Vault
log_info "2. Testando conectividade com Azure Key Vault..."
echo ""
if docker exec backend-teste curl -f --connect-timeout 10 "https://conexao-de-sorte-vault.vault.azure.net/" > /dev/null 2>&1; then
    log_success "Azure Key Vault acessível"
else
    log_warning "Azure Key Vault pode não estar acessível"
fi

# 3. Verificar logs específicos do Azure
log_info "3. Verificando logs específicos do Azure Key Vault..."
echo ""
docker logs backend-teste 2>&1 | grep -E "(Azure|KeyVault|Fallback)" | tail -20

# 4. Verificar se secrets estão sendo carregados
log_info "4. Verificando carregamento de secrets..."
echo ""
docker logs backend-teste 2>&1 | grep -E "(secret|jwt|database)" | tail -10

echo ""
log_info "🔧 Análise concluída!"
echo ""
echo "📋 INTERPRETAÇÃO DOS LOGS:"
echo "   ✅ 'Azure Key Vault conectado com sucesso' = Funcionando"
echo "   ⚠️  'ATIVANDO FALLBACK LOCAL' = Usando secrets locais"
echo "   ❌ 'ALERTA CRÍTICO DE SEGURANÇA' = Configuração incorreta"
echo ""
echo "📋 AÇÕES RECOMENDADAS:"
echo "   1. Se fallback ativo: Verificar variáveis AZURE_* no container"
echo "   2. Se secrets locais: Confirmar se é comportamento esperado para teste"
echo "   3. Se crítico: Recriar container com variáveis Azure corretas"
