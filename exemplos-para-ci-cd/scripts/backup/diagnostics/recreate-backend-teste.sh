#!/bin/bash

# Script para recriar o backend-teste com configurações corretas
# Autor: Sistema de Deploy Automatizado
# Data: 29/07/2025

set -e

# Cores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Configurações padrão
IMAGE_TAG="${1:-latest}"
DB_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}"
DB_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-senha123}"
AZURE_KEYVAULT_ENDPOINT="${AZURE_KEYVAULT_ENDPOINT:-}"
AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-}"
AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET:-}"
AZURE_TENANT_ID="${AZURE_TENANT_ID:-}"
APP_ENCRYPTION_MASTER_PASSWORD="${APP_ENCRYPTION_MASTER_PASSWORD:-default-password}"

log_header "CRIAÇÃO AUTOMÁTICA DO BACKEND-TESTE"

# 1. Limpeza completa do backend-teste
log_info "FORÇANDO remoção do container backend-teste..."
if docker ps -a --format "{{.Names}}" | grep -q "^backend-teste$"; then
    log_info "Container backend-teste encontrado, removendo..."
    docker stop backend-teste 2>/dev/null || log_warning "Container não estava rodando"
    docker rm backend-teste 2>/dev/null || log_warning "Container não existia"
else
    log_info "Nenhum container backend-teste encontrado"
fi

log_info "Parando backend-teste..."
docker stop backend-teste 2>/dev/null || echo "Container não estava rodando"

log_info "Removendo backend-teste..."
docker rm backend-teste 2>/dev/null || echo "Container não existia"

log_success "Limpeza completa do backend-teste realizada"

# 2. Verificar rede
log_info "Verificando rede conexao-network..."
if docker network ls | grep -q "conexao-network"; then
    log_success "Rede conexao-network não encontrada, criando..."
    docker network create conexao-network 2>/dev/null || echo "Rede já existe"
else
    log_success "Rede já existe"
fi
log_success "Rede conexao-network criada/verificada"

# 3. Conectar Traefik à rede
if docker ps --format "{{.Names}}" | grep -q "^traefik$"; then
    log_info "Conectando Traefik à rede conexao-network..."
    docker network connect conexao-network traefik 2>/dev/null || echo "Traefik já conectado"
    log_success "Traefik conectado à rede"
else
    log_warning "Traefik não está rodando - backend-teste pode não funcionar corretamente"
fi

# 4. Verificar e baixar imagem
log_info "Verificando imagem backend-teste..."
IMAGE_NAME="facilita/conexao-de-sorte-backend-teste:$IMAGE_TAG"
log_info "Imagem alvo: $IMAGE_NAME"

if docker pull "$IMAGE_NAME" 2>/dev/null; then
    log_success "Imagem $IMAGE_NAME encontrada e baixada"
else
    log_warning "Imagem $IMAGE_NAME não encontrada"
    log_info "Tentando imagem latest..."
    IMAGE_NAME="facilita/conexao-de-sorte-backend-teste:latest"
    if docker pull "$IMAGE_NAME" 2>/dev/null; then
        log_success "Usando imagem latest"
    else
        log_error "Nenhuma imagem de teste encontrada"
        log_info "Usando imagem de produção como fallback..."
        IMAGE_NAME="facilita/conexao-de-sorte-backend:latest"
        docker pull "$IMAGE_NAME"
        log_warning "ATENÇÃO: Usando imagem de produção para teste"
    fi
fi

# 5. Criar container backend-teste
log_info "Criando container backend-teste..."
log_info "Configuração:"
echo "   • Imagem: $IMAGE_NAME"
echo "   • Rede: conexao-network"
echo "   • Porta: 8081"
echo "   • Profile: test,local-fallback"
echo "   • Environment: test"

log_info "Criando container backend-teste..."
docker run -d \
  --name backend-teste \
  --network conexao-network \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=test,local-fallback \
  -e ENVIRONMENT=test \
  -e SERVER_PORT=8081 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
  -e SPRING_DATASOURCE_USERNAME="$DB_USERNAME" \
  -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
  -e AZURE_KEYVAULT_ENABLED=false \
  -e AZURE_KEYVAULT_FALLBACK_ENABLED=true \
  -e AZURE_KEYVAULT_ENDPOINT="$AZURE_KEYVAULT_ENDPOINT" \
  -e AZURE_CLIENT_ID="$AZURE_CLIENT_ID" \
  -e AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET" \
  -e AZURE_TENANT_ID="$AZURE_TENANT_ID" \
  -e APP_ENCRYPTION_MASTER_PASSWORD="$APP_ENCRYPTION_MASTER_PASSWORD" \
  -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC" \
  --label "com.conexaodesorte.service=backend" \
  --label "com.conexaodesorte.environment=test" \
  --label "com.conexaodesorte.version=$IMAGE_TAG" \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=conexao-network" \
  --label "traefik.http.routers.backend-teste-http.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)" \
  --label "traefik.http.routers.backend-teste-http.entrypoints=web" \
  --label "traefik.http.routers.backend-teste-http.priority=300" \
  --label "traefik.http.routers.backend-teste-http.middlewares=backend-teste-stripprefix" \
  --label "traefik.http.routers.backend-teste-https.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)" \
  --label "traefik.http.routers.backend-teste-https.entrypoints=websecure" \
  --label "traefik.http.routers.backend-teste-https.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.backend-teste-https.priority=300" \
  --label "traefik.http.routers.backend-teste-https.middlewares=backend-teste-stripprefix" \
  --label "traefik.http.services.backend-teste.loadbalancer.server.port=8081" \
  --label "traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste/rest" \
  "$IMAGE_NAME"

# 6. Verificação completa
log_header "VERIFICAÇÃO COMPLETA DO BACKEND-TESTE"

# Verificar se container está rodando
if docker ps --format "{{.Names}}" | grep -q "^backend-teste$"; then
    log_success "Container backend-teste está rodando"
    
    # Mostrar status
    log_info "Status do container:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|backend-teste)"
    
    # Verificar variáveis de ambiente críticas
    log_info "Verificando variáveis de ambiente críticas..."
    echo "SPRING_PROFILES_ACTIVE:"
    docker exec backend-teste env | grep SPRING_PROFILES_ACTIVE || echo "Não encontrada"
    echo "ENVIRONMENT:"
    docker exec backend-teste env | grep ENVIRONMENT || echo "Não encontrada"
    echo "SPRING_DATASOURCE_URL:"
    docker exec backend-teste env | grep SPRING_DATASOURCE_URL || echo "Não encontrada"
    
    # Aguardar inicialização
    log_info "Testando health check do backend-teste..."
    log_info "Tentativa 1/12 - aguardando health check..."
    
    # Aguardar health check
    for i in {1..12}; do
        if curl -f -s http://localhost:8081/actuator/health >/dev/null 2>&1; then
            log_success "Health check passou na tentativa $i/12"
            break
        else
            log_info "Tentativa $i/12 - aguardando health check..."
            sleep 5
        fi
        
        if [ $i -eq 12 ]; then
            log_warning "Health check falhou após 60 segundos"
            log_info "Logs recentes do backend-teste:"
            docker logs backend-teste --tail 10
        fi
    done
    
else
    log_error "Container backend-teste não está rodando"
    log_info "Logs do container:"
    docker logs backend-teste --tail 20 2>/dev/null || echo "Sem logs disponíveis"
fi

# 7. Verificar detecção pelo Traefik
if docker ps --format "{{.Names}}" | grep -q "^traefik$"; then
    log_info "Verificando roteadores Traefik para backend-teste..."
    
    # Aguardar detecção
    for i in {1..6}; do
        if curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "backend-teste"; then
            log_success "Traefik detectou backend-teste na tentativa $i/6"
            break
        else
            log_info "Tentativa $i/6 - aguardando detecção pelo Traefik..."
            sleep 10
        fi
        
        if [ $i -eq 6 ]; then
            log_warning "Roteadores backend-teste não detectados ainda"
            log_info "Verificando labels do container..."
            docker inspect backend-teste --format '{{range $key, $value := .Config.Labels}}{{if contains $key "traefik"}}{{$key}}: {{$value}}{{"\n"}}{{end}}{{end}}' | head -5
        fi
    done
else
    log_warning "Traefik não está rodando - roteamento não funcionará"
fi

log_header "RESUMO DA CRIAÇÃO"
echo ""
log_info "Status final:"
echo "• Container: $(docker ps --format "{{.Names}}" | grep -q "^backend-teste$" && echo "✅ RODANDO" || echo "❌ PARADO")"
echo "• Health check: $(curl -f -s http://localhost:8081/actuator/health >/dev/null 2>&1 && echo "✅ OK" || echo "❌ FALHOU")"
echo "• Traefik: $(curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "backend-teste" && echo "✅ DETECTADO" || echo "❌ NÃO DETECTADO")"

log_success "Criação do backend-teste concluída!"
