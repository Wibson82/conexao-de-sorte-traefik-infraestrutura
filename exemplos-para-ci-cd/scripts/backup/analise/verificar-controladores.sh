#!/bin/bash

# Script para verificar controladores WebFlux
# Autor: Sistema de Análise
# Data: 2025-08-09

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_FILE="$PROJECT_ROOT/scripts/analise/relatorios/controladores-webflux.md"

echo "🔍 ANÁLISE DE CONTROLADORES WEBFLUX"
echo "=================================="

# Criar relatório
cat > "$REPORT_FILE" << 'EOF'
# 🎯 ANÁLISE DE CONTROLADORES WEBFLUX

## 🔍 Controladores Encontrados

EOF

# Buscar todos os controladores
echo "📋 Buscando controladores..."
CONTROLADORES=$(find "$PROJECT_ROOT/src/main/java" -name "*.java" -type f -exec grep -l "@RestController\|@Controller" {} \;)

echo "### 📊 Estatísticas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **Total de controladores:** $(echo "$CONTROLADORES" | wc -l)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 📋 Lista de Controladores" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Analisar cada controlador
while IFS= read -r controller_file; do
    if [[ -n "$controller_file" ]]; then
        filename=$(basename "$controller_file" .java)
        relative_path=$(echo "$controller_file" | sed "s|$PROJECT_ROOT/||")
        
        # Verificar anotações
        has_rest_controller=$(grep -c "@RestController" "$controller_file" || echo "0")
        has_controller=$(grep -c "@Controller" "$controller_file" || echo "0")
        has_request_mapping=$(grep -c "@RequestMapping" "$controller_file" || echo "0")
        
        # Extrair RequestMapping
        request_mapping=$(grep "@RequestMapping" "$controller_file" | head -1 | sed 's/.*@RequestMapping[^"]*"\([^"]*\)".*/\1/' || echo "N/A")
        
        echo "#### $filename" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "- **Arquivo:** \`$relative_path\`" >> "$REPORT_FILE"
        echo "- **@RestController:** $has_rest_controller" >> "$REPORT_FILE"
        echo "- **@Controller:** $has_controller" >> "$REPORT_FILE"
        echo "- **@RequestMapping:** $has_request_mapping" >> "$REPORT_FILE"
        echo "- **Base Path:** \`$request_mapping\`" >> "$REPORT_FILE"
        
        # Verificar endpoints
        endpoints=$(grep -c -E "@(Get|Post|Put|Delete|Patch)Mapping" "$controller_file" 2>/dev/null || echo "0")
        echo "- **Endpoints:** $endpoints" >> "$REPORT_FILE"

        # Listar endpoints se existirem
        if [ "$endpoints" -gt 0 ]; then
            echo "- **Métodos:**" >> "$REPORT_FILE"
            grep -E "@(Get|Post|Put|Delete|Patch)Mapping" "$controller_file" 2>/dev/null | head -5 | while read -r endpoint; do
                method=$(echo "$endpoint" | sed 's/.*@\([A-Za-z]*\)Mapping.*/\1/' 2>/dev/null || echo "Unknown")
                echo "  - **$method**" >> "$REPORT_FILE"
            done
        fi
        
        echo "" >> "$REPORT_FILE"
    fi
done <<< "$CONTROLADORES"

# Verificar problemas comuns
echo "### 🚨 Problemas Identificados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Verificar controladores sem @RequestMapping
controllers_without_mapping=$(find "$PROJECT_ROOT/src/main/java" -name "*.java" -type f -exec grep -l "@RestController\|@Controller" {} \; | xargs grep -L "@RequestMapping" 2>/dev/null | wc -l)
if [[ "$controllers_without_mapping" -gt 0 ]]; then
    echo "#### ⚠️ Controladores sem @RequestMapping" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **Quantidade:** $controllers_without_mapping" >> "$REPORT_FILE"
    echo "- **Problema:** Controladores podem não estar sendo mapeados corretamente" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Verificar controladores em pacotes incorretos
controllers_wrong_package=$(find "$PROJECT_ROOT/src/main/java" -name "*Controller*.java" -type f | grep -v "/controle/\|/controlador/" 2>/dev/null | wc -l)
if [[ "$controllers_wrong_package" -gt 0 ]]; then
    echo "#### 📦 Controladores em Pacotes Incorretos" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **Quantidade:** $controllers_wrong_package" >> "$REPORT_FILE"
    echo "- **Problema:** Controladores fora dos pacotes padrão (controle/controlador)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Verificar conflitos de anotação
controllers_with_both=$(find "$PROJECT_ROOT/src/main/java" -name "*.java" -type f -exec grep -l "@RestController" {} \; | xargs grep -l "@Controller" 2>/dev/null | wc -l)
if [[ "$controllers_with_both" -gt 0 ]]; then
    echo "#### 🔄 Conflitos de Anotação" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **Quantidade:** $controllers_with_both" >> "$REPORT_FILE"
    echo "- **Problema:** Controladores com @Controller e @RestController" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

echo "✅ Análise de controladores concluída!"
echo "📄 Relatório salvo em: $REPORT_FILE"
