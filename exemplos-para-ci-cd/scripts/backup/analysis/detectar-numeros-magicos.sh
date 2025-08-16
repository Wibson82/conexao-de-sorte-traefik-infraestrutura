#!/bin/bash

# Script para detectar números mágicos em código Java
# Parte do plano de consolidação de constantes

echo "🔍 DETECTANDO NÚMEROS MÁGICOS NO CÓDIGO JAVA"
echo "============================================="
echo

# Diretório de saída para relatórios
OUTPUT_DIR="analysis-reports"
mkdir -p "$OUTPUT_DIR"

# Arquivo de relatório
REPORT_FILE="$OUTPUT_DIR/numeros-magicos-$(date +%Y%m%d-%H%M%S).txt"

echo "📊 Iniciando análise em $(date)" > "$REPORT_FILE"
echo "Total de arquivos Java: $(find src/main/java -name '*.java' | wc -l)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Função para detectar números mágicos
detectar_numeros() {
    local pattern="$1"
    local description="$2"
    
    echo "🔍 Procurando: $description"
    echo "=== $description ===" >> "$REPORT_FILE"
    
    # Buscar padrão e contar ocorrências
    local count=$(grep -r -n "$pattern" src/main/java --include="*.java" | wc -l)
    echo "Total encontrado: $count" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [ $count -gt 0 ]; then
        grep -r -n "$pattern" src/main/java --include="*.java" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    echo "  ✓ Encontrados: $count"
}

# Detectar diferentes tipos de números mágicos
echo "🔍 NÚMEROS INTEIROS SUSPEITOS"
detectar_numeros "\b[0-9]{2,}\b" "Números inteiros com 2+ dígitos"

echo "🔍 NÚMEROS DECIMAIS"
detectar_numeros "\b[0-9]+\.[0-9]+\b" "Números decimais"

echo "🔍 NÚMEROS NEGATIVOS"
detectar_numeros "\-[0-9]+" "Números negativos"

echo "🔍 TIMEOUTS E DELAYS COMUNS"
detectar_numeros "\b(1000|2000|3000|5000|10000|30000|60000)\b" "Timeouts comuns (ms)"

echo "🔍 TAMANHOS DE BUFFER/CACHE"
detectar_numeros "\b(16|32|64|128|256|512|1024|2048)\b" "Tamanhos de buffer/cache"

echo "🔍 CÓDIGOS HTTP"
detectar_numeros "\b(200|201|400|401|403|404|500|502|503)\b" "Códigos de status HTTP"

echo "🔍 PORTAS COMUNS"
detectar_numeros "\b(80|443|8080|8443|3000|3306|5432|6379)\b" "Portas de rede comuns"

echo "🔍 PERCENTUAIS"
detectar_numeros "\b(10|20|25|50|75|90|95|99)\b" "Valores percentuais comuns"

# Detectar strings hardcoded suspeitas
echo "🔍 STRINGS HARDCODED"
echo "=== STRINGS HARDCODED ===" >> "$REPORT_FILE"

# URLs e endpoints
echo "🔍 URLs e Endpoints"
detectar_numeros "\"https?://[^\"]*\"" "URLs hardcoded"
detectar_numeros "\"/[a-zA-Z0-9/_-]*\"" "Endpoints/paths hardcoded"

# Mensagens de erro
echo "🔍 Mensagens de Erro"
detectar_numeros "\"[Ee]rro[^\"]*\"" "Mensagens de erro"
detectar_numeros "\"[Ff]alha[^\"]*\"" "Mensagens de falha"

# Configurações
echo "🔍 Configurações"
detectar_numeros "\"[a-zA-Z0-9._-]*\.(properties|yml|yaml|xml)\"" "Nomes de arquivos de configuração"

# Detectar constantes já existentes para evitar duplicação
echo "🔍 CONSTANTES EXISTENTES"
echo "=== CONSTANTES EXISTENTES ===" >> "$REPORT_FILE"
echo "🔍 Classes de Constantes Existentes"
find src/main/java -name "*Constante*.java" -o -name "*Constant*.java" | while read file; do
    echo "Arquivo: $file" >> "$REPORT_FILE"
    grep -n "public static final" "$file" | head -10 >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
done

# Estatísticas finais
echo "" >> "$REPORT_FILE"
echo "=== ESTATÍSTICAS FINAIS ===" >> "$REPORT_FILE"
echo "Análise concluída em: $(date)" >> "$REPORT_FILE"
echo "Relatório salvo em: $REPORT_FILE" >> "$REPORT_FILE"

echo ""
echo "✅ Análise concluída!"
echo "📄 Relatório salvo em: $REPORT_FILE"
echo "📊 Resumo:"
echo "   - Total de arquivos analisados: $(find src/main/java -name '*.java' | wc -l)"
echo "   - Relatório detalhado disponível no arquivo acima"
echo ""
echo "🔍 Para visualizar o relatório:"
echo "   cat $REPORT_FILE"
echo ""
echo "📋 Próximos passos:"
echo "   1. Revisar o relatório gerado"
echo "   2. Priorizar constantes por frequência de uso"
echo "   3. Criar estrutura de classes de constantes"
echo "   4. Iniciar refatoração incremental"