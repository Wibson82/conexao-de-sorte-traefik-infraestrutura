#!/bin/bash

# Script de migração automática de constantes deprecated
# Migra de constantes deprecated para as novas classes ConstantesHTTP e ConstantesTempo

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"
LOG_FILE="$SCRIPT_DIR/migracao-constantes-$(date +%Y%m%d-%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando migração de constantes deprecated${NC}" | tee "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "Diretório: $PROJECT_ROOT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Contadores
total_files=0
migrated_files=0
total_replacements=0

# Função para migrar constantes HTTP
migrate_http_constants() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changes_made=false
    
    echo -e "${YELLOW}📄 Processando: $(basename "$file")${NC}" | tee -a "$LOG_FILE"
    
    # Criar arquivo temporário com as substituições
    sed -E '
        # ConstantesNumericas.HTTP -> ConstantesHTTP.Status
        s/ConstantesNumericas\.HTTP\.OK/ConstantesHTTP.Status.OK/g;
        s/ConstantesNumericas\.HTTP\.CREATED/ConstantesHTTP.Status.CREATED/g;
        s/ConstantesNumericas\.HTTP\.BAD_REQUEST/ConstantesHTTP.Status.BAD_REQUEST/g;
        s/ConstantesNumericas\.HTTP\.UNAUTHORIZED/ConstantesHTTP.Status.UNAUTHORIZED/g;
        s/ConstantesNumericas\.HTTP\.FORBIDDEN/ConstantesHTTP.Status.FORBIDDEN/g;
        s/ConstantesNumericas\.HTTP\.NOT_FOUND/ConstantesHTTP.Status.NOT_FOUND/g;
        s/ConstantesNumericas\.HTTP\.UNPROCESSABLE_ENTITY/ConstantesHTTP.Status.UNPROCESSABLE_ENTITY/g;
        s/ConstantesNumericas\.HTTP\.INTERNAL_SERVER_ERROR/ConstantesHTTP.Status.INTERNAL_SERVER_ERROR/g;
        
        # ConstantesNumericasConsolidadas.StatusHTTP -> ConstantesHTTP.Status
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.OK/ConstantesHTTP.Status.OK/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.CREATED/ConstantesHTTP.Status.CREATED/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.BAD_REQUEST/ConstantesHTTP.Status.BAD_REQUEST/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.UNAUTHORIZED/ConstantesHTTP.Status.UNAUTHORIZED/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.FORBIDDEN/ConstantesHTTP.Status.FORBIDDEN/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.NOT_FOUND/ConstantesHTTP.Status.NOT_FOUND/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.UNPROCESSABLE_ENTITY/ConstantesHTTP.Status.UNPROCESSABLE_ENTITY/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.INTERNAL_SERVER_ERROR/ConstantesHTTP.Status.INTERNAL_SERVER_ERROR/g;
        
        # Strings de status HTTP
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.OK_STR/String.valueOf(ConstantesHTTP.Status.OK)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.CREATED_STR/String.valueOf(ConstantesHTTP.Status.CREATED)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.BAD_REQUEST_STR/String.valueOf(ConstantesHTTP.Status.BAD_REQUEST)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.UNAUTHORIZED_STR/String.valueOf(ConstantesHTTP.Status.UNAUTHORIZED)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.FORBIDDEN_STR/String.valueOf(ConstantesHTTP.Status.FORBIDDEN)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.NOT_FOUND_STR/String.valueOf(ConstantesHTTP.Status.NOT_FOUND)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.UNPROCESSABLE_ENTITY_STR/String.valueOf(ConstantesHTTP.Status.UNPROCESSABLE_ENTITY)/g;
        s/ConstantesNumericasConsolidadas\.StatusHTTP\.INTERNAL_SERVER_ERROR_STR/String.valueOf(ConstantesHTTP.Status.INTERNAL_SERVER_ERROR)/g;
    ' "$file" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        changes_made=true
        echo "  ✅ Constantes HTTP migradas" | tee -a "$LOG_FILE"
        
        # Adicionar import se necessário
        if ! grep -q "import.*ConstantesHTTP" "$file"; then
            add_import "$file" "br.tec.facilitaservicos.conexaodesorte.constantes.core.ConstantesHTTP"
        fi
    else
        rm "$temp_file"
    fi
    
    return $([[ "$changes_made" == "true" ]] && echo 0 || echo 1)
}

# Função para migrar constantes temporais
migrate_time_constants() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changes_made=false
    
    # Criar arquivo temporário com as substituições
    sed -E '
        # ConstantesNumericas.Tempo -> ConstantesTempo
        s/ConstantesNumericas\.Tempo\.SEGUNDOS_60/ConstantesTempo.Conversao.SECONDS_PER_MINUTE/g;
        s/ConstantesNumericas\.Tempo\.SEGUNDOS_3600/ConstantesTempo.Conversao.SECONDS_PER_HOUR/g;
        s/ConstantesNumericas\.Tempo\.MINUTOS_60/ConstantesTempo.Conversao.MINUTES_PER_HOUR/g;
        s/ConstantesNumericas\.Tempo\.HORAS_24/ConstantesTempo.Conversao.HOURS_PER_DAY/g;
        s/ConstantesNumericas\.Tempo\.TIMEOUT_SHUTDOWN_SEGUNDOS/ConstantesTempo.Autenticacao.TIMEOUT_AUTH_DEFAULT_SECONDS/g;
        
        # ProjetoConstants -> ConstantesTempo
        s/ProjetoConstants\.SEGUNDOS_EM_UM_MINUTO/ConstantesTempo.Conversao.SECONDS_PER_MINUTE/g;
        s/ProjetoConstants\.MINUTOS_EM_UMA_HORA/ConstantesTempo.Conversao.MINUTES_PER_HOUR/g;
        s/ProjetoConstants\.HORAS_EM_UM_DIA/ConstantesTempo.Conversao.HOURS_PER_DAY/g;
        s/ProjetoConstants\.DIAS_EM_UMA_SEMANA/ConstantesTempo.Conversao.DAYS_PER_WEEK/g;
        s/ProjetoConstants\.MINUTOS_SESSAO_WEB/30/g;
        
        # ConstantesNumericasConsolidadas.Timeouts -> ConstantesTempo
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_15_SEGUNDOS/ConstantesTempo.Autenticacao.TIMEOUT_LOGOUT_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_30_SEGUNDOS/ConstantesTempo.Autenticacao.TIMEOUT_AUTH_DEFAULT_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_1_MINUTO/ConstantesTempo.Autenticacao.TIMEOUT_TOKEN_VALIDATION_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_2_MINUTOS/ConstantesTempo.Autenticacao.TIMEOUT_OAUTH2_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_5_MINUTOS/ConstantesTempo.Http.TIMEOUT_FILE_UPLOAD_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_30_MINUTOS/ConstantesTempo.Sessao.DURATION_SESSION_TIMEOUT_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_1_HORA/ConstantesTempo.Sessao.DURATION_ADMIN_SESSION_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_1_DIA/ConstantesTempo.Conversao.SECONDS_PER_DAY/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_1_SEMANA/ConstantesTempo.Sessao.DURATION_REMEMBER_ME_SECONDS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_1_ANO/ConstantesTempo.Cache.DURATION_YEAR_CACHE_SECONDS/g;
        
        # Timeouts em milissegundos
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_2000_MS/ConstantesTempo.Millis.TIMEOUT_2_SECONDS_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_10000_MS/ConstantesTempo.Millis.TIMEOUT_10_SECONDS_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_15000_MS/ConstantesTempo.Millis.TIMEOUT_15_SECONDS_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_30000_MS/ConstantesTempo.Millis.TIMEOUT_30_SECONDS_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_45000_MS/ConstantesTempo.Millis.TIMEOUT_45_SECONDS_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_300000_MS/ConstantesTempo.Millis.TIMEOUT_5_MINUTES_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_600000_MS/ConstantesTempo.Millis.TIMEOUT_10_MINUTES_MILLIS/g;
        s/ConstantesNumericasConsolidadas\.Timeouts\.TIMEOUT_1800000_MS/ConstantesTempo.Millis.TIMEOUT_30_MINUTES_MILLIS/g;
    ' "$file" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        changes_made=true
        echo "  ✅ Constantes temporais migradas" | tee -a "$LOG_FILE"
        
        # Adicionar import se necessário
        if ! grep -q "import.*ConstantesTempo" "$file"; then
            add_import "$file" "br.tec.facilitaservicos.conexaodesorte.constantes.temporal.ConstantesTempo"
        fi
    else
        rm "$temp_file"
    fi
    
    return $([[ "$changes_made" == "true" ]] && echo 0 || echo 1)
}

# Função para adicionar import
add_import() {
    local file="$1"
    local import_class="$2"
    
    # Encontrar a linha do último import
    local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    if [[ -n "$last_import_line" ]]; then
        sed -i "" "${last_import_line}a\\
import $import_class;
" "$file"
        echo "  ✅ Import adicionado: $import_class" | tee -a "$LOG_FILE"
    fi
}

# Função principal de migração
migrate_file() {
    local file="$1"
    local file_changed=false
    
    ((total_files++))
    
    # Migrar constantes HTTP
    if migrate_http_constants "$file"; then
        file_changed=true
        ((total_replacements++))
    fi
    
    # Migrar constantes temporais
    if migrate_time_constants "$file"; then
        file_changed=true
        ((total_replacements++))
    fi
    
    if [[ "$file_changed" == "true" ]]; then
        ((migrated_files++))
        echo "  ✅ Arquivo migrado com sucesso" | tee -a "$LOG_FILE"
    else
        echo "  ⏭️  Nenhuma migração necessária" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
}

# Encontrar arquivos Java que usam constantes deprecated
echo -e "${BLUE}🔍 Buscando arquivos com constantes deprecated...${NC}" | tee -a "$LOG_FILE"

files_to_migrate=()
while IFS= read -r -d '' file; do
    if grep -l -E '(ConstantesNumericas\.(HTTP|Tempo)|ConstantesNumericasConsolidadas\.(StatusHTTP|Timeouts)|ProjetoConstants\.(SEGUNDOS_EM_UM_MINUTO|MINUTOS_EM_UMA_HORA|HORAS_EM_UM_DIA|DIAS_EM_UMA_SEMANA|MINUTOS_SESSAO_WEB))' "$file" >/dev/null 2>&1; then
        files_to_migrate+=("$file")
    fi
done < <(find "$SOURCE_DIR" -name "*.java" -print0)

echo "Encontrados ${#files_to_migrate[@]} arquivos para migração" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Processar cada arquivo
for file in "${files_to_migrate[@]}"; do
    migrate_file "$file"
done

# Relatório final
echo -e "${GREEN}📊 RELATÓRIO DE MIGRAÇÃO${NC}" | tee -a "$LOG_FILE"
echo "=================================" | tee -a "$LOG_FILE"
echo "Arquivos processados: $total_files" | tee -a "$LOG_FILE"
echo "Arquivos migrados: $migrated_files" | tee -a "$LOG_FILE"
echo "Total de substituições: $total_replacements" | tee -a "$LOG_FILE"
echo "Log salvo em: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [[ $migrated_files -gt 0 ]]; then
    echo -e "${GREEN}✅ Migração concluída com sucesso!${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}⚠️  Recomendação: Execute os testes para validar as mudanças${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${BLUE}ℹ️  Nenhuma migração foi necessária${NC}" | tee -a "$LOG_FILE"
fi

exit 0
