#!/bin/bash

# 🔧 CORREÇÃO AUTOMÁTICA SSL/TLS - Conexão de Sorte
# ✅ Script para corrigir problemas de certificado SSL automaticamente

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
DOMAIN="conexaodesorte.com.br"
WWW_DOMAIN="www.conexaodesorte.com.br"
TRAEFIK_CONTAINER="conexao-traefik"
COMPOSE_FILE="deploy/docker-compose.prod.yml"
BACKUP_DIR="backups/ssl-$(date +%Y%m%d-%H%M%S)"

# Funções de log
log_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║$(printf "%66s" | tr ' ' ' ')║${NC}"
    echo -e "${PURPLE}║$(printf "%*s" $(((66-${#1})/2)) "")${1}$(printf "%*s" $(((66-${#1})/2)) "")║${NC}"
    echo -e "${PURPLE}║$(printf "%66s" | tr ' ' ' ')║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
}

log_section() {
    echo -e "\n${CYAN}🔧 $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Função para confirmar ação
confirm_action() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Operação cancelada pelo usuário${NC}"
        exit 1
    fi
}

# Função para backup
create_backup() {
    log_step "Criando backup dos certificados..."
    mkdir -p "$BACKUP_DIR"
    
    if docker exec "$TRAEFIK_CONTAINER" test -f /certs/acme.json 2>/dev/null; then
        docker cp "$TRAEFIK_CONTAINER:/certs/acme.json" "$BACKUP_DIR/acme.json.backup" 2>/dev/null || true
        log_success "Backup criado em: $BACKUP_DIR/acme.json.backup"
    else
        log_warn "Arquivo acme.json não encontrado - pulando backup"
    fi
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_step "Verificando pré-requisitos..."
    
    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        exit 1
    fi
    
    # Verificar se Traefik existe
    if ! docker ps -a | grep -q "$TRAEFIK_CONTAINER"; then
        log_error "Container Traefik não encontrado: $TRAEFIK_CONTAINER"
        exit 1
    fi
    
    # Verificar se arquivo compose existe
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Arquivo docker-compose não encontrado: $COMPOSE_FILE"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Função para limpar certificados antigos
clean_old_certificates() {
    log_step "Limpando certificados antigos..."
    
    # Parar Traefik temporariamente
    log_info "Parando Traefik..."
    docker stop "$TRAEFIK_CONTAINER" 2>/dev/null || true
    
    # Remover arquivo acme.json
    log_info "Removendo acme.json..."
    docker exec "$TRAEFIK_CONTAINER" rm -f /certs/acme.json 2>/dev/null || true
    
    # Limpar cache de certificados
    log_info "Limpando cache de certificados..."
    docker exec "$TRAEFIK_CONTAINER" find /certs -name "*.crt" -delete 2>/dev/null || true
    docker exec "$TRAEFIK_CONTAINER" find /certs -name "*.key" -delete 2>/dev/null || true
    
    log_success "Certificados antigos removidos"
}

# Função para reiniciar Traefik
restart_traefik() {
    log_step "Reiniciando Traefik..."
    
    # Reiniciar container
    docker restart "$TRAEFIK_CONTAINER"
    
    # Aguardar container ficar saudável
    log_info "Aguardando Traefik inicializar..."
    sleep 10
    
    # Verificar se está rodando
    if docker ps | grep -q "$TRAEFIK_CONTAINER.*Up"; then
        log_success "Traefik reiniciado com sucesso"
    else
        log_error "Falha ao reiniciar Traefik"
        exit 1
    fi
}

# Função para aguardar certificados
wait_for_certificates() {
    log_step "Aguardando geração de certificados Let's Encrypt..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Tentativa $attempt/$max_attempts - Verificando certificados..."
        
        # Verificar se acme.json foi criado
        if docker exec "$TRAEFIK_CONTAINER" test -f /certs/acme.json 2>/dev/null; then
            # Verificar se contém certificados
            local cert_count=$(docker exec "$TRAEFIK_CONTAINER" cat /certs/acme.json 2>/dev/null | grep -c "\"certificate\":" || echo "0")
            if [[ $cert_count -gt 0 ]]; then
                log_success "Certificados gerados com sucesso!"
                return 0
            fi
        fi
        
        # Verificar logs para erros
        local error_logs=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | tail -20 | grep -i "error\|fail" || echo "")
        if [[ -n "$error_logs" ]]; then
            log_warn "Erros detectados nos logs:"
            echo "$error_logs" | tail -3
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "Timeout aguardando certificados - verifique logs do Traefik"
    return 1
}

# Função para testar SSL
test_ssl() {
    log_step "Testando certificados SSL..."
    
    # Testar conectividade HTTPS
    if curl -s --connect-timeout 10 "https://$DOMAIN" >/dev/null; then
        log_success "Conectividade HTTPS OK"
    else
        log_warn "Falha na conectividade HTTPS"
    fi
    
    # Verificar certificado
    local cert_info=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null || echo "")
    if [[ "$cert_info" == *"Let's Encrypt"* ]]; then
        log_success "Certificado Let's Encrypt válido encontrado"
    else
        log_warn "Certificado Let's Encrypt não encontrado"
        log_info "Certificado atual: $cert_info"
    fi
}

# Função para mostrar status final
show_final_status() {
    log_section "Status Final"
    
    echo -e "${CYAN}📊 RESUMO DA CORREÇÃO:${NC}"
    echo ""
    
    # Status do Traefik
    if docker ps | grep -q "$TRAEFIK_CONTAINER.*Up"; then
        echo -e "${GREEN}✅ Traefik: Rodando${NC}"
    else
        echo -e "${RED}❌ Traefik: Parado${NC}"
    fi
    
    # Status dos certificados
    if docker exec "$TRAEFIK_CONTAINER" test -f /certs/acme.json 2>/dev/null; then
        echo -e "${GREEN}✅ Certificados: Arquivo acme.json existe${NC}"
    else
        echo -e "${RED}❌ Certificados: Arquivo acme.json não encontrado${NC}"
    fi
    
    # Teste de conectividade
    if curl -s --connect-timeout 5 "https://$DOMAIN" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTPS: Funcionando${NC}"
    else
        echo -e "${RED}❌ HTTPS: Não funcionando${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔗 URLs para testar:${NC}"
    echo -e "   • https://$DOMAIN"
    echo -e "   • https://$WWW_DOMAIN"
    echo -e "   • http://localhost:8080 (Dashboard Traefik)"
    echo ""
    
    echo -e "${YELLOW}📝 Próximos passos:${NC}"
    echo -e "   1. Aguarde 2-5 minutos para propagação completa"
    echo -e "   2. Teste o site no navegador"
    echo -e "   3. Execute ./scripts/ssl-diagnostico.sh para verificação completa"
    echo -e "   4. Se ainda houver problemas, verifique DNS e firewall"
}

# Banner principal
log_header "CORREÇÃO AUTOMÁTICA SSL/TLS - CONEXÃO DE SORTE"

# Confirmar execução
confirm_action "Esta operação irá reiniciar o Traefik e regenerar certificados SSL."

# Executar correções
check_prerequisites
create_backup
clean_old_certificates
restart_traefik

# Aguardar e testar
if wait_for_certificates; then
    test_ssl
    show_final_status
    echo -e "\n${GREEN}🎉 Correção SSL concluída com sucesso!${NC}"
else
    echo -e "\n${RED}⚠️  Correção SSL concluída com avisos - verifique logs${NC}"
    echo -e "${BLUE}💡 Execute: docker logs $TRAEFIK_CONTAINER | grep -i acme${NC}"
fi

echo -e "${BLUE}📝 Para diagnóstico completo, execute: ./scripts/ssl-diagnostico.sh${NC}\n"
