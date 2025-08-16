#!/bin/bash
# =============================================================================
# SCRIPT DE VALIDAÇÃO DA CORREÇÃO DO AMBIENTE DE TESTE
# =============================================================================
# Este script valida se a correção do loop infinito no ambiente de teste
# foi aplicada corretamente

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVICO_FALLBACK_FILE="$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/integracao/azure/ServicoSecretsFallback.java"

# Funções de log
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
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Função principal de validação
validar_correcao() {
    log_info "🔍 Validando correção do ambiente de teste..."
    echo ""
    
    # 1. Verificar se o arquivo existe
    if [[ ! -f "$SERVICO_FALLBACK_FILE" ]]; then
        log_error "❌ Arquivo ServicoSecretsFallback.java não encontrado!"
        log_error "   Caminho esperado: $SERVICO_FALLBACK_FILE"
        return 1
    fi
    log_success "✅ Arquivo ServicoSecretsFallback.java encontrado"
    
    # 2. Verificar se a anotação @Profile contém 'test'
    if grep -q '@Profile.*"test"' "$SERVICO_FALLBACK_FILE"; then
        log_success "✅ Perfil 'test' encontrado na anotação @Profile"
        
        # Mostrar a linha específica
        local profile_line
        profile_line=$(grep '@Profile' "$SERVICO_FALLBACK_FILE")
        log_info "   📋 Linha encontrada: $profile_line"
    else
        log_error "❌ Perfil 'test' NÃO encontrado na anotação @Profile!"
        log_error "   A correção não foi aplicada corretamente."
        
        # Mostrar a linha atual
        local current_line
        current_line=$(grep '@Profile' "$SERVICO_FALLBACK_FILE" || echo "Linha @Profile não encontrada")
        log_error "   📋 Linha atual: $current_line"
        return 1
    fi
    
    # 3. Verificar se todos os perfis necessários estão presentes
    local perfis_necessarios=("prod" "production" "dev" "development" "macos" "ubuntu" "test")
    local perfis_faltando=()
    
    for perfil in "${perfis_necessarios[@]}"; do
        if ! grep -q "\"$perfil\"" "$SERVICO_FALLBACK_FILE"; then
            perfis_faltando+=("$perfil")
        fi
    done
    
    if [[ ${#perfis_faltando[@]} -eq 0 ]]; then
        log_success "✅ Todos os perfis necessários estão presentes"
        log_info "   📋 Perfis: ${perfis_necessarios[*]}"
    else
        log_warning "⚠️  Alguns perfis estão faltando: ${perfis_faltando[*]}"
    fi
    
    # 4. Verificar configurações do docker-compose.test.yml
    local docker_compose_test="$PROJECT_ROOT/docker-compose.test.yml"
    if [[ -f "$docker_compose_test" ]]; then
        log_success "✅ Arquivo docker-compose.test.yml encontrado"
        
        # Verificar perfis Spring
        if grep -q "SPRING_PROFILES_ACTIVE=test,prod" "$docker_compose_test"; then
            log_success "✅ Perfis Spring configurados corretamente (test,prod)"
        else
            log_warning "⚠️  Perfis Spring podem não estar configurados corretamente"
        fi
        
        # Verificar Azure Key Vault
        if grep -q "AZURE_KEYVAULT_FALLBACK_ENABLED=true" "$docker_compose_test"; then
            log_success "✅ Azure Key Vault fallback habilitado"
        else
            log_warning "⚠️  Azure Key Vault fallback pode não estar habilitado"
        fi
    else
        log_warning "⚠️  Arquivo docker-compose.test.yml não encontrado"
    fi
    
    echo ""
    log_success "🎉 VALIDAÇÃO CONCLUÍDA!"
    echo ""
    
    # Resumo da correção
    log_info "📋 RESUMO DA CORREÇÃO APLICADA:"
    echo "   • Adicionado perfil 'test' na anotação @Profile do ServicoSecretsFallback"
    echo "   • Isso permite que o serviço seja injetado no ambiente de teste"
    echo "   • Resolve o loop infinito causado pela dependência não satisfeita"
    echo "   • Mantém a segurança e arquitetura de produção"
    echo ""
    
    log_info "🚀 PRÓXIMOS PASSOS:"
    echo "   1. Construir a imagem de teste: ./scripts/manage-test-environment.sh build"
    echo "   2. Iniciar o ambiente: ./scripts/manage-test-environment.sh start"
    echo "   3. Verificar logs: ./scripts/manage-test-environment.sh logs"
    echo "   4. Testar endpoints: curl http://localhost:8081/actuator/health"
    echo ""
    
    return 0
}

# Função para mostrar diferenças
mostrar_diferencas() {
    log_info "📊 DIFERENÇAS ENTRE AMBIENTES:"
    echo ""
    echo "┌─────────────────┬─────────────────┬─────────────────┐"
    echo "│ Aspecto         │ Produção        │ Teste           │"
    echo "├─────────────────┼─────────────────┼─────────────────┤"
    echo "│ Porta Backend   │ 8080            │ 8081            │"
    echo "│ Perfil Spring   │ production      │ test,prod       │"
    echo "│ Azure Key Vault │ Habilitado      │ Habilitado*     │"
    echo "│ Fallback        │ Emergência      │ Sempre ativo    │"
    echo "│ Memória JVM     │ 2GB             │ 1GB             │"
    echo "│ Logs Level      │ INFO            │ DEBUG           │"
    echo "└─────────────────┴─────────────────┴─────────────────┘"
    echo ""
    echo "* Com fallback sempre habilitado para testes"
    echo ""
}

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  validar     - Validar se a correção foi aplicada (padrão)"
    echo "  diferencas  - Mostrar diferenças entre ambientes"
    echo "  help        - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                    # Validar correção"
    echo "  $0 validar            # Validar correção"
    echo "  $0 diferencas         # Mostrar diferenças"
}

# Função principal
main() {
    local comando="${1:-validar}"
    
    case "$comando" in
        "validar")
            validar_correcao
            ;;
        "diferencas")
            mostrar_diferencas
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "Comando inválido: $comando"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"