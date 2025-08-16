#!/bin/bash

# ===================================================================
# SCRIPT DE VALIDAÇÃO - CONEXÃO DE SORTE
# ===================================================================
# Este script valida se o deploy está funcionando corretamente
# ===================================================================

set -euo pipefail

# Configurações
STACK_NAME="${STACK_NAME:-app-stack}"
MYSQL_ROOT_PASSWORD_FILE="/run/secrets/mysql_root_password"

if [[ ! -f "$MYSQL_ROOT_PASSWORD_FILE" ]]; then
    echo "❌ Secret mysql_root_password não encontrado em $MYSQL_ROOT_PASSWORD_FILE"
    exit 1
fi
MYSQL_ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Banner
echo "
╔══════════════════════════════════════════════════════════════════╗
║             VALIDAÇÃO DO DEPLOY - CONEXÃO DE SORTE             ║
╚══════════════════════════════════════════════════════════════════╝
"

# ===== TESTE 1: VERIFICAR DOCKER SWARM =====
log_test "Verificando Docker Swarm..."
if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
    log_pass "Docker Swarm está ativo"
else
    log_fail "Docker Swarm não está ativo"
fi

# ===== TESTE 2: VERIFICAR STACK =====
log_test "Verificando stack deployada..."
if docker stack ls | grep -q "$STACK_NAME"; then
    log_pass "Stack $STACK_NAME encontrada"
    
    # Mostrar serviços
    echo "Serviços da stack:"
    docker stack services "$STACK_NAME"
else
    log_fail "Stack $STACK_NAME não encontrada"
fi

# ===== TESTE 3: VERIFICAR SECRETS =====
log_test "Verificando Docker secrets..."
REQUIRED_SECRETS=(
    "MYSQL_ROOT_PASSWORD"
    "MYSQL_USER_PASSWORD"
    "AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET"
    "AZURE_TENANT_ID"
)

for secret in "${REQUIRED_SECRETS[@]}"; do
    if docker secret ls --format "{{.Name}}" | grep -q "^${secret}$"; then
        log_pass "Secret $secret existe"
    else
        log_fail "Secret $secret não encontrado"
    fi
done

# ===== TESTE 4: VERIFICAR VOLUMES =====
log_test "Verificando volumes..."
REQUIRED_VOLUMES=(
    "mysql_data"
    "traefik_letsencrypt"
)

for volume in "${REQUIRED_VOLUMES[@]}"; do
    if docker volume ls --format "{{.Name}}" | grep -q "^${volume}$"; then
        log_pass "Volume $volume existe"
    else
        log_fail "Volume $volume não encontrado"
    fi
done

# ===== TESTE 5: VERIFICAR REDE =====
log_test "Verificando rede traefik-public..."
if docker network ls --format "{{.Name}}" | grep -q "traefik-public"; then
    log_pass "Rede traefik-public existe"
else
    log_fail "Rede traefik-public não encontrada"
fi

# ===== TESTE 6: VERIFICAR SERVIÇOS RODANDO =====
log_test "Verificando status dos serviços..."

# MySQL
if docker service ls --format "{{.Name}} {{.Replicas}}" | grep "${STACK_NAME}_mysql" | grep -q "1/1"; then
    log_pass "MySQL está rodando (1/1)"
else
    log_fail "MySQL não está rodando corretamente"
fi

# Backend
if docker service ls --format "{{.Name}} {{.Replicas}}" | grep "${STACK_NAME}_backend" | grep -q "1/1"; then
    log_pass "Backend está rodando (1/1)"
else
    log_fail "Backend não está rodando corretamente"
fi

# Traefik
if docker service ls --format "{{.Name}} {{.Replicas}}" | grep "${STACK_NAME}_traefik" | grep -q "1/1"; then
    log_pass "Traefik está rodando (1/1)"
else
    log_fail "Traefik não está rodando corretamente"
fi

# ===== TESTE 7: VERIFICAR CONECTIVIDADE MYSQL =====
log_test "Verificando conectividade MySQL..."

MYSQL_CONTAINER=$(docker ps -q -f name="${STACK_NAME}_mysql")

if [[ -n "$MYSQL_CONTAINER" ]]; then
    if docker exec "$MYSQL_CONTAINER" mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" &>/dev/null; then
        log_pass "MySQL está respondendo a pings"
        
        # Verificar databases
        DBS=$(docker exec "$MYSQL_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep "${DB_NAME:-appdb}" || true)
        if [[ -n "$DBS" ]]; then
            log_pass "Database '${DB_NAME:-appdb}' existe"
        else
            log_fail "Database '${DB_NAME:-appdb}' não encontrado"
        fi

        # Verificar usuários
        USERS=$(docker exec "$MYSQL_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT User FROM mysql.user WHERE User IN ('${DB_USER:-root}', '${LEGACY_DB_USER:-legacy_user}');" 2>/dev/null | grep -E "(${DB_USER:-root}|${LEGACY_DB_USER:-legacy_user})" || true)
        if [[ -n "$USERS" ]]; then
            log_pass "Usuários da aplicação existem"
        else
            log_fail "Usuários da aplicação não encontrados"
        fi
    else
        log_fail "MySQL não está respondendo"
    fi
else
    log_fail "Container MySQL não encontrado"
fi

# ===== TESTE 8: VERIFICAR PORTAS =====
log_test "Verificando portas abertas..."

# MySQL (3306)
if netstat -tlnp 2>/dev/null | grep -q ":3306" || ss -tlnp 2>/dev/null | grep -q ":3306"; then
    log_pass "Porta MySQL (3306) está aberta"
else
    log_fail "Porta MySQL (3306) não está aberta"
fi

# HTTP (80)
if netstat -tlnp 2>/dev/null | grep -q ":80" || ss -tlnp 2>/dev/null | grep -q ":80"; then
    log_pass "Porta HTTP (80) está aberta"
else
    log_fail "Porta HTTP (80) não está aberta"
fi

# HTTPS (443)
if netstat -tlnp 2>/dev/null | grep -q ":443" || ss -tlnp 2>/dev/null | grep -q ":443"; then
    log_pass "Porta HTTPS (443) está aberta"
else
    log_fail "Porta HTTPS (443) não está aberta"
fi

# ===== TESTE 9: VERIFICAR LOGS RECENTES =====
log_test "Verificando logs dos serviços..."

echo ""
log_info "Últimas linhas do log do MySQL:"
docker service logs --tail 5 "${STACK_NAME}_mysql" 2>/dev/null || echo "Não foi possível obter logs"

echo ""
log_info "Últimas linhas do log do Backend:"
docker service logs --tail 5 "${STACK_NAME}_backend" 2>/dev/null || echo "Não foi possível obter logs"

# ===== TESTE 10: VERIFICAR CONECTIVIDADE EXTERNA =====
log_test "Verificando conectividade externa..."

SERVER_IP=$(hostname -I | awk '{print $1}')
log_info "IP do servidor: $SERVER_IP"

# Testar porta MySQL
if timeout 2 bash -c "</dev/tcp/$SERVER_IP/3306" 2>/dev/null; then
    log_pass "Porta MySQL (3306) acessível externamente"
else
    log_fail "Porta MySQL (3306) não acessível externamente"
fi

# ===== RELATÓRIO FINAL =====
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                       RELATÓRIO FINAL                          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Testes aprovados: $TESTS_PASSED"
echo "❌ Testes falhados: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN} TODOS OS TESTES PASSARAM!${NC}"
    echo "O sistema está funcionando corretamente."
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  ALGUNS TESTES FALHARAM!${NC}"
    echo "Verifique os problemas acima e execute as correções necessárias."
    EXIT_CODE=1
fi

echo ""
echo "� INFORMAÇÕES DE ACESSO:"
echo "   MySQL Host: $SERVER_IP"
echo "   MySQL Port: 3306"
echo ""
echo "� COMANDOS ÚTEIS:"
echo "   docker stack ps $STACK_NAME"
echo "   docker service logs ${STACK_NAME}_mysql -f"
echo "   docker exec -it \$(docker ps -q -f name=${STACK_NAME}_mysql) mysql -u root -p"
echo ""

exit $EXIT_CODE