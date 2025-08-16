#!/bin/bash
# =============================================================================
# SCRIPT: Validação Pós-Deploy
# =============================================================================
# Objetivo: Validar se o deploy foi realizado com sucesso, verificando a porta correta
# Uso: ./scripts/deploy/run-validation.sh [teste|prod]
# =============================================================================

set -euo pipefail

# Configurações
DEPLOY_TYPE="${1:-teste}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 VALIDAÇÃO DE DEPLOY - CONEXÃO DE SORTE${NC}"
echo "=================================="

# Validar parâmetros
if [[ -z "$DEPLOY_TYPE" ]]; then
    echo -e "${RED}❌ Tipo de deploy não especificado${NC}"
    echo "Uso: $0 [teste|prod]"
    exit 1
fi

# Configurar porta esperada
if [[ "${DEPLOY_TYPE}" == "teste" ]]; then
    CONTAINER_NAME="backend-teste"
    EXPECTED_PORT="8081"
elif [[ "${DEPLOY_TYPE}" == "prod" ]]; then
    CONTAINER_NAME="backend-prod"
    EXPECTED_PORT="8080"
else
    echo -e "${RED}❌ Tipo de deploy inválido: ${DEPLOY_TYPE}${NC}"
    echo "Uso: $0 [teste|prod]"
    exit 1
fi

echo -e "${BLUE}🔍 Validando deploy do tipo: ${DEPLOY_TYPE}${NC}"
echo -e "${BLUE}🔍 Porta esperada: ${EXPECTED_PORT}${NC}"

# Verificar se container está em execução
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}❌ Container ${CONTAINER_NAME} não está em execução${NC}"
    echo "Verifique os logs do container para mais detalhes"
    docker ps -a --filter name="${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    exit 1
fi

# Executar script de validação
if [[ -f "/app/validate-port.sh" ]]; then
    echo -e "${BLUE}🔧 Executando script de validação de porta...${NC}"
    /app/validate-port.sh "${DEPLOY_TYPE}"
else
    echo -e "${YELLOW}⚠️ Script de validação não encontrado${NC}"

    # Verificar porta através de curl
    echo -e "${BLUE}🔍 Verificando resposta da aplicação na porta ${EXPECTED_PORT}...${NC}"
    if curl -s -f "http://localhost:${EXPECTED_PORT}/actuator/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Aplicação está respondendo na porta ${EXPECTED_PORT}!${NC}"
    else
        echo -e "${RED}❌ Aplicação não está respondendo na porta ${EXPECTED_PORT}${NC}"
        echo -e "${YELLOW}⚠️ Verifique os logs do container para mais detalhes${NC}"
        docker logs --tail 50 "${CONTAINER_NAME}"
        exit 1
    fi
fi

echo -e "${GREEN}🎉 Validação de deploy concluída com sucesso!${NC}"
echo -e "${BLUE}💡 Informações do container:${NC}"
docker ps --filter name="${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}'

echo -e "${GREEN}✅ O deploy para o ambiente ${DEPLOY_TYPE} está utilizando a porta ${EXPECTED_PORT} conforme esperado!${NC}"
