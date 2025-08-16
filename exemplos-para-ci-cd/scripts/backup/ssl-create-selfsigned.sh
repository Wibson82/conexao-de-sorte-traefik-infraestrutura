#!/bin/bash

# 🔒 CRIAR CERTIFICADO AUTO-ASSINADO TEMPORÁRIO
# ⚠️  APENAS PARA EMERGÊNCIA - NÃO RECOMENDADO PARA PRODUÇÃO

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
CERT_DIR="/tmp/ssl-selfsigned"
VALIDITY_DAYS=30

log_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║              CERTIFICADO AUTO-ASSINADO TEMPORÁRIO                ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
}

log_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Função para confirmar ação
confirm_action() {
    echo -e "${RED}⚠️  AVISO: Certificado auto-assinado causará avisos de segurança nos navegadores!${NC}"
    echo -e "${YELLOW}Isso é apenas para emergência. Recomendamos aguardar Let's Encrypt.${NC}"
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Operação cancelada${NC}"
        exit 1
    fi
}

# Função para criar certificado auto-assinado
create_selfsigned_certificate() {
    log_step "Criando certificado auto-assinado..."
    
    # Criar diretório temporário
    mkdir -p "$CERT_DIR"
    
    # Criar arquivo de configuração OpenSSL
    cat > "$CERT_DIR/openssl.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = BR
ST = SP
L = Sao Paulo
O = Conexao de Sorte
OU = IT Department
CN = $DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = $WWW_DOMAIN
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF
    
    # Gerar chave privada
    log_info "Gerando chave privada..."
    openssl genrsa -out "$CERT_DIR/private.key" 2048
    
    # Gerar certificado auto-assinado
    log_info "Gerando certificado auto-assinado..."
    openssl req -new -x509 -key "$CERT_DIR/private.key" \
        -out "$CERT_DIR/certificate.crt" \
        -days $VALIDITY_DAYS \
        -config "$CERT_DIR/openssl.conf" \
        -extensions v3_req
    
    # Verificar certificado criado
    if [[ -f "$CERT_DIR/certificate.crt" && -f "$CERT_DIR/private.key" ]]; then
        log_success "Certificado auto-assinado criado com sucesso"
        
        # Mostrar informações do certificado
        log_info "Informações do certificado:"
        openssl x509 -in "$CERT_DIR/certificate.crt" -text -noout | grep -E "(Subject:|DNS:|Not After)"
    else
        log_error "Falha ao criar certificado"
        exit 1
    fi
}

# Função para instalar certificado no Traefik
install_certificate() {
    log_step "Instalando certificado no Traefik..."
    
    # Parar Traefik
    log_info "Parando Traefik..."
    docker stop $TRAEFIK_CONTAINER 2>/dev/null || true
    
    # Copiar certificados para container
    log_info "Copiando certificados..."
    docker cp "$CERT_DIR/certificate.crt" $TRAEFIK_CONTAINER:/tmp/selfsigned.crt
    docker cp "$CERT_DIR/private.key" $TRAEFIK_CONTAINER:/tmp/selfsigned.key
    
    # Criar configuração dinâmica do Traefik
    cat > "$CERT_DIR/traefik-selfsigned.yml" << EOF
tls:
  certificates:
    - certFile: /tmp/selfsigned.crt
      keyFile: /tmp/selfsigned.key
      stores:
        - default
  stores:
    default:
      defaultCertificate:
        certFile: /tmp/selfsigned.crt
        keyFile: /tmp/selfsigned.key
EOF
    
    # Copiar configuração para Traefik
    docker cp "$CERT_DIR/traefik-selfsigned.yml" $TRAEFIK_CONTAINER:/tmp/traefik-selfsigned.yml
    
    # Reiniciar Traefik
    log_info "Reiniciando Traefik..."
    docker start $TRAEFIK_CONTAINER
    
    # Aguardar Traefik inicializar
    sleep 15
    
    log_success "Certificado instalado no Traefik"
}

# Função para habilitar HTTPS
enable_https() {
    log_step "Habilitando roteamento HTTPS..."
    
    # Recriar containers com HTTPS habilitado
    log_info "Atualizando configuração dos containers..."
    
    cd ~/conexao-deploy 2>/dev/null || cd ~/
    
    # Parar containers
    docker stop conexao-frontend conexao-backend-green 2>/dev/null || true
    docker rm conexao-frontend conexao-backend-green 2>/dev/null || true
    
    # Recriar com HTTPS
    docker-compose -f docker-compose.prod.yml up -d frontend backend-green
    
    log_success "HTTPS habilitado"
}

# Função para testar certificado
test_certificate() {
    log_step "Testando certificado auto-assinado..."
    
    # Aguardar containers inicializarem
    sleep 20
    
    # Testar HTTPS (ignorando certificado auto-assinado)
    log_info "Testando HTTPS..."
    if curl -k -s "https://$DOMAIN" >/dev/null 2>&1; then
        log_success "HTTPS funcionando (certificado auto-assinado)"
    else
        log_warn "HTTPS pode não estar funcionando"
    fi
    
    # Testar backend HTTPS
    log_info "Testando backend HTTPS..."
    if curl -k -s "https://$DOMAIN/rest/actuator/health" >/dev/null 2>&1; then
        log_success "Backend HTTPS funcionando"
    else
        log_warn "Backend HTTPS pode não estar funcionando"
    fi
    
    # Mostrar informações do certificado via HTTPS
    log_info "Verificando certificado via HTTPS..."
    echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | \
        openssl x509 -noout -subject -dates 2>/dev/null || echo "Não foi possível verificar"
}

# Função para mostrar instruções
show_instructions() {
    log_step "Instruções importantes"
    
    echo -e "${YELLOW}⚠️  CERTIFICADO AUTO-ASSINADO INSTALADO${NC}"
    echo ""
    echo -e "${RED}AVISOS IMPORTANTES:${NC}"
    echo -e "• Navegadores mostrarão aviso de segurança"
    echo -e "• Usuários precisarão aceitar o certificado manualmente"
    echo -e "• NÃO é adequado para produção real"
    echo -e "• Use apenas em emergência"
    echo ""
    echo -e "${BLUE}COMO ACESSAR:${NC}"
    echo -e "• Frontend: ${CYAN}https://$DOMAIN${NC} (aceitar aviso)"
    echo -e "• Backend: ${CYAN}https://$DOMAIN/rest/actuator/health${NC} (aceitar aviso)"
    echo ""
    echo -e "${GREEN}PARA RESTAURAR LET'S ENCRYPT:${NC}"
    echo -e "• Aguarde até 21:19 UTC hoje"
    echo -e "• Execute: ./scripts/ssl-fix.sh"
    echo -e "• Certificados válidos serão gerados automaticamente"
    echo ""
    echo -e "${YELLOW}VALIDADE DO CERTIFICADO:${NC}"
    echo -e "• Válido por: $VALIDITY_DAYS dias"
    echo -e "• Criado em: $(date)"
    echo -e "• Expira em: $(date -d "+$VALIDITY_DAYS days")"
}

# Função para limpeza
cleanup() {
    log_info "Limpando arquivos temporários..."
    rm -rf "$CERT_DIR" 2>/dev/null || true
}

# Função principal
main() {
    log_header
    
    # Verificar se Traefik está rodando
    if ! docker ps | grep -q $TRAEFIK_CONTAINER; then
        log_error "Traefik não está rodando"
        exit 1
    fi
    
    # Confirmar ação
    confirm_action
    
    # Executar criação e instalação
    create_selfsigned_certificate
    install_certificate
    enable_https
    test_certificate
    show_instructions
    cleanup
    
    echo -e "\n${GREEN}🎯 Certificado auto-assinado instalado!${NC}"
    echo -e "${YELLOW}⚠️  Lembre-se: Isso é temporário para emergência${NC}"
}

# Executar função principal
main "$@"
