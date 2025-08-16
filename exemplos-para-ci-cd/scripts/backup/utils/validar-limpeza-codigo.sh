#!/bin/bash

echo "🔍 Validando limpeza de código..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

success_count=0
warning_count=0
error_count=0

# Função para log
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((success_count++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((warning_count++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((error_count++))
}

# Verificar valores fake
echo "Verificando valores fake..."
if grep -r "fake-" src/ --include="*.java" --include="*.yml" | grep -v "test" > /dev/null 2>&1; then
    log_error "Ainda existem valores fake no código!"
    grep -r "fake-" src/ --include="*.java" --include="*.yml" | grep -v "test"
else
    log_success "Nenhum valor fake encontrado no código"
fi

# Verificar secrets default longos
echo "Verificando secrets default..."
if grep -r "default-jwt-secret" src/ --include="*.java" > /dev/null 2>&1; then
    log_error "Ainda existem secrets default!"
    grep -r "default-jwt-secret" src/ --include="*.java"
else
    log_success "Nenhum secret default encontrado"
fi

# Verificar fallback inseguro
echo "Verificando fallback inseguro..."
if grep -r "fallback-jwt-secret" src/ --include="*.yml" > /dev/null 2>&1; then
    log_error "Ainda existe fallback JWT inseguro!"
    grep -r "fallback-jwt-secret" src/ --include="*.yml"
else
    log_success "Nenhum fallback inseguro encontrado"
fi

# Verificar deprecated relacionados às mudanças
echo "Verificando deprecated removidos..."
DEPRECATED_COUNT=$(grep -r "@Deprecated" src/ --include="*.java" | grep -v "test" | wc -l | tr -d ' ')
log_warning "Ainda existem $DEPRECATED_COUNT items deprecated (alguns podem ser intencionais)"

# Verificar stubs UnsupportedOperationException
echo "Verificando stubs não implementados..."
if grep -r "UnsupportedOperationException.*não implementad" src/ --include="*.java" > /dev/null 2>&1; then
    log_error "Ainda existem stubs não implementados!"
    grep -r "UnsupportedOperationException.*não implementad" src/ --include="*.java"
else
    log_success "Nenhum stub UnsupportedOperationException encontrado"
fi

# Verificar arquivos removidos
echo "Verificando arquivos removidos..."
if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/AzureKeyVaultConfig.java" ]; then
    log_error "AzureKeyVaultConfig.java ainda existe!"
else
    log_success "AzureKeyVaultConfig.java removido corretamente"
fi

if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/VerificadorAzureStartup.java" ]; then
    log_error "VerificadorAzureStartup.java ainda existe!"
else
    log_success "VerificadorAzureStartup.java removido corretamente"
fi

if [ -f "src/main/resources/application-dev.yml.backup" ]; then
    log_error "application-dev.yml.backup ainda existe!"
else
    log_success "application-dev.yml.backup removido corretamente"
fi

# Verificar arquivos deprecated movidos
echo "Verificando scripts deprecated..."
if [ -f "scripts/deprecated/test-azure-keyvault.sh" ] && [ -f "scripts/deprecated/test-azure-connectivity.sh" ]; then
    log_success "Scripts movidos para deprecated/ corretamente"
else
    log_error "Scripts não foram movidos para deprecated/"
fi

if [ -f "scripts/deprecated/README.md" ]; then
    log_success "README.md criado em deprecated/"
else
    log_error "README.md não encontrado em deprecated/"
fi

# Verificar arquivos criados
echo "Verificando arquivos criados..."
if [ -f "scripts/backup-config.sh" ] && [ -x "scripts/backup-config.sh" ]; then
    log_success "Script backup-config.sh criado e executável"
else
    log_error "Script backup-config.sh não encontrado ou sem permissão"
fi

if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/azure/ServicoHealthCheckAzure.java" ]; then
    log_success "ServicoHealthCheckAzure.java criado"
else
    log_error "ServicoHealthCheckAzure.java não encontrado"
fi

if [ -f "CHANGELOG.md" ]; then
    log_success "CHANGELOG.md criado"
else
    log_error "CHANGELOG.md não encontrado"
fi

# Executar build
echo "Verificando build..."
if mvn clean compile -q > /dev/null 2>&1; then
    log_success "Build executado com sucesso"
else
    log_error "Build falhando!"
    echo "Execute 'mvn clean compile' para ver detalhes do erro"
fi

# Verificar classe com builder pattern
echo "Verificando builder pattern..."
if grep -q "public ResultadoMegaSena(" src/main/java/br/tec/facilitaservicos/conexaodesorte/modelo/resultado/loteria/ResultadoMegaSena.java; then
    log_error "ResultadoMegaSena ainda tem construtores públicos!"
else
    log_success "ResultadoMegaSena usa apenas builder pattern"
fi

# Relatório final
echo ""
echo "======================================"
echo "📊 RELATÓRIO DE VALIDAÇÃO"
echo "======================================"
echo -e "${GREEN}✅ Sucessos: $success_count${NC}"
echo -e "${YELLOW}⚠️  Avisos: $warning_count${NC}"
echo -e "${RED}❌ Erros: $error_count${NC}"
echo ""

if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}🎉 Validação completa com sucesso!${NC}"
    echo "✅ Todos os critérios de limpeza de código foram atendidos"
    exit 0
else
    echo -e "${RED}❌ Validação falhou!${NC}"
    echo "Corrija os erros acima antes de fazer merge"
    exit 1
fi 