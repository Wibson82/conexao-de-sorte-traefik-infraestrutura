#!/bin/bash
# =============================================================================
# SCRIPT DE VALIDAÇÃO DE PORTA - CONEXÃO DE SORTE
# =============================================================================
# Este script valida se a porta configurada está correta de acordo com o tipo de deploy
# Uso: ./scripts/utils/validate-port.sh [teste|prod]
# =============================================================================

set -euo pipefail

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DEPLOY_TYPE="${1:-}"
EXPECTED_PORT=""

# Validar parâmetros
if [[ -z "$DEPLOY_TYPE" ]]; then
    echo -e "${RED}❌ Tipo de deploy não especificado${NC}"
    echo "Uso: $0 [teste|prod]"
    exit 1
fi

# Determinar porta esperada com base no tipo de deploy
if [[ "$DEPLOY_TYPE" == "teste" ]]; then
    EXPECTED_PORT="8081"
    CONTAINER_NAME="backend-teste"
elif [[ "$DEPLOY_TYPE" == "prod" ]]; then
    EXPECTED_PORT="8080"
    CONTAINER_NAME="backend-prod"
else
    echo -e "${RED}❌ Tipo de deploy inválido: ${DEPLOY_TYPE}${NC}"
    echo "Uso: $0 [teste|prod]"
    exit 1
fi

echo -e "${BLUE}🔍 Validando configuração de porta para deploy ${DEPLOY_TYPE}${NC}"
echo -e "${BLUE}📋 Porta esperada: ${EXPECTED_PORT}${NC}"

# Verificar se o container está em execução
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}⚠️ Container ${CONTAINER_NAME} não está em execução${NC}"
    echo "Não é possível validar a porta. O container precisa estar em execução."
    exit 0
fi

# Obter porta configurada no container
CONTAINER_PORT=$(docker exec "${CONTAINER_NAME}" bash -c 'echo $SERVER_PORT' 2>/dev/null || echo "")

if [[ -z "$CONTAINER_PORT" ]]; then
    echo -e "${YELLOW}⚠️ Não foi possível obter a porta configurada no container${NC}"

    # Tentar obter porta de mapeamento do docker
    MAPPED_PORT=$(docker port "${CONTAINER_NAME}" | grep -oE '0.0.0.0:[0-9]+' | cut -d':' -f2 || echo "")

    if [[ -n "$MAPPED_PORT" ]]; then
        echo -e "${BLUE}📋 Porta mapeada no Docker: ${MAPPED_PORT}${NC}"

        if [[ "$MAPPED_PORT" == "$EXPECTED_PORT" ]]; then
            echo -e "${GREEN}✅ A porta mapeada está correta!${NC}"
        else
            echo -e "${RED}❌ A porta mapeada está incorreta!${NC}"
            echo -e "${RED}   Esperado: ${EXPECTED_PORT}, Encontrado: ${MAPPED_PORT}${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️ Não foi possível obter informações de porta do container${NC}"
        exit 0
    fi
else
    echo -e "${BLUE}📋 Porta configurada no container: ${CONTAINER_PORT}${NC}"

    if [[ "$CONTAINER_PORT" == "$EXPECTED_PORT" ]]; then
        echo -e "${GREEN}✅ A porta está configurada corretamente!${NC}"
    else
        echo -e "${RED}❌ A porta está configurada incorretamente!${NC}"
        echo -e "${RED}   Esperado: ${EXPECTED_PORT}, Encontrado: ${CONTAINER_PORT}${NC}"
        exit 1
    fi
fi

# Verificar se a aplicação está respondendo na porta esperada
echo -e "${BLUE}🔍 Verificando resposta da aplicação na porta ${EXPECTED_PORT}...${NC}"

if curl -s -f "http://localhost:${EXPECTED_PORT}/actuator/health" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Aplicação está respondendo na porta ${EXPECTED_PORT}!${NC}"
else
    echo -e "${RED}❌ Aplicação não está respondendo na porta ${EXPECTED_PORT}${NC}"
    echo -e "${YELLOW}⚠️ Verifique os logs do container para mais detalhes${NC}"
    docker logs --tail 50 "${CONTAINER_NAME}"
    exit 1
fi

echo -e "${GREEN}🎉 Validação de porta concluída com sucesso!${NC}"
echo -e "${BLUE}💡 Deploy ${DEPLOY_TYPE} está usando a porta ${EXPECTED_PORT} corretamente${NC}"
