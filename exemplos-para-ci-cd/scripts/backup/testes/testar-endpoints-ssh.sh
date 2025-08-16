#!/bin/bash

# Script de Teste de Endpoints via SSH
# Autor: Sistema de Testes Automatizados
# Data: 2025-08-09

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧪 TESTE DE ENDPOINTS VIA SSH${NC}"
echo -e "${CYAN}==============================${NC}"
echo ""

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅${NC} $1"
}

# Configurações
SERVER_HOST="srv649924.hstgr.cloud"
SERVER_USER="root"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_PORT="22"

# URLs para teste
DOMAIN="www.conexaodesorte.com.br"
BACKEND_TESTE_PORT="8081"
BACKEND_PROD_PORT="8080"

# Função para executar comando SSH
execute_ssh() {
    local command="$1"
    ssh -i "$SSH_KEY_PATH" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "$command"
}

# 1. VERIFICAR STATUS DOS CONTAINERS
log "1️⃣ Verificando status dos containers..."

CONTAINER_STATUS=$(execute_ssh "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
echo "$CONTAINER_STATUS"
echo ""

# 2. TESTAR ENDPOINTS LOCAIS NO SERVIDOR
log "2️⃣ Testando endpoints locais no servidor..."

# Teste backend-teste (porta 8081)
log "🧪 Testando backend-teste (localhost:8081)..."
TESTE_LOCAL_8081=$(execute_ssh "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081/rest/actuator/health || echo 'ERRO'")
if [[ "$TESTE_LOCAL_8081" == "200" ]]; then
    success "Backend-teste respondendo na porta 8081: HTTP $TESTE_LOCAL_8081"
else
    error "Backend-teste não responde na porta 8081: $TESTE_LOCAL_8081"
fi

# Teste backend-prod (porta 8080)
log "🚀 Testando backend-prod (localhost:8080)..."
TESTE_LOCAL_8080=$(execute_ssh "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/rest/actuator/health || echo 'ERRO'")
if [[ "$TESTE_LOCAL_8080" == "200" ]]; then
    success "Backend-prod respondendo na porta 8080: HTTP $TESTE_LOCAL_8080"
else
    warn "Backend-prod não responde na porta 8080: $TESTE_LOCAL_8080"
fi

# 3. TESTAR ENDPOINTS VIA TRAEFIK
log "3️⃣ Testando endpoints via Traefik..."

# Teste endpoint público
log "🌐 Testando endpoint público via Traefik..."
TESTE_PUBLICO=$(execute_ssh "curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/rest/v1/publico/resultados/hoje || echo 'ERRO'")
if [[ "$TESTE_PUBLICO" == "200" ]]; then
    success "Endpoint público funcionando: HTTP $TESTE_PUBLICO"
else
    error "Endpoint público falhou: $TESTE_PUBLICO"
fi

# Teste health check via Traefik
log "🏥 Testando health check via Traefik..."
TESTE_HEALTH=$(execute_ssh "curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/rest/actuator/health || echo 'ERRO'")
if [[ "$TESTE_HEALTH" == "200" ]]; then
    success "Health check via Traefik funcionando: HTTP $TESTE_HEALTH"
else
    error "Health check via Traefik falhou: $TESTE_HEALTH"
fi

# Teste endpoint de teste via Traefik
log "🧪 Testando endpoint de teste via Traefik..."
TESTE_ENDPOINT_TESTE=$(execute_ssh "curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/teste/rest/actuator/health || echo 'ERRO'")
if [[ "$TESTE_ENDPOINT_TESTE" == "200" ]]; then
    success "Endpoint de teste via Traefik funcionando: HTTP $TESTE_ENDPOINT_TESTE"
else
    error "Endpoint de teste via Traefik falhou: $TESTE_ENDPOINT_TESTE"
fi

# 4. VERIFICAR LOGS DOS CONTAINERS
log "4️⃣ Verificando logs dos containers..."

# Logs backend-teste (últimas 20 linhas)
log "📋 Logs backend-teste (últimas 20 linhas)..."
execute_ssh "docker logs --tail 20 backend-teste 2>&1 | grep -E '(ERROR|WARN|INFO.*mapping|INFO.*controller|INFO.*endpoint)' || echo 'Nenhum log relevante encontrado'"
echo ""

# Logs Traefik (últimas 10 linhas)
log "📋 Logs Traefik (últimas 10 linhas)..."
execute_ssh "docker logs --tail 10 traefik 2>&1 | grep -E '(ERROR|WARN|backend|rule)' || echo 'Nenhum log relevante encontrado'"
echo ""

# 5. VERIFICAR CONFIGURAÇÃO TRAEFIK
log "5️⃣ Verificando configuração Traefik..."

# Verificar labels dos containers
log "🏷️ Verificando labels dos containers..."
execute_ssh "docker inspect backend-teste | grep -A 20 'Labels' | grep traefik || echo 'Nenhum label Traefik encontrado'"
echo ""

# 6. TESTAR CONECTIVIDADE INTERNA
log "6️⃣ Testando conectividade interna..."

# Teste conectividade entre containers
log "🔗 Testando conectividade entre containers..."
CONECTIVIDADE=$(execute_ssh "docker exec traefik wget -qO- --timeout=5 http://backend-teste:8081/rest/actuator/health 2>/dev/null | head -c 100 || echo 'FALHA'")
if [[ "$CONECTIVIDADE" != "FALHA" ]]; then
    success "Conectividade interna Traefik -> backend-teste: OK"
else
    error "Conectividade interna Traefik -> backend-teste: FALHA"
fi

# 7. RESUMO DOS TESTES
echo ""
echo -e "${PURPLE}📊 RESUMO DOS TESTES:${NC}"
echo -e "   🧪 Backend-teste (8081): $([[ "$TESTE_LOCAL_8081" == "200" ]] && echo "✅ OK" || echo "❌ FALHA")"
echo -e "   🚀 Backend-prod (8080): $([[ "$TESTE_LOCAL_8080" == "200" ]] && echo "✅ OK" || echo "⚠️ INATIVO")"
echo -e "   🌐 Endpoint público: $([[ "$TESTE_PUBLICO" == "200" ]] && echo "✅ OK" || echo "❌ FALHA")"
echo -e "   🏥 Health check: $([[ "$TESTE_HEALTH" == "200" ]] && echo "✅ OK" || echo "❌ FALHA")"
echo -e "   🧪 Teste via Traefik: $([[ "$TESTE_ENDPOINT_TESTE" == "200" ]] && echo "✅ OK" || echo "❌ FALHA")"
echo -e "   🔗 Conectividade interna: $([[ "$CONECTIVIDADE" != "FALHA" ]] && echo "✅ OK" || echo "❌ FALHA")"
echo ""

# Determinar status geral
if [[ "$TESTE_LOCAL_8081" == "200" && "$TESTE_PUBLICO" == "200" ]]; then
    success "🎉 TESTES CONCLUÍDOS: Sistema funcionando corretamente!"
    exit 0
else
    error "🚨 TESTES FALHARAM: Sistema com problemas identificados!"
    exit 1
fi
