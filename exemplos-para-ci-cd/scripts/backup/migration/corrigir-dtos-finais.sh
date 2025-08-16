#!/bin/bash

# Script para corrigir DTOs com constantes faltantes
set -e

echo "🔧 Corrigindo DTOs finais..."

# Função para corrigir um arquivo
fix_dto() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "📄 Corrigindo: $(basename "$file")"
        
        # Substituir constantes por valores literais
        sed -i '' -E '
            # Constantes de bate-papo
            s/ConstantesConsolidadas\.BatePapo\.MENSAGEM_CONTEUDO_MAX/1000/g;
            s/ConstantesConsolidadas\.MENSAGEM_CONTEUDO_MAX/1000/g;
            s/ConstantesConsolidadas\.BatePapo\.ANEXO_NOME_MAX/255/g;
            s/ConstantesConsolidadas\.ANEXO_NOME_MAX/255/g;
            s/ConstantesConsolidadas\.BatePapo\.ANEXO_URL_MAX/2048/g;
            s/ConstantesConsolidadas\.ANEXO_URL_MAX/2048/g;
            s/ConstantesConsolidadas\.BatePapo\.ANEXO_MIME_TYPE_MAX/100/g;
            s/ConstantesConsolidadas\.ANEXO_MIME_TYPE_MAX/100/g;
            s/ConstantesConsolidadas\.BatePapo\.CONVERSA_NOME_MAX/100/g;
            s/ConstantesConsolidadas\.CONVERSA_NOME_MAX/100/g;
            s/ConstantesConsolidadas\.BatePapo\.CONVERSA_DESCRICAO_MAX/500/g;
            s/ConstantesConsolidadas\.CONVERSA_DESCRICAO_MAX/500/g;
            s/ConstantesConsolidadas\.BatePapo\.GRUPO_NOME_MIN/3/g;
            s/ConstantesConsolidadas\.GRUPO_NOME_MIN/3/g;
            s/ConstantesConsolidadas\.BatePapo\.GRUPO_NOME_MAX/100/g;
            s/ConstantesConsolidadas\.GRUPO_NOME_MAX/100/g;
            s/ConstantesConsolidadas\.BatePapo\.MAX_PARTICIPANTES/50/g;
            s/ConstantesConsolidadas\.MAX_PARTICIPANTES/50/g;
            
        ' "$file"
        
        echo "  ✅ Corrigido"
    else
        echo "  ❌ Arquivo não encontrado: $file"
    fi
}

# Lista de arquivos para corrigir
files_to_fix=(
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/AnexoDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/GrupoDTO.java"
)

# Corrigir cada arquivo
for file in "${files_to_fix[@]}"; do
    fix_dto "$file"
done

echo ""
echo "✅ Correção de DTOs finais concluída!"
echo "🔄 Testando compilação..."

# Testar compilação
if ./mvnw compile -q > /dev/null 2>&1; then
    echo "✅ Compilação bem-sucedida!"
    echo "🎉 Todos os erros foram corrigidos!"
else
    echo "⚠️  Ainda há alguns erros. Verificando..."
    ./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | head -5
fi
