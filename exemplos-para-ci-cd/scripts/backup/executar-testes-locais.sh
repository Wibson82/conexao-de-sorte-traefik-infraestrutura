#!/bin/bash

# 🧪 SCRIPT PARA EXECUTAR TESTES LOCALMENTE
# Substitui a execução no GitHub Actions para evitar custos extras
# Executa os mesmos testes e análises que são feitos no pipeline

set -euo pipefail

echo "🚀 INICIANDO EXECUÇÃO DE TESTES LOCAIS"
echo "========================================"
echo "📅 Data/Hora: $(date)"
echo "📂 Diretório: $(pwd)"
echo "☕ Versão Java: $(java -version 2>&1 | head -1)"
echo "📦 Versão Maven: $(./mvnw -version | head -1)"
echo ""

# Função para exibir tempo decorrido
start_time=$(date +%s)
function show_elapsed() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    echo "⏱️ Tempo decorrido: ${elapsed}s"
}

# Função para verificar se comando existe
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ ERRO: $1 não está instalado"
        exit 1
    fi
}

# Verificar dependências
echo "🔍 Verificando dependências..."
check_command java

# Verificar se Maven wrapper está disponível
if [ ! -f "./mvnw" ]; then
    echo "❌ ERRO: Maven wrapper (mvnw) não encontrado"
    exit 1
fi

# Verificar Docker (opcional)
if command -v docker &> /dev/null; then
    echo "✅ Docker disponível"
    DOCKER_AVAILABLE=true
else
    echo "⚠️ Docker não disponível (build de imagem será pulado)"
    DOCKER_AVAILABLE=false
fi

echo "✅ Dependências verificadas"
echo ""

# Limpar cache e builds anteriores
echo "🧹 Limpando builds anteriores..."
./mvnw clean -q
echo "✅ Limpeza concluída"
show_elapsed
echo ""

# ===== COMPILAÇÃO =====
echo "🔨 COMPILANDO PROJETO..."
echo "========================"
if ./mvnw compile -B -q; then
    echo "✅ Compilação bem-sucedida"
else
    echo "❌ ERRO na compilação"
    exit 1
fi
show_elapsed
echo ""

# ===== TESTES UNITÁRIOS =====
echo "🧪 EXECUTANDO TESTES UNITÁRIOS..."
echo "=================================="
if ./mvnw test -B; then
    echo "✅ Testes unitários passaram"
else
    echo "❌ ERRO nos testes unitários"
    exit 1
fi
show_elapsed
echo ""

# ===== TESTES COM COBERTURA =====
echo "📊 EXECUTANDO TESTES COM COBERTURA..."
echo "====================================="
if ./mvnw verify -B; then
    echo "✅ Testes com cobertura concluídos"
    
    # Verificar se relatório de cobertura foi gerado
    if [ -f "target/site/jacoco/jacoco.xml" ]; then
        echo "📋 Relatório de cobertura gerado: target/site/jacoco/jacoco.xml"
        echo "🌐 Relatório HTML disponível em: target/site/jacoco/index.html"
    else
        echo "⚠️ Relatório de cobertura não encontrado"
    fi
else
    echo "❌ ERRO nos testes com cobertura"
    exit 1
fi
show_elapsed
echo ""

# ===== ANÁLISE SPOTBUGS =====
echo "🐛 EXECUTANDO ANÁLISE SPOTBUGS..."
echo "=================================="
if ./mvnw compile spotbugs:check -B; then
    echo "✅ Análise SpotBugs passou"
else
    echo "⚠️ SpotBugs encontrou problemas (continuando...)"
    
    # Exibir relatório SpotBugs se existir
    if [ -f "target/spotbugsXml.xml" ]; then
        echo "📋 Relatório SpotBugs: target/spotbugsXml.xml"
        echo "🔍 Resumo dos problemas encontrados:"
        
        # Extrair e exibir problemas do XML
        if command -v xmllint &> /dev/null; then
            xmllint --xpath "//BugInstance/@type" target/spotbugsXml.xml 2>/dev/null | \
                sed 's/type="/\n- /g' | sed 's/"//g' | grep -v '^$' | sort | uniq -c | sort -nr
        else
            echo "📄 Para ver detalhes, abra: target/spotbugsXml.xml"
        fi
    fi
fi
show_elapsed
echo ""

# ===== ANÁLISE CHECKSTYLE =====
echo "📏 EXECUTANDO ANÁLISE CHECKSTYLE..."
echo "===================================="
if ./mvnw checkstyle:check -B; then
    echo "✅ Análise Checkstyle passou"
else
    echo "⚠️ Checkstyle encontrou problemas (continuando...)"
    
    # Exibir relatório Checkstyle se existir
    if [ -f "target/checkstyle-result.xml" ]; then
        echo "📋 Relatório Checkstyle: target/checkstyle-result.xml"
    fi
fi
show_elapsed
echo ""

# ===== ANÁLISE PMD =====
echo "🔍 EXECUTANDO ANÁLISE PMD..."
echo "============================="
if ./mvnw pmd:check -B; then
    echo "✅ Análise PMD passou"
else
    echo "⚠️ PMD encontrou problemas (continuando...)"
    
    # Exibir relatório PMD se existir
    if [ -f "target/pmd.xml" ]; then
        echo "📋 Relatório PMD: target/pmd.xml"
    fi
fi
show_elapsed
echo ""

# ===== ANÁLISE OWASP DEPENDENCY CHECK =====
echo "🔐 EXECUTANDO ANÁLISE OWASP DEPENDENCY CHECK..."
echo "================================================"
if ./mvnw org.owasp:dependency-check-maven:check -B \
    -Dformat=ALL \
    -DfailBuildOnCVSS=7 \
    -DsuppressionsFile=owasp-suppressions.xml \
    -DretireJsAnalyzerEnabled=false; then
    echo "✅ Análise OWASP passou"
else
    echo "⚠️ OWASP encontrou vulnerabilidades (continuando...)"
    
    # Exibir relatório OWASP se existir
    if [ -f "target/dependency-check-report.html" ]; then
        echo "📋 Relatório OWASP HTML: target/dependency-check-report.html"
        echo "📋 Relatório OWASP XML: target/dependency-check-report.xml"
    fi
fi
show_elapsed
echo ""

# ===== VERIFICAÇÃO DE DEPENDÊNCIAS DESATUALIZADAS =====
echo "📦 VERIFICANDO DEPENDÊNCIAS DESATUALIZADAS..."
echo "==============================================="
./mvnw versions:display-dependency-updates -B
./mvnw versions:display-plugin-updates -B
echo "✅ Verificação de dependências concluída"
show_elapsed
echo ""

# ===== ANÁLISE DE LICENÇAS =====
echo "📜 EXECUTANDO ANÁLISE DE LICENÇAS..."
echo "====================================="
if ./mvnw org.codehaus.mojo:license-maven-plugin:2.4.0:aggregate-third-party-report -B; then
    echo "✅ Análise de licenças concluída"
    
    if [ -f "target/generated-sources/license/THIRD-PARTY.txt" ]; then
        echo "📋 Relatório de licenças: target/generated-sources/license/THIRD-PARTY.txt"
    fi
else
    echo "⚠️ Problemas na análise de licenças (continuando...)"
fi
show_elapsed
echo ""

# ===== BUILD DA IMAGEM DOCKER (OPCIONAL) =====
echo "🐳 BUILD DA IMAGEM DOCKER (OPCIONAL)..."
echo "======================================="
if [ "$DOCKER_AVAILABLE" = "true" ]; then
    read -p "Deseja fazer build da imagem Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔨 Fazendo build da imagem Docker..."
        if docker build -t conexao-de-sorte-backend:local .; then
            echo "✅ Build da imagem Docker concluído"
            echo "📋 Imagem criada: conexao-de-sorte-backend:local"
        else
            echo "❌ ERRO no build da imagem Docker"
        fi
        show_elapsed
    else
        echo "⏭️ Build da imagem Docker pulado"
    fi
else
    echo "⚠️ Docker não está disponível - build da imagem pulado"
fi
echo ""

# ===== RESUMO FINAL =====
echo "📋 RESUMO FINAL"
echo "==============="
echo "✅ Compilação: OK"
echo "✅ Testes unitários: OK"
echo "✅ Testes com cobertura: OK"
echo "📊 Análises de qualidade executadas"
echo "🔐 Análises de segurança executadas"
echo ""
echo "📁 RELATÓRIOS GERADOS:"
echo "----------------------"
[ -f "target/site/jacoco/index.html" ] && echo "📊 Cobertura: target/site/jacoco/index.html"
[ -f "target/spotbugsXml.xml" ] && echo "🐛 SpotBugs: target/spotbugsXml.xml"
[ -f "target/checkstyle-result.xml" ] && echo "📏 Checkstyle: target/checkstyle-result.xml"
[ -f "target/pmd.xml" ] && echo "🔍 PMD: target/pmd.xml"
[ -f "target/dependency-check-report.html" ] && echo "🔐 OWASP: target/dependency-check-report.html"
[ -f "target/generated-sources/license/THIRD-PARTY.txt" ] && echo "📜 Licenças: target/generated-sources/license/THIRD-PARTY.txt"
echo ""
show_elapsed
echo "🎉 EXECUÇÃO LOCAL CONCLUÍDA COM SUCESSO!"
echo "========================================"
echo ""
echo "💡 DICAS:"
echo "- Para ver relatórios HTML, abra os arquivos no navegador"
echo "- Para corrigir problemas do SpotBugs, veja o próximo script"
echo "- Execute este script sempre antes de fazer push para o repositório"
echo ""