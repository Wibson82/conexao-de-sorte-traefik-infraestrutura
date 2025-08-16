#!/bin/bash
set -euo pipefail

# Script simplificado para iniciar a aplicação Spring Boot
# Resolve problemas de compatibilidade com diferentes versões do Spring Boot

echo "🚀 [$(date)] Iniciando Conexão de Sorte Backend..."

# Verificar Java
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java não encontrado!"
    exit 1
fi

echo "☕ Java version: $(java -version 2>&1 | head -n 1)"

# Verificar JAR
JAR_FILE="/app/app.jar"
if [[ ! -f "$JAR_FILE" ]]; then
    echo "❌ JAR não encontrado: $JAR_FILE"
    exit 1
fi

echo "📦 JAR encontrado: $JAR_FILE"
echo "📊 Tamanho do JAR: $(du -h "$JAR_FILE" | cut -f1)"

# 🔐 CARREGAR ENDPOINT DO AZURE KEY VAULT (OBRIGATÓRIO)
# Tentar primeiro variável de ambiente (Docker Compose), depois Docker Secret (Swarm)
if [[ -n "${AZURE_KEYVAULT_ENDPOINT:-}" ]]; then
    echo "✅ Azure Key Vault endpoint carregado da variável de ambiente"
    echo "🔑 Endpoint: ${AZURE_KEYVAULT_ENDPOINT:0:20}..."
    echo "🌍 Ambiente: ${ENVIRONMENT:-dev} - Usando Azure Key Vault com DefaultAzureCredential"
elif [[ -f "/run/secrets/AZURE_KEYVAULT_ENDPOINT" ]]; then
    AZURE_KEYVAULT_ENDPOINT=$(cat /run/secrets/AZURE_KEYVAULT_ENDPOINT)
    export AZURE_KEYVAULT_ENDPOINT="$AZURE_KEYVAULT_ENDPOINT"
    echo "✅ Azure Key Vault endpoint carregado do Docker Secret"
    echo "🔑 Endpoint: ${AZURE_KEYVAULT_ENDPOINT:0:20}..."
    echo "🌍 Ambiente: ${ENVIRONMENT:-dev} - Usando Azure Key Vault"
else
    echo "❌ ERRO: Azure Key Vault endpoint obrigatório não encontrado!"
    echo " Configure a variável AZURE_KEYVAULT_ENDPOINT ou o secret no Docker Swarm"
    exit 1
fi

# Configurar JAVA_OPTS padrão se não estiver definido
if [[ -z "${JAVA_OPTS:-}" ]]; then
    export JAVA_OPTS="-server -Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
    echo "🔧 JAVA_OPTS padrão aplicado: $JAVA_OPTS"
else
    echo "🔧 JAVA_OPTS: $JAVA_OPTS"
fi

# Configurar profile padrão se não estiver definido
if [[ -z "${SPRING_PROFILES_ACTIVE:-}" ]]; then
    export SPRING_PROFILES_ACTIVE="dev"
    echo "📊 Profile padrão aplicado: $SPRING_PROFILES_ACTIVE"
else
    echo "📊 Profile ativo: $SPRING_PROFILES_ACTIVE"
fi

echo "✅ Iniciando aplicação com Azure Key Vault unificado..."

# Método mais compatível - usar sempre -jar
exec java $JAVA_OPTS -jar "$JAR_FILE" 