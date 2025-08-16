#!/bin/bash
set -euo pipefail

echo "🚀 [$(date)] Iniciando aplicação backend..."

# Detectar ambiente baseado em variáveis
if [[ "${ENVIRONMENT:-dev}" == "production" ]] || [[ "${SPRING_PROFILES_ACTIVE:-}" == *"prod"* ]]; then
    echo "🏭 [$(date)] Modo: PRODUÇÃO"
    DETECTED_ENV="production"
else
    echo "🔍 [$(date)] Modo: DESENVOLVIMENTO"
    DETECTED_ENV="development"
fi

# OVERRIDE: Se ENVIRONMENT=production, sempre mostrar PRODUÇÃO
if [[ "${ENVIRONMENT:-}" == "production" ]]; then
    echo "🏭 [$(date)] OVERRIDE: Forçando modo PRODUÇÃO (ENVIRONMENT=production)"
    DETECTED_ENV="production"
fi

# Verificar se estamos em ambiente de produção com Docker Swarm
if [[ "${DETECTED_ENV}" == "production" ]] && [[ -d "/run/secrets" ]]; then
    echo "🔐 [$(date)] Modo PRODUÇÃO: Carregando secrets do Docker Swarm..."
    
    # Lista de secrets necessários (Managed Identity + fallback Service Principal)
    required_secrets=(
      AZURE_KEYVAULT_ENDPOINT
      AZURE_CLIENT_ID
      AZURE_CLIENT_SECRET
      AZURE_TENANT_ID
    )
    
    load_secret() {
      local name="$1"
      local file="/run/secrets/$name"

      if [[ ! -r "$file" ]]; then
        echo "⚠️  [$(date)] Secret $file não encontrado - usando fallback" >&2
        return 1
      fi

      local value
      value=$(cat "$file")
      printf '%s' "$value"
    }
    
    # Carregar secrets do Docker Swarm (Managed Identity primeiro)
    if AZURE_KEYVAULT_ENDPOINT=$(load_secret AZURE_KEYVAULT_ENDPOINT 2>/dev/null); then
        echo "✅ [$(date)] Azure Key Vault endpoint carregado"
        export AZURE_KEYVAULT_ENDPOINT="$AZURE_KEYVAULT_ENDPOINT"
        export AZURE_MANAGED_IDENTITY_ENABLED=true
    else
        echo "❌ [$(date)] AZURE_KEYVAULT_ENDPOINT obrigatório não encontrado"
        exit 1
    fi
    
    # Carregar Service Principal como fallback (opcional)
    if AZURE_CLIENT_ID=$(load_secret AZURE_CLIENT_ID 2>/dev/null); then
        export AZURE_CLIENT_ID="$AZURE_CLIENT_ID"
        if AZURE_CLIENT_SECRET=$(load_secret AZURE_CLIENT_SECRET 2>/dev/null); then
            export AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET"
            if AZURE_TENANT_ID=$(load_secret AZURE_TENANT_ID 2>/dev/null); then
                export AZURE_TENANT_ID="$AZURE_TENANT_ID"
                echo "✅ [$(date)] Service Principal carregado como fallback"
            fi
        fi
    else
        echo "ℹ️  [$(date)] Service Principal não configurado - usando apenas Managed Identity"
    fi
    
    echo "✅ [$(date)] Secrets do Docker Swarm carregados"
else
    if [[ "${DETECTED_ENV}" == "production" ]]; then
        echo "🏭 [$(date)] Modo PRODUÇÃO: Usando variáveis de ambiente (sem Docker Swarm)"
    else
        echo "🛠️ [$(date)] Modo DESENVOLVIMENTO: Usando variáveis de ambiente para Azure Key Vault"
    fi
    
    # Verificar se o endpoint do Azure Key Vault está definido
    if [[ -n "${AZURE_KEYVAULT_ENDPOINT:-}" ]]; then
        echo "✅ [$(date)] Azure Key Vault endpoint encontrado - ativando Managed Identity"
        export AZURE_MANAGED_IDENTITY_ENABLED=true
        export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-dev}"
    else
        echo "⚠️  [$(date)] Azure Key Vault não configurado - usando configurações locais"
        export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-dev}"
    fi
fi

echo "📊 [$(date)] Profile ativo: ${SPRING_PROFILES_ACTIVE}"
echo "🌍 [$(date)] Plataforma: ${DOCKER_PLATFORM:-desconhecida}"
echo "🗄️  [$(date)] Banco de dados: ${SPRING_DATASOURCE_URL:-${CONEXAO_DE_SORTE_DATABASE_URL:-configurado via secrets}}"

if [[ -n "${AZURE_KEYVAULT_ENDPOINT:-}" ]]; then
    echo "🔐 [$(date)] Azure Key Vault: ${AZURE_KEYVAULT_ENDPOINT}"
else
    echo "⚠️  [$(date)] Azure Key Vault não configurado - usando configurações locais"
fi

# Verificar se o JAR existe
if [[ ! -f "/app/app.jar" ]]; then
    echo "❌ [$(date)] Arquivo JAR não encontrado em /app/app.jar"
    exit 1
fi

echo "✅ [$(date)] Iniciando aplicação Spring Boot com método compatível..."
echo "🔧 [$(date)] JAVA_OPTS: ${JAVA_OPTS:-sem opções específicas}"

# Executar a aplicação Spring Boot usando o método mais compatível
exec java ${JAVA_OPTS:-} -jar /app/app.jar
