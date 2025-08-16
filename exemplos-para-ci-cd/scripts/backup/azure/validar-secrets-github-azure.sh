#!/bin/bash

# 🔐 Script de Validação Cruzada - GitHub Secrets vs Azure Key Vault
# ✅ Compara valores entre GitHub Actions Secrets e Azure Key Vault
# ✅ Identifica inconsistências e sugere correções
# ✅ Garante sincronização entre ambientes

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] 🔐 Validação:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ Validação:${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  Validação:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ Validação:${NC} $1" >&2
}

# Configurações
readonly REQUIRED_VARS=(
    "AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET" 
    "AZURE_TENANT_ID"
    "AZURE_KEYVAULT_ENDPOINT"
)

# Mapeamento GitHub Secrets -> Azure Key Vault
# NOTA: DATABASE credentials removidas - usando apenas GitHub Secrets
# NOTA: DATABASE_URL removida - usando hostname Docker interno 'mysql:3306'
declare -A SECRETS_MAPPING=(
    ["CONEXAO_DE_SORTE_JWT_PRIVATE_KEY"]="conexao-de-sorte-jwt-private-key"
    ["CONEXAO_DE_SORTE_JWT_PUBLIC_KEY"]="conexao-de-sorte-jwt-public-key"
)

# Verificar pré-requisitos
check_prerequisites() {
    log "Verificando pré-requisitos..."
    
    # Verificar Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI não encontrado. Instale: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi
    
    # Verificar login Azure
    if ! az account show &> /dev/null; then
        log_error "Não logado no Azure. Execute: az login"
        return 1
    fi
    
    # Verificar variáveis de ambiente
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variável de ambiente $var não definida"
            return 1
        fi
    done
    
    log_success "Pré-requisitos verificados"
}

# Obter secret do Azure Key Vault
get_azure_secret() {
    local secret_name="$1"
    local keyvault_name
    
    # Extrair nome do Key Vault da URL
    keyvault_name=$(echo "$AZURE_KEYVAULT_ENDPOINT" | sed 's|https://||' | sed 's|\.vault\.azure\.net/||')
    
    az keyvault secret show \
        --vault-name "$keyvault_name" \
        --name "$secret_name" \
        --query "value" \
        --output tsv 2>/dev/null || echo ""
}

# Comparar secrets
compare_secrets() {
    log "Comparando secrets entre GitHub e Azure Key Vault..."
    
    local inconsistencies=0
    local total_secrets=${#SECRETS_MAPPING[@]}
    
    echo ""
    echo "📊 RELATÓRIO DE COMPARAÇÃO DE SECRETS"
    echo "======================================"
    
    for github_secret in "${!SECRETS_MAPPING[@]}"; do
        local azure_secret="${SECRETS_MAPPING[$github_secret]}"
        local github_value="${!github_secret:-}"
        local azure_value
        
        echo ""
        echo "🔍 Secret: $github_secret"
        echo "   GitHub Secret: $github_secret"
        echo "   Azure Secret:  $azure_secret"
        
        if [[ -z "$github_value" ]]; then
            log_warn "GitHub Secret $github_secret não definido"
            ((inconsistencies++))
            continue
        fi
        
        azure_value=$(get_azure_secret "$azure_secret")
        
        if [[ -z "$azure_value" ]]; then
            log_warn "Azure Secret $azure_secret não encontrado"
            ((inconsistencies++))
            continue
        fi
        
        # Comparar valores (mascarando para log)
        if [[ "$github_value" == "$azure_value" ]]; then
            log_success "Valores sincronizados"
        else
            log_error "Valores diferentes!"
            echo "   GitHub: ${github_value:0:8}***"
            echo "   Azure:  ${azure_value:0:8}***"
            ((inconsistencies++))
        fi
    done
    
    echo ""
    echo "📈 RESUMO"
    echo "========="
    echo "Total de secrets verificados: $total_secrets"
    echo "Inconsistências encontradas: $inconsistencies"
    
    if [[ $inconsistencies -eq 0 ]]; then
        log_success "Todos os secrets estão sincronizados!"
        return 0
    else
        log_error "$inconsistencies inconsistências encontradas"
        return 1
    fi
}

# Gerar relatório detalhado
generate_report() {
    local report_file="secrets-validation-report-$(date +%Y%m%d-%H%M%S).md"
    
    log "Gerando relatório detalhado: $report_file"
    
    cat > "$report_file" << EOF
# 🔐 Relatório de Validação de Secrets

**Data:** $(date)
**Ambiente:** Production
**Projeto:** Conexão de Sorte

## 📋 Secrets Verificados

| GitHub Secret | Azure Key Vault Secret | Status | Observações |
|---------------|------------------------|--------|-------------|
EOF

    for github_secret in "${!SECRETS_MAPPING[@]}"; do
        local azure_secret="${SECRETS_MAPPING[$github_secret]}"
        local github_value="${!github_secret:-}"
        local azure_value
        local status="❌ Não verificado"
        local obs="N/A"
        
        if [[ -n "$github_value" ]]; then
            azure_value=$(get_azure_secret "$azure_secret")
            
            if [[ -n "$azure_value" ]]; then
                if [[ "$github_value" == "$azure_value" ]]; then
                    status="✅ Sincronizado"
                    obs="Valores idênticos"
                else
                    status="⚠️ Divergente"
                    obs="Valores diferentes"
                fi
            else
                status="❌ Azure não encontrado"
                obs="Secret não existe no Azure Key Vault"
            fi
        else
            status="❌ GitHub não definido"
            obs="Variável de ambiente não definida"
        fi
        
        echo "| \`$github_secret\` | \`$azure_secret\` | $status | $obs |" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## 🔧 Ações Recomendadas

### Para Secrets Divergentes:
1. Verificar qual valor está correto
2. Atualizar o valor incorreto
3. Executar nova validação

### Para Secrets Não Encontrados:
1. Criar o secret no ambiente faltante
2. Configurar valor correto
3. Testar aplicação

## 📝 Comandos Úteis

### Atualizar Azure Key Vault:
\`\`\`bash
az keyvault secret set --vault-name <vault-name> --name <secret-name> --value "<value>"
\`\`\`

### Verificar GitHub Secrets:
- Acessar: https://github.com/Wibson82/conexao-de-sorte-backend/settings/secrets/actions
- Verificar valores configurados

EOF

    log_success "Relatório gerado: $report_file"
}

# Função principal
main() {
    log "Iniciando validação cruzada de secrets..."
    
    # Verificar pré-requisitos
    if ! check_prerequisites; then
        log_error "Falha nos pré-requisitos"
        exit 1
    fi
    
    # Comparar secrets
    local comparison_result=0
    compare_secrets || comparison_result=$?
    
    # Gerar relatório
    generate_report
    
    if [[ $comparison_result -eq 0 ]]; then
        log_success "Validação concluída com sucesso!"
        exit 0
    else
        log_error "Validação encontrou inconsistências"
        exit 1
    fi
}

# Executar função principal se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
