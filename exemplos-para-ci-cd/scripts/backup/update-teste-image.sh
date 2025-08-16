#!/bin/bash
# 🧪 Script para Atualizar Imagem de Teste
# ✅ Facilita a substituição da imagem de teste quando implementada

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Configurações
DEFAULT_IMAGE="facilita/conexao-de-sorte-teste:latest"
DEFAULT_PORT="80"

# Função para mostrar uso
show_usage() {
    echo -e "${CYAN}Uso: $0 [OPÇÕES]${NC}"
    echo ""
    echo -e "${BLUE}Opções:${NC}"
    echo -e "  -i, --image IMAGEM    Imagem Docker a usar (padrão: $DEFAULT_IMAGE)"
    echo -e "  -p, --port PORTA      Porta do container (padrão: $DEFAULT_PORT)"
    echo -e "  -h, --help            Mostrar esta ajuda"
    echo ""
    echo -e "${BLUE}Exemplos:${NC}"
    echo -e "  $0                                    # Usar imagem padrão"
    echo -e "  $0 -i minha-imagem:latest            # Usar imagem específica"
    echo -e "  $0 -i minha-imagem:latest -p 3000   # Usar imagem e porta específicas"
    echo ""
    echo -e "${YELLOW}Nota:${NC} Este script substitui o container temporário nginx:alpine pela sua imagem de teste."
}

# Função para verificar se Docker está disponível
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
}

# Função para verificar se a rede existe
check_network() {
    if ! docker network ls | grep -q "traefik-network"; then
        log_error "Rede traefik-network não encontrada. Execute o deploy primeiro."
        exit 1
    fi
}

# Função para atualizar imagem de teste
update_teste_image() {
    local image="$1"
    local port="$2"

    log_header "ATUALIZANDO IMAGEM DE TESTE"

    log_step "Parando container atual..."
    docker stop frontend-teste 2>/dev/null || true
    docker rm frontend-teste 2>/dev/null || true

    log_step "Fazendo pull da nova imagem..."
    if ! docker pull "$image"; then
        log_error "Falha ao fazer pull da imagem: $image"
        exit 1
    fi

    log_step "Criando novo container com imagem de teste..."
    docker run -d --name frontend-teste \
        --network traefik-network \
        --label "traefik.enable=true" \
        --label "traefik.http.routers.teste.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste\`)" \
        --label "traefik.http.routers.teste.entrypoints=websecure" \
        --label "traefik.http.routers.teste.tls=true" \
        --label "traefik.http.routers.teste.tls.certresolver=letsencrypt" \
        --label "traefik.http.routers.teste.priority=150" \
        --label "traefik.http.services.teste.loadbalancer.server.port=$port" \
        --label "traefik.http.middlewares.teste-stripprefix.stripprefix.prefixes=/teste" \
        --label "traefik.http.routers.teste.middlewares=teste-stripprefix" \
        --restart unless-stopped \
        "$image"

    log_success "Container frontend-teste criado com sucesso!"
}

# Função para verificar se o container está funcionando
verify_container() {
    log_step "Verificando se o container está funcionando..."

    if docker ps | grep -q "frontend-teste.*Up"; then
        log_success "Container frontend-teste está rodando"
    else
        log_error "Container frontend-teste não está rodando"
        docker logs frontend-teste --tail 10 || true
        exit 1
    fi

    log_step "Testando conectividade..."
    sleep 5

    if curl -f -s -o /dev/null "https://conexaodesorte.com.br/teste" 2>/dev/null; then
        log_success "✅ Imagem de teste acessível em https://conexaodesorte.com.br/teste"
    else
        log_warning "⚠️  Imagem de teste pode não estar respondendo ainda (aguarde alguns segundos)"
    fi
}

# Função para mostrar status
show_status() {
    log_header "STATUS ATUAL"

    echo -e "${BLUE}Containers relacionados ao teste:${NC}"
    docker ps --filter "name=frontend-teste" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

    echo -e "\n${BLUE}URLs de teste:${NC}"
    echo -e "  ${CYAN}https://conexaodesorte.com.br/teste${NC}"
    echo -e "  ${CYAN}https://www.conexaodesorte.com.br/teste${NC}"

    echo -e "\n${BLUE}Logs do container (últimas 5 linhas):${NC}"
    docker logs frontend-teste --tail 5 2>/dev/null || echo "  Nenhum log disponível"
}

# Função principal
main() {
    local image="$DEFAULT_IMAGE"
    local port="$DEFAULT_PORT"

    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image)
                image="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log_header "ATUALIZADOR DE IMAGEM DE TESTE"
    echo -e "${CYAN}Imagem:${NC} $image"
    echo -e "${CYAN}Porta:${NC} $port"
    echo ""

    # Verificações
    check_docker
    check_network

    # Atualizar imagem
    update_teste_image "$image" "$port"

    # Verificar funcionamento
    verify_container

    # Mostrar status
    show_status

    log_success "🎉 Imagem de teste atualizada com sucesso!"
    echo -e "${GREEN}✅ Acesse: https://conexaodesorte.com.br/teste${NC}"
}

# Executar função principal
main "$@"
