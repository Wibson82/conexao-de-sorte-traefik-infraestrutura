#!/bin/bash

# Script simplificado para corrigir erros pós-refatoração
set -e

echo "🔧 Corrigindo erros de expressões constantes em anotações..."

# Lista de arquivos com erros conhecidos
files_to_fix=(
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/controle/ControladorOAuth2.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/autenticacao/controle/ControladorUsuario.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/loteria/controle/ControladorExtracaoPublica.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/privacidade/ControladorPrivacidade.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/aplicacao/transacao/controle/ControladorTipoItem.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/cache/ControladorMonitoramentoCache.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/controlador/metricas/ControladorMetricas.java"
)

# Função para corrigir um arquivo
fix_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "📄 Corrigindo: $(basename "$file")"
        
        # Substituir constantes string por valores literais em anotações
        sed -i '' -E '
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
        ' "$file"
        
        echo "  ✅ Corrigido"
    else
        echo "  ❌ Arquivo não encontrado: $file"
    fi
}

# Corrigir cada arquivo
for file in "${files_to_fix[@]}"; do
    fix_file "$file"
done

echo ""
echo "✅ Correção de expressões constantes concluída!"
echo "🔄 Testando compilação..."

# Testar compilação
if ./mvnw compile -q > /dev/null 2>&1; then
    echo "✅ Compilação bem-sucedida!"
else
    echo "⚠️  Ainda há erros. Verificando..."
    ./mvnw compile -q 2>&1 | grep -E "\[ERROR\]" | head -10
fi
