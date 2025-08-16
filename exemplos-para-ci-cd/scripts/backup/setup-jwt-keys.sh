#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO DE CHAVES JWT - CONEXÃO DE SORTE
# =============================================================================
# Este script configura as chaves RSA para JWT no Azure Key Vault
# e também cria chaves locais como fallback

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
KEY_VAULT_NAME="conexao-de-sorte-kv"
KEY_SIZE=2048
PRIVATE_KEY_FILE="jwt-private-key.pem"
PUBLIC_KEY_FILE="jwt-public-key.pem"

# Funções auxiliares
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

# Verificar dependências
check_dependencies() {
    log_info "Verificando dependências..."
    
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL não está instalado. Por favor, instale-o."
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI não está instalado. Por favor, instale-o."
        exit 1
    fi
    
    log_success "Dependências verificadas"
}

# Gerar chaves RSA
generate_keys() {
    log_info "Gerando par de chaves RSA de ${KEY_SIZE} bits..."
    
    # Gerar chave privada
    openssl genrsa -out ${PRIVATE_KEY_FILE} ${KEY_SIZE}
    
    # Extrair chave pública
    openssl rsa -in ${PRIVATE_KEY_FILE} -pubout -out ${PUBLIC_KEY_FILE}
    
    log_success "Chaves geradas com sucesso"
}

# Configurar no Azure Key Vault
setup_azure_keyvault() {
    log_info "Configurando Azure Key Vault..."
    
    # Verificar login no Azure
    if ! az account show &> /dev/null; then
        log_error "Não está logado no Azure. Execute: az login"
        exit 1
    fi
    
    # Ler chaves
    PRIVATE_KEY=$(cat ${PRIVATE_KEY_FILE})
    PUBLIC_KEY=$(cat ${PUBLIC_KEY_FILE})
    
    # Configurar no Key Vault
    log_info "Configurando chave privada no Azure Key Vault..."
    az keyvault secret set \
        --vault-name ${KEY_VAULT_NAME} \
        --name "jwt-private-key" \
        --value "${PRIVATE_KEY}" \
        --description "Chave privada RSA para JWT - Conexão de Sorte"
    
    log_info "Configurando chave pública no Azure Key Vault..."
    az keyvault secret set \
        --vault-name ${KEY_VAULT_NAME} \
        --name "jwt-public-key" \
        --value "${PUBLIC_KEY}" \
        --description "Chave pública RSA para JWT - Conexão de Sorte"
    
    log_success "Chaves configuradas no Azure Key Vault"
}

# Criar configuração local de fallback
create_fallback_config() {
    log_info "Criando configuração de fallback local..."
    
    cat > .env.test << EOF
# =============================================================================
# CONFIGURAÇÃO DE TESTE - FALLBACK LOCAL
# =============================================================================

# JWT - Chaves para teste (use apenas em ambiente de teste/dev)
JWT_PRIVATE_KEY="$(cat ${PRIVATE_KEY_FILE})"
JWT_PUBLIC_KEY="$(cat ${PUBLIC_KEY_FILE})"
JWT_SECRET=chave-secreta-para-teste-256-bits

# Azure Key Vault (desabilitado para teste)
AZURE_KEYVAULT_ENABLED=false
AZURE_KEYVAULT_FALLBACK_ENABLED=true

# Database (configurações para teste)
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/conexao_de_sorte_test?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=password

# Logging
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_BR_TEC_FACILITASERVICOS=DEBUG
EOF

    log_success "Configuração de fallback criada"
}

# Verificar configuração
check_configuration() {
    log_info "Verificando configuração..."
    
    # Testar se as chaves são válidas
    if openssl rsa -in ${PRIVATE_KEY_FILE} -check &> /dev/null; then
        log_success "Chave privada é válida"
    else
        log_error "Chave privada não é válida"
        exit 1
    fi
    
    # Testar chave pública
    if openssl rsa -pubin -in ${PUBLIC_KEY_FILE} -text -noout &> /dev/null; then
        log_success "Chave pública é válida"
    else
        log_error "Chave pública não é válida"
        exit 1
    fi
}

# Limpar arquivos temporários
cleanup() {
    log_info "Limpando arquivos temporários..."
    
    # Opcional: manter os arquivos para referência
    # rm -f ${PRIVATE_KEY_FILE} ${PUBLIC_KEY_FILE}
    
    log_success "Limpeza concluída"
}

# Função principal
main() {
    log_info "Iniciando configuração de chaves JWT..."
    
    check_dependencies
    generate_keys
    check_configuration
    
    # Perguntar se quer configurar no Azure
    read -p "Deseja configurar as chaves no Azure Key Vault? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_azure_keyvault
    else
        log_warning "Pulando configuração do Azure Key Vault"
    fi
    
    create_fallback_config
    cleanup
    
    log_success "Configuração de chaves JWT concluída!"
    log_info "Próximos passos:"
    echo "1. Configure as variáveis de ambiente no seu ambiente de produção"
    echo "2. Teste a aplicação: ./mvnw spring-boot:run -Dspring.profiles.active=test"
    echo "3. Verifique os logs para confirmar que as chaves estão sendo carregadas"
}

# Executar script
main "$@"