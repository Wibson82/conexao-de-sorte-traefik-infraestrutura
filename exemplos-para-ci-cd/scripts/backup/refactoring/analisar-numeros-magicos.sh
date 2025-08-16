#!/bin/bash

# =============================================================================
# SCRIPT DE ANÁLISE SISTEMÁTICA DE NÚMEROS MÁGICOS
# =============================================================================
# 
# Objetivo: Analisar e categorizar todos os números mágicos no projeto
# para facilitar a refatoração sistemática por prioridade.
#
# Uso: ./scripts/refactoring/analisar-numeros-magicos.sh
# =============================================================================

set -e

# Configurações
PROJETO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELATORIO_DIR="$PROJETO_ROOT/docs/refactoring/analise"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RELATORIO_ARQUIVO="$RELATORIO_DIR/analise_numeros_magicos_$TIMESTAMP.md"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Criar diretório de relatórios se não existir
mkdir -p "$RELATORIO_DIR"

echo -e "${BLUE}🔍 INICIANDO ANÁLISE SISTEMÁTICA DE NÚMEROS MÁGICOS${NC}"
echo "Projeto: $PROJETO_ROOT"
echo "Relatório: $RELATORIO_ARQUIVO"
echo ""

# Inicializar relatório
cat > "$RELATORIO_ARQUIVO" << 'EOF'
# 📊 ANÁLISE SISTEMÁTICA DE NÚMEROS MÁGICOS

## 🎯 RESUMO EXECUTIVO

**Data da Análise**: $(date)
**Diretório Analisado**: src/main/java
**Critério**: Números com 2+ dígitos ou decimais

## 📈 ESTATÍSTICAS GERAIS

EOF

# Função para contar ocorrências de um padrão
contar_ocorrencias() {
    local padrao="$1"
    local descricao="$2"
    local count=$(grep -r -E "$padrao" "$PROJETO_ROOT/src/main/java" --include="*.java" | wc -l)
    echo "$count"
}

# Função para listar ocorrências detalhadas
listar_ocorrencias() {
    local padrao="$1"
    local descricao="$2"
    local limite="${3:-20}"
    
    echo -e "${YELLOW}🔍 Analisando: $descricao${NC}"
    
    # Contar total
    local total=$(contar_ocorrencias "$padrao" "$descricao")
    echo "Total encontrado: $total"
    
    # Adicionar ao relatório
    echo "" >> "$RELATORIO_ARQUIVO"
    echo "### $descricao" >> "$RELATORIO_ARQUIVO"
    echo "**Total de ocorrências**: $total" >> "$RELATORIO_ARQUIVO"
    echo "" >> "$RELATORIO_ARQUIVO"
    
    if [ $total -gt 0 ]; then
        echo "| Arquivo | Linha | Número | Contexto |" >> "$RELATORIO_ARQUIVO"
        echo "|---------|-------|--------|----------|" >> "$RELATORIO_ARQUIVO"
        
        # Listar ocorrências com contexto
        grep -r -n -E "$padrao" "$PROJETO_ROOT/src/main/java" --include="*.java" | \
        head -n $limite | \
        while IFS=: read -r arquivo linha contexto; do
            # Extrair apenas o nome do arquivo (sem path completo)
            arquivo_nome=$(basename "$arquivo")
            # Extrair o número do contexto
            numero=$(echo "$contexto" | grep -oE "$padrao" | head -1)
            # Limitar contexto a 50 caracteres
            contexto_limitado=$(echo "$contexto" | cut -c1-50 | sed 's/|/\\|/g')
            
            echo "| $arquivo_nome | $linha | \`$numero\` | $contexto_limitado... |" >> "$RELATORIO_ARQUIVO"
        done
        
        if [ $total -gt $limite ]; then
            echo "| ... | ... | ... | *($((total - limite)) ocorrências adicionais)* |" >> "$RELATORIO_ARQUIVO"
        fi
    fi
    
    echo ""
}

# Função para analisar frequência de números específicos
analisar_frequencia_numeros() {
    echo -e "${BLUE}📊 ANÁLISE DE FREQUÊNCIA DE NÚMEROS ESPECÍFICOS${NC}"
    
    echo "" >> "$RELATORIO_ARQUIVO"
    echo "## 📊 FREQUÊNCIA DE NÚMEROS ESPECÍFICOS" >> "$RELATORIO_ARQUIVO"
    echo "" >> "$RELATORIO_ARQUIVO"
    echo "| Número | Ocorrências | Categoria Provável |" >> "$RELATORIO_ARQUIVO"
    echo "|--------|-------------|-------------------|" >> "$RELATORIO_ARQUIVO"
    
    # Lista de números para analisar especificamente
    local numeros_interesse=(
        "30" "60" "300" "600" "1200" "1800" "3600" "86400" "604800" "31536000"
        "1024" "256" "128" "64" "32" "16" "2048"
        "500" "429" "401" "403" "404" "200"
        "11" "12" "255" "150" "100" "50"
        "0.1" "0.15" "0.3" "0.4" "0.5" "0.7" "0.8" "0.95" "0.99"
    )
    
    for numero in "${numeros_interesse[@]}"; do
        local count=$(grep -r -E "\b$numero\b" "$PROJETO_ROOT/src/main/java" --include="*.java" | wc -l)
        if [ $count -gt 0 ]; then
            local categoria=""
            case $numero in
                "30"|"60"|"300"|"600"|"1200"|"1800"|"3600"|"86400"|"604800"|"31536000")
                    categoria="⏱️ Timeout/Duração" ;;
                "1024"|"256"|"128"|"64"|"32"|"16"|"2048")
                    categoria="💾 Memória/Buffer" ;;
                "500"|"429"|"401"|"403"|"404"|"200")
                    categoria="🌐 HTTP Status" ;;
                "11"|"12"|"255"|"150"|"100"|"50")
                    categoria="📋 Validação/Limite" ;;
                "0.1"|"0.15"|"0.3"|"0.4"|"0.5"|"0.7"|"0.8"|"0.95"|"0.99")
                    categoria="📊 Percentual/Probabilidade" ;;
                *)
                    categoria="❓ Outros" ;;
            esac
            
            echo "| \`$numero\` | $count | $categoria |" >> "$RELATORIO_ARQUIVO"
            echo "  $numero: $count ocorrências ($categoria)"
        fi
    done
}

# Executar análises por categoria
echo -e "${GREEN}🚀 Iniciando análise detalhada...${NC}"

# 1. Timeouts e Durações
listar_ocorrencias "\b(30|60|300|600|1200|1800|3600|86400|604800|31536000)\b" "⏱️ TIMEOUTS E DURAÇÕES (segundos)" 15

# 2. Timeouts em milissegundos
listar_ocorrencias "\b(1000|2000|3000|5000|10000|15000|30000|45000|60000|300000|600000|1800000)\b" "⏱️ TIMEOUTS EM MILISSEGUNDOS" 15

# 3. Tamanhos de memória e buffer
listar_ocorrencias "\b(16|32|64|128|256|512|1024|2048|4096)\b" "💾 TAMANHOS DE MEMÓRIA E BUFFER" 15

# 4. Números grandes (milhões)
listar_ocorrencias "\b(1_000_000|1000000)\b" "💾 NÚMEROS GRANDES (milhões)" 10

# 5. Códigos HTTP
listar_ocorrencias "\b(200|201|400|401|403|404|422|429|500|502|503|504)\b" "🌐 CÓDIGOS HTTP" 15

# 6. Validação de documentos brasileiros
listar_ocorrencias "\b(11|12|14)\b" "📋 VALIDAÇÃO DE DOCUMENTOS BRASILEIROS" 15

# 7. Percentuais e probabilidades
listar_ocorrencias "\b(0\.[0-9]+)\b" "📊 PERCENTUAIS E PROBABILIDADES" 15

# 8. Horários específicos
listar_ocorrencias "\b(13|15|17|18|20|24|44)\b" "🕐 HORÁRIOS ESPECÍFICOS" 10

# 9. Limites de negócio
listar_ocorrencias "\b(50|100|150|200|255|500|999)\b" "📋 LIMITES DE NEGÓCIO" 15

# 10. Números decimais com sufixo
listar_ocorrencias "\b[0-9]+\.[0-9]+[fF]?\b" "🔢 NÚMEROS DECIMAIS" 15

# Análise de frequência
analisar_frequencia_numeros

# Adicionar recomendações ao relatório
cat >> "$RELATORIO_ARQUIVO" << 'EOF'

## 🎯 RECOMENDAÇÕES DE REFATORAÇÃO

### Prioridade 1: CRÍTICA (Segurança e Configuração)
- **Timeouts de autenticação**: 30, 60, 300, 600 segundos
- **Códigos HTTP**: 401, 403, 429, 500
- **Tamanhos criptográficos**: 16, 32, 64, 256, 2048

### Prioridade 2: ALTA (Performance e Cache)
- **Timeouts de cache**: 1800, 3600, 86400 segundos
- **Tamanhos de buffer**: 1024, 1_000_000 bytes
- **Limites de memória**: 128, 256, 512

### Prioridade 3: MÉDIA (Validação e Negócio)
- **Documentos brasileiros**: 11 (CPF), 12 (telefone)
- **Limites de interface**: 50, 100, 150, 200, 255, 500
- **Horários específicos**: 13, 15, 17, 18, 20

### Prioridade 4: BAIXA (Monitoramento e Métricas)
- **Percentuais**: 0.1, 0.15, 0.3, 0.5, 0.7, 0.95, 0.99
- **Thresholds**: 29.0, 30.0
- **Intervalos de coleta**: valores específicos de monitoramento

## 📋 PRÓXIMOS PASSOS

1. **Criar classes de constantes** organizadas por categoria
2. **Refatorar por prioridade** começando pelos valores mais críticos
3. **Validar impacto** medindo redução de alertas Checkstyle
4. **Documentar padrões** para evitar regressão futura

---
**Gerado automaticamente em**: $(date)
**Script**: scripts/refactoring/analisar-numeros-magicos.sh
EOF

# Estatísticas finais
echo -e "${GREEN}✅ ANÁLISE CONCLUÍDA${NC}"
echo "Relatório salvo em: $RELATORIO_ARQUIVO"

# Contar total de números mágicos
total_magicos=$(grep -r -E "\b[0-9]{2,}\b|\b[0-9]+\.[0-9]+[fF]?\b" "$PROJETO_ROOT/src/main/java" --include="*.java" | wc -l)
echo "Total de números mágicos encontrados: $total_magicos"

# Adicionar estatísticas ao início do relatório
sed -i.bak "s/\*\*Data da Análise\*\*:.*/\*\*Data da Análise\*\*: $(date)/" "$RELATORIO_ARQUIVO"
sed -i.bak "/## 📈 ESTATÍSTICAS GERAIS/a\\
\\
**Total de números mágicos encontrados**: $total_magicos\\
**Arquivos Java analisados**: $(find "$PROJETO_ROOT/src/main/java" -name "*.java" | wc -l)\\
**Diretórios analisados**: $(find "$PROJETO_ROOT/src/main/java" -type d | wc -l)\\
" "$RELATORIO_ARQUIVO"

# Limpar arquivo temporário
rm -f "$RELATORIO_ARQUIVO.bak"

echo -e "${BLUE}📖 Para visualizar o relatório:${NC}"
echo "cat $RELATORIO_ARQUIVO"
echo ""
echo -e "${YELLOW}💡 Próximo passo: Executar refatoração sistemática baseada nas prioridades identificadas${NC}"
