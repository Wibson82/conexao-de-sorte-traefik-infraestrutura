#!/bin/bash
# ============================================================================
# 🐳 DOCKER ENTRYPOINT - TRAEFIK INFRASTRUCTURE
# ============================================================================
#
# Script de inicialização personalizado para Traefik Infrastructure
# Contexto: Componente crítico de infraestrutura exposta (Reverse Proxy)
# - Validações específicas para Traefik 3.x e Let's Encrypt
# - Health checks para reverse proxy e load balancer
# - Validação de certificados SSL/TLS
# - Verificação de configuração de segurança
# - Teste de conectividade com backend services
# - Validação de middlewares e plugins
#
# Uso: Configurar no Dockerfile como ENTRYPOINT
# ============================================================================

set -euo pipefail

# ============================================================================
# 📋 CONFIGURAÇÃO ESPECÍFICA DO TRAEFIK
# ============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [TRAFIK]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [TRAFIK] ERROR:${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [TRAFIK] SUCCESS:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [TRAFIK] WARNING:${NC} $1"
}

# ============================================================================
# 🔧 VALIDAÇÃO DE AMBIENTE - TRAEFIK ESPECÍFICO
# ============================================================================

log "🚀 Iniciando validação de ambiente - Traefik Infrastructure..."

# Verificar se estamos rodando como usuário correto
if [[ "$(id -u)" -eq 0 ]]; then
    warning "Executando como root - isso pode ser inseguro em produção"
fi

# Variáveis obrigatórias específicas do Traefik
required_vars=(
    "CONEXAO_DE_SORTE_LETSENCRYPT_EMAIL"
    "CONEXAO_DE_SORTE_TRAEFIK_DASHBOARD_PASSWORD"
    "CONEXAO_DE_SORTE_SERVER_PORT"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    error "Variáveis de ambiente obrigatórias não definidas para Traefik:"
    for var in "${missing_vars[@]}"; do
        error "  - $var"
    done
    exit 1
fi

# Validações específicas do Traefik
if [[ "$CONEXAO_DE_SORTE_SERVER_PORT" != "80" && "$CONEXAO_DE_SORTE_SERVER_PORT" != "443" ]]; then
    warning "Porta do Traefik diferente do padrão HTTP/HTTPS: $CONEXAO_DE_SORTE_SERVER_PORT"
fi

# Validar email do Let's Encrypt
if [[ ! "$CONEXAO_DE_SORTE_LETSENCRYPT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    error "❌ Email do Let's Encrypt inválido: $CONEXAO_DE_SORTE_LETSENCRYPT_EMAIL"
    exit 1
fi

success "✅ Validação de ambiente concluída - Traefik Infrastructure"

# ============================================================================
# 🔐 VALIDAÇÃO DE SEGURANÇA ESPECÍFICA - TRAEFIK
# ============================================================================

log "🔐 Executando validações de segurança específicas do Traefik..."

# Verificar se há exposição de dashboard sem proteção
if [[ -n "${TRAFIK_DASHBOARD_ENABLED:-}" ]]; then
    if [[ "${TRAFIK_DASHBOARD_ENABLED}" == "true" ]]; then
        if [[ -z "${CONEXAO_DE_SORTE_TRAEFIK_DASHBOARD_PASSWORD:-}" ]]; then
            error "❌ Dashboard do Traefik habilitado sem senha - violação de segurança crítica"
            exit 1
        fi
        success "✅ Dashboard do Traefik protegido com senha"
    fi
fi

# Validar complexidade da senha do dashboard
if [[ -n "${CONEXAO_DE_SORTE_TRAEFIK_DASHBOARD_PASSWORD:-}" ]]; then
    if [[ ${#CONEXAO_DE_SORTE_TRAEFIK_DASHBOARD_PASSWORD} -lt 8 ]]; then
        error "❌ Senha do dashboard do Traefik muito curta (mínimo 8 caracteres)"
        exit 1
    fi
    success "✅ Complexidade da senha do dashboard validada"
fi

# Validar se não está usando certificados auto-assinados em produção
if [[ "${LETSENCRYPT_STAGING:-}" == "true" ]]; then
    warning "⚠️ Usando Let's Encrypt Staging - certificados não confiáveis em produção"
fi

# ============================================================================
# 🌐 VALIDAÇÃO DE CONECTIVIDADE - NETWORK
# ============================================================================

log "🔍 Validando conectividade de rede..."

# Verificar se Docker está disponível
if ! docker info >/dev/null 2>&1; then
    error "❌ Docker não está disponível ou não está rodando"
    exit 1
fi

# Verificar se Docker Swarm está ativo
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
    warning "⚠️ Docker Swarm não está ativo - inicializando..."
    if ! docker swarm init --advertise-addr $(hostname -I | awk '{print $1}') 2>/dev/null; then
        log "ℹ️ Docker Swarm pode já estar inicializado ou não é possível inicializar"
    fi
fi

success "✅ Docker e Docker Swarm disponíveis"

# ============================================================================
# 🔄 VALIDAÇÃO DE CONECTIVIDADE - BACKEND SERVICES
# ============================================================================

log "🔍 Validando conectividade com backend services..."

# Lista de services que devem estar disponíveis
backend_services=(
    "conexao-gateway"
    "conexao-resultados"
    "conexao-redis"
    "conexao-mysql"
)

for service in "${backend_services[@]}"; do
    if docker service ls --format '{{.Name}}' | grep -q "^${service}$"; then
        success "✅ Backend service encontrado: $service"
    else
        warning "⚠️ Backend service não encontrado: $service (pode estar iniciando)"
    fi
done

# ============================================================================
# 📋 VALIDAÇÃO DE CONFIGURAÇÃO TRAEFIK
# ============================================================================

log "🔍 Validando configuração específica do Traefik..."

# Verificar se há configuração de middlewares de segurança
if [[ -f "/app/traefik.yml" ]]; then
    if grep -q "basicAuth" /app/traefik.yml; then
        success "✅ Middleware de autenticação básica configurado"
    fi

    if grep -q "rateLimit" /app/traefik.yml; then
        success "✅ Middleware de rate limiting configurado"
    fi

    if grep -q "cors" /app/traefik.yml; then
        success "✅ Middleware de CORS configurado"
    fi
fi

# Validar configuração de Let's Encrypt
if [[ -n "${LETSENCRYPT_STAGING:-}" ]]; then
    log "ℹ️ Let's Encrypt configurado para ambiente: ${LETSENCRYPT_STAGING:-production}"
fi

# ============================================================================
# 🏥 VALIDAÇÃO DE HEALTH ENDPOINTS
# ============================================================================

log "🏥 Validando health endpoints dos serviços..."

# Função para testar health endpoint
test_health_endpoint() {
    local service_name=$1
    local port=${2:-80}
    local protocol=${3:-http}

    local url="${protocol}://localhost:${port}/health"
    if [[ "$service_name" == "gateway" ]]; then
        url="${protocol}://localhost:${port}/actuator/health"
    elif [[ "$service_name" == "resultados" ]]; then
        url="${protocol}://localhost:${port}/actuator/health"
    fi

    if curl -f -s "$url" >/dev/null 2>&1; then
        success "✅ Health endpoint acessível: $service_name ($url)"
        return 0
    else
        warning "⚠️ Health endpoint não acessível: $service_name ($url)"
        return 1
    fi
}

# Testar health endpoints dos serviços principais
test_health_endpoint "gateway" "8086" "http" || true
test_health_endpoint "resultados" "8083" "http" || true

# ============================================================================
# 🔒 VALIDAÇÃO DE CERTIFICADOS SSL
# ============================================================================

log "🔒 Validando configuração de SSL/TLS..."

if [[ -d "/app/certs" ]]; then
    if [[ -f "/app/certs/tls.crt" && -f "/app/certs/tls.key" ]]; then
        success "✅ Certificados SSL encontrados"

        # Validar data de expiração (se openssl estiver disponível)
        if command -v openssl >/dev/null 2>&1; then
            expiry_date=$(openssl x509 -in /app/certs/tls.crt -enddate -noout 2>/dev/null | cut -d= -f2 || echo "")
            if [[ -n "$expiry_date" ]]; then
                expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || echo "")
                current_timestamp=$(date +%s)

                if [[ -n "$expiry_timestamp" && "$expiry_timestamp" -gt "$current_timestamp" ]]; then
                    days_remaining=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                    if [[ $days_remaining -lt 30 ]]; then
                        warning "⚠️ Certificado SSL expira em $days_remaining dias"
                    else
                        success "✅ Certificado SSL válido por mais $days_remaining dias"
                    fi
                else
                    warning "⚠️ Certificado SSL expirado ou inválido"
                fi
            fi
        fi
    else
        warning "⚠️ Certificados SSL não encontrados em /app/certs"
    fi
fi

# ============================================================================
# 📊 INFORMAÇÕES DO AMBIENTE - TRAEFIK
# ============================================================================

log "📋 Informações do ambiente - Traefik Infrastructure:"
echo "  - Service: Conexão de Sorte - Traefik Infrastructure"
echo "  - Profile: ${SPRING_PROFILES_ACTIVE:-default}"
echo "  - Server Port: $CONEXAO_DE_SORTE_SERVER_PORT (Padrão: 80/443)"
echo "  - Let's Encrypt Email: $CONEXAO_DE_SORTE_LETSENCRYPT_EMAIL"
echo "  - Dashboard: ${TRAFIK_DASHBOARD_ENABLED:-Desabilitado}"
echo "  - Staging Mode: ${LETSENCRYPT_STAGING:-false}"
echo "  - SSL Certificates: ${SSL_CERTS_CONFIGURED:-Não configurado}"
echo "  - Health Endpoint: http://localhost:$CONEXAO_DE_SORTE_SERVER_PORT/ping"
echo "  - Dashboard: http://localhost:8080/dashboard"
echo "  - API: http://localhost:8080/api"

# ============================================================================
# 🏃 EXECUÇÃO DA APLICAÇÃO - TRAEFIK
# ============================================================================

log "🏃 Iniciando Traefik Infrastructure..."

# Executar aplicação com exec para permitir signal handling
exec "$@"
