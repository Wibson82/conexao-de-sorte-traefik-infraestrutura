#!/bin/bash
# =============================================================================
# SCRIPT DE CONFIGURAÇÃO DE AMBIENTE DE DESENVOLVIMENTO - CONEXÃO DE SORTE
# =============================================================================
# Este script configura o ambiente de desenvolvimento de forma segura,
# solicitando credenciais necessárias e configurando variáveis de ambiente
# sem armazenar credenciais em arquivos.
#
# IMPORTANTE: Este script NUNCA armazena credenciais em arquivos
# Todas as credenciais são mantidas apenas em variáveis de ambiente da sessão

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para solicitar input seguro
read_secret() {
    local prompt="$1"
    local var_name="$2"
    echo -n "$prompt: "
    read -s value
    echo
    export "$var_name"="$value"
}

# Função para solicitar input normal
read_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="${3:-}"
    
    if [ -n "$default_value" ]; then
        echo -n "$prompt [$default_value]: "
    else
        echo -n "$prompt: "
    fi
    
    read value
    if [ -z "$value" ] && [ -n "$default_value" ]; then
        value="$default_value"
    fi
    export "$var_name"="$value"
}

# Banner
echo "============================================================================="
echo "🚀 CONFIGURAÇÃO DE AMBIENTE DE DESENVOLVIMENTO - CONEXÃO DE SORTE"
echo "============================================================================="
echo
log_info "Este script configurará seu ambiente de desenvolvimento de forma segura."
log_warning "NUNCA compartilhe as credenciais que você inserir aqui!"
echo

# Verificar se Java 24 está instalado
log_info "Verificando Java 24..."
if ! java -version 2>&1 | grep -q "24"; then
    log_error "Java 24 não encontrado. Por favor, instale Java 24 antes de continuar."
    exit 1
fi
log_success "Java 24 encontrado."

# Verificar se Docker está rodando
log_info "Verificando Docker..."
if ! docker info >/dev/null 2>&1; then
    log_error "Docker não está rodando. Por favor, inicie o Docker antes de continuar."
    exit 1
fi
log_success "Docker está rodando."

# Configurações gerais
log_info "Configurando variáveis gerais..."
export ENVIRONMENT=development
export SPRING_PROFILES_ACTIVE=dev,macos
export SERVER_PORT=8080

# Configurações Azure Key Vault
echo
log_info "=== CONFIGURAÇÃO AZURE KEY VAULT ==="
read_input "Azure Key Vault Endpoint" "AZURE_KEYVAULT_ENDPOINT" "https://seu-keyvault-dev.vault.azure.net/"
read_secret "Azure Tenant ID" "AZURE_TENANT_ID"
read_secret "Azure Client ID" "AZURE_CLIENT_ID"
read_secret "Azure Client Secret" "AZURE_CLIENT_SECRET"
export AZURE_KEYVAULT_ENABLED=true
export AZURE_KEYVAULT_FALLBACK_ENABLED=true

# Configurações de banco de dados
echo
log_info "=== CONFIGURAÇÃO BANCO DE DADOS ==="
read_input "Database URL" "CONEXAO_DE_SORTE_DATABASE_URL" "jdbc:mysql://localhost:3306/conexao_de_sorte_dev?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo&characterEncoding=UTF-8"

# Configurações JWT
echo
log_info "=== CONFIGURAÇÃO JWT ==="
export JWT_ISSUER=https://dev.conexaodesorte.com.br
export JWT_AUDIENCE=conexao-de-sorte-frontend-app
export JWT_ALGORITHM=RS256

# Configurações de desenvolvimento
export LOGGING_LEVEL_ROOT=INFO
export LOGGING_LEVEL_BR_TEC_FACILITASERVICOS=DEBUG
export CORS_ALLOWED_ORIGINS="http://localhost:3000,http://localhost:3001,http://localhost:8080,http://localhost:8081,http://localhost:5173,http://127.0.0.1:3000"
export SEGURANCA_TAXA_ATIVADO=false
export SPRING_CACHE_TYPE=simple
export AUDITORIA_ENABLED=true
export GDPR_COMPLIANCE_ENABLED=true

# Configurações JVM
export JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError"

echo
log_success "Ambiente configurado com sucesso!"
echo
log_info "Para iniciar a aplicação, execute:"
echo "  mvn spring-boot:run"
echo
log_info "Para verificar se as variáveis estão configuradas:"
echo "  env | grep -E '(AZURE|CONEXAO|JWT)'"
echo
log_warning "IMPORTANTE: As variáveis de ambiente são válidas apenas para esta sessão do terminal."
log_warning "Se você fechar o terminal, precisará executar este script novamente."
echo
