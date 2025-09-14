#!/usr/bin/env bash
set -euo pipefail

STACK=${STACK_NAME:-conexao-traefik}

echo "🔍 Validando saúde do serviço ${STACK}_traefik..."

replicas=$(docker service ls --filter name="${STACK}_traefik" --format "{{.Replicas}}" | head -1 || true)
if [[ -z "$replicas" ]]; then
  echo "❌ Serviço ${STACK}_traefik não encontrado" >&2
  docker service ls | grep "$STACK" || true
  exit 1
fi

echo "ℹ️  Réplicas atuais: $replicas"

echo "🔎 Últimos logs do serviço:"
docker service logs "${STACK}_traefik" --tail 80 || true

echo "✅ Healthcheck concluído"

