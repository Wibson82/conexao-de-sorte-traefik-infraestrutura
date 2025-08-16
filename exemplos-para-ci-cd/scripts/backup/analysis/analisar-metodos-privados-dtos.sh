#!/bin/bash

# Script para analisar métodos privados em DTOs
# Parte da Fase 2 do plano de análise completa de variáveis não utilizadas

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/analysis-reports"
REPORT_FILE="$REPORT_DIR/analise-metodos-privados-dtos-$(date +%Y%m%d-%H%M%S).md"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"

# Criar diretório de relatórios se não existir
mkdir -p "$REPORT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para log
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "=== ANÁLISE DE MÉTODOS PRIVADOS EM DTOs ===" > "$REPORT_FILE"
echo "Data: $(date)" >> "$REPORT_FILE"
echo "Diretório: $SOURCE_DIR" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_info "🔍 Iniciando análise de métodos privados em DTOs..."

# Encontrar arquivos DTO
ARQUIVOS_DTO=$(find "$SOURCE_DIR" -name "*DTO.java" -o -name "*Dto.java" -o -path "*/dto/*" -name "*.java")

if [ -z "$ARQUIVOS_DTO" ]; then
    log_warning "Nenhum arquivo DTO encontrado!"
    echo "⚠️ Nenhum arquivo DTO encontrado no projeto." >> "$REPORT_FILE"
    exit 0
fi

echo "## DTOs com Métodos Privados Analisados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

count=0
dtos_com_metodos_privados=0
metodos_utilizados=0
metodos_nao_utilizados=0

for arquivo in $ARQUIVOS_DTO; do
    arquivo_relativo=${arquivo#$PROJECT_ROOT/}
    
    # Verificar se tem métodos privados
    metodos_privados=$(grep -n "private.*(" "$arquivo" 2>/dev/null | grep -v "private final\|private static final\|private.*=" || true)
    
    if [ -n "$metodos_privados" ]; then
        ((count++))
        ((dtos_com_metodos_privados++))
        
        log_info "📁 Analisando: $arquivo_relativo"
        echo "### $count. $arquivo_relativo" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        echo "**Métodos privados encontrados:**" >> "$REPORT_FILE"
        echo '```java' >> "$REPORT_FILE"
        echo "$metodos_privados" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        # Analisar uso de cada método privado
        echo "**Análise de uso:**" >> "$REPORT_FILE"
        
        while IFS= read -r linha_metodo; do
            if [[ $linha_metodo =~ private.*[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\( ]]; then
                nome_metodo="${BASH_REMATCH[1]}"
                
                # Verificar se o método é usado no arquivo
                uso_count=$(grep -c "$nome_metodo" "$arquivo" 2>/dev/null || echo "0")
                
                if [ "$uso_count" -gt 1 ]; then
                    echo "- ✅ \`$nome_metodo()\`: **UTILIZADO** ($((uso_count - 1)) referências)" >> "$REPORT_FILE"
                    ((metodos_utilizados++))
                else
                    echo "- ❌ \`$nome_metodo()\`: **NÃO UTILIZADO** (apenas declaração)" >> "$REPORT_FILE"
                    ((metodos_nao_utilizados++))
                fi
            fi
        done <<< "$metodos_privados"
        
        echo "" >> "$REPORT_FILE"
        
        # Verificar padrões comuns em DTOs
        echo "**Padrões identificados:**" >> "$REPORT_FILE"
        
        # Verificar se é um record
        if grep -q "public record" "$arquivo"; then
            echo "- 📋 **Record**: Métodos privados podem ser auxiliares para validação" >> "$REPORT_FILE"
        fi
        
        # Verificar se tem Builder pattern
        if grep -q "Builder\|builder" "$arquivo"; then
            echo "- 🏗️ **Builder Pattern**: Métodos privados podem ser auxiliares do builder" >> "$REPORT_FILE"
        fi
        
        # Verificar se tem toString customizado
        if grep -q "toString()" "$arquivo"; then
            echo "- 📝 **toString() customizado**: Métodos privados podem ser formatadores" >> "$REPORT_FILE"
        fi
        
        # Verificar se tem validações
        if grep -q "validar\|validate" "$arquivo"; then
            echo "- ✅ **Validações**: Métodos privados podem ser validadores" >> "$REPORT_FILE"
        fi
        
        echo "" >> "$REPORT_FILE"
        echo "---" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
done

# Estatísticas finais
echo "## Resumo da Análise" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **Total de arquivos DTO:** $(echo "$ARQUIVOS_DTO" | wc -l)" >> "$REPORT_FILE"
echo "- **DTOs com métodos privados:** $dtos_com_metodos_privados" >> "$REPORT_FILE"
echo "- **Métodos privados utilizados:** $metodos_utilizados" >> "$REPORT_FILE"
echo "- **Métodos privados não utilizados:** $metodos_nao_utilizados" >> "$REPORT_FILE"
echo "- **Taxa de utilização:** $(echo "scale=1; $metodos_utilizados * 100 / ($metodos_utilizados + $metodos_nao_utilizados)" | bc 2>/dev/null || echo "N/A")%" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Recomendações
echo "## Recomendações" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ $metodos_nao_utilizados -gt 0 ]; then
    echo "### ⚠️ Ação Requerida" >> "$REPORT_FILE"
    echo "- [ ] **Revisar métodos não utilizados:** $metodos_nao_utilizados métodos identificados" >> "$REPORT_FILE"
    echo "- [ ] **Verificar se são necessários:** Alguns podem ser preparação para funcionalidades futuras" >> "$REPORT_FILE"
    echo "- [ ] **Remover se desnecessários:** Limpar código não utilizado" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

echo "### ✅ Boas Práticas Identificadas" >> "$REPORT_FILE"
echo "- **Métodos de validação:** Auxiliares para garantir integridade dos dados" >> "$REPORT_FILE"
echo "- **Métodos de formatação:** Para toString() e serialização customizada" >> "$REPORT_FILE"
echo "- **Métodos auxiliares do Builder:** Para construção segura de objetos" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 📋 Diretrizes para DTOs" >> "$REPORT_FILE"
echo "1. **Métodos privados em DTOs devem ter propósito claro:**" >> "$REPORT_FILE"
echo "   - Validação de dados" >> "$REPORT_FILE"
echo "   - Formatação para serialização" >> "$REPORT_FILE"
echo "   - Auxiliares para Builder pattern" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "2. **Evitar lógica de negócio em DTOs:**" >> "$REPORT_FILE"
echo "   - DTOs devem ser objetos de transferência simples" >> "$REPORT_FILE"
echo "   - Lógica complexa deve estar em Services" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "3. **Preferir Records quando possível:**" >> "$REPORT_FILE"
echo "   - Records reduzem boilerplate" >> "$REPORT_FILE"
echo "   - Validação no construtor compacto" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Mostrar estatísticas no console
log_info "📊 Estatísticas da análise:"
echo "   - DTOs analisados: $(echo "$ARQUIVOS_DTO" | wc -l)"
echo "   - DTOs com métodos privados: $dtos_com_metodos_privados"
echo "   - Métodos utilizados: $metodos_utilizados"
echo "   - Métodos não utilizados: $metodos_nao_utilizados"

if [ $metodos_nao_utilizados -gt 0 ]; then
    log_warning "Encontrados $metodos_nao_utilizados métodos privados não utilizados"
else
    log_success "Todos os métodos privados em DTOs estão sendo utilizados adequadamente!"
fi

log_success "Análise concluída!"
log_info "📄 Relatório salvo em: $REPORT_FILE"

echo ""
log_info "🔍 Para visualizar o relatório:"
echo "   cat $REPORT_FILE"

echo ""
log_info "📋 Próximos passos sugeridos:"
echo "   1. Revisar métodos não utilizados identificados"
echo "   2. Verificar se são necessários para funcionalidades futuras"
echo "   3. Remover métodos desnecessários"
echo "   4. Documentar métodos auxiliares importantes"
