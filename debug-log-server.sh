#!/bin/bash
# =============================================================================
# 🔍 DEBUG LOG-SERVER - INVESTIGAÇÃO URGENTE
# =============================================================================

echo "🔍 INVESTIGAÇÃO: Por que log-server não está deployado?"
echo "=================================================="

echo "📊 1. SERVIÇOS DO STACK TRAEFIK:"
docker service ls --filter name=conexao-traefik

echo ""
echo "📊 2. DETALHES DOS SERVIÇOS (se existirem):"
docker service ps conexao-traefik_log-server --no-trunc 2>/dev/null || echo "❌ Serviço log-server NÃO EXISTE"

echo ""
echo "📊 3. IMAGENS DISPONÍVEIS:"
docker images | grep -E "(log-server|<none>)"

echo ""
echo "📊 4. VERIFICAR SE STACK FOI DEPLOYADO CORRETAMENTE:"
docker stack ls

echo ""
echo "📊 5. LOGS DO ÚLTIMO DEPLOYMENT (se houver):"
docker service logs conexao-traefik_traefik --tail 10 2>/dev/null || echo "❌ Sem logs do traefik"

echo ""
echo "📊 6. TENTAR RECRIAR SERVIÇO LOG-SERVER MANUALMENTE:"
echo "Comando para teste manual:"
echo "docker service create --name test-log-server --network conexao-network-swarm log-server:latest"

echo ""
echo "✅ DEBUG CONCLUÍDO"