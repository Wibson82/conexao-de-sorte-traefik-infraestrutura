#!/bin/bash

# =============================================================================
# SCRIPT DE COMMIT - CORREÇÕES DE EXTRAÇÃO
# =============================================================================
# Faz commit das correções relacionadas à configuração de extração
# e expressão cron
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📝 FAZENDO COMMIT DAS CORREÇÕES DE EXTRAÇÃO${NC}"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}❌ Erro: Execute este script na raiz do projeto${NC}"
    exit 1
fi

# Verificar se há mudanças para commitar
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Nenhuma mudança para commitar${NC}"
    exit 0
fi

echo -e "${YELLOW}📋 Verificando mudanças...${NC}"

# Mostrar status das mudanças
echo -e "${BLUE}Status das mudanças:${NC}"
git status --short

echo ""

# Verificar se há arquivos específicos modificados
MODIFIED_FILES=$(git status --porcelain | grep -E "\.(java|yml|yaml|properties)$" | wc -l)

if [ "$MODIFIED_FILES" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Nenhum arquivo de configuração modificado${NC}"
    exit 0
fi

echo -e "${BLUE}📁 Arquivos modificados:${NC}"
git status --porcelain | grep -E "\.(java|yml|yaml|properties)$"

echo ""

# Adicionar arquivos modificados
echo -e "${YELLOW}📦 Adicionando arquivos...${NC}"
git add .

# Verificar se há arquivos para commitar
if [ -z "$(git diff --cached --name-only)" ]; then
    echo -e "${YELLOW}⚠️  Nenhum arquivo para commitar${NC}"
    exit 0
fi

# Criar mensagem de commit
COMMIT_MESSAGE="fix: Corrigir configuração de extração e expressão cron

- Adicionar configuração explícita de extração no application.yml
- Adicionar configuração de extração no application-production.yml
- Corrigir expressão cron para formato Spring Boot (6 campos)
- Adicionar scripts de teste para configuração de extração
- Verificar sintaxe YAML e configurações do Spring Boot

Resolve erro: 'Cron expression must consist of 6 fields (found 5)'
Melhora: Configuração centralizada de extração
Testa: Scripts de validação de configuração"

echo -e "${BLUE}💬 Mensagem de commit:${NC}"
echo "$COMMIT_MESSAGE"
echo ""

# Fazer commit
echo -e "${YELLOW}📝 Fazendo commit...${NC}"
git commit -m "$COMMIT_MESSAGE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Commit realizado com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}📊 Resumo do commit:${NC}"
    echo "=================================================="
    echo -e "${GREEN}✅ Arquivos modificados:${NC}"
    git diff --cached --name-only
    echo ""
    echo -e "${GREEN}✅ Hash do commit:${NC}"
    git rev-parse HEAD
    echo ""
    echo -e "${YELLOW}💡 Para fazer push: git push origin main${NC}"
else
    echo -e "${RED}❌ Erro ao fazer commit${NC}"
    exit 1
fi
