#!/bin/bash

# =============================================================================
# DIAGNÓSTICO ESPECÍFICO: BACKEND DE PRODUÇÃO NÃO ACESSÍVEL
# =============================================================================
# Este script diagnostica especificamente por que:
# ✅ Backend teste acessível
# ❌ Backend produção não acessível
# =============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

log_info "🔍 DIAGNÓSTICO: Por que backend produção não está acessível?"

# =============================================================================
# 1. VERIFICAR CONTAINERS
# =============================================================================
log_info "1. Verificando containers..."

echo "📊 Status de todos os containers:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" | head -10

echo ""
echo "🔍 Containers específicos:"

# Backend produção
if docker ps | grep -q "backend-prod"; then
    log_success "Backend produção: RODANDO"
    echo "   Status: $(docker ps --format '{{.Status}}' --filter name=backend-prod)"
    echo "   Porta: $(docker ps --format '{{.Ports}}' --filter name=backend-prod)"
else
    log_error "Backend produção: NÃO ESTÁ RODANDO"
    
    # Verificar se existe parado
    if docker ps -a | grep -q "backend-prod"; then
        log_warning "Container backend-prod existe mas está parado"
        echo "   Status: $(docker ps -a --format '{{.Status}}' --filter name=backend-prod)"
        echo "   Logs recentes:"
        docker logs backend-prod --tail 10 2>/dev/null || echo "   Não foi possível obter logs"
    else
        log_error "Container backend-prod não existe"
    fi
fi

# Backend teste (para comparação)
if docker ps | grep -q "backend-teste"; then
    log_success "Backend teste: RODANDO"
    echo "   Status: $(docker ps --format '{{.Status}}' --filter name=backend-teste)"
    echo "   Porta: $(docker ps --format '{{.Ports}}' --filter name=backend-teste)"
else
    log_warning "Backend teste: NÃO ESTÁ RODANDO"
fi

# =============================================================================
# 2. TESTAR CONECTIVIDADE DIRETA
# =============================================================================
log_info "2. Testando conectividade direta..."

# Teste backend produção (porta 8080)
echo "🚀 Testando backend produção (porta 8080):"
if curl -f --connect-timeout 10 http://localhost:8080/actuator/health >/dev/null 2>&1; then
    log_success "Backend produção responde diretamente"
    echo "   Response: $(curl -s http://localhost:8080/actuator/health | head -1)"
else
    log_error "Backend produção NÃO responde diretamente"
    echo "   Tentando conectar: $(curl -s --connect-timeout 5 http://localhost:8080/actuator/health || echo 'Falha na conexão')"
fi

# Teste backend teste (porta 8081)
echo "🧪 Testando backend teste (porta 8081):"
if curl -f --connect-timeout 10 http://localhost:8081/actuator/health >/dev/null 2>&1; then
    log_success "Backend teste responde diretamente"
    echo "   Response: $(curl -s http://localhost:8081/actuator/health | head -1)"
else
    log_error "Backend teste NÃO responde diretamente"
fi

# =============================================================================
# 3. VERIFICAR ROTEAMENTO TRAEFIK
# =============================================================================
log_info "3. Verificando roteamento Traefik..."

# Verificar se Traefik está rodando
if docker ps | grep -q "traefik"; then
    log_success "Traefik está rodando"
    
    # Verificar API do Traefik
    if curl -f http://localhost:8090/api/http/routers >/dev/null 2>&1; then
        log_success "API do Traefik acessível"
        
        # Contar roteadores
        TOTAL_ROUTERS=$(curl -s http://localhost:8090/api/http/routers | grep -c '"name"' || echo "0")
        BACKEND_PROD_ROUTERS=$(curl -s http://localhost:8090/api/http/routers | grep -c "backend-prod" || echo "0")
        BACKEND_TESTE_ROUTERS=$(curl -s http://localhost:8090/api/http/routers | grep -c "backend-teste" || echo "0")
        
        echo "   Total de roteadores: $TOTAL_ROUTERS"
        echo "   Roteadores backend-prod: $BACKEND_PROD_ROUTERS"
        echo "   Roteadores backend-teste: $BACKEND_TESTE_ROUTERS"
        
        if [ "$BACKEND_PROD_ROUTERS" -gt 0 ]; then
            log_success "Traefik detectou backend-prod"
        else
            log_error "Traefik NÃO detectou backend-prod"
        fi
        
        if [ "$BACKEND_TESTE_ROUTERS" -gt 0 ]; then
            log_success "Traefik detectou backend-teste"
        else
            log_warning "Traefik NÃO detectou backend-teste"
        fi
        
    else
        log_error "API do Traefik não acessível"
    fi
else
    log_error "Traefik não está rodando"
fi

# =============================================================================
# 4. TESTAR ROTEAMENTO EXTERNO
# =============================================================================
log_info "4. Testando roteamento externo..."

# Teste produção via Traefik
echo "🌐 Testando produção via Traefik (/rest):"
PROD_RESPONSE=$(curl -s --connect-timeout 10 http://localhost/rest/actuator/health || echo "FALHA")
if echo "$PROD_RESPONSE" | grep -q '"status":"UP"'; then
    log_success "Roteamento produção funcionando"
    echo "   Response: $(echo "$PROD_RESPONSE" | head -1)"
else
    log_error "Roteamento produção NÃO funcionando"
    echo "   Response: $PROD_RESPONSE"
    
    # Verificar se retorna HTML (frontend)
    if echo "$PROD_RESPONSE" | grep -q "<!DOCTYPE html>"; then
        log_warning "PROBLEMA: Retornando HTML do frontend em vez do backend"
    fi
fi

# Teste teste via Traefik
echo "🧪 Testando teste via Traefik (/teste/rest):"
TESTE_RESPONSE=$(curl -s --connect-timeout 10 http://localhost/teste/rest/actuator/health || echo "FALHA")
if echo "$TESTE_RESPONSE" | grep -q '"status":"UP"'; then
    log_success "Roteamento teste funcionando"
    echo "   Response: $(echo "$TESTE_RESPONSE" | head -1)"
else
    log_warning "Roteamento teste NÃO funcionando"
    echo "   Response: $TESTE_RESPONSE"
fi

# =============================================================================
# 5. VERIFICAR LABELS DOS CONTAINERS
# =============================================================================
log_info "5. Verificando labels dos containers..."

# Labels backend produção
if docker ps | grep -q "backend-prod"; then
    echo "🚀 Labels backend-prod:"
    PROD_LABELS=$(docker inspect backend-prod --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}: {{$value}}{{"\n"}}{{end}}{{end}}' 2>/dev/null || echo "Erro ao obter labels")
    if [[ -n "$PROD_LABELS" ]]; then
        echo "$PROD_LABELS" | head -5
        PROD_LABEL_COUNT=$(echo "$PROD_LABELS" | wc -l)
        echo "   Total de labels Traefik: $PROD_LABEL_COUNT"
    else
        log_error "Backend-prod sem labels Traefik"
    fi
else
    log_error "Backend-prod não está rodando - não é possível verificar labels"
fi

# Labels backend teste
if docker ps | grep -q "backend-teste"; then
    echo "🧪 Labels backend-teste:"
    TESTE_LABELS=$(docker inspect backend-teste --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}: {{$value}}{{"\n"}}{{end}}{{end}}' 2>/dev/null || echo "Erro ao obter labels")
    if [[ -n "$TESTE_LABELS" ]]; then
        echo "$TESTE_LABELS" | head -5
        TESTE_LABEL_COUNT=$(echo "$TESTE_LABELS" | wc -l)
        echo "   Total de labels Traefik: $TESTE_LABEL_COUNT"
    else
        log_warning "Backend-teste sem labels Traefik"
    fi
else
    log_warning "Backend-teste não está rodando - não é possível verificar labels"
fi

# =============================================================================
# 6. VERIFICAR REDE
# =============================================================================
log_info "6. Verificando rede..."

if docker network inspect conexao-network >/dev/null 2>&1; then
    log_success "Rede conexao-network existe"
    
    echo "   Containers na rede:"
    docker network inspect conexao-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}' | grep -E "(backend-prod|backend-teste|traefik)" || echo "   Nenhum container relevante encontrado"
else
    log_error "Rede conexao-network não existe"
fi

# =============================================================================
# 7. LOGS DOS CONTAINERS
# =============================================================================
log_info "7. Verificando logs dos containers..."

# Logs backend produção
if docker ps | grep -q "backend-prod"; then
    echo "🚀 Logs recentes backend-prod:"
    docker logs backend-prod --tail 10 2>/dev/null | grep -E "(ERROR|WARN|Started|Tomcat)" || echo "   Nenhum log relevante"
else
    log_error "Backend-prod não está rodando - não é possível obter logs"
fi

# Logs backend teste
if docker ps | grep -q "backend-teste"; then
    echo "🧪 Logs recentes backend-teste:"
    docker logs backend-teste --tail 10 2>/dev/null | grep -E "(ERROR|WARN|Started|Tomcat)" || echo "   Nenhum log relevante"
else
    log_warning "Backend-teste não está rodando - não é possível obter logs"
fi

# =============================================================================
# 8. RESUMO E RECOMENDAÇÕES
# =============================================================================
log_info "8. Resumo e recomendações..."

echo ""
echo "📊 RESUMO DO DIAGNÓSTICO:"
echo "========================"

# Status containers
BACKEND_PROD_RUNNING=$(docker ps | grep -q "backend-prod" && echo "SIM" || echo "NÃO")
BACKEND_TESTE_RUNNING=$(docker ps | grep -q "backend-teste" && echo "SIM" || echo "NÃO")
TRAEFIK_RUNNING=$(docker ps | grep -q "traefik" && echo "SIM" || echo "NÃO")

echo "🐳 Containers:"
echo "   Backend produção rodando: $BACKEND_PROD_RUNNING"
echo "   Backend teste rodando: $BACKEND_TESTE_RUNNING"
echo "   Traefik rodando: $TRAEFIK_RUNNING"

# Conectividade
PROD_DIRECT=$(curl -f --connect-timeout 5 http://localhost:8080/actuator/health >/dev/null 2>&1 && echo "OK" || echo "FALHA")
TESTE_DIRECT=$(curl -f --connect-timeout 5 http://localhost:8081/actuator/health >/dev/null 2>&1 && echo "OK" || echo "FALHA")
PROD_TRAEFIK=$(curl -s --connect-timeout 5 http://localhost/rest/actuator/health | grep -q '"status":"UP"' && echo "OK" || echo "FALHA")
TESTE_TRAEFIK=$(curl -s --connect-timeout 5 http://localhost/teste/rest/actuator/health | grep -q '"status":"UP"' && echo "OK" || echo "FALHA")

echo "🌐 Conectividade:"
echo "   Backend produção (direto): $PROD_DIRECT"
echo "   Backend teste (direto): $TESTE_DIRECT"
echo "   Backend produção (Traefik): $PROD_TRAEFIK"
echo "   Backend teste (Traefik): $TESTE_TRAEFIK"

echo ""
echo "🎯 RECOMENDAÇÕES:"

if [[ "$BACKEND_PROD_RUNNING" == "NÃO" ]]; then
    log_error "PROBLEMA PRINCIPAL: Backend de produção não está rodando"
    echo "   ➤ Executar deploy do backend de produção"
    echo "   ➤ Verificar por que container não foi criado"
    echo "   ➤ Verificar logs de deploy"
elif [[ "$PROD_DIRECT" == "FALHA" ]]; then
    log_error "PROBLEMA: Backend produção rodando mas não responde"
    echo "   ➤ Verificar logs do container backend-prod"
    echo "   ➤ Verificar configuração de porta (8080)"
    echo "   ➤ Verificar health check"
elif [[ "$PROD_TRAEFIK" == "FALHA" ]]; then
    log_error "PROBLEMA: Backend produção responde direto mas não via Traefik"
    echo "   ➤ Verificar labels Traefik do container"
    echo "   ➤ Verificar se container está na rede conexao-network"
    echo "   ➤ Reiniciar Traefik se necessário"
else
    log_success "Backend de produção parece estar funcionando"
fi

if [[ "$TESTE_TRAEFIK" == "OK" && "$PROD_TRAEFIK" == "FALHA" ]]; then
    log_info "COMPARAÇÃO: Backend teste funciona, produção não"
    echo "   ➤ Comparar labels entre backend-teste e backend-prod"
    echo "   ➤ Verificar se ambos estão na mesma rede"
    echo "   ➤ Verificar prioridades de roteamento"
fi

echo ""
log_success "Diagnóstico concluído!"
