#!/usr/bin/env bash
# Script de validação de configuração para Traefik Infrastructure
# Uso: ./validate-config.sh

set -Eeuo pipefail
IFS=$'\n\t'

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se estamos no diretório correto
if [[ ! -f "docker-compose.yml" ]]; then
    log_error "docker-compose.yml não encontrado. Execute este script no diretório raiz do projeto."
    exit 1
fi

echo "🔍 Validando configuração do Traefik Infrastructure..."
echo

# 1. Verificar GitHub Variables
echo "📋 Verificando GitHub Variables..."
required_vars=(
    "AZURE_CLIENT_ID"
    "AZURE_TENANT_ID"
    "AZURE_SUBSCRIPTION_ID"
    "AZURE_KEYVAULT_NAME"
)

vars_ok=true
for var in "${required_vars[@]}"; do
    # Simular verificação (em CI/CD isso seria feito automaticamente)
    if [[ -n "${!var:-}" ]]; then
        log_info "✅ $var está configurado"
    else
        log_error "❌ $var não está configurado"
        vars_ok=false
    fi
done

if [[ "$vars_ok" == true ]]; then
    log_info "✅ Todas as GitHub Variables obrigatórias estão configuradas"
else
    log_warn "⚠️  Algumas GitHub Variables estão faltando. Configure-as em Settings > Secrets and variables > Actions > Variables"
fi

echo

# 2. Verificar Azure CLI e Key Vault
echo "🔐 Verificando Azure Key Vault..."
if command -v az &> /dev/null; then
    if [[ -n "${AZURE_KEYVAULT_NAME:-}" ]]; then
        # Tentar listar segredos do Key Vault
        if az keyvault secret list --vault-name "$AZURE_KEYVAULT_NAME" --query "[].name" -o tsv &>/dev/null; then
            log_info "✅ Azure Key Vault está acessível"
            
            # Verificar segredos essenciais
            essential_secrets=(
                "conexao-de-sorte-letsencrypt-email"
                "conexao-de-sorte-traefik-dashboard-password"
            )
            
            secrets_ok=true
            for secret in "${essential_secrets[@]}"; do
                if az keyvault secret show --vault-name "$AZURE_KEYVAULT_NAME" --name "$secret" --query value -o tsv &>/dev/null; then
                    log_info "✅ $secret está presente no Key Vault"
                else
                    log_error "❌ $secret não encontrado no Key Vault"
                    secrets_ok=false
                fi
            done
            
            if [[ "$secrets_ok" == true ]]; then
                log_info "✅ Todos os segredos essenciais estão presentes no Key Vault"
            else
                log_warn "⚠️  Alguns segredos essenciais estão faltando no Key Vault"
            fi
        else
            log_error "❌ Não foi possível acessar o Azure Key Vault. Verifique suas credenciais e permissões."
        fi
    else
        log_warn "⚠️  AZURE_KEYVAULT_NAME não está configurado. Não é possível verificar o Key Vault."
    fi
else
    log_warn "⚠️  Azure CLI não está instalada. Não é possível verificar o Key Vault localmente."
fi

echo

# 3. Validar Docker Compose
echo "🐳 Validando Docker Compose..."
if docker compose -f docker-compose.yml config -q &>/dev/null; then
    log_info "✅ Docker Compose está válido"
else
    log_error "❌ Docker Compose contém erros de sintaxe"
    docker compose -f docker-compose.yml config
fi

echo

# 4. Verificar arquivos de configuração
echo "📁 Verificando arquivos de configuração..."
config_files=(
    "traefik/traefik.yml"
    "traefik/dynamic/middlewares.yml"
    "traefik/dynamic/security-headers.yml"
    "traefik/dynamic/tls.yml"
)

for file in "${config_files[@]}"; do
    if [[ -f "$file" ]]; then
        log_info "✅ $file existe"
    else
        log_warn "⚠️  $file não encontrado"
    fi
done

echo

# 5. Verificar hardcoded passwords
echo "🔒 Verificando hardcoded passwords..."
if grep -r "password.*:" docker-compose.yml | grep -v "\${" | grep -v "#" | grep -v "external:"; then
    log_error "❌ Possíveis passwords hardcoded encontrados no docker-compose.yml"
else
    log_info "✅ Nenhum password hardcoded detectado"
fi

echo

# Resumo final
echo "📊 Resumo da Validação:"
echo "====================="

# Inicializar variáveis de controle
vars_ok="${vars_ok:-false}"
secrets_ok="${secrets_ok:-false}"

if [[ "$vars_ok" == true ]] && [[ "$secrets_ok" == true ]]; then
    log_info "✅ Configuração está pronta para deploy!"
    echo
    echo "Próximos passos:"
    echo "1. Faça commit das suas alterações"
    echo "2. Push para a branch main"
    echo "3. Monitore o pipeline em Actions > CI/CD Pipeline"
else
    log_warn "⚠️  Configuração incompleta. Por favor, corrija os problemas acima antes de prosseguir."
    echo
    echo "Ações necessárias:"
    [[ "$vars_ok" != true ]] && echo "- Configure as GitHub Variables faltantes"
    [[ "$secrets_ok" != true ]] && echo "- Adicione os segredos essenciais ao Azure Key Vault"
fi

echo
echo "📚 Documentação:"
echo "- GitHub Variables: .github/VARIABLES-EXAMPLE.md"
echo "- Guia de troubleshooting: ci-cd-exemplo.txt"
echo "- Pipeline atual: .github/workflows/ci-cd.yml"