#!/bin/bash

# =============================================================================
# SCRIPT DE COMMIT - CORREÇÃO EXPRESSÃO CRON
# =============================================================================
# Faz commit da correção da expressão cron no OrquestradorExtracoes
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📝 FAZENDO COMMIT DA CORREÇÃO DA EXPRESSÃO CRON${NC}"
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
echo "  ✅ Corrigida expressão cron no OrquestradorExtracoes (5 → 6 campos)"
echo "  ✅ Corrigida configuração no application.yml (5 → 6 campos)"
echo "  ✅ Formato correto: '0 0 8,12,18,22 * * *' (seg min hora dia mês dia-semana)"

echo -e "\n${YELLOW}🔍 Verificando status do git...${NC}"
git status --porcelain

echo -e "\n${BLUE}📝 Adicionando arquivos modificados...${NC}"
git add src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java
git add src/main/resources/application.yml

echo -e "\n${BLUE}📝 Fazendo commit da correção...${NC}"
git commit -m "fix: Corrigir expressão cron inválida no OrquestradorExtracoes

- Corrigir expressão cron de 5 campos para 6 campos no @Scheduled
- Atualizar configuração no application.yml
- Formato correto: '0 0 8,12,18,22 * * *' (seg min hora dia mês dia-semana)
- Resolver erro: 'cron expression must consist of 6 fields'

O erro causava falha na inicialização da aplicação devido à expressão cron
inválida no Spring Boot."

echo -e "\n${GREEN}✅ Commit da correção realizado com sucesso!${NC}"
echo "=================================================="

echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo "  1. Fazer push das mudanças"
echo "  2. Testar inicialização da aplicação"
echo "  3. Verificar se o erro de cron foi resolvido"

echo -e "\n${BLUE}📊 Hash do commit:${NC}"
git rev-parse HEAD
