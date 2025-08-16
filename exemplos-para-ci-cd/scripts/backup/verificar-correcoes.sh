#!/bin/bash

# 🔍 Script para Verificar Correções Aplicadas - Conexão de Sorte

set -euo pipefail

echo "🔍 Verificando correções aplicadas..."
echo "====================================="

# Verificar se os arquivos foram modificados
echo "1. Verificando arquivos modificados..."

if [ -f "src/main/resources/application-azure.yml.bak" ]; then
    echo "   ✅ Backup do application-azure.yml criado"
else
    echo "   ❌ Backup do application-azure.yml não encontrado"
fi

if [ -f "src/main/resources/logback-spring.xml" ]; then
    echo "   ✅ Configuração do Logback criada"
else
    echo "   ❌ Configuração do Logback não encontrada"
fi

# Verificar configurações específicas
echo "2. Verificando configurações..."

if grep -q "use-default-credential: false" src/main/resources/application-azure.yml; then
    echo "   ✅ Configuração do Azure Key Vault corrigida"
else
    echo "   ❌ Configuração do Azure Key Vault não corrigida"
fi

if grep -q "cache:" src/main/resources/application.yml; then
    echo "   ✅ Configuração de cache adicionada"
else
    echo "   ❌ Configuração de cache não encontrada"
fi

if grep -q "notificacao:" src/main/resources/application.yml; then
    echo "   ✅ Configuração de notificação adicionada"
else
    echo "   ❌ Configuração de notificação não encontrada"
fi

echo "3. Verificando sintaxe dos arquivos..."

# Verificar sintaxe YAML
if command -v yamllint >/dev/null 2>&1; then
    if yamllint src/main/resources/application.yml; then
        echo "   ✅ Sintaxe YAML válida"
    else
        echo "   ❌ Erro na sintaxe YAML"
    fi
else
    echo "   ⚠️ yamllint não disponível - pulando verificação de sintaxe"
fi

echo "✅ Verificação concluída!"
