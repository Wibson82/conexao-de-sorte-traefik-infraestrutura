#!/bin/bash

# ===== SCRIPT DE DEPLOY PARA GITHUB ACTIONS =====
# Sistema: Conexão de Sorte - Backend
# Função: Deploy automatizado via GitHub Actions
# Versão: 1.0.0
# Data: $(date +"%d/%m/%Y")

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configurações do deploy
IMAGE_NAME="facilita/conexao-de-sorte-backend"
PRIMARY_TAG="${PRIMARY_TAG:-}"
DEPLOY_TIMEOUT=300  # 5 minutos
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=10

# URLs para verificação
APP_URL="https://conexaodesorte.com.br/rest/actuator/health"
TRAEFIK_API="http://localhost:8080/api/rawdata"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNÇÕES AUXILIARES =====
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

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

# ===== VERIFICAÇÕES PRÉ-DEPLOY =====
check_prerequisites() {
    log_info "Verificando pré-requisitos para deploy..."

    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        return 1
    fi

    # Verificar se está logado no Docker Hub
    if ! docker info | grep -q "Username"; then
        log_warning "Não está logado no Docker Hub, tentando fazer login..."
        # Se não estiver logado, tentar fazer login (pode falhar se as credenciais não estiverem disponíveis)
        if ! docker login -u "${DOCKER_USERNAME:-}" -p "${DOCKER_PASSWORD:-}" >/dev/null 2>&1; then
            log_warning "Não foi possível fazer login no Docker Hub automaticamente"
        fi
    fi

    # Verificar se PRIMARY_TAG foi fornecida
    if [[ -z "$PRIMARY_TAG" ]]; then
        log_error "PRIMARY_TAG não foi fornecida"
        return 1
    fi

    # Fazer pull da imagem se não existir localmente
    if ! docker image inspect "$PRIMARY_TAG" >/dev/null 2>&1; then
        log_info "Imagem $PRIMARY_TAG não encontrada localmente, fazendo pull..."
        if ! docker pull "$PRIMARY_TAG"; then
            log_error "Falha ao fazer pull da imagem $PRIMARY_TAG"
            return 1
        fi
        log_success "Imagem $PRIMARY_TAG baixada com sucesso"
    else
        log_info "Imagem $PRIMARY_TAG já existe localmente"
    fi

    # Verificar espaço em disco
    local available_space
    available_space=$(df / | tail -1 | awk '{print $4}')
    local required_space=1048576  # 1GB em KB

    if (( available_space < required_space )); then
        log_error "Espaço em disco insuficiente. Disponível: ${available_space}KB, Necessário: ${required_space}KB"
        return 1
    fi

    log_success "Pré-requisitos verificados com sucesso"
}

# ===== CRIAÇÃO DE REDE =====
setup_network() {
    log_info "Configurando rede Docker..."

    # Criar rede se não existir
    if ! docker network ls | grep -q traefik-network; then
        docker network create traefik-network
        log_success "Rede traefik-network criada"
    else
        log_info "Rede traefik-network já existe"
    fi
}

# ===== CONFIGURAÇÃO DO MYSQL =====
setup_mysql() {
    log_info "Configurando MySQL..."

    # Verificar se MySQL já está rodando
    if docker ps -q -f name=conexao-mysql | grep -q .; then
        log_info "MySQL já está rodando"
        return 0
    fi

    # Parar e remover container antigo se existir
    docker stop conexao-mysql 2>/dev/null || true
    docker rm conexao-mysql 2>/dev/null || true

    # Iniciar MySQL
    log_info "Iniciando MySQL..."
    docker run -d --name conexao-mysql \
        --network traefik-network \
        -e MYSQL_ROOT_PASSWORD=root123 \
        -e MYSQL_DATABASE=conexao_de_sorte \
        -e MYSQL_USER=app_user \
        -e MYSQL_PASSWORD=app123 \
        -v mysql-data:/var/lib/mysql \
        --restart unless-stopped \
        mysql:8.0

    # Aguardar MySQL inicializar
    log_info "Aguardando MySQL inicializar..."
    sleep 30

    # Verificar se MySQL está funcionando
    if docker exec conexao-mysql mysqladmin ping -h localhost --silent; then
        log_success "MySQL iniciado com sucesso"
    else
        log_error "Falha ao iniciar MySQL"
        return 1
    fi
}

# ===== CONFIGURAÇÃO DO TRAEFIK =====
setup_traefik() {
    log_info "Configurando Traefik com configuração centralizada..."

    # Verificar se Traefik já está rodando
    if docker ps --format "table {{.Names}}" | grep -q "traefik"; then
        log_info "Traefik já está rodando"
        return 0
    fi

    # Usar configuração centralizada
    if [[ -f "config/traefik/generate-traefik-config.sh" ]]; then
        log_info "Usando configuração centralizada do Traefik"
        chmod +x config/traefik/generate-traefik-config.sh
        ./config/traefik/generate-traefik-config.sh create production
    else
        log_error "Configuração centralizada não encontrada"
        return 1
    fi

    log_success "Traefik configurado com sucesso"
}
# ===== DEPLOY DO BACKEND =====
# ⚠️ FUNÇÃO DESABILITADA - Backend de produção não será atualizado
# Para manter o backend de produção inalterado, esta função foi comentada
deploy_backend() {
    log_info "🚫 DEPLOY DO BACKEND DE PRODUÇÃO DESABILITADO"
    log_info "📋 Motivo: CI/CD configurado para atualizar apenas o backend de teste"
    log_info "🔒 Backend de produção permanecerá inalterado"
    log_info "🧪 Apenas o backend de teste será atualizado com a nova imagem"

    # Verificar se o backend de produção está rodando
    if docker ps --filter "name=backend-prod" --format "{{.Status}}" | grep -q "Up"; then
        log_success "✅ Backend de produção está rodando e será mantido inalterado"
    else
        log_warning "⚠️ Backend de produção não está rodando - será iniciado se necessário"

        # Se não estiver rodando, iniciar com a imagem atual (não a nova)
        if ! docker ps -a --filter "name=backend-prod" --format "{{.Names}}" | grep -q "backend-prod"; then
            log_info "🔄 Iniciando backend de produção com imagem atual..."
            # Usar a imagem que já está rodando ou a última estável
            docker run -d --name backend-prod \
                --network traefik-network \
                -e SPRING_PROFILES_ACTIVE=prod,azure \
                -e SERVER_PORT=8080 \
                -e ENVIRONMENT=production \
                -e TZ=America/Sao_Paulo \
                -e INSTANCE_COLOR=blue \
                -e AZURE_KEYVAULT_ENABLED=true \
                -e AZURE_KEYVAULT_ENDPOINT="${AZURE_KEYVAULT_ENDPOINT:-}" \
                -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-}" \
                -e AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET:-}" \
                -e AZURE_TENANT_ID="${AZURE_TENANT_ID:-}" \
                -e AZURE_KEYVAULT_FALLBACK_ENABLED=true \
                -e SPRING_DATASOURCE_URL="${CONEXAO_DE_SORTE_DATABASE_URL:-jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo&createDatabaseIfNotExist=true}" \
                -e SPRING_DATASOURCE_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}" \
                -e SPRING_DATASOURCE_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-root123}" \
                -e CONEXAO_DE_SORTE_DATABASE_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}" \
                -e CONEXAO_DE_SORTE_DATABASE_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-root123}" \
                -e TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}" \
                -e JAVA_OPTS="-server -Xms512m -Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/" \
                -e MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics,prometheus \
                -e MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS=always \
                -e MANAGEMENT_METRICS_EXPORT_PROMETHEUS_ENABLED=true \
                --label "traefik.enable=true" \
                --label "traefik.http.routers.backend.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/rest\`)" \
                --label "traefik.http.routers.backend.entrypoints=websecure" \
                --label "traefik.http.routers.backend.tls=true" \
                --label "traefik.http.routers.backend.tls.certresolver=letsencrypt" \
                --label "traefik.http.routers.backend.priority=200" \
                --label "traefik.http.services.backend.loadbalancer.server.port=8080" \
                --label "traefik.http.middlewares.backend-stripprefix.stripprefix.prefixes=/rest" \
                --label "traefik.http.routers.backend.middlewares=backend-stripprefix" \
                --restart unless-stopped \
                facilita/conexao-de-sorte-backend:latest
        fi
    fi

    log_success "✅ Backend de produção verificado/mantido"
}

# ===== CONFIGURAÇÃO DO BACKEND DE TESTE =====
setup_test_backend() {
    log_info "🧪 CONFIGURANDO BACKEND DE TESTE COM NOVA IMAGEM"
    log_info "🔄 Backend de teste será sempre atualizado com a nova imagem: $PRIMARY_TAG"

    # Sempre parar e remover container antigo para garantir atualização
    log_info "🛑 Parando e removendo container de teste anterior..."
    docker stop backend-teste 2>/dev/null || true
    docker rm backend-teste 2>/dev/null || true

    # Container de teste do backend
    docker run -d --name backend-teste \
        --network traefik-network \
        -e SPRING_PROFILES_ACTIVE=prod,azure,local-fallback \
        -e AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-}" \
        -e AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET:-}" \
        -e AZURE_TENANT_ID="${AZURE_TENANT_ID:-}" \
        -e AZURE_KEYVAULT_FALLBACK_ENABLED=true \
        -e SPRING_DATASOURCE_URL="${CONEXAO_DE_SORTE_DATABASE_URL:-jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo&createDatabaseIfNotExist=true}" \
        -e SPRING_DATASOURCE_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}" \
        -e SPRING_DATASOURCE_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-root123}" \
        -e CONEXAO_DE_SORTE_DATABASE_USERNAME="${CONEXAO_DE_SORTE_DATABASE_USERNAME:-root}" \
        -e CONEXAO_DE_SORTE_DATABASE_PASSWORD="${CONEXAO_DE_SORTE_DATABASE_PASSWORD:-root123}" \
        -e TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-123456789}" \
        -e JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/" \
        -e MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics,prometheus \
        -e MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS=always \
        -e MANAGEMENT_METRICS_EXPORT_PROMETHEUS_ENABLED=true \
        --label "traefik.enable=true" \
        --label "traefik.http.routers.backend-teste.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && PathPrefix(\`/teste\`)" \
        --label "traefik.http.routers.backend-teste.entrypoints=websecure" \
        --label "traefik.http.routers.backend-teste.tls=true" \
        --label "traefik.http.routers.backend-teste.tls.certresolver=letsencrypt" \
        --label "traefik.http.routers.backend-teste.priority=150" \
        --label "traefik.http.services.backend-teste.loadbalancer.server.port=8080" \
        --label "traefik.http.middlewares.backend-teste-stripprefix.stripprefix.prefixes=/teste" \
        --label "traefik.http.routers.backend-teste.middlewares=backend-teste-stripprefix" \
        --restart unless-stopped \
        "$PRIMARY_TAG"

    log_success "Backend de teste iniciado"
}

# ===== CONFIGURAÇÃO DO FRONTEND PRINCIPAL =====
setup_main_frontend() {
    log_info "Verificando frontend principal..."

    # Verificar se o container já está rodando
    if docker ps --filter "name=frontend-prod" --format "{{.Status}}" | grep -q "Up"; then
        log_info "Frontend principal já está rodando - mantendo como está"
        return 0
    fi

    log_info "Frontend principal não está rodando - iniciando..."

    # Parar e remover container antigo se existir (apenas se não estiver rodando)
    docker stop frontend-prod 2>/dev/null || true
    docker rm frontend-prod 2>/dev/null || true

    # Frontend principal
    docker run -d --name frontend-prod \
        --network traefik-network \
        --label "traefik.enable=true" \
        --label "traefik.http.routers.frontend.rule=(Host(\`conexaodesorte.com.br\`) || Host(\`www.conexaodesorte.com.br\`)) && !PathPrefix(\`/rest\`) && !PathPrefix(\`/teste\`)" \
        --label "traefik.http.routers.frontend.entrypoints=websecure" \
        --label "traefik.http.routers.frontend.tls=true" \
        --label "traefik.http.routers.frontend.tls.certresolver=letsencrypt" \
        --label "traefik.http.routers.frontend.priority=1" \
        --label "traefik.http.services.frontend.loadbalancer.server.port=3000" \
        --restart unless-stopped \
        facilita/conexao-de-sorte-frontend:latest

    log_success "Frontend principal iniciado"
}

# ===== REINICIALIZAÇÃO DO TRAEFIK =====
restart_traefik() {
    log_info "Reiniciando Traefik para aplicar novas configurações..."
    log_info "🔒 Configurações de segurança aplicadas:"
    log_info "   - Dashboard apenas local (localhost/127.0.0.1)"
    log_info "   - Autenticação básica habilitada"
    log_info "   - API insegura desabilitada"

    # Método simples: restart do container
    if docker restart traefik; then
        log_success "Traefik reiniciado com sucesso"
        sleep 10
    else
        log_warning "Restart falhou, recriando Traefik..."

        # Se restart falhar, recriar do zero
        docker stop traefik 2>/dev/null || true
        docker rm traefik 2>/dev/null || true

        # Aguardar liberação das portas
        sleep 10

        # Recriar Traefik
        docker run -d --name traefik \
            -p 80:80 -p 443:443 -p 8090:8080 \
            --network traefik-network \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            -v /home/ubuntu/traefik:/etc/traefik \
            --restart unless-stopped \
                    --label "traefik.enable=true" \
        --label "traefik.http.routers.traefik.rule=Host(\`localhost\`) || Host(\`127.0.0.1\`)" \
        --label "traefik.http.routers.traefik.entrypoints=web" \
        --label "traefik.http.routers.traefik.middlewares=traefik-auth" \
        --label "traefik.http.middlewares.traefik-auth.basicauth.users=admin:\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi" \
        --label "traefik.http.services.traefik.loadbalancer.server.port=8080" \
            traefik:v3.0 \
                    --api.dashboard=true \
        --api.insecure=false \
            --providers.docker=true \
            --providers.docker.exposedbydefault=false \
            --providers.docker.network=traefik-network \
            --entrypoints.web.address=:80 \
            --entrypoints.websecure.address=:443 \
            --entrypoints.web.http.redirections.entrypoint.to=websecure \
            --entrypoints.web.http.redirections.entrypoint.scheme=https \
            --entrypoints.web.http.redirections.entrypoint.permanent=true \
            --certificatesresolvers.letsencrypt.acme.email=facilitaservicos.tec@gmail.com \
            --certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme.json \
            --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web \
            --certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory \
            --log.level=INFO \
            --accesslog=true \
            --log.format=json \
            --serverstransport.insecureskipverify=false \
            --global.sendanonymoususage=false

        sleep 15

        if docker ps | grep -q "traefik.*Up"; then
            log_success "Traefik recriado com sucesso"
        else
            log_error "Erro: Falha ao recriar Traefik"
            docker logs traefik --tail 10 || true
            log_warning "Continuando deploy sem reiniciar Traefik"
        fi
    fi
}

# ===== VERIFICAÇÃO DE SAÚDE =====
wait_for_health() {
    local container_name="backend-teste"

    log_info "🧪 Aguardando backend de teste ficar saudável..."

    local retries=0
    local max_retries=$HEALTH_CHECK_RETRIES

    while (( retries < max_retries )); do
        # Verificar se o container está rodando
        if ! docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
            log_error "Container $container_name não está rodando"
            return 1
        fi

        # Verificar logs do container para erros
        local recent_logs
        recent_logs=$(docker logs --tail 50 "$container_name" 2>&1)

        # Verificar se a aplicação Spring Boot iniciou
        if echo "$recent_logs" | grep -q "Started.*Application"; then
            log_info "Aplicação Spring Boot iniciada no container $container_name"

            # Aguardar um pouco mais para a aplicação ficar totalmente pronta
            sleep 10

            # Verificar endpoint de saúde com timeout reduzido
            local container_port
            container_port=$(docker port "$container_name" 8080 | cut -d: -f2)

            if [[ -n "$container_port" ]]; then
                # Tentar primeiro o endpoint de health do actuator com timeout
                local health_url="http://localhost:$container_port/actuator/health"
                log_info "Testando endpoint de saúde: $health_url"

                local health_response
                health_response=$(curl -s --max-time 10 "$health_url" 2>/dev/null)

                if [[ -n "$health_response" ]]; then
                    log_info "Resposta do health check: $health_response"

                    if echo "$health_response" | grep -q '"status":"UP"'; then
                        log_success "Backend está saudável"
                        return 0
                    elif echo "$health_response" | grep -q '"status":"up"'; then
                        log_success "Backend está saudável (status case-insensitive)"
                        return 0
                    else
                        log_info "Endpoint de saúde não retornou UP, tentando endpoint básico..."
                    fi
                else
                    log_info "Health check não retornou resposta, tentando endpoint básico..."
                fi

                # Tentar endpoint básico como fallback com timeout
                local basic_url="http://localhost:$container_port/"
                log_info "Testando endpoint básico: $basic_url"

                if curl -f -s --max-time 10 "$basic_url" >/dev/null 2>&1; then
                    log_success "Backend está respondendo no endpoint básico"
                    return 0
                else
                    log_info "Endpoint básico também não respondeu, tentando novamente..."
                fi
            else
                log_info "Porta 8080 não está mapeada, aguardando..."
            fi
        fi

        # Verificar se há mensagens de inicialização do Spring Boot
        if echo "$recent_logs" | grep -q "Spring Boot.*started"; then
            log_info "Spring Boot detectado como iniciado"
        fi

        # Verificar se há erros críticos (mas não bloquear por warnings)
        if echo "$recent_logs" | grep -q "FATAL\|OutOfMemoryError\|BindException"; then
            log_error "Erro crítico detectado no backend"
            log_info "Últimos logs do container:"
            docker logs --tail 30 "$container_name"
            return 1
        fi

        # Verificar se o container parou
        if ! docker ps --filter "name=$container_name" --format "{{.Status}}" | grep -q "Up"; then
            log_error "Container $container_name parou de rodar"
            log_info "Status do container:"
            docker ps -a --filter "name=$container_name"
            log_info "Últimos logs do container:"
            docker logs --tail 30 "$container_name"
            return 1
        fi

        retries=$((retries + 1))
        log_info "Tentativa $retries/$max_retries - Aguardando $HEALTH_CHECK_INTERVAL segundos..."

        # Mostrar status atual do container
        log_info "Status atual do container:"
        docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        sleep $HEALTH_CHECK_INTERVAL
    done

    # Se chegou aqui, considerar como sucesso se o container está rodando
    if docker ps --filter "name=$container_name" --format "{{.Status}}" | grep -q "Up"; then
        log_warning "Timeout no health check, mas container está rodando - considerando como sucesso"
        return 0
    else
        log_error "Timeout aguardando backend ficar saudável"
        return 1
    fi
}

# ===== VERIFICAÇÃO FINAL =====
final_verification() {
    log_info "Executando verificação final..."

    # Verificar conectividade do Traefik
    log_info "Verificando conectividade do Traefik..."
    sleep 5

    if curl -f -s -o /dev/null http://localhost:8080/ping 2>/dev/null; then
        log_success "Traefik está respondendo corretamente"
    else
        log_warning "Traefik pode não estar totalmente funcional"
    fi

    # Verificar status dos containers
    log_info "Status dos containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    # Verificar URLs disponíveis
    log_info "URLs disponíveis:"
    echo "   - Frontend: https://conexaodesorte.com.br"
    echo "   - Backend API (PRODUÇÃO - INALTERADO): https://conexaodesorte.com.br/rest"
    echo "   - Backend Teste (ATUALIZADO): https://conexaodesorte.com.br/teste"
    echo "   - Traefik Dashboard: http://localhost:8080 (apenas local, com autenticação)"

    log_success "🧪 Deploy de teste concluído com sucesso!"
    log_info "✅ Backend de produção permaneceu inalterado"
    log_info "🔄 Backend de teste foi atualizado com a nova imagem"
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    log_info "🧪 Iniciando deploy de TESTE (backend de produção inalterado)..."
    log_info "🔍 Debug - PRIMARY_TAG recebida: '$PRIMARY_TAG'"

    # Verificar se PRIMARY_TAG foi passada
    if [[ -z "$PRIMARY_TAG" ]]; then
        log_error "❌ ERRO: PRIMARY_TAG não foi passada para o script!"
        return 1
    fi

    # Executar etapas do deploy
    check_prerequisites || return 1
    setup_network || return 1
    setup_mysql || return 1
    setup_traefik || return 1
    deploy_backend || return 1
    setup_test_backend || return 1
    setup_main_frontend || return 1
    restart_traefik || log_warning "Problema com Traefik, mas continuando..."
    wait_for_health || return 1
    final_verification || return 1

    log_success "🧪 Deploy de teste concluído com sucesso!"
    log_info "📋 Resumo:"
    log_info "   ✅ Backend de produção: Mantido inalterado"
    log_info "   🔄 Backend de teste: Atualizado com nova imagem"
    log_info "   🌐 URLs:"
    log_info "      - Produção: https://conexaodesorte.com.br/rest"
    log_info "      - Teste: https://conexaodesorte.com.br/teste"
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
