#!/bin/bash

# =============================================================================
# SCRIPT DE CONFIGURAÇÃO DE FERRAMENTAS DE ACOMPANHAMENTO
# Projeto: Conexão de Sorte - Segurança e Criptografia
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MONITORING_DIR="$PROJECT_ROOT/monitoring"
LOGS_DIR="$PROJECT_ROOT/logs/monitoring"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
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

# Função para verificar dependências
check_dependencies() {
    log_info "🔍 Verificando dependências..."
    
    local deps=("docker" "docker-compose" "curl" "jq")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências e execute novamente"
        exit 1
    fi
    
    log_success "Todas as dependências estão disponíveis"
}

# Criar estrutura de diretórios
setup_directories() {
    log_info "📁 Criando estrutura de diretórios..."
    
    mkdir -p "$MONITORING_DIR"/{prometheus,grafana,sonarqube,owasp}
    mkdir -p "$LOGS_DIR"
    mkdir -p "$PROJECT_ROOT/reports"/{security,performance,quality}
    
    log_success "Estrutura de diretórios criada"
}

# Configurar Prometheus para métricas
setup_prometheus() {
    log_info "📊 Configurando Prometheus..."
    
    cat > "$MONITORING_DIR/prometheus/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "security_rules.yml"

scrape_configs:
  - job_name: 'conexao-de-sorte-backend'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 10s
    
  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['mysql-exporter:9104']
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s
EOF

    # Regras de alerta para segurança
    cat > "$MONITORING_DIR/prometheus/security_rules.yml" << 'EOF'
groups:
  - name: security_alerts
    rules:
      - alert: HighFailedAuthRate
        expr: rate(auth_failures_total[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Alta taxa de falhas de autenticação"
          
      - alert: EncryptionFailure
        expr: encryption_errors_total > 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Falha na criptografia detectada"
          
      - alert: KeyRotationOverdue
        expr: key_age_days > 90
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "Rotação de chaves em atraso"
EOF

    log_success "Prometheus configurado"
}

# Configurar Grafana Dashboard
setup_grafana() {
    log_info "📈 Configurando Grafana..."
    
    mkdir -p "$MONITORING_DIR/grafana/dashboards"
    mkdir -p "$MONITORING_DIR/grafana/provisioning"/{dashboards,datasources}
    
    # Configuração de datasource
    cat > "$MONITORING_DIR/grafana/provisioning/datasources/prometheus.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    # Dashboard de segurança
    cat > "$MONITORING_DIR/grafana/dashboards/security-dashboard.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Conexão de Sorte - Security Dashboard",
    "tags": ["security", "monitoring"],
    "timezone": "America/Sao_Paulo",
    "panels": [
      {
        "id": 1,
        "title": "Authentication Failures",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(auth_failures_total[5m])",
            "legendFormat": "Failures/sec"
          }
        ]
      },
      {
        "id": 2,
        "title": "Encryption Operations",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(encryption_operations_total[5m])",
            "legendFormat": "Encrypt/Decrypt per sec"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

    log_success "Grafana configurado"
}

# Configurar Docker Compose para monitoramento
setup_monitoring_compose() {
    log_info "🐳 Configurando Docker Compose para monitoramento..."
    
    cat > "$MONITORING_DIR/docker-compose.monitoring.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
EOF

    log_success "Docker Compose para monitoramento configurado"
}

# Configurar SonarQube
setup_sonarqube() {
    log_info "🔍 Configurando SonarQube..."
    
    cat > "$MONITORING_DIR/sonarqube/docker-compose.sonarqube.yml" << 'EOF'
version: '3.8'

services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    depends_on:
      - sonarqube-db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://sonarqube-db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ports:
      - "9000:9000"
    networks:
      - sonarqube

  sonarqube-db:
    image: postgres:13
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    networks:
      - sonarqube

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:

networks:
  sonarqube:
    driver: bridge
EOF

    # Script de configuração do SonarQube
    cat > "$MONITORING_DIR/sonarqube/configure-sonarqube.sh" << 'EOF'
#!/bin/bash

echo "🔍 Configurando projeto no SonarQube..."

# Aguardar SonarQube inicializar
sleep 60

# Criar projeto
curl -u admin:admin -X POST \
  "http://localhost:9000/api/projects/create" \
  -d "project=conexao-de-sorte&name=Conexao+de+Sorte"

# Gerar token
TOKEN=$(curl -u admin:admin -X POST \
  "http://localhost:9000/api/user_tokens/generate" \
  -d "name=conexao-de-sorte-token" | jq -r '.token')

echo "Token gerado: $TOKEN"
echo "SONAR_TOKEN=$TOKEN" > .env.sonar

echo "✅ SonarQube configurado com sucesso!"
EOF

    chmod +x "$MONITORING_DIR/sonarqube/configure-sonarqube.sh"
    
    log_success "SonarQube configurado"
}

# Criar scripts de inicialização
create_startup_scripts() {
    log_info "🚀 Criando scripts de inicialização..."
    
    # Script para iniciar monitoramento
    cat > "$MONITORING_DIR/start-monitoring.sh" << 'EOF'
#!/bin/bash

echo "🚀 Iniciando ferramentas de monitoramento..."

# Iniciar Prometheus e Grafana
cd monitoring
docker-compose -f docker-compose.monitoring.yml up -d

# Iniciar SonarQube
cd sonarqube
docker-compose -f docker-compose.sonarqube.yml up -d

echo "⏳ Aguardando serviços inicializarem..."
sleep 30

echo "✅ Ferramentas de monitoramento iniciadas!"
echo "📊 Prometheus: http://localhost:9090"
echo "📈 Grafana: http://localhost:3001 (admin/admin123)"
echo "🔍 SonarQube: http://localhost:9000 (admin/admin)"
EOF

    chmod +x "$MONITORING_DIR/start-monitoring.sh"
    
    # Script para parar monitoramento
    cat > "$MONITORING_DIR/stop-monitoring.sh" << 'EOF'
#!/bin/bash

echo "🛑 Parando ferramentas de monitoramento..."

cd monitoring
docker-compose -f docker-compose.monitoring.yml down

cd sonarqube
docker-compose -f docker-compose.sonarqube.yml down

echo "✅ Ferramentas de monitoramento paradas!"
EOF

    chmod +x "$MONITORING_DIR/stop-monitoring.sh"
    
    log_success "Scripts de inicialização criados"
}

# Função principal
main() {
    log_info "🛠️ Iniciando configuração de ferramentas de acompanhamento..."
    
    check_dependencies
    setup_directories
    setup_prometheus
    setup_grafana
    setup_monitoring_compose
    setup_sonarqube
    create_startup_scripts
    
    log_success "🎉 Configuração de ferramentas de acompanhamento concluída!"
    log_info "📋 Próximos passos:"
    log_info "  1. Execute: cd monitoring && ./start-monitoring.sh"
    log_info "  2. Configure o SonarQube: cd monitoring/sonarqube && ./configure-sonarqube.sh"
    log_info "  3. Acesse os dashboards nos URLs mostrados"
}

# Executar função principal
main "$@"
