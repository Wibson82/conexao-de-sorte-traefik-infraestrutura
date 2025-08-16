#!/bin/bash

# Script para migração da Fase 1 - Status HTTP
# Migra status HTTP hardcoded para constantes consolidadas

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"
BACKUP_DIR="$PROJECT_ROOT/migration-backup/fase1-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/migration-plans/log-fase1-$(date +%Y%m%d-%H%M%S).txt"

# Criar diretórios
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "=== MIGRAÇÃO FASE 1 - STATUS HTTP ===" | tee "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "Diretório: $SOURCE_DIR" | tee -a "$LOG_FILE"
echo "Backup: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Função para fazer backup de um arquivo
backup_file() {
    local file="$1"
    local relative_path="${file#$SOURCE_DIR/}"
    local backup_path="$BACKUP_DIR/$relative_path"
    
    mkdir -p "$(dirname "$backup_path")"
    cp "$file" "$backup_path"
    echo "Backup criado: $backup_path" | tee -a "$LOG_FILE"
}

# Função para aplicar migração em um arquivo
migrate_file() {
    local file="$1"
    local changes_made=false
    
    echo "Processando: $file" | tee -a "$LOG_FILE"
    
    # Fazer backup antes de modificar
    backup_file "$file"
    
    # Criar arquivo temporário
    local temp_file="${file}.tmp"
    
    # Aplicar substituições
    sed -E '
        # Status HTTP como string
        s/"200"/ConstantesNumericasConsolidadas.StatusHTTP.OK/g;
        s/"201"/ConstantesNumericasConsolidadas.StatusHTTP.CREATED/g;
        s/"400"/ConstantesNumericasConsolidadas.StatusHTTP.BAD_REQUEST/g;
        s/"401"/ConstantesNumericasConsolidadas.StatusHTTP.UNAUTHORIZED/g;
        s/"403"/ConstantesNumericasConsolidadas.StatusHTTP.FORBIDDEN/g;
        s/"404"/ConstantesNumericasConsolidadas.StatusHTTP.NOT_FOUND/g;
        s/"422"/ConstantesNumericasConsolidadas.StatusHTTP.UNPROCESSABLE_ENTITY/g;
        s/"500"/ConstantesNumericasConsolidadas.StatusHTTP.INTERNAL_SERVER_ERROR/g;
        
        # Status HTTP como número (em contextos específicos)
        s/responseCode = 200/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.OK/g;
        s/responseCode = 201/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.CREATED/g;
        s/responseCode = 400/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.BAD_REQUEST/g;
        s/responseCode = 401/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.UNAUTHORIZED/g;
        s/responseCode = 403/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.FORBIDDEN/g;
        s/responseCode = 404/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.NOT_FOUND/g;
        s/responseCode = 422/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.UNPROCESSABLE_ENTITY/g;
        s/responseCode = 500/responseCode = ConstantesNumericasConsolidadas.StatusHTTP.INTERNAL_SERVER_ERROR/g;
        
        # HttpStatus.valueOf
        s/HttpStatus\.valueOf\(200\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.OK)/g;
        s/HttpStatus\.valueOf\(201\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.CREATED)/g;
        s/HttpStatus\.valueOf\(400\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.BAD_REQUEST)/g;
        s/HttpStatus\.valueOf\(401\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.UNAUTHORIZED)/g;
        s/HttpStatus\.valueOf\(403\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.FORBIDDEN)/g;
        s/HttpStatus\.valueOf\(404\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.NOT_FOUND)/g;
        s/HttpStatus\.valueOf\(422\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.UNPROCESSABLE_ENTITY)/g;
        s/HttpStatus\.valueOf\(500\)/HttpStatus.valueOf(ConstantesNumericasConsolidadas.StatusHTTP.INTERNAL_SERVER_ERROR)/g;
        
        # Swagger annotations
        s/@ApiResponse\(code = 200/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.OK/g;
        s/@ApiResponse\(code = 201/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.CREATED/g;
        s/@ApiResponse\(code = 400/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.BAD_REQUEST/g;
        s/@ApiResponse\(code = 401/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.UNAUTHORIZED/g;
        s/@ApiResponse\(code = 403/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.FORBIDDEN/g;
        s/@ApiResponse\(code = 404/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.NOT_FOUND/g;
        s/@ApiResponse\(code = 422/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.UNPROCESSABLE_ENTITY/g;
        s/@ApiResponse\(code = 500/@ApiResponse(code = ConstantesNumericasConsolidadas.StatusHTTP.INTERNAL_SERVER_ERROR/g;
    ' "$file" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        changes_made=true
        echo "  ✅ Arquivo modificado" | tee -a "$LOG_FILE"
        
        # Adicionar import se necessário
        if ! grep -q "import.*ConstantesNumericasConsolidadas" "$file"; then
            # Encontrar a linha do último import
            local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
            if [[ -n "$last_import_line" ]]; then
                sed -i "" "${last_import_line}a\\
import br.tec.facilitaservicos.conexaodesorte.infraestrutura.util.ConstantesNumericasConsolidadas;
" "$file"
                echo "  ✅ Import adicionado" | tee -a "$LOG_FILE"
            fi
        fi
    else
        rm "$temp_file"
        echo "  ⏭️  Nenhuma mudança necessária" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
    return $([[ "$changes_made" == "true" ]] && echo 0 || echo 1)
}

# Encontrar arquivos Java que podem conter status HTTP
echo "Buscando arquivos com status HTTP..." | tee -a "$LOG_FILE"

files_with_status=()
while IFS= read -r -d '' file; do
    if grep -l -E '("[0-9]{3}"|responseCode.*=.*[0-9]{3}|HttpStatus\.valueOf\([0-9]{3}\)|@ApiResponse\(code.*=.*[0-9]{3})' "$file" >/dev/null 2>&1; then
        files_with_status+=("$file")
    fi
done < <(find "$SOURCE_DIR" -name "*.java" -print0)

echo "Encontrados ${#files_with_status[@]} arquivos com status HTTP" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Processar cada arquivo
total_files=${#files_with_status[@]}
processed_files=0
modified_files=0

for file in "${files_with_status[@]}"; do
    ((processed_files++))
    echo "[$processed_files/$total_files] Processando arquivo..." | tee -a "$LOG_FILE"
    
    if migrate_file "$file"; then
        ((modified_files++))
    fi
done

# Relatório final
echo "=== RELATÓRIO FINAL ===" | tee -a "$LOG_FILE"
echo "Arquivos processados: $processed_files" | tee -a "$LOG_FILE"
echo "Arquivos modificados: $modified_files" | tee -a "$LOG_FILE"
echo "Arquivos sem mudanças: $((processed_files - modified_files))" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Verificar se a compilação ainda funciona
echo "Verificando compilação..." | tee -a "$LOG_FILE"
if cd "$PROJECT_ROOT" && ./mvnw compile -q; then
    echo "✅ Compilação bem-sucedida" | tee -a "$LOG_FILE"
else
    echo "❌ Erro na compilação - verifique os logs" | tee -a "$LOG_FILE"
    echo "Backup disponível em: $BACKUP_DIR" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== PRÓXIMOS PASSOS ===" | tee -a "$LOG_FILE"
echo "1. Executar testes: ./mvnw test" | tee -a "$LOG_FILE"
echo "2. Revisar mudanças: git diff" | tee -a "$LOG_FILE"
echo "3. Se tudo estiver OK, commit: git add . && git commit -m 'Migração Fase 1: Status HTTP'" | tee -a "$LOG_FILE"
echo "4. Se houver problemas, restaurar backup de: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "Migração da Fase 1 (Status HTTP) concluída!" | tee -a "$LOG_FILE"
echo "Log salvo em: $LOG_FILE"
echo "Backup salvo em: $BACKUP_DIR"

# Criar script de rollback
ROLLBACK_SCRIPT="$PROJECT_ROOT/migration-plans/rollback-fase1-$(date +%Y%m%d-%H%M%S).sh"
cat > "$ROLLBACK_SCRIPT" << EOF
#!/bin/bash
# Script de rollback para Fase 1 - Status HTTP
# Gerado automaticamente em $(date)

set -e

BACKUP_DIR="$BACKUP_DIR"
SOURCE_DIR="$SOURCE_DIR"

echo "Restaurando arquivos do backup..."

if [ ! -d "\$BACKUP_DIR" ]; then
    echo "Erro: Diretório de backup não encontrado: \$BACKUP_DIR"
    exit 1
fi

# Restaurar todos os arquivos do backup
find "\$BACKUP_DIR" -name "*.java" | while read backup_file; do
    relative_path="\${backup_file#\$BACKUP_DIR/}"
    original_file="\$SOURCE_DIR/\$relative_path"
    
    if [ -f "\$backup_file" ]; then
        cp "\$backup_file" "\$original_file"
        echo "Restaurado: \$original_file"
    fi
done

echo "Rollback concluído!"
echo "Verifique a compilação: ./mvnw compile"
EOF

chmod +x "$ROLLBACK_SCRIPT"
echo "Script de rollback criado: $ROLLBACK_SCRIPT"

echo "Fase 1 da migração (Status HTTP) executada com sucesso!"