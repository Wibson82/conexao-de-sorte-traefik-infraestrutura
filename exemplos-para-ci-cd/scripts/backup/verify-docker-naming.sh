#!/bin/bash

# 🐳 VERIFICAÇÃO NOMENCLATURA DOCKER
# ✅ Verifica se frontend e backend seguem mesmo padrão

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações esperadas
EXPECTED_REGISTRY="docker.io"
EXPECTED_NAMESPACE="facilita"
BACKEND_IMAGE="conexao-de-sorte-backend"
FRONTEND_IMAGE="conexao-de-sorte-frontend"

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar se Docker está disponível
check_docker() {
    log_step "Verificando Docker..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não encontrado"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        exit 1
    fi
    
    log_success "Docker disponível"
}

# Verificar imagens no Docker Hub
check_docker_hub_images() {
    log_step "Verificando imagens no Docker Hub..."
    
    # Verificar backend
    log_info "Verificando backend: $EXPECTED_NAMESPACE/$BACKEND_IMAGE"
    if docker pull "$EXPECTED_NAMESPACE/$BACKEND_IMAGE:latest" >/dev/null 2>&1; then
        log_success "Backend image disponível"
        
        # Verificar tags do backend
        local backend_tags=$(docker image ls "$EXPECTED_NAMESPACE/$BACKEND_IMAGE" --format "table {{.Tag}}" | tail -n +2 | head -5)
        log_info "Tags do backend encontradas:"
        echo "$backend_tags" | while read -r tag; do
            echo "  - $EXPECTED_NAMESPACE/$BACKEND_IMAGE:$tag"
        done
    else
        log_error "Backend image não encontrada"
    fi
    
    echo ""
    
    # Verificar frontend
    log_info "Verificando frontend: $EXPECTED_NAMESPACE/$FRONTEND_IMAGE"
    if docker pull "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE:latest" >/dev/null 2>&1; then
        log_success "Frontend image disponível"
        
        # Verificar tags do frontend
        local frontend_tags=$(docker image ls "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE" --format "table {{.Tag}}" | tail -n +2 | head -5)
        log_info "Tags do frontend encontradas:"
        echo "$frontend_tags" | while read -r tag; do
            echo "  - $EXPECTED_NAMESPACE/$FRONTEND_IMAGE:$tag"
        done
    else
        log_error "Frontend image não encontrada"
    fi
}

# Verificar padrão de nomenclatura
check_naming_pattern() {
    log_step "Verificando padrão de nomenclatura..."
    
    local backend_tags=$(docker image ls "$EXPECTED_NAMESPACE/$BACKEND_IMAGE" --format "{{.Tag}}" 2>/dev/null || echo "")
    local frontend_tags=$(docker image ls "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE" --format "{{.Tag}}" 2>/dev/null || echo "")
    
    # Verificar se tem tag 'latest'
    if echo "$backend_tags" | grep -q "^latest$"; then
        log_success "Backend tem tag 'latest'"
    else
        log_warn "Backend não tem tag 'latest'"
    fi
    
    if echo "$frontend_tags" | grep -q "^latest$"; then
        log_success "Frontend tem tag 'latest'"
    else
        log_warn "Frontend não tem tag 'latest'"
    fi
    
    # Verificar padrão branch-commit
    local backend_branch_tags=$(echo "$backend_tags" | grep -E "^[a-zA-Z0-9_-]+-[a-f0-9]{7,}$" | wc -l)
    local frontend_branch_tags=$(echo "$frontend_tags" | grep -E "^[a-zA-Z0-9_-]+-[a-f0-9]{7,}$" | wc -l)
    
    if [[ "$backend_branch_tags" -gt 0 ]]; then
        log_success "Backend tem $backend_branch_tags tags no padrão branch-commit"
    else
        log_warn "Backend não tem tags no padrão branch-commit"
    fi
    
    if [[ "$frontend_branch_tags" -gt 0 ]]; then
        log_success "Frontend tem $frontend_branch_tags tags no padrão branch-commit"
    else
        log_warn "Frontend não tem tags no padrão branch-commit"
    fi
}

# Verificar consistência entre projetos
check_consistency() {
    log_step "Verificando consistência entre projetos..."
    
    local backend_tags=$(docker image ls "$EXPECTED_NAMESPACE/$BACKEND_IMAGE" --format "{{.Tag}}" 2>/dev/null || echo "")
    local frontend_tags=$(docker image ls "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE" --format "{{.Tag}}" 2>/dev/null || echo "")
    
    # Verificar se ambos seguem mesmo padrão
    local backend_has_latest=$(echo "$backend_tags" | grep -c "^latest$" || echo "0")
    local frontend_has_latest=$(echo "$frontend_tags" | grep -c "^latest$" || echo "0")
    
    if [[ "$backend_has_latest" -eq "$frontend_has_latest" && "$backend_has_latest" -eq 1 ]]; then
        log_success "Ambos projetos têm tag 'latest'"
    else
        log_warn "Inconsistência na tag 'latest'"
    fi
    
    # Verificar namespace consistente
    log_info "Namespace usado: $EXPECTED_NAMESPACE"
    log_info "Registry usado: $EXPECTED_REGISTRY"
    
    if docker image ls | grep -q "$EXPECTED_NAMESPACE/$BACKEND_IMAGE" && docker image ls | grep -q "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE"; then
        log_success "Ambos projetos usam namespace consistente"
    else
        log_warn "Namespace pode estar inconsistente"
    fi
}

# Mostrar recomendações
show_recommendations() {
    log_header "RECOMENDAÇÕES"
    
    echo -e "${BLUE}🎯 Padrão recomendado:${NC}"
    echo -e "  Registry: ${CYAN}$EXPECTED_REGISTRY${NC}"
    echo -e "  Namespace: ${CYAN}$EXPECTED_NAMESPACE${NC}"
    echo -e "  Backend: ${CYAN}$EXPECTED_NAMESPACE/$BACKEND_IMAGE${NC}"
    echo -e "  Frontend: ${CYAN}$EXPECTED_NAMESPACE/$FRONTEND_IMAGE${NC}"
    
    echo -e "\n${BLUE}🏷️ Tags recomendadas:${NC}"
    echo -e "  • ${CYAN}latest${NC} - Última versão estável"
    echo -e "  • ${CYAN}main-a1b2c3d${NC} - Branch main + commit"
    echo -e "  • ${CYAN}feature-xyz-e4f5g6h${NC} - Branch feature + commit"
    
    echo -e "\n${BLUE}📝 Para implementar no frontend:${NC}"
    echo -e "  1. Adicionar variáveis de ambiente no workflow"
    echo -e "  2. Usar docker/metadata-action@v5"
    echo -e "  3. Configurar tags automáticas"
    echo -e "  4. Testar build e push"
    
    echo -e "\n${BLUE}🔍 Comandos úteis:${NC}"
    echo -e "  • Listar tags backend: ${CYAN}docker image ls $EXPECTED_NAMESPACE/$BACKEND_IMAGE${NC}"
    echo -e "  • Listar tags frontend: ${CYAN}docker image ls $EXPECTED_NAMESPACE/$FRONTEND_IMAGE${NC}"
    echo -e "  • Pull específico: ${CYAN}docker pull $EXPECTED_NAMESPACE/$FRONTEND_IMAGE:latest${NC}"
}

# Verificar configuração local
check_local_config() {
    log_step "Verificando configuração local..."
    
    # Verificar se há imagens locais
    local backend_local=$(docker image ls "$EXPECTED_NAMESPACE/$BACKEND_IMAGE" --format "{{.Tag}}" 2>/dev/null | wc -l)
    local frontend_local=$(docker image ls "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE" --format "{{.Tag}}" 2>/dev/null | wc -l)
    
    log_info "Imagens backend locais: $backend_local"
    log_info "Imagens frontend locais: $frontend_local"
    
    if [[ "$backend_local" -gt 0 && "$frontend_local" -gt 0 ]]; then
        log_success "Ambos projetos têm imagens locais"
    elif [[ "$backend_local" -gt 0 ]]; then
        log_warn "Apenas backend tem imagens locais"
    elif [[ "$frontend_local" -gt 0 ]]; then
        log_warn "Apenas frontend tem imagens locais"
    else
        log_info "Nenhuma imagem local encontrada (normal)"
    fi
}

# Mostrar resumo final
show_summary() {
    log_header "RESUMO DA VERIFICAÇÃO"
    
    local backend_available=$(docker image ls "$EXPECTED_NAMESPACE/$BACKEND_IMAGE" --format "{{.Tag}}" 2>/dev/null | wc -l)
    local frontend_available=$(docker image ls "$EXPECTED_NAMESPACE/$FRONTEND_IMAGE" --format "{{.Tag}}" 2>/dev/null | wc -l)
    
    echo -e "${BLUE}📊 Status atual:${NC}"
    
    if [[ "$backend_available" -gt 0 ]]; then
        echo -e "  ${GREEN}✅ Backend: $backend_available imagens disponíveis${NC}"
    else
        echo -e "  ${RED}❌ Backend: Nenhuma imagem encontrada${NC}"
    fi
    
    if [[ "$frontend_available" -gt 0 ]]; then
        echo -e "  ${GREEN}✅ Frontend: $frontend_available imagens disponíveis${NC}"
    else
        echo -e "  ${RED}❌ Frontend: Nenhuma imagem encontrada${NC}"
    fi
    
    echo -e "\n${BLUE}🎯 Próximos passos:${NC}"
    if [[ "$frontend_available" -eq 0 ]]; then
        echo -e "  1. ${YELLOW}Implementar padrão no frontend${NC}"
        echo -e "  2. ${YELLOW}Fazer push para gerar imagens${NC}"
        echo -e "  3. ${YELLOW}Verificar tags geradas${NC}"
    else
        echo -e "  1. ${GREEN}Verificar se tags seguem padrão${NC}"
        echo -e "  2. ${GREEN}Testar deploy conjunto${NC}"
        echo -e "  3. ${GREEN}Monitorar consistência${NC}"
    fi
    
    echo -e "\n${BLUE}📚 Documentação:${NC}"
    echo -e "  • PROMPT-NOMENCLATURA-DOCKER-FRONTEND.md"
    echo -e "  • PROMPT-DIRETO-FRONTEND.md"
}

# EXECUÇÃO PRINCIPAL
main() {
    log_header "VERIFICAÇÃO NOMENCLATURA DOCKER"
    
    check_docker
    check_docker_hub_images
    check_naming_pattern
    check_consistency
    check_local_config
    show_recommendations
    show_summary
    
    echo -e "\n${GREEN}🔍 Verificação concluída!${NC}\n"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
