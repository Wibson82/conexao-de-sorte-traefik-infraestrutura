#!/bin/bash
# =============================================================================
# SCRIPT DE INICIALIZAÇÃO DO BACKEND - AMBIENTE DE PRODUÇÃO
# =============================================================================
# Este script inicializa o backend Spring Boot no ambiente de produção
# com configurações específicas para VPS Hostinger com Azure Key Vault

set -euo pipefail

# ===== CONFIGURAÇÕES =====
APP_JAR="/app/app.jar"
LOG_DIR="/app/logs"
TMP_DIR="/app/tmp"
ENVIRONMENT="${ENVIRONMENT:-production}"
# Usa porta 8080 para produção por padrão
SERVER_PORT="${SERVER_PORT:-8080}"

# ===== FUNÇÕES DE LOG =====
log_info() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] [PROD] $1"
}

log_warn() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] [PROD] $1"
}

log_error() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] [PROD] $1" >&2
}

# ===== VERIFICAÇÕES INICIAIS =====
check_environment() {
    log_info "Verificando ambiente de produção..."

    # Verificar se o JAR existe
    if [[ ! -f "$APP_JAR" ]]; then
        log_error "JAR da aplicação não encontrado: $APP_JAR"
        exit 1
    fi

    # Verificar diretórios
    mkdir -p "$LOG_DIR" "$TMP_DIR"

    # Verificar Java
    if ! command -v java >/dev/null 2>&1; then
        log_error "Java não encontrado"
        exit 1
    fi

    local java_version
    java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
    log_info "Java version: $java_version"

    if [[ "$java_version" -lt 24 ]]; then
        log_error "Java 24+ é necessário. Versão encontrada: $java_version"
        exit 1
    fi
}

# ===== CONFIGURAÇÕES DE AMBIENTE DE PRODUÇÃO =====
setup_production_environment() {
    log_info "Configurando ambiente de produção..."

    # Configurações específicas para produção
    export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-prod,azure}"
    export ENVIRONMENT="${ENVIRONMENT:-production}"
    export SERVER_PORT="${SERVER_PORT:-8080}"

    # Azure Key Vault habilitado por padrão em produção
    export AZURE_KEYVAULT_ENABLED="${AZURE_KEYVAULT_ENABLED:-true}"
    export AZURE_KEYVAULT_FALLBACK_ENABLED="${AZURE_KEYVAULT_FALLBACK_ENABLED:-true}"

    # Configurações de banco para produção (MySQL) - credenciais via variáveis ambiente
    export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://conexao-mysql:3306/conexao_de_sorte?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo&defaultAuthenticationPlugin=caching_sha2_password&authenticationPlugins=mysql_native_password,caching_sha2_password}"
    export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME}"
    export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD}"
    export SPRING_JPA_DATABASE_PLATFORM="${SPRING_JPA_DATABASE_PLATFORM:-org.hibernate.dialect.MySQL8Dialect}"

    # Configurações de logging para produção
    export LOGGING_LEVEL_ROOT="${LOGGING_LEVEL_ROOT:-INFO}"
    export LOGGING_LEVEL_BR_TEC_FACILITASERVICOS="${LOGGING_LEVEL_BR_TEC_FACILITASERVICOS:-INFO}"
    export LOGGING_FILE_NAME="$LOG_DIR/conexao-prod.log"

    # Configurações de cache para produção
    export SPRING_CACHE_TYPE="${SPRING_CACHE_TYPE:-redis}"

    # Timezone
    export TZ="${TZ:-America/Sao_Paulo}"

    log_info "Ambiente de produção configurado"
    log_info "Porta do servidor: $SERVER_PORT"
    log_info "Profile ativo: $SPRING_PROFILES_ACTIVE"
    log_info "Azure Key Vault: $AZURE_KEYVAULT_ENABLED"
    log_info "Timezone: $TZ"
}

# ===== VERIFICAÇÃO DE SAÚDE =====
wait_for_health() {
    log_info "Aguardando aplicação ficar saudável..."
    
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f "http://localhost:$SERVER_PORT/actuator/health" >/dev/null 2>&1; then
            log_info "Aplicação está saudável!"
            return 0
        fi
        
        log_info "Tentativa $attempt/$max_attempts - Aguardando aplicação..."
        sleep 10
        ((attempt++))
    done
    
    log_error "Aplicação não ficou saudável após $max_attempts tentativas"
    return 1
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    log_info "=== INICIANDO BACKEND - AMBIENTE DE PRODUÇÃO ==="
    log_info "Timestamp: $(date)"
    log_info "Hostname: $(hostname)"
    log_info "User: $(whoami)"
    log_info "Environment: $ENVIRONMENT"

    # Executar verificações e configurações
    check_environment
    setup_production_environment

    # Configurar JVM options específicas para produção
    local jvm_opts="${JAVA_OPTS:--server -Xms256m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/tmp/ -Djava.security.egd=file:/dev/./urandom}"
    jvm_opts="$jvm_opts -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE"
    jvm_opts="$jvm_opts -Dserver.port=$SERVER_PORT"
    jvm_opts="$jvm_opts -Dlogging.file.name=$LOGGING_FILE_NAME"
    jvm_opts="$jvm_opts -Djava.io.tmpdir=$TMP_DIR"
    jvm_opts="$jvm_opts -Duser.timezone=$TZ"

    log_info "Iniciando aplicação Spring Boot..."
    log_info "JAR: $APP_JAR"
    log_info "JVM Options: $jvm_opts"

    # Iniciar aplicação em background para verificação de saúde
    java $jvm_opts -jar "$APP_JAR" &
    local app_pid=$!

    # Aguardar aplicação ficar saudável
    if wait_for_health; then
        log_info "=== BACKEND DE PRODUÇÃO INICIADO COM SUCESSO ==="
        log_info "URL: http://localhost:$SERVER_PORT"
        log_info "Health Check: http://localhost:$SERVER_PORT/actuator/health"
        log_info "Environment: $ENVIRONMENT"
        log_info "PID: $app_pid"
    else
        log_error "Falha ao iniciar aplicação"
        kill $app_pid 2>/dev/null || true
        exit 1
    fi

    # Aguardar o processo da aplicação
    wait $app_pid
}

# ===== TRATAMENTO DE SINAIS =====
trap 'log_info "Recebido sinal de término. Finalizando aplicação..."; exit 0' SIGTERM SIGINT

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi