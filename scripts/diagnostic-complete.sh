#!/bin/bash
# =============================================================================
# 🔍 DIAGNÓSTICO COMPLETO DO SERVIDOR - TUDO EM UM ENDPOINT
# =============================================================================
# Fornece TUDO que você precisa para diagnóstico remoto:
# - Containers rodando vs esperados
# - Imagens disponíveis vs em uso
# - Comandos docker run para testar
# - Logs de erro de containers falhando
# - Status completo do ambiente
# =============================================================================

set -e

# Configurações
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DOMAIN="conexaodesorte.com.br"

# Lista de projetos esperados
BACKEND_PROJECTS=(
    "conexao-gateway"
    "conexao-autenticacao"
    "conexao-resultados"
    "conexao-scheduler"
    "conexao-notificacoes"
    "conexao-batepapo"
    "conexao-chatbot"
    "conexao-observabilidade"
    "conexao-financeiro"
    "conexao-auditoria-compliance"
    "conexao-criptografia-kms"
)

INFRA_PROJECTS=(
    "conexao-mysql"
    "conexao-redis"
    "conexao-kafka"
    "conexao-zookeeper"
    "conexao-rabbitmq"
    "conexao-traefik"
    "conexao-jaeger"
    "conexao-frontend"
)

echo "# ============================================================================="
echo "# 🔍 DIAGNÓSTICO COMPLETO DO SERVIDOR - $(date)"
echo "# ============================================================================="
echo ""

# =============================================================================
# 📊 1. RESUMO EXECUTIVO
# =============================================================================
echo "## 📊 1. RESUMO EXECUTIVO"
echo ""

# Contar containers
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | wc -l)
TOTAL_CONTAINERS=$(docker ps -a --format "{{.Names}}" | wc -l)
SWARM_STATUS="não-swarm"
if docker info 2>/dev/null | grep -q "Swarm: active"; then
    SWARM_STATUS="swarm-ativo"
fi

echo "**Data/Hora**: $TIMESTAMP"
echo "**Domínio**: $DOMAIN"
echo "**Containers Rodando**: $RUNNING_CONTAINERS"
echo "**Containers Total**: $TOTAL_CONTAINERS"
echo "**Docker Swarm**: $SWARM_STATUS"
echo "**Node Role**: $(docker info 2>/dev/null | grep 'Node Role:' | awk '{print $3}' || echo 'standalone')"
echo ""

# =============================================================================
# 🐳 2. CONTAINERS RODANDO AGORA
# =============================================================================
echo "## 🐳 2. CONTAINERS RODANDO AGORA"
echo ""
echo "| Nome | Imagem | Status | Portas |"
echo "|------|--------|--------|--------|"

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while read line; do
    echo "| $(echo "$line" | tr '\t' ' | ') |"
done
echo ""

# =============================================================================
# 🚨 3. CONTAINERS PARADOS/COM PROBLEMA
# =============================================================================
echo "## 🚨 3. CONTAINERS PARADOS/COM PROBLEMA"
echo ""

STOPPED_CONTAINERS=$(docker ps -a --filter "status=exited" --format "{{.Names}}")
if [[ -z "$STOPPED_CONTAINERS" ]]; then
    echo "✅ **Nenhum container parado encontrado**"
else
    echo "| Nome | Imagem | Status | Comando para Testar |"
    echo "|------|--------|--------|---------------------|"

    docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 | while read name image status; do
        echo "| $name | $image | $status | \`docker run --rm $image\` |"
    done
fi
echo ""

# =============================================================================
# 🏗️ 4. SERVIÇOS DOCKER SWARM (se ativo)
# =============================================================================
if [[ "$SWARM_STATUS" == "swarm-ativo" ]]; then
    echo "## 🏗️ 4. SERVIÇOS DOCKER SWARM"
    echo ""
    echo "| Nome | Réplicas | Imagem | Portas |"
    echo "|------|----------|--------|--------|"

    docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}\t{{.Ports}}" | tail -n +2 | while read line; do
        echo "| $(echo "$line" | tr '\t' ' | ') |"
    done
    echo ""

    # Serviços com problema (0/1 réplicas)
    echo "### 🚨 Serviços com Problema (0/X réplicas)"
    echo ""

    FAILED_SERVICES=$(docker service ls --format "{{.Name}} {{.Replicas}}" | grep " 0/" | awk '{print $1}')
    if [[ -z "$FAILED_SERVICES" ]]; then
        echo "✅ **Todos os serviços estão rodando**"
    else
        echo "| Serviço | Réplicas | Último Erro | Comando para Debug |"
        echo "|---------|----------|-------------|--------------------| "

        for service in $FAILED_SERVICES; do
            REPLICAS=$(docker service ls --filter "name=$service" --format "{{.Replicas}}")
            LAST_ERROR=$(docker service ps "$service" --no-trunc --format "{{.Error}}" | head -1)
            if [[ -z "$LAST_ERROR" ]]; then
                LAST_ERROR="sem erro relatado"
            fi
            echo "| $service | $REPLICAS | $LAST_ERROR | \`docker service logs $service --tail 20\` |"
        done
    fi
    echo ""
fi

# =============================================================================
# 🖼️ 5. IMAGENS DISPONÍVEIS
# =============================================================================
echo "## 🖼️ 5. IMAGENS DISPONÍVEIS"
echo ""
echo "| Repository | Tag | ID | Tamanho | Comando para Testar |"
echo "|------------|-----|----|---------|--------------------|"

docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2 | while read repo tag id size; do
    if [[ "$repo" == "<none>" ]]; then
        echo "| ❌ $repo | $tag | $id | $size | \`docker run --rm $id\` (imagem órfã) |"
    else
        echo "| $repo | $tag | $id | $size | \`docker run --rm $repo:$tag\` |"
    fi
done
echo ""

# =============================================================================
# 📈 6. ANÁLISE DE PROJETOS ESPERADOS
# =============================================================================
echo "## 📈 6. ANÁLISE DE PROJETOS ESPERADOS"
echo ""

analyze_project_status() {
    local projects=("$@")
    local category=$1
    shift

    echo "### $category"
    echo ""
    echo "| Projeto | Status | Container | Imagem Disponível |"
    echo "|---------|--------|-----------|-------------------|"

    for project in "${projects[@]}"; do
        # Verificar se container está rodando
        RUNNING_CONTAINER=$(docker ps --format "{{.Names}}" | grep "$project" | head -1 || echo "")

        # Verificar se imagem existe
        AVAILABLE_IMAGE=$(docker images --format "{{.Repository}}" | grep "$project" | head -1 || echo "")

        if [[ -n "$RUNNING_CONTAINER" ]]; then
            STATUS="✅ Rodando"
        elif [[ -n "$AVAILABLE_IMAGE" ]]; then
            STATUS="⚠️ Imagem disponível, não rodando"
        else
            STATUS="❌ Imagem não encontrada"
        fi

        echo "| $project | $STATUS | ${RUNNING_CONTAINER:-N/A} | ${AVAILABLE_IMAGE:-N/A} |"
    done
    echo ""
}

analyze_project_status "Backend Projects" "${BACKEND_PROJECTS[@]}"
analyze_project_status "Infrastructure Projects" "${INFRA_PROJECTS[@]}"

# =============================================================================
# 🔍 7. LOGS DE ERRO RECENTES
# =============================================================================
echo "## 🔍 7. LOGS DE ERRO RECENTES"
echo ""

echo "### Últimos erros dos containers rodando:"
echo ""

for container in $(docker ps --format "{{.Names}}"); do
    ERROR_LOGS=$(docker logs "$container" --tail 10 2>&1 | grep -i "error\|exception\|failed\|fatal" | head -3 || echo "")
    if [[ -n "$ERROR_LOGS" ]]; then
        echo "**$container**:"
        echo "\`\`\`"
        echo "$ERROR_LOGS"
        echo "\`\`\`"
        echo ""
    fi
done

# =============================================================================
# ⚡ 8. COMANDOS PARA DEBUG MANUAL
# =============================================================================
echo "## ⚡ 8. COMANDOS PARA DEBUG MANUAL"
echo ""

echo "### Comandos úteis para investigar problemas:"
echo ""
echo "\`\`\`bash"
echo "# Ver logs de um serviço específico"
echo "docker service logs NOME_SERVICO --tail 50"
echo ""
echo "# Executar imagem manualmente para debug"
echo "docker run --rm -it IMAGEM /bin/bash"
echo ""
echo "# Ver detalhes de um serviço com problema"
echo "docker service ps NOME_SERVICO --no-trunc"
echo ""
echo "# Limpar imagens órfãs"
echo "docker image prune -f"
echo ""
echo "# Ver recursos do sistema"
echo "docker system df"
echo "\`\`\`"
echo ""

# =============================================================================
# 📊 9. RECURSOS DO SISTEMA
# =============================================================================
echo "## 📊 9. RECURSOS DO SISTEMA"
echo ""

echo "### Uso de disco Docker:"
echo "\`\`\`"
docker system df 2>/dev/null || echo "Erro ao obter informações de disco"
echo "\`\`\`"
echo ""

echo "### Informações do Docker:"
echo "\`\`\`"
docker version --format "Client: {{.Client.Version}} | Server: {{.Server.Version}}" 2>/dev/null || echo "Erro ao obter versão do Docker"
echo "\`\`\`"
echo ""

# =============================================================================
# ✅ 10. RESUMO FINAL
# =============================================================================
echo "## ✅ 10. RESUMO FINAL"
echo ""

TOTAL_EXPECTED=$((${#BACKEND_PROJECTS[@]} + ${#INFRA_PROJECTS[@]}))
RUNNING_COUNT=0

for project in "${BACKEND_PROJECTS[@]}" "${INFRA_PROJECTS[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "$project"; then
        RUNNING_COUNT=$((RUNNING_COUNT + 1))
    fi
done

SUCCESS_RATE=$(echo "scale=1; $RUNNING_COUNT * 100 / $TOTAL_EXPECTED" | bc -l 2>/dev/null || echo "N/A")

echo "- **Projetos Esperados**: $TOTAL_EXPECTED"
echo "- **Projetos Rodando**: $RUNNING_COUNT"
echo "- **Taxa de Sucesso**: ${SUCCESS_RATE}%"
echo "- **Status Geral**: $(if (( $(echo "$SUCCESS_RATE > 80" | bc -l 2>/dev/null || echo 0) )); then echo "✅ Saudável"; elif (( $(echo "$SUCCESS_RATE > 50" | bc -l 2>/dev/null || echo 0) )); then echo "⚠️ Degradado"; else echo "❌ Crítico"; fi)"
echo ""

echo "**Diagnóstico completo finalizado em**: $(date)"
echo ""
echo "# ============================================================================="