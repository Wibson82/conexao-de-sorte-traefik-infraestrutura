#!/bin/bash

# Script para limpar Traefik antes do deploy
# Garante que a nova configuração seja aplicada corretamente

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

# Função para verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar se Docker está disponível
if ! command_exists docker; then
    log_error "Docker não está instalado ou não está no PATH"
    exit 1
fi

# Verificar se Docker Compose está disponível
if ! command_exists docker-compose; then
    log_error "Docker Compose não está instalado ou não está no PATH"
    exit 1
fi

log_info "Iniciando limpeza do Traefik antes do deploy..."

# 1. Parar o Traefik atual
log_info "Parando Traefik atual..."
if docker ps --format "table {{.Names}}" | grep -q "traefik"; then
    docker stop traefik
    log_success "Traefik parado"
else
    log_warning "Traefik não estava rodando"
fi

# 2. Remover container do Traefik
log_info "Removendo container do Traefik..."
if docker ps -a --format "table {{.Names}}" | grep -q "traefik"; then
    docker rm traefik
    log_success "Container do Traefik removido"
else
    log_warning "Container do Traefik não encontrado"
fi

# 3. Remover volumes do Traefik (se existirem)
log_info "Removendo volumes do Traefik..."
if docker volume ls --format "table {{.Name}}" | grep -q "traefik"; then
    docker volume rm traefik 2>/dev/null || log_warning "Volume traefik não pôde ser removido"
    log_success "Volumes do Traefik removidos"
else
    log_warning "Nenhum volume do Traefik encontrado"
fi

# 4. Limpar configurações antigas do Traefik
log_info "Limpando configurações antigas do Traefik..."
if [ -d "/etc/traefik" ]; then
    sudo rm -rf /etc/traefik/*
    log_success "Configurações antigas removidas"
else
    log_warning "Diretório /etc/traefik não encontrado"
fi

# 5. Verificar e resolver conflitos de porta
log_info "Verificando conflitos de porta..."

# Verificar se há algo usando a porta 80
if netstat -tuln | grep ":80 " >/dev/null 2>&1; then
    log_warning "Porta 80 está em uso. Verificando processos..."
    netstat -tulnp | grep ":80 " || true
fi

# Verificar se há algo usando a porta 443
if netstat -tuln | grep ":443 " >/dev/null 2>&1; then
    log_warning "Porta 443 está em uso. Verificando processos..."
    netstat -tulnp | grep ":443 " || true
fi

# Verificar se há algo usando a porta 8080
if netstat -tuln | grep ":8080 " >/dev/null 2>&1; then
    log_warning "Porta 8080 está em uso. Verificando processos..."
    netstat -tulnp | grep ":8080 " || true
fi

# 6. Verificar conflito com Grafana na porta 3000
log_info "Verificando conflito com Grafana na porta 3000..."
if docker ps --format "table {{.Names}}" | grep -q "conexao-grafana"; then
    log_warning "Grafana está rodando e pode estar usando a porta 3000"
    log_info "Verificando portas do Grafana..."
    docker port conexao-grafana || true
fi

# 7. Limpar cache do Docker (opcional)
log_info "Limpando cache do Docker..."
docker system prune -f --volumes
log_success "Cache do Docker limpo"

# 8. Verificar se há containers órfãos
log_info "Verificando containers órfãos..."
ORPHANED_CONTAINERS=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | grep -E "(traefik|nginx)" || true)
if [ -n "$ORPHANED_CONTAINERS" ]; then
    log_warning "Containers órfãos encontrados:"
    echo "$ORPHANED_CONTAINERS"
    log_info "Removendo containers órfãos..."
    echo "$ORPHANED_CONTAINERS" | xargs -r docker rm
    log_success "Containers órfãos removidos"
else
    log_success "Nenhum container órfão encontrado"
fi

# 9. Verificar se há imagens antigas do Traefik
log_info "Verificando imagens antigas do Traefik..."
TRAEFIK_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(traefik|nginx)" || true)
if [ -n "$TRAEFIK_IMAGES" ]; then
    log_warning "Imagens antigas encontradas:"
    echo "$TRAEFIK_IMAGES"
    log_info "Removendo imagens antigas..."
    echo "$TRAEFIK_IMAGES" | xargs -r docker rmi
    log_success "Imagens antigas removidas"
else
    log_success "Nenhuma imagem antiga encontrada"
fi

# 10. Verificar status final
log_info "Verificando status final..."
log_info "Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

log_info "Portas em uso:"
netstat -tuln | grep -E ":(80|443|8080|3000) " || log_warning "Nenhuma das portas críticas está em uso"

# 11. Criar diretórios necessários
log_info "Criando diretórios necessários..."
sudo mkdir -p /etc/traefik/conf.d
sudo mkdir -p /etc/traefik/certs
sudo chmod 755 /etc/traefik
sudo chmod 755 /etc/traefik/conf.d
sudo chmod 755 /etc/traefik/certs
log_success "Diretórios criados com permissões corretas"

# 12. Verificar conectividade de rede
log_info "Verificando conectividade de rede..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log_success "Conectividade de rede OK"
else
    log_error "Problema de conectividade de rede"
fi

# 13. Verificar DNS
log_info "Verificando resolução DNS..."
if nslookup conexaodesorte.com.br >/dev/null 2>&1; then
    log_success "DNS funcionando para conexaodesorte.com.br"
else
    log_warning "Problema com DNS para conexaodesorte.com.br"
fi

if nslookup www.conexaodesorte.com.br >/dev/null 2>&1; then
    log_success "DNS funcionando para www.conexaodesorte.com.br"
else
    log_warning "Problema com DNS para www.conexaodesorte.com.br"
fi

log_success "Limpeza do Traefik concluída com sucesso!"
log_info "Agora você pode executar o deploy com a nova configuração do Traefik"

# 14. Recomendações
echo ""
log_info "Recomendações para o deploy:"
echo "1. Execute o deploy normalmente"
echo "2. Aguarde pelo menos 30 segundos após o deploy para o Traefik inicializar"
echo "3. Verifique se o Traefik está saudável: docker logs traefik"
echo "4. Teste a conectividade: curl -I https://conexaodesorte.com.br"
echo "5. Se houver problemas, verifique os logs: docker logs traefik --tail 50"

exit 0
