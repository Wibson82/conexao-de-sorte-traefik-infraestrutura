#!/bin/bash

# =============================================================================
# SCRIPT DE ANÁLISE OWASP DEPENDENCY CHECK
# Projeto: Conexão de Sorte - Análise de Vulnerabilidades
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/reports/security"
OWASP_VERSION="9.0.9"
OWASP_JAR="dependency-check-${OWASP_VERSION}-release.zip"
OWASP_URL="https://github.com/jeremylong/DependencyCheck/releases/download/v${OWASP_VERSION}/${OWASP_JAR}"

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

# Verificar se Java está disponível
check_java() {
    log_info "☕ Verificando Java..."

    if ! command -v java &> /dev/null; then
        log_error "Java não encontrado. Instale Java 8+ para continuar."
        exit 1
    fi

    local java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    log_success "Java encontrado: $java_version"
}

# Criar diretórios necessários
setup_directories() {
    log_info "📁 Criando diretórios..."

    mkdir -p "$REPORTS_DIR"
    mkdir -p "$PROJECT_ROOT/tools/owasp"

    log_success "Diretórios criados"
}

# Download e configuração do OWASP Dependency Check
download_owasp_tool() {
    local tools_dir="$PROJECT_ROOT/tools/owasp"
    local owasp_path="$tools_dir/dependency-check"

    if [[ -d "$owasp_path" ]]; then
        log_info "🔍 OWASP Dependency Check já está instalado"
        return 0
    fi

    log_info "📥 Baixando OWASP Dependency Check v${OWASP_VERSION}..."

    cd "$tools_dir"

    # Download usando curl
    if command -v curl &> /dev/null; then
        curl -L -o "$OWASP_JAR" "$OWASP_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$OWASP_JAR" "$OWASP_URL"
    else
        log_error "curl ou wget necessário para download"
        exit 1
    fi

    # Extrair
    log_info "📦 Extraindo OWASP Dependency Check..."
    unzip -q "$OWASP_JAR"
    rm "$OWASP_JAR"

    # Dar permissão de execução
    chmod +x dependency-check/bin/dependency-check.sh

    log_success "OWASP Dependency Check instalado"
}

# Executar análise de dependências
run_dependency_analysis() {
    log_info "🔍 Executando análise OWASP Dependency Check..."

    local tools_dir="$PROJECT_ROOT/tools/owasp"
    local owasp_bin="$tools_dir/dependency-check/bin/dependency-check.sh"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_name="owasp-dependency-check-${timestamp}"

    # Verificar se o Maven wrapper existe
    local scan_path="$PROJECT_ROOT"
    if [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
        log_info "📋 Projeto Maven detectado"
    else
        log_warning "pom.xml não encontrado, analisando diretório completo"
    fi

    # Executar análise
    log_info "⏳ Iniciando análise (pode demorar alguns minutos)..."

    "$owasp_bin" \
        --project "Conexao de Sorte" \
        --scan "$scan_path" \
        --out "$REPORTS_DIR/dependency-check-report" \
        --format "ALL" \
        --enableExperimental \
        --noupdate \
        --suppression "$SCRIPT_DIR/owasp-suppressions.xml" \
        --log "$REPORTS_DIR/owasp-analysis.log" \
        --failOnCVSS 7 \
        || true  # Não falhar se vulnerabilidades forem encontradas

    log_success "Análise OWASP concluída"
    log_info "📊 Relatórios gerados em: $REPORTS_DIR"
    log_info "📄 HTML: $REPORTS_DIR/dependency-check-report.html"
    log_info "📄 JSON: $REPORTS_DIR/dependency-check-report.json"
    log_info "📄 XML: $REPORTS_DIR/dependency-check-report.xml"
}

# Criar arquivo de supressões
create_suppressions_file() {
    log_info "📝 Criando arquivo de supressões..."

    cat > "$SCRIPT_DIR/owasp-suppressions.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <!--
    Arquivo de supressões para falsos positivos conhecidos
    Adicione supressões conforme necessário após análise manual
    -->

    <!-- Exemplo de supressão por CVE específico
    <suppress>
        <notes><![CDATA[
        Falso positivo - não aplicável ao nosso uso
        ]]></notes>
        <cve>CVE-2021-12345</cve>
    </suppress>
    -->

    <!-- Exemplo de supressão por arquivo específico
    <suppress>
        <notes><![CDATA[
        Dependência de desenvolvimento apenas
        ]]></notes>
        <filePath regex="true">.*test.*\.jar</filePath>
    </suppress>
    -->
</suppressions>
EOF

    log_success "Arquivo de supressões criado"
}

# Analisar resultados
analyze_results() {
    log_info "📊 Analisando resultados..."

    local latest_json="$REPORTS_DIR/dependency-check-report.json"

    if [[ ! -f "$latest_json" ]]; then
        log_warning "Relatório JSON não encontrado: $latest_json"
        return 1
    fi

    log_info "📄 Analisando: $latest_json"

    # Verificar se jq está disponível para análise JSON
    if command -v jq &> /dev/null; then
        local total_deps=$(jq '.dependencies | length' "$latest_json")
        local vulnerable_deps=$(jq '[.dependencies[] | select(.vulnerabilities | length > 0)] | length' "$latest_json")
        local critical_vulns=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "CRITICAL")] | length' "$latest_json")
        local high_vulns=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "HIGH")] | length' "$latest_json")
        local medium_vulns=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "MEDIUM")] | length' "$latest_json")

        echo ""
        log_info "📈 RESUMO DA ANÁLISE:"
        echo "  📦 Total de dependências: $total_deps"
        echo "  🚨 Dependências vulneráveis: $vulnerable_deps"
        echo "  🔴 Vulnerabilidades CRÍTICAS: $critical_vulns"
        echo "  🟠 Vulnerabilidades ALTAS: $high_vulns"
        echo "  🟡 Vulnerabilidades MÉDIAS: $medium_vulns"
        echo ""

        if [[ $critical_vulns -gt 0 ]] || [[ $high_vulns -gt 0 ]]; then
            log_error "⚠️ VULNERABILIDADES CRÍTICAS/ALTAS ENCONTRADAS!"
            log_info "📋 Revise o relatório HTML para detalhes"

            # Listar vulnerabilidades críticas
            if [[ $critical_vulns -gt 0 ]]; then
                log_error "🔴 VULNERABILIDADES CRÍTICAS:"
                jq -r '.dependencies[].vulnerabilities[]? | select(.severity == "CRITICAL") | "  - " + .name + " (" + .cvssv3.baseScore + ")"' "$latest_json" | head -10
            fi
        else
            log_success "✅ Nenhuma vulnerabilidade crítica ou alta encontrada"
        fi
    else
        log_warning "jq não disponível - instale para análise detalhada"
        log_info "📄 Verifique manualmente o relatório HTML"
    fi
}

# Gerar relatório resumido
generate_summary_report() {
    log_info "📝 Gerando relatório resumido..."

    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local summary_file="$REPORTS_DIR/owasp-summary-$(date +%Y%m%d_%H%M%S).md"

    cat > "$summary_file" << EOF
# 🔍 Relatório OWASP Dependency Check
## Conexão de Sorte - Análise de Vulnerabilidades

**Data da Análise**: $timestamp
**Projeto**: Conexão de Sorte Backend
**Ferramenta**: OWASP Dependency Check v${OWASP_VERSION}

---

## 📊 Resumo Executivo

$(if command -v jq &> /dev/null && [[ -f "$REPORTS_DIR"/owasp-dependency-check-*.json ]]; then
    local latest_json=$(find "$REPORTS_DIR" -name "owasp-dependency-check-*.json" -type f -exec ls -t {} + | head -n1)
    local total_deps=$(jq '.dependencies | length' "$latest_json")
    local vulnerable_deps=$(jq '[.dependencies[] | select(.vulnerabilities | length > 0)] | length' "$latest_json")
    local critical_vulns=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "CRITICAL")] | length' "$latest_json")
    local high_vulns=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "HIGH")] | length' "$latest_json")

    echo "- **Total de Dependências**: $total_deps"
    echo "- **Dependências Vulneráveis**: $vulnerable_deps"
    echo "- **Vulnerabilidades Críticas**: $critical_vulns"
    echo "- **Vulnerabilidades Altas**: $high_vulns"
else
    echo "- Análise detalhada disponível no relatório HTML"
fi)

---

## 🎯 Próximos Passos

1. **Revisar relatório HTML detalhado**
2. **Priorizar correção de vulnerabilidades críticas/altas**
3. **Atualizar dependências vulneráveis**
4. **Configurar supressões para falsos positivos**
5. **Integrar análise no pipeline CI/CD**

---

## 📁 Arquivos Gerados

- **Relatório HTML**: Visualização completa das vulnerabilidades
- **Relatório JSON**: Dados estruturados para automação
- **Relatório XML**: Formato para integração com outras ferramentas
- **Log de Análise**: Detalhes da execução

---

**📝 Gerado automaticamente pelo script OWASP Dependency Check**
EOF

    log_success "Relatório resumido gerado: $summary_file"
}

# Função principal
main() {
    log_info "🔍 Iniciando análise OWASP Dependency Check..."

    check_java
    setup_directories
    create_suppressions_file
    download_owasp_tool
    run_dependency_analysis
    analyze_results
    generate_summary_report

    log_success "🎉 Análise OWASP Dependency Check concluída!"
    log_info "📊 Verifique os relatórios em: $REPORTS_DIR"

    # Abrir relatório HTML se possível
    local latest_html=$(find "$REPORTS_DIR" -name "owasp-dependency-check-*.html" -type f -exec ls -t {} + | head -n1)
    if [[ -n "$latest_html" ]]; then
        log_info "🌐 Para visualizar o relatório, abra: $latest_html"
    fi
}

# Executar função principal
main "$@"
