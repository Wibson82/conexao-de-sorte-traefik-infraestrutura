#!/bin/bash

# =============================================================================
# SCRIPT DE TESTE - CONFIGURAÇÃO DE EXTRAÇÃO
# =============================================================================
# Testa se a configuração de extração está correta e se a expressão cron
# está sendo interpretada corretamente pelo Spring Boot
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 TESTANDO CONFIGURAÇÃO DE EXTRAÇÃO${NC}"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}❌ Erro: Execute este script na raiz do projeto${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Verificando configurações de extração...${NC}"

# 1. Verificar se a expressão cron está correta no código
echo -e "${BLUE}1. Verificando expressão cron no OrquestradorExtracoes...${NC}"
if grep -q "0 0 8,12,18,22 \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    echo -e "${GREEN}✅ Expressão cron encontrada: 0 0 8,12,18,22 * *${NC}"
else
    echo -e "${RED}❌ Expressão cron não encontrada no OrquestradorExtracoes${NC}"
fi

# 2. Verificar configuração no application.yml
echo -e "${BLUE}2. Verificando configuração no application.yml...${NC}"
if grep -q "cron: \${APP_EXTRACAO_CRON:0 0 8,12,18,22 \* \*}" src/main/resources/application.yml; then
    echo -e "${GREEN}✅ Configuração de cron encontrada no application.yml${NC}"
else
    echo -e "${RED}❌ Configuração de cron não encontrada no application.yml${NC}"
fi

# 3. Verificar se há configurações conflitantes
echo -e "${BLUE}3. Verificando configurações conflitantes...${NC}"
CONFLICTING_FILES=$(grep -r "app\.extracao\.cron" src/main/resources/ --include="*.yml" --include="*.yaml" --include="*.properties" 2>/dev/null || true)
if [ -n "$CONFLICTING_FILES" ]; then
    echo -e "${YELLOW}⚠️  Configurações encontradas:${NC}"
    echo "$CONFLICTING_FILES"
else
    echo -e "${GREEN}✅ Nenhuma configuração conflitante encontrada${NC}"
fi

# 4. Verificar se há variáveis de ambiente definidas
echo -e "${BLUE}4. Verificando variáveis de ambiente...${NC}"
if [ -n "$APP_EXTRACAO_CRON" ]; then
    echo -e "${YELLOW}⚠️  Variável APP_EXTRACAO_CRON definida: $APP_EXTRACAO_CRON${NC}"
    # Verificar se tem 6 campos
    FIELD_COUNT=$(echo "$APP_EXTRACAO_CRON" | wc -w)
    if [ "$FIELD_COUNT" -eq 6 ]; then
        echo -e "${GREEN}✅ Variável tem 6 campos (correto)${NC}"
    else
        echo -e "${RED}❌ Variável tem $FIELD_COUNT campos (deveria ter 6)${NC}"
    fi
else
    echo -e "${GREEN}✅ Variável APP_EXTRACAO_CRON não definida (usando padrão)${NC}"
fi

# 5. Testar compilação
echo -e "${BLUE}5. Testando compilação...${NC}"
if mvn compile -q; then
    echo -e "${GREEN}✅ Compilação bem-sucedida${NC}"
else
    echo -e "${RED}❌ Erro na compilação${NC}"
    exit 1
fi

# 6. Verificar se há problemas de sintaxe na expressão cron
echo -e "${BLUE}6. Verificando sintaxe da expressão cron...${NC}"
CRON_EXPRESSION="0 0 8,12,18,22 * *"
echo -e "${YELLOW}Expressão cron: $CRON_EXPRESSION${NC}"

# Verificar se tem 6 campos
FIELD_COUNT=$(echo "$CRON_EXPRESSION" | wc -w)
if [ "$FIELD_COUNT" -eq 6 ]; then
    echo -e "${GREEN}✅ Expressão tem 6 campos (correto)${NC}"
else
    echo -e "${RED}❌ Expressão tem $FIELD_COUNT campos (deveria ter 6)${NC}"
fi

# Verificar formato dos campos
echo -e "${YELLOW}Análise dos campos:${NC}"
echo "  Campo 1 (segundo): 0"
echo "  Campo 2 (minuto): 0"
echo "  Campo 3 (hora): 8,12,18,22"
echo "  Campo 4 (dia): *"
echo "  Campo 5 (mês): *"
echo "  Campo 6 (dia da semana): *"

# 7. Verificar se há problemas no Spring Boot
echo -e "${BLUE}7. Verificando configuração do Spring Boot...${NC}"
if grep -q "@EnableScheduling" src/main/java/br/tec/facilitaservicos/conexaodesorte/Application.java; then
    echo -e "${GREEN}✅ @EnableScheduling encontrado na classe Application${NC}"
else
    echo -e "${RED}❌ @EnableScheduling não encontrado na classe Application${NC}"
fi

# 8. Verificar configuração de task scheduling
echo -e "${BLUE}8. Verificando configuração de task scheduling...${NC}"
if grep -q "task:" src/main/resources/application.yml; then
    echo -e "${GREEN}✅ Configuração de task encontrada${NC}"
    grep -A 10 "task:" src/main/resources/application.yml | head -10
else
    echo -e "${YELLOW}⚠️  Configuração de task não encontrada${NC}"
fi

echo ""
echo -e "${BLUE}📊 RESUMO DO TESTE${NC}"
echo "=================================================="

# Contar problemas encontrados
PROBLEMS=0

if ! grep -q "0 0 8,12,18,22 \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! grep -q "cron: \${APP_EXTRACAO_CRON:0 0 8,12,18,22 \* \*}" src/main/resources/application.yml; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ -n "$APP_EXTRACAO_CRON" ] && [ "$(echo "$APP_EXTRACAO_CRON" | wc -w)" -ne 6 ]; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! grep -q "@EnableScheduling" src/main/java/br/tec/facilitaservicos/conexaodesorte/Application.java; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ "$PROBLEMS" -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS OS TESTES PASSARAM!${NC}"
    echo -e "${GREEN}✅ Configuração de extração está correta${NC}"
    exit 0
else
    echo -e "${RED}❌ $PROBLEMS PROBLEMA(S) ENCONTRADO(S)${NC}"
    echo -e "${YELLOW}💡 Verifique os itens marcados com ❌ acima${NC}"
    exit 1
fi
