#!/bin/bash
# =============================================================================
# SCRIPT DE BUILD CONSOLIDADO - CONEXÃO DE SORTE BACKEND
# =============================================================================
# Script para build de imagens Docker usando o Dockerfile consolidado
# Suporta múltiplos ambientes e configurações

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações padrão
DEFAULT_ENVIRONMENT="prod"
DEFAULT_TAG="latest"
DEFAULT_REGISTRY="facilita"
DEFAULT_IMAGE_NAME="conexao-de-sorte-backend"
DEFAULT_JAVA_VERSION="24"
DEFAULT_MAVEN_VERSION="3.9.8"

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
🐳 SCRIPT DE BUILD CONSOLIDADO - CONEXÃO DE SORTE BACKEND

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -e, --environment ENV     Ambiente (prod, test, dev) [default: $DEFAULT_ENVIRONMENT]
    -t, --tag TAG            Tag da imagem [default: $DEFAULT_TAG]
    -r, --registry REGISTRY  Registry Docker [default: $DEFAULT_REGISTRY]
    -n, --name NAME          Nome da imagem [default: $DEFAULT_IMAGE_NAME]
    -j, --java-version VER   Versão do Java [default: $DEFAULT_JAVA_VERSION]
    -m, --maven-version VER  Versão do Maven [default: $DEFAULT_MAVEN_VERSION]
    --skip-tests             Pular testes durante o build
    --no-cache               Build sem cache
    --push                   Push para registry após build
    --multi-arch             Build para múltiplas arquiteturas
    -h, --help               Mostrar esta ajuda

EXAMPLES:
    # Build para produção
    $0 -e prod -t v1.0.0

    # Build para teste com push
    $0 -e test -t latest --push

    # Build para desenvolvimento sem cache
    $0 -e dev --no-cache

    # Build multi-arquitetura para produção
    $0 -e prod -t v1.0.0 --multi-arch --push

ENVIRONMENTS:
    prod    - Produção (otimizado, sem fallbacks)
    test    - Teste (configurações relaxadas)
    dev     - Desenvolvimento (debug habilitado)
EOF
}

# Parsing de argumentos
ENVIRONMENT="$DEFAULT_ENVIRONMENT"
TAG="$DEFAULT_TAG"
REGISTRY="$DEFAULT_REGISTRY"
IMAGE_NAME="$DEFAULT_IMAGE_NAME"
JAVA_VERSION="$DEFAULT_JAVA_VERSION"
MAVEN_VERSION="$DEFAULT_MAVEN_VERSION"
SKIP_TESTS="true"
NO_CACHE=""
PUSH="false"
MULTI_ARCH="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -j|--java-version)
            JAVA_VERSION="$2"
            shift 2
            ;;
        -m|--maven-version)
            MAVEN_VERSION="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS="true"
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --push)
            PUSH="true"
            shift
            ;;
        --multi-arch)
            MULTI_ARCH="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validar ambiente
if [[ ! "$ENVIRONMENT" =~ ^(prod|test|dev)$ ]]; then
    log_error "Ambiente inválido: $ENVIRONMENT. Use: prod, test, ou dev"
    exit 1
fi

# Construir nome completo da imagem
FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME"
FULL_TAG="$FULL_IMAGE_NAME:$TAG"
ENV_TAG="$FULL_IMAGE_NAME:$ENVIRONMENT-$TAG"

# Banner
echo "============================================================================="
echo "🐳 BUILD CONSOLIDADO - CONEXÃO DE SORTE BACKEND"
echo "============================================================================="
echo
log_info "Configurações do build:"
echo "  📦 Imagem: $FULL_TAG"
echo "  🏷️  Tag ambiente: $ENV_TAG"
echo "  🌍 Ambiente: $ENVIRONMENT"
echo "  ☕ Java: $JAVA_VERSION"
echo "  📦 Maven: $MAVEN_VERSION"
echo "  🧪 Skip tests: $SKIP_TESTS"
echo "  🚀 Push: $PUSH"
echo "  🏗️  Multi-arch: $MULTI_ARCH"
echo

# Verificar se Docker está rodando
log_info "Verificando Docker..."
if ! docker info >/dev/null 2>&1; then
    log_error "Docker não está rodando. Por favor, inicie o Docker."
    exit 1
fi
log_success "Docker está rodando."

# Verificar se Dockerfile existe
if [[ ! -f "Dockerfile.multistage" ]]; then
    log_error "Dockerfile.multistage não encontrado."
    exit 1
fi

# Configurar argumentos de build
BUILD_ARGS=(
    "--build-arg" "ENVIRONMENT=$ENVIRONMENT"
    "--build-arg" "JAVA_VERSION=$JAVA_VERSION"
    "--build-arg" "MAVEN_VERSION=$MAVEN_VERSION"
    "--build-arg" "SKIP_TESTS=$SKIP_TESTS"
)

# Configurar Azure Key Vault baseado no ambiente
if [[ "$ENVIRONMENT" == "prod" ]]; then
    BUILD_ARGS+=("--build-arg" "ENABLE_AZURE_KEYVAULT=true")
else
    BUILD_ARGS+=("--build-arg" "ENABLE_AZURE_KEYVAULT=false")
fi

# Executar build
log_info "Iniciando build da imagem..."

if [[ "$MULTI_ARCH" == "true" ]]; then
    log_info "Build multi-arquitetura habilitado..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        "${BUILD_ARGS[@]}" \
        $NO_CACHE \
        -f Dockerfile.multistage \
        -t "$FULL_TAG" \
        -t "$ENV_TAG" \
        $([ "$PUSH" == "true" ] && echo "--push" || echo "--load") \
        .
else
    docker build \
        "${BUILD_ARGS[@]}" \
        $NO_CACHE \
        -f Dockerfile.multistage \
        -t "$FULL_TAG" \
        -t "$ENV_TAG" \
        .
fi

if [[ $? -eq 0 ]]; then
    log_success "Build concluído com sucesso!"
    echo "  📦 Imagem: $FULL_TAG"
    echo "  🏷️  Tag ambiente: $ENV_TAG"
else
    log_error "Falha no build da imagem."
    exit 1
fi

# Push se solicitado
if [[ "$PUSH" == "true" && "$MULTI_ARCH" != "true" ]]; then
    log_info "Fazendo push da imagem..."
    docker push "$FULL_TAG"
    docker push "$ENV_TAG"
    
    if [[ $? -eq 0 ]]; then
        log_success "Push concluído com sucesso!"
    else
        log_error "Falha no push da imagem."
        exit 1
    fi
fi

# Mostrar informações da imagem
log_info "Informações da imagem:"
docker images | grep "$REGISTRY/$IMAGE_NAME" | head -5

echo
log_success "🎉 Build consolidado concluído com sucesso!"
echo "Para executar a imagem:"
echo "  docker run -p 8080:8080 $FULL_TAG"
