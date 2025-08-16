#!/bin/bash

# =============================================================================
# GARANTIR FRONTEND FUNCIONANDO
# =============================================================================
# Este script garante que o frontend esteja sempre funcionando
# Verifica se está rodando e recria se necessário
# =============================================================================

set -euo pipefail

# Cores para output
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

log_info "🌐 Verificando e garantindo frontend funcionando..."

# =============================================================================
# VERIFICAR STATUS ATUAL
# =============================================================================
log_info "🔍 Verificando status atual do frontend..."

echo "📊 Status de todos os containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10

echo ""
echo "🔍 Verificando especificamente o frontend:"

# Verificar se frontend está rodando
FRONTEND_RUNNING=false
FRONTEND_NAME=""

# Verificar possíveis nomes do frontend
for name in conexao-frontend frontend-prod frontend; do
    if docker ps | grep -q "$name"; then
        FRONTEND_RUNNING=true
        FRONTEND_NAME="$name"
        log_success "Frontend encontrado: $name"
        FRONTEND_STATUS=$(docker ps --format '{{.Status}}' --filter name=$name)
        echo "   Status: $FRONTEND_STATUS"
        break
    fi
done

if [[ "$FRONTEND_RUNNING" == "false" ]]; then
    log_warning "Frontend NÃO está rodando"
    
    # Verificar se existe parado
    for name in conexao-frontend frontend-prod frontend; do
        if docker ps -a | grep -q "$name"; then
            log_info "Container $name existe mas está parado"
            FRONTEND_STATUS=$(docker ps -a --format '{{.Status}}' --filter name=$name)
            echo "   Status: $FRONTEND_STATUS"
            FRONTEND_NAME="$name"
            break
        fi
    done
    
    if [[ -z "$FRONTEND_NAME" ]]; then
        log_info "Nenhum container de frontend encontrado"
        FRONTEND_NAME="conexao-frontend"
    fi
fi

# =============================================================================
# GARANTIR REDE
# =============================================================================
log_info "🌐 Garantindo rede conexao-network..."
docker network create conexao-network 2>/dev/null || true
log_success "Rede conexao-network disponível"

# =============================================================================
# RECRIAR FRONTEND SE NECESSÁRIO
# =============================================================================
if [[ "$FRONTEND_RUNNING" == "false" ]] || [[ "$1" == "--force" ]]; then
    log_info "🔧 Recriando frontend..."
    
    # Parar e remover frontend antigo
    log_info "🛑 Removendo frontend antigo..."
    for name in conexao-frontend frontend-prod frontend; do
        docker stop "$name" 2>/dev/null || true
        docker rm "$name" 2>/dev/null || true
    done
    log_success "Limpeza do frontend concluída"
    
    # Domínios
    DOMAIN_PRIMARY="conexaodesorte.com.br"
    DOMAIN_WWW="www.conexaodesorte.com.br"
    
    # Criar container do frontend
    log_info "🚀 Criando frontend..."
    docker run -d \
      --name conexao-frontend \
      --network conexao-network \
      --restart unless-stopped \
      --health-cmd='curl -f http://localhost:3000/ || exit 1' \
      --health-interval=60s \
      --health-timeout=30s \
      --health-retries=3 \
      --health-start-period=60s \
      -e TZ=America/Sao_Paulo \
      -e NODE_ENV=production \
      --label "traefik.enable=true" \
      --label "traefik.docker.network=conexao-network" \
      --label "traefik.http.routers.frontend-https.rule=(Host(\`$DOMAIN_PRIMARY\`) || Host(\`$DOMAIN_WWW\`)) && !PathPrefix(\`/rest\`) && !PathPrefix(\`/teste\`)" \
      --label "traefik.http.routers.frontend-https.entrypoints=websecure" \
      --label "traefik.http.routers.frontend-https.tls.certresolver=letsencrypt" \
      --label "traefik.http.routers.frontend-https.priority=1" \
      --label "traefik.http.services.conexao-frontend.loadbalancer.server.port=3000" \
      facilita/conexao-de-sorte-frontend:latest
    
    log_success "Frontend criado com sucesso!"
    
    # Aguardar inicialização
    log_info "⏳ Aguardando inicialização (60 segundos)..."
    sleep 60
    
else
    log_success "Frontend já está rodando"
fi

# =============================================================================
# VERIFICAÇÃO FINAL
# =============================================================================
log_info "🔍 Verificação final..."

# Verificar status
echo "📊 Status após verificação:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(frontend|conexao-frontend)" || echo "Frontend não encontrado"

# Testar conectividade direta
log_info "🧪 Testando conectividade direta..."
if docker exec conexao-frontend curl -f http://localhost:3000/ 2>/dev/null >/dev/null; then
    log_success "Frontend responde diretamente"
else
    log_warning "Frontend ainda não está respondendo diretamente"
fi

# Testar do host
if curl -f --connect-timeout 10 http://localhost:3000/ >/dev/null 2>&1; then
    log_success "Frontend acessível do host (porta 3000)"
else
    log_warning "Frontend ainda não está acessível do host"
fi

# =============================================================================
# VERIFICAR TRAEFIK
# =============================================================================
log_info "🌐 Verificando detecção pelo Traefik..."

# Aguardar Traefik detectar
sleep 30

# Verificar em ambas as portas possíveis do Traefik
TRAEFIK_DETECTED=false
if curl -s http://localhost:8090/api/http/routers 2>/dev/null | grep -q "frontend"; then
    log_success "Traefik detectou frontend (porta 8090)!"
    FRONTEND_ROUTERS=$(curl -s http://localhost:8090/api/http/routers 2>/dev/null | grep -c "frontend" || echo "0")
    echo "   Roteadores frontend: $FRONTEND_ROUTERS"
    TRAEFIK_DETECTED=true
elif curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "frontend"; then
    log_success "Traefik detectou frontend (porta 8080)!"
    FRONTEND_ROUTERS=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -c "frontend" || echo "0")
    echo "   Roteadores frontend: $FRONTEND_ROUTERS"
    TRAEFIK_DETECTED=true
else
    log_warning "Traefik ainda não detectou frontend"
fi

# Teste via Traefik local
echo "🔗 Teste via Traefik local:"
if curl -f --connect-timeout 10 http://localhost/ >/dev/null 2>&1; then
    log_success "Frontend acessível via Traefik local"
else
    log_warning "Frontend ainda não acessível via Traefik local"
fi

# =============================================================================
# RESUMO
# =============================================================================
log_success "🎉 Verificação do frontend concluída!"

echo ""
echo "📊 RESUMO:"
echo "=========="
echo ""

# Status final
FINAL_STATUS=$(docker ps --format '{{.Status}}' --filter name=conexao-frontend 2>/dev/null || echo "NÃO ENCONTRADO")
echo "🐳 Status do container: $FINAL_STATUS"

# Conectividade
DIRECT_TEST=$(docker exec conexao-frontend curl -f http://localhost:3000/ 2>/dev/null >/dev/null && echo "OK" || echo "FALHA")
HOST_TEST=$(curl -f --connect-timeout 5 http://localhost:3000/ >/dev/null 2>&1 && echo "OK" || echo "FALHA")
TRAEFIK_TEST=$(curl -f --connect-timeout 5 http://localhost/ >/dev/null 2>&1 && echo "OK" || echo "FALHA")

echo "🌐 Conectividade:"
echo "   Direto (3000): $DIRECT_TEST"
echo "   Host (3000): $HOST_TEST"
echo "   Traefik (/): $TRAEFIK_TEST"

# Traefik
if [[ "$TRAEFIK_DETECTED" == "true" ]]; then
    echo "🔀 Traefik: DETECTADO"
else
    echo "🔀 Traefik: NÃO DETECTADO"
fi

echo ""
echo "🌐 URLs PARA TESTAR:"
echo "   🌐 Local: http://localhost/"
echo "   🌐 Direto: http://localhost:3000/"
echo "   🌐 Externo: https://www.conexaodesorte.com.br/"

echo ""
if [[ "$FINAL_STATUS" =~ "Up" ]]; then
    if [[ "$TRAEFIK_TEST" == "OK" ]]; then
        log_success "✅ FRONTEND FUNCIONANDO PERFEITAMENTE!"
    else
        log_warning "⚠️ Frontend rodando mas Traefik pode precisar de mais tempo"
        echo "💡 Aguarde alguns minutos para propagação SSL"
    fi
else
    log_error "❌ Problema com o frontend"
    echo "🔍 Verificar logs: docker logs conexao-frontend"
fi

log_success "✅ Verificação concluída!"
