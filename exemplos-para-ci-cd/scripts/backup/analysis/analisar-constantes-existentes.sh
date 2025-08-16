#!/bin/bash

# Script para analisar constantes existentes nos arquivos de constantes
# Parte do plano de consolidação de constantes

echo "📊 Análise de Constantes Existentes - $(date)"
echo "================================================"

# Diretório de relatórios
REPORT_DIR="analysis-reports"
mkdir -p "$REPORT_DIR"

# Arquivo de relatório
REPORT_FILE="$REPORT_DIR/constantes-existentes-$(date +%Y%m%d-%H%M%S).txt"

echo "📊 Análise de Constantes Existentes - $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Encontrar todos os arquivos de constantes
echo "=== Arquivos de Constantes Identificados ===" >> "$REPORT_FILE"
find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" | while read file; do
    echo "📁 $file" >> "$REPORT_FILE"
done
echo "" >> "$REPORT_FILE"

# Analisar cada arquivo de constantes
echo "=== Análise Detalhada por Arquivo ===" >> "$REPORT_FILE"
find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" | while read file; do
    echo "" >> "$REPORT_FILE"
    echo "📄 Arquivo: $file" >> "$REPORT_FILE"
    echo "$(printf '=%.0s' {1..80})" >> "$REPORT_FILE"
    
    # Contar constantes por tipo
    echo "📊 Estatísticas:" >> "$REPORT_FILE"
    
    # Constantes static final
    static_final_count=$(grep -c "static final" "$file" 2>/dev/null || echo "0")
    echo "   • static final: $static_final_count" >> "$REPORT_FILE"
    
    # Constantes String
    string_count=$(grep -c "static final String" "$file" 2>/dev/null || echo "0")
    echo "   • String: $string_count" >> "$REPORT_FILE"
    
    # Constantes int
    int_count=$(grep -c "static final int" "$file" 2>/dev/null || echo "0")
    echo "   • int: $int_count" >> "$REPORT_FILE"
    
    # Constantes long
    long_count=$(grep -c "static final long" "$file" 2>/dev/null || echo "0")
    echo "   • long: $long_count" >> "$REPORT_FILE"
    
    # Constantes double
    double_count=$(grep -c "static final double" "$file" 2>/dev/null || echo "0")
    echo "   • double: $double_count" >> "$REPORT_FILE"
    
    # Classes internas
    inner_class_count=$(grep -c "public static.*class" "$file" 2>/dev/null || echo "0")
    echo "   • Classes internas: $inner_class_count" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    echo "🏷️ Classes/Seções internas:" >> "$REPORT_FILE"
    grep "public static.*class" "$file" 2>/dev/null | sed 's/^/   • /' >> "$REPORT_FILE" || echo "   • Nenhuma classe interna encontrada" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    echo "📝 Exemplos de constantes:" >> "$REPORT_FILE"
    grep "static final" "$file" 2>/dev/null | head -10 | sed 's/^/   /' >> "$REPORT_FILE" || echo "   • Nenhuma constante encontrada" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
done

# Resumo geral
echo "" >> "$REPORT_FILE"
echo "=== Resumo Geral ===" >> "$REPORT_FILE"

total_files=$(find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" | wc -l)
echo "📁 Total de arquivos de constantes: $total_files" >> "$REPORT_FILE"

total_constants=$(find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" -exec grep -c "static final" {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
echo "🔢 Total de constantes static final: ${total_constants:-0}" >> "$REPORT_FILE"

# Identificar duplicações potenciais
echo "" >> "$REPORT_FILE"
echo "=== Análise de Duplicações Potenciais ===" >> "$REPORT_FILE"
echo "🔍 Valores que aparecem em múltiplos arquivos:" >> "$REPORT_FILE"

# Buscar valores numéricos comuns
for value in 100 200 500 1000 5000 10000; do
    count=$(find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" -exec grep -l "= $value" {} \; 2>/dev/null | wc -l)
    if [ "$count" -gt 1 ]; then
        echo "   • Valor $value encontrado em $count arquivos:" >> "$REPORT_FILE"
        find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" -exec grep -l "= $value" {} \; 2>/dev/null | sed 's/^/     - /' >> "$REPORT_FILE"
    fi
done

# Buscar strings comuns
echo "" >> "$REPORT_FILE"
echo "🔍 Strings que podem estar duplicadas:" >> "$REPORT_FILE"
for string in "erro" "sucesso" "invalid" "required" "max" "min"; do
    count=$(find src/main/java -name "*Constante*.java" -o -name "*Constants*.java" -exec grep -il "$string" {} \; 2>/dev/null | wc -l)
    if [ "$count" -gt 1 ]; then
        echo "   • Termo '$string' encontrado em $count arquivos" >> "$REPORT_FILE"
    fi
done

echo "" >> "$REPORT_FILE"
echo "✅ Análise concluída. Relatório salvo em: $REPORT_FILE"
echo "✅ Análise concluída. Relatório salvo em: $REPORT_FILE"

# Mostrar resumo no terminal
echo "📊 Resumo:"
echo "   • Arquivos de constantes: $total_files"
echo "   • Total de constantes: ${total_constants:-0}"
echo "   • Relatório: $REPORT_FILE"