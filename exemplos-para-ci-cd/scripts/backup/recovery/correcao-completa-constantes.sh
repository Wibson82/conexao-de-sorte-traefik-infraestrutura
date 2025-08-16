#!/bin/bash

# Script de correção completa para todos os problemas de constantes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"
LOG_FILE="$SCRIPT_DIR/correcao-completa-$(date +%Y%m%d-%H%M%S).log"

echo "🛠️ CORREÇÃO COMPLETA DE CONSTANTES PARA PRODUÇÃO" | tee "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "Ambiente: Java 21 + Spring Boot 3.5+" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Função para substituir constantes por valores literais
fix_constants_to_literals() {
    local file="$1"
    echo "📄 Corrigindo: $(basename "$file")" | tee -a "$LOG_FILE"
    
    # Backup do arquivo
    cp "$file" "${file}.backup"
    
    # Substituições massivas por valores literais
    sed -i '' -E '
        # Constantes de anexo
        s/ConstantesConsolidadas\.ANEXO_TAMANHO_MAX_BYTES/10485760L/g;
        s/ConstantesConsolidadas\.BatePapo\.ANEXO_TAMANHO_MAX_BYTES/10485760L/g;
        s/ConstantesConsolidadas\.ANEXO_NOME_MAX/255/g;
        s/ConstantesConsolidadas\.ANEXO_URL_MAX/2048/g;
        s/ConstantesConsolidadas\.ANEXO_MIME_TYPE_MAX/100/g;
        
        # Constantes de grupo e conversa
        s/ConstantesConsolidadas\.GRUPO_NOME_MIN/3/g;
        s/ConstantesConsolidadas\.GRUPO_NOME_MAX/100/g;
        s/ConstantesConsolidadas\.MAX_PARTICIPANTES/50/g;
        s/ConstantesConsolidadas\.CONVERSA_NOME_MIN/3/g;
        s/ConstantesConsolidadas\.CONVERSA_NOME_MAX/100/g;
        s/ConstantesConsolidadas\.CONVERSA_DESCRICAO_MAX/500/g;
        s/ConstantesConsolidadas\.MENSAGEM_CONTEUDO_MAX/1000/g;
        
        # Constantes de tamanho de campos
        s/ConstantesNumericas\.TamanhoCampos\.BAIRRO_MAX/100/g;
        s/ConstantesNumericas\.TamanhoCampos\.CIDADE_MAX/100/g;
        s/ConstantesNumericas\.TamanhoCampos\.USER_AGENT_MAX/500/g;
        s/ConstantesNumericas\.TamanhoCampos\.NOME_MAX/100/g;
        s/ConstantesNumericas\.TamanhoCampos\.DESCRICAO_MAX/500/g;
        s/ConstantesNumericas\.TamanhoCampos\.URL_MAX/2048/g;
        s/ConstantesNumericas\.TamanhoCampos\.EMAIL_MAX/100/g;
        s/ConstantesNumericas\.TamanhoCampos\.REALIZADA_POR_MAX/100/g;
        
        # Constantes de loteria
        s/ConstantesNumericas\.LOTOFACIL_MAX_ACERTOS_15/15/g;
        s/ConstantesNumericas\.LOTOFACIL_DEZENAS_15/15/g;
        s/ConstantesNumericas\.LOTOFACIL_MIN_ACERTOS_11/11/g;
        
        # Constantes de dias
        s/ConstantesNumericas\.DIAS_11/11/g;
        s/ConstantesNumericas\.DIAS_15/15/g;
        s/ConstantesNumericas\.DIAS_20/20/g;
        s/ConstantesNumericas\.RETENCAO_ESTENDIDA_DIAS_60/60/g;
        
        # Constantes de negócio
        s/ConstantesNegocio\.TAMANHO_CAMPO_CURTO/50/g;
        s/ConstantesNegocio\.TAMANHO_CAMPO_MEDIO/100/g;
        s/ConstantesNegocio\.TAMANHO_CAMPO_LONGO/255/g;
        s/ConstantesNegocio\.TAMANHO_DESCRICAO/500/g;
        s/ConstantesNegocio\.TAMANHO_OBSERVACAO/1000/g;
        
        # Constantes de validação
        s/ConstantesNumericas\.TAMANHO_MAXIMO_NOME_USUARIO/50/g;
        s/ConstantesNumericas\.TAMANHO_MINIMO_NOME_USUARIO/3/g;
        s/ConstantesNumericas\.TAMANHO_MAXIMO_DESCRICAO/500/g;
        s/ConstantesNumericas\.TAMANHO_MAXIMO_OBSERVACAO/1000/g;
        
    ' "$file"
    
    echo "  ✅ Constantes substituídas por valores literais" | tee -a "$LOG_FILE"
}

# Função para remover imports problemáticos
fix_imports() {
    local file="$1"
    
    # Remover imports de classes que não existem mais
    sed -i '' -E '
        /import.*ConstantesNumericas;/d;
        /import.*ConstantesMensagens;/d;
        /import.*ConstantesURLs;/d;
        /import.*ConstantesConsolidadas;/d;
        /import.*ConstantesNegocio;/d;
        /import static.*ConstantesNumericas\./d;
        /import static.*ConstantesMensagens\./d;
        /import static.*ConstantesURLs\./d;
        /import static.*ConstantesConsolidadas\./d;
        /import static.*ConstantesNegocio\./d;
    ' "$file"
    
    echo "  ✅ Imports problemáticos removidos" | tee -a "$LOG_FILE"
}

# Obter lista de arquivos com erros
echo "🔍 Identificando arquivos com erros..." | tee -a "$LOG_FILE"
error_files=()

# Compilar e extrair arquivos com erro
while IFS= read -r line; do
    if [[ $line =~ \[ERROR\].*(/[^:]+\.java): ]]; then
        file_path="${BASH_REMATCH[1]}"
        if [[ -f "$file_path" ]]; then
            # Verificar se já está na lista
            found=false
            for existing in "${error_files[@]}"; do
                if [[ "$existing" == "$file_path" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" == "false" ]]; then
                error_files+=("$file_path")
            fi
        fi
    fi
done < <(./mvnw compile -q 2>&1)

echo "Encontrados ${#error_files[@]} arquivos com erros" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Processar cada arquivo
total_files=0
fixed_files=0

if [[ ${#error_files[@]} -gt 0 ]]; then
    for file in "${error_files[@]}"; do
    if [[ -f "$file" ]]; then
        ((total_files++))
        
        # Aplicar correções
        fix_constants_to_literals "$file"
        fix_imports "$file"
        
        ((fixed_files++))
        echo "" | tee -a "$LOG_FILE"
    done
else
    echo "Nenhum arquivo com erro encontrado ou problema na detecção" | tee -a "$LOG_FILE"
fi

echo "📊 RELATÓRIO DE CORREÇÃO" | tee -a "$LOG_FILE"
echo "========================" | tee -a "$LOG_FILE"
echo "Arquivos processados: $total_files" | tee -a "$LOG_FILE"
echo "Arquivos corrigidos: $fixed_files" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Testar compilação
echo "🔄 Testando compilação após correções..." | tee -a "$LOG_FILE"
if ./mvnw compile -q > /dev/null 2>&1; then
    echo "✅ Compilação bem-sucedida!" | tee -a "$LOG_FILE"
    
    # Remover backups se compilação OK
    find "$SOURCE_DIR" -name "*.backup" -delete
    echo "🗑️  Backups removidos (compilação OK)" | tee -a "$LOG_FILE"
else
    echo "⚠️  Ainda há erros. Contando..." | tee -a "$LOG_FILE"
    error_count=$(./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | grep -v "COMPILATION ERROR" | wc -l)
    echo "Erros restantes: $error_count" | tee -a "$LOG_FILE"
    
    echo "📄 Primeiros 10 erros:" | tee -a "$LOG_FILE"
    ./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | head -10 | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "📄 Log completo salvo em: $LOG_FILE" | tee -a "$LOG_FILE"
