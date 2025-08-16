#!/bin/bash

# Script para identificar constantes dispersas que precisam ser consolidadas
# Baseado na análise dos relatórios anteriores

echo "🔍 Identificação de Constantes Dispersas - $(date)"
echo "================================================"

# Diretório de relatórios
REPORT_DIR="analysis-reports"
mkdir -p "$REPORT_DIR"

# Arquivo de relatório
REPORT_FILE="$REPORT_DIR/constantes-dispersas-$(date +%Y%m%d-%H%M%S).txt"

echo "🔍 Identificação de Constantes Dispersas - $(date)" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Função para buscar padrões específicos
buscar_padrao() {
    local padrao="$1"
    local descricao="$2"
    local arquivos_excluir="$3"
    
    echo "=== $descricao ===" >> "$REPORT_FILE"
    
    # Buscar em arquivos Java, excluindo arquivos de constantes
    find src/main/java -name "*.java" \
        ! -name "*Constante*.java" \
        ! -name "*Constants*.java" \
        ! -path "*/test/*" \
        -exec grep -Hn "$padrao" {} \; 2>/dev/null | \
        head -50 >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
}

# 1. Números mágicos comuns que aparecem frequentemente
echo "📊 Analisando números mágicos comuns..." 
buscar_padrao "= 100[^0-9]" "Números 100 dispersos no código"
buscar_padrao "= 200[^0-9]" "Números 200 dispersos no código"
buscar_padrao "= 500[^0-9]" "Números 500 dispersos no código"
buscar_padrao "= 1000[^0-9]" "Números 1000 dispersos no código"
buscar_padrao "= 5000[^0-9]" "Números 5000 dispersos no código"

# 2. Timeouts e delays
echo "⏱️ Analisando timeouts e delays..."
buscar_padrao "timeout.*[0-9]+" "Timeouts hardcoded"
buscar_padrao "delay.*[0-9]+" "Delays hardcoded"
buscar_padrao "sleep.*[0-9]+" "Sleep hardcoded"
buscar_padrao "Duration\.of.*[0-9]+" "Durações hardcoded"

# 3. Tamanhos e limites
echo "📏 Analisando tamanhos e limites..."
buscar_padrao "@Size.*max.*[0-9]+" "Validações de tamanho hardcoded"
buscar_padrao "length.*>.*[0-9]+" "Verificações de tamanho hardcoded"
buscar_padrao "capacity.*[0-9]+" "Capacidades hardcoded"

# 4. Códigos HTTP
echo "🌐 Analisando códigos HTTP..."
buscar_padrao "statusCode.*[0-9]{3}" "Códigos HTTP hardcoded"
buscar_padrao "HttpStatus\.[A-Z_]+" "HttpStatus enums que poderiam ser constantes"

# 5. Strings de erro comuns
echo "❌ Analisando mensagens de erro..."
buscar_padrao '"[Ee]rro.*"' "Mensagens de erro hardcoded"
buscar_padrao '"[Ff]alha.*"' "Mensagens de falha hardcoded"
buscar_padrao '"[Ss]ucesso.*"' "Mensagens de sucesso hardcoded"

# 6. URLs e endpoints
echo "🔗 Analisando URLs e endpoints..."
buscar_padrao '"http[s]?://[^"]+"' "URLs hardcoded"
buscar_padrao '@RequestMapping.*"/[^"]+"' "Endpoints hardcoded"
buscar_padrao '@GetMapping.*"/[^"]+"' "GET endpoints hardcoded"
buscar_padrao '@PostMapping.*"/[^"]+"' "POST endpoints hardcoded"

# 7. Configurações de banco
echo "🗄️ Analisando configurações de banco..."
buscar_padrao 'maxPoolSize.*[0-9]+' "Pool sizes hardcoded"
buscar_padrao 'connectionTimeout.*[0-9]+' "Connection timeouts hardcoded"

# 8. Configurações de cache
echo "💾 Analisando configurações de cache..."
buscar_padrao 'cacheSize.*[0-9]+' "Cache sizes hardcoded"
buscar_padrao 'expireAfter.*[0-9]+' "Cache expiration hardcoded"

# 9. Regex patterns
echo "🔤 Analisando padrões regex..."
buscar_padrao 'Pattern\.compile.*"[^"]+"' "Regex patterns hardcoded"

# 10. Configurações de thread
echo "🧵 Analisando configurações de thread..."
buscar_padrao 'corePoolSize.*[0-9]+' "Core pool sizes hardcoded"
buscar_padrao 'maximumPoolSize.*[0-9]+' "Maximum pool sizes hardcoded"
buscar_padrao 'queueCapacity.*[0-9]+' "Queue capacities hardcoded"

# Análise de prioridades
echo "" >> "$REPORT_FILE"
echo "=== Análise de Prioridades para Consolidação ===" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "🔥 ALTA PRIORIDADE:" >> "$REPORT_FILE"
echo "   • Números que aparecem mais de 10 vezes (100, 200, 500, 1000)" >> "$REPORT_FILE"
echo "   • Códigos HTTP hardcoded" >> "$REPORT_FILE"
echo "   • Timeouts e delays" >> "$REPORT_FILE"
echo "   • Mensagens de erro frequentes" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "⚡ MÉDIA PRIORIDADE:" >> "$REPORT_FILE"
echo "   • Validações de tamanho (@Size)" >> "$REPORT_FILE"
echo "   • Configurações de pool e cache" >> "$REPORT_FILE"
echo "   • Endpoints de API" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "📝 BAIXA PRIORIDADE:" >> "$REPORT_FILE"
echo "   • URLs externas específicas" >> "$REPORT_FILE"
echo "   • Regex patterns únicos" >> "$REPORT_FILE"
echo "   • Configurações muito específicas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Recomendações
echo "=== Recomendações de Consolidação ===" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. 📁 Criar ConstantesNumericas.java para números mágicos" >> "$REPORT_FILE"
echo "2. ⏱️ Consolidar timeouts em ConstantesConfiguracao.java" >> "$REPORT_FILE"
echo "3. 🌐 Mover códigos HTTP para ConstantesHTTP.java" >> "$REPORT_FILE"
echo "4. ❌ Centralizar mensagens em ConstantesMensagens.java" >> "$REPORT_FILE"
echo "5. 🔗 Organizar endpoints em ConstantesURLs.java" >> "$REPORT_FILE"
echo "6. 📏 Padronizar validações em ConstantesValidacao.java" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "✅ Análise concluída. Relatório salvo em: $REPORT_FILE"
echo "✅ Análise concluída. Relatório salvo em: $REPORT_FILE"

# Estatísticas finais
total_java_files=$(find src/main/java -name "*.java" ! -name "*Constante*.java" ! -name "*Constants*.java" | wc -l)
echo "📊 Resumo:"
echo "   • Arquivos Java analisados: $total_java_files"
echo "   • Relatório: $REPORT_FILE"