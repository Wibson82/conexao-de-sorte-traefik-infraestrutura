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
# Configuração Segura - Conexão de Sorte
# Não commitar este arquivo!

# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=conexao_sorte

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DATABASE=0

# JWT
JWT_ISSUER=conexao-de-sorte

# SSL
SSL_ENABLED=true

# CORS
CORS_ALLOWED_ORIGINS=https://conexao-de-sorte.com
CORS_ALLOW_CREDENTIALS=true
EOF
        echo "✅ Arquivo .env criado"
    fi

    # Adicionar .env ao .gitignore se não estiver
    if [[ -f .gitignore ]] && ! grep -q ".env" .gitignore; then
        echo ".env" >> .gitignore
        echo "✅ .env adicionado ao .gitignore"
    fi
}

# Função para configurar sudo sem senha (desenvolvimento)
setup_sudo_nopasswd() {
    echo "🔐 Configurando sudo sem senha para desenvolvimento..."

    local user=$(whoami)
    local sudoers_file="/etc/sudoers.d/conexao-de-sorte-dev"

    if [[ ! -f "$sudoers_file" ]]; then
        echo "$user ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/local/bin/docker-compose" | sudo tee "$sudoers_file" > /dev/null
        sudo chmod 440 "$sudoers_file"
        echo "✅ Configuração sudo criada em $sudoers_file"
    else
        echo "ℹ️  Configuração sudo já existe"
    fi
}

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

    # Apenas em ambiente de desenvolvimento
    if [[ "${ENVIRONMENT:-dev}" == "dev" ]]; then
        setup_sudo_nopasswd
    fi

    validate_setup

    echo "✅ Configuração segura concluída!"
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Configure as variáveis AZURE_* no seu ambiente"
    echo "2. Execute 'source .env' para carregar as variáveis"
    echo "3. Teste a conexão com o Azure Key Vault"
    echo "4. Execute os testes de integração"
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi