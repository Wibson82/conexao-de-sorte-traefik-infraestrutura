#!/bin/bash

# Script de validação do endpoint público de extração
# Executa testes automatizados em ambiente de desenvolvimento

set -e

# Configurações
BASE_URL="http://localhost:8080"
ENDPOINT="/v1/resultados/publico/extrair"
LOG_FILE="logs/validacao-extracao-$(date +%Y%m%d_%H%M%S).log"
RESULTS_FILE="logs/resultados-validacao.json"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Criar diretório de logs se não existir
mkdir -p logs

echo -e "${BLUE}=== VALIDAÇÃO DO ENDPOINT DE EXTRAÇÃO PÚBLICA ===${NC}"
echo "Iniciando validação em $(date)"
echo "URL Base: $BASE_URL"
echo "Log: $LOG_FILE"
echo ""

# Função para log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Função para teste HTTP
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local expected_status=$4
    local test_name=$5
    
    log "Testando: $test_name"
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url" 2>&1)
    else
        response=$(curl -s -w "\n%{http_code}" -X GET "$url" 2>&1)
    fi
    
    # Separar body e status code
    body=$(echo "$response" | head -n -1)
    status_code=$(echo "$response" | tail -n 1)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSOU${NC} - $test_name (Status: $status_code)"
        log "SUCESSO: $test_name - Status: $status_code"
        return 0
    else
        echo -e "${RED}✗ FALHOU${NC} - $test_name (Esperado: $expected_status, Recebido: $status_code)"
        log "ERRO: $test_name - Esperado: $expected_status, Recebido: $status_code"
        log "Response: $body"
        return 1
    fi
}

# Verificar se o servidor está rodando
log "Verificando se o servidor está ativo..."
if ! curl -s "$BASE_URL/actuator/health" > /dev/null 2>&1; then
    echo -e "${RED}ERRO: Servidor não está rodando em $BASE_URL${NC}"
    log "ERRO: Servidor não está ativo"
    exit 1
fi
echo -e "${GREEN}✓ Servidor ativo${NC}"

# Data para testes (ontem)
DATA_ONTEM=$(date -d "yesterday" +%Y-%m-%d)
DATA_HOJE=$(date +%Y-%m-%d)
DATA_FUTURA=$(date -d "tomorrow" +%Y-%m-%d)
DATA_ANTIGA=$(date -d "32 days ago" +%Y-%m-%d)

echo ""
echo -e "${BLUE}=== TESTES DE FUNCIONALIDADE ===${NC}"

# Teste 1: POST com dados válidos
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"RIO\",\"data\":\"$DATA_ONTEM\"}" \
    "200" \
    "POST com horário RIO e data válida"

# Teste 2: GET com parâmetros válidos
test_endpoint "GET" "$BASE_URL$ENDPOINT/RIO/$DATA_ONTEM" \
    "" \
    "200" \
    "GET com parâmetros de URL válidos"

# Teste 3: Todos os horários válidos
HORARIOS=("RIO" "BOA SORTE" "09 HORAS" "14 HORAS" "16 HORAS" "18 HORAS" "FEDERAL" "21 HORAS")
for horario in "${HORARIOS[@]}"; do
    # URL encode do horário
    horario_encoded=$(echo "$horario" | sed 's/ /%20/g')
    test_endpoint "GET" "$BASE_URL$ENDPOINT/$horario_encoded/$DATA_ONTEM" \
        "" \
        "200" \
        "Horário válido: $horario"
done

echo ""
echo -e "${BLUE}=== TESTES DE VALIDAÇÃO ===${NC}"

# Teste 4: Horário inválido
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"INVALIDO\",\"data\":\"$DATA_ONTEM\"}" \
    "400" \
    "Horário inválido deve retornar 400"

# Teste 5: Data futura
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"RIO\",\"data\":\"$DATA_FUTURA\"}" \
    "400" \
    "Data futura deve retornar 400"

# Teste 6: Data muito antiga
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"RIO\",\"data\":\"$DATA_ANTIGA\"}" \
    "200" \
    "Data antiga deve ser processada (mas pode falhar na validação)"

# Teste 7: Campos obrigatórios ausentes
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"\",\"data\":null}" \
    "400" \
    "Campos obrigatórios ausentes devem retornar 400"

# Teste 8: JSON malformado
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"RIO\",\"data\":" \
    "400" \
    "JSON malformado deve retornar 400"

echo ""
echo -e "${BLUE}=== TESTES DE PERFORMANCE ===${NC}"

# Teste 9: Múltiplas requisições para o mesmo resultado
log "Testando múltiplas requisições para o mesmo resultado..."
start_time=$(date +%s)
for i in {1..10}; do
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"horario\":\"RIO\",\"data\":\"$DATA_ONTEM\"}" \
        "$BASE_URL$ENDPOINT" > /dev/null
done
end_time=$(date +%s)
duration=$((end_time - start_time))
echo -e "${GREEN}✓ 10 requisições completadas em ${duration}s${NC}"
log "Performance: 10 requisições em ${duration}s"

# Teste 10: Tempo de resposta
log "Medindo tempo de resposta..."
start_time=$(date +%s%3N)
curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"horario\":\"RIO\",\"data\":\"$DATA_ONTEM\"}" \
    "$BASE_URL$ENDPOINT" > /dev/null
end_time=$(date +%s%3N)
response_time=$((end_time - start_time))
echo -e "${GREEN}✓ Tempo de resposta: ${response_time}ms${NC}"
log "Tempo de resposta: ${response_time}ms"

echo ""
echo -e "${BLUE}=== TESTES DE SEGURANÇA ===${NC}"

# Teste 11: SQL Injection
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"RIO'; DROP TABLE resultado; --\",\"data\":\"$DATA_ONTEM\"}" \
    "400" \
    "Tentativa de SQL Injection deve ser rejeitada"

# Teste 12: XSS
test_endpoint "POST" "$BASE_URL$ENDPOINT" \
    "{\"horario\":\"<script>alert('xss')</script>\",\"data\":\"$DATA_ONTEM\"}" \
    "400" \
    "Tentativa de XSS deve ser rejeitada"

# Teste 13: Headers maliciosos
log "Testando headers maliciosos..."
response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -H "X-Forwarded-For: 127.0.0.1; DROP TABLE resultado;" \
    -d "{\"horario\":\"RIO\",\"data\":\"$DATA_ONTEM\"}" \
    "$BASE_URL$ENDPOINT" 2>&1)
status_code=$(echo "$response" | tail -n 1)
if [ "$status_code" = "200" ]; then
    echo -e "${GREEN}✓ Headers maliciosos tratados corretamente${NC}"
else
    echo -e "${YELLOW}⚠ Headers maliciosos retornaram status $status_code${NC}"
fi

echo ""
echo -e "${BLUE}=== RESUMO DA VALIDAÇÃO ===${NC}"

# Contar sucessos e falhas
total_tests=$(grep -c "Testando:" "$LOG_FILE" || echo "0")
successful_tests=$(grep -c "SUCESSO:" "$LOG_FILE" || echo "0")
failed_tests=$(grep -c "ERRO:" "$LOG_FILE" || echo "0")

echo "Total de testes: $total_tests"
echo -e "Sucessos: ${GREEN}$successful_tests${NC}"
echo -e "Falhas: ${RED}$failed_tests${NC}"

# Gerar relatório JSON
cat > "$RESULTS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "endpoint": "$BASE_URL$ENDPOINT",
  "total_tests": $total_tests,
  "successful_tests": $successful_tests,
  "failed_tests": $failed_tests,
  "success_rate": $(echo "scale=2; $successful_tests * 100 / $total_tests" | bc -l 2>/dev/null || echo "0"),
  "log_file": "$LOG_FILE"
}
EOF

log "Validação concluída. Relatório salvo em: $RESULTS_FILE"

if [ "$failed_tests" -eq 0 ]; then
    echo -e "${GREEN}🎉 TODOS OS TESTES PASSARAM!${NC}"
    exit 0
else
    echo -e "${RED}❌ $failed_tests TESTE(S) FALHARAM${NC}"
    echo "Verifique o log para detalhes: $LOG_FILE"
    exit 1
fi
