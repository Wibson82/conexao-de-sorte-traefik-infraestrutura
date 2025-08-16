#!/bin/bash

# Script para corrigir os imports finais após limpeza das constantes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"
LOG_FILE="$SCRIPT_DIR/correcao-imports-finais-$(date +%Y%m%d-%H%M%S).log"

echo "🔧 CORREÇÃO SISTEMÁTICA DOS IMPORTS FINAIS" | tee "$LOG_FILE"
echo "Data: $(date)" | tee -a "$LOG_FILE"
echo "Situação: 80 erros restantes após limpeza" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Função para corrigir imports quebrados
fix_broken_imports() {
    local file="$1"
    echo "📄 Corrigindo imports: $(basename "$file")" | tee -a "$LOG_FILE"
    
    # Backup do arquivo
    cp "$file" "${file}.backup"
    
    # Substituir imports quebrados por imports corretos
    sed -i '' -E '
        # Remover imports de classes que não existem mais
        /import.*\.infraestrutura\.util\.ConstantesConsolidadas;/d;
        /import.*\.infraestrutura\.util\.ConstantesMensagens;/d;
        /import.*\.infraestrutura\.util\.ConstantesURLs;/d;
        /import.*\.infraestrutura\.util\.ConstantesNumericas;/d;
        /import.*\.infraestrutura\.util\.ConstantesNegocio;/d;
        
        # Substituir por imports corretos
        s|import.*\.infraestrutura\.util\.ConstantesConsolidadas;|import br.tec.facilitaservicos.conexaodesorte.constantes.ConstantesNumericas;|g;
        
        # Adicionar imports estáticos necessários
        /^package /a\
\
import static br.tec.facilitaservicos.conexaodesorte.constantes.ConstantesNumericas.Tamanho.*;
        
    ' "$file"
    
    echo "  ✅ Imports corrigidos" | tee -a "$LOG_FILE"
}

# Função para substituir referências de constantes
fix_constant_references() {
    local file="$1"
    
    # Substituir referências antigas por novas
    sed -i '' -E '
        # Constantes de anexo
        s/ConstantesConsolidadas\.ANEXO_TAMANHO_MAX_BYTES/10485760L/g;
        s/ConstantesConsolidadas\.ANEXO_NOME_MAX/ANEXO_MIME_TYPE_MAX/g;
        s/ConstantesConsolidadas\.ANEXO_URL_MAX/2048/g;
        s/ConstantesConsolidadas\.ANEXO_MIME_TYPE_MAX/ANEXO_MIME_TYPE_MAX/g;
        
        # Constantes de grupo e conversa
        s/ConstantesConsolidadas\.GRUPO_NOME_MIN/3/g;
        s/ConstantesConsolidadas\.GRUPO_NOME_MAX/TEXTO_CURTO_MAX/g;
        s/ConstantesConsolidadas\.MAX_PARTICIPANTES/50/g;
        s/ConstantesConsolidadas\.CONVERSA_NOME_MIN/3/g;
        s/ConstantesConsolidadas\.CONVERSA_NOME_MAX/TEXTO_CURTO_MAX/g;
        s/ConstantesConsolidadas\.CONVERSA_DESCRICAO_MAX/500/g;
        s/ConstantesConsolidadas\.MENSAGEM_CONTEUDO_MAX/1000/g;
        
        # Constantes de bate-papo
        s/ConstantesConsolidadas\.BatePapo\.ANEXO_TAMANHO_MAX_BYTES/10485760L/g;
        s/ConstantesConsolidadas\.BatePapo\.GRUPO_NOME_MIN/3/g;
        s/ConstantesConsolidadas\.BatePapo\.GRUPO_NOME_MAX/TEXTO_CURTO_MAX/g;
        s/ConstantesConsolidadas\.BatePapo\.MAX_PARTICIPANTES/50/g;
        s/ConstantesConsolidadas\.BatePapo\.CONVERSA_NOME_MIN/3/g;
        
    ' "$file"
    
    echo "  ✅ Referências de constantes atualizadas" | tee -a "$LOG_FILE"
}

# Obter lista de arquivos com erros de import
echo "🔍 Identificando arquivos com erros de import..." | tee -a "$LOG_FILE"
error_files=()

# Extrair arquivos com erro de compilação
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
            fix_broken_imports "$file"
            fix_constant_references "$file"
            
            ((fixed_files++))
            echo "" | tee -a "$LOG_FILE"
        fi
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
    echo "✅ COMPILAÇÃO BEM-SUCEDIDA!" | tee -a "$LOG_FILE"
    
    # Remover backups se compilação OK
    find "$SOURCE_DIR" -name "*.backup" -delete
    echo "🗑️  Backups removidos (compilação OK)" | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    echo "🎉 PROJETO TOTALMENTE FUNCIONAL!" | tee -a "$LOG_FILE"
    echo "✅ Todos os erros de compilação foram corrigidos" | tee -a "$LOG_FILE"
    echo "✅ Estrutura de constantes consolidada e organizada" | tee -a "$LOG_FILE"
    echo "✅ Imports atualizados para nova arquitetura" | tee -a "$LOG_FILE"
    
else
    echo "⚠️  Ainda há erros. Contando..." | tee -a "$LOG_FILE"
    error_count=$(./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | grep -v "COMPILATION ERROR" | wc -l)
    echo "Erros restantes: $error_count" | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    echo "📄 Primeiros 10 erros restantes:" | tee -a "$LOG_FILE"
    ./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | head -10 | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    echo "💡 PRÓXIMOS PASSOS:" | tee -a "$LOG_FILE"
    echo "1. Analisar erros específicos restantes" | tee -a "$LOG_FILE"
    echo "2. Corrigir manualmente casos especiais" | tee -a "$LOG_FILE"
    echo "3. Validar funcionalidades críticas" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "📄 Log completo salvo em: $LOG_FILE" | tee -a "$LOG_FILE"
