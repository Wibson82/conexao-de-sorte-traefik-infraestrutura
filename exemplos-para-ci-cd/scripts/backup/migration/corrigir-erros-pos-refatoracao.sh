#!/bin/bash

# Script para corrigir erros pós-refatoração de constantes
# Corrige expressões constantes em anotações e imports faltantes

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"
LOG_FILE="$SCRIPT_DIR/correcao-erros-$(date +%Y%m%d-%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Iniciando correção de erros pós-refatoração${NC}" | tee "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "Diretório: $PROJECT_ROOT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Contadores
total_files=0
fixed_files=0
total_fixes=0

# Função para corrigir expressões constantes em anotações
fix_constant_expressions() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changes_made=false
    
    echo -e "${YELLOW}📄 Corrigindo expressões constantes: $(basename "$file")${NC}" | tee -a "$LOG_FILE"
    
    # Substituir constantes string por valores literais em anotações
    sed -E '
        # Swagger/OpenAPI annotations - substituir por valores literais
        s/ConstantesHTTP\.Status\.OK_STR/"200"/g;
        s/ConstantesHTTP\.Status\.CREATED_STR/"201"/g;
        s/ConstantesHTTP\.Status\.NO_CONTENT_STR/"204"/g;
        s/ConstantesHTTP\.Status\.BAD_REQUEST_STR/"400"/g;
        s/ConstantesHTTP\.Status\.UNAUTHORIZED_STR/"401"/g;
        s/ConstantesHTTP\.Status\.FORBIDDEN_STR/"403"/g;
        s/ConstantesHTTP\.Status\.NOT_FOUND_STR/"404"/g;
        s/ConstantesHTTP\.Status\.METHOD_NOT_ALLOWED_STR/"405"/g;
        s/ConstantesHTTP\.Status\.CONFLICT_STR/"409"/g;
        s/ConstantesHTTP\.Status\.UNPROCESSABLE_ENTITY_STR/"422"/g;
        s/ConstantesHTTP\.Status\.TOO_MANY_REQUESTS_STR/"429"/g;
        s/ConstantesHTTP\.Status\.INTERNAL_SERVER_ERROR_STR/"500"/g;
        s/ConstantesHTTP\.Status\.BAD_GATEWAY_STR/"502"/g;
        s/ConstantesHTTP\.Status\.SERVICE_UNAVAILABLE_STR/"503"/g;
        s/ConstantesHTTP\.Status\.GATEWAY_TIMEOUT_STR/"504"/g;
        
        # Constantes numéricas em anotações JPA/Validation
        s/ConstantesConsolidadas\.GRUPO_NOME_MIN/3/g;
        s/ConstantesConsolidadas\.GRUPO_NOME_MAX/100/g;
        s/ConstantesConsolidadas\.ANEXO_NOME_MAX/255/g;
        s/ConstantesConsolidadas\.ANEXO_URL_MAX/2048/g;
        s/ConstantesConsolidadas\.ANEXO_MIME_TYPE_MAX/100/g;
        s/ConstantesConsolidadas\.Tamanhos\.NOME/100/g;
        s/ConstantesConsolidadas\.Tamanhos\.TEXTO_LONGO/255/g;
        s/ConstantesConsolidadas\.Tamanhos\.URL/2048/g;
        s/ConstantesConsolidadas\.Tamanhos\.TEXTO_MEDIO/100/g;
        s/ConstantesConsolidadas\.Tamanhos\.DESCRICAO/500/g;
        
        # Constantes de validação específicas
        s/ConstantesNumericas\.TAMANHO_MAXIMO_NOME_USUARIO/50/g;
        s/ConstantesNumericas\.TAMANHO_MINIMO_NOME_USUARIO/3/g;
        s/ConstantesNumericas\.TAMANHO_MAXIMO_DESCRICAO/500/g;
        s/ConstantesNumericas\.TAMANHO_MAXIMO_OBSERVACAO/1000/g;
        
        # Constantes temporais em anotações
        s/ConstantesTempo\.Sessao\.DURATION_SESSION_TIMEOUT_SECONDS/1800/g;
        s/ConstantesTempo\.Autenticacao\.TIMEOUT_AUTH_DEFAULT_SECONDS/30/g;
        s/ConstantesTempo\.Http\.TIMEOUT_FILE_UPLOAD_SECONDS/300/g;
        
    ' "$file" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        changes_made=true
        echo "  ✅ Expressões constantes corrigidas" | tee -a "$LOG_FILE"
        ((total_fixes++))
    else
        rm "$temp_file"
    fi
    
    return $([[ "$changes_made" == "true" ]] && echo 0 || echo 1)
}

# Função para corrigir imports faltantes
fix_missing_imports() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changes_made=false
    
    # Corrigir imports de classes que não existem mais
    sed -E '
        # Remover imports de classes inexistentes
        /import.*ConstantesNumericas;/d;
        /import.*ConstantesMensagens;/d;
        /import.*ConstantesURLs;/d;
        /import static.*ConstantesNumericas\./d;
        /import static.*ConstantesMensagens\./d;
        /import static.*ConstantesURLs\./d;
        
        # Corrigir imports específicos
        s/import br\.tec\.facilitaservicos\.conexaodesorte\.infraestrutura\.util\.ConstantesNumericas;/\/\/ import br.tec.facilitaservicos.conexaodesorte.infraestrutura.util.ConstantesNumericas; \/\/ Removido na refatoração/g;
        
    ' "$file" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        changes_made=true
        echo "  ✅ Imports corrigidos" | tee -a "$LOG_FILE"
        ((total_fixes++))
    else
        rm "$temp_file"
    fi
    
    return $([[ "$changes_made" == "true" ]] && echo 0 || echo 1)
}

# Função para adicionar constantes faltantes
add_missing_constants() {
    local file="$1"
    local changes_made=false
    
    # Adicionar constantes locais quando necessário
    if grep -q "ConstantesConsolidadas\.GRUPO_NOME_MIN\|ConstantesConsolidadas\.GRUPO_NOME_MAX" "$file"; then
        if ! grep -q "private static final int GRUPO_NOME_MIN" "$file"; then
            # Encontrar local para inserir constantes (após declaração da classe)
            local class_line=$(grep -n "public class\|public final class" "$file" | head -1 | cut -d: -f1)
            if [[ -n "$class_line" ]]; then
                sed -i "" "${class_line}a\\
\\
    // Constantes locais para validação\\
    private static final int GRUPO_NOME_MIN = 3;\\
    private static final int GRUPO_NOME_MAX = 100;\\
" "$file"
                changes_made=true
                echo "  ✅ Constantes locais adicionadas" | tee -a "$LOG_FILE"
                ((total_fixes++))
            fi
        fi
    fi
    
    return $([[ "$changes_made" == "true" ]] && echo 0 || echo 1)
}

# Função principal de correção
fix_file() {
    local file="$1"
    local file_changed=false
    
    ((total_files++))
    
    echo -e "${YELLOW}📄 Processando: $(basename "$file")${NC}" | tee -a "$LOG_FILE"
    
    # Corrigir expressões constantes
    if fix_constant_expressions "$file"; then
        file_changed=true
    fi
    
    # Corrigir imports faltantes
    if fix_missing_imports "$file"; then
        file_changed=true
    fi
    
    # Adicionar constantes faltantes
    if add_missing_constants "$file"; then
        file_changed=true
    fi
    
    if [[ "$file_changed" == "true" ]]; then
        ((fixed_files++))
        echo "  ✅ Arquivo corrigido com sucesso" | tee -a "$LOG_FILE"
    else
        echo "  ⏭️  Nenhuma correção necessária" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
}

# Obter lista de arquivos com erros de compilação
echo -e "${BLUE}🔍 Identificando arquivos com erros...${NC}" | tee -a "$LOG_FILE"

# Compilar e extrair arquivos com erro
error_files=()
while IFS= read -r line; do
    if [[ $line =~ \[ERROR\].*(/[^:]+\.java): ]]; then
        file_path="${BASH_REMATCH[1]}"
        if [[ -f "$file_path" ]] && [[ ! " ${error_files[@]} " =~ " ${file_path} " ]]; then
            error_files+=("$file_path")
        fi
    fi
done < <(./mvnw compile -q 2>&1)

echo "Encontrados ${#error_files[@]} arquivos com erros" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Processar cada arquivo com erro
for file in "${error_files[@]}"; do
    if [[ -f "$file" ]]; then
        fix_file "$file"
    fi
done

# Relatório final
echo -e "${GREEN}📊 RELATÓRIO DE CORREÇÃO${NC}" | tee -a "$LOG_FILE"
echo "=================================" | tee -a "$LOG_FILE"
echo "Arquivos processados: $total_files" | tee -a "$LOG_FILE"
echo "Arquivos corrigidos: $fixed_files" | tee -a "$LOG_FILE"
echo "Total de correções: $total_fixes" | tee -a "$LOG_FILE"
echo "Log salvo em: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [[ $fixed_files -gt 0 ]]; then
    echo -e "${GREEN}✅ Correção concluída com sucesso!${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}⚠️  Recomendação: Execute nova compilação para verificar correções${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${BLUE}ℹ️  Nenhuma correção foi necessária${NC}" | tee -a "$LOG_FILE"
fi

exit 0
