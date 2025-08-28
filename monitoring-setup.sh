#!/bin/bash

# ===== MONITORING AND ALERTING SETUP =====
# Configure comprehensive monitoring for all microservices

set -e

echo "📊 Setting up monitoring and alerting for microservices..."

# Configuration
PROJECT_DIR="/opt/conexao-microservices"
MONITORING_DIR="$PROJECT_DIR/monitoring"
GRAFANA_DIR="$MONITORING_DIR/grafana"
PROMETHEUS_DIR="$MONITORING_DIR/prometheus"
ALERTMANAGER_DIR="$MONITORING_DIR/alertmanager"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Create monitoring directories
create_directories() {
    log "Creating monitoring directories..."
    
    mkdir -p "$GRAFANA_DIR/dashboards"
    mkdir -p "$GRAFANA_DIR/provisioning/dashboards"
    mkdir -p "$GRAFANA_DIR/provisioning/datasources"
    mkdir -p "$PROMETHEUS_DIR"
    mkdir -p "$ALERTMANAGER_DIR"
    
    success "Monitoring directories created"
}

# Create Prometheus configuration
create_prometheus_config() {
    log "Creating Prometheus configuration..."
    
    cat > "$PROMETHEUS_DIR/prometheus.yml" << EOF
# ===== PROMETHEUS CONFIGURATION =====
# Monitoring configuration for Conexão de Sorte microservices

global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'conexao-microservices'
    environment: 'production'

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: /metrics
    scrape_interval: 15s

  # Traefik monitoring
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
    metrics_path: /metrics
    scrape_interval: 15s

  # Authentication Microservice
  - job_name: 'auth-microservice'
    static_configs:
      - targets: ['auth-microservice:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s
    basic_auth:
      username: 'prometheus'
      password: 'monitoring123'

  # Results Microservice
  - job_name: 'results-microservice'
    static_configs:
      - targets: ['results-microservice:8081']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # Chat Microservice
  - job_name: 'chat-microservice'
    static_configs:
      - targets: ['chat-microservice:8082']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # Notifications Microservice
  - job_name: 'notifications-microservice'
    static_configs:
      - targets: ['notifications-microservice:8083']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # Audit Microservice
  - job_name: 'audit-microservice'
    static_configs:
      - targets: ['audit-microservice:8084']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # Observability Microservice
  - job_name: 'observability-microservice'
    static_configs:
      - targets: ['observability-microservice:8085']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # Scheduler Microservice
  - job_name: 'scheduler-microservice'
    static_configs:
      - targets: ['scheduler-microservice:8086']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # Crypto Microservice
  - job_name: 'crypto-microservice'
    static_configs:
      - targets: ['crypto-microservice:8087']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  # MySQL Exporter
  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']
    scrape_interval: 30s

  # Redis Exporter
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
    scrape_interval: 30s

  # Node Exporter (System metrics)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s

  # cAdvisor (Container metrics)
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 30s
EOF

    success "Prometheus configuration created"
}

# Create Prometheus alert rules
create_alert_rules() {
    log "Creating Prometheus alert rules..."
    
    cat > "$PROMETHEUS_DIR/alert_rules.yml" << EOF
# ===== PROMETHEUS ALERT RULES =====
# Alert rules for Conexão de Sorte microservices

groups:
  # System-level alerts
  - name: system_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for {{ \$labels.instance }}"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85% for {{ \$labels.instance }}"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
          description: "Disk space is below 10% for {{ \$labels.instance }}"

  # Microservice health alerts
  - name: microservice_health
    rules:
      - alert: MicroserviceDown
        expr: up{job=~".*-microservice"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Microservice is down"
          description: "{{ \$labels.job }} has been down for more than 1 minute"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 5% for {{ \$labels.job }}"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High response time"
          description: "95th percentile response time is above 2s for {{ \$labels.job }}"

  # Database alerts
  - name: database_alerts
    rules:
      - alert: DatabaseConnectionsHigh
        expr: mysql_global_status_threads_connected / mysql_global_variables_max_connections * 100 > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High database connections"
          description: "MySQL connections are above 80% of max_connections"

      - alert: DatabaseSlowQueries
        expr: rate(mysql_global_status_slow_queries[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Database slow queries detected"
          description: "Slow query rate is above 0.1 queries/second"

  # Redis alerts
  - name: redis_alerts
    rules:
      - alert: RedisMemoryHigh
        expr: redis_memory_used_bytes / redis_memory_max_bytes * 100 > 90
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Redis memory usage high"
          description: "Redis memory usage is above 90%"

      - alert: RedisConnectionsHigh
        expr: redis_connected_clients > 100
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High Redis connections"
          description: "Redis has more than 100 connected clients"

  # SSL Certificate alerts
  - name: ssl_alerts
    rules:
      - alert: SSLCertificateExpiringSoon
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon"
          description: "SSL certificate for {{ \$labels.instance }} expires in less than 30 days"

      - alert: SSLCertificateExpired
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "SSL certificate expired"
          description: "SSL certificate for {{ \$labels.instance }} has expired"
EOF

    success "Prometheus alert rules created"
}

# Create Grafana datasource configuration
create_grafana_datasource() {
    log "Creating Grafana datasource configuration..."
    
    cat > "$GRAFANA_DIR/provisioning/datasources/prometheus.yml" << EOF
# ===== GRAFANA DATASOURCES =====
# Datasource configuration for Grafana

apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
    basicAuth: false
    jsonData:
      timeInterval: "15s"
      queryTimeout: "60s"
      httpMethod: "POST"
EOF

    success "Grafana datasource configured"
}

# Create Grafana dashboard provisioning
create_grafana_dashboards() {
    log "Creating Grafana dashboard configuration..."
    
    cat > "$GRAFANA_DIR/provisioning/dashboards/default.yml" << EOF
# ===== GRAFANA DASHBOARDS =====
# Dashboard provisioning configuration

apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    # Create microservices overview dashboard
    cat > "$GRAFANA_DIR/dashboards/microservices-overview.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Conexão de Sorte - Microservices Overview",
    "tags": ["microservices", "conexao", "overview"],
    "style": "dark",
    "timezone": "America/Sao_Paulo",
    "panels": [
      {
        "id": 1,
        "title": "Services Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=~\".*-microservice\"}",
            "legendFormat": "{{job}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (job)",
            "legendFormat": "{{job}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Response Time (95th percentile)",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le))",
            "legendFormat": "{{job}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (job) / sum(rate(http_requests_total[5m])) by (job) * 100",
            "legendFormat": "{{job}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "10s"
  }
}
EOF

    success "Grafana dashboards created"
}

# Create AlertManager configuration
create_alertmanager_config() {
    log "Creating AlertManager configuration..."
    
    cat > "$ALERTMANAGER_DIR/alertmanager.yml" << EOF
# ===== ALERTMANAGER CONFIGURATION =====
# Alert routing and notification configuration

global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@conexaodesorte.com.br'
  smtp_auth_username: 'facilitaservicos.dev@gmail.com'
  smtp_auth_password: 'your_app_password_here'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'

  - name: 'critical-alerts'
    email_configs:
      - to: 'admin@conexaodesorte.com.br'
        subject: '🚨 CRITICAL: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          Severity: {{ .Labels.severity }}
          {{ end }}
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts-critical'
        title: '🚨 Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

  - name: 'warning-alerts'
    email_configs:
      - to: 'monitoring@conexaodesorte.com.br'
        subject: '⚠️  WARNING: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          Severity: {{ .Labels.severity }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF

    success "AlertManager configuration created"
}

# Create monitoring Docker Compose extension
create_monitoring_compose() {
    log "Creating monitoring Docker Compose configuration..."
    
    cat > "$PROJECT_DIR/docker-compose.monitoring.yml" << EOF
# ===== MONITORING STACK =====
# Prometheus, Grafana, AlertManager and exporters

version: '3.8'

networks:
  conexao-network:
    external: true

volumes:
  prometheus_data:
    driver: local
  grafana_data:
    driver: local

services:
  # Prometheus - Metrics collection
  prometheus:
    image: prom/prometheus:v2.47.0
    container_name: conexao-prometheus
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
      - '--log.level=info'
    labels:
      - traefik.enable=true
      - traefik.http.routers.prometheus.rule=Host(\`monitoring.conexaodesorte.com.br\`) && PathPrefix(\`/prometheus\`)
      - traefik.http.routers.prometheus.entrypoints=websecure
      - traefik.http.routers.prometheus.tls.certresolver=letsencrypt
      - traefik.http.routers.prometheus.middlewares=admin-auth@file
      - traefik.http.services.prometheus.loadbalancer.server.port=9090

  # Grafana - Dashboards and visualization
  grafana:
    image: grafana/grafana:10.1.1
    container_name: conexao-grafana
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=GrafanaConexao2024!
      - GF_SERVER_ROOT_URL=https://monitoring.conexaodesorte.com.br/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
      - GF_DATABASE_TYPE=sqlite3
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    labels:
      - traefik.enable=true
      - traefik.http.routers.grafana.rule=Host(\`monitoring.conexaodesorte.com.br\`) && PathPrefix(\`/grafana\`)
      - traefik.http.routers.grafana.entrypoints=websecure
      - traefik.http.routers.grafana.tls.certresolver=letsencrypt
      - traefik.http.services.grafana.loadbalancer.server.port=3000

  # AlertManager - Alert routing
  alertmanager:
    image: prom/alertmanager:v0.26.0
    container_name: conexao-alertmanager
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
      - '--web.route-prefix=/'
    labels:
      - traefik.enable=true
      - traefik.http.routers.alertmanager.rule=Host(\`monitoring.conexaodesorte.com.br\`) && PathPrefix(\`/alertmanager\`)
      - traefik.http.routers.alertmanager.entrypoints=websecure
      - traefik.http.routers.alertmanager.tls.certresolver=letsencrypt
      - traefik.http.routers.alertmanager.middlewares=admin-auth@file

  # Node Exporter - System metrics
  node-exporter:
    image: prom/node-exporter:v1.6.1
    container_name: conexao-node-exporter
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

  # cAdvisor - Container metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.2
    container_name: conexao-cadvisor
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg:/dev/kmsg

  # MySQL Exporter
  mysql-exporter:
    image: prom/mysqld-exporter:v0.15.0
    container_name: conexao-mysql-exporter
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "9104:9104"
    environment:
      - DATA_SOURCE_NAME=exporter:password@(mysql:3306)/
    command:
      - '--config.my-cnf=/cfg/.my.cnf'
      - '--collect.global_status'
      - '--collect.info_schema.innodb_metrics'
      - '--collect.auto_increment.columns'
      - '--collect.info_schema.processlist'
      - '--collect.binlog_size'
      - '--collect.info_schema.tablestats'
      - '--collect.global_variables'
      - '--collect.info_schema.query_response_time'
      - '--collect.info_schema.userstats'
      - '--collect.info_schema.tables'
      - '--collect.perf_schema.tablelocks'
      - '--collect.perf_schema.file_events'
      - '--collect.perf_schema.eventswaits'
      - '--collect.perf_schema.indexiowaits'
      - '--collect.perf_schema.tableiowaits'

  # Redis Exporter
  redis-exporter:
    image: oliver006/redis_exporter:v1.53.0
    container_name: conexao-redis-exporter
    restart: unless-stopped
    networks:
      - conexao-network
    ports:
      - "9121:9121"
    environment:
      - REDIS_ADDR=redis://redis:6379
      - REDIS_PASSWORD=your_redis_password
EOF

    success "Monitoring Docker Compose created"
}

# Create monitoring health check script
create_health_check_script() {
    log "Creating monitoring health check script..."
    
    cat > "$PROJECT_DIR/health-check-monitoring.sh" << 'EOF'
#!/bin/bash

# ===== MONITORING HEALTH CHECK =====
# Verify all monitoring components are working

echo "🔍 Checking monitoring components health..."

# Check Prometheus
if curl -f -s http://localhost:9090/-/healthy > /dev/null; then
    echo "✅ Prometheus is healthy"
else
    echo "❌ Prometheus is not responding"
fi

# Check Grafana
if curl -f -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
fi

# Check AlertManager
if curl -f -s http://localhost:9093/-/healthy > /dev/null; then
    echo "✅ AlertManager is healthy"
else
    echo "❌ AlertManager is not responding"
fi

# Check exporters
if curl -f -s http://localhost:9100/metrics > /dev/null; then
    echo "✅ Node Exporter is healthy"
else
    echo "❌ Node Exporter is not responding"
fi

if curl -f -s http://localhost:8081/healthz > /dev/null; then
    echo "✅ cAdvisor is healthy"
else
    echo "❌ cAdvisor is not responding"
fi

echo ""
echo "📊 Monitoring URLs:"
echo "  • Prometheus: http://localhost:9090"
echo "  • Grafana: http://localhost:3001 (admin/GrafanaConexao2024!)"
echo "  • AlertManager: http://localhost:9093"
echo ""
echo "🌐 External URLs:"
echo "  • Monitoring: https://monitoring.conexaodesorte.com.br/grafana/"
echo "  • Prometheus: https://monitoring.conexaodesorte.com.br/prometheus/"
echo "  • AlertManager: https://monitoring.conexaodesorte.com.br/alertmanager/"
EOF

    chmod +x "$PROJECT_DIR/health-check-monitoring.sh"
    
    success "Health check script created"
}

# Main function
main() {
    echo "📊 Conexão de Sorte - Monitoring Setup"
    echo "======================================"
    echo "Setting up comprehensive monitoring stack..."
    echo ""
    
    create_directories
    create_prometheus_config
    create_alert_rules
    create_grafana_datasource
    create_grafana_dashboards
    create_alertmanager_config
    create_monitoring_compose
    create_health_check_script
    
    echo ""
    success "🎉 Monitoring setup completed successfully!"
    echo ""
    echo "🚀 To start monitoring stack:"
    echo "  docker compose -f docker-compose.monitoring.yml up -d"
    echo ""
    echo "📊 Access monitoring:"
    echo "  • Prometheus: http://localhost:9090"
    echo "  • Grafana: http://localhost:3001 (admin/GrafanaConexao2024!)"
    echo "  • AlertManager: http://localhost:9093"
    echo ""
    echo "🔧 Configuration files created:"
    echo "  • Prometheus: $PROMETHEUS_DIR/prometheus.yml"
    echo "  • Grafana: $GRAFANA_DIR/provisioning/"
    echo "  • AlertManager: $ALERTMANAGER_DIR/alertmanager.yml"
    echo ""
    echo "⚠️  Remember to:"
    echo "  1. Update email/Slack credentials in alertmanager.yml"
    echo "  2. Configure MySQL and Redis credentials"
    echo "  3. Set up firewall rules for monitoring ports"
    echo "  4. Configure SSL certificates for external access"
}

# Change to project directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Run main function
main "$@"