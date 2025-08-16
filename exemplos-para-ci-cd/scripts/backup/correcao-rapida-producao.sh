#!/bin/bash

# Script de correção rápida para problemas de produção
# - Corrigir Traefik com problemas de conexão
# - Verificar e corrigir roteamento
# - Testar conectividade

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

log_header "CORREÇÃO RÁPIDA DE PRODUÇÃO"

# 1. Verificar status atual
log_header "1. VERIFICANDO STATUS ATUAL"

log_info "Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(frontend|backend|traefik)" || true

# 2. Verificar portas em uso
log_header "2. VERIFICANDO PORTAS"

log_info "Portas em uso:"
netstat -tuln 2>/dev/null | grep -E ":(80|443|3000|8080) " || log_info "Nenhuma das portas principais está em uso"

# 3. Corrigir Traefik
log_header "3. CORRIGINDO TRAEFIK"

if docker ps --format "table {{.Names}}" | grep -q "traefik"; then
    log_info "Traefik está rodando - verificando problemas..."

    # Verificar se Traefik está respondendo
    if curl -f -s -o /dev/null http://localhost:8080/ping 2>/dev/null; then
        log_success "Traefik está respondendo corretamente"
    else
        log_warning "Traefik não está respondendo - reiniciando..."

        # Parar Traefik
        docker stop traefik
        log_info "Traefik parado"

        # Aguardar liberação das portas
        sleep 5

        # Recriar Traefik com configuração correta
        log_info "Recriando Traefik..."
        docker run -d --name traefik \
            -p 80:80 -p 443:443 -p 8080:8080 \
            --network traefik-network \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            -v /home/ubuntu/traefik:/etc/traefik \
            --restart unless-stopped \
            traefik:v3.0 \
            --api.dashboard=true \
            --api.insecure=true \
            --providers.docker=true \
            --providers.docker.exposedbydefault=false \
            --providers.docker.network=traefik-network \
            --entrypoints.web.address=:80 \
            --entrypoints.websecure.address=:443 \
            --entrypoints.web.http.redirections.entrypoint.to=websecure \
            --entrypoints.web.http.redirections.entrypoint.scheme=https \
            --entrypoints.web.http.redirections.entrypoint.permanent=true \
            --certificatesresolvers.letsencrypt.acme.email=facilitaservicos.tec@gmail.com \
            --certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme.json \
            --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web \
            --certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory \
            --log.level=INFO \
            --accesslog=true \
            --log.format=json \
            --serverstransport.insecureskipverify=false \
            --global.sendanonymoususage=false

        log_success "Traefik recriado"
        sleep 10
    fi
else
    log_error "Traefik não está rodando"
fi

# 4. Verificar roteamento
log_header "4. VERIFICANDO ROTEAMENTO"

log_info "Verificando rotas do Traefik..."
if curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "backend"; then
    log_success "Rota do backend configurada"
else
    log_warning "Rota do backend não encontrada"
fi

if curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -q "frontend"; then
    log_success "Rota do frontend configurada"
else
    log_warning "Rota do frontend não encontrada"
fi

# 5. Verificar backend
log_header "5. VERIFICANDO BACKEND"

if docker ps --format "table {{.Names}}" | grep -q "backend-prod"; then
    log_info "Backend está rodando - verificando health..."

    # Aguardar backend inicializar
    log_info "Aguardando backend inicializar completamente..."
    sleep 30

    # Verificar health do backend
    if curl -f -s -o /dev/null http://localhost:8080/actuator/health 2>/dev/null; then
        log_success "Backend está saudável"
    else
        log_warning "Backend pode não estar totalmente funcional"
        log_info "Últimas linhas do log do backend:"
        docker logs backend-prod --tail 10 || true
    fi
else
    log_error "Backend não está rodando"
fi

# 6. Verificar frontend
log_header "6. VERIFICANDO FRONTEND"

if docker ps --format "table {{.Names}}" | grep -q "frontend-prod"; then
    log_info "Frontend está rodando"

    # Verificar se frontend está respondendo
    if curl -f -s -o /dev/null http://localhost:3000 2>/dev/null; then
        log_success "Frontend está respondendo na porta 3000"
    else
        log_warning "Frontend não está respondendo na porta 3000"
    fi
else
    log_error "Frontend não está rodando"
fi

# 7. Testar conectividade externa
log_header "7. TESTANDO CONECTIVIDADE EXTERNA"

log_info "Testando conectividade do domínio..."
if curl -f -s -o /dev/null https://conexaodesorte.com.br 2>/dev/null; then
    log_success "Domínio principal respondendo"
else
    log_warning "Domínio principal não respondendo"
fi

if curl -f -s -o /dev/null https://conexaodesorte.com.br/rest/actuator/health 2>/dev/null; then
    log_success "API backend respondendo"
else
    log_warning "API backend não respondendo"
fi

# 8. Status final
log_header "8. STATUS FINAL"

log_info "Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(frontend|backend|traefik)" || true

log_info "Portas em uso:"
netstat -tuln 2>/dev/null | grep -E ":(80|443|3000|8080) " || log_info "Nenhuma das portas principais está em uso"

# 9. Recomendações
log_header "9. RECOMENDAÇÕES"

echo ""
log_info "Se ainda houver problemas:"
echo "1. Verifique logs: docker logs traefik --tail 20"
echo "2. Verifique logs: docker logs backend-prod --tail 20"
echo "3. Teste local: curl -f http://localhost:3000"
echo "4. Teste local: curl -f http://localhost:8080/actuator/health"
echo "5. Verifique DNS: nslookup conexaodesorte.com.br"
echo "6. Verifique firewall: ufw status"

log_header "CORREÇÃO CONCLUÍDA"
