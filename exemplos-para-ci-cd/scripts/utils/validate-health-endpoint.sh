#!/bin/bash
# =============================================================================
# SCRIPT DE VALIDAÇÃO DO ENDPOINT DE SAÚDE
# =============================================================================
# Este script valida se o endpoint /actuator/health está acessível
# Uso: ./scripts/utils/validate-health-endpoint.sh [teste|prod]
# =============================================================================

set -euo pipefail

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DEPLOY_TYPE="${1:-teste}"
TIMEOUT=30

echo -e "${BLUE}🔍 VALIDAÇÃO DO ENDPOINT DE SAÚDE${NC}"
echo "=================================="

# Validar parâmetros
if [[ "$DEPLOY_TYPE" != "teste" && "$DEPLOY_TYPE" != "prod" ]]; then
    echo -e "${RED}❌ Tipo de deploy inválido: ${DEPLOY_TYPE}${NC}"
    echo "Uso: $0 [teste|prod]"
    exit 1
fi

# Configurar URLs baseado no tipo de deploy
if [[ "$DEPLOY_TYPE" == "teste" ]]; then
    LOCAL_URL="http://localhost:8081/actuator/health"
    EXTERNAL_URL="https://www.conexaodesorte.com.br/teste/rest/actuator/health"
    CONTAINER_NAME="backend-teste"
else
    LOCAL_URL="http://localhost:8080/actuator/health"
    EXTERNAL_URL="https://www.conexaodesorte.com.br/rest/actuator/health"
    CONTAINER_NAME="backend-prod"
fi

echo -e "${BLUE}🎯 Validando ambiente: ${DEPLOY_TYPE}${NC}"
echo -e "${BLUE}📋 URL local: ${LOCAL_URL}${NC}"
echo -e "${BLUE}📋 URL externa: ${EXTERNAL_URL}${NC}"

# Verificar se container está rodando
echo -e "${BLUE}🔍 Verificando se o container está rodando...${NC}"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}❌ Container ${CONTAINER_NAME} não está em execução${NC}"
    echo "Execute o deploy primeiro"
    exit 1
fi

echo -e "${GREEN}✅ Container ${CONTAINER_NAME} está rodando${NC}"

# Testar acesso local
echo -e "${BLUE}🔍 Testando acesso local...${NC}"
if curl -f -s --connect-timeout "$TIMEOUT" "$LOCAL_URL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Endpoint local acessível: ${LOCAL_URL}${NC}"

    # Mostrar resposta local
    HEALTH_RESPONSE=$(curl -s --connect-timeout "$TIMEOUT" "$LOCAL_URL" 2>/dev/null || echo "{}")
    echo -e "${BLUE}📋 Resposta do health check:${NC}"
    echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Endpoint local não acessível: ${LOCAL_URL}${NC}"
    echo -e "${YELLOW}⚠️ Verifique os logs do container:${NC}"
    docker logs --tail 20 "${CONTAINER_NAME}"
    exit 1
fi

# Testar acesso externo
echo -e "${BLUE}🔍 Testando acesso externo...${NC}"
if curl -f -s --connect-timeout "$TIMEOUT" "$EXTERNAL_URL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Endpoint externo acessível: ${EXTERNAL_URL}${NC}"

    # Mostrar resposta externa
    EXTERNAL_RESPONSE=$(curl -s --connect-timeout "$TIMEOUT" "$EXTERNAL_URL" 2>/dev/null || echo "{}")
    echo -e "${BLUE}📋 Resposta externa do health check:${NC}"
    echo "$EXTERNAL_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$EXTERNAL_RESPONSE"
else
    echo -e "${RED}❌ Endpoint externo não acessível: ${EXTERNAL_URL}${NC}"
    echo -e "${YELLOW}⚠️ Possíveis problemas:${NC}"
    echo "   1. Proxy reverso (Nginx/Load Balancer) não configurado"
    echo "   2. Firewall bloqueando a porta"
    echo "   3. SSL/TLS mal configurado"
    echo "   4. DNS não resolvendo corretamente"

    # Testar conectividade básica
    echo -e "${BLUE}🔍 Testando conectividade básica...${NC}"
    if curl -I -s --connect-timeout 10 "https://www.conexaodesorte.com.br" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ Servidor está acessível, problema específico do endpoint${NC}"
    else
        echo -e "${RED}❌ Servidor não está acessível${NC}"
    fi

    exit 1
fi

echo -e "${GREEN}🎉 Validação do endpoint de saúde concluída com sucesso!${NC}"
echo -e "${GREEN}✅ Ambiente ${DEPLOY_TYPE} está configurado corretamente${NC}"
