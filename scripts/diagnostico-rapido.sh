#!/bin/bash

# =============================================================================
# DIAGNÓSTICO RÁPIDO - TRAEFIK INFRASTRUCTURE
# =============================================================================
# Script para diagnósticos rápidos baseado nos testes manuais realizados
# Executa apenas os comandos essenciais para verificar conectividade
# =============================================================================

set -e

echo "🔧 Diagnóstico Rápido - Traefik Infrastructure"
echo "================================================"
echo "🖥️  Servidor: $(hostname)"
echo "📍 IP: $(hostname -I | awk '{print $1}')"
echo "🕐 Data/hora: $(date)"
echo "👤 Usuário: $(whoami)"
echo ""

# =============================================================================
# VERIFICAÇÕES BÁSICAS
# =============================================================================
echo "📋 1. STATUS DOS CONTAINERS PRINCIPAIS"
echo "--------------------------------------"

echo "🐳 Containers em execução:"
docker container ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(conexao-traefik|conexao-frontend|backend-prod|conexao-mysql)"

echo ""
echo "🔗 Verificando redes Docker:"
docker network ls | grep conexao || echo "❌ Nenhuma rede 'conexao' encontrada"

echo ""
echo "📡 Containers na rede conexao-network:"
docker network inspect conexao-network --format '{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "❌ Rede conexao-network não existe"

# =============================================================================
# TESTES DE CONECTIVIDADE INTERNA
# =============================================================================
echo ""
echo "📡 2. TESTES DE CONECTIVIDADE INTERNA"
echo "-------------------------------------"

echo "🔍 Testando Traefik -> Backend (Health Check):"
if docker exec conexao-traefik wget -qO- --timeout=10 http://backend-prod:8080/actuator/health > /tmp/health_check.json 2>/dev/null; then
    echo "✅ Backend acessível via Traefik"
    echo "📊 Status do Health Check:"
    cat /tmp/health_check.json | jq -r '.status' 2>/dev/null || echo "Status não disponível"
    echo "🔧 Componentes principais:"
    cat /tmp/health_check.json | jq -r '.components | keys[]' 2>/dev/null | head -5 || echo "Componentes não disponíveis"
else
    echo "❌ Backend inacessível via Traefik"
fi

echo ""
echo "🔍 Testando Traefik -> Frontend:"
if docker exec conexao-traefik wget -qO- --timeout=10 http://conexao-frontend:3000 > /dev/null 2>&1; then
    echo "✅ Frontend acessível via Traefik"
else
    echo "❌ Frontend inacessível via Traefik"
fi

# =============================================================================
# VERIFICAÇÃO DE REDES
# =============================================================================
echo ""
echo "🔗 3. VERIFICAÇÃO DE CONECTIVIDADE DE REDE"
echo "------------------------------------------"

echo "🔍 Tentando conectar containers à rede (se necessário):"
docker network connect conexao-network backend-prod 2>/dev/null && echo "✅ backend-prod conectado à rede" || echo "ℹ️  backend-prod já conectado ou erro na conexão"
docker network connect conexao-network conexao-frontend 2>/dev/null && echo "✅ conexao-frontend conectado à rede" || echo "ℹ️  conexao-frontend já conectado ou erro na conexão"

# =============================================================================
# TESTES EXTERNOS
# =============================================================================
echo ""
echo "🌐 4. TESTES DE CONECTIVIDADE EXTERNA"
echo "------------------------------------"

echo "🔍 Testando HTTPS principal:"
curl -I --connect-timeout 10 https://conexaodesorte.com.br 2>/dev/null | head -1 || echo "❌ HTTPS principal inacessível"

echo "🔍 Testando HTTPS www:"
curl -I --connect-timeout 10 https://www.conexaodesorte.com.br 2>/dev/null | head -1 || echo "❌ HTTPS www inacessível"

# =============================================================================
# API DO TRAEFIK
# =============================================================================
echo ""
echo "📊 5. VERIFICAÇÃO DA API DO TRAEFIK"
echo "----------------------------------"

echo "🔍 Testando acesso à API do Traefik:"
if curl -s http://localhost:8090/api/http/routers 2>/dev/null > /tmp/traefik_routers.json; then
    echo "✅ API do Traefik acessível"
    
    echo "📋 Rotas ativas:"
    cat /tmp/traefik_routers.json | jq -r '.[] | select(.status == "enabled") | "✅ " + .name + " (" + .rule + ")"' 2>/dev/null | head -5 || echo "Erro ao processar rotas ativas"
    
    echo "🚨 Rotas desabilitadas:"
    cat /tmp/traefik_routers.json | jq -r '.[] | select(.status == "disabled") | "❌ " + .name + " (" + .rule + ")"' 2>/dev/null || echo "Nenhuma rota desabilitada ou erro ao processar"
else
    echo "❌ API do Traefik inacessível"
fi

# =============================================================================
# RESUMO FINAL
# =============================================================================
echo ""
echo "📋 6. RESUMO FINAL"
echo "================="

# Verificar status geral
TRAEFIK_OK=$(docker ps | grep -q "conexao-traefik" && echo "true" || echo "false")
BACKEND_OK=$(docker exec conexao-traefik wget -qO- --timeout=5 http://backend-prod:8080/actuator/health > /dev/null 2>&1 && echo "true" || echo "false")
FRONTEND_OK=$(docker exec conexao-traefik wget -qO- --timeout=5 http://conexao-frontend:3000 > /dev/null 2>&1 && echo "true" || echo "false")
HTTPS_OK=$(curl -I --connect-timeout 5 https://conexaodesorte.com.br > /dev/null 2>&1 && echo "true" || echo "false")

echo "🐳 Traefik: $([ "$TRAEFIK_OK" = "true" ] && echo "✅ OK" || echo "❌ PROBLEMA")"
echo "🔧 Backend: $([ "$BACKEND_OK" = "true" ] && echo "✅ OK" || echo "❌ PROBLEMA")"
echo "🌐 Frontend: $([ "$FRONTEND_OK" = "true" ] && echo "✅ OK" || echo "❌ PROBLEMA")"
echo "🔐 HTTPS: $([ "$HTTPS_OK" = "true" ] && echo "✅ OK" || echo "❌ PROBLEMA")"

echo ""
if [ "$TRAEFIK_OK" = "true" ] && [ "$BACKEND_OK" = "true" ] && [ "$FRONTEND_OK" = "true" ]; then
    echo "🎉 DIAGNÓSTICO: Infraestrutura funcionando corretamente!"
    echo "💡 Se ainda há problemas de acesso, verifique:"
    echo "   - Configurações de DNS"
    echo "   - Certificados SSL"
    echo "   - Regras de firewall"
else
    echo "⚠️  DIAGNÓSTICO: Problemas detectados na infraestrutura!"
    echo "🔧 Próximos passos recomendados:"
    echo "   1. Verificar logs: docker logs conexao-traefik"
    echo "   2. Executar diagnóstico completo: ./diagnostico-completo.sh"
    echo "   3. Verificar configurações em dynamic/services.yml"
fi

echo ""
echo "✅ Diagnóstico rápido concluído em $(date)!"
echo "📋 Para diagnósticos mais detalhados, execute: ./diagnostico-completo.sh"

# Cleanup
rm -f /tmp/health_check.json /tmp/traefik_routers.json 2>/dev/null || true