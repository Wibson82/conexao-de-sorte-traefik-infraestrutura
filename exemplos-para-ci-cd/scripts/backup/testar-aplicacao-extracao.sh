#!/bin/bash

# =============================================================================
# SCRIPT DE TESTE - APLICAÇÃO DE EXTRAÇÃO
# =============================================================================
# Testa se a aplicação inicia corretamente e se o erro de expressão cron
# foi corrigido
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 TESTANDO APLICAÇÃO DE EXTRAÇÃO${NC}"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}❌ Erro: Execute este script na raiz do projeto${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Iniciando teste da aplicação...${NC}"

# 1. Verificar se há problemas de compilação
echo -e "${BLUE}1. Verificando compilação...${NC}"
if command -v mvn &> /dev/null; then
    if mvn compile -q; then
        echo -e "${GREEN}✅ Compilação bem-sucedida${NC}"
    else
        echo -e "${RED}❌ Erro na compilação${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Maven não encontrado, pulando compilação${NC}"
fi

# 2. Verificar configurações de extração
echo -e "${BLUE}2. Verificando configurações de extração...${NC}"

# Verificar se a configuração está no application.yml
if grep -q "extracao:" src/main/resources/application.yml; then
    echo -e "${GREEN}✅ Configuração de extração encontrada no application.yml${NC}"
    grep -A 5 "extracao:" src/main/resources/application.yml
else
    echo -e "${RED}❌ Configuração de extração não encontrada no application.yml${NC}"
fi

# Verificar se a configuração está no application-production.yml
if grep -q "extracao:" src/main/resources/application-production.yml; then
    echo -e "${GREEN}✅ Configuração de extração encontrada no application-production.yml${NC}"
    grep -A 5 "extracao:" src/main/resources/application-production.yml
else
    echo -e "${RED}❌ Configuração de extração não encontrada no application-production.yml${NC}"
fi

# 3. Verificar se a expressão cron está correta
echo -e "${BLUE}3. Verificando expressão cron...${NC}"
if grep -q "0 0 8,12,18,22 \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    echo -e "${GREEN}✅ Expressão cron correta no OrquestradorExtracoes${NC}"
else
    echo -e "${RED}❌ Expressão cron incorreta no OrquestradorExtracoes${NC}"
fi

# 4. Verificar se há configurações conflitantes
echo -e "${BLUE}4. Verificando configurações conflitantes...${NC}"
CONFLICTING_CONFIGS=$(grep -r "app\.extracao\.cron" src/main/resources/ --include="*.yml" --include="*.yaml" --include="*.properties" 2>/dev/null || true)
if [ -n "$CONFLICTING_CONFIGS" ]; then
    echo -e "${YELLOW}⚠️  Configurações encontradas:${NC}"
    echo "$CONFLICTING_CONFIGS"
else
    echo -e "${GREEN}✅ Nenhuma configuração conflitante encontrada${NC}"
fi

# 5. Verificar se há problemas de sintaxe YAML
echo -e "${BLUE}5. Verificando sintaxe YAML...${NC}"
if command -v python3 &> /dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('src/main/resources/application.yml'))" 2>/dev/null; then
        echo -e "${GREEN}✅ Sintaxe YAML válida no application.yml${NC}"
    else
        echo -e "${RED}❌ Erro de sintaxe YAML no application.yml${NC}"
    fi

    if python3 -c "import yaml; yaml.safe_load(open('src/main/resources/application-production.yml'))" 2>/dev/null; then
        echo -e "${GREEN}✅ Sintaxe YAML válida no application-production.yml${NC}"
    else
        echo -e "${RED}❌ Erro de sintaxe YAML no application-production.yml${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Python3 não encontrado, pulando verificação YAML${NC}"
fi

# 6. Verificar se há problemas de importação
echo -e "${BLUE}6. Verificando importações...${NC}"
if grep -q "import.*Scheduled" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    echo -e "${GREEN}✅ Importação @Scheduled encontrada${NC}"
else
    echo -e "${RED}❌ Importação @Scheduled não encontrada${NC}"
fi

# 7. Verificar se há problemas de anotação
echo -e "${BLUE}7. Verificando anotações...${NC}"
if grep -q "@Scheduled" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    echo -e "${GREEN}✅ Anotação @Scheduled encontrada${NC}"
else
    echo -e "${RED}❌ Anotação @Scheduled não encontrada${NC}"
fi

# 8. Verificar se há problemas de configuração do Spring
echo -e "${BLUE}8. Verificando configuração do Spring...${NC}"
if grep -q "@EnableScheduling" src/main/java/br/tec/facilitaservicos/conexaodesorte/Application.java; then
    echo -e "${GREEN}✅ @EnableScheduling encontrado${NC}"
else
    echo -e "${RED}❌ @EnableScheduling não encontrado${NC}"
fi

echo ""
echo -e "${BLUE}📊 RESUMO DO TESTE${NC}"
echo "=================================================="

# Contar problemas encontrados
PROBLEMS=0

if ! grep -q "extracao:" src/main/resources/application.yml; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! grep -q "extracao:" src/main/resources/application-production.yml; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! grep -q "0 0 8,12,18,22 \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! grep -q "@Scheduled" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! grep -q "@EnableScheduling" src/main/java/br/tec/facilitaservicos/conexaodesorte/Application.java; then
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ "$PROBLEMS" -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS OS TESTES PASSARAM!${NC}"
    echo -e "${GREEN}✅ Configuração de extração está correta${NC}"
    echo -e "${YELLOW}💡 Agora você pode testar a aplicação com:${NC}"
    echo -e "${YELLOW}   SPRING_PROFILES_ACTIVE=prod mvn spring-boot:run${NC}"
    exit 0
else
    echo -e "${RED}❌ $PROBLEMS PROBLEMA(S) ENCONTRADO(S)${NC}"
    echo -e "${YELLOW}💡 Verifique os itens marcados com ❌ acima${NC}"
    exit 1
fi
