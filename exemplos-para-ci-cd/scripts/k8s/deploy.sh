#!/bin/bash

# =============================================================================
# SCRIPT DE DEPLOYMENT KUBERNETES Q2 2025 - CLOUD NATIVE
# =============================================================================
# Deploy completo da arquitetura Cloud Native do Conexão de Sorte
# Inclui: Production, Staging, Monitoring, Auto-scaling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
K8S_DIR="${PROJECT_ROOT}/k8s"

# Default values
ENVIRONMENT="${ENVIRONMENT:-production}"
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_TESTS="${SKIP_TESTS:-false}"
DRY_RUN="${DRY_RUN:-false}"
FORCE_RECREATE="${FORCE_RECREATE:-false}"

# Kubernetes configuration
KUBE_CONTEXT="${KUBE_CONTEXT:-conexao-de-sorte-cluster}"
REGISTRY="${REGISTRY:-registry.conexaodesorte.com}"
IMAGE_TAG="${IMAGE_TAG:-2025-q2-$(date +%Y%m%d-%H%M%S)}"

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)  echo -e "${GREEN}[INFO]${NC}  ${timestamp} - $message" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC}  ${timestamp} - $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" ;;
        DEBUG) echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" ;;
        *)     echo -e "         ${timestamp} - $message" ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    log INFO "Verificando pré-requisitos..."
    
    # Check required tools
    local required_tools=("kubectl" "docker" "mvn")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log ERROR "Ferramenta necessária não encontrada: $tool"
            exit 1
        fi
    done
    
    # Check Kubernetes connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log ERROR "Não foi possível conectar ao cluster Kubernetes"
        log INFO "Configure o contexto: kubectl config use-context $KUBE_CONTEXT"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log ERROR "Docker daemon não está rodando"
        exit 1
    fi
    
    log INFO "Pré-requisitos verificados com sucesso"
}

# Function to build and push Docker image
build_and_push_image() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        log INFO "Pulando build da imagem (SKIP_BUILD=true)"
        return
    fi
    
    log INFO "Construindo imagem Docker..."
    
    cd "$PROJECT_ROOT"
    
    # Build application
    if [[ "$SKIP_TESTS" != "true" ]]; then
        log INFO "Executando testes..."
        ./mvnw clean test
    fi
    
    # Build Docker image
    local image_name="$REGISTRY/conexao-de-sorte-backend:$IMAGE_TAG"
    local latest_name="$REGISTRY/conexao-de-sorte-backend:2025-q2-latest"
    
    log INFO "Construindo imagem: $image_name"
    docker build -t "$image_name" -t "$latest_name" --target production .
    
    # Push to registry
    log INFO "Enviando imagem para registry..."
    docker push "$image_name"
    docker push "$latest_name"
    
    log INFO "Imagem construída e enviada: $image_name"
}

# Function to create namespaces
create_namespaces() {
    log INFO "Criando namespaces..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/namespace.yaml"
    else
        kubectl apply -f "$K8S_DIR/namespace.yaml"
    fi
    
    log INFO "Namespaces criados/atualizados"
}

# Function to deploy secrets
deploy_secrets() {
    log INFO "Aplicando secrets..."
    
    # Check if secrets exist and are properly configured
    if [[ ! -f "$K8S_DIR/secrets.yaml" ]]; then
        log ERROR "Arquivo de secrets não encontrado: $K8S_DIR/secrets.yaml"
        log WARN "Certifique-se de configurar os secrets antes do deploy"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/secrets.yaml"
    else
        kubectl apply -f "$K8S_DIR/secrets.yaml"
    fi
    
    log INFO "Secrets aplicados"
}

# Function to deploy ConfigMaps
deploy_configmaps() {
    log INFO "Aplicando ConfigMaps..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/configmap-application.yaml"
    else
        kubectl apply -f "$K8S_DIR/configmap-application.yaml"
    fi
    
    log INFO "ConfigMaps aplicados"
}

# Function to deploy RBAC
deploy_rbac() {
    log INFO "Aplicando configurações RBAC..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/rbac.yaml"
    else
        kubectl apply -f "$K8S_DIR/rbac.yaml"
    fi
    
    log INFO "RBAC configurado"
}

# Function to deploy databases
deploy_databases() {
    log INFO "Aplicando bancos de dados..."
    
    # MySQL
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/database-mysql.yaml"
    else
        kubectl apply -f "$K8S_DIR/database-mysql.yaml"
    fi
    
    # Redis
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/redis-cache.yaml"
    else
        kubectl apply -f "$K8S_DIR/redis-cache.yaml"
    fi
    
    # Wait for databases to be ready
    if [[ "$DRY_RUN" != "true" ]]; then
        log INFO "Aguardando bancos de dados ficarem prontos..."
        kubectl wait --for=condition=ready pod -l app=mysql -n conexao-de-sorte --timeout=300s
        kubectl wait --for=condition=ready pod -l app=redis -n conexao-de-sorte --timeout=300s
        kubectl wait --for=condition=ready pod -l app=mysql -n conexao-de-sorte-staging --timeout=300s || true
        kubectl wait --for=condition=ready pod -l app=redis -n conexao-de-sorte-staging --timeout=300s || true
    fi
    
    log INFO "Bancos de dados aplicados"
}

# Function to deploy application
deploy_application() {
    log INFO "Aplicando aplicação backend..."
    
    # Update image tag in deployment
    local temp_deployment="/tmp/deployment-${ENVIRONMENT}.yaml"
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        sed "s|registry.conexaodesorte.com/conexao-de-sorte-backend:2025-q2-latest|$REGISTRY/conexao-de-sorte-backend:$IMAGE_TAG|g" \
            "$K8S_DIR/deployment-production.yaml" > "$temp_deployment"
    else
        sed "s|registry.conexaodesorte.com/conexao-de-sorte-backend:2025-q2-staging|$REGISTRY/conexao-de-sorte-backend:$IMAGE_TAG|g" \
            "$K8S_DIR/deployment-production-complete.yaml" > "$temp_deployment"
    fi
    
    # Apply deployment
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$temp_deployment"
    else
        kubectl apply -f "$temp_deployment"
    fi
    
    # Apply services
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/service.yaml"
    else
        kubectl apply -f "$K8S_DIR/service.yaml"
    fi
    
    # Apply ingress
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/ingress.yaml"
    else
        kubectl apply -f "$K8S_DIR/ingress.yaml"
    fi
    
    # Cleanup temp file
    rm -f "$temp_deployment"
    
    log INFO "Aplicação backend aplicada"
}

# Function to deploy auto-scaling
deploy_autoscaling() {
    log INFO "Aplicando auto-scaling..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/hpa-autoscaling.yaml"
    else
        kubectl apply -f "$K8S_DIR/hpa-autoscaling.yaml"
    fi
    
    log INFO "Auto-scaling configurado"
}

# Function to deploy monitoring
deploy_monitoring() {
    log INFO "Aplicando monitoramento..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        kubectl apply --dry-run=client -f "$K8S_DIR/monitoring-prometheus.yaml"
    else
        kubectl apply -f "$K8S_DIR/monitoring-prometheus.yaml"
    fi
    
    log INFO "Monitoramento aplicado"
}

# Function to wait for deployment
wait_for_deployment() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "Modo dry-run: pulando verificação de deployment"
        return
    fi
    
    log INFO "Aguardando deployment completar..."
    
    local namespace="conexao-de-sorte"
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        namespace="conexao-de-sorte-staging"
    fi
    
    # Wait for rollout to complete
    kubectl rollout status deployment/conexao-de-sorte-backend -n "$namespace" --timeout=600s
    
    # Check if pods are ready
    kubectl wait --for=condition=ready pod -l app=conexao-de-sorte-backend -n "$namespace" --timeout=300s
    
    log INFO "Deployment completado com sucesso"
}

# Function to run post-deployment checks
post_deployment_checks() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "Modo dry-run: pulando verificações pós-deployment"
        return
    fi
    
    log INFO "Executando verificações pós-deployment..."
    
    local namespace="conexao-de-sorte"
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        namespace="conexao-de-sorte-staging"
    fi
    
    # Check pod status
    local pod_count=$(kubectl get pods -l app=conexao-de-sorte-backend -n "$namespace" --no-headers | wc -l)
    local ready_pods=$(kubectl get pods -l app=conexao-de-sorte-backend -n "$namespace" --no-headers | grep -c "Running" || true)
    
    log INFO "Pods backend: $ready_pods/$pod_count rodando"
    
    # Check service endpoints
    local service_endpoints=$(kubectl get endpoints conexao-de-sorte-backend-service -n "$namespace" -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | jq length 2>/dev/null || echo "0")
    log INFO "Service endpoints: $service_endpoints"
    
    # Test health endpoint (if possible)
    local service_ip=$(kubectl get svc conexao-de-sorte-backend-internal -n "$namespace" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
    if [[ -n "$service_ip" ]]; then
        if kubectl run curl-test --image=curlimages/curl:8.4.0 --rm -i --restart=Never --timeout=60s -- \
           curl -f "http://$service_ip:8080/actuator/health" &>/dev/null; then
            log INFO "Health check: OK"
        else
            log WARN "Health check: Falhou (pode estar inicializando ainda)"
        fi
    fi
    
    log INFO "Verificações pós-deployment concluídas"
}

# Function to display deployment info
display_deployment_info() {
    log INFO "=== INFORMAÇÕES DO DEPLOYMENT ==="
    log INFO "Ambiente: $ENVIRONMENT"
    log INFO "Imagem: $REGISTRY/conexao-de-sorte-backend:$IMAGE_TAG"
    log INFO "Contexto K8s: $(kubectl config current-context)"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        local namespace="conexao-de-sorte"
        if [[ "$ENVIRONMENT" == "staging" ]]; then
            namespace="conexao-de-sorte-staging"
        fi
        
        log INFO "Pods:"
        kubectl get pods -l app=conexao-de-sorte-backend -n "$namespace"
        
        log INFO "Services:"
        kubectl get svc -l app=conexao-de-sorte-backend -n "$namespace"
        
        log INFO "Ingress:"
        kubectl get ingress -n "$namespace"
        
        log INFO "HPA:"
        kubectl get hpa -n "$namespace"
    fi
    
    log INFO "================================="
}

# Function to show usage
usage() {
    cat << EOF
Uso: $0 [OPTIONS]

Deploy da aplicação Conexão de Sorte no Kubernetes Q2 2025

OPÇÕES:
    -e, --environment ENV     Ambiente de deploy (production|staging) [default: production]
    -t, --image-tag TAG       Tag da imagem Docker [default: auto-gerado]
    -r, --registry REGISTRY   Registry Docker [default: registry.conexaodesorte.com]
    -k, --kube-context CTX    Contexto Kubernetes [default: conexao-de-sorte-cluster]
    --skip-build              Pula build da imagem Docker
    --skip-tests              Pula execução dos testes
    --dry-run                 Executa em modo dry-run (não aplica recursos)
    --force-recreate          Força recriação dos recursos
    -h, --help                Mostra esta ajuda

EXEMPLOS:
    # Deploy production completo
    $0 --environment production

    # Deploy staging sem build
    $0 --environment staging --skip-build

    # Dry run para verificar configurações
    $0 --dry-run

    # Deploy com tag específica
    $0 --image-tag v1.2.3

VARIÁVEIS DE AMBIENTE:
    ENVIRONMENT        Ambiente de deploy
    IMAGE_TAG          Tag da imagem Docker
    SKIP_BUILD         Pula build (true|false)
    SKIP_TESTS         Pula testes (true|false)
    DRY_RUN           Modo dry-run (true|false)
    KUBE_CONTEXT      Contexto Kubernetes
    REGISTRY          Registry Docker

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--image-tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -k|--kube-context)
            KUBE_CONTEXT="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD="true"
            shift
            ;;
        --skip-tests)
            SKIP_TESTS="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --force-recreate)
            FORCE_RECREATE="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log ERROR "Opção desconhecida: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "staging" ]]; then
    log ERROR "Ambiente inválido: $ENVIRONMENT (deve ser 'production' ou 'staging')"
    exit 1
fi

# Main deployment flow
main() {
    log INFO "=== INICIANDO DEPLOYMENT KUBERNETES Q2 2025 - CLOUD NATIVE ==="
    log INFO "Ambiente: $ENVIRONMENT"
    log INFO "Dry Run: $DRY_RUN"
    
    # Step 1: Prerequisites
    check_prerequisites
    
    # Step 2: Build and push image
    build_and_push_image
    
    # Step 3: Create namespaces
    create_namespaces
    
    # Step 4: Deploy secrets (must be done before other resources)
    deploy_secrets
    
    # Step 5: Deploy ConfigMaps
    deploy_configmaps
    
    # Step 6: Deploy RBAC
    deploy_rbac
    
    # Step 7: Deploy databases
    deploy_databases
    
    # Step 8: Deploy application
    deploy_application
    
    # Step 9: Deploy auto-scaling
    deploy_autoscaling
    
    # Step 10: Deploy monitoring
    deploy_monitoring
    
    # Step 11: Wait for deployment
    wait_for_deployment
    
    # Step 12: Post-deployment checks
    post_deployment_checks
    
    # Step 13: Display info
    display_deployment_info
    
    log INFO "=== DEPLOYMENT CONCLUÍDO COM SUCESSO! ==="
    
    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ "$ENVIRONMENT" == "production" ]]; then
            log INFO "Aplicação disponível em: https://api.conexaodesorte.com"
            log INFO "WebSockets em: wss://ws.conexaodesorte.com/ws"
        else
            log INFO "Staging disponível em: https://staging-api.conexaodesorte.com"
            log INFO "WebSockets em: wss://staging-ws.conexaodesorte.com/ws"
        fi
    fi
}

# Run main function
main "$@"