#!/bin/bash

# Script para corrigir entidades e DTOs com erros de constantes
set -e

echo "🔧 Corrigindo entidades e DTOs..."

# Função para corrigir um arquivo
fix_entity_dto() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "📄 Corrigindo: $(basename "$file")"
        
        # Substituir constantes por valores literais
        sed -i '' -E '
            # Constantes de tamanho comuns
            s/ConstantesConsolidadas\.ANEXO_NOME_MAX/255/g;
            s/ConstantesConsolidadas\.ANEXO_URL_MAX/2048/g;
            s/ConstantesConsolidadas\.ANEXO_MIME_TYPE_MAX/100/g;
            s/ConstantesConsolidadas\.Tamanhos\.NOME/100/g;
            s/ConstantesConsolidadas\.Tamanhos\.TEXTO_LONGO/255/g;
            s/ConstantesConsolidadas\.Tamanhos\.URL/2048/g;
            s/ConstantesConsolidadas\.Tamanhos\.TEXTO_MEDIO/100/g;
            s/ConstantesConsolidadas\.Tamanhos\.DESCRICAO/500/g;
            s/ConstantesConsolidadas\.Tamanhos\.OBSERVACAO/1000/g;
            s/ConstantesConsolidadas\.Tamanhos\.EMAIL/100/g;
            s/ConstantesConsolidadas\.Tamanhos\.TELEFONE/20/g;
            s/ConstantesConsolidadas\.Tamanhos\.DOCUMENTO/20/g;
            s/ConstantesConsolidadas\.Tamanhos\.CODIGO/50/g;
            s/ConstantesConsolidadas\.Tamanhos\.TITULO/200/g;
            
            # Constantes numéricas específicas
            s/ConstantesNumericas\.TAMANHO_MAXIMO_NOME_USUARIO/50/g;
            s/ConstantesNumericas\.TAMANHO_MINIMO_NOME_USUARIO/3/g;
            s/ConstantesNumericas\.TAMANHO_MAXIMO_DESCRICAO/500/g;
            s/ConstantesNumericas\.TAMANHO_MAXIMO_OBSERVACAO/1000/g;
            s/ConstantesNumericas\.TamanhoCampos\.USER_AGENT_MAX/500/g;
            s/ConstantesNumericas\.TamanhoCampos\.NOME_MAX/100/g;
            s/ConstantesNumericas\.TamanhoCampos\.DESCRICAO_MAX/500/g;
            s/ConstantesNumericas\.TamanhoCampos\.URL_MAX/2048/g;
            s/ConstantesNumericas\.TamanhoCampos\.EMAIL_MAX/100/g;
            
            # Constantes de validação
            s/ConstantesNumericas\.Validacao\.SENHA_MIN/8/g;
            s/ConstantesNumericas\.Validacao\.SENHA_MAX/50/g;
            s/ConstantesNumericas\.Validacao\.USERNAME_MIN/3/g;
            s/ConstantesNumericas\.Validacao\.USERNAME_MAX/50/g;
            
            # Constantes temporais
            s/ConstantesTempo\.Sessao\.DURATION_SESSION_TIMEOUT_SECONDS/1800/g;
            s/ConstantesTempo\.Autenticacao\.TIMEOUT_AUTH_DEFAULT_SECONDS/30/g;
            s/ConstantesTempo\.Http\.TIMEOUT_FILE_UPLOAD_SECONDS/300/g;
            s/ConstantesTempo\.Cache\.DURATION_SHORT_CACHE_SECONDS/300/g;
            s/ConstantesTempo\.Cache\.DURATION_MEDIUM_CACHE_SECONDS/3600/g;
            s/ConstantesTempo\.Cache\.DURATION_LONG_CACHE_SECONDS/86400/g;
            
            # Remover imports não utilizados
            /import.*ConstantesNumericas;/d;
            /import.*ConstantesMensagens;/d;
            /import.*ConstantesURLs;/d;
            /import static.*ConstantesNumericas\./d;
            /import static.*ConstantesMensagens\./d;
            /import static.*ConstantesURLs\./d;
            
        ' "$file"
        
        echo "  ✅ Corrigido"
    else
        echo "  ❌ Arquivo não encontrado: $file"
    fi
}

# Lista de arquivos para corrigir
files_to_fix=(
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/Anexo.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/entidade/contas/TransacaoConta.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemWebSocketDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/MensagemDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/AnexoDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/ConversaDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/batepapo/dto/GrupoDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/ErroRespostaDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/dto/erro/ErroRespostaDTO.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/validacao/GeradorNumeroConta.java"
)

# Corrigir cada arquivo
for file in "${files_to_fix[@]}"; do
    fix_entity_dto "$file"
done

echo ""
echo "✅ Correção de entidades e DTOs concluída!"
echo "🔄 Testando compilação..."

# Testar compilação
if ./mvnw compile -q > /dev/null 2>&1; then
    echo "✅ Compilação bem-sucedida!"
else
    echo "⚠️  Ainda há erros. Verificando..."
    ./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | head -10
fi
