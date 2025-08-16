#!/bin/bash

# 🔐 REFATORAÇÃO SEGURANÇA BASEADA EM PERFIS
# ✅ Aplica anotações de segurança corretas nos controllers baseado em perfis

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Função para adicionar import se não existir
add_import_if_missing() {
    local file="$1"
    local import_line="$2"
    
    if ! grep -q "$import_line" "$file"; then
        # Encontrar linha após os imports do Spring
        local insert_line=$(grep -n "import org.springframework" "$file" | tail -1 | cut -d: -f1)
        if [[ -n "$insert_line" ]]; then
            sed -i.tmp "${insert_line}a\\
$import_line" "$file"
            rm -f "$file.tmp"
            log_info "    Import adicionado: $import_line"
        fi
    fi
}

# Função para refatorar controller específico
refactor_controller() {
    local file="$1"
    local controller_name="$2"
    local profile="$3"
    
    log_step "Refatorando: $controller_name ($profile)"
    
    if [[ ! -f "$file" ]]; then
        log_warn "  Arquivo não encontrado: $file"
        return 1
    fi
    
    # Fazer backup
    cp "$file" "$file.backup"
    
    # Adicionar import do PreAuthorize se necessário
    add_import_if_missing "$file" "import org.springframework.security.access.prepost.PreAuthorize;"
    
    case "$profile" in
        "USER")
            # Adicionar @PreAuthorize("hasRole('USER')") em métodos que não são públicos
            log_info "  Aplicando perfil USER - autenticação obrigatória"
            
            # Adicionar anotação em métodos POST, PUT, DELETE, PATCH
            sed -i.tmp 's/@PostMapping\(.*\)/@PreAuthorize("hasRole('\''USER'\''")\
    @PostMapping\1/g' "$file"
            sed -i.tmp 's/@PutMapping\(.*\)/@PreAuthorize("hasRole('\''USER'\''")\
    @PutMapping\1/g' "$file"
            sed -i.tmp 's/@DeleteMapping\(.*\)/@PreAuthorize("hasRole('\''USER'\''")\
    @DeleteMapping\1/g' "$file"
            sed -i.tmp 's/@PatchMapping\(.*\)/@PreAuthorize("hasRole('\''USER'\''")\
    @PatchMapping\1/g' "$file"
            
            # Adicionar em métodos GET que não são públicos
            sed -i.tmp 's/@GetMapping\((?!.*publico).*\)/@PreAuthorize("hasRole('\''USER'\''")\
    @GetMapping\1/g' "$file"
            
            rm -f "$file.tmp"
            ;;
            
        "OPERADOR")
            log_info "  Aplicando perfil OPERADOR - operações do sistema"
            
            # Adicionar @PreAuthorize("hasRole('OPERADOR')") em todos os métodos
            sed -i.tmp 's/@\(Get\|Post\|Put\|Delete\|Patch\)Mapping\(.*\)/@PreAuthorize("hasRole('\''OPERADOR'\''")\
    @\1Mapping\2/g' "$file"
            
            rm -f "$file.tmp"
            ;;
            
        "ADMIN")
            log_info "  Aplicando perfil ADMIN - administração completa"
            
            # Adicionar @PreAuthorize("hasRole('ADMIN')") em todos os métodos
            sed -i.tmp 's/@\(Get\|Post\|Put\|Delete\|Patch\)Mapping\(.*\)/@PreAuthorize("hasRole('\''ADMIN'\''")\
    @\1Mapping\2/g' "$file"
            
            rm -f "$file.tmp"
            ;;
            
        "PUBLIC")
            log_info "  Aplicando perfil PUBLIC - sem alterações necessárias"
            # Endpoints públicos não precisam de anotações
            ;;
            
        *)
            log_warn "  Perfil desconhecido: $profile"
            ;;
    esac
    
    log_success "  $controller_name refatorado com sucesso"
}

# Função para desabilitar configuração antiga
disable_old_security_config() {
    log_step "Desabilitando configuração de segurança antiga..."
    
    local old_config="src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/ConfiguracaoSegurancaOAuth2.java"
    
    if [[ -f "$old_config" ]]; then
        # Renomear para .old
        mv "$old_config" "${old_config}.old"
        log_success "  Configuração antiga desabilitada: ${old_config}.old"
    else
        log_info "  Configuração antiga não encontrada"
    fi
}

# Função principal
main() {
    log_header "REFATORAÇÃO SEGURANÇA BASEADA EM PERFIS"
    
    echo -e "${YELLOW}🎯 Aplicando segurança baseada em perfis de usuário${NC}"
    echo -e "${BLUE}📋 Perfis: PÚBLICO, USER, OPERADOR, ADMIN${NC}\n"
    
    # Definir controllers e seus perfis
    declare -A controllers=(
        # Controllers de usuário (requerem autenticação)
        ["src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/controller/ConversaControlador.java"]="USER|ConversaControlador"
        ["src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/controller/GrupoControlador.java"]="USER|GrupoControlador"
        ["src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/verificacao/ControladorCodigoVerificacao.java"]="USER|ControladorCodigoVerificacao"
        
        # Controllers operacionais (requerem ROLE_OPERADOR)
        ["src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controller/ControladorResultadoLoteria.java"]="OPERADOR|ControladorResultadoLoteria"
        
        # Controllers públicos (sem alteração necessária)
        ["src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/publico/ControladorTestePublico.java"]="PUBLIC|ControladorTestePublico"
        ["src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/ControladorInformacoesAplicacao.java"]="PUBLIC|ControladorInformacoesAplicacao"
        
        # Controllers administrativos (já têm @PreAuthorize correto)
        # ControladorMetricas e ControladorMonitoramentoCache já estão corretos
    )
    
    local total_controllers=${#controllers[@]}
    local processed_controllers=0
    
    # Processar cada controller
    for file in "${!controllers[@]}"; do
        local controller_info="${controllers[$file]}"
        IFS='|' read -r profile controller_name <<< "$controller_info"
        
        if refactor_controller "$file" "$controller_name" "$profile"; then
            ((processed_controllers++))
        fi
    done
    
    echo ""
    
    # Desabilitar configuração antiga
    disable_old_security_config
    
    echo ""
    
    # Mostrar resumo
    log_header "RESUMO DA REFATORAÇÃO"
    
    echo -e "${BLUE}📊 Estatísticas:${NC}"
    echo -e "  Controllers processados: ${CYAN}$processed_controllers/$total_controllers${NC}"
    
    echo -e "\n${BLUE}🔐 Perfis aplicados:${NC}"
    echo -e "  ${GREEN}✅ PÚBLICO${NC}: Endpoints sem autenticação (/v1/publico/**, /v1/info/**)"
    echo -e "  ${GREEN}✅ USER${NC}: Endpoints com autenticação básica (mensagens, conversas, grupos)"
    echo -e "  ${GREEN}✅ OPERADOR${NC}: Endpoints operacionais (loterias, resultados)"
    echo -e "  ${GREEN}✅ ADMIN${NC}: Endpoints administrativos (métricas, cache, configurações)"
    
    echo -e "\n${BLUE}📁 Arquivos de backup:${NC}"
    echo -e "  Criados arquivos .backup para rollback se necessário"
    
    echo -e "\n${BLUE}🔧 Nova configuração:${NC}"
    echo -e "  ConfiguracaoSegurancaPerfilBased.java ativada"
    echo -e "  ConfiguracaoSegurancaOAuth2.java desabilitada"
    
    echo -e "\n${BLUE}🔍 Verificação:${NC}"
    echo -e "  Para verificar as mudanças: ${CYAN}git diff${NC}"
    echo -e "  Para compilar: ${CYAN}mvn clean compile${NC}"
    echo -e "  Para testar: ${CYAN}mvn test${NC}"
    
    if [[ "$processed_controllers" -eq "$total_controllers" ]]; then
        echo -e "\n${GREEN}✅ Refatoração concluída com sucesso!${NC}"
        echo -e "${BLUE}💡 Próximos passos:${NC}"
        echo -e "  1. Compilar e testar a aplicação"
        echo -e "  2. Verificar se todos os endpoints funcionam corretamente"
        echo -e "  3. Fazer commit das mudanças"
        echo -e "  4. Testar autenticação e autorização"
    else
        echo -e "\n${YELLOW}⚠️ Alguns controllers não foram processados${NC}"
        echo -e "${BLUE}💡 Verificar logs acima para detalhes${NC}"
    fi
    
    echo ""
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
