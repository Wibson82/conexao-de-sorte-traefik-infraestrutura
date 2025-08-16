#!/bin/bash

# =============================================================================
# SCRIPT DE ANÁLISE DE SEGURANÇA COM MAVEN
# Projeto: Conexão de Sorte - Análise de Dependências e Qualidade
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/reports/security"

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

# Verificar se Maven está disponível
check_maven() {
    log_info "🔨 Verificando Maven..."
    
    if [[ -f "$PROJECT_ROOT/mvnw" ]]; then
        log_success "Maven Wrapper encontrado"
        MAVEN_CMD="$PROJECT_ROOT/mvnw"
    elif command -v mvn &> /dev/null; then
        log_success "Maven encontrado no sistema"
        MAVEN_CMD="mvn"
    else
        log_error "Maven não encontrado. Instale Maven ou use o wrapper."
        exit 1
    fi
}

# Criar diretórios necessários
setup_directories() {
    log_info "📁 Criando diretórios..."
    
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$PROJECT_ROOT/target/site"
    
    log_success "Diretórios criados"
}

# Análise de dependências vulneráveis
analyze_vulnerable_dependencies() {
    log_info "🔍 Analisando dependências vulneráveis..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar dependências desatualizadas
    log_info "📊 Verificando dependências desatualizadas..."
    $MAVEN_CMD versions:display-dependency-updates > "$REPORTS_DIR/dependency-updates.txt" 2>&1 || true
    
    # Verificar plugins desatualizados
    log_info "🔌 Verificando plugins desatualizados..."
    $MAVEN_CMD versions:display-plugin-updates > "$REPORTS_DIR/plugin-updates.txt" 2>&1 || true
    
    # Árvore de dependências
    log_info "🌳 Gerando árvore de dependências..."
    $MAVEN_CMD dependency:tree > "$REPORTS_DIR/dependency-tree.txt" 2>&1 || true
    
    # Análise de dependências
    log_info "🔬 Analisando dependências..."
    $MAVEN_CMD dependency:analyze > "$REPORTS_DIR/dependency-analysis.txt" 2>&1 || true
    
    log_success "Análise de dependências concluída"
}

# Análise de qualidade de código
analyze_code_quality() {
    log_info "📝 Analisando qualidade de código..."
    
    cd "$PROJECT_ROOT"
    
    # Compilar projeto
    log_info "🔨 Compilando projeto..."
    $MAVEN_CMD clean compile test-compile -DskipTests > "$REPORTS_DIR/compile.log" 2>&1 || true
    
    # Executar testes
    log_info "🧪 Executando testes..."
    $MAVEN_CMD test > "$REPORTS_DIR/test-results.txt" 2>&1 || true
    
    # Gerar relatório de cobertura (se JaCoCo estiver configurado)
    log_info "📊 Gerando relatório de cobertura..."
    $MAVEN_CMD jacoco:report > "$REPORTS_DIR/jacoco.log" 2>&1 || true
    
    # SpotBugs (se configurado)
    log_info "🐛 Executando SpotBugs..."
    $MAVEN_CMD spotbugs:check > "$REPORTS_DIR/spotbugs.log" 2>&1 || true
    
    # Checkstyle (se configurado)
    log_info "✅ Executando Checkstyle..."
    $MAVEN_CMD checkstyle:check > "$REPORTS_DIR/checkstyle.log" 2>&1 || true
    
    log_success "Análise de qualidade concluída"
}

# Análise de segurança específica
analyze_security() {
    log_info "🔒 Executando análise de segurança..."
    
    cd "$PROJECT_ROOT"
    
    # Verificar configurações de segurança no código
    log_info "🔍 Analisando configurações de segurança..."
    
    # Buscar por padrões de segurança problemáticos
    cat > "$REPORTS_DIR/security-patterns.txt" << 'EOF'
# ANÁLISE DE PADRÕES DE SEGURANÇA - CONEXÃO DE SORTE

## 1. Verificação de Senhas Hardcoded
EOF
    
    grep -r -n "password\s*=" src/ --include="*.java" --include="*.properties" --include="*.yml" >> "$REPORTS_DIR/security-patterns.txt" 2>/dev/null || echo "Nenhuma senha hardcoded encontrada" >> "$REPORTS_DIR/security-patterns.txt"
    
    echo -e "\n## 2. Verificação de Chaves API/Secrets" >> "$REPORTS_DIR/security-patterns.txt"
    grep -r -n -E "(api[_-]?key|secret|token)" src/ --include="*.java" --include="*.properties" --include="*.yml" >> "$REPORTS_DIR/security-patterns.txt" 2>/dev/null || echo "Nenhuma chave API hardcoded encontrada" >> "$REPORTS_DIR/security-patterns.txt"
    
    echo -e "\n## 3. Verificação de URLs de Banco de Dados" >> "$REPORTS_DIR/security-patterns.txt"
    grep -r -n "jdbc:" src/ --include="*.java" --include="*.properties" --include="*.yml" >> "$REPORTS_DIR/security-patterns.txt" 2>/dev/null || echo "Nenhuma URL de banco hardcoded encontrada" >> "$REPORTS_DIR/security-patterns.txt"
    
    echo -e "\n## 4. Verificação de Configurações de CORS" >> "$REPORTS_DIR/security-patterns.txt"
    grep -r -n -E "(allowedOrigins|CORS)" src/ --include="*.java" >> "$REPORTS_DIR/security-patterns.txt" 2>/dev/null || echo "Configurações CORS não encontradas no código" >> "$REPORTS_DIR/security-patterns.txt"
    
    echo -e "\n## 5. Verificação de Configurações de Criptografia" >> "$REPORTS_DIR/security-patterns.txt"
    grep -r -n -E "(AES|RSA|SHA|MD5|encrypt|decrypt)" src/ --include="*.java" >> "$REPORTS_DIR/security-patterns.txt" 2>/dev/null || echo "Configurações de criptografia não encontradas" >> "$REPORTS_DIR/security-patterns.txt"
    
    log_success "Análise de segurança concluída"
}

# Gerar relatório consolidado
generate_consolidated_report() {
    log_info "📋 Gerando relatório consolidado..."
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local report_file="$REPORTS_DIR/security-analysis-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔍 Relatório de Análise de Segurança
## Conexão de Sorte - Análise Maven

**Data da Análise**: $timestamp  
**Projeto**: Conexão de Sorte Backend  
**Ferramenta**: Maven + Análise Customizada

---

## 📊 Resumo Executivo

### 🔧 Ferramentas Utilizadas
- Maven Dependency Analysis
- Versions Plugin (atualizações)
- Análise de padrões de segurança
- Verificação de configurações

### 📈 Resultados Principais

#### 📦 Dependências
$(if [[ -f "$REPORTS_DIR/dependency-updates.txt" ]]; then
    local outdated=$(grep -c "The following dependencies in Dependencies have newer versions:" "$REPORTS_DIR/dependency-updates.txt" 2>/dev/null || echo "0")
    echo "- Dependências desatualizadas encontradas: Verifique $REPORTS_DIR/dependency-updates.txt"
else
    echo "- Análise de dependências não disponível"
fi)

#### 🧪 Testes
$(if [[ -f "$REPORTS_DIR/test-results.txt" ]]; then
    if grep -q "BUILD SUCCESS" "$REPORTS_DIR/test-results.txt"; then
        echo "- ✅ Testes executados com sucesso"
    else
        echo "- ❌ Falhas nos testes encontradas"
    fi
else
    echo "- Resultados de testes não disponíveis"
fi)

#### 🔒 Segurança
$(if [[ -f "$REPORTS_DIR/security-patterns.txt" ]]; then
    echo "- Análise de padrões de segurança concluída"
    echo "- Verifique $REPORTS_DIR/security-patterns.txt para detalhes"
else
    echo "- Análise de segurança não disponível"
fi)

---

## 📁 Arquivos Gerados

- **dependency-updates.txt**: Dependências desatualizadas
- **plugin-updates.txt**: Plugins desatualizados  
- **dependency-tree.txt**: Árvore completa de dependências
- **dependency-analysis.txt**: Análise de dependências não utilizadas
- **security-patterns.txt**: Padrões de segurança encontrados
- **test-results.txt**: Resultados dos testes
- **compile.log**: Log de compilação

---

## 🎯 Recomendações

### 🔄 Atualizações Prioritárias
1. Revisar dependências desatualizadas em dependency-updates.txt
2. Atualizar plugins críticos conforme plugin-updates.txt
3. Remover dependências não utilizadas identificadas

### 🔒 Segurança
1. Revisar padrões identificados em security-patterns.txt
2. Verificar se não há secrets hardcoded
3. Validar configurações de criptografia

### 🧪 Qualidade
1. Corrigir falhas de testes se houver
2. Melhorar cobertura de testes
3. Resolver issues de qualidade de código

---

## 📞 Próximos Passos

1. **Análise Detalhada**: Revisar todos os arquivos gerados
2. **Priorização**: Focar em vulnerabilidades críticas
3. **Correções**: Implementar correções necessárias
4. **Validação**: Re-executar análise após correções
5. **Automação**: Integrar no pipeline CI/CD

---

**📝 Gerado automaticamente pelo script de análise Maven**
EOF
    
    log_success "Relatório consolidado gerado: $report_file"
}

# Função principal
main() {
    log_info "🔍 Iniciando análise de segurança com Maven..."
    
    check_maven
    setup_directories
    analyze_vulnerable_dependencies
    analyze_code_quality
    analyze_security
    generate_consolidated_report
    
    log_success "🎉 Análise de segurança concluída!"
    log_info "📊 Verifique os relatórios em: $REPORTS_DIR"
    
    # Mostrar resumo rápido
    echo ""
    log_info "📋 RESUMO RÁPIDO:"
    
    if [[ -f "$REPORTS_DIR/dependency-updates.txt" ]]; then
        local updates=$(grep -c "newer version" "$REPORTS_DIR/dependency-updates.txt" 2>/dev/null || echo "0")
        echo "  📦 Dependências com atualizações disponíveis: $updates"
    fi
    
    if [[ -f "$REPORTS_DIR/test-results.txt" ]]; then
        if grep -q "BUILD SUCCESS" "$REPORTS_DIR/test-results.txt"; then
            echo "  ✅ Testes: PASSOU"
        else
            echo "  ❌ Testes: FALHOU"
        fi
    fi
    
    echo "  📁 Relatórios detalhados em: $REPORTS_DIR"
}

# Executar função principal
main "$@"
