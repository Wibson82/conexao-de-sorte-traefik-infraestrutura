#!/usr/bin/env bash
set -euo pipefail

# Deploy Traefik stack using the repo's docker-compose.yml and validate readiness.

STACK_NAME=${STACK_NAME:-conexao-traefik}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}

echo "🔧 Preparing environment for Traefik deploy..."

# Check which network to use based on environment variable
NETWORK_NAME=${DOCKER_NETWORK_NAME:-conexao-network-swarm}

# Determine correct compose file based on network type
if [ "$NETWORK_NAME" = "conexao-network-swarm" ]; then
  COMPOSE_FILE="docker-compose.swarm.yml"
  echo "🐝 Using Docker Swarm mode with $COMPOSE_FILE"
else
  COMPOSE_FILE="docker-compose.yml"
  echo "🐳 Using standalone mode with $COMPOSE_FILE"
fi

# Ensure required network exists
if [ "$NETWORK_NAME" = "conexao-network-swarm" ]; then
  echo "🌐 Checking Docker Swarm overlay network: $NETWORK_NAME"
  # Verificar se a rede já existe antes de tentar criar
  if ! docker network ls --filter name="$NETWORK_NAME" --format "{{.Name}}" | grep -q "^$NETWORK_NAME$"; then
    echo "🌐 Creating overlay network: $NETWORK_NAME"
    docker network create --driver overlay --attachable "$NETWORK_NAME" 2>/dev/null || true
  else
    echo "✅ Network $NETWORK_NAME already exists"
  fi
else
  echo "🌐 Checking bridge network: $NETWORK_NAME"
  # Para redes bridge (standalone mode)
  if ! docker network ls --filter name="$NETWORK_NAME" --format "{{.Name}}" | grep -q "^$NETWORK_NAME$"; then
    echo "🌐 Creating bridge network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME" 2>/dev/null || true
  else
    echo "✅ Network $NETWORK_NAME already exists"
  fi
fi

# Ensure required directories exist
mkdir -p ./letsencrypt || true
mkdir -p ./logs/traefik || true

# Set proper permissions for acme.json
if [ ! -f ./letsencrypt/acme.json ]; then
    touch ./letsencrypt/acme.json
fi
chmod 600 ./letsencrypt/acme.json

# Verificações pré-deploy
echo "🔍 Verificações pré-deploy:"
echo "  - Docker compose file: $(test -f "$COMPOSE_FILE" && echo "✅" || echo "❌") $COMPOSE_FILE"
echo "  - Traefik config: $(test -f traefik/traefik.yml && echo "✅" || echo "❌") traefik/traefik.yml"
echo "  - Dynamic config dir: $(test -d traefik/dynamic && echo "✅" || echo "❌") traefik/dynamic"
echo "  - Secrets dir: $(test -d secrets && echo "✅" || echo "❌") secrets"
echo "  - LetsEncrypt dir: $(test -d letsencrypt && echo "✅" || echo "❌") letsencrypt"
echo "  - ACME file: $(test -f letsencrypt/acme.json && echo "✅" || echo "❌") letsencrypt/acme.json"

echo ""
echo "🚀 Deploying stack $STACK_NAME from $COMPOSE_FILE"
docker stack deploy -c "$COMPOSE_FILE" --with-registry-auth "$STACK_NAME"

echo "⏳ Waiting for $STACK_NAME service to reach 1/1..."
timeout=180
elapsed=0

while [ $elapsed -lt $timeout ]; do
  replicas=$(docker service ls --filter name="${STACK_NAME}_traefik" --format "{{.Replicas}}" | head -1 || echo "")
  if [ -n "$replicas" ]; then
    running=${replicas%/*}
    desired=${replicas#*/}
    if [ "$running" = "$desired" ] && [ "$running" = "1" ]; then
      echo "✅ Traefik ready: $replicas"
      exit 0
    else
      echo "⏳ Traefik progress: $replicas"
    fi
  else
    echo "⏳ Waiting for service to appear..."
  fi
  sleep 5
  elapsed=$((elapsed+5))
done

echo "❌ Traefik did not reach 1/1 in ${timeout}s. Service status:"
docker service ls --filter name="${STACK_NAME}_traefik" || true

echo ""
echo "🔍 Service inspection:"
docker service inspect "${STACK_NAME}_traefik" --pretty || true

echo ""
echo "📋 Service tasks:"
docker service ps "${STACK_NAME}_traefik" --no-trunc || true

echo ""
echo "📜 Service logs (últimas 100 linhas):"
docker service logs "${STACK_NAME}_traefik" --tail 100 --timestamps || true

echo ""
echo "🌐 Network inspection:"
docker network inspect conexao-network-swarm || true

exit 1

