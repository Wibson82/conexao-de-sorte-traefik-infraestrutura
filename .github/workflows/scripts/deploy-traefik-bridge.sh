#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🌉 DEPLOY TRAEFIK BRIDGE - COMUNICAÇÃO COM BACKEND-PROD
# =============================================================================
# Deploy do container Traefik bridge para comunicação com backend-prod
# Funciona em paralelo com o Traefik Swarm sem conflitos
# =============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    local level=$1
    shift
    case $level in
        "INFO")  echo -e "${BLUE}ℹ️  $*${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $*${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $*${NC}" ;;
        "ERROR") echo -e "${RED}❌ $*${NC}" ;;
    esac
}

# Função principal
deploy_traefik_bridge() {
    log "INFO" "🌉 Iniciando deploy do Traefik Bridge para backend-prod..."
    echo ""
    
    # Verificar se a rede conexao-network existe
    if ! docker network ls --filter name="conexao-network" --format "{{.Name}}" | grep -q "^conexao-network$"; then
        log "INFO" "Criando rede bridge conexao-network..."
        if docker network create conexao-network 2>/dev/null; then
            log "SUCCESS" "Rede conexao-network criada"
        else
            log "WARNING" "Rede conexao-network já existe ou falha na criação"
        fi
    else
        log "SUCCESS" "Rede conexao-network já existe"
    fi
    
    # Garantir que diretórios necessários existam
    mkdir -p ./letsencrypt-bridge || true
    mkdir -p ./logs/traefik-bridge || true
    
    # Corrigir permissões do acme.json
    if [ ! -f ./letsencrypt-bridge/acme.json ]; then
        touch ./letsencrypt-bridge/acme.json
    fi
    chmod 600 ./letsencrypt-bridge/acme.json
    
    # Verificar se o backend-prod está rodando
    if docker ps --filter name="backend-prod" --format "{{.Names}}" | grep -q "^backend-prod$"; then
        log "SUCCESS" "Container backend-prod encontrado e rodando"
        
        # Conectar backend-prod à rede se não estiver conectado
        if ! docker inspect backend-prod --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}}{{"\n"}}{{end}}' | grep -q "^conexao-network$"; then
            log "INFO" "Conectando backend-prod à rede conexao-network..."
            if docker network connect conexao-network backend-prod 2>/dev/null; then
                log "SUCCESS" "backend-prod conectado à rede conexao-network"
            else
                log "WARNING" "Falha ao conectar backend-prod (pode já estar conectado)"
            fi
        else
            log "SUCCESS" "backend-prod já está conectado à rede conexao-network"
        fi
    else
        log "WARNING" "Container backend-prod não encontrado - continuando deploy"
    fi
    
    echo ""
    log "INFO" "Fazendo deploy do Traefik Bridge..."
    
    # Parar container existente se estiver rodando
    if docker ps --filter name="traefik-bridge" --format "{{.Names}}" | grep -q "^traefik-bridge$"; then
        log "INFO" "Parando container traefik-bridge existente..."
        docker-compose -f docker-compose.bridge.yml down || true
    fi
    
    # Deploy do Traefik Bridge
    if docker-compose -f docker-compose.bridge.yml up -d; then
        log "SUCCESS" "Traefik Bridge deployado com sucesso!"
    else
        log "ERROR" "Falha no deploy do Traefik Bridge"
        return 1
    fi
    
    echo ""
    log "INFO" "Aguardando Traefik Bridge ficar saudável..."
    
    # Aguardar container ficar saudável
    local timeout=60
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if docker ps --filter name="traefik-bridge" --format "{{.Status}}" | grep -q "healthy"; then
            log "SUCCESS" "Traefik Bridge está saudável!"
            break
        elif docker ps --filter name="traefik-bridge" --format "{{.Status}}" | grep -q "Up"; then
            log "INFO" "Traefik Bridge iniciando... ($elapsed/$timeout segundos)"
        else
            log "WARNING" "Traefik Bridge não está rodando"
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    if [ $elapsed -ge $timeout ]; then
        log "WARNING" "Timeout aguardando Traefik Bridge ficar saudável"
        log "INFO" "Verificando logs..."
        docker-compose -f docker-compose.bridge.yml logs --tail 20 traefik-bridge
    fi
    
    echo ""
    log "INFO" "📋 Status final:"
    docker-compose -f docker-compose.bridge.yml ps
    
    echo ""
    log "SUCCESS" "🎉 Deploy do Traefik Bridge concluído!"
    log "INFO" "🌍 Endpoints disponíveis:"
    log "INFO" "  - HTTP: http://localhost:8080 (Bridge)"
    log "INFO" "  - HTTPS: https://localhost:8443 (Bridge)"
    log "INFO" "  - Backend: http://backend-prod:8080 (via Bridge)"
    
    return 0
}

# Função para parar o Traefik Bridge
stop_traefik_bridge() {
    log "INFO" "🛑 Parando Traefik Bridge..."
    
    if docker-compose -f docker-compose.bridge.yml down; then
        log "SUCCESS" "Traefik Bridge parado com sucesso"
    else
        log "ERROR" "Falha ao parar Traefik Bridge"
        return 1
    fi
}

# Função para mostrar logs
show_logs() {
    log "INFO" "📜 Logs do Traefik Bridge:"
    docker-compose -f docker-compose.bridge.yml logs -f traefik-bridge
}

# Função de ajuda
show_help() {
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos:"
    echo "  deploy    Deploy do Traefik Bridge (padrão)"
    echo "  stop      Parar Traefik Bridge"
    echo "  logs      Mostrar logs do Traefik Bridge"
    echo "  help      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                # Deploy"
    echo "  $0 deploy         # Deploy"
    echo "  $0 stop           # Parar"
    echo "  $0 logs           # Logs"
}

# Função principal
main() {
    local command="${1:-deploy}"
    
    case "$command" in
        "deploy")
            deploy_traefik_bridge
            ;;
        "stop")
            stop_traefik_bridge
            ;;
        "logs")
            show_logs
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log "ERROR" "Comando inválido: $command"
            show_help
            exit 1
            ;;
    esac
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi