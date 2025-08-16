#!/bin/bash
# =============================================================================
# SCRIPT PARA TESTAR SE O WORKFLOW CI-TEST.YML SERIA EXECUTADO
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

echo "🧪 Teste de Gatilhos do Workflow CI-Test"
echo "========================================"

# Verificar branch atual
current_branch=$(git branch --show-current)
log_info "Branch atual: $current_branch"

# Verificar se a branch corresponde aos padrões do workflow
if [[ "$current_branch" == "develop" ]]; then
    log_success "Branch 'develop' - Workflow DEVE ser executado"
elif [[ "$current_branch" =~ ^feature/.* ]]; then
    log_success "Branch 'feature/*' - Workflow DEVE ser executado"
elif [[ "$current_branch" =~ ^fix/.* ]]; then
    log_success "Branch 'fix/*' - Workflow DEVE ser executado"
elif [[ "$current_branch" =~ ^hotfix/.* ]]; then
    log_success "Branch 'hotfix/*' - Workflow DEVE ser executado"
elif [[ "$current_branch" =~ ^refactor/.* ]]; then
    log_success "Branch 'refactor/*' - Workflow DEVE ser executado"
elif [[ "$current_branch" =~ ^refatoracao-.* ]]; then
    log_success "Branch 'refatoracao-*' - Workflow DEVE ser executado"
else
    log_warning "Branch '$current_branch' - Workflow NÃO será executado"
    echo ""
    echo "📋 Branches que executam o workflow:"
    echo "   - develop"
    echo "   - feature/*"
    echo "   - fix/*"
    echo "   - hotfix/*"
    echo "   - refactor/*"
    echo "   - refatoracao-*"
    echo ""
    echo "💡 Para testar o workflow, mude para uma dessas branches ou execute manualmente:"
    echo "   - Via GitHub Actions UI (workflow_dispatch)"
    echo "   - Criando um PR para main/develop"
    exit 1
fi

# Verificar se há mudanças recentes que ativariam o workflow
log_info "Verificando mudanças recentes..."

# Simular a lógica de detecção de mudanças do workflow
if git diff --name-only HEAD~1 HEAD | grep -E "(src/|pom.xml|Dockerfile\.test|docker-compose\.test\.yml)" > /dev/null; then
    log_success "Mudanças no backend de teste detectadas - Deploy será executado"
elif git diff --name-only HEAD~1 HEAD | grep -E "(\.github/workflows/ci-test\.yml|scripts/.*test.*)" > /dev/null; then
    log_success "Mudanças no deploy de teste detectadas - Deploy será executado"
else
    log_warning "Nenhuma mudança relevante detectada - Deploy pode ser pulado"
    echo ""
    echo "📋 Arquivos que ativam o deploy:"
    echo "   - src/**"
    echo "   - pom.xml"
    echo "   - Dockerfile.test"
    echo "   - docker-compose.test.yml"
    echo "   - .github/workflows/ci-test.yml"
    echo "   - scripts/*test*"
fi

# Verificar se o arquivo do workflow existe e está válido
workflow_file=".github/workflows/ci-test.yml"
if [[ -f "$workflow_file" ]]; then
    log_success "Arquivo do workflow encontrado: $workflow_file"
else
    log_error "Arquivo do workflow não encontrado: $workflow_file"
    exit 1
fi

# Verificar últimos commits
echo ""
log_info "Últimos 3 commits:"
git log --oneline -3

echo ""
log_info "Status do repositório:"
git status --porcelain

echo ""
log_success "🎉 Análise concluída!"
echo ""
echo "📋 Próximos passos para verificar se o workflow foi executado:"
echo "   1. Acesse: https://github.com/Wibson82/conexao-de-sorte-backend/actions"
echo "   2. Procure por execuções do workflow '🧪 CI/CD Teste - Deploy Backend Teste'"
echo "   3. Verifique se há execuções recentes para o commit: $(git rev-parse --short HEAD)"
echo ""
echo "🔧 Para executar manualmente:"
echo "   1. Acesse: https://github.com/Wibson82/conexao-de-sorte-backend/actions/workflows/ci-test.yml"
echo "   2. Clique em 'Run workflow'"
echo "   3. Selecione a branch '$current_branch'"
echo "   4. Configure as opções e execute"
