#!/usr/bin/env bash
set -euo pipefail

# 🔐 Sync Azure Key Vault Secrets - Padronização Conexão de Sorte
# Sincroniza segredos do Azure Key Vault seguindo nomenclatura padronizada
# Baseado em: SEGREDOS_PADRONIZADOS.md

VAULT_NAME=${1:-}
SERVICE_PREFIX=${2:-}

if [ -z "$VAULT_NAME" ] || [ -z "$SERVICE_PREFIX" ]; then
    echo "❌ Uso: $0 <vault-name> <service-prefix>"
    echo "📋 Exemplo: $0 kv-conexao-de-sorte gateway"
    exit 1
fi

echo "🔐 Sincronizando segredos do Azure Key Vault: $VAULT_NAME"
echo "🏷️  Prefixo do serviço: $SERVICE_PREFIX"

# Função para verificar/criar segredo
sync_secret() {
    local secret_name="$1"
    local description="$2"

    echo "🔍 Verificando segredo: $secret_name"

    if az keyvault secret show --vault-name "$VAULT_NAME" --name "$secret_name" >/dev/null 2>&1; then
        echo "✅ Segredo '$secret_name' já existe"
    else
        echo "⚠️  Segredo '$secret_name' não existe - requer criação manual"
        echo "   📝 Descrição: $description"
        echo "   🔧 Comando: az keyvault secret set --vault-name '$VAULT_NAME' --name '$secret_name' --value 'VALOR_AQUI'"
    fi
}

echo ""
echo "🔴 === REDIS CONFIGURATION ==="
sync_secret "conexao-de-sorte-redis-host" "Host do Redis (ex: conexao-redis)"
sync_secret "conexao-de-sorte-redis-port" "Porta do Redis (ex: 6379)"
sync_secret "conexao-de-sorte-redis-password" "Senha do Redis"
sync_secret "conexao-de-sorte-redis-database" "Database do Redis (ex: 1)"

echo ""
echo "🔴 === DATABASE CONFIGURATION ==="
sync_secret "conexao-de-sorte-database-jdbc-url" "JDBC URL (ex: jdbc:mysql://conexao-mysql:3306/dbname)"
sync_secret "conexao-de-sorte-database-r2dbc-url" "R2DBC URL (ex: r2dbc:mysql://conexao-mysql:3306/dbname)"
sync_secret "conexao-de-sorte-database-username" "Usuário do banco de dados"
sync_secret "conexao-de-sorte-database-password" "Senha do banco de dados"
sync_secret "conexao-de-sorte-database-host" "Host do banco (ex: conexao-mysql)"
sync_secret "conexao-de-sorte-database-port" "Porta do banco (ex: 3306)"

echo ""
echo "🔴 === JWT CONFIGURATION ==="
sync_secret "conexao-de-sorte-jwt-secret" "JWT Secret Key"
sync_secret "conexao-de-sorte-jwt-issuer" "JWT Issuer URL (ex: https://auth.conexaodesorte.com.br)"
sync_secret "conexao-de-sorte-jwt-jwks-uri" "JWKS URI (ex: https://auth.conexaodesorte.com.br/.well-known/jwks.json)"
sync_secret "conexao-de-sorte-jwt-key-id" "JWT Key ID (ex: gateway-key)"
sync_secret "conexao-de-sorte-jwt-signing-key" "JWT Signing Key"
sync_secret "conexao-de-sorte-jwt-verification-key" "JWT Verification Key"
sync_secret "conexao-de-sorte-jwt-privateKey" "JWT Private Key"
sync_secret "conexao-de-sorte-jwt-publicKey" "JWT Public Key"

echo ""
echo "🔴 === CORS & SSL CONFIGURATION ==="
sync_secret "conexao-de-sorte-cors-allowed-origins" "CORS Allowed Origins (ex: https://conexaodesorte.com.br,https://www.conexaodesorte.com.br)"
sync_secret "conexao-de-sorte-cors-allow-credentials" "CORS Allow Credentials (ex: true)"
sync_secret "conexao-de-sorte-ssl-enabled" "SSL Enabled (ex: false)"
sync_secret "conexao-de-sorte-ssl-keystore-path" "SSL Keystore Path"
sync_secret "conexao-de-sorte-ssl-keystore-password" "SSL Keystore Password"

echo ""
echo "🔴 === ENCRYPTION CONFIGURATION ==="
sync_secret "conexao-de-sorte-encryption-master-key" "Master Encryption Key"
sync_secret "conexao-de-sorte-encryption-master-password" "Master Encryption Password"
sync_secret "conexao-de-sorte-encryption-backup-key" "Backup Encryption Key"

echo ""
echo "🎯 === RESUMO DA SINCRONIZAÇÃO ==="
echo "✅ Verificação concluída para o Azure Key Vault: $VAULT_NAME"
echo "📋 Segredos seguem padrão: SEGREDOS_PADRONIZADOS.md"
echo "🔧 Para criar segredos ausentes, use os comandos 'az keyvault secret set' mostrados acima"
echo ""
echo "💡 DICA: Execute este script regularmente para garantir consistência"
echo "📖 Documentação: SEGREDOS_PADRONIZADOS.md"