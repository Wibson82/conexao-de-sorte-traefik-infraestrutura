#!/bin/bash

# ===== SCRIPT DE CONFIGURAÇÃO DO AMBIENTE DE DESENVOLVIMENTO =====
# Sistema: Conexão de Sorte - Backend
# Função: Configurar ambiente de desenvolvimento local
# Versão: 1.0.0
# Data: $(date +"%d/%m/%Y")

set -euo pipefail

# ===== CONFIGURAÇÕES =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/setup-dev.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNÇÕES AUXILIARES =====
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# ===== VERIFICAÇÕES DE PRÉ-REQUISITOS =====
check_java() {
    log_info "Verificando Java..."
    
    if command -v java >/dev/null 2>&1; then
        local java_version
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
        
        if [[ "$java_version" -ge 21 ]]; then
            log_success "Java $java_version encontrado"
        else
            log_error "Java 21+ é necessário. Versão encontrada: $java_version"
            return 1
        fi
    else
        log_error "Java não encontrado. Instale Java 21+"
        return 1
    fi
}

check_maven() {
    log_info "Verificando Maven..."
    
    if command -v mvn >/dev/null 2>&1; then
        local maven_version
        maven_version=$(mvn -version | head -n1 | cut -d' ' -f3)
        log_success "Maven $maven_version encontrado"
    else
        log_error "Maven não encontrado. Instale Apache Maven"
        return 1
    fi
}

check_docker() {
    log_info "Verificando Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            local docker_version
            docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
            log_success "Docker $docker_version rodando"
        else
            log_error "Docker não está rodando. Inicie o Docker"
            return 1
        fi
    else
        log_error "Docker não encontrado. Instale Docker"
        return 1
    fi
}

check_docker_compose() {
    log_info "Verificando Docker Compose..."
    
    if command -v docker-compose >/dev/null 2>&1; then
        local compose_version
        compose_version=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker Compose $compose_version encontrado"
    else
        log_error "Docker Compose não encontrado. Instale Docker Compose"
        return 1
    fi
}

check_git() {
    log_info "Verificando Git..."
    
    if command -v git >/dev/null 2>&1; then
        local git_version
        git_version=$(git --version | cut -d' ' -f3)
        log_success "Git $git_version encontrado"
    else
        log_error "Git não encontrado. Instale Git"
        return 1
    fi
}

check_prerequisites() {
    log_info "Verificando pré-requisitos do ambiente de desenvolvimento..."
    
    local all_ok=true
    
    check_java || all_ok=false
    check_maven || all_ok=false
    check_docker || all_ok=false
    check_docker_compose || all_ok=false
    check_git || all_ok=false
    
    if $all_ok; then
        log_success "Todos os pré-requisitos foram verificados"
    else
        log_error "Alguns pré-requisitos não foram atendidos"
        return 1
    fi
}

# ===== CONFIGURAÇÃO DE DIRETÓRIOS =====
setup_directories() {
    log_info "Criando estrutura de diretórios..."
    
    local directories=(
        "logs"
        "backups"
        "backups/database"
        "backups/volumes"
        "backups/configs"
        "temp"
        "docs/adr"
        "docs/api"
        "docs/deployment"
        "deploy/configs"
        "deploy/secrets"
        "deploy/monitoring/dashboards"
        "deploy/monitoring/templates"
        "deploy/cron"
        "scripts/database"
        "scripts/deployment"
        "scripts/monitoring"
    )
    
    for dir in "${directories[@]}"; do
        local full_path="$PROJECT_ROOT/$dir"
        if [[ ! -d "$full_path" ]]; then
            mkdir -p "$full_path"
            log_success "Diretório criado: $dir"
        else
            log_info "Diretório já existe: $dir"
        fi
    done
    
    log_success "Estrutura de diretórios configurada"
}

# ===== CONFIGURAÇÃO DE ARQUIVOS DE AMBIENTE =====
setup_env_files() {
    log_info "Configurando arquivos de ambiente..."
    
    # .env para desenvolvimento
    local env_dev="$PROJECT_ROOT/.env.dev"
    if [[ ! -f "$env_dev" ]]; then
        cat > "$env_dev" << 'EOF'
# ===== AMBIENTE DE DESENVOLVIMENTO =====
# Conexão de Sorte - Backend

# Aplicação
SPRING_PROFILES_ACTIVE=dev
SERVER_PORT=8080
APP_NAME=conexao-de-sorte-backend
APP_VERSION=1.0.0

# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=conexao_sorte_dev
DB_USERNAME=dev_user
DB_PASSWORD=dev_password
DB_ROOT_PASSWORD=root_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_password

# JWT
JWT_SECRET=dev_jwt_secret_key_change_in_production
JWT_EXPIRATION=86400000

# Azure Key Vault (Dev)
AZURE_KEYVAULT_URI=https://dev-conexao-sorte-kv.vault.azure.net/
AZURE_CLIENT_ID=your_dev_client_id
AZURE_CLIENT_SECRET=your_dev_client_secret
AZURE_TENANT_ID=your_tenant_id

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_ADMIN_PASSWORD=admin_password
ALERTMANAGER_PORT=9093

# SonarQube
SONARQUBE_PORT=9000
SONARQUBE_ADMIN_PASSWORD=admin_password

# Logging
LOG_LEVEL=DEBUG
LOG_FILE_PATH=./logs/application.log

# LGPD
LGPD_RETENTION_DAYS=2555  # 7 anos
LGPD_ANONYMIZATION_ENABLED=true
LGPD_AUDIT_ENABLED=true

# Email (Dev)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=dev@conexaosorte.com
MAIL_PASSWORD=dev_email_password
MAIL_FROM=dev@conexaosorte.com

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE=0 2 * * *
BACKUP_ENCRYPTION_KEY=dev_backup_encryption_key
EOF
        log_success "Arquivo .env.dev criado"
    else
        log_info "Arquivo .env.dev já existe"
    fi
    
    # .env para testes
    local env_test="$PROJECT_ROOT/.env.test"
    if [[ ! -f "$env_test" ]]; then
        cat > "$env_test" << 'EOF'
# ===== AMBIENTE DE TESTES =====
# Conexão de Sorte - Backend

# Aplicação
SPRING_PROFILES_ACTIVE=test
SERVER_PORT=8081
APP_NAME=conexao-de-sorte-backend-test
APP_VERSION=1.0.0

# Database (H2 em memória para testes)
DB_HOST=localhost
DB_PORT=3307
DB_NAME=conexao_sorte_test
DB_USERNAME=test_user
DB_PASSWORD=test_password

# JWT
JWT_SECRET=test_jwt_secret_key
JWT_EXPIRATION=3600000

# Logging
LOG_LEVEL=WARN
LOG_FILE_PATH=./logs/test.log

# LGPD (Testes)
LGPD_RETENTION_DAYS=1
LGPD_ANONYMIZATION_ENABLED=true
LGPD_AUDIT_ENABLED=true
EOF
        log_success "Arquivo .env.test criado"
    else
        log_info "Arquivo .env.test já existe"
    fi
    
    # Arquivo .gitignore para ambientes
    local gitignore_env="$PROJECT_ROOT/.gitignore.env"
    if [[ ! -f "$gitignore_env" ]]; then
        cat > "$gitignore_env" << 'EOF'
# Arquivos de ambiente
.env
.env.local
.env.prod
.env.staging
*.env

# Logs
logs/
*.log

# Backups
backups/

# Temporários
temp/
tmp/

# Secrets
deploy/secrets/
*.key
*.pem
*.p12
*.jks

# IDE
.vscode/
.idea/
*.iml

# OS
.DS_Store
Thumbs.db
EOF
        log_success "Arquivo .gitignore.env criado"
    else
        log_info "Arquivo .gitignore.env já existe"
    fi
}

# ===== CONFIGURAÇÃO DO MAVEN =====
setup_maven() {
    log_info "Configurando Maven..."
    
    # Verificar se pom.xml existe
    if [[ ! -f "$PROJECT_ROOT/pom.xml" ]]; then
        log_warning "pom.xml não encontrado. Pulando configuração do Maven."
        return 0
    fi
    
    # Limpar e compilar projeto
    log_info "Limpando e compilando projeto..."
    cd "$PROJECT_ROOT"
    
    if mvn clean compile -q; then
        log_success "Projeto compilado com sucesso"
    else
        log_error "Falha na compilação do projeto"
        return 1
    fi
    
    # Baixar dependências
    log_info "Baixando dependências..."
    if mvn dependency:resolve -q; then
        log_success "Dependências baixadas"
    else
        log_warning "Algumas dependências podem não ter sido baixadas"
    fi
}

# ===== CONFIGURAÇÃO DO DOCKER =====
setup_docker() {
    log_info "Configurando ambiente Docker..."
    
    cd "$PROJECT_ROOT"
    
    # Criar volumes
    log_info "Criando volumes Docker..."
    if [[ -f "$SCRIPT_DIR/setup-volumes.sh" ]]; then
        bash "$SCRIPT_DIR/setup-volumes.sh" create
    else
        log_warning "Script setup-volumes.sh não encontrado"
    fi
    
    # Verificar docker-compose.yml
    if [[ -f "docker-compose.yml" ]]; then
        log_info "Validando docker-compose.yml..."
        if docker-compose config >/dev/null 2>&1; then
            log_success "docker-compose.yml válido"
        else
            log_error "docker-compose.yml inválido"
            return 1
        fi
    else
        log_warning "docker-compose.yml não encontrado"
    fi
    
    # Verificar docker-compose.dev.yml
    if [[ -f "docker-compose.dev.yml" ]]; then
        log_info "Validando docker-compose.dev.yml..."
        if docker-compose -f docker-compose.yml -f docker-compose.dev.yml config >/dev/null 2>&1; then
            log_success "docker-compose.dev.yml válido"
        else
            log_error "docker-compose.dev.yml inválido"
            return 1
        fi
    else
        log_warning "docker-compose.dev.yml não encontrado"
    fi
}

# ===== CONFIGURAÇÃO DO GIT =====
setup_git() {
    log_info "Configurando Git..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar se é um repositório Git
    if [[ ! -d ".git" ]]; then
        log_warning "Não é um repositório Git. Inicializando..."
        git init
        log_success "Repositório Git inicializado"
    fi
    
    # Configurar hooks do Git
    local hooks_dir=".git/hooks"
    
    # Pre-commit hook para verificar código
    cat > "$hooks_dir/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook para Conexão de Sorte

echo "Executando verificações pre-commit..."

# Verificar se há arquivos .env sendo commitados
if git diff --cached --name-only | grep -E "\.(env|key|pem|p12|jks)$"; then
    echo "ERRO: Arquivos de ambiente/secrets detectados no commit!"
    echo "Remova estes arquivos antes de fazer commit:"
    git diff --cached --name-only | grep -E "\.(env|key|pem|p12|jks)$"
    exit 1
fi

# Verificar formato do código Java (se existir)
if command -v mvn >/dev/null 2>&1 && [[ -f "pom.xml" ]]; then
    echo "Verificando formato do código..."
    if ! mvn spotless:check -q; then
        echo "AVISO: Código não está formatado corretamente"
        echo "Execute: mvn spotless:apply"
    fi
fi

echo "Verificações pre-commit concluídas"
EOF
    
    chmod +x "$hooks_dir/pre-commit"
    log_success "Git hooks configurados"
    
    # Configurar .gitignore se não existir
    if [[ ! -f ".gitignore" ]]; then
        cat > ".gitignore" << 'EOF'
# Compiled class file
*.class

# Log file
*.log
logs/

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# virtual machine crash logs
hs_err_pid*
replay_pid*

# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iws
*.iml
*.ipr
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Environment files
.env
.env.local
.env.prod
.env.staging
*.env

# Secrets
deploy/secrets/
*.key
*.pem
*.p12
*.jks

# Backups
backups/

# Temporary files
temp/
tmp/

# Docker
.dockerignore
EOF
        log_success ".gitignore criado"
    else
        log_info ".gitignore já existe"
    fi
}

# ===== CONFIGURAÇÃO DE SCRIPTS AUXILIARES =====
setup_helper_scripts() {
    log_info "Criando scripts auxiliares..."
    
    # Script para iniciar ambiente de desenvolvimento
    cat > "$SCRIPT_DIR/start-dev.sh" << 'EOF'
#!/bin/bash
# Script para iniciar ambiente de desenvolvimento

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Iniciando ambiente de desenvolvimento..."

cd "$PROJECT_ROOT"

# Carregar variáveis de ambiente
if [[ -f ".env.dev" ]]; then
    export $(cat .env.dev | grep -v '^#' | xargs)
fi

# Iniciar serviços Docker
echo "Iniciando serviços Docker..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Aguardar serviços ficarem prontos
echo "Aguardando serviços ficarem prontos..."
sleep 10

# Verificar status dos serviços
echo "Status dos serviços:"
docker-compose ps

echo "Ambiente de desenvolvimento iniciado!"
echo "Aplicação: http://localhost:8080"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "Prometheus: http://localhost:9090"
echo "SonarQube: http://localhost:9000 (admin/admin)"
EOF
    
    chmod +x "$SCRIPT_DIR/start-dev.sh"
    log_success "Script start-dev.sh criado"
    
    # Script para parar ambiente de desenvolvimento
    cat > "$SCRIPT_DIR/stop-dev.sh" << 'EOF'
#!/bin/bash
# Script para parar ambiente de desenvolvimento

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Parando ambiente de desenvolvimento..."

cd "$PROJECT_ROOT"

# Parar serviços Docker
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

echo "Ambiente de desenvolvimento parado!"
EOF
    
    chmod +x "$SCRIPT_DIR/stop-dev.sh"
    log_success "Script stop-dev.sh criado"
    
    # Script para executar testes
    cat > "$SCRIPT_DIR/run-tests.sh" << 'EOF'
#!/bin/bash
# Script para executar testes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Executando testes..."

cd "$PROJECT_ROOT"

# Carregar variáveis de ambiente de teste
if [[ -f ".env.test" ]]; then
    export $(cat .env.test | grep -v '^#' | xargs)
fi

# Executar testes unitários
echo "Executando testes unitários..."
mvn test

# Executar testes de integração
echo "Executando testes de integração..."
mvn verify -P integration-tests

# Gerar relatório de cobertura
echo "Gerando relatório de cobertura..."
mvn jacoco:report

echo "Testes concluídos!"
echo "Relatório de cobertura: target/site/jacoco/index.html"
EOF
    
    chmod +x "$SCRIPT_DIR/run-tests.sh"
    log_success "Script run-tests.sh criado"
    
    # Script para build da aplicação
    cat > "$SCRIPT_DIR/build-app.sh" << 'EOF'
#!/bin/bash
# Script para build da aplicação

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Fazendo build da aplicação..."

cd "$PROJECT_ROOT"

# Limpar e compilar
echo "Limpando e compilando..."
mvn clean compile

# Executar testes
echo "Executando testes..."
mvn test

# Gerar JAR
echo "Gerando JAR..."
mvn package -DskipTests

# Build da imagem Docker
echo "Fazendo build da imagem Docker..."
# Gerar tag baseada na data brasileira
BRAZIL_DATE=$(TZ='America/Sao_Paulo' date +'%d-%m-%Y-%H')
docker build -t facilita/conexao-de-sorte-backend:$BRAZIL_DATE .

echo "Build concluído!"
echo "JAR: target/conexao-de-sorte-backend.jar"
echo "Imagem Docker: facilita/conexao-de-sorte-backend:$BRAZIL_DATE"
EOF
    
    chmod +x "$SCRIPT_DIR/build-app.sh"
    log_success "Script build-app.sh criado"
}

# ===== VERIFICAÇÃO FINAL =====
verify_setup() {
    log_info "Verificando configuração do ambiente..."
    
    local all_ok=true
    
    # Verificar estrutura de diretórios
    local required_dirs=(
        "logs"
        "backups"
        "docs"
        "deploy"
        "scripts"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_success "✓ Diretório $dir existe"
        else
            log_error "✗ Diretório $dir não encontrado"
            all_ok=false
        fi
    done
    
    # Verificar arquivos de ambiente
    local env_files=(
        ".env.dev"
        ".env.test"
    )
    
    for file in "${env_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "✓ Arquivo $file existe"
        else
            log_error "✗ Arquivo $file não encontrado"
            all_ok=false
        fi
    done
    
    # Verificar scripts
    local scripts=(
        "start-dev.sh"
        "stop-dev.sh"
        "run-tests.sh"
        "build-app.sh"
        "setup-volumes.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" && -x "$SCRIPT_DIR/$script" ]]; then
            log_success "✓ Script $script existe e é executável"
        else
            log_error "✗ Script $script não encontrado ou não é executável"
            all_ok=false
        fi
    done
    
    if $all_ok; then
        log_success "Ambiente de desenvolvimento configurado com sucesso!"
        
        echo
        echo "===== PRÓXIMOS PASSOS ====="
        echo "1. Revisar e ajustar arquivos .env.dev e .env.test"
        echo "2. Configurar secrets no Azure Key Vault"
        echo "3. Executar: ./scripts/start-dev.sh"
        echo "4. Acessar: http://localhost:8080"
        echo
        echo "===== SCRIPTS DISPONÍVEIS ====="
        echo "./scripts/start-dev.sh      - Iniciar ambiente de desenvolvimento"
        echo "./scripts/stop-dev.sh       - Parar ambiente de desenvolvimento"
        echo "./scripts/run-tests.sh      - Executar testes"
        echo "./scripts/build-app.sh      - Build da aplicação"
        echo "./scripts/setup-volumes.sh  - Gerenciar volumes Docker"
        echo
    else
        log_error "Alguns problemas foram encontrados na configuração"
        return 1
    fi
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    log_info "Iniciando configuração do ambiente de desenvolvimento"
    
    # Criar diretório de logs
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Executar configurações
    check_prerequisites
    setup_directories
    setup_env_files
    setup_maven
    setup_docker
    setup_git
    setup_helper_scripts
    verify_setup
    
    log_success "Configuração do ambiente de desenvolvimento concluída!"
}

# ===== EXECUÇÃO =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi