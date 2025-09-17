#!/usr/bin/env bash
set -euo pipefail

# Deploy Traefik stack using the repo's docker-compose.yml and validate readiness.

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
mkdir -p ./secrets || true

# Set proper permissions for acme.json
if [ ! -f ./letsencrypt/acme.json ]; then
    touch ./letsencrypt/acme.json
fi
chmod 600 ./letsencrypt/acme.json

# Set proper permissions for letsencrypt-bridge acme.json
if [ ! -f ./letsencrypt-bridge/acme.json ]; then
    touch ./letsencrypt-bridge/acme.json
fi
chmod 600 ./letsencrypt-bridge/acme.json

# Create basic auth file for Traefik dashboard
if [ ! -f ./secrets/traefik-basicauth ]; then
    echo "🔐 Criando arquivo básico de autenticação..."
    # Usuário: admin, Senha: admin123 (hash htpasswd)
    echo 'admin:$2y$10$rQ.0eEWJx7mQ8k4yR4x9/.2l0JUqN7zYTHmFePXkz1YRkFvqRZ5hW' > ./secrets/traefik-basicauth
    chmod 600 ./secrets/traefik-basicauth
    echo "✅ Arquivo traefik-basicauth criado"
fi

# Verificações pré-deploy
echo "🔍 Verificações pré-deploy:"
echo "  - Docker compose file: $(test -f "$COMPOSE_FILE" && echo "✅" || echo "❌") $COMPOSE_FILE"
echo "  - Traefik config: $(test -f traefik/traefik.yml && echo "✅" || echo "❌") traefik/traefik.yml"
echo "  - Dynamic config dir: $(test -d traefik/dynamic && echo "✅" || echo "❌") traefik/dynamic"
echo "  - Secrets dir: $(test -d secrets && echo "✅" || echo "❌") secrets"
echo "  - LetsEncrypt dir: $(test -d letsencrypt && echo "✅" || echo "❌") letsencrypt"
echo "  - ACME file: $(test -f letsencrypt/acme.json && echo "✅" || echo "❌") letsencrypt/acme.json"

# Validar configurações SWARM antes do deploy
echo "🔍 Validando configurações do Swarm para Traefik..."
if ! docker stack config -c "$COMPOSE_FILE" > /dev/null; then
  echo "❌ ERRO na configuração do $COMPOSE_FILE"
  echo "🔍 Listando secrets disponíveis:"
  docker secret ls --format "table {{.Name}}\t{{.CreatedAt}}"
  echo "🔍 Verificando arquivo compose:"
  cat "$COMPOSE_FILE" | head -50
  exit 1
fi

# Remover imagens antigas do Traefik antes de fazer o deploy
echo "🧹 Removendo imagens antigas do Traefik..."
# Verificar se o serviço existe antes de tentar remover
if docker service ls --filter name="${STACK_NAME}_traefik" --format "{{.Name}}" | grep -q "${STACK_NAME}_traefik"; then
  echo "🔄 Serviço Traefik existente encontrado, preparando para atualização..."
  
  # Obter a imagem atual para referência
  CURRENT_IMAGE=$(docker service inspect --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' "${STACK_NAME}_traefik" 2>/dev/null || echo "")
  if [ -n "$CURRENT_IMAGE" ]; then
    echo "📋 Imagem atual: $CURRENT_IMAGE"
  fi
  
  # Forçar remoção de containers antigos
  echo "🧹 Removendo containers antigos do Traefik..."
  docker service scale "${STACK_NAME}_traefik=0" || true
  sleep 5
  
  # Verificar se há containers ainda em execução
  RUNNING_CONTAINERS=$(docker ps --filter name="${STACK_NAME}_traefik" --format "{{.ID}}" || echo "")
  if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "🧹 Forçando remoção de containers ainda em execução..."
    echo "$RUNNING_CONTAINERS" | xargs -r docker rm -f
  fi
  
  # Limpar imagens antigas não utilizadas
  echo "🧹 Limpando imagens antigas não utilizadas..."
  docker image prune -f
else
  echo "ℹ️ Nenhum serviço Traefik existente encontrado, prosseguindo com deploy inicial..."
fi

echo ""
echo "🚀 Deploying stack $STACK_NAME from $COMPOSE_FILE com Swarm"

# Implementar mecanismo de retry para garantir o envio da imagem
MAX_RETRIES=3
RETRY_COUNT=0
DEPLOY_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$DEPLOY_SUCCESS" != "true" ]; do
  echo "🔄 Tentativa de deploy #$((RETRY_COUNT+1))..."
  
  # Forçar pull da imagem antes do deploy
  echo "📥 Forçando pull da imagem Traefik..."
  docker pull traefik:v3.5.2
  
  # Executar o deploy com --with-registry-auth para garantir acesso ao registry
  if docker stack deploy -c "$COMPOSE_FILE" --with-registry-auth "$STACK_NAME" --prune; then
    echo "✅ Deploy executado com sucesso!"
    DEPLOY_SUCCESS=true
  else
    echo "❌ Falha no deploy, tentando novamente..."
    RETRY_COUNT=$((RETRY_COUNT+1))
    
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "⏳ Aguardando 10 segundos antes da próxima tentativa..."
      sleep 10
      
      # Limpar possíveis containers problemáticos
      echo "🧹 Limpando possíveis containers problemáticos..."
      docker ps -a --filter name="${STACK_NAME}_traefik" --format "{{.ID}}" | xargs -r docker rm -f
      
      # Verificar status do Docker
      echo "🔍 Verificando status do Docker..."
      docker info | grep -E "Server Version|Containers|Images|Swarm"
    else
      echo "❌ Número máximo de tentativas excedido!"
    fi
  fi
done

if [ "$DEPLOY_SUCCESS" != "true" ]; then
  echo "❌ Falha ao fazer deploy após $MAX_RETRIES tentativas!"
  exit 1
fi

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

