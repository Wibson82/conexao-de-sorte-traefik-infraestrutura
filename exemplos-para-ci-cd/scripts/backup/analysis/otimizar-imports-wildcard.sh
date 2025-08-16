#!/bin/bash

# Script para otimizar imports wildcard no projeto
# Parte da Fase 2 do plano de análise completa de variáveis não utilizadas

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/analysis-reports"
REPORT_FILE="$REPORT_DIR/otimizacao-imports-$(date +%Y%m%d-%H%M%S).md"
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

echo "=== OTIMIZAÇÃO DE IMPORTS WILDCARD ===" > "$REPORT_FILE"
echo "Data: $(date)" >> "$REPORT_FILE"
echo "Diretório: $SOURCE_DIR" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_info "🔍 Iniciando análise de imports wildcard..."

# Encontrar arquivos com imports wildcard
ARQUIVOS_WILDCARD=$(find "$SOURCE_DIR" -name "*.java" -exec grep -l "import.*\*" {} \;)

if [ -z "$ARQUIVOS_WILDCARD" ]; then
    log_success "Nenhum import wildcard encontrado!"
    echo "✅ Nenhum import wildcard encontrado no projeto." >> "$REPORT_FILE"
    exit 0
fi

echo "## Arquivos com Imports Wildcard Identificados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

count=0
for arquivo in $ARQUIVOS_WILDCARD; do
    ((count++))
    arquivo_relativo=${arquivo#$PROJECT_ROOT/}
    
    log_info "📁 Analisando: $arquivo_relativo"
    echo "### $count. $arquivo_relativo" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Extrair imports wildcard
    imports_wildcard=$(grep "import.*\*" "$arquivo")
    echo "**Imports wildcard encontrados:**" >> "$REPORT_FILE"
    echo '```java' >> "$REPORT_FILE"
    echo "$imports_wildcard" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Analisar uso das constantes/classes importadas
    echo "**Análise de uso:**" >> "$REPORT_FILE"
    
    # Para cada import wildcard, tentar identificar o que está sendo usado
    while IFS= read -r import_line; do
        if [[ $import_line =~ import[[:space:]]+static[[:space:]]+([^*]+)\.\* ]]; then
            # Import static wildcard
            package_path="${BASH_REMATCH[1]}"
            echo "- Import static wildcard: \`$package_path.*\`" >> "$REPORT_FILE"
            
            # Tentar encontrar a classe correspondente
            class_file=$(find "$SOURCE_DIR" -path "*${package_path//./\/}.java" 2>/dev/null | head -1)
            if [ -n "$class_file" ]; then
                # Extrair constantes públicas da classe
                constants=$(grep -E "public static final|public static.*=" "$class_file" | head -10)
                if [ -n "$constants" ]; then
                    echo "  - Constantes disponíveis (primeiras 10):" >> "$REPORT_FILE"
                    echo '```java' >> "$REPORT_FILE"
                    echo "$constants" >> "$REPORT_FILE"
                    echo '```' >> "$REPORT_FILE"
                fi
            fi
            
        elif [[ $import_line =~ import[[:space:]]+([^*]+)\.\* ]]; then
            # Import wildcard normal
            package_path="${BASH_REMATCH[1]}"
            echo "- Import wildcard: \`$package_path.*\`" >> "$REPORT_FILE"
        fi
    done <<< "$imports_wildcard"
    
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
done

# Estatísticas finais
echo "## Resumo da Análise" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **Total de arquivos com imports wildcard:** $count" >> "$REPORT_FILE"
echo "- **Arquivos analisados:** $(find "$SOURCE_DIR" -name "*.java" | wc -l)" >> "$REPORT_FILE"
echo "- **Percentual com imports wildcard:** $(echo "scale=2; $count * 100 / $(find "$SOURCE_DIR" -name "*.java" | wc -l)" | bc)%" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Recomendações
echo "## Recomendações de Otimização" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "### Prioridade Alta" >> "$REPORT_FILE"
echo "- [ ] **ServicoExportacaoDados:** Substituir import static wildcard por imports específicos" >> "$REPORT_FILE"
echo "- [ ] **ServicoAnonimizacao:** Otimizar múltiplos imports wildcard" >> "$REPORT_FILE"
echo "- [ ] **ServicoAuditoriaDados:** Revisar imports wildcard" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### Prioridade Média" >> "$REPORT_FILE"
echo "- [ ] **ConfiguracaoWebSocket:** Verificar necessidade de imports wildcard" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### Benefícios da Otimização" >> "$REPORT_FILE"
echo "1. **Performance de compilação:** Imports específicos são mais rápidos" >> "$REPORT_FILE"
echo "2. **Clareza do código:** Mostra exatamente quais classes/constantes são usadas" >> "$REPORT_FILE"
echo "3. **Detecção de conflitos:** Evita ambiguidade entre classes com mesmo nome" >> "$REPORT_FILE"
echo "4. **Manutenibilidade:** Facilita refatoração e análise de dependências" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### Próximos Passos" >> "$REPORT_FILE"
echo "1. **Análise manual:** Identificar constantes/classes realmente utilizadas" >> "$REPORT_FILE"
echo "2. **Substituição gradual:** Trocar imports wildcard por específicos" >> "$REPORT_FILE"
echo "3. **Testes:** Validar que não há quebras após otimização" >> "$REPORT_FILE"
echo "4. **Documentação:** Atualizar guidelines de imports do projeto" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Mostrar estatísticas no console
log_info "📊 Estatísticas da análise:"
echo "   - Arquivos com imports wildcard: $count"
echo "   - Total de arquivos Java: $(find "$SOURCE_DIR" -name "*.java" | wc -l)"
echo "   - Percentual: $(echo "scale=1; $count * 100 / $(find "$SOURCE_DIR" -name "*.java" | wc -l)" | bc)%"

log_success "Análise concluída!"
log_info "📄 Relatório salvo em: $REPORT_FILE"

echo ""
log_info "🔍 Para visualizar o relatório:"
echo "   cat $REPORT_FILE"

echo ""
log_info "📋 Próximos passos sugeridos:"
echo "   1. Revisar relatório gerado"
echo "   2. Identificar imports específicos necessários"
echo "   3. Substituir imports wildcard gradualmente"
echo "   4. Executar testes após cada mudança"
