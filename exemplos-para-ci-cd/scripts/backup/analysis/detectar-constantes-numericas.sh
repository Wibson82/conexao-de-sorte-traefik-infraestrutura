#!/bin/bash

# Script melhorado para detectar constantes numéricas específicas
# Foca em números que realmente são constantes candidatas

echo "🔍 DETECTANDO CONSTANTES NUMÉRICAS ESPECÍFICAS"
echo "============================================="
echo

OUTPUT_DIR="analysis-reports"
mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/constantes-numericas-$(date +%Y%m%d-%H%M%S).txt"

echo "📊 Análise de Constantes Numéricas - $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Função para buscar padrões específicos
buscar_padrao() {
    local pattern="$1"
    local description="$2"
    local context_lines="${3:-0}"
    
    echo "🔍 $description"
    echo "=== $description ===" >> "$REPORT_FILE"
    
    if [ $context_lines -gt 0 ]; then
        grep -r -n -A$context_lines -B$context_lines "$pattern" src/main/java --include="*.java" >> "$REPORT_FILE" 2>/dev/null
    else
        grep -r -n "$pattern" src/main/java --include="*.java" >> "$REPORT_FILE" 2>/dev/null
    fi
    
    local count=$(grep -r -c "$pattern" src/main/java --include="*.java" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
    echo "Total encontrado: $count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "  ✓ Encontrados: $count"
}

# Buscar números em declarações de constantes
echo "🔍 CONSTANTES DECLARADAS"
buscar_padrao "static final.*= [0-9]+" "Constantes static final com números"
buscar_padrao "static final.*= [0-9]+L" "Constantes long"
buscar_padrao "static final.*= [0-9]+\." "Constantes decimais"

# Buscar números específicos comuns
echo "🔍 NÚMEROS ESPECÍFICOS COMUNS"
buscar_padrao "\b100\b" "Número 100"
buscar_padrao "\b200\b" "Número 200"
buscar_padrao "\b500\b" "Número 500"
buscar_padrao "\b1000\b" "Número 1000"
buscar_padrao "\b5000\b" "Número 5000"
buscar_padrao "\b10000\b" "Número 10000"

# Buscar timeouts e delays
echo "🔍 TIMEOUTS E DELAYS"
buscar_padrao "timeout.*[0-9]+" "Timeouts"
buscar_padrao "delay.*[0-9]+" "Delays"
buscar_padrao "sleep.*[0-9]+" "Sleep"
buscar_padrao "wait.*[0-9]+" "Wait"

# Buscar tamanhos e limites
echo "🔍 TAMANHOS E LIMITES"
buscar_padrao "size.*[0-9]+" "Tamanhos"
buscar_padrao "limit.*[0-9]+" "Limites"
buscar_padrao "max.*[0-9]+" "Máximos"
buscar_padrao "min.*[0-9]+" "Mínimos"

# Buscar códigos de status
echo "🔍 CÓDIGOS DE STATUS"
buscar_padrao "HttpStatus\.[A-Z_]*" "HttpStatus enums"
buscar_padrao "status.*[0-9]{3}" "Códigos de status numéricos"

# Buscar configurações de rede
echo "🔍 CONFIGURAÇÕES DE REDE"
buscar_padrao "port.*[0-9]+" "Portas"
buscar_padrao ":[0-9]{2,5}" "Portas em URLs"

# Buscar números em anotações
echo "🔍 NÚMEROS EM ANOTAÇÕES"
buscar_padrao "@.*([0-9]+)" "Números em anotações"

# Buscar BigDecimal com números
echo "🔍 BIGDECIMAL E VALORES MONETÁRIOS"
buscar_padrao "BigDecimal.*[0-9]+" "BigDecimal com números"
buscar_padrao "new BigDecimal\(\"[0-9.]+\"\)" "BigDecimal construtor"

# Buscar arrays e coleções com tamanhos
echo "🔍 ARRAYS E COLEÇÕES"
buscar_padrao "new.*\[[0-9]+\]" "Arrays com tamanho fixo"
buscar_padrao "capacity.*[0-9]+" "Capacidade de coleções"

# Buscar regex patterns com números
echo "🔍 REGEX PATTERNS"
buscar_padrao "\\{[0-9]+" "Quantificadores em regex"
buscar_padrao "\\{[0-9]+,[0-9]+\\}" "Ranges em regex"

echo "" >> "$REPORT_FILE"
echo "=== ANÁLISE CONCLUÍDA ===" >> "$REPORT_FILE"
echo "Data: $(date)" >> "$REPORT_FILE"
echo "Arquivo: $REPORT_FILE" >> "$REPORT_FILE"

echo ""
echo "✅ Análise de constantes numéricas concluída!"
echo "📄 Relatório: $REPORT_FILE"
echo ""
echo "📋 Para revisar:"
echo "   cat $REPORT_FILE | less"