#!/usr/bin/env bash
set -euo pipefail

# Script para conectar o backend-prod à rede overlay do Swarm
# Permite comunicação híbrida entre Traefik (Swarm) e backend-prod (Compose)

SWARM_NETWORK="conexao-network-swarm"
BRIDGE_NETWORK="conexao-network"
BACKEND_CONTAINER="backend-prod"

echo "🔗 Configurando conectividade híbrida para $BACKEND_CONTAINER..."

# Verificar se o container backend-prod existe
if ! docker ps --filter name="$BACKEND_CONTAINER" --format "{{.Names}}" | grep -q "^$BACKEND_CONTAINER$"; then
  echo "⚠️ Container $BACKEND_CONTAINER não encontrado ou não está rodando"
  echo "📋 Containers disponíveis:"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  echo "ℹ️ Continuando sem conectar o backend-prod..."
  exit 0
fi

# Verificar se a rede overlay existe
if ! docker network ls --filter name="$SWARM_NETWORK" --format "{{.Name}}" | grep -q "^$SWARM_NETWORK$"; then
  echo "❌ Rede $SWARM_NETWORK não encontrada"
  echo "📋 Redes disponíveis:"
  docker network ls
  exit 1
fi

# Verificar se a rede bridge existe, se não, criar
if ! docker network ls --filter name="$BRIDGE_NETWORK" --format "{{.Name}}" | grep -q "^$BRIDGE_NETWORK$"; then
  echo "🌐 Criando rede bridge $BRIDGE_NETWORK..."
  if docker network create "$BRIDGE_NETWORK" 2>/dev/null; then
    echo "✅ Rede bridge $BRIDGE_NETWORK criada"
  else
    echo "⚠️ Falha ao criar rede bridge $BRIDGE_NETWORK"
  fi
fi

# Conectar backend-prod à rede overlay (se não estiver conectado)
if docker inspect "$BACKEND_CONTAINER" --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}}{{"\n"}}{{end}}' | grep -q "^$SWARM_NETWORK$"; then
  echo "✅ Container $BACKEND_CONTAINER já está conectado à rede $SWARM_NETWORK"
else
  echo "🔗 Conectando $BACKEND_CONTAINER à rede overlay $SWARM_NETWORK..."
  if docker network connect "$SWARM_NETWORK" "$BACKEND_CONTAINER" 2>/dev/null; then
    echo "✅ Container $BACKEND_CONTAINER conectado à rede overlay $SWARM_NETWORK"
  else
    echo "⚠️ Falha ao conectar $BACKEND_CONTAINER à rede overlay (pode já estar conectado)"
  fi
fi

# Conectar backend-prod à rede bridge (se não estiver conectado)
if docker inspect "$BACKEND_CONTAINER" --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}}{{"\n"}}{{end}}' | grep -q "^$BRIDGE_NETWORK$"; then
  echo "✅ Container $BACKEND_CONTAINER já está conectado à rede $BRIDGE_NETWORK"
else
  echo "🔗 Conectando $BACKEND_CONTAINER à rede bridge $BRIDGE_NETWORK..."
  if docker network connect "$BRIDGE_NETWORK" "$BACKEND_CONTAINER" 2>/dev/null; then
    echo "✅ Container $BACKEND_CONTAINER conectado à rede bridge $BRIDGE_NETWORK"
  else
    echo "⚠️ Falha ao conectar $BACKEND_CONTAINER à rede bridge (pode já estar conectado)"
  fi
fi

# Verificar conectividade
echo "🔍 Verificando conectividade..."
if docker exec "$BACKEND_CONTAINER" ping -c 1 8.8.8.8 > /dev/null 2>&1; then
  echo "✅ Conectividade externa OK"
else
  echo "⚠️ Sem conectividade externa"
fi

# Mostrar redes conectadas
echo "📋 Redes conectadas ao $BACKEND_CONTAINER:"
docker inspect "$BACKEND_CONTAINER" --format '{{range $net, $config := .NetworkSettings.Networks}}  - {{$net}} ({{$config.IPAddress}}){{"\n"}}{{end}}'

echo "✅ Configuração de conectividade híbrida concluída!"