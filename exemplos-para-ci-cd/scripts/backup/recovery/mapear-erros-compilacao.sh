#!/bin/bash

# Script para mapear todos os erros de compilação e criar plano de correção
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="$SCRIPT_DIR/mapeamento-erros-$(date +%Y%m%d-%H%M%S).log"

echo "🔍 MAPEAMENTO COMPLETO DE ERROS DE COMPILAÇÃO" | tee "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "Projeto: Conexão de Sorte Backend" | tee -a "$LOG_FILE"
echo "Ambiente: Produção (Java 21 + Spring Boot 3.5+)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Compilar e capturar todos os erros
echo "📊 Executando compilação completa..." | tee -a "$LOG_FILE"
./mvnw compile -q > /tmp/compile_output.log 2>&1 || true

# Contar total de erros
total_errors=$(grep -E "\[ERROR\]" /tmp/compile_output.log | grep -v "COMPILATION ERROR" | wc -l)
echo "Total de erros encontrados: $total_errors" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Categorizar erros por tipo
echo "📋 CATEGORIZAÇÃO DOS ERROS:" | tee -a "$LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"

# Erros de símbolo não encontrado
symbol_errors=$(grep -E "cannot find symbol" /tmp/compile_output.log | wc -l)
echo "1. Símbolos não encontrados: $symbol_errors" | tee -a "$LOG_FILE"

# Erros de pacote não existe
package_errors=$(grep -E "package .* does not exist" /tmp/compile_output.log | wc -l)
echo "2. Pacotes não existem: $package_errors" | tee -a "$LOG_FILE"

# Erros de import
import_errors=$(grep -E "cannot find symbol.*import" /tmp/compile_output.log | wc -l)
echo "3. Imports inválidos: $import_errors" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"

# Arquivos mais problemáticos
echo "📁 ARQUIVOS MAIS PROBLEMÁTICOS:" | tee -a "$LOG_FILE"
echo "===============================" | tee -a "$LOG_FILE"
grep -E "\[ERROR\].*\.java:" /tmp/compile_output.log | \
    sed 's/.*\/\([^/]*\.java\):.*/\1/' | \
    sort | uniq -c | sort -nr | head -10 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"

# Constantes mais referenciadas em erros
echo "🔧 CONSTANTES MAIS PROBLEMÁTICAS:" | tee -a "$LOG_FILE"
echo "==================================" | tee -a "$LOG_FILE"
grep -E "cannot find symbol.*variable" /tmp/compile_output.log | \
    sed 's/.*variable \([A-Z_]*\).*/\1/' | \
    sort | uniq -c | sort -nr | head -10 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"

# Classes de constantes referenciadas
echo "📦 CLASSES DE CONSTANTES PROBLEMÁTICAS:" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"
grep -E "cannot find symbol.*location: class" /tmp/compile_output.log | \
    sed 's/.*location: class \([A-Za-z.]*\).*/\1/' | \
    sort | uniq -c | sort -nr | head -10 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "📄 Log completo salvo em: $LOG_FILE" | tee -a "$LOG_FILE"
echo "📄 Output de compilação salvo em: /tmp/compile_output.log" | tee -a "$LOG_FILE"

# Criar arquivo de erros detalhados
echo "" | tee -a "$LOG_FILE"
echo "🔍 PRIMEIROS 50 ERROS DETALHADOS:" | tee -a "$LOG_FILE"
echo "==================================" | tee -a "$LOG_FILE"
grep -E "\[ERROR\]" /tmp/compile_output.log | grep -v "COMPILATION ERROR" | head -50 | tee -a "$LOG_FILE"

echo ""
echo "✅ Mapeamento concluído! Verifique o arquivo: $LOG_FILE"
