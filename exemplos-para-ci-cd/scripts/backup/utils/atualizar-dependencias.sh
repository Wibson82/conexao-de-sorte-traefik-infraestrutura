#!/bin/bash

# Script para Atualização de Dependências - Conexão de Sorte Backend
# Data: 30/12/2024
# Uso: ./scripts/atualizar-dependencias.sh [fase]

set -e

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${COLOR_BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${COLOR_NC}"
}

success() {
    echo -e "${COLOR_GREEN}✅ $1${COLOR_NC}"
}

warning() {
    echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_NC}"
}

error() {
    echo -e "${COLOR_RED}❌ $1${COLOR_NC}"
}

# Verificar se Maven está instalado
check_maven() {
    if ! command -v mvn &> /dev/null; then
        error "Maven não está instalado ou não está no PATH"
        exit 1
    fi
    success "Maven encontrado: $(mvn --version | head -1)"
}

# Backup do pom.xml
backup_pom() {
    log "Criando backup do pom.xml..."
    cp pom.xml "pom.xml.backup.$(date +%Y%m%d_%H%M%S)"
    success "Backup criado"
}

# Restaurar backup em caso de erro
restore_backup() {
    local backup_file=$(ls -t pom.xml.backup.* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]]; then
        log "Restaurando backup devido a erro..."
        cp "$backup_file" pom.xml
        warning "pom.xml restaurado do backup: $backup_file"
    fi
}

# Fase 1: Atualizações de Segurança (Críticas)
fase_1_seguranca() {
    log "=== FASE 1: ATUALIZAÇÕES DE SEGURANÇA ==="
    
    # Atualizar Spring Boot parent
    log "Atualizando Spring Boot para 3.5.3..."
    mvn versions:update-parent -DparentVersion=3.5.3 -DallowSnapshots=false
    
    # Atualizar propriedades Azure
    log "Atualizando Azure SDK BOM..."
    mvn versions:set-property -Dproperty=azure-sdk-bom.version -DnewVersion=1.2.36
    
    success "Fase 1 concluída - Atualizações de segurança aplicadas"
}

# Fase 2: Atualizações de Funcionalidades
fase_2_funcionalidades() {
    log "=== FASE 2: ATUALIZAÇÕES DE FUNCIONALIDADES ==="
    
    # JJWT
    log "Atualizando JJWT para 0.12.6..."
    mvn versions:set-property -Dproperty=jjwt.version -DnewVersion=0.12.6
    
    # JSoup
    log "Atualizando JSoup para 1.21.1..."
    mvn versions:set-property -Dproperty=jsoup.version -DnewVersion=1.21.1
    
    # SpringDoc
    log "Atualizando SpringDoc para 2.8.9..."
    mvn versions:set-property -Dproperty=springdoc.version -DnewVersion=2.8.9
    
    success "Fase 2 concluída - Atualizações de funcionalidades aplicadas"
}

# Fase 3: Atualizações de Plugins
fase_3_plugins() {
    log "=== FASE 3: ATUALIZAÇÕES DE PLUGINS ==="
    
    # SpotBugs
    log "Atualizando SpotBugs plugin para 4.9.3.2..."
    mvn versions:set-property -Dproperty=spotbugs-maven-plugin.version -DnewVersion=4.9.3.2
    
    success "Fase 3 concluída - Plugins atualizados"
}

# Compilar e testar
compilar_e_testar() {
    log "=== COMPILAÇÃO E TESTES ==="
    
    log "Limpando projeto..."
    mvn clean
    
    log "Compilando projeto..."
    if mvn compile; then
        success "Compilação bem-sucedida"
    else
        error "Falha na compilação"
        restore_backup
        exit 1
    fi
    
    log "Executando testes..."
    if mvn test -DskipTests=false; then
        success "Todos os testes passaram"
    else
        warning "Alguns testes falharam - verifique os logs"
        # Não aborta aqui, mas avisa
    fi
}

# Verificar dependências atualizadas
verificar_dependencias() {
    log "=== VERIFICAÇÃO FINAL ==="
    
    log "Verificando dependências após atualizações..."
    mvn dependency:tree > dependency-tree-after-update.txt
    
    log "Verificando plugins após atualizações..."
    mvn help:effective-pom > effective-pom-after-update.xml
    
    success "Verificação concluída - arquivos gerados:"
    echo "  - dependency-tree-after-update.txt"
    echo "  - effective-pom-after-update.xml"
}

# Gerar relatório de mudanças
gerar_relatorio() {
    log "=== GERANDO RELATÓRIO ==="
    
    local report_file="relatorio-atualizacao-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Relatório de Atualização de Dependências

**Data**: $(date)
**Projeto**: Conexão de Sorte Backend

## Atualizações Aplicadas

### Fase 1 - Segurança
- Spring Boot: 3.5.0 → 3.5.3
- Azure SDK BOM: 1.2.35 → 1.2.36

### Fase 2 - Funcionalidades
- JJWT: 0.12.5 → 0.12.6
- JSoup: 1.18.1 → 1.21.1
- SpringDoc: 2.7.0 → 2.8.9

### Fase 3 - Plugins
- SpotBugs: 4.8.6.4 → 4.9.3.2

## Status da Compilação
- ✅ Compilação: Sucesso
- ✅ Testes: $(if mvn test -q &>/dev/null; then echo "Sucesso"; else echo "Verificar logs"; fi)

## Próximos Passos
1. Testar aplicação em ambiente de desenvolvimento
2. Validar integração com Azure Key Vault
3. Executar testes de integração completos
4. Deploy em ambiente de homologação

## Arquivos Gerados
- dependency-tree-after-update.txt
- effective-pom-after-update.xml
- Backup do pom.xml original

EOF

    success "Relatório gerado: $report_file"
}

# Mostrar uso
mostrar_uso() {
    echo "Uso: $0 [opcao]"
    echo ""
    echo "Opções:"
    echo "  fase1     - Aplicar apenas atualizações de segurança"
    echo "  fase2     - Aplicar atualizações de funcionalidades"
    echo "  fase3     - Aplicar atualizações de plugins"
    echo "  all       - Aplicar todas as fases (recomendado)"
    echo "  check     - Apenas verificar dependências sem atualizar"
    echo "  help      - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 all          # Atualização completa"
    echo "  $0 fase1        # Apenas segurança"
    echo "  $0 check        # Verificar apenas"
}

# Verificar apenas sem atualizar
apenas_verificar() {
    log "=== VERIFICAÇÃO DE DEPENDÊNCIAS ==="
    
    log "Verificando atualizações disponíveis..."
    mvn versions:display-dependency-updates
    
    log "Verificando atualizações de plugins..."
    mvn versions:display-plugin-updates
    
    log "Verificando atualizações de propriedades..."
    mvn versions:display-property-updates
    
    success "Verificação concluída - nenhuma mudança aplicada"
}

# Função principal
main() {
    local fase=${1:-help}
    
    # Verificar se estamos no diretório correto
    if [[ ! -f "pom.xml" ]]; then
        error "pom.xml não encontrado. Execute este script na raiz do projeto."
        exit 1
    fi
    
    case $fase in
        "fase1")
            check_maven
            backup_pom
            fase_1_seguranca
            compilar_e_testar
            verificar_dependencias
            gerar_relatorio
            ;;
        "fase2")
            check_maven
            backup_pom
            fase_2_funcionalidades
            compilar_e_testar
            verificar_dependencias
            gerar_relatorio
            ;;
        "fase3")
            check_maven
            backup_pom
            fase_3_plugins
            compilar_e_testar
            verificar_dependencias
            gerar_relatorio
            ;;
        "all")
            check_maven
            backup_pom
            fase_1_seguranca
            fase_2_funcionalidades
            fase_3_plugins
            compilar_e_testar
            verificar_dependencias
            gerar_relatorio
            ;;
        "check")
            check_maven
            apenas_verificar
            ;;
        "help"|*)
            mostrar_uso
            exit 0
            ;;
    esac
    
    success "Processo concluído com sucesso!"
    warning "IMPORTANTE: Teste a aplicação antes de fazer commit das mudanças"
}

# Configurar trap para restaurar backup em caso de interrupção
trap 'error "Script interrompido"; restore_backup; exit 1' INT TERM

# Executar função principal
main "$@" 