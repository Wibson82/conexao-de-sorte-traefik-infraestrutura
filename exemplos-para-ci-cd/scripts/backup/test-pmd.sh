#!/bin/bash

# Script para testar o PMD com as novas configurações

set -euo pipefail

echo "🧪 Testando PMD com configurações otimizadas..."

# Limpar cache anterior
rm -rf target/pmd/

# Executar PMD (sem timeout no macOS)
echo "⏱️ Executando PMD..."

if ./mvnw pmd:check -B -q; then
    echo "✅ PMD executado com sucesso!"
    
    # Verificar se relatório foi gerado
    if [ -f "target/site/pmd.html" ]; then
        echo "📊 Relatório PMD gerado: target/site/pmd.html"
        
        # Contar violações
        VIOLATIONS=$(grep -c "violation" target/site/pmd.html 2>/dev/null || echo "0")
        echo "📋 Violações encontradas: $VIOLATIONS"
    fi
else
    echo "❌ PMD falhou ou excedeu timeout"
    
    # Verificar logs para StackOverflowError
    if grep -q "StackOverflowError" target/surefire-reports/*.txt 2>/dev/null; then
        echo "🚨 StackOverflowError ainda presente - verificar configurações"
    fi
    
    exit 1
fi

echo "✅ Teste do PMD concluído"
