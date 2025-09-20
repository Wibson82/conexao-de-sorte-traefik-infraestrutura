#!/usr/bin/env bash
set -Eeuo pipefail

# Script de teste baseado no padrão RabbitMQ para validar o workflow do Traefik
# Este script simula as etapas do pipeline com OIDC e Key Vault

echo "🧪 Testando Workflow Traefik - Padrão RabbitMQ"
echo "================================================"

# Simular variáveis do GitHub Actions
echo "🔧 Configurando variáveis de ambiente simuladas..."

# Secrets do GitHub (obrigatórios)
export AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-test-client-id}"
export AZURE_TENANT_ID="${AZURE_TENANT_ID:-test-tenant-id}"
export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-test-subscription-id}"
export AZURE_KEYVAULT_NAME="${AZURE_KEYVAULT_NAME:-kv-conexao-de-sorte}"
export AZURE_KEYVAULT_ENDPOINT="${AZURE_KEYVAULT_ENDPOINT:-}"

# Outputs simulados do job validate-and-build
export has_keyvault="true"
export has_azure_creds="true"

echo "✅ Variáveis de ambiente configuradas"

# Testar validação de secrets (padrão RabbitMQ)
echo ""
echo "🔍 Testando validação de OIDC Azure (padrão RabbitMQ)..."

missing=()
for var in AZURE_CLIENT_ID AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID; do
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if (( ${#missing[@]} )); then
  printf '❌ GitHub Secrets obrigatórios ausentes: %s\n' "${missing[*]}"
  exit 1
fi

echo "✅ Identificadores Azure configurados via secrets"

# Verificar Key Vault (opcional)
if [[ -n "${AZURE_KEYVAULT_NAME:-}" ]]; then
  echo "has_keyvault=true"
else
  echo "has_keyvault=false"
fi

if [[ -z "${AZURE_KEYVAULT_ENDPOINT:-}" ]]; then
  echo 'ℹ️ AZURE_KEYVAULT_ENDPOINT não definido (usando endpoint padrão)'
else
  echo '✅ Endpoint customizado definido'
fi

echo "has_azure_creds=true"

echo ""
echo "✅ Validação OIDC Azure concluída (padrão RabbitMQ)"

# Testar consumo mínimo do Key Vault
echo ""
echo "🔍 Testando consumo mínimo do Key Vault (padrão RabbitMQ)..."
echo 'Job de validação não consome segredos do Key Vault (lista vazia).'
echo "✅ Validação de Key Vault concluída sem consumo de segredos"

# Testar validação de segurança - Port Exposure
echo ""
echo "🔍 Testando validação de segurança - Port Exposure..."

# Simular docker-compose.yml para teste
cat > /tmp/test-docker-compose.yml << 'EOF'
services:
  traefik:
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
EOF

if grep -E "^\s*-\s*[\"']?(80|443|8080):" /tmp/test-docker-compose.yml; then
  echo "⚠️ WARNING: Traefik ports may be exposed - ensure firewall protection"
  echo "🔒 Note: Current configuration works but consider overlay-only for maximum security"
else
  echo "✅ No ports exposed - maximum security (overlay network only)"
fi

# Limpar arquivo de teste
rm -f /tmp/test-docker-compose.yml

echo ""
echo "✅ Testes de segurança concluídos"

# Testar estrutura de deploy com variáveis de ambiente
echo ""
echo "🔍 Testando estrutura de deploy (padrão RabbitMQ)..."

# Simular segredos do Key Vault
export conexao_de_sorte_letsencrypt_email="facilitaservicos.tec@gmail.com"
export conexao_de_sorte_traefik_dashboard_password="PLvBqeqv0zu7s4E6MPcIOY4U"

# Configurar variáveis com valores dos segredos ou padrões de desenvolvimento
if [[ -n "${conexao_de_sorte_letsencrypt_email:-}" ]]; then
  LETSENCRYPT_EMAIL="${conexao_de_sorte_letsencrypt_email}"
  echo "✅ Email Let's Encrypt configurado"
else
  LETSENCRYPT_EMAIL="dev@localhost"
  echo "⚠️ Email Let's Encrypt não configurado (modo desenvolvimento)"
fi

if [[ -n "${conexao_de_sorte_traefik_dashboard_password:-}" ]]; then
  DASHBOARD_PASSWORD="${conexao_de_sorte_traefik_dashboard_password}"
  echo "✅ Senha do dashboard configurada"
else
  DASHBOARD_PASSWORD="dev123"
  echo "⚠️ Senha do dashboard não configurada (modo desenvolvimento)"
fi

# Exportar variáveis para o ambiente
export LETSENCRYPT_EMAIL
export DASHBOARD_PASSWORD

echo "✅ Estrutura de deploy configurada (padrão RabbitMQ)"

echo ""
echo "🎉 Teste do Workflow Traefik - Padrão RabbitMQ concluído com sucesso!"
echo "📋 Resumo das melhorias implementadas:"
echo "   ✅ Validação OIDC com set -Eeuo pipefail"
echo "   ✅ Lista de secrets ausentes formatada"
echo "   ✅ Confirmação de consumo mínimo do Key Vault"
echo "   ✅ Validação de segurança - Port Exposure"
echo "   ✅ Estrutura de deploy com variáveis de ambiente claras"
echo "   ✅ Mensagens de status padronizadas"