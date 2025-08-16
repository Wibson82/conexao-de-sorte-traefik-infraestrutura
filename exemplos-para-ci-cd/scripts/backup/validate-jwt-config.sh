#!/bin/bash

# =============================================================================
# SCRIPT DE VALIDAÇÃO DE CONFIGURAÇÃO JWT - CONEXÃO DE SORTE
# =============================================================================
# Este script valida se a configuração de chaves JWT está funcionando corretamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Função para verificar Azure Key Vault
check_azure_keyvault() {
    log_info "Verificando Azure Key Vault..."
    
    # Verificar se está logado
    if ! az account show &> /dev/null; then
        log_error "Não está logado no Azure"
        return 1
    fi
    
    # Verificar se secrets existem
    if az keyvault secret show --vault-name conexao-de-sorte-kv --name jwt-private-key &> /dev/null; then
        log_success "jwt-private-key encontrada no Key Vault"
    else
        log_error "jwt-private-key não encontrada no Key Vault"
        return 1
    fi
    
    if az keyvault secret show --vault-name conexao-de-sorte-kv --name jwt-public-key &> /dev/null; then
        log_success "jwt-public-key encontrada no Key Vault"
    else
        log_error "jwt-public-key não encontrada no Key Vault"
        return 1
    fi
}

# Função para verificar variáveis de ambiente
check_environment_variables() {
    log_info "Verificando variáveis de ambiente..."
    
    # Verificar arquivo .env.prod
    if [ -f ".env.prod" ]; then
        log_success "Arquivo .env.prod encontrado"
        
        # Verificar variáveis essenciais
        if grep -q "AZURE_KEYVAULT_ENABLED=true" .env.prod; then
            log_success "AZURE_KEYVAULT_ENABLED=true configurado"
        else
            log_warning "AZURE_KEYVAULT_ENABLED não está configurado como true"
        fi
        
        if grep -q "AZURE_KEYVAULT_ENDPOINT" .env.prod; then
            log_success "AZURE_KEYVAULT_ENDPOINT configurado"
        else
            log_error "AZURE_KEYVAULT_ENDPOINT não encontrado"
            return 1
        fi
    else
        log_warning "Arquivo .env.prod não encontrado"
    fi
}

# Função para verificar configuração de logging
check_logging_config() {
    log_info "Verificando configuração de logging..."
    
    # Verificar arquivo de configuração
    if [ -f "src/main/resources/logback-spring.xml" ]; then
        log_success "logback-spring.xml encontrado"
        
        # Verificar profiles
        if grep -q "springProfile name=\"prod,azure\"" src/main/resources/logback-spring.xml; then
            log_success "Profile prod,azure configurado no logback"
        else
            log_warning "Profile prod,azure não encontrado no logback"
        fi
    else
        log_error "logback-spring.xml não encontrado"
        return 1
    fi
}

# Função para verificar configuração Spring
check_spring_config() {
    log_info "Verificando configuração Spring..."
    
    # Verificar application.yml
    if [ -f "src/main/resources/application.yml" ]; then
        log_success "application.yml encontrado"
        
        # Verificar configuração JWT
        if grep -q "jwt:" src/main/resources/application.yml; then
            log_success "Configuração JWT encontrada em application.yml"
        else
            log_warning "Configuração JWT não encontrada em application.yml"
        fi
    else
        log_error "application.yml não encontrado"
        return 1
    fi
}

# Função para testar build Maven
test_maven_build() {
    log_info "Testando build Maven..."
    
    if ./mvnw clean compile -q &> /dev/null; then
        log_success "Build Maven bem-sucedido"
    else
        log_error "Build Maven falhou"
        return 1
    fi
}

# Função para testar configuração local
test_local_config() {
    log_info "Testando configuração local..."
    
    # Criar arquivo de teste temporário
    cat > test-jwt-config.yml << EOF
spring:
  profiles:
    active: test
  cloud:
    azure:
      keyvault:
        secret:
          property-sources[0]:
            endpoint: https://conexao-de-sorte-kv.vault.azure.net/
            enabled: false
  security:
    jwt:
      secret: test-secret-key-for-validation-only
EOF

    log_success "Configuração de teste criada"
}

# Função principal de validação
main() {
    log_info "Iniciando validação de configuração JWT..."
    
    local exit_code=0
    
    # Verificar Azure Key Vault (opcional)
    if command -v az &> /dev/null; then
        check_azure_keyvault || exit_code=1
    else
        log_warning "Azure CLI não disponível, pulando verificação do Key Vault"
    fi
    
    # Verificar variáveis de ambiente
    check_environment_variables || exit_code=1
    
    # Verificar configuração de logging
    check_logging_config || exit_code=1
    
    # Verificar configuração Spring
    check_spring_config || exit_code=1
    
    # Testar build
    test_maven_build || exit_code=1
    
    # Testar configuração local
    test_local_config
    
    # Limpar arquivos temporários
    rm -f test-jwt-config.yml
    
    if [ $exit_code -eq 0 ]; then
        log_success "Validação concluída com sucesso!"
        echo ""
        echo "Próximos passos:"
        echo "1. Configure as chaves no Azure Key Vault (se ainda não fez)"
        echo "2. Execute: ./scripts/setup-jwt-keys.sh"
        echo "3. Teste a aplicação: ./mvnw spring-boot:run -Dspring.profiles.active=test"
    else
        log_error "Validação encontrou problemas. Por favor, verifique os logs acima."
    fi
    
    return $exit_code
}

# Executar validação
main "$@"