#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🔐 SCRIPT DE CRIAÇÃO DE DOCKER SECRETS - TRAEFIK INFRASTRUCTURE
# =============================================================================
# Cria todos os secrets Docker obrigatórios para o Traefik funcionar
# Usado quando o servidor é limpo e precisa recriar os secrets
# =============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    local level=$1
    shift
    case $level in
        "INFO")  echo -e "${BLUE}ℹ️  $*${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $*${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $*${NC}" ;;
        "ERROR") echo -e "${RED}❌ $*${NC}" ;;
    esac
}

# Função para criar um secret se não existir
create_secret_if_not_exists() {
    local secret_name="$1"
    local secret_value="$2"
    local description="$3"
    
    if docker secret inspect "$secret_name" >/dev/null 2>&1; then
        log "WARNING" "$secret_name: Já existe, pulando criação"
    else
        log "INFO" "Criando secret: $secret_name ($description)"
        if echo "$secret_value" | docker secret create "$secret_name" -; then
            log "SUCCESS" "$secret_name: Criado com sucesso"
        else
            log "ERROR" "$secret_name: Falha na criação"
            return 1
        fi
    fi
}

# Função principal para criar todos os secrets
create_traefik_secrets() {
    log "INFO" "🔐 Criando Docker Secrets obrigatórios para Traefik..."
    echo ""
    
    # Verificar se Docker Swarm está ativo
    if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        log "ERROR" "Docker Swarm não está ativo. Secrets requerem Swarm mode."
        log "INFO" "Execute: docker swarm init"
        return 1
    fi
    
    log "SUCCESS" "Docker Swarm ativo, prosseguindo com criação de secrets..."
    echo ""
    
    # Secrets críticos para Traefik
    log "INFO" "Criando secrets CRÍTICOS:"
    
    # CORS_ALLOWED_ORIGINS - Domínios permitidos para CORS
    create_secret_if_not_exists \
        "CORS_ALLOWED_ORIGINS" \
        "https://conexaodesorte.com.br,https://www.conexaodesorte.com.br,https://api.conexaodesorte.com.br" \
        "Domínios permitidos para CORS"
    
    # SSL_ENABLED - Habilitar SSL/TLS
    create_secret_if_not_exists \
        "SSL_ENABLED" \
        "true" \
        "Habilitar SSL/TLS"
    
    # SSL_KEYSTORE_PASSWORD - Senha do keystore SSL
    create_secret_if_not_exists \
        "SSL_KEYSTORE_PASSWORD" \
        "$(openssl rand -base64 32)" \
        "Senha do keystore SSL (gerada automaticamente)"
    
    # JWT_VERIFICATION_KEY - Chave para verificação JWT
    create_secret_if_not_exists \
        "JWT_VERIFICATION_KEY" \
        "$(openssl rand -base64 64)" \
        "Chave para verificação JWT (gerada automaticamente)"
    
    echo ""
    log "INFO" "Criando secrets OPCIONAIS:"
    
    # CORS_ALLOW_CREDENTIALS - Permitir credenciais em CORS
    create_secret_if_not_exists \
        "CORS_ALLOW_CREDENTIALS" \
        "true" \
        "Permitir credenciais em CORS"
    
    # SSL_KEYSTORE_PATH - Caminho do keystore SSL
    create_secret_if_not_exists \
        "SSL_KEYSTORE_PATH" \
        "/etc/ssl/certs/keystore.p12" \
        "Caminho do keystore SSL"
    
    # JWT_SIGNING_KEY - Chave para assinatura JWT
    create_secret_if_not_exists \
        "JWT_SIGNING_KEY" \
        "$(openssl rand -base64 64)" \
        "Chave para assinatura JWT (gerada automaticamente)"
    
    echo ""
    log "INFO" "📋 Listando todos os secrets criados:"
    docker secret ls --format "table {{.Name}}\t{{.CreatedAt}}\t{{.UpdatedAt}}"
    
    echo ""
    log "SUCCESS" "🎉 Todos os secrets Docker foram criados com sucesso!"
    log "INFO" "✅ Traefik agora pode ser deployado sem erros de secrets"
}

# Função para remover todos os secrets (usar com cuidado)
remove_all_secrets() {
    log "WARNING" "🗑️  REMOVENDO TODOS OS SECRETS (USE COM CUIDADO)..."
    
    local secrets=(
        "CORS_ALLOWED_ORIGINS"
        "SSL_ENABLED"
        "SSL_KEYSTORE_PASSWORD"
        "JWT_VERIFICATION_KEY"
        "CORS_ALLOW_CREDENTIALS"
        "SSL_KEYSTORE_PATH"
        "JWT_SIGNING_KEY"
    )
    
    for secret in "${secrets[@]}"; do
        if docker secret inspect "$secret" >/dev/null 2>&1; then
            log "INFO" "Removendo secret: $secret"
            docker secret rm "$secret" || log "WARNING" "Falha ao remover $secret"
        else
            log "INFO" "$secret: Não existe, pulando remoção"
        fi
    done
    
    log "SUCCESS" "Remoção de secrets concluída"
}

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  create    Criar todos os secrets Docker obrigatórios (padrão)"
    echo "  remove    Remover todos os secrets Docker (USE COM CUIDADO)"
    echo "  help      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                # Criar secrets"
    echo "  $0 create         # Criar secrets"
    echo "  $0 remove         # Remover secrets"
}

# Função principal
main() {
    local action="${1:-create}"
    
    case "$action" in
        "create")
            create_traefik_secrets
            ;;
        "remove")
            remove_all_secrets
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log "ERROR" "Ação inválida: $action"
            show_help
            exit 1
            ;;
    esac
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi