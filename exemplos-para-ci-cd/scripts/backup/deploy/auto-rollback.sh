#!/bin/bash

# ============================================================================
# 🔄 AUTO ROLLBACK - DEPLOY WORKFLOW
# ============================================================================
# Este script executa rollback automático quando loops infinitos ou falhas
# críticas são detectadas durante o deploy.
# ============================================================================

set -euo pipefail

# Configurações
CONTAINER_NAME="${1:-backend-prod}"
DEPLOY_TYPE="${2:-prod}"
BACKUP_IMAGE_TAG="${3:-}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Função para encontrar a última imagem funcional
find_last_working_image() {
    local deploy_type="$1"
    
    log "🔍 Procurando última imagem funcional..."
    
    local image_pattern
    if [[ "$deploy_type" == "prod" ]]; then
        image_pattern="facilita/conexao-de-sorte-backend"
    else
        image_pattern="facilita/conexao-de-sorte-backend-teste"
    fi
    
    # Se foi fornecida uma tag de backup específica, usar ela
    if [[ -n "$BACKUP_IMAGE_TAG" ]]; then
        local backup_image="$image_pattern:$BACKUP_IMAGE_TAG"
        if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^$backup_image$"; then
            echo "$backup_image"
            return 0
        else
            warning "Imagem de backup especificada não encontrada: $backup_image"
        fi
    fi
    
    # Procurar imagens disponíveis (excluindo a atual que falhou)
    local current_image
    current_image=$(docker inspect "$CONTAINER_NAME" --format='{{.Config.Image}}' 2>/dev/null || echo "")
    
    local available_images
    available_images=$(docker images "$image_pattern" --format '{{.Repository}}:{{.Tag}}' | grep -v "^$current_image$" | head -3)
    
    if [[ -z "$available_images" ]]; then
        error "Nenhuma imagem de backup encontrada para rollback!"
        return 1
    fi
    
    # Retornar a primeira imagem disponível (mais recente)
    echo "$available_images" | head -1
    return 0
}

# Função para executar rollback
execute_rollback() {
    local container_name="$1"
    local deploy_type="$2"
    
    log "🔄 Iniciando rollback automático..."
    log "   Container: $container_name"
    log "   Deploy type: $deploy_type"
    
    # Encontrar imagem para rollback
    local rollback_image
    if ! rollback_image=$(find_last_working_image "$deploy_type"); then
        error "Não foi possível encontrar imagem para rollback!"
        return 1
    fi
    
    log "📦 Imagem para rollback: $rollback_image"
    
    # Parar container atual
    log "🛑 Parando container com falha..."
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    
    # Configurar variáveis baseadas no tipo de deploy
    local port
    local profile
    local router_rule
    local service_name
    
    if [[ "$deploy_type" == "prod" ]]; then
        port="8080"
        profile="prod,azure"
        router_rule="(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/rest\`)"
        service_name="backend-prod"
    else
        port="8081"
        profile="teste,azure"
        router_rule="(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste/rest\`)"
        service_name="backend-teste"
    fi
    
    # Recriar container com imagem de rollback
    log "🔧 Recriando container com imagem de rollback..."
    docker run -d \
      --name "$container_name" \
      --network conexao-network \
      --restart unless-stopped \
      -p "$port:8080" \
      --health-cmd='curl -f http://localhost:8080/actuator/health || exit 1' \
      --health-interval=60s \
      --health-timeout=30s \
      --health-retries=3 \
      --health-start-period=120s \
      -e SPRING_PROFILES_ACTIVE="$profile" \
      -e ENVIRONMENT=production \
      -e SERVER_PORT=8080 \
      -e AZURE_KEYVAULT_ENABLED=true \
      -e AZURE_KEYVAULT_ENDPOINT="$AZURE_KEYVAULT_ENDPOINT" \
      -e AZURE_CLIENT_ID="$AZURE_CLIENT_ID" \
      -e AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET" \
      -e AZURE_TENANT_ID="$AZURE_TENANT_ID" \
      -e AZURE_KEYVAULT_FALLBACK_ENABLED=true \
      -e SPRING_DATASOURCE_URL="jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo" \
      -e SPRING_DATASOURCE_USERNAME="$CONEXAO_DE_SORTE_DATABASE_USERNAME" \
      -e SPRING_DATASOURCE_PASSWORD="$CONEXAO_DE_SORTE_DATABASE_PASSWORD" \
      -e APP_ENCRYPTION_MASTER_PASSWORD="$APP_ENCRYPTION_MASTER_PASSWORD" \
      -e JWT_ISSUER="http://localhost:8080" \
      -e JWT_AUDIENCE="conexao-de-sorte" \
      -e JWT_ALGORITHM="RS256" \
      -e JWT_SECRET="" \
      -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC" \
      -e TZ=America/Sao_Paulo \

      "$rollback_image"
    
    # Aguardar inicialização
    log "⏳ Aguardando inicialização do rollback..."
    sleep 30
    
    # Verificar se rollback foi bem-sucedido
    local max_attempts=12
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if docker ps --format '{{.Names}}\t{{.Status}}' | grep "$container_name" | grep -q "Up"; then
            local health_status
            health_status=$(docker inspect "$container_name" --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
            
            if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "none" ]]; then
                success "✅ Rollback executado com sucesso!"
                success "   Container: $container_name"
                success "   Imagem: $rollback_image"
                success "   Status: $(docker ps --format '{{.Status}}' --filter name="$container_name")"
                return 0
            fi
        fi
        
        ((attempt++))
        log "🔄 Tentativa $attempt/$max_attempts - aguardando rollback..."
        sleep 10
    done
    
    error "❌ Rollback falhou! Container não ficou saudável."
    return 1
}

# Função para gerar relatório de rollback
generate_rollback_report() {
    local container_name="$1"
    local deploy_type="$2"
    local rollback_image="$3"
    
    log "📋 Gerando relatório de rollback..."
    
    cat << EOF

# 🔄 RELATÓRIO DE ROLLBACK AUTOMÁTICO

## Informações do Rollback
- **Data/Hora**: $(date +'%Y-%m-%d %H:%M:%S %Z')
- **Container**: $container_name
- **Tipo de Deploy**: $deploy_type
- **Imagem de Rollback**: $rollback_image

## Status Atual
- **Container Status**: $(docker ps --format '{{.Status}}' --filter name="$container_name" 2>/dev/null || echo "Não encontrado")
- **Health Status**: $(docker inspect "$container_name" --format='{{.State.Health.Status}}' 2>/dev/null || echo "N/A")
- **Restart Count**: $(docker inspect "$container_name" --format='{{.RestartCount}}' 2>/dev/null || echo "N/A")

## Logs Recentes (últimas 20 linhas)
\`\`\`
$(docker logs "$container_name" --tail 20 2>/dev/null || echo "Logs não disponíveis")
\`\`\`

## Ação Requerida
⚠️ **ATENÇÃO**: Um rollback automático foi executado devido à detecção de problemas no deploy.
Por favor, investigue a causa raiz antes de tentar um novo deploy.

EOF
}

# Função principal
main() {
    log "🚀 Iniciando processo de rollback automático..."
    
    # Verificar se container existe
    if ! docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        error "Container $CONTAINER_NAME não encontrado!"
        exit 1
    fi
    
    # Executar rollback
    if execute_rollback "$CONTAINER_NAME" "$DEPLOY_TYPE"; then
        # Gerar relatório
        local rollback_image
        rollback_image=$(docker inspect "$CONTAINER_NAME" --format='{{.Config.Image}}' 2>/dev/null || echo "unknown")
        generate_rollback_report "$CONTAINER_NAME" "$DEPLOY_TYPE" "$rollback_image"
        
        success "🎉 Rollback automático concluído com sucesso!"
        exit 0
    else
        error "💥 Rollback automático falhou!"
        exit 1
    fi
}

# Verificar se script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
