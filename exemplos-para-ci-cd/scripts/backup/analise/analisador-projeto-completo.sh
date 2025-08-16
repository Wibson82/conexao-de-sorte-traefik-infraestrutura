#!/bin/bash

# Script de Análise Completa do Projeto - Detecção de Conflitos e Redundâncias
# Autor: Sistema de Análise Automatizada
# Data: 2025-08-09

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretórios
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANALYSIS_DIR="$PROJECT_ROOT/scripts/analise"
REPORT_DIR="$ANALYSIS_DIR/relatorios"

# Criar diretórios necessários
mkdir -p "$REPORT_DIR"

echo -e "${CYAN}🔍 ANÁLISE COMPLETA DO PROJETO CONEXÃO DE SORTE${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"
}

# 1. ANÁLISE DE CLASSES DUPLICADAS/SIMILARES
log "1️⃣ Analisando classes duplicadas e similares..."

DUPLICATES_REPORT="$REPORT_DIR/classes-duplicadas.md"
cat > "$DUPLICATES_REPORT" << 'EOF'
# 📋 RELATÓRIO DE CLASSES DUPLICADAS E SIMILARES

## 🔍 Metodologia
- Busca por classes com nomes similares
- Identificação de sufixos problemáticos (*Consolidada, *Refatorado, etc.)
- Análise de pacotes incorretos
- Detecção de nomes em inglês vs português

## 📊 RESULTADOS DA ANÁLISE

EOF

# Buscar classes com sufixos problemáticos
echo "### 🚨 Classes com Sufixos Problemáticos" >> "$DUPLICATES_REPORT"
echo "" >> "$DUPLICATES_REPORT"

find "$PROJECT_ROOT/src" -name "*.java" -type f | while read -r file; do
    filename=$(basename "$file" .java)
    if [[ "$filename" =~ (Consolidada?|Refatorada?|Unificada?|Melhorada?|Nova?|Antiga?)$ ]]; then
        relative_path=$(echo "$file" | sed "s|$PROJECT_ROOT/||")
        echo "- **$filename** → \`$relative_path\`" >> "$DUPLICATES_REPORT"
    fi
done

# Buscar classes similares (mesmo nome base)
echo "" >> "$DUPLICATES_REPORT"
echo "### 🔄 Classes com Nomes Similares" >> "$DUPLICATES_REPORT"
echo "" >> "$DUPLICATES_REPORT"

# Buscar classes similares por nome base
find "$PROJECT_ROOT/src" -name "*.java" -type f | while read -r file; do
    filename=$(basename "$file" .java)
    # Remover sufixos comuns para agrupar
    base_name=$(echo "$filename" | sed -E 's/(Consolidada?|Refatorada?|Unificada?|Melhorada?|Nova?|Antiga?|Impl|Implementation|Service|Servico)$//')

    # Buscar outras classes com o mesmo nome base
    similar_files=$(find "$PROJECT_ROOT/src" -name "*${base_name}*.java" -type f | wc -l)
    if [[ $similar_files -gt 1 ]]; then
        echo "**Grupo: $base_name** ($similar_files classes)" >> "$DUPLICATES_REPORT"
        find "$PROJECT_ROOT/src" -name "*${base_name}*.java" -type f | while read -r similar_file; do
            relative_path=$(echo "$similar_file" | sed "s|$PROJECT_ROOT/||")
            echo "  - \`$relative_path\`" >> "$DUPLICATES_REPORT"
        done
        echo "" >> "$DUPLICATES_REPORT"
    fi
done | sort -u

# 2. ANÁLISE DE CONFIGURAÇÕES CONFLITANTES
log "2️⃣ Analisando configurações conflitantes..."

CONFIG_REPORT="$REPORT_DIR/configuracoes-conflitantes.md"
cat > "$CONFIG_REPORT" << 'EOF'
# ⚙️ RELATÓRIO DE CONFIGURAÇÕES CONFLITANTES

## 🔍 Análise de Arquivos de Configuração

EOF

# Analisar arquivos application*.yml
echo "### 📄 Arquivos de Configuração Spring" >> "$CONFIG_REPORT"
echo "" >> "$CONFIG_REPORT"

find "$PROJECT_ROOT/src/main/resources" -name "application*.yml" -o -name "application*.yaml" -o -name "application*.properties" | while read -r config_file; do
    echo "#### $(basename "$config_file")" >> "$CONFIG_REPORT"
    echo "" >> "$CONFIG_REPORT"
    echo "\`\`\`yaml" >> "$CONFIG_REPORT"
    head -20 "$config_file" >> "$CONFIG_REPORT"
    echo "\`\`\`" >> "$CONFIG_REPORT"
    echo "" >> "$CONFIG_REPORT"
done

# 3. ANÁLISE DE ESTRUTURA DDD
log "3️⃣ Analisando estrutura DDD..."

DDD_REPORT="$REPORT_DIR/estrutura-ddd.md"
cat > "$DDD_REPORT" << 'EOF'
# 🏗️ ANÁLISE DE ESTRUTURA DDD

## 📦 Estrutura de Pacotes Atual

EOF

# Gerar árvore de pacotes
echo "\`\`\`" >> "$DDD_REPORT"
find "$PROJECT_ROOT/src/main/java" -type d | sed "s|$PROJECT_ROOT/src/main/java||" | sort | sed 's|^/||' | while read -r dir; do
    if [[ -n "$dir" ]]; then
        level=$(echo "$dir" | tr -cd '/' | wc -c)
        indent=$(printf "%*s" $((level * 2)) "")
        echo "${indent}📁 $(basename "$dir")" >> "$DDD_REPORT"
    fi
done
echo "\`\`\`" >> "$DDD_REPORT"

# 4. ANÁLISE DE MÉTRICAS E CONFLITOS
log "4️⃣ Analisando métricas e conflitos..."

METRICS_REPORT="$REPORT_DIR/metricas-conflitos.md"
cat > "$METRICS_REPORT" << 'EOF'
# 📊 ANÁLISE DE MÉTRICAS E CONFLITOS

## 🔍 Busca por Registros de Métricas Duplicados

EOF

# Buscar registros de métricas
echo "### 📈 Registros de Métricas Encontrados" >> "$METRICS_REPORT"
echo "" >> "$METRICS_REPORT"

grep -r "meterRegistry\|MeterRegistry\|gauge\|counter\|timer" "$PROJECT_ROOT/src" --include="*.java" | \
    grep -E "(gauge|counter|timer|register)" | \
    head -50 >> "$METRICS_REPORT"

# 5. ANÁLISE DE BEANS SPRING
log "5️⃣ Analisando beans Spring..."

BEANS_REPORT="$REPORT_DIR/beans-spring.md"
cat > "$BEANS_REPORT" << 'EOF'
# 🫘 ANÁLISE DE BEANS SPRING

## 🔍 Beans Definidos no Projeto

EOF

# Buscar definições de beans
echo "### 🏭 Definições de @Bean" >> "$BEANS_REPORT"
echo "" >> "$BEANS_REPORT"

grep -r "@Bean" "$PROJECT_ROOT/src" --include="*.java" -A 2 | head -100 >> "$BEANS_REPORT"

log "✅ Análise completa concluída!"
echo ""
echo -e "${PURPLE}📋 RELATÓRIOS GERADOS:${NC}"
echo -e "   📄 Classes Duplicadas: ${REPORT_DIR}/classes-duplicadas.md"
echo -e "   ⚙️ Configurações: ${REPORT_DIR}/configuracoes-conflitantes.md"
echo -e "   🏗️ Estrutura DDD: ${REPORT_DIR}/estrutura-ddd.md"
echo -e "   📊 Métricas: ${REPORT_DIR}/metricas-conflitos.md"
echo -e "   🫘 Beans Spring: ${REPORT_DIR}/beans-spring.md"
echo ""
