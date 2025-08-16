#!/bin/bash

# Script para mapear o uso de constantes dispersas no código
# Identifica onde cada constante está sendo usada para facilitar a migração

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/analysis-reports"
REPORT_FILE="$REPORT_DIR/mapeamento-uso-constantes-$(date +%Y%m%d-%H%M%S).txt"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"

# Criar diretório de relatórios se não existir
mkdir -p "$REPORT_DIR"

echo "=== MAPEAMENTO DE USO DE CONSTANTES DISPERSAS ===" > "$REPORT_FILE"
echo "Data: $(date)" >> "$REPORT_FILE"
echo "Diretório: $SOURCE_DIR" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Função para buscar uso de uma constante
buscar_uso_constante() {
    local valor="$1"
    local descricao="$2"
    local contexto="$3"
    
    echo "=== $descricao ===" >> "$REPORT_FILE"
    echo "Valor: $valor" >> "$REPORT_FILE"
    echo "Contexto: $contexto" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Buscar ocorrências
    local count=0
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "$line" >> "$REPORT_FILE"
            ((count++))
        fi
    done < <(grep -rn "$valor" "$SOURCE_DIR" --include="*.java" | head -20)
    
    if [[ $count -eq 0 ]]; then
        echo "Nenhuma ocorrência encontrada." >> "$REPORT_FILE"
    else
        echo "Total de ocorrências: $count" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "----------------------------------------" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Função para buscar padrões regex
buscar_padrao_regex() {
    local padrao="$1"
    local descricao="$2"
    local contexto="$3"
    
    echo "=== $descricao ===" >> "$REPORT_FILE"
    echo "Padrão: $padrao" >> "$REPORT_FILE"
    echo "Contexto: $contexto" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Buscar ocorrências
    local count=0
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "$line" >> "$REPORT_FILE"
            ((count++))
        fi
    done < <(grep -rn -E "$padrao" "$SOURCE_DIR" --include="*.java" | head -15)
    
    if [[ $count -eq 0 ]]; then
        echo "Nenhuma ocorrência encontrada." >> "$REPORT_FILE"
    else
        echo "Total de ocorrências: $count" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "----------------------------------------" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

echo "Iniciando mapeamento de uso de constantes..."

# 1. CONSTANTES NUMÉRICAS MAIS COMUNS
echo "1. Mapeando constantes numéricas..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_uso_constante "100" "Número 100" "Tamanhos, limites, percentuais"
buscar_uso_constante "200" "Número 200" "Status HTTP, tamanhos médios"
buscar_uso_constante "500" "Número 500" "Status HTTP, tamanhos longos, timeouts"
buscar_uso_constante "1000" "Número 1000" "Capacidades, timeouts longos"
buscar_uso_constante "5000" "Número 5000" "Timeouts muito longos, tamanhos grandes"

# 2. STATUS HTTP
echo "2. Mapeando status HTTP..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_uso_constante "\"200\"" "Status HTTP 200 (string)" "Respostas de sucesso"
buscar_uso_constante "\"400\"" "Status HTTP 400 (string)" "Bad Request"
buscar_uso_constante "\"401\"" "Status HTTP 401 (string)" "Unauthorized"
buscar_uso_constante "\"403\"" "Status HTTP 403 (string)" "Forbidden"
buscar_uso_constante "\"404\"" "Status HTTP 404 (string)" "Not Found"
buscar_uso_constante "\"500\"" "Status HTTP 500 (string)" "Internal Server Error"

# 3. MENSAGENS DE ERRO COMUNS
echo "3. Mapeando mensagens de erro..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_uso_constante "\"Erro" "Mensagens de erro genéricas" "Logs, exceções, respostas"
buscar_uso_constante "\"Erro de validação\"" "Erro de validação" "Validações de entrada"
buscar_uso_constante "\"Erro interno\"" "Erro interno" "Erros de sistema"
buscar_uso_constante "\"Erro Interno do Servidor\"" "Erro interno do servidor" "Respostas HTTP 500"
buscar_uso_constante "\"Acesso negado\"" "Acesso negado" "Autorizações"

# 4. TIMEOUTS E DELAYS
echo "4. Mapeando timeouts e delays..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "timeout.*=.*[0-9]+" "Configurações de timeout" "Configurações de rede e processamento"
buscar_padrao_regex "delay.*=.*[0-9]+" "Configurações de delay" "Delays entre operações"
buscar_padrao_regex "sleep\\([0-9]+\\)" "Sleep com valores hardcoded" "Pausas no código"
buscar_padrao_regex "Thread\\.sleep\\([0-9]+\\)" "Thread.sleep com valores hardcoded" "Pausas de thread"

# 5. ANOTAÇÕES @SIZE
echo "5. Mapeando anotações @Size..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "@Size\\(.*max.*=.*[0-9]+" "Anotações @Size com max" "Validações de tamanho"
buscar_padrao_regex "@Size\\(.*min.*=.*[0-9]+" "Anotações @Size com min" "Validações de tamanho mínimo"

# 6. CONFIGURAÇÕES DE CACHE
echo "6. Mapeando configurações de cache..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "cache.*size.*=.*[0-9]+" "Configurações de tamanho de cache" "Configurações de cache"
buscar_padrao_regex "capacity.*=.*[0-9]+" "Configurações de capacidade" "Capacidades de estruturas de dados"

# 7. CONFIGURAÇÕES DE THREAD POOL
echo "7. Mapeando configurações de thread pool..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "corePoolSize.*=.*[0-9]+" "Core pool size" "Configurações de thread pool"
buscar_padrao_regex "maxPoolSize.*=.*[0-9]+" "Max pool size" "Configurações de thread pool"
buscar_padrao_regex "queueCapacity.*=.*[0-9]+" "Queue capacity" "Capacidade de filas"

# 8. PADRÕES REGEX HARDCODED
echo "8. Mapeando padrões regex hardcoded..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "Pattern\\.compile\\(\"" "Padrões regex compilados" "Validações e parsing"
buscar_padrao_regex "matches\\(\"" "Matches com regex hardcoded" "Validações inline"

# 9. URLs E ENDPOINTS HARDCODED
echo "9. Mapeando URLs e endpoints hardcoded..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "\"http[s]?://" "URLs hardcoded" "Integrações externas"
buscar_padrao_regex "\"/" "Endpoints de API hardcoded" "Rotas de API"
buscar_padrao_regex "\"localhost" "Referencias a localhost" "Configurações de desenvolvimento"

# 10. CONFIGURAÇÕES DE BANCO DE DADOS
echo "10. Mapeando configurações de banco..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "maxPoolSize.*=.*[0-9]+" "Max pool size de conexões" "Pool de conexões"
buscar_padrao_regex "minPoolSize.*=.*[0-9]+" "Min pool size de conexões" "Pool de conexões"
buscar_padrao_regex "connectionTimeout.*=.*[0-9]+" "Timeout de conexão" "Configurações de conexão"

# 11. VALIDAÇÕES DE LOTERIA
echo "11. Mapeando validações de loteria..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_uso_constante "60" "Número máximo Mega-Sena" "Validações de loteria"
buscar_uso_constante "80" "Número máximo Quina" "Validações de loteria"
buscar_uso_constante "25" "Número máximo Lotofácil" "Validações de loteria"
buscar_uso_constante "15" "Máximo de dezenas Mega-Sena" "Validações de apostas"

# 12. CONFIGURAÇÕES DE SEGURANÇA
echo "12. Mapeando configurações de segurança..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "expiration.*=.*[0-9]+" "Configurações de expiração" "Tokens e sessões"
buscar_padrao_regex "maxAttempts.*=.*[0-9]+" "Máximo de tentativas" "Segurança e rate limiting"

# 13. MENSAGENS DE SUCESSO
echo "13. Mapeando mensagens de sucesso..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_uso_constante "\"Sucesso\"" "Mensagens de sucesso" "Respostas de operações bem-sucedidas"
buscar_uso_constante "\"realizada com sucesso\"" "Operação realizada com sucesso" "Confirmações de operações"

# 14. CONFIGURAÇÕES DE PAGINAÇÃO
echo "14. Mapeando configurações de paginação..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

buscar_padrao_regex "pageSize.*=.*[0-9]+" "Tamanho de página" "Paginação"
buscar_padrao_regex "limit.*=.*[0-9]+" "Limites de consulta" "Limitações de resultados"

# 15. ANÁLISE DE PRIORIDADE PARA MIGRAÇÃO
echo "15. Análise de prioridade para migração..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== PRIORIDADE ALTA (Migração Imediata) ===" >> "$REPORT_FILE"
echo "1. Status HTTP hardcoded (200, 400, 401, 403, 404, 500)" >> "$REPORT_FILE"
echo "2. Mensagens de erro frequentes" >> "$REPORT_FILE"
echo "3. Timeouts e delays críticos" >> "$REPORT_FILE"
echo "4. Validações de tamanho (@Size)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== PRIORIDADE MÉDIA (Migração Planejada) ===" >> "$REPORT_FILE"
echo "1. Configurações de cache e thread pool" >> "$REPORT_FILE"
echo "2. Padrões regex de validação" >> "$REPORT_FILE"
echo "3. URLs e endpoints de integração" >> "$REPORT_FILE"
echo "4. Configurações de banco de dados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== PRIORIDADE BAIXA (Migração Futura) ===" >> "$REPORT_FILE"
echo "1. Constantes específicas de negócio" >> "$REPORT_FILE"
echo "2. Configurações de desenvolvimento" >> "$REPORT_FILE"
echo "3. Mensagens informativas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 16. RECOMENDAÇÕES DE MIGRAÇÃO
echo "16. Recomendações de migração..." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== RECOMENDAÇÕES DE MIGRAÇÃO ===" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. CONSTANTES NUMÉRICAS:" >> "$REPORT_FILE"
echo "   - Migrar para ConstantesNumericasConsolidadas" >> "$REPORT_FILE"
echo "   - Organizar por categoria (Tamanhos, StatusHTTP, Timeouts, etc.)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "2. MENSAGENS:" >> "$REPORT_FILE"
echo "   - Migrar para ConstantesMensagensConsolidadas" >> "$REPORT_FILE"
echo "   - Separar por tipo (Erro, Sucesso, Info, Aviso)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "3. CONFIGURAÇÕES:" >> "$REPORT_FILE"
echo "   - Migrar para ConstantesConfiguracaoConsolidadas" >> "$REPORT_FILE"
echo "   - Organizar por sistema (BancoDados, Cache, Seguranca, etc.)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "4. VALIDAÇÕES:" >> "$REPORT_FILE"
echo "   - Migrar para ConstantesValidacaoConsolidadas" >> "$REPORT_FILE"
echo "   - Organizar por tipo de dado (Documentos, Contato, Endereco, etc.)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "5. ESTRATÉGIA DE MIGRAÇÃO:" >> "$REPORT_FILE"
echo "   - Fase 1: Migrar constantes de alta prioridade" >> "$REPORT_FILE"
echo "   - Fase 2: Atualizar imports e referencias" >> "$REPORT_FILE"
echo "   - Fase 3: Remover constantes antigas" >> "$REPORT_FILE"
echo "   - Fase 4: Validar e testar" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Mapeamento concluído!"
echo "Relatório salvo em: $REPORT_FILE"
echo "Total de linhas no relatório: $(wc -l < "$REPORT_FILE")"

# Mostrar estatísticas finais
echo "" >> "$REPORT_FILE"
echo "=== ESTATÍSTICAS FINAIS ===" >> "$REPORT_FILE"
echo "Data de geração: $(date)" >> "$REPORT_FILE"
echo "Arquivos Java analisados: $(find "$SOURCE_DIR" -name "*.java" | wc -l)" >> "$REPORT_FILE"
echo "Diretório analisado: $SOURCE_DIR" >> "$REPORT_FILE"
echo "Relatório gerado em: $REPORT_FILE" >> "$REPORT_FILE"

echo "Análise de mapeamento de constantes concluída com sucesso!"