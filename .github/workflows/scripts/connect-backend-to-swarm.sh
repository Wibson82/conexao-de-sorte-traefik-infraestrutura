#!/usr/bin/env bash
set -euo pipefail

# Script para conectar o backend-prod à rede overlay do Swarm
# Permite comunicação híbrida entre Traefik (Swarm) e backend-prod (Compose)

NETWORK_NAME="conexao-network-swarm"
BACKEND_CONTAINER="backend-prod"

echo "🔗 Conectando $BACKEND_CONTAINER à rede overlay $NETWORK_NAME..."

# Verificar se o container backend-prod existe
if ! docker ps --filter name="$BACKEND_CONTAINER" --format "{{.Names}}" | grep -q "^$BACKEND_CONTAINER$"; then
  echo "⚠️ Container $BACKEND_CONTAINER não encontrado ou não está rodando"
  echo "📋 Containers disponíveis:"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  exit 0
fi

# Verificar se a rede overlay existe
if ! docker network ls --filter name="$NETWORK_NAME" --format "{{.Name}}" | grep -q "^$NETWORK_NAME$"; then
  echo "❌ Rede $NETWORK_NAME não encontrada"
  echo "📋 Redes disponíveis:"
  docker network ls
  exit 1
fi

# Verificar se o container já está conectado à rede
if docker inspect "$BACKEND_CONTAINER" --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}}{{"\n"}}{{end}}' | grep -q "^$NETWORK_NAME$"; then
  echo "✅ Container $BACKEND_CONTAINER já está conectado à rede $NETWORK_NAME"
else
  echo "🔗 Conectando $BACKEND_CONTAINER à rede $NETWORK_NAME..."
  if docker network connect "$NETWORK_NAME" "$BACKEND_CONTAINER"; then
    echo "✅ Container $BACKEND_CONTAINER conectado com sucesso à rede $NETWORK_NAME"
  else
    echo "❌ Falha ao conectar $BACKEND_CONTAINER à rede $NETWORK_NAME"
    exit 1
  fi
fi

# Verificar conectividade
echo "🔍 Verificando conectividade..."
docker exec "$BACKEND_CONTAINER" ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "✅ Conectividade externa OK" || echo "⚠️ Sem conectividade externa"

echo "✅ Configuração de rede híbrida concluída!"