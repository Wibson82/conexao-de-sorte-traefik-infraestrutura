#!/bin/bash

# Script de Teste de Conectividade SSH
# Valida conectividade com o servidor antes do deploy

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log com cores
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

# Função principal de teste
test_ssh_connectivity() {
    local host="$1"
    local user="$2"
    local timeout="${3:-10}"
    
    if [ -z "$host" ] || [ -z "$user" ]; then
        log_error "Uso: test_ssh_connectivity <host> <user> [timeout]"
        return 1
    fi
    
    log_info "Iniciando testes de conectividade SSH para ${user}@${host}"
    echo ""
    
    # 1. Teste de resolução DNS
    log_info "1. Testando resolução DNS..."
    if nslookup "$host" > /dev/null 2>&1; then
        log_success "DNS resolve corretamente"
        # Mostrar informações do DNS
        local dns_info=$(nslookup "$host" 2>/dev/null | grep -E "name =|Address:" | head -2)
        if [ -n "$dns_info" ]; then
            echo "   $dns_info"
        fi
    else
        log_error "Não foi possível resolver o hostname $host"
        log_error "Verifique se o hostname está correto"
        return 1
    fi
    echo ""
    
    # 2. Teste de conectividade de rede
    log_info "2. Testando conectividade de rede..."
    if ping -c 3 -W 5 "$host" > /dev/null 2>&1; then
        log_success "Host responde ao ping"
        # Mostrar estatísticas do ping
        local ping_stats=$(ping -c 3 "$host" 2>/dev/null | tail -1)
        echo "   $ping_stats"
    else
        log_warning "Host não responde ao ping, mas pode estar bloqueando ICMP"
        log_info "Continuando com os testes..."
    fi
    echo ""
    
    # 3. Teste de porta SSH
    log_info "3. Testando porta SSH (22)..."
    if ssh-keyscan -T "$timeout" -H "$host" > /dev/null 2>&1; then
        log_success "Porta SSH está acessível"
        # Mostrar informações do servidor SSH
        local ssh_info=$(ssh-keyscan -T "$timeout" "$host" 2>/dev/null | head -1 | grep -o 'SSH-[^[:space:]]*')
        if [ -n "$ssh_info" ]; then
            echo "   Servidor SSH: $ssh_info"
        fi
    else
        log_error "Não foi possível conectar ao servidor SSH na porta 22"
        log_error "Verifique se o servidor SSH está rodando e acessível"
        return 1
    fi
    echo ""
    
    # 4. Teste de chaves SSH (se disponível)
    log_info "4. Obtendo chaves SSH do servidor..."
    local ssh_keys=$(ssh-keyscan -T "$timeout" "$host" 2>/dev/null)
    if [ -n "$ssh_keys" ]; then
        log_success "Chaves SSH obtidas com sucesso"
        echo "$ssh_keys" | while read -r line; do
            if [[ $line == *"ssh-rsa"* ]]; then
                echo "   🔑 RSA key disponível"
            elif [[ $line == *"ecdsa"* ]]; then
                echo "   🔑 ECDSA key disponível"
            elif [[ $line == *"ssh-ed25519"* ]]; then
                echo "   🔑 ED25519 key disponível"
            fi
        done
    else
        log_warning "Não foi possível obter chaves SSH"
    fi
    echo ""
    
    # 5. Teste de conectividade SSH (se chave privada estiver disponível)
    if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ] || [ -f ~/.ssh/id_ecdsa ]; then
        log_info "5. Testando autenticação SSH..."
        if ssh -o ConnectTimeout="$timeout" -o StrictHostKeyChecking=no -o BatchMode=yes "${user}@${host}" 'echo "Conexão SSH funcionando!"' > /dev/null 2>&1; then
            log_success "Autenticação SSH funcionando!"
        else
            log_warning "Autenticação SSH falhou (chave privada pode não estar configurada)"
            log_info "Isso é normal se a chave privada não estiver no ambiente de teste"
        fi
    else
        log_info "5. Pulando teste de autenticação (chave privada não encontrada)"
    fi
    echo ""
    
    log_success "Testes de conectividade concluídos com sucesso!"
    log_info "O host $host está pronto para receber conexões SSH"
    
    return 0
}

# Função para uso no GitHub Actions
test_for_github_actions() {
    local host="$1"
    local user="$2"
    
    echo "::group::🔍 Teste de Conectividade SSH"
    
    if test_ssh_connectivity "$host" "$user" 10; then
        echo "::notice::Conectividade SSH validada com sucesso para ${user}@${host}"
        echo "::endgroup::"
        return 0
    else
        echo "::error::Falha na validação de conectividade SSH para ${user}@${host}"
        echo "::endgroup::"
        return 1
    fi
}

# Execução principal
if [ "$#" -eq 0 ]; then
    echo "Uso: $0 <host> <user> [timeout]"
    echo "Exemplo: $0 145.223.31.87 root 10"
    echo ""
    echo "Para uso no GitHub Actions:"
    echo "  GITHUB_ACTIONS=true $0 <host> <user>"
    exit 1
fi

# Verificar se está rodando no GitHub Actions
if [ "$GITHUB_ACTIONS" = "true" ]; then
    test_for_github_actions "$1" "$2"
else
    test_ssh_connectivity "$1" "$2" "$3"
fi