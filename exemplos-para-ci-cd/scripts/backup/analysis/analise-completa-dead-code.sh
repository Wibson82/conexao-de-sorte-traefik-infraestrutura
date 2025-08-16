#!/bin/bash

# Script para análise completa de dead code e hardcoded values
# Parte do plano de limpeza de código

echo "🔍 ANÁLISE COMPLETA DE DEAD CODE E HARDCODED VALUES"
echo "=================================================="
echo

# Diretório de saída para relatórios
OUTPUT_DIR="analysis-reports"
mkdir -p "$OUTPUT_DIR"

# Arquivo de relatório
REPORT_FILE="$OUTPUT_DIR/analise-completa-$(date +%Y%m%d-%H%M%S).md"

echo "# Análise Completa de Dead Code e Hardcoded Values" > "$REPORT_FILE"
echo "**Data:** $(date)" >> "$REPORT_FILE"
echo "**Total de arquivos Java:** $(find src/main/java -name '*.java' | wc -l)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Função para adicionar seção ao relatório
add_section() {
    local title="$1"
    local content="$2"
    echo "## $title" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "$content" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 1. DEAD CODE - Métodos privados nunca chamados
echo "🔍 Analisando métodos privados não utilizados..."
add_section "1. MÉTODOS PRIVADOS NÃO UTILIZADOS" "### Análise de métodos privados que podem não estar sendo utilizados:"

# Buscar métodos privados
private_methods=$(grep -r "private.*(" src/main/java --include="*.java" | grep -v "private final\|private static final\|private.*=")

echo "### Métodos privados encontrados:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$private_methods" | head -20 >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 2. CAMPOS PRIVADOS NÃO UTILIZADOS
echo "🔍 Analisando campos privados não utilizados..."
add_section "2. CAMPOS PRIVADOS NÃO UTILIZADOS" "### Campos privados que podem não estar sendo utilizados:"

# Buscar campos privados (excluindo final)
private_fields=$(grep -r "private.*;" src/main/java --include="*.java" | grep -v "private final\|private static final" | head -20)

echo "### Campos privados encontrados:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$private_fields" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 3. STRINGS LITERAIS DUPLICADAS
echo "🔍 Analisando strings literais duplicadas..."
add_section "3. STRINGS LITERAIS DUPLICADAS" "### Strings que aparecem múltiplas vezes no código:"

# Buscar strings comuns
common_strings=$(grep -rho '"[^"]\{10,\}"' src/main/java --include="*.java" | sort | uniq -c | sort -nr | head -20)

echo "### Top 20 strings mais utilizadas:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$common_strings" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 4. NÚMEROS MÁGICOS
echo "🔍 Analisando números mágicos..."
add_section "4. NÚMEROS MÁGICOS" "### Números hardcoded que deveriam ser constantes:"

# Buscar números específicos
magic_numbers=$(grep -rn "\b[0-9]\{2,\}\b" src/main/java --include="*.java" | grep -v "final\|static" | head -20)

echo "### Números mágicos encontrados:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$magic_numbers" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 5. ENDPOINTS HARDCODED
echo "🔍 Analisando endpoints hardcoded..."
add_section "5. ENDPOINTS HARDCODED" "### Endpoints que poderiam ser constantes:"

# Buscar endpoints
endpoints=$(grep -rn '@.*Mapping.*"/' src/main/java --include="*.java" | head -20)

echo "### Endpoints encontrados:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$endpoints" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 6. MENSAGENS DE ERRO DUPLICADAS
echo "🔍 Analisando mensagens de erro duplicadas..."
add_section "6. MENSAGENS DE ERRO DUPLICADAS" "### Mensagens de erro que aparecem múltiplas vezes:"

# Buscar mensagens de erro
error_messages=$(grep -rho '"[Ee]rro[^"]*"' src/main/java --include="*.java" | sort | uniq -c | sort -nr | head -10)

echo "### Mensagens de erro mais comuns:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$error_messages" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 7. IMPORTS NÃO UTILIZADOS (análise básica)
echo "🔍 Analisando imports potencialmente não utilizados..."
add_section "7. IMPORTS POTENCIALMENTE NÃO UTILIZADOS" "### Imports que podem não estar sendo utilizados:"

# Buscar imports suspeitos (análise básica)
unused_imports=$(find src/main/java -name "*.java" -exec grep -l "import.*\*" {} \; | head -10)

echo "### Arquivos com imports com wildcard (*):" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$unused_imports" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 8. CLASSES COM MUITAS LINHAS
echo "🔍 Analisando classes muito grandes..."
add_section "8. CLASSES MUITO GRANDES (>500 linhas)" "### Classes que podem precisar de refatoração:"

# Buscar classes grandes
large_classes=$(find src/main/java -name "*.java" -exec wc -l {} \; | sort -nr | head -10)

echo "### Classes com mais linhas:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$large_classes" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 9. MÉTODOS COM MUITOS PARÂMETROS
echo "🔍 Analisando métodos com muitos parâmetros..."
add_section "9. MÉTODOS COM MUITOS PARÂMETROS" "### Métodos que podem precisar de refatoração:"

# Buscar métodos com muitos parâmetros (análise básica)
complex_methods=$(grep -rn "([^)]*,[^)]*,[^)]*,[^)]*,[^)]*," src/main/java --include="*.java" | head -10)

echo "### Métodos com 5+ parâmetros:" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "$complex_methods" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 10. RESUMO E RECOMENDAÇÕES
add_section "10. RESUMO E RECOMENDAÇÕES" "### Priorização por impacto:"

echo "#### CRÍTICO (Impacta funcionalidade ou segurança):" >> "$REPORT_FILE"
echo "- [ ] Revisar strings de erro duplicadas" >> "$REPORT_FILE"
echo "- [ ] Consolidar endpoints hardcoded" >> "$REPORT_FILE"
echo "- [ ] Verificar números mágicos em validações" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "#### ALTO (Impacta manutenibilidade significativamente):" >> "$REPORT_FILE"
echo "- [ ] Refatorar classes muito grandes (>500 linhas)" >> "$REPORT_FILE"
echo "- [ ] Simplificar métodos com muitos parâmetros" >> "$REPORT_FILE"
echo "- [ ] Remover campos privados não utilizados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "#### MÉDIO (Melhoria de qualidade de código):" >> "$REPORT_FILE"
echo "- [ ] Remover métodos privados não utilizados" >> "$REPORT_FILE"
echo "- [ ] Limpar imports não utilizados" >> "$REPORT_FILE"
echo "- [ ] Criar constantes para strings duplicadas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "#### BAIXO (Limpeza cosmética):" >> "$REPORT_FILE"
echo "- [ ] Organizar estrutura de pacotes" >> "$REPORT_FILE"
echo "- [ ] Padronizar nomenclatura" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Estatísticas finais
echo "### Estatísticas Finais:" >> "$REPORT_FILE"
echo "- **Total de arquivos Java:** $(find src/main/java -name '*.java' | wc -l)" >> "$REPORT_FILE"
echo "- **Linhas de código total:** $(find src/main/java -name '*.java' -exec wc -l {} \; | awk '{sum += $1} END {print sum}')" >> "$REPORT_FILE"
echo "- **Data da análise:** $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "✅ Análise concluída!"
echo "📄 Relatório salvo em: $REPORT_FILE"
echo ""
echo "🔍 Para visualizar o relatório:"
echo "   cat $REPORT_FILE"
echo ""
echo "📋 Próximos passos:"
echo "   1. Revisar o relatório gerado"
echo "   2. Priorizar correções por impacto"
echo "   3. Criar issues para cada categoria"
echo "   4. Iniciar refatoração incremental"
