#!/bin/bash

# =============================================================================
# SCRIPT DE MANUTENÇÃO DO HOMEBREW
# =============================================================================
# Descrição: Script para manutenção preventiva do Homebrew
# Autor: Sistema de Manutenção Automatizada
# Data: $(date '+%Y-%m-%d')
# =============================================================================

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

# Função para verificar se o Homebrew está instalado
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado"
        exit 1
    fi
    log_success "Homebrew encontrado: $(brew --version | head -n1)"
}

# Função para atualizar o Homebrew
update_homebrew() {
    log_info "Atualizando repositórios do Homebrew..."
    if brew update; then
        log_success "Repositórios atualizados com sucesso"
    else
        log_error "Falha ao atualizar repositórios"
        return 1
    fi
}

# Função para verificar pacotes desatualizados
check_outdated() {
    log_info "Verificando pacotes desatualizados..."
    
    local outdated_formulae
    local outdated_casks
    
    outdated_formulae=$(brew outdated --formula 2>/dev/null || echo "")
    outdated_casks=$(brew outdated --cask 2>/dev/null || echo "")
    
    if [[ -n "$outdated_formulae" ]]; then
        log_warning "Formulae desatualizados encontrados:"
        echo "$outdated_formulae"
        return 1
    fi
    
    if [[ -n "$outdated_casks" ]]; then
        log_warning "Casks desatualizados encontrados:"
        echo "$outdated_casks"
        return 1
    fi
    
    log_success "Todos os pacotes estão atualizados"
    return 0
}

# Função para atualizar pacotes
upgrade_packages() {
    log_info "Atualizando pacotes desatualizados..."
    
    if brew upgrade; then
        log_success "Pacotes atualizados com sucesso"
    else
        log_error "Falha ao atualizar pacotes"
        return 1
    fi
}

# Função para limpar cache
cleanup_cache() {
    log_info "Limpando cache do Homebrew..."
    
    local space_before
    local space_after
    
    # Obter espaço usado antes da limpeza
    space_before=$(du -sh ~/Library/Caches/Homebrew 2>/dev/null | cut -f1 || echo "0B")
    
    if brew cleanup; then
        space_after=$(du -sh ~/Library/Caches/Homebrew 2>/dev/null | cut -f1 || echo "0B")
        log_success "Cache limpo com sucesso (antes: $space_before, depois: $space_after)"
    else
        log_error "Falha ao limpar cache"
        return 1
    fi
}

# Função para verificar saúde do sistema
check_health() {
    log_info "Verificando saúde do Homebrew..."
    
    local doctor_output
    doctor_output=$(brew doctor 2>&1)
    
    if echo "$doctor_output" | grep -q "Your system is ready to brew"; then
        log_success "Sistema está saudável"
    else
        log_warning "Problemas encontrados:"
        echo "$doctor_output"
        return 1
    fi
}

# Função para gerar relatório
generate_report() {
    local report_file="logs/homebrew-maintenance-$(date '+%Y%m%d-%H%M%S').log"
    
    log_info "Gerando relatório de manutenção..."
    
    mkdir -p logs
    
    {
        echo "====================================================================="
        echo "RELATÓRIO DE MANUTENÇÃO DO HOMEBREW"
        echo "====================================================================="
        echo "Data: $(date)"
        echo "Usuário: $(whoami)"
        echo "Sistema: $(uname -a)"
        echo ""
        echo "VERSÃO DO HOMEBREW:"
        brew --version
        echo ""
        echo "PACOTES INSTALADOS:"
        echo "Formulae: $(brew list --formula | wc -l | tr -d ' ')"
        echo "Casks: $(brew list --cask | wc -l | tr -d ' ')"
        echo ""
        echo "ESPAÇO EM CACHE:"
        du -sh ~/Library/Caches/Homebrew 2>/dev/null || echo "Cache não encontrado"
        echo ""
        echo "STATUS DO SISTEMA:"
        brew doctor
        echo ""
        echo "====================================================================="
    } > "$report_file"
    
    log_success "Relatório salvo em: $report_file"
}

# Função principal
main() {
    echo "====================================================================="
    echo "🍺 MANUTENÇÃO AUTOMÁTICA DO HOMEBREW"
    echo "====================================================================="
    echo ""
    
    local exit_code=0
    
    # Verificar se Homebrew está instalado
    check_homebrew || exit 1
    
    # Atualizar repositórios
    update_homebrew || exit_code=1
    
    # Verificar pacotes desatualizados
    if ! check_outdated; then
        log_info "Pacotes desatualizados encontrados, iniciando atualização..."
        upgrade_packages || exit_code=1
    fi
    
    # Limpar cache
    cleanup_cache || exit_code=1
    
    # Verificar saúde
    check_health || exit_code=1
    
    # Gerar relatório
    generate_report
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Manutenção concluída com sucesso!"
        echo "====================================================================="
        echo "✅ SISTEMA HOMEBREW ESTÁ SAUDÁVEL"
        echo "====================================================================="
    else
        log_warning "Manutenção concluída com alguns avisos"
        echo "====================================================================="
        echo "⚠️  VERIFIQUE OS LOGS PARA DETALHES"
        echo "====================================================================="
    fi
    
    exit $exit_code
}

# Verificar argumentos
case "${1:-}" in
    --help|-h)
        echo "Uso: $0 [opções]"
        echo ""
        echo "Opções:"
        echo "  --help, -h     Mostra esta ajuda"
        echo "  --check-only   Apenas verifica, não faz alterações"
        echo "  --force        Força atualização mesmo se não houver pacotes desatualizados"
        echo ""
        echo "Exemplos:"
        echo "  $0                 # Executa manutenção completa"
        echo "  $0 --check-only   # Apenas verifica status"
        echo "  $0 --force        # Força atualização"
        exit 0
        ;;
    --check-only)
        log_info "Modo somente verificação ativado"
        check_homebrew
        check_outdated
        check_health
        generate_report
        exit 0
        ;;
    --force)
        log_info "Modo força ativado"
        main
        ;;
    "")
        main
        ;;
    *)
        log_error "Opção inválida: $1"
        echo "Use --help para ver as opções disponíveis"
        exit 1
        ;;
esac