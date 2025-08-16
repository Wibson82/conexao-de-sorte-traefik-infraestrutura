#!/bin/bash
set -e

echo "🔐 Atualizando secrets do MySQL para configuração padronizada..."
echo "=================================================================="

# Verificar se Docker Swarm está ativo
if ! docker info | grep -q "Swarm: active"; then
    echo "❌ Docker Swarm não está ativo. Execute: docker swarm init"
    exit 1
fi

echo "✅ Docker Swarm está ativo"

# Função para criar/atualizar segredo
update_secret() {
    local secret_name=$1
    local secret_value=$2
    
    if docker secret ls | grep -q "$secret_name"; then
        echo "🔄 Atualizando segredo: $secret_name"
        docker secret rm "$secret_name"
        sleep 2
    fi
    
    echo "$secret_value" | docker secret create "$secret_name" -
    echo "✅ Segredo '$secret_name' criado/atualizado"
}

# Obter senhas de variáveis de ambiente ou GitHub Secrets
# NUNCA usar senhas hardcoded em produção
MYSQL_ROOT_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-$(openssl rand -base64 32)}"
MYSQL_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_USERNAME_PASSWORD:-$(openssl rand -base64 32)}"

# Verificar se as senhas foram fornecidas
if [[ -z "$MYSQL_ROOT_PASSWORD" ]] || [[ "$MYSQL_ROOT_PASSWORD" == *"openssl"* ]]; then
    echo "❌ ERRO: CONEXAO_DE_SORTE_DATABASE_PASSWORD não definida"
    echo "📋 Configure a variável de ambiente ou GitHub Secret"
    exit 1
fi

if [[ -z "$MYSQL_PASSWORD" ]] || [[ "$MYSQL_PASSWORD" == *"openssl"* ]]; then
    echo "❌ ERRO: CONEXAO_DE_SORTE_DATABASE_USERNAME_PASSWORD não definida"
    echo "📋 Configure a variável de ambiente ou GitHub Secret"
    exit 1
fi

echo ""
echo "🔐 Configurando secrets do MySQL com valores padronizados..."
echo ""

# Atualizar secrets do MySQL
update_secret "mysql_root_password" "$MYSQL_ROOT_PASSWORD"
update_secret "mysql_password" "$MYSQL_PASSWORD"

echo ""
echo "✅ Secrets do MySQL atualizados com sucesso!"
echo ""
echo "📋 Secrets criados/atualizados:"
docker secret ls | grep mysql

echo ""
echo "🔍 Verificando configuração:"
echo "   - mysql_root_password: ${MYSQL_ROOT_PASSWORD:0:8}..."
echo "   - mysql_password: ${MYSQL_PASSWORD:0:8}..."
echo ""
echo "🚀 Agora você pode fazer o deploy do stack com as configurações padronizadas!"
echo "   docker stack deploy -c docker-compose.yml conexao-stack" 