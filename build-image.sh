#!/bin/bash

set -euo pipefail

# Script para construir imagem Docker com BuildKit e secrets seguros

# Habilitar BuildKit
export DOCKER_BUILDKIT=1

# Variáveis de build
IMAGE_NAME="conexaodesorte/traefik"
IMAGE_TAG="$(date +%Y%m%d)-$(git rev-parse --short HEAD 2>/dev/null || echo 'dev')"
BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'dev')"
VCS_URL="$(git config --get remote.origin.url 2>/dev/null || echo 'https://github.com/conexao-de-sorte/traefik-infraestrutura')"
BUILD_VERSION="1.0.0"

echo "🔨 Construindo imagem Docker: ${IMAGE_NAME}:${IMAGE_TAG}"

# Verificar se o diretório secrets existe
if [ ! -d "./secrets" ]; then
  mkdir -p ./secrets
  echo "📁 Diretório secrets criado"
fi

# Construir imagem com BuildKit e secrets
docker build \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg BUILD_VERSION="${BUILD_VERSION}" \
  --build-arg VCS_REF="${VCS_REF}" \
  --build-arg VCS_URL="${VCS_URL}" \
  --secret id=traefik_dashboard_password,src=./secrets/traefik_dashboard_password.txt \
  --secret id=letsencrypt_email,src=./secrets/letsencrypt_email.txt \
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
  --tag "${IMAGE_NAME}:latest" \
  --file Dockerfile \
  --provenance=true \
  --sbom=true \
  .

echo "✅ Imagem construída com sucesso: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "✅ Imagem também tagueada como: ${IMAGE_NAME}:latest"

# Exibir informações da imagem
echo "📊 Informações da imagem:"
docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" --format '{{.RepoTags}} {{.Size}}'