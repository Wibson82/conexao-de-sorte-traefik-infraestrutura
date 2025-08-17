#!/bin/bash

# =============================================================================
# SCRIPT DE DIAGNÓSTICO COMPLETO - TRAEFIK CONEXÃO DE SORTE
# =============================================================================
# Este script executa uma verificação completa da infraestrutura Traefik
# e identifica problemas de conectividade, roteamento e SSL

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Função para imprimir sucesso
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para imprimir erro
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para imprimir aviso
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                 DIAGNÓSTICO TRAEFIK                         ║
║                 CONEXÃO DE SORTE                             ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# =============================================================================
# 1. VERIFICAÇÃO DE CONTAINERS
# =============================================================================
print_header "1. CONTAINERS EM EXECUÇÃO"

echo "Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || print_error "Erro ao listar containers"

echo "\nVerificando containers específicos:"
containers=("conexao-traefik" "backend-prod" "conexao-frontend" "backend-teste" "frontend-teste")

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        print_success "Container $container está em execução"
    else
        print_error "Container $container NÃO está em execução"
    fi
done

# =============================================================================
# 2. VERIFICAÇÃO DE REDES
# =============================================================================
print_header "2. REDES DOCKER"

echo "Redes disponíveis:"
docker network ls | grep -E "(conexao|traefik)" || print_warning "Nenhuma rede conexao/traefik encontrada"

echo "\nVerificando rede conexao-network:"
if docker network inspect conexao-network >/dev/null 2>&1; then
    print_success "Rede conexao-network existe"
    echo "\nContainers conectados à rede conexao-network:"
    docker network inspect conexao-network --format '{{range .Containers}}{{.Name}} {{end}}' | tr ' ' '\n' | grep -v '^$' || print_warning "Nenhum container conectado"
else
    print_error "Rede conexao-network NÃO existe"
fi

# =============================================================================
# 3. VERIFICAÇÃO DO TRAEFIK
# =============================================================================
print_header "3. STATUS DO TRAEFIK"

echo "Verificando API do Traefik:"
if curl -s http://localhost:8090/ping >/dev/null 2>&1; then
    print_success "API do Traefik está acessível"
else
    print_error "API do Traefik NÃO está acessível"
fi

echo "\nVerificando routers:"
if command -v jq >/dev/null 2>&1; then
    curl -s http://localhost:8090/api/http/routers 2>/dev/null | jq -r '.[] | "\(.name): \(.rule) [\(.status)]"' || print_warning "Erro ao obter routers"
else
    print_warning "jq não instalado - não é possível analisar routers JSON"
    curl -s http://localhost:8090/api/http/routers 2>/dev/null || print_error "Erro ao acessar routers"
fi

echo "\nVerificando serviços:"
if command -v jq >/dev/null 2>&1; then
    curl -s http://localhost:8090/api/http/services 2>/dev/null | jq -r '.[] | "\(.name): \(.loadBalancer.servers[0].url) [\(.status)]"' || print_warning "Erro ao obter serviços"
else
    print_warning "jq não instalado - não é possível analisar serviços JSON"
fi

# =============================================================================
# 4. TESTE DE CONECTIVIDADE INTERNA
# =============================================================================
print_header "4. CONECTIVIDADE INTERNA"

echo "Testando conectividade do Traefik para backends:"

# Teste backend-prod
if docker exec conexao-traefik wget -qO- --timeout=5 http://backend-prod:8080/actuator/health 2>/dev/null; then
    print_success "Traefik → backend-prod: OK"
else
    print_error "Traefik → backend-prod: FALHOU"
fi

# Teste conexao-frontend
if docker exec conexao-traefik wget -qO- --timeout=5 http://conexao-frontend:3000 2>/dev/null >/dev/null; then
    print_success "Traefik → conexao-frontend: OK"
else
    print_error "Traefik → conexao-frontend: FALHOU"
fi

# Teste resolução DNS
echo "\nTestando resolução DNS:"
backends=("backend-prod" "conexao-frontend" "backend-teste")
for backend in "${backends[@]}"; do
    if docker exec conexao-traefik nslookup "$backend" >/dev/null 2>&1; then
        print_success "DNS resolve: $backend"
    else
        print_error "DNS NÃO resolve: $backend"
    fi
done

# =============================================================================
# 5. TESTE DE SSL/HTTPS
# =============================================================================
print_header "5. CERTIFICADOS SSL"

echo "Testando HTTPS endpoints:"
endpoints=(
    "https://www.conexaodesorte.com.br/actuator/health"
    "https://conexaodesorte.com.br/actuator/health"
    "https://traefik.conexaodesorte.com.br/ping"
)

for endpoint in "${endpoints[@]}"; do
    if curl -k -s -I "$endpoint" | head -1 | grep -q "HTTP"; then
        status=$(curl -k -s -I "$endpoint" | head -1 | cut -d' ' -f2)
        if [[ "$status" == "200" ]]; then
            print_success "$endpoint: HTTP $status"
        else
            print_warning "$endpoint: HTTP $status"
        fi
    else
        print_error "$endpoint: Não acessível"
    fi
done

echo "\nVerificando arquivos de certificados:"
if docker exec conexao-traefik ls -la /certs/ 2>/dev/null; then
    cert_files=$(docker exec conexao-traefik ls -la /certs/ 2>/dev/null | grep -E "\.(json|pem|crt|key)$" || true)
    if [[ -n "$cert_files" ]]; then
        print_success "Arquivos de certificados encontrados"
        echo "$cert_files"
    else
        print_warning "Nenhum arquivo de certificado encontrado"
    fi
else
    print_error "Não foi possível acessar diretório de certificados"
fi

# =============================================================================
# 6. LOGS RECENTES
# =============================================================================
print_header "6. LOGS RECENTES"

echo "Últimas 10 linhas do log do Traefik:"
docker logs conexao-traefik --tail=10 2>/dev/null || print_error "Erro ao obter logs do Traefik"

echo "\nErros recentes no Traefik:"
docker logs conexao-traefik --tail=50 2>/dev/null | grep -i error | tail -5 || print_success "Nenhum erro recente encontrado"

# =============================================================================
# 7. RESUMO E RECOMENDAÇÕES
# =============================================================================
print_header "7. RESUMO E RECOMENDAÇÕES"

echo "Verificando problemas comuns:"

# Verificar se containers estão na rede
if ! docker network inspect conexao-network --format '{{range .Containers}}{{.Name}} {{end}}' | grep -q "conexao-traefik"; then
    print_error "Traefik não está conectado à rede conexao-network"
    echo "   Solução: docker network connect conexao-network conexao-traefik"
fi

if ! docker network inspect conexao-network --format '{{range .Containers}}{{.Name}} {{end}}' | grep -q "backend-prod"; then
    print_error "backend-prod não está conectado à rede conexao-network"
    echo "   Solução: docker network connect conexao-network backend-prod"
fi

# Verificar certificados vazios
if docker exec conexao-traefik test -f /certs/acme.json 2>/dev/null; then
    cert_size=$(docker exec conexao-traefik stat -c%s /certs/acme.json 2>/dev/null || echo "0")
    if [[ "$cert_size" == "0" ]]; then
        print_error "Arquivo acme.json está vazio"
        echo "   Solução: Verificar conectividade e forçar renovação de certificados"
    fi
fi

echo "\n${GREEN}Diagnóstico concluído!${NC}"
echo "Para mais detalhes, consulte: ANALISE-ARQUITETURA-TRAEFIK.md"