#!/bin/bash

# =============================================================================
# TESTE DE CARGA SIMPLIFICADO PARA VERIFICAÇÃO LOCAL
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 TESTE DE CARGA SIMPLIFICADO - CONEXÃO DE SORTE${NC}"
echo -e "${BLUE}================================================${NC}"

# Configurações
BASE_URL="http://localhost:8080"
if [ ! -z "$1" ]; then
    BASE_URL="$1"
fi

echo -e "${YELLOW}🎯 Testando URL: $BASE_URL${NC}"

# Teste 1: Health Check
echo -e "\n${YELLOW}📊 Teste 1: Health Check${NC}"
for i in {1..10}; do
    response=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/actuator/health" || echo "000")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Request $i: OK${NC}"
    else
        echo -e "${RED}❌ Request $i: HTTP $response${NC}"
    fi
    sleep 0.1
done

# Teste 2: Info Endpoint
echo -e "\n${YELLOW}📊 Teste 2: Info Endpoint${NC}"
for i in {1..5}; do
    response=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/actuator/info" || echo "000")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Info Request $i: OK${NC}"
    else
        echo -e "${RED}❌ Info Request $i: HTTP $response${NC}"
    fi
    sleep 0.2
done

# Teste 3: Metrics Endpoint
echo -e "\n${YELLOW}📊 Teste 3: Metrics Endpoint${NC}"
response=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/actuator/metrics" || echo "000")
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✅ Metrics: OK${NC}"
else
    echo -e "${RED}❌ Metrics: HTTP $response${NC}"
fi

# Teste 4: Prometheus Endpoint
echo -e "\n${YELLOW}📊 Teste 4: Prometheus Endpoint${NC}"
response=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/actuator/prometheus" || echo "000")
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✅ Prometheus: OK${NC}"
else
    echo -e "${YELLOW}⚠️ Prometheus: HTTP $response (pode não estar habilitado)${NC}"
fi

# Teste 5: Concurrent Requests
echo -e "\n${YELLOW}📊 Teste 5: Requisições Concorrentes (20 requests)${NC}"
success_count=0
for i in {1..20}; do
    (
        response=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/actuator/health" || echo "000")
        if [ "$response" = "200" ]; then
            echo -e "${GREEN}✅ Concurrent $i: OK${NC}"
        else
            echo -e "${RED}❌ Concurrent $i: HTTP $response${NC}"
        fi
    ) &
done

# Aguardar todas as requisições concorrentes
wait

echo -e "\n${BLUE}📋 RELATÓRIO FINAL${NC}"
echo -e "${BLUE}==================${NC}"
echo -e "${GREEN}✅ Testes básicos de carga concluídos${NC}"
echo -e "${YELLOW}📊 URL testada: $BASE_URL${NC}"
echo -e "${YELLOW}🔍 Verifique os logs da aplicação para detalhes${NC}"

echo -e "\n${GREEN}🎯 PRÓXIMOS PASSOS:${NC}"
echo "1. Verificar logs da aplicação"
echo "2. Monitorar métricas no /actuator/metrics"
echo "3. Executar testes mais robustos em produção"

echo -e "\n${GREEN}✅ Teste de carga simplificado concluído!${NC}"
