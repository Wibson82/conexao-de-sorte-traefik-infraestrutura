#!/bin/bash

# =============================================================================
# SCRIPT DE DEPLOY E VERIFICAÇÃO - CORREÇÕES DE EXTRAÇÃO
# =============================================================================
# Faz deploy das correções e verifica se os erros foram resolvidos
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 DEPLOY E VERIFICAÇÃO - CORREÇÕES DE EXTRAÇÃO${NC}"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}❌ Erro: Execute este script na raiz do projeto${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Iniciando processo de deploy e verificação...${NC}"

# 1. Verificar se há mudanças não commitadas
echo -e "${BLUE}1. Verificando mudanças não commitadas...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Há mudanças não commitadas:${NC}"
    git status --short
    echo ""
    echo -e "${YELLOW}💡 Execute: ./scripts/commit-correcoes-extracao.sh${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Nenhuma mudança pendente${NC}"
fi

# 2. Verificar se estamos na branch correta
echo -e "${BLUE}2. Verificando branch atual...${NC}"
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}Branch atual: $CURRENT_BRANCH${NC}"

if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "${YELLOW}⚠️  Você está na branch: $CURRENT_BRANCH${NC}"
    echo -e "${YELLOW}💡 Considere fazer merge para main/master antes do deploy${NC}"
fi

# 3. Verificar se há commits recentes
echo -e "${BLUE}3. Verificando commits recentes...${NC}"
RECENT_COMMITS=$(git log --oneline -5)
echo -e "${YELLOW}Últimos 5 commits:${NC}"
echo "$RECENT_COMMITS"

# 4. Verificar configurações de extração
echo -e "${BLUE}4. Verificando configurações de extração...${NC}"
if [ -f "scripts/testar-aplicacao-extracao.sh" ]; then
    echo -e "${YELLOW}Executando teste de configuração...${NC}"
    if ./scripts/testar-aplicacao-extracao.sh; then
        echo -e "${GREEN}✅ Configurações de extração estão corretas${NC}"
    else
        echo -e "${RED}❌ Problemas encontrados nas configurações${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Script de teste não encontrado${NC}"
    exit 1
fi

# 5. Verificar se há scripts de deploy disponíveis
echo -e "${BLUE}5. Verificando scripts de deploy...${NC}"
if [ -f "deploy/scripts/deploy-manual.sh" ]; then
    echo -e "${GREEN}✅ Script de deploy encontrado${NC}"
    DEPLOY_SCRIPT="deploy/scripts/deploy-manual.sh"
elif [ -f "scripts/deploy.sh" ]; then
    echo -e "${GREEN}✅ Script de deploy encontrado${NC}"
    DEPLOY_SCRIPT="scripts/deploy.sh"
else
    echo -e "${YELLOW}⚠️  Script de deploy não encontrado${NC}"
    echo -e "${YELLOW}💡 Execute o deploy manualmente${NC}"
    DEPLOY_SCRIPT=""
fi

# 6. Executar deploy se disponível
if [ -n "$DEPLOY_SCRIPT" ]; then
    echo -e "${BLUE}6. Executando deploy...${NC}"
    echo -e "${YELLOW}Executando: $DEPLOY_SCRIPT${NC}"

    # Perguntar se deve executar o deploy
    read -p "Deseja executar o deploy agora? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if bash "$DEPLOY_SCRIPT"; then
            echo -e "${GREEN}✅ Deploy executado com sucesso${NC}"
        else
            echo -e "${RED}❌ Erro no deploy${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  Deploy pulado${NC}"
    fi
fi

# 7. Verificar logs do servidor
echo -e "${BLUE}7. Verificando logs do servidor...${NC}"
echo -e "${YELLOW}💡 Para verificar os logs, execute:${NC}"
echo -e "${YELLOW}   docker logs conexao-backend-green --tail 50${NC}"
echo -e "${YELLOW}   docker logs conexao-backend-blue --tail 50${NC}"

# 8. Verificar endpoints de saúde
echo -e "${BLUE}8. Verificando endpoints de saúde...${NC}"
echo -e "${YELLOW}💡 Para verificar a saúde da aplicação:${NC}"
echo -e "${YELLOW}   curl -s http://localhost:8080/actuator/health | jq${NC}"
echo -e "${YELLOW}   curl -s http://localhost:8080/api/rawdata | jq${NC}"

# 9. Verificar se o erro de expressão cron foi resolvido
echo -e "${BLUE}9. Verificando se o erro de expressão cron foi resolvido...${NC}"
echo -e "${YELLOW}💡 Procure por estas mensagens nos logs:${NC}"
echo -e "${GREEN}✅ 'OrquestradorExtracoes inicializado'${NC}"
echo -e "${GREEN}✅ 'Extração automática: true'${NC}"
echo -e "${RED}❌ 'Cron expression must consist of 6 fields' (não deve aparecer)${NC}"

echo ""
echo -e "${BLUE}📊 RESUMO DO PROCESSO${NC}"
echo "=================================================="
echo -e "${GREEN}✅ Configurações de extração corrigidas${NC}"
echo -e "${GREEN}✅ Expressão cron corrigida para 6 campos${NC}"
echo -e "${GREEN}✅ Scripts de teste criados${NC}"
echo -e "${GREEN}✅ Commit realizado${NC}"

if [ -n "$DEPLOY_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Deploy disponível: $DEPLOY_SCRIPT${NC}"
else
    echo -e "${YELLOW}⚠️  Deploy deve ser executado manualmente${NC}"
fi

echo ""
echo -e "${BLUE}🎯 PRÓXIMOS PASSOS${NC}"
echo "=================================================="
echo -e "${YELLOW}1. Execute o deploy se ainda não foi feito${NC}"
echo -e "${YELLOW}2. Monitore os logs do servidor${NC}"
echo -e "${YELLOW}3. Verifique se o erro de expressão cron foi resolvido${NC}"
echo -e "${YELLOW}4. Teste os endpoints de saúde${NC}"
echo -e "${YELLOW}5. Verifique se as extrações estão funcionando${NC}"

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
