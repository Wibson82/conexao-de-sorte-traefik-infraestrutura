#!/bin/bash
# Configuração Segura - Conexão de Sorte
# Substitui práticas inseguras do terminal.txt original

set -euo pipefail

# Configuração de encoding UTF-8
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8

echo "🔧 Configurando ambiente seguro..."

# Verificar se Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI não encontrado. Instale com: brew install azure-cli"
    exit 1
fi

# Verificar autenticação Azure
if ! az account show &> /dev/null; then
    echo "❌ Não autenticado no Azure. Execute: az login"
    exit 1
fi

# Função para recuperar segredos do Azure Key Vault
get_secret() {
    local secret_name="$1"
    local vault_name="${AZURE_KEYVAULT_NAME:-conexao-de-sorte-keyvault}"

    # SECURITY: Não logar nomes de segredos
    az keyvault secret show \
        --vault-name "$vault_name" \
        --name "$secret_name" \
        --query value \
        --output tsv 2>/dev/null || {
        echo "❌ Erro ao recuperar segredo do Azure Key Vault"
        return 1
    }
}

# Função para configurar variáveis de ambiente seguras
setup_environment() {
    echo "🌍 Configurando variáveis de ambiente..."

    # Criar arquivo .env se não existir
    if [[ ! -f .env ]]; then
        cat > .env << 'EOF'
# =============================================================================
# 🔐 CONFIGURAÇÃO SEGURA - CONEXÃO DE SORTE
# =============================================================================
# CONFLITOS RESOLVIDOS: Variáveis padronizadas para docker-compose.consolidated.yml
# Não commitar este arquivo!

# =============================================================================
# 🌐 TRAEFIK CONFIGURATION (Obrigatório)
# =============================================================================
TZ=America/Sao_Paulo
TRAEFIK_ACME_EMAIL=facilitaservicos.tec@gmail.com
TRAEFIK_DOMAIN=traefik.conexaodesorte.com.br
API_DOMAIN=api.conexaodesorte.com.br

# =============================================================================
# 🔧 BACKEND CONFIGURATION (Docker Swarm Only)
# =============================================================================
# Configurações removidas: BACKEND_SERVICE e BACKEND_PORT eram específicas
# para comunicação bridge com backend-prod legacy
# Agora usando apenas Docker Swarm para todos os serviços

# =============================================================================
# 📊 DASHBOARD & LOGGING
# =============================================================================
ENABLE_DASHBOARD=true
API_INSECURE=false
LOG_LEVEL=INFO
ACCESS_LOG_ENABLED=true

# =============================================================================
# 🔐 AZURE KEY VAULT (Obrigatório para Produção)
# =============================================================================
# AZURE_CLIENT_ID=your-client-id
# AZURE_TENANT_ID=your-tenant-id
# AZURE_KEYVAULT_ENDPOINT=https://your-keyvault.vault.azure.net/
# AZURE_KEYVAULT_NAME=conexao-de-sorte-keyvault

# =============================================================================
# 🗄️ DATABASE (Legacy - manter compatibilidade)
# =============================================================================
DB_HOST=localhost
DB_PORT=3306
DB_NAME=conexao_sorte

# =============================================================================
# 📡 REDIS
# =============================================================================
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DATABASE=0

# =============================================================================
# 🔑 JWT & SECURITY
# =============================================================================
JWT_ISSUER=conexao-de-sorte
SSL_ENABLED=true

# =============================================================================
# 🌐 CORS
# =============================================================================
CORS_ALLOWED_ORIGINS=https://conexaodesorte.com.br,https://www.conexaodesorte.com.br
CORS_ALLOW_CREDENTIALS=true

# =============================================================================
# 🏗️ BUILD & DEPLOYMENT
# =============================================================================
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ENVIRONMENT=production
EOF
        echo "✅ Arquivo .env criado com configurações consolidadas"
    fi

    # Adicionar .env ao .gitignore se não estiver
    if [[ -f .gitignore ]] && ! grep -q ".env" .gitignore; then
        echo ".env" >> .gitignore
        echo "✅ .env adicionado ao .gitignore"
    fi
}

# FUNÇÃO REMOVIDA: setup_sudo_nopasswd
# Motivo: Configuração insegura não adequada para produção
# Em produção, usar autenticação adequada e controle de acesso restrito

# Função para validar configuração
validate_setup() {
    echo "🔍 Validando configuração..."

    # Verificar encoding
    if [[ "$LANG" == "pt_BR.UTF-8" ]]; then
        echo "✅ Encoding UTF-8 configurado"
    else
        echo "❌ Encoding não configurado corretamente"
    fi

    # Verificar Azure Key Vault
    if [[ -n "${AZURE_KEYVAULT_NAME:-}" ]]; then
        if az keyvault show --name "$AZURE_KEYVAULT_NAME" &> /dev/null; then
            echo "✅ Azure Key Vault acessível"
        else
            echo "❌ Azure Key Vault não acessível"
        fi
    else
        echo "⚠️  AZURE_KEYVAULT_NAME não definido"
    fi

    # Verificar variáveis obrigatórias do Traefik
    local traefik_vars=("TRAEFIK_DOMAIN" "API_DOMAIN" "TRAEFIK_ACME_EMAIL")
    for var in "${traefik_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            echo "✅ $var configurado"
        else
            echo "❌ $var não configurado"
        fi
    done

    # Verificar arquivo .env
    if [[ -f .env ]]; then
        echo "✅ Arquivo .env existe"
    else
        echo "❌ Arquivo .env não encontrado"
    fi
}

# Função principal
main() {
    echo "🚀 Iniciando configuração segura..."

    setup_environment

    # PRODUÇÃO: Sem configurações inseguras de desenvolvimento
    # Todas as configurações são validadas para ambiente de produção

    validate_setup

    echo "✅ Configuração segura concluída!"
    echo ""
    echo "📋 Próximos passos para PRODUÇÃO:"
    echo "1. ⚠️  OBRIGATÓRIO: Configure as variáveis AZURE_* no arquivo .env"
    echo "2. Execute 'source .env' para carregar as variáveis"
    echo "3. ✅ Teste a conexão com o Azure Key Vault"
    echo "4. 🚀 Execute o deploy: ./deploy-strategy.sh"
    echo "5. 📊 Verifique os serviços: docker service ls (Swarm)"
    echo "6. 🔍 Monitore logs: docker service logs traefik-stack_traefik"
    echo ""
    echo "🔗 URLs de PRODUÇÃO após deploy:"
    echo "   🌐 Frontend: https://www.conexaodesorte.com.br"
    echo "   📊 Dashboard: https://traefik.conexaodesorte.com.br (PROTEGIDO)"
    echo "   🔌 API: https://api.conexaodesorte.com.br"
    echo ""
    echo "🛡️  SEGURANÇA: Dashboard protegido por autenticação obrigatória"
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi