#!/usr/bin/env bash
set -euo pipefail

# Deploy Traefik stack using Docker Swarm

STACK_NAME=${STACK_NAME:-conexao-traefik}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}

echo "🔧 Preparing environment for Traefik deploy..."

# Check which network to use based on environment variable
NETWORK_NAME=${DOCKER_NETWORK_NAME:-conexao-network-swarm}

# OBRIGATÓRIO: Usar arquivo consolidado docker-compose.yml
if [ -n "${COMPOSE_FILE:-}" ]; then
  echo "✅ Usando arquivo especificado: $COMPOSE_FILE"
else
  COMPOSE_FILE="docker-compose.yml"
  echo "🔄 Usando arquivo consolidado: $COMPOSE_FILE"
fi

# Verificar se o arquivo obrigatório existe
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ ERRO: Arquivo obrigatório não encontrado: $COMPOSE_FILE"
  echo "📋 Arquivos disponíveis:"
  ls -la docker-compose*.yml || true
  exit 1
fi

echo "🐝 Usando Docker Swarm mode com $COMPOSE_FILE"

# Ensure required network exists
if [ "$NETWORK_NAME" = "conexao-network-swarm" ]; then
  echo "🌐 Checking Docker Swarm overlay network: $NETWORK_NAME"
  if ! docker network ls --filter name="$NETWORK_NAME" --format "{{.Name}}" | grep -q "^$NETWORK_NAME$"; then
    echo "🌐 Creating overlay network: $NETWORK_NAME"
    docker network create --driver overlay --attachable "$NETWORK_NAME" 2>/dev/null || true
  else
    echo "✅ Network $NETWORK_NAME already exists"
  fi
else
  echo "🌐 Checking bridge network: $NETWORK_NAME"
  if ! docker network ls --filter name="$NETWORK_NAME" --format "{{.Name}}" | grep -q "^$NETWORK_NAME$"; then
    echo "🌐 Creating bridge network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME" 2>/dev/null || true
  else
    echo "✅ Network $NETWORK_NAME already exists"
  fi
fi

# Ensure required directories exist
echo "📁 Configurando diretórios e arquivos necessários..."
echo "📍 Diretório de trabalho: $(pwd)"

# Create directories
echo "🗂️ Criando diretórios..."
mkdir -p ./letsencrypt
mkdir -p ./logs/traefik
mkdir -p ./secrets
echo "✅ Todos os diretórios criados"

# Create acme.json with simpler approach
echo "🔐 Configurando arquivo acme.json..."
echo '{}' > ./letsencrypt/acme.json
chmod 600 ./letsencrypt/acme.json
echo "✅ Arquivo acme.json configurado com permissões 600"

# Create basic auth file for Traefik dashboard
if [ ! -f ./secrets/traefik-basicauth ]; then
    echo "🔐 Criando arquivo básico de autenticação..."
    echo 'admin:$2y$10$rQ.0eEWJx7mQ8k4yR4x9/.2l0JUqN7zYTHmFePXkz1YRkFvqRZ5hW' > ./secrets/traefik-basicauth
    chmod 600 ./secrets/traefik-basicauth
    echo "✅ Arquivo traefik-basicauth criado"
fi

# Deploy the stack
echo "🚀 Deploying Traefik stack: $STACK_NAME using $COMPOSE_FILE"

if docker stack deploy --compose-file "$COMPOSE_FILE" "$STACK_NAME"; then
    echo "✅ Stack $STACK_NAME deployed successfully!"
else
    echo "❌ Failed to deploy stack $STACK_NAME"
    exit 1
fi

# Wait for services to be ready
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 10

# Verify deployment
echo "🔍 Verificando status do deployment..."
docker stack ps "$STACK_NAME" --no-trunc

echo "🌐 Verificando serviços do stack..."
docker stack services "$STACK_NAME"

echo "✅ Deploy do Traefik finalizado com sucesso!"
echo "🌐 Traefik Dashboard: https://traefik.conexaodesorte.com.br"
echo "🔐 API: https://api.conexaodesorte.com.br"
