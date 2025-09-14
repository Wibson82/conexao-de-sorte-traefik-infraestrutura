#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Validando artefatos e sintaxe do Traefik..."

# Arquivos obrigatórios
required=(
  "docker-compose.yml"
  "traefik/traefik.yml"
  "traefik/dynamic/middlewares.yml"
  "traefik/dynamic/security-headers.yml"
  "traefik/dynamic/tls.yml"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ Arquivo obrigatório não encontrado: $f" >&2
    exit 1
  fi
  echo "✅ $f encontrado"
done

echo "🔧 Validando docker-compose.yml"
docker compose -f docker-compose.yml config >/dev/null
echo "✅ Docker Compose válido"

echo "✅ Validação concluída"

