#!/bin/bash

# ===== SCRIPT DE DIAGNÓSTICO DOS SCHEDULERS =====
# Script para diagnosticar problemas com schedulers não executando
# Autor: Sistema de Diagnóstico Automatizado
# Data: $(date +"%d/%m/%Y")

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log com timestamp
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_info() {
    log "${BLUE}ℹ️  INFO: $1${NC}"
}

log_success() {
    log "${GREEN}✅ SUCCESS: $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  WARNING: $1${NC}"
}

log_error() {
    log "${RED}❌ ERROR: $1${NC}"
}

echo "====================================================="
echo "🔍 DIAGNÓSTICO DOS SCHEDULERS - CONEXÃO DE SORTE"
echo "====================================================="
echo ""

# 1. Verificar timezone do sistema
log_info "Verificando timezone do sistema..."
echo "📋 Timezone atual: $(timedatectl show --property=Timezone --value 2>/dev/null || date +%Z)"
echo "🕐 Data/hora atual: $(date)"
echo "🌍 Data/hora UTC: $(date -u)"
echo "🇧🇷 Data/hora São Paulo: $(TZ='America/Sao_Paulo' date)"
echo ""

# 2. Verificar se aplicação está rodando
log_info "Verificando se aplicação está rodando..."
if docker ps | grep -q conexao-backend; then
    CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep conexao-backend | head -1)
    log_success "Container encontrado: $CONTAINER_NAME"
    
    # Verificar timezone do container
    log_info "Verificando timezone do container..."
    echo "📋 Timezone do container: $(docker exec $CONTAINER_NAME date 2>/dev/null || echo 'Não acessível')"
    echo "🌍 UTC do container: $(docker exec $CONTAINER_NAME date -u 2>/dev/null || echo 'Não acessível')"
    
    # Verificar variáveis de ambiente relacionadas ao timezone
    log_info "Verificando variáveis de ambiente do container..."
    docker exec $CONTAINER_NAME env | grep -E "(TZ|TIMEZONE|JAVA_OPTS)" || echo "Nenhuma variável de timezone encontrada"
    
else
    log_error "Nenhum container da aplicação encontrado!"
    echo "Containers rodando:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi
echo ""

# 3. Verificar logs da aplicação para schedulers
log_info "Verificando logs da aplicação para schedulers..."
echo "📋 Últimos logs relacionados a schedulers:"
docker logs $CONTAINER_NAME --since="1h" 2>&1 | grep -i -E "(scheduler|agendamento|cron|@scheduled|extrac)" | tail -20 || echo "Nenhum log de scheduler encontrado na última hora"
echo ""

# 4. Verificar se endpoint de diagnóstico está disponível
log_info "Verificando endpoint de diagnóstico..."
if curl -f -s http://localhost:8080/api/diagnostico/schedulers > /tmp/diagnostico.json 2>/dev/null; then
    log_success "Endpoint de diagnóstico acessível"
    echo "📊 Resultado do diagnóstico:"
    cat /tmp/diagnostico.json | python3 -m json.tool 2>/dev/null || cat /tmp/diagnostico.json
else
    log_warning "Endpoint de diagnóstico não acessível"
    echo "Tentando acessar health check..."
    curl -f -s http://localhost:8080/actuator/health | python3 -m json.tool 2>/dev/null || echo "Health check também não acessível"
fi
echo ""

# 5. Verificar configuração do Spring Scheduling
log_info "Verificando configuração do Spring Scheduling..."
if curl -f -s http://localhost:8080/api/diagnostico/spring-scheduling > /tmp/spring-scheduling.json 2>/dev/null; then
    echo "📊 Configuração do Spring Scheduling:"
    cat /tmp/spring-scheduling.json | python3 -m json.tool 2>/dev/null || cat /tmp/spring-scheduling.json
else
    log_warning "Não foi possível verificar configuração do Spring Scheduling"
fi
echo ""

# 6. Forçar execução do teste de scheduler
log_info "Forçando execução do teste de scheduler..."
if curl -f -s http://localhost:8080/api/diagnostico/teste-scheduler > /tmp/teste-scheduler.json 2>/dev/null; then
    log_success "Teste de scheduler executado"
    echo "📊 Resultado do teste:"
    cat /tmp/teste-scheduler.json | python3 -m json.tool 2>/dev/null || cat /tmp/teste-scheduler.json
else
    log_warning "Não foi possível executar teste de scheduler"
fi
echo ""

# 7. Verificar logs em tempo real por alguns segundos
log_info "Monitorando logs em tempo real por 30 segundos..."
echo "📺 Logs em tempo real (pressione Ctrl+C para parar):"
timeout 30s docker logs -f $CONTAINER_NAME 2>&1 | grep -i -E "(scheduler|agendamento|cron|@scheduled|extrac|erro|error)" || true
echo ""

# 8. Verificar configuração de horários válidos
log_info "Verificando configuração de horários válidos..."
echo "📋 Tentando acessar configuração de horários..."
curl -f -s "http://localhost:8080/rest/v1/horarios-validos/hoje" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Endpoint de horários válidos não acessível"
echo ""

# 9. Verificar se há resultados recentes
log_info "Verificando resultados recentes..."
echo "📋 Últimos resultados extraídos:"
curl -f -s "http://localhost:8080/rest/v1/resultados/publico/ultimo/rio" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Endpoint de resultados não acessível"
echo ""

# 10. Verificar configuração do banco de dados
log_info "Verificando conexão com banco de dados..."
if docker exec $CONTAINER_NAME curl -f -s http://localhost:8080/actuator/health/db > /tmp/db-health.json 2>/dev/null; then
    echo "📊 Status do banco de dados:"
    cat /tmp/db-health.json | python3 -m json.tool 2>/dev/null || cat /tmp/db-health.json
else
    log_warning "Não foi possível verificar status do banco de dados"
fi
echo ""

# 11. Resumo e recomendações
echo "====================================================="
echo "📋 RESUMO DO DIAGNÓSTICO"
echo "====================================================="
echo ""

log_info "Verificações realizadas:"
echo "✓ Timezone do sistema e container"
echo "✓ Status da aplicação"
echo "✓ Logs de schedulers"
echo "✓ Endpoints de diagnóstico"
echo "✓ Configuração do Spring Scheduling"
echo "✓ Teste forçado de scheduler"
echo "✓ Monitoramento em tempo real"
echo "✓ Configuração de horários válidos"
echo "✓ Resultados recentes"
echo "✓ Status do banco de dados"
echo ""

log_info "Possíveis causas dos schedulers não executarem:"
echo "1. 🕐 Timezone incorreto (deve ser America/Sao_Paulo)"
echo "2. 🔧 @EnableScheduling não configurado"
echo "3. 📋 Horários válidos não configurados no banco"
echo "4. 🚫 Schedulers desabilitados por configuração"
echo "5. 💾 Problemas de conexão com banco de dados"
echo "6. 🔄 Aplicação não inicializou completamente"
echo "7. ⚙️ Configuração de TaskScheduler incorreta"
echo ""

log_info "Próximos passos recomendados:"
echo "1. Verificar se timezone está correto em todos os níveis"
echo "2. Confirmar se @EnableScheduling está ativo"
echo "3. Verificar configuração de horários válidos no banco"
echo "4. Revisar logs da aplicação para erros de inicialização"
echo "5. Testar schedulers manualmente via endpoints"
echo "6. Verificar se há bloqueios de segurança"
echo ""

# Limpeza
rm -f /tmp/diagnostico.json /tmp/spring-scheduling.json /tmp/teste-scheduler.json /tmp/db-health.json 2>/dev/null || true

log_success "Diagnóstico concluído!"
echo "====================================================="