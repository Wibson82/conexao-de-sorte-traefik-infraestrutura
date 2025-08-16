#!/bin/bash

# =============================================================================
# SCRIPT: Parar Loop Infinito do Container
# =============================================================================
# Objetivo: Parar temporariamente o container que está em loop infinito
# Uso: ./scripts/deploy/stop-loop.sh [teste|prod]
# =============================================================================

set -euo pipefail

# Configurações
DEPLOY_TYPE="${1:-teste}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🛑 PARANDO LOOP INFINITO DO CONTAINER${NC}"
echo "=================================="

# Determinar nome do container
if [[ "${DEPLOY_TYPE}" == "teste" ]]; then
    CONTAINER_NAME="backend-teste"
elif [[ "${DEPLOY_TYPE}" == "prod" ]]; then
    CONTAINER_NAME="backend-prod"
else
    echo -e "${RED}❌ Tipo de deploy inválido: ${DEPLOY_TYPE}${NC}"
    echo "Uso: $0 [teste|prod]"
    exit 1
fi

echo -e "${BLUE}🔍 Verificando container: ${CONTAINER_NAME}${NC}"

# Verificar se container existe
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}⚠️ Container ${CONTAINER_NAME} não encontrado${NC}"
    exit 0
fi

# Mostrar status atual
echo -e "${BLUE}📊 Status atual:${NC}"
docker ps -a --filter name="${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.RunningFor}}'

# Parar container
echo -e "${YELLOW}🛑 Parando container ${CONTAINER_NAME}...${NC}"
if docker stop "${CONTAINER_NAME}" 2>/dev/null; then
    echo -e "${GREEN}✅ Container ${CONTAINER_NAME} parado com sucesso${NC}"
else
    echo -e "${RED}❌ Falha ao parar container ${CONTAINER_NAME}${NC}"
    exit 1
fi

# Remover container para evitar restart automático
echo -e "${YELLOW}🗑️ Removendo container ${CONTAINER_NAME}...${NC}"
if docker rm "${CONTAINER_NAME}" 2>/dev/null; then
    echo -e "${GREEN}✅ Container ${CONTAINER_NAME} removido com sucesso${NC}"
else
    echo -e "${RED}❌ Falha ao remover container ${CONTAINER_NAME}${NC}"
    exit 1
fi

# Verificar se há outros containers em loop
echo -e "${BLUE}🔍 Verificando outros containers...${NC}"
LOOP_CONTAINERS=$(docker ps --filter "status=restarting" --format '{{.Names}}' || true)
if [[ -n "${LOOP_CONTAINERS}" ]]; then
    echo -e "${YELLOW}⚠️ Containers em loop encontrados:${NC}"
    echo "${LOOP_CONTAINERS}"
    echo -e "${YELLOW}💡 Execute este script para cada container se necessário${NC}"
else
    echo -e "${GREEN}✅ Nenhum outro container em loop encontrado${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Loop infinito interrompido com sucesso!${NC}"
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo "   1. Execute o workflow de deploy para aplicar as correções"
echo "   2. Monitore os logs do novo container"
echo "   3. Verifique se as chaves JWT são carregadas corretamente"
echo ""
echo -e "${YELLOW}🔗 Workflow de deploy:${NC}"
echo "   https://github.com/Wibson82/conexao-de-sorte-backend/actions/workflows/deploy-unified.yml"
