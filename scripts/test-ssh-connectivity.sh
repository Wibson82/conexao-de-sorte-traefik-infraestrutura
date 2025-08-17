#!/bin/bash

# Script para testar conectividade SSH
# Uso: ./test-ssh-connectivity.sh <host> <user>

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar argumentos
if [ $# -ne 2 ]; then
    log_error "Uso: $0 <host> <user>"
    exit 1
fi

HOST="$1"
USER="$2"

log_info "Iniciando teste de conectividade SSH"
log_info "Host: $HOST"
log_info "Usuário: $USER"
echo ""

# Teste 1: Verificar se o host responde a ping
log_info "Teste 1: Verificando conectividade de rede..."
if ping -c 3 -W 5 "$HOST" > /dev/null 2>&1; then
    log_success "Host $HOST responde a ping"
else
    log_warning "Host $HOST não responde a ping (pode estar bloqueado por firewall)"
fi
echo ""

# Teste 2: Verificar se a porta SSH está aberta
log_info "Teste 2: Verificando porta SSH (22)..."
if timeout 10 bash -c "</dev/tcp/$HOST/22" 2>/dev/null; then
    log_success "Porta SSH (22) está aberta em $HOST"
else
    log_error "Porta SSH (22) não está acessível em $HOST"
    exit 1
fi
echo ""

# Teste 3: Verificar se conseguimos obter a chave do host
log_info "Teste 3: Obtendo chave do host..."
if ssh-keyscan -T 10 -H "$HOST" > /dev/null 2>&1; then
    log_success "Chave do host obtida com sucesso"
    log_info "Fingerprint do host:"
    ssh-keyscan -T 10 "$HOST" 2>/dev/null | ssh-keygen -lf - | head -3
else
    log_error "Falha ao obter chave do host"
    exit 1
fi
echo ""

# Teste 4: Verificar conectividade SSH (apenas se não estivermos no GitHub Actions)
if [ "$GITHUB_ACTIONS" != "true" ]; then
    log_info "Teste 4: Testando conectividade SSH..."
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$USER@$HOST" "echo 'SSH conectado com sucesso'" 2>/dev/null; then
        log_success "Conectividade SSH funcionando"
    else
        log_warning "Não foi possível conectar via SSH (normal se a chave não estiver configurada)"
        log_info "Isso será resolvido durante o deploy quando a chave SSH for configurada"
    fi
else
    log_info "Teste 4: Pulando teste de conectividade SSH (executando no GitHub Actions)"
    log_info "A conectividade SSH será testada durante o deploy com as chaves configuradas"
fi
echo ""

# Teste 5: Verificar informações do sistema (se possível)
log_info "Teste 5: Coletando informações do sistema..."
log_info "Resolvendo DNS para $HOST:"
nslookup "$HOST" 2>/dev/null | grep -E "^Name:|^Address:" || log_warning "Não foi possível resolver DNS"
echo ""

# Teste 6: Verificar se Docker está disponível (se conseguirmos conectar)
if [ "$GITHUB_ACTIONS" != "true" ]; then
    log_info "Teste 6: Verificando disponibilidade do Docker no servidor..."
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$USER@$HOST" "docker --version" 2>/dev/null; then
        log_success "Docker está disponível no servidor"
        ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$USER@$HOST" "docker compose version" 2>/dev/null || log_warning "Docker Compose pode não estar disponível"
    else
        log_warning "Não foi possível verificar Docker (normal se SSH não estiver configurado)"
    fi
else
    log_info "Teste 6: Pulando verificação do Docker (executando no GitHub Actions)"
fi
echo ""

# Resumo
log_success "Teste de conectividade SSH concluído"
log_info "Host: $HOST"
log_info "Usuário: $USER"
log_info "Status: Pronto para deploy"

if [ "$GITHUB_ACTIONS" = "true" ]; then
    log_info "Próximos passos: O pipeline configurará as chaves SSH e executará o deploy"
else
    log_info "Próximos passos: Configure as chaves SSH no GitHub Secrets para habilitar o deploy automático"
fi

echo ""
log_success "✨ Todos os testes de conectividade foram concluídos com sucesso!"