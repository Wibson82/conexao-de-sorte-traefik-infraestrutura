#!/bin/bash

# =============================================================================
# SCRIPT DE COMMIT - OTIMIZAÇÕES SERVICOEXTRACAOARMAZENAMENTO
# =============================================================================
# Faz commit das otimizações realizadas na classe ServicoExtracaoArmazenamento
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📝 FAZENDO COMMIT DAS OTIMIZAÇÕES${NC}"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}❌ Erro: Execute este script na raiz do projeto${NC}"
    exit 1
fi

# Verificar se há mudanças para commitar
if git diff --quiet; then
    echo -e "${YELLOW}⚠️  Nenhuma mudança detectada para commitar${NC}"
    exit 0
fi

echo -e "${YELLOW}📋 Resumo das otimizações realizadas:${NC}"
echo "  ✅ Removido import ApplicationContext não utilizado"
echo "  ✅ Removida variável applicationContext não utilizada"
echo "  ✅ Removido parâmetro extracaoAutomaticaHabilitada não utilizado"
echo "  ✅ Removida declaração da variável extracaoAutomaticaHabilitada"
echo "  ✅ Removido método extrairEArmazenarConcursoEspecifico não utilizado"
echo "  ✅ Limpos comentários desnecessários"

echo -e "\n${YELLOW}🔍 Verificando status do git...${NC}"
git status --porcelain

echo -e "\n${BLUE}📝 Adicionando arquivos modificados...${NC}"
git add src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoArmazenamento.java

echo -e "\n${BLUE}📝 Fazendo commit das otimizações...${NC}"
git commit -m "refactor: Otimizar ServicoExtracaoArmazenamento removendo elementos não utilizados

- Remover import ApplicationContext não utilizado
- Remover variável applicationContext não utilizada
- Remover parâmetro extracaoAutomaticaHabilitada não utilizado
- Remover declaração da variável extracaoAutomaticaHabilitada
- Remover método extrairEArmazenarConcursoEspecifico não utilizado
- Limpar comentários desnecessários

Melhoria de performance e limpeza de código seguindo as diretrizes do projeto."

echo -e "\n${GREEN}✅ Commit realizado com sucesso!${NC}"
echo "=================================================="

echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo "  1. Executar testes para validar as otimizações"
echo "  2. Fazer push das mudanças"
echo "  3. Monitorar o comportamento em produção"

echo -e "\n${BLUE}📊 Hash do commit:${NC}"
git rev-parse HEAD
