#!/bin/bash

# ============================================================================
# 🔍 SCRIPT DE VERIFICAÇÃO E MANUTENÇÃO DA DOCUMENTAÇÃO
# ============================================================================
#
# Este script verifica a integridade da documentação do projeto:
# - Links quebrados em arquivos markdown
# - Arquivos obsoletos ou duplicados
# - Consistência de formatação
# - Estrutura de diretórios
#
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
DOCS_DIR="docs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🔍 VERIFICANDO DOCUMENTAÇÃO DO PROJETO${NC}"
echo "=================================================="
echo ""

# Função para verificar se um arquivo existe
check_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅${NC} $file"
        return 0
    else
        echo -e "${RED}❌${NC} $file (NÃO ENCONTRADO)"
        return 1
    fi
}

# Função para verificar links em arquivos markdown
check_markdown_links() {
    local file="$1"
    local broken_links=0

    echo -e "${BLUE}📄 Verificando links em: $file${NC}"

    # Extrair links markdown
    local links=$(grep -o '\[.*\]([^)]*\.md)' "$file" 2>/dev/null || true)

    if [[ -n "$links" ]]; then
        while IFS= read -r link; do
            # Extrair o caminho do arquivo do link
            local file_path=$(echo "$link" | sed -n 's/.*](\([^)]*\.md\)).*/\1/p')

            if [[ -n "$file_path" ]]; then
                # Remover ./ do início se existir
                file_path=$(echo "$file_path" | sed 's|^\./||')

                # Construir caminho completo
                local full_path="$DOCS_DIR/$file_path"

                if [[ -f "$full_path" ]]; then
                    echo -e "  ${GREEN}✅${NC} $file_path"
                else
                    echo -e "  ${RED}❌${NC} $file_path (LINK QUEBRADO)"
                    ((broken_links++))
                fi
            fi
        done <<< "$links"
    else
        echo -e "  ${YELLOW}⚠️${NC} Nenhum link markdown encontrado"
    fi

    return $broken_links
}

# Função para verificar estrutura de diretórios
check_directory_structure() {
    echo -e "${BLUE}📁 Verificando estrutura de diretórios${NC}"

    # Verificar se o diretório docs existe
    if [[ ! -d "$DOCS_DIR" ]]; then
        echo -e "${RED}❌${NC} Diretório $DOCS_DIR não encontrado"
        return 1
    fi

    echo -e "${GREEN}✅${NC} Diretório $DOCS_DIR encontrado"

    # Verificar se o README.md existe
    if [[ -f "$DOCS_DIR/README.md" ]]; then
        echo -e "${GREEN}✅${NC} README.md encontrado"
    else
        echo -e "${RED}❌${NC} README.md não encontrado"
    fi

    # Verificar diretório ADR
    if [[ -d "$DOCS_DIR/adr" ]]; then
        echo -e "${GREEN}✅${NC} Diretório adr/ encontrado"
        local adr_files=$(find "$DOCS_DIR/adr" -name "*.md" | wc -l)
        echo -e "  📄 $adr_files arquivos ADR encontrados"
    else
        echo -e "${YELLOW}⚠️${NC} Diretório adr/ não encontrado"
    fi
}

# Função para verificar arquivos obsoletos
check_obsolete_files() {
    echo -e "${BLUE}🗑️ Verificando arquivos obsoletos${NC}"

    local obsolete_patterns=(
        "*CORRECAO-ERRO-*"
        "*RESUMO-CORRECOES-LOG-*"
        "*RESUMO-CORRECOES-TRAEFIK-*"
        "*TESTE*"
        "*TEMP*"
    )

    # Excluir templates da verificação de arquivos obsoletos
    local exclude_patterns=(
        "*/templates/*"
    )

    local found_obsolete=0

        for pattern in "${obsolete_patterns[@]}"; do
        local files=$(find "$DOCS_DIR" -name "$pattern" -type f 2>/dev/null || true)

        if [[ -n "$files" ]]; then
            # Filtrar arquivos excluídos
            local filtered_files=""
            while IFS= read -r file; do
                local should_exclude=false
                for exclude_pattern in "${exclude_patterns[@]}"; do
                    if [[ "$file" == $exclude_pattern ]]; then
                        should_exclude=true
                        break
                    fi
                done

                if [[ "$should_exclude" == false ]]; then
                    if [[ -z "$filtered_files" ]]; then
                        filtered_files="$file"
                    else
                        filtered_files="$filtered_files"$'\n'"$file"
                    fi
                fi
            done <<< "$files"

            if [[ -n "$filtered_files" ]]; then
                echo -e "${YELLOW}⚠️${NC} Possíveis arquivos obsoletos encontrados:"
                while IFS= read -r file; do
                    echo -e "  📄 $file"
                    ((found_obsolete++))
                done <<< "$filtered_files"
            fi
        fi
    done

    if [[ $found_obsolete -eq 0 ]]; then
        echo -e "${GREEN}✅${NC} Nenhum arquivo obsoleto detectado"
    fi

    return $found_obsolete
}

# Função para verificar consistência de formatação
check_formatting() {
    echo -e "${BLUE}📝 Verificando consistência de formatação${NC}"

    local markdown_files=$(find "$DOCS_DIR" -name "*.md" -type f)
    local total_files=0
    local formatted_files=0

    while IFS= read -r file; do
        ((total_files++))

        # Verificar se o arquivo tem título principal
        if grep -q "^# " "$file"; then
            ((formatted_files++))
        else
            echo -e "${YELLOW}⚠️${NC} $file - Sem título principal"
        fi

        # Verificar se o arquivo tem seção de visão geral
        if grep -q "## 📋 Visão Geral\|## 📋 Visão geral\|## Visão Geral\|## Visão geral" "$file"; then
            ((formatted_files++))
        else
            echo -e "${YELLOW}⚠️${NC} $file - Sem seção de visão geral"
        fi

    done <<< "$markdown_files"

    echo -e "${GREEN}✅${NC} $formatted_files de $total_files arquivos com formatação adequada"
}

# Função principal
main() {
    local total_broken_links=0
    local total_obsolete_files=0

    # Verificar estrutura de diretórios
    check_directory_structure
    echo ""

    # Verificar arquivos obsoletos
    check_obsolete_files
    echo ""

    # Verificar consistência de formatação
    check_formatting
    echo ""

    # Verificar links em todos os arquivos markdown
    echo -e "${BLUE}🔗 Verificando links markdown${NC}"
    echo "----------------------------------------"

    local markdown_files=$(find "$DOCS_DIR" -name "*.md" -type f)

    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            local broken_links=$(check_markdown_links "$file")
            total_broken_links=$((total_broken_links + broken_links))
            echo ""
        fi
    done <<< "$markdown_files"

    # Resumo final
    echo "=================================================="
    echo -e "${BLUE}📊 RESUMO DA VERIFICAÇÃO${NC}"
    echo "=================================================="

    if [[ $total_broken_links -eq 0 ]]; then
        echo -e "${GREEN}✅${NC} Nenhum link quebrado encontrado"
    else
        echo -e "${RED}❌${NC} $total_broken_links links quebrados encontrados"
    fi

    if [[ $total_obsolete_files -eq 0 ]]; then
        echo -e "${GREEN}✅${NC} Nenhum arquivo obsoleto detectado"
    else
        echo -e "${YELLOW}⚠️${NC} $total_obsolete_files possíveis arquivos obsoletos"
    fi

    echo ""
    echo -e "${BLUE}💡 DICAS DE MANUTENÇÃO:${NC}"
    echo "1. Execute este script regularmente (semanalmente)"
    echo "2. Mantenha os links atualizados quando mover arquivos"
    echo "3. Use o padrão de formatação estabelecido"
    echo "4. Consolide arquivos relacionados quando possível"
    echo ""

    # Retornar código de saída baseado nos problemas encontrados
    if [[ $total_broken_links -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Executar função principal
main "$@"
