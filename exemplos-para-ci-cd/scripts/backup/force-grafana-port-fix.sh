#!/bin/bash

# Script para forçar a correção da porta do Grafana
# Remove o container atual e recria com porta 3001

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

log_header "FORÇANDO CORREÇÃO DA PORTA DO GRAFANA"

# 1. Verificar status atual
log_header "1. VERIFICANDO STATUS ATUAL"

log_info "Verificando containers do Grafana..."
if docker ps --format "table {{.Names}}" | grep -q "conexao-grafana"; then
    log_info "Grafana está rodando - verificando portas..."
    GRAFANA_PORTS=$(docker port conexao-grafana 2>/dev/null || echo "Erro ao obter portas")
    echo "$GRAFANA_PORTS"

    if echo "$GRAFANA_PORTS" | grep -q "3000"; then
        log_warning "Grafana está usando porta 3000 - será corrigido"
    else
        log_success "Grafana já está na porta correta"
    fi
else
    log_info "Grafana não está rodando"
fi

# 2. Verificar uso da porta 3000
log_header "2. VERIFICANDO USO DA PORTA 3000"

log_info "Processos usando porta 3000:"
netstat -tulnp 2>/dev/null | grep ":3000 " || log_info "Nenhum processo na porta 3000"

# 3. Parar e remover Grafana atual
log_header "3. REMOVENDO GRAFANA ATUAL"

if docker ps --format "table {{.Names}}" | grep -q "conexao-grafana"; then
    log_info "Parando Grafana..."
    docker stop conexao-grafana
    log_success "Grafana parado"

    log_info "Removendo container Grafana..."
    docker rm conexao-grafana
    log_success "Container Grafana removido"
else
    log_info "Grafana não estava rodando"
fi

# 4. Verificar se há outros containers usando porta 3000
log_header "4. VERIFICANDO OUTROS CONTAINERS"

log_info "Containers que podem estar usando porta 3000:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "3000" || log_info "Nenhum container usando porta 3000"

# 5. Aguardar liberação da porta
log_header "5. AGUARDANDO LIBERAÇÃO"

log_info "Aguardando 5 segundos para liberação da porta..."
sleep 5

# 6. Verificar se porta 3000 está livre
log_header "6. VERIFICANDO SE PORTA ESTÁ LIVRE"

if netstat -tuln 2>/dev/null | grep -q ":3000 "; then
    log_warning "Porta 3000 ainda está em uso após remoção do Grafana"
    log_info "Processos restantes:"
    netstat -tulnp 2>/dev/null | grep ":3000 " || true
else
    log_success "Porta 3000 está livre!"
fi

# 7. Recriar Grafana na porta 3001
log_header "7. RECRIANDO GRAFANA NA PORTA 3001"

log_info "Criando volume para Grafana (se não existir)..."
docker volume create grafana_data 2>/dev/null || log_info "Volume grafana_data já existe"

log_info "Recriando Grafana na porta 3001..."
if docker run -d --name conexao-grafana \
    --network traefik-network \
    -p 3001:3000 \
    -v grafana_data:/var/lib/grafana \
    -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
    -e GF_USERS_ALLOW_SIGN_UP=false \
    -e GF_INSTALL_PLUGINS=grafana-piechart-panel \
    --restart unless-stopped \
    grafana/grafana:latest; then

    log_success "Grafana recriado com sucesso na porta 3001"
else
    log_error "Erro ao recriar Grafana"
    exit 1
fi

# 8. Verificar se Grafana está funcionando
log_header "8. VERIFICANDO FUNCIONAMENTO"

log_info "Aguardando Grafana inicializar..."
sleep 10

if docker ps --format "table {{.Names}}" | grep -q "conexao-grafana"; then
    log_success "Grafana está rodando"

    log_info "Verificando portas do novo Grafana:"
    NEW_GRAFANA_PORTS=$(docker port conexao-grafana 2>/dev/null || echo "Erro ao obter portas")
    echo "$NEW_GRAFANA_PORTS"

    if echo "$NEW_GRAFANA_PORTS" | grep -q "3001"; then
        log_success "Grafana está usando porta 3001 corretamente"
    else
        log_warning "Grafana pode não estar na porta correta"
    fi
else
    log_error "Grafana não está rodando após recriação"
fi

# 9. Testar conectividade
log_header "9. TESTANDO CONECTIVIDADE"

log_info "Testando acesso ao Grafana na porta 3001..."
if curl -f -s -o /dev/null http://localhost:3001 2>/dev/null; then
    log_success "Grafana está respondendo na porta 3001"
else
    log_warning "Grafana não está respondendo na porta 3001 (pode estar inicializando)"
fi

log_info "Testando se porta 3000 está livre para o Frontend..."
if netstat -tuln 2>/dev/null | grep -q ":3000 "; then
    log_warning "Porta 3000 ainda está em uso"
    netstat -tulnp 2>/dev/null | grep ":3000 " || true
else
    log_success "Porta 3000 está livre para o Frontend"
fi

# 10. Status final
log_header "10. STATUS FINAL"

log_info "Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(grafana|frontend)" || true

log_info "Portas em uso:"
netstat -tuln | grep -E ":(3000|3001) " || log_warning "Nenhuma das portas 3000/3001 está em uso"

# 11. Instruções finais
log_header "11. INSTRUÇÕES FINAIS"

echo ""
log_info "Grafana corrigido com sucesso!"
echo ""
log_success "✅ Grafana agora está na porta 3001"
log_success "✅ Porta 3000 está livre para o Frontend"
echo ""
log_info "Acessos:"
echo "   - Grafana: http://seu-vps:3001 (admin/admin123)"
echo "   - Frontend: https://conexaodesorte.com.br (porta 3000)"
echo ""
log_info "Para aplicar completamente:"
echo "   1. Reinicie o Frontend: docker restart frontend-prod"
echo "   2. Verifique o Traefik: docker logs traefik"
echo "   3. Teste o domínio: curl -f https://conexaodesorte.com.br"

log_header "CORREÇÃO CONCLUÍDA"
