#!/bin/bash

# =============================================================================
# SCRIPT DE COMMIT - CORREÇÃO DA OTIMIZAÇÃO
# =============================================================================
# Faz commit da correção da otimização problemática da classe ServicoExtracaoArmazenamento
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📝 FAZENDO COMMIT DA CORREÇÃO DA OTIMIZAÇÃO${NC}"
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

echo -e "${YELLOW}📋 Resumo da correção realizada:${NC}"
echo "  ✅ Revertida remoção da variável 'extracaoAutomaticaHabilitada'"
echo "  ✅ Adicionado import @Value de volta"
echo "  ✅ Restaurado parâmetro no construtor"
echo "  ✅ Adicionada verificação de habilitação no método principal"
echo "  ✅ Mantidas as outras otimizações válidas"

echo -e "\n${YELLOW}🔍 Verificando status do git...${NC}"
git status --porcelain

echo -e "\n${BLUE}📝 Adicionando arquivos modificados...${NC}"
git add src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoArmazenamento.java

echo -e "\n${BLUE}📝 Fazendo commit da correção...${NC}"
git commit -m "fix: Corrigir otimização problemática em ServicoExtracaoArmazenamento

- Reverter remoção da variável 'extracaoAutomaticaHabilitada' (era necessária)
- Adicionar verificação de habilitação no método extrairEArmazenarResultado
- Manter configuração de ambiente para controle de extrações
- Preservar flexibilidade operacional em produção

A remoção anterior foi prematura pois a variável é necessária para:
- Controle de feature flag por ambiente
- Desabilitar extrações temporariamente
- Configuração específica de produção"

echo -e "\n${GREEN}✅ Commit da correção realizado com sucesso!${NC}"
echo "=================================================="

echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo "  1. Executar testes para validar a correção"
echo "  2. Fazer push das mudanças"
echo "  3. Monitorar o comportamento em produção"

echo -e "\n${BLUE}📊 Hash do commit:${NC}"
git rev-parse HEAD
