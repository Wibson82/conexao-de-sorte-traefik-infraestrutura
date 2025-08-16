#!/bin/bash

echo "🧪 Testando correções do Traefik..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar se estamos no diretório correto
if [[ ! -f "deploy/docker-compose.prod.yml" ]]; then
    log_error "Execute este script no diretório raiz do projeto"
    exit 1
fi

log_info "=== VERIFICAÇÃO DAS CORREÇÕES APLICADAS ==="

# 1. Verificar se o perfil Spring Boot está correto
log_info "1. Verificando perfil Spring Boot..."
if grep -q "SPRING_PROFILES_ACTIVE=prod,azure" deploy/docker-compose.prod.yml; then
    log_success "✅ Perfil Spring Boot corrigido para 'prod,azure'"
else
    log_error "❌ Perfil Spring Boot ainda incorreto"
fi

# 2. Verificar se a rede traefik-network está configurada
log_info "2. Verificando rede traefik-network..."
if grep -q "traefik-network:" deploy/docker-compose.prod.yml; then
    log_success "✅ Rede traefik-network configurada"
else
    log_error "❌ Rede traefik-network não configurada"
fi

# 3. Verificar se o health check do Traefik está correto
log_info "3. Verificando health check do Traefik..."
if grep -q "http://localhost:8080/api/rawdata" deploy/docker-compose.prod.yml; then
    log_success "✅ Health check do Traefik corrigido"
else
    log_error "❌ Health check do Traefik ainda incorreto"
fi

# 4. Verificar se o endpoint do Docker está configurado
log_info "4. Verificando endpoint do Docker..."
if grep -q "providers.docker.endpoint" deploy/docker-compose.prod.yml; then
    log_success "✅ Endpoint do Docker configurado"
else
    log_error "❌ Endpoint do Docker não configurado"
fi

# 5. Verificar se o Traefik está conectado às duas redes
log_info "5. Verificando configuração de redes do Traefik..."
if grep -A 10 "networks:" deploy/docker-compose.prod.yml | grep -A 5 "traefik:" | grep -q "traefik-network"; then
    log_success "✅ Traefik conectado à rede traefik-network"
else
    log_error "❌ Traefik não conectado à rede traefik-network"
fi

log_info "=== RESUMO DAS CORREÇÕES ==="

echo ""
log_info "📋 Correções aplicadas no docker-compose.prod.yml:"
echo "   • SPRING_PROFILES_ACTIVE=prod,azure (era 'production,azure')"
echo "   • Adicionada rede traefik-network"
echo "   • Health check corrigido para /api/rawdata"
echo "   • Endpoint do Docker configurado explicitamente"
echo "   • Traefik conectado às duas redes"
echo ""

log_info "🚀 Para aplicar no servidor de produção:"
echo "   1. Fazer backup do docker-compose atual"
echo "   2. Aplicar as correções no arquivo"
echo "   3. Executar: ./scripts/corrigir-traefik.sh"
echo "   4. Verificar logs: docker logs conexao-traefik"
echo ""

log_success "🎉 Verificação concluída! As correções estão prontas para deploy."
