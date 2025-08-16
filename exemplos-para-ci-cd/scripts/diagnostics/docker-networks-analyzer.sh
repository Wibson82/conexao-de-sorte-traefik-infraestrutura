#!/bin/bash

# ===== ANALISADOR DE REDES DOCKER =====
# Exibe todas as networks, containers conectados e tempo de uso

set -e

# Cores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_network() {
    echo -e "${CYAN}[NETWORK]${NC} $1"
}

log_container() {
    echo -e "${MAGENTA}[CONTAINER]${NC} $1"
}

# ===== FUNÇÃO PARA CONVERTER TIMESTAMP =====
convert_timestamp() {
    local timestamp="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "N/A"
    else
        # Linux
        date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "N/A"
    fi
}

# ===== FUNÇÃO PARA CALCULAR TEMPO DE USO =====
calculate_uptime() {
    local created_timestamp="$1"
    local current_timestamp=$(date +%s)
    local uptime_seconds=$((current_timestamp - created_timestamp))
    
    local days=$((uptime_seconds / 86400))
    local hours=$(((uptime_seconds % 86400) / 3600))
    local minutes=$(((uptime_seconds % 3600) / 60))
    
    if [ $days -gt 0 ]; then
        echo "${days}d ${hours}h ${minutes}m"
    elif [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

# ===== ANALISAR REDES DOCKER =====
analyze_docker_networks() {
    log_info "🔍 Analisando redes Docker do projeto..."
    echo
    
    # Obter todas as redes
    local networks=$(docker network ls --format "{{.Name}}" | grep -v "^bridge$\|^host$\|^none$")
    
    if [[ -z "$networks" ]]; then
        log_warning "Nenhuma rede customizada encontrada"
        return
    fi
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                           📊 ANÁLISE DE REDES DOCKER"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo
    
    for network in $networks; do
        log_network "🌐 REDE: $network"
        echo "────────────────────────────────────────────────────────────────────────────────"
        
        # Informações básicas da rede
        local network_info=$(docker network inspect "$network" --format '{{.Created}}|{{.Driver}}|{{.Scope}}|{{.IPAM.Config}}')
        IFS='|' read -r created driver scope ipam <<< "$network_info"
        
        # Converter timestamp de criação
        local created_timestamp=$(date -d "$created" +%s 2>/dev/null || echo "0")
        local created_formatted=$(convert_timestamp "$created_timestamp")
        local network_age=$(calculate_uptime "$created_timestamp")
        
        echo "   📅 Criada em: $created_formatted"
        echo "   ⏱️  Idade: $network_age"
        echo "   🔧 Driver: $driver"
        echo "   🌍 Escopo: $scope"
        echo "   🔢 IPAM: $ipam"
        echo
        
        # Containers conectados
        local containers=$(docker network inspect "$network" --format '{{range .Containers}}{{.Name}}|{{.IPv4Address}}|{{.IPv6Address}}|{{.MacAddress}} {{end}}')
        
        if [[ -n "$containers" && "$containers" != " " ]]; then
            log_container "📦 CONTAINERS CONECTADOS:"
            echo
            
            for container_info in $containers; do
                if [[ -n "$container_info" && "$container_info" != "|" ]]; then
                    IFS='|' read -r name ipv4 ipv6 mac <<< "$container_info"
                    
                    # Informações do container
                    local container_details=$(docker inspect "$name" --format '{{.Created}}|{{.State.Status}}|{{.State.StartedAt}}' 2>/dev/null || echo "N/A|N/A|N/A")
                    IFS='|' read -r container_created status started_at <<< "$container_details"
                    
                    # Calcular tempo de execução
                    local started_timestamp=$(date -d "$started_at" +%s 2>/dev/null || echo "0")
                    local container_uptime=$(calculate_uptime "$started_timestamp")
                    
                    echo "      🏷️  Nome: $name"
                    echo "      📊 Status: $status"
                    echo "      🕐 Uptime: $container_uptime"
                    echo "      🌐 IPv4: ${ipv4:-N/A}"
                    echo "      🌐 IPv6: ${ipv6:-N/A}"
                    echo "      🔧 MAC: ${mac:-N/A}"
                    echo
                fi
            done
        else
            log_warning "   ⚠️  Nenhum container conectado"
            echo
        fi
        
        echo "────────────────────────────────────────────────────────────────────────────────"
        echo
    done
}

# ===== ANALISAR CONECTIVIDADE ENTRE CONTAINERS =====
analyze_connectivity() {
    log_info "🔗 Testando conectividade entre containers do projeto..."
    echo
    
    # Containers do projeto
    local project_containers=("backend-teste" "backend-prod" "conexao-mysql" "conexao-frontend")
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                        🧪 TESTE DE CONECTIVIDADE"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo
    
    for source in "${project_containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${source}$"; then
            log_container "📡 TESTANDO CONECTIVIDADE DE: $source"
            echo
            
            for target in "${project_containers[@]}"; do
                if [[ "$source" != "$target" ]] && docker ps --format "{{.Names}}" | grep -q "^${target}$"; then
                    echo -n "      $source → $target: "
                    
                    if docker exec "$source" ping -c 1 -W 2 "$target" >/dev/null 2>&1; then
                        echo -e "${GREEN}✅ OK${NC}"
                    else
                        echo -e "${RED}❌ FALHA${NC}"
                    fi
                fi
            done
            echo
        fi
    done
}

# ===== RESUMO EXECUTIVO =====
executive_summary() {
    log_info "📋 Gerando resumo executivo..."
    echo
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                           📊 RESUMO EXECUTIVO"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo
    
    # Contar redes
    local total_networks=$(docker network ls --format "{{.Name}}" | grep -v "^bridge$\|^host$\|^none$" | wc -l)
    echo "🌐 Total de redes customizadas: $total_networks"
    
    # Contar containers
    local total_containers=$(docker ps --format "{{.Names}}" | wc -l)
    echo "📦 Total de containers ativos: $total_containers"
    
    # Containers do projeto
    local project_containers=("backend-teste" "backend-prod" "conexao-mysql" "conexao-frontend")
    echo "🎯 Containers do projeto:"
    
    for container in "${project_containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            local status=$(docker inspect "$container" --format '{{.State.Status}}' 2>/dev/null)
            local uptime=$(docker inspect "$container" --format '{{.State.StartedAt}}' 2>/dev/null)
            local uptime_timestamp=$(date -d "$uptime" +%s 2>/dev/null || echo "0")
            local container_uptime=$(calculate_uptime "$uptime_timestamp")
            
            echo "   ✅ $container: $status (uptime: $container_uptime)"
        else
            echo "   ❌ $container: não encontrado"
        fi
    done
    
    echo
    echo "🔍 Problemas identificados:"
    
    # Verificar se backend consegue conectar ao MySQL
    if docker ps --format "{{.Names}}" | grep -q "^backend-teste$" && docker ps --format "{{.Names}}" | grep -q "^conexao-mysql$"; then
        if docker exec backend-teste ping -c 1 -W 2 conexao-mysql >/dev/null 2>&1; then
            echo "   ✅ Conectividade backend-teste → conexao-mysql: OK"
        else
            echo "   ❌ Conectividade backend-teste → conexao-mysql: FALHA"
            echo "      💡 Sugestão: Verificar se estão na mesma rede Docker"
        fi
    fi
    
    echo
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    echo
    log_success "🚀 INICIANDO ANÁLISE COMPLETA DE REDES DOCKER"
    echo "Timestamp: $(date)"
    echo "Servidor: $(hostname)"
    echo
    
    analyze_docker_networks
    analyze_connectivity
    executive_summary
    
    log_success "🎉 Análise completa finalizada!"
    echo
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
