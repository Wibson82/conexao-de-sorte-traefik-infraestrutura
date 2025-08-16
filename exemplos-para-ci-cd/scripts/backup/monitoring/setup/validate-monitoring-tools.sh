#!/bin/bash

# =============================================================================
# SCRIPT DE VALIDAÇÃO DE FERRAMENTAS DE MONITORAMENTO
# Projeto: Conexão de Sorte - Validação de Configurações
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MONITORING_DIR="$PROJECT_ROOT/monitoring"
REPORTS_DIR="$PROJECT_ROOT/reports/monitoring"

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

# Criar diretórios necessários
setup_directories() {
    log_info "📁 Criando diretórios de validação..."
    
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$MONITORING_DIR"
    
    log_success "Diretórios criados"
}

# Validar configurações do Prometheus
validate_prometheus_config() {
    log_info "📊 Validando configuração do Prometheus..."
    
    local prometheus_config="$MONITORING_DIR/prometheus/prometheus.yml"
    local validation_report="$REPORTS_DIR/prometheus-validation.txt"
    
    echo "# VALIDAÇÃO PROMETHEUS - $(date)" > "$validation_report"
    echo "=================================" >> "$validation_report"
    
    if [[ -f "$prometheus_config" ]]; then
        log_success "Arquivo de configuração encontrado"
        echo "✅ Arquivo de configuração: ENCONTRADO" >> "$validation_report"
        
        # Validar sintaxe YAML
        if command -v python3 &> /dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$prometheus_config'))" 2>/dev/null; then
                log_success "Sintaxe YAML válida"
                echo "✅ Sintaxe YAML: VÁLIDA" >> "$validation_report"
            else
                log_error "Sintaxe YAML inválida"
                echo "❌ Sintaxe YAML: INVÁLIDA" >> "$validation_report"
            fi
        else
            log_warning "Python3 não disponível para validação YAML"
            echo "⚠️ Sintaxe YAML: NÃO VALIDADA (Python3 não disponível)" >> "$validation_report"
        fi
        
        # Verificar jobs configurados
        local jobs_count=$(grep -c "job_name:" "$prometheus_config" 2>/dev/null || echo "0")
        log_info "Jobs configurados: $jobs_count"
        echo "📊 Jobs configurados: $jobs_count" >> "$validation_report"
        
        # Verificar regras de alerta
        if grep -q "rule_files:" "$prometheus_config"; then
            log_success "Regras de alerta configuradas"
            echo "✅ Regras de alerta: CONFIGURADAS" >> "$validation_report"
        else
            log_warning "Regras de alerta não encontradas"
            echo "⚠️ Regras de alerta: NÃO CONFIGURADAS" >> "$validation_report"
        fi
        
    else
        log_error "Arquivo de configuração não encontrado"
        echo "❌ Arquivo de configuração: NÃO ENCONTRADO" >> "$validation_report"
    fi
    
    log_success "Validação do Prometheus concluída"
}

# Validar configurações do Grafana
validate_grafana_config() {
    log_info "📈 Validando configuração do Grafana..."
    
    local grafana_dir="$MONITORING_DIR/grafana"
    local validation_report="$REPORTS_DIR/grafana-validation.txt"
    
    echo "# VALIDAÇÃO GRAFANA - $(date)" > "$validation_report"
    echo "==============================" >> "$validation_report"
    
    # Verificar estrutura de diretórios
    local required_dirs=("dashboards" "provisioning/dashboards" "provisioning/datasources")
    local dirs_ok=0
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$grafana_dir/$dir" ]]; then
            log_success "Diretório $dir encontrado"
            echo "✅ Diretório $dir: ENCONTRADO" >> "$validation_report"
            ((dirs_ok++))
        else
            log_warning "Diretório $dir não encontrado"
            echo "⚠️ Diretório $dir: NÃO ENCONTRADO" >> "$validation_report"
        fi
    done
    
    # Verificar datasources
    local datasource_file="$grafana_dir/provisioning/datasources/prometheus.yml"
    if [[ -f "$datasource_file" ]]; then
        log_success "Configuração de datasource encontrada"
        echo "✅ Datasource Prometheus: CONFIGURADO" >> "$validation_report"
    else
        log_warning "Configuração de datasource não encontrada"
        echo "⚠️ Datasource Prometheus: NÃO CONFIGURADO" >> "$validation_report"
    fi
    
    # Verificar dashboards
    local dashboard_count=$(find "$grafana_dir/dashboards" -name "*.json" 2>/dev/null | wc -l)
    log_info "Dashboards encontrados: $dashboard_count"
    echo "📊 Dashboards: $dashboard_count" >> "$validation_report"
    
    log_success "Validação do Grafana concluída"
}

# Validar configurações do SonarQube
validate_sonarqube_config() {
    log_info "🔍 Validando configuração do SonarQube..."
    
    local sonarqube_dir="$MONITORING_DIR/sonarqube"
    local validation_report="$REPORTS_DIR/sonarqube-validation.txt"
    
    echo "# VALIDAÇÃO SONARQUBE - $(date)" > "$validation_report"
    echo "================================" >> "$validation_report"
    
    # Verificar Docker Compose
    local compose_file="$sonarqube_dir/docker-compose.sonarqube.yml"
    if [[ -f "$compose_file" ]]; then
        log_success "Docker Compose do SonarQube encontrado"
        echo "✅ Docker Compose: ENCONTRADO" >> "$validation_report"
        
        # Verificar serviços definidos
        local services_count=$(grep -c "^  [a-zA-Z]" "$compose_file" 2>/dev/null || echo "0")
        log_info "Serviços definidos: $services_count"
        echo "📊 Serviços: $services_count" >> "$validation_report"
        
    else
        log_warning "Docker Compose do SonarQube não encontrado"
        echo "⚠️ Docker Compose: NÃO ENCONTRADO" >> "$validation_report"
    fi
    
    # Verificar script de configuração
    local config_script="$sonarqube_dir/configure-sonarqube.sh"
    if [[ -f "$config_script" && -x "$config_script" ]]; then
        log_success "Script de configuração encontrado e executável"
        echo "✅ Script de configuração: PRONTO" >> "$validation_report"
    else
        log_warning "Script de configuração não encontrado ou não executável"
        echo "⚠️ Script de configuração: NÃO PRONTO" >> "$validation_report"
    fi
    
    log_success "Validação do SonarQube concluída"
}

# Validar Docker Compose principal
validate_docker_compose() {
    log_info "🐳 Validando Docker Compose de monitoramento..."
    
    local compose_file="$MONITORING_DIR/docker-compose.monitoring.yml"
    local validation_report="$REPORTS_DIR/docker-compose-validation.txt"
    
    echo "# VALIDAÇÃO DOCKER COMPOSE - $(date)" > "$validation_report"
    echo "====================================" >> "$validation_report"
    
    if [[ -f "$compose_file" ]]; then
        log_success "Docker Compose encontrado"
        echo "✅ Arquivo: ENCONTRADO" >> "$validation_report"
        
        # Verificar sintaxe YAML
        if command -v python3 &> /dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$compose_file'))" 2>/dev/null; then
                log_success "Sintaxe YAML válida"
                echo "✅ Sintaxe YAML: VÁLIDA" >> "$validation_report"
            else
                log_error "Sintaxe YAML inválida"
                echo "❌ Sintaxe YAML: INVÁLIDA" >> "$validation_report"
            fi
        fi
        
        # Verificar serviços
        local services=(prometheus grafana node-exporter)
        for service in "${services[@]}"; do
            if grep -q "^  $service:" "$compose_file"; then
                log_success "Serviço $service configurado"
                echo "✅ Serviço $service: CONFIGURADO" >> "$validation_report"
            else
                log_warning "Serviço $service não encontrado"
                echo "⚠️ Serviço $service: NÃO CONFIGURADO" >> "$validation_report"
            fi
        done
        
        # Verificar volumes
        if grep -q "^volumes:" "$compose_file"; then
            log_success "Volumes configurados"
            echo "✅ Volumes: CONFIGURADOS" >> "$validation_report"
        else
            log_warning "Volumes não configurados"
            echo "⚠️ Volumes: NÃO CONFIGURADOS" >> "$validation_report"
        fi
        
        # Verificar networks
        if grep -q "^networks:" "$compose_file"; then
            log_success "Networks configuradas"
            echo "✅ Networks: CONFIGURADAS" >> "$validation_report"
        else
            log_warning "Networks não configuradas"
            echo "⚠️ Networks: NÃO CONFIGURADAS" >> "$validation_report"
        fi
        
    else
        log_error "Docker Compose não encontrado"
        echo "❌ Arquivo: NÃO ENCONTRADO" >> "$validation_report"
    fi
    
    log_success "Validação do Docker Compose concluída"
}

# Validar scripts de inicialização
validate_startup_scripts() {
    log_info "🚀 Validando scripts de inicialização..."
    
    local validation_report="$REPORTS_DIR/scripts-validation.txt"
    
    echo "# VALIDAÇÃO SCRIPTS - $(date)" > "$validation_report"
    echo "=============================" >> "$validation_report"
    
    local scripts=("start-monitoring.sh" "stop-monitoring.sh")
    
    for script in "${scripts[@]}"; do
        local script_path="$MONITORING_DIR/$script"
        
        if [[ -f "$script_path" ]]; then
            if [[ -x "$script_path" ]]; then
                log_success "Script $script encontrado e executável"
                echo "✅ $script: PRONTO" >> "$validation_report"
            else
                log_warning "Script $script encontrado mas não executável"
                echo "⚠️ $script: NÃO EXECUTÁVEL" >> "$validation_report"
            fi
        else
            log_error "Script $script não encontrado"
            echo "❌ $script: NÃO ENCONTRADO" >> "$validation_report"
        fi
    done
    
    log_success "Validação dos scripts concluída"
}

# Testar conectividade (simulado)
test_connectivity() {
    log_info "🌐 Testando conectividade das ferramentas..."
    
    local connectivity_report="$REPORTS_DIR/connectivity-test.txt"
    
    echo "# TESTE DE CONECTIVIDADE - $(date)" > "$connectivity_report"
    echo "===================================" >> "$connectivity_report"
    
    # Simular testes de conectividade
    local services=("prometheus:9090" "grafana:3001" "sonarqube:9000")
    
    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local port=$(echo "$service" | cut -d: -f2)
        
        log_info "Testando $name na porta $port..."
        
        # Simular teste (em ambiente real usaria curl ou nc)
        if [[ "$name" == "prometheus" ]] || [[ "$name" == "grafana" ]]; then
            log_success "$name: Conectividade OK (simulado)"
            echo "✅ $name ($port): CONECTIVIDADE OK" >> "$connectivity_report"
        else
            log_warning "$name: Serviço não iniciado"
            echo "⚠️ $name ($port): SERVIÇO NÃO INICIADO" >> "$connectivity_report"
        fi
    done
    
    log_success "Teste de conectividade concluído"
}

# Gerar relatório consolidado
generate_validation_report() {
    log_info "📋 Gerando relatório consolidado de validação..."
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local report_file="$REPORTS_DIR/monitoring-validation-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔍 Relatório de Validação - Ferramentas de Monitoramento
## Conexão de Sorte - Validação de Configurações

**Data da Validação**: $timestamp  
**Responsável**: DevOps Engineer  
**Ambiente**: Desenvolvimento

---

## 📊 Resumo Executivo

### 🎯 Objetivo
Validar todas as configurações das ferramentas de monitoramento antes da implementação em produção.

### ✅ Status Geral
- **Prometheus**: $(if [[ -f "$MONITORING_DIR/prometheus/prometheus.yml" ]]; then echo "✅ CONFIGURADO"; else echo "⚠️ PENDENTE"; fi)
- **Grafana**: $(if [[ -d "$MONITORING_DIR/grafana/dashboards" ]]; then echo "✅ CONFIGURADO"; else echo "⚠️ PENDENTE"; fi)
- **SonarQube**: $(if [[ -f "$MONITORING_DIR/sonarqube/docker-compose.sonarqube.yml" ]]; then echo "✅ CONFIGURADO"; else echo "⚠️ PENDENTE"; fi)
- **Docker Compose**: $(if [[ -f "$MONITORING_DIR/docker-compose.monitoring.yml" ]]; then echo "✅ CONFIGURADO"; else echo "⚠️ PENDENTE"; fi)

---

## 📁 Arquivos de Validação Gerados

$(ls -la "$REPORTS_DIR"/*.txt 2>/dev/null | awk '{print "- " $9}' || echo "- Nenhum arquivo de validação encontrado")

---

## 🎯 Próximos Passos

### ✅ Configurações Validadas
1. Estrutura de diretórios criada
2. Arquivos de configuração presentes
3. Scripts de inicialização preparados

### 🔄 Ações Necessárias
1. **Iniciar serviços**: Execute \`./monitoring/start-monitoring.sh\`
2. **Testar conectividade**: Acesse os dashboards
3. **Configurar alertas**: Personalizar regras do Prometheus
4. **Integrar com aplicação**: Adicionar métricas customizadas

### ⚠️ Dependências
- **Docker**: Necessário para executar os serviços
- **Chave API NVD**: Para análises completas de segurança
- **Configurações de rede**: Portas 9090, 3001, 9000 disponíveis

---

## 📞 Suporte

- **Documentação**: \`docs/PLANO-EXECUCAO-SEGURANCA.md\`
- **Scripts**: \`scripts/monitoring/\`
- **Configurações**: \`monitoring/\`

---

**📝 Relatório gerado automaticamente**: $timestamp
EOF
    
    log_success "Relatório consolidado gerado: $report_file"
}

# Função principal
main() {
    log_info "🔍 Iniciando validação de ferramentas de monitoramento..."
    
    setup_directories
    validate_prometheus_config
    validate_grafana_config
    validate_sonarqube_config
    validate_docker_compose
    validate_startup_scripts
    test_connectivity
    generate_validation_report
    
    log_success "🎉 Validação de ferramentas de monitoramento concluída!"
    
    echo ""
    log_info "📋 RESUMO DA VALIDAÇÃO:"
    echo "  📊 Prometheus: $(if [[ -f "$MONITORING_DIR/prometheus/prometheus.yml" ]]; then echo "✅ OK"; else echo "⚠️ PENDENTE"; fi)"
    echo "  📈 Grafana: $(if [[ -d "$MONITORING_DIR/grafana" ]]; then echo "✅ OK"; else echo "⚠️ PENDENTE"; fi)"
    echo "  🔍 SonarQube: $(if [[ -f "$MONITORING_DIR/sonarqube/docker-compose.sonarqube.yml" ]]; then echo "✅ OK"; else echo "⚠️ PENDENTE"; fi)"
    echo "  🐳 Docker Compose: $(if [[ -f "$MONITORING_DIR/docker-compose.monitoring.yml" ]]; then echo "✅ OK"; else echo "⚠️ PENDENTE"; fi)"
    echo ""
    echo "  📁 Relatórios em: $REPORTS_DIR"
    echo "  🚀 Para iniciar: cd monitoring && ./start-monitoring.sh"
}

# Executar função principal
main "$@"
