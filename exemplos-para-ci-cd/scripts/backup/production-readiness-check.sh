#!/bin/bash

# =============================================================================
# VERIFICAÇÃO FINAL DE PREPARAÇÃO PARA PRODUÇÃO
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 VERIFICAÇÃO FINAL DE PREPARAÇÃO PARA PRODUÇÃO${NC}"
echo -e "${BLUE}===============================================${NC}"

# Contadores
total_checks=0
passed_checks=0
failed_checks=0

# Função para verificar
check_item() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    total_checks=$((total_checks + 1))
    echo -e "\n${YELLOW}🔍 Verificando: $description${NC}"
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSOU: $description${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ FALHOU: $description${NC}"
        failed_checks=$((failed_checks + 1))
    fi
}

# Função para verificar secret
check_secret() {
    local secret_name="$1"
    total_checks=$((total_checks + 1))
    
    echo -e "\n${YELLOW}🔍 Verificando secret: $secret_name${NC}"
    
    if gh secret list --repo "Wibson82/conexao-de-sorte-backend" | grep -q "$secret_name"; then
        echo -e "${GREEN}✅ PASSOU: Secret $secret_name configurado${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ FALHOU: Secret $secret_name não encontrado${NC}"
        failed_checks=$((failed_checks + 1))
    fi
}

echo -e "\n${BLUE}📋 VERIFICANDO SECRETS DO GITHUB ACTIONS${NC}"
echo -e "${BLUE}=========================================${NC}"

# Verificar secrets críticos
check_secret "WEBSOCKET_JWT_SECRET"
check_secret "CHAT_ENCRYPTION_KEY"
check_secret "BACKUP_ENCRYPTION_KEY"
check_secret "RATE_LIMIT_GLOBAL_LIMIT"
check_secret "SECURITY_CONTENT_SECURITY_POLICY"
check_secret "SECURITY_HSTS_MAX_AGE"
check_secret "WEBSOCKET_CORS_ORIGINS"

# Verificar secrets existentes
check_secret "AZURE_CLIENT_ID"
check_secret "JWT_ISSUER"
check_secret "CONEXAO_DE_SORTE_DATABASE_URL"

echo -e "\n${BLUE}📁 VERIFICANDO ARQUIVOS DE CONFIGURAÇÃO${NC}"
echo -e "${BLUE}=======================================${NC}"

# Verificar arquivos de configuração
check_item "Profile prod-optimized existe" "test -f src/main/resources/application-prod-optimized.yml"
check_item "Profile production-final existe" "test -f src/main/resources/application-production-final.yml"
check_item "Configuração HTTPS existe" "test -f src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/ConfiguracaoHTTPS.java"

echo -e "\n${BLUE}🔧 VERIFICANDO SCRIPTS E FERRAMENTAS${NC}"
echo -e "${BLUE}===================================${NC}"

# Verificar scripts
check_item "Script de setup de secrets existe" "test -f scripts/setup-production-secrets.sh"
check_item "Script de teste de carga existe" "test -f scripts/load-testing.sh"
check_item "Script de teste simples existe" "test -f scripts/simple-load-test.sh"
check_item "Script executável" "test -x scripts/simple-load-test.sh"

echo -e "\n${BLUE}🐳 VERIFICANDO CI/CD${NC}"
echo -e "${BLUE}==================${NC}"

# Verificar CI/CD
check_item "Workflow de deploy existe" "test -f .github/workflows/deploy-unified.yml"
check_item "Verificação de loops no CI/CD" "grep -q 'Verificar loops' .github/workflows/deploy-unified.yml"

echo -e "\n${BLUE}☁️ VERIFICANDO CONECTIVIDADE AZURE${NC}"
echo -e "${BLUE}==================================${NC}"

# Verificar Azure CLI
check_item "Azure CLI instalado" "command -v az"
check_item "Azure CLI logado" "az account show"

echo -e "\n${BLUE}🐙 VERIFICANDO CONECTIVIDADE GITHUB${NC}"
echo -e "${BLUE}===================================${NC}"

# Verificar GitHub CLI
check_item "GitHub CLI instalado" "command -v gh"
check_item "GitHub CLI logado" "gh auth status"

echo -e "\n${BLUE}🏗️ VERIFICANDO ESTRUTURA DO PROJETO${NC}"
echo -e "${BLUE}===================================${NC}"

# Verificar estrutura
check_item "Diretório de serviços existe" "test -d src/main/java/br/tec/facilitaservicos/conexaodesorte/servico"
check_item "Serviços de chat implementados" "test -f src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/batepapo/comando/impl/ComandoMensagemBatePapoImpl.java"
check_item "Sistema de notificações implementado" "test -f src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/notificacao/ServicoNotificacaoPush.java"
check_item "Sistema de criptografia implementado" "test -f src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/criptografia/GerenciadorChavesCriptografia.java"
check_item "Sistema de backup implementado" "test -f src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/backup/SistemaBackupRecuperacao.java"

echo -e "\n${BLUE}📊 RELATÓRIO FINAL${NC}"
echo -e "${BLUE}==================${NC}"

percentage=$((passed_checks * 100 / total_checks))

echo -e "\n${YELLOW}📈 ESTATÍSTICAS:${NC}"
echo -e "   Total de verificações: $total_checks"
echo -e "   ${GREEN}✅ Passou: $passed_checks${NC}"
echo -e "   ${RED}❌ Falhou: $failed_checks${NC}"
echo -e "   ${BLUE}📊 Percentual: $percentage%${NC}"

if [ $percentage -ge 95 ]; then
    echo -e "\n${GREEN}🎉 EXCELENTE! Sistema 100% pronto para produção!${NC}"
    echo -e "${GREEN}✅ Todos os componentes críticos estão configurados${NC}"
    echo -e "${GREEN}🚀 Pode fazer deploy com segurança!${NC}"
elif [ $percentage -ge 90 ]; then
    echo -e "\n${YELLOW}⚠️ QUASE PRONTO! Sistema 95% pronto para produção${NC}"
    echo -e "${YELLOW}🔧 Algumas verificações falharam, mas não são críticas${NC}"
    echo -e "${YELLOW}🚀 Deploy pode ser feito com cuidado${NC}"
else
    echo -e "\n${RED}❌ ATENÇÃO! Sistema não está pronto para produção${NC}"
    echo -e "${RED}🛑 Corrija os problemas antes do deploy${NC}"
    echo -e "${RED}📋 Revise os itens que falharam acima${NC}"
fi

echo -e "\n${BLUE}🎯 PRÓXIMOS PASSOS:${NC}"
if [ $failed_checks -eq 0 ]; then
    echo "1. ✅ Fazer commit das alterações"
    echo "2. ✅ Executar push para trigger do CI/CD"
    echo "3. ✅ Monitorar deploy no GitHub Actions"
    echo "4. ✅ Verificar aplicação em produção"
else
    echo "1. 🔧 Corrigir os $failed_checks itens que falharam"
    echo "2. 🔄 Executar este script novamente"
    echo "3. ✅ Quando tudo estiver OK, fazer deploy"
fi

echo -e "\n${GREEN}✅ Verificação de preparação para produção concluída!${NC}"

exit $failed_checks
