#!/bin/bash

# Script para gerar relatório de alertas de compilação
# Autor: Sistema Automatizado
# Data: $(date '+%Y-%m-%d')

set -e

echo "🔍 Iniciando geração do relatório de alertas..."

# Diretório de trabalho
PROJECT_DIR="/Volumes/NVME/Projetos/conexao-de-sorte-backend"
REPORT_FILE="$PROJECT_DIR/docs/RELATORIO-ALERTAS.md"
TEMP_LOG="/tmp/compilation-alerts.log"

# Limpar arquivo temporário
> "$TEMP_LOG"

echo "📋 Executando compilação com análise de código..."

# Executar compilação e capturar alertas
cd "$PROJECT_DIR"
./mvnw clean compile checkstyle:check pmd:pmd spotbugs:spotbugs -Ddependency-check.skip=true 2>&1 | tee "$TEMP_LOG"

echo "📊 Processando alertas encontrados..."

# Criar relatório
cat > "$REPORT_FILE" << 'EOF'
# 📋 RELATÓRIO DE ALERTAS - CONEXÃO DE SORTE

**Data de Geração:** $(date '+%d/%m/%Y às %H:%M:%S')
**Versão:** Java 21 + Spring Boot 3.5.4
**Perfil:** Produção

## 📈 Resumo Executivo

Este relatório apresenta todos os alertas e warnings detectados durante a compilação do projeto, organizados por categoria e criticidade.

---

EOF

# Processar alertas por categoria
echo "🔄 Categorizando alertas..."

# Função para extrair alertas por tipo
extract_alerts() {
    local alert_type="$1"
    local description="$2"
    local count=$(grep -c "\[$alert_type\]" "$TEMP_LOG" 2>/dev/null || echo "0")
    
    if [ "$count" -gt 0 ]; then
        echo "" >> "$REPORT_FILE"
        echo "### 🚨 $description ($count ocorrências)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        # Extrair e formatar alertas
        grep "\[$alert_type\]" "$TEMP_LOG" | while IFS= read -r line; do
            # Extrair arquivo, linha e descrição
            file_path=$(echo "$line" | sed -n 's/.*\/\([^/]*\.java\):\([0-9]*\):\([0-9]*\):.*/\1/p')
            line_num=$(echo "$line" | sed -n 's/.*\/[^/]*\.java:\([0-9]*\):\([0-9]*\):.*/\1/p')
            message=$(echo "$line" | sed -n 's/.*\] \(.*\) \[.*/\1/p')
            
            if [ -n "$file_path" ] && [ -n "$line_num" ]; then
                echo "- **$file_path** → Linha $line_num: $message" >> "$REPORT_FILE"
            fi
        done
        
        echo "" >> "$REPORT_FILE"
        echo "---" >> "$REPORT_FILE"
    fi
}

# Categorizar alertas por ordem de criticidade
extract_alerts "ParameterNumber" "Excesso de Parâmetros"
extract_alerts "MagicNumber" "Números Mágicos"
extract_alerts "NeedBraces" "Estruturas sem Chaves"
extract_alerts "OperatorWrap" "Quebra de Linha em Operadores"
extract_alerts "LeftCurly" "Formatação de Chaves"
extract_alerts "UnusedImports" "Importações Não Utilizadas"

# Adicionar seção de estatísticas
echo "" >> "$REPORT_FILE"
echo "## 📊 Estatísticas Gerais" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Contar total de alertas
total_warnings=$(grep -c "\[WARN\]" "$TEMP_LOG" 2>/dev/null || echo "0")
total_checkstyle=$(grep -c "\[.*\]" "$TEMP_LOG" | grep -v "\[INFO\]" | grep -v "\[WARN\]" || echo "0")

echo "| Categoria | Quantidade |" >> "$REPORT_FILE"
echo "|-----------|------------|" >> "$REPORT_FILE"
echo "| Total de Warnings | $total_warnings |" >> "$REPORT_FILE"
echo "| Excesso de Parâmetros | $(grep -c "\[ParameterNumber\]" "$TEMP_LOG" 2>/dev/null || echo "0") |" >> "$REPORT_FILE"
echo "| Números Mágicos | $(grep -c "\[MagicNumber\]" "$TEMP_LOG" 2>/dev/null || echo "0") |" >> "$REPORT_FILE"
echo "| Estruturas sem Chaves | $(grep -c "\[NeedBraces\]" "$TEMP_LOG" 2>/dev/null || echo "0") |" >> "$REPORT_FILE"
echo "| Quebra de Linha | $(grep -c "\[OperatorWrap\]" "$TEMP_LOG" 2>/dev/null || echo "0") |" >> "$REPORT_FILE"
echo "| Formatação de Chaves | $(grep -c "\[LeftCurly\]" "$TEMP_LOG" 2>/dev/null || echo "0") |" >> "$REPORT_FILE"
echo "| Importações Não Utilizadas | $(grep -c "\[UnusedImports\]" "$TEMP_LOG" 2>/dev/null || echo "0") |" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "## 🎯 Recomendações de Priorização" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **Alta Prioridade:** Excesso de Parâmetros e Números Mágicos (impacto na manutenibilidade)" >> "$REPORT_FILE"
echo "2. **Média Prioridade:** Estruturas sem Chaves (impacto na legibilidade e segurança)" >> "$REPORT_FILE"
echo "3. **Baixa Prioridade:** Formatação e Importações (impacto estético)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "*Relatório gerado automaticamente pelo sistema de análise de código.*" >> "$REPORT_FILE"

# Limpar arquivo temporário
rm -f "$TEMP_LOG"

echo "✅ Relatório gerado com sucesso em: $REPORT_FILE"
echo "📊 Total de alertas processados: $total_warnings"