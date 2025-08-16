#!/bin/bash

# Script para configurar JAVA_HOME no macOS
# Autor: Conexão de Sorte Backend Team
# Data: 2025-07-25

echo "🍎 Configurando JAVA_HOME para macOS..."

# Detecta o Java 21 instalado
JAVA_21_PATH="/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home"

# Verifica se o Java 21 está instalado
if [ ! -d "$JAVA_21_PATH" ]; then
    echo "❌ Java 21 da Microsoft não encontrado em: $JAVA_21_PATH"
    echo "Por favor, instale o Java 21 da Microsoft primeiro."
    exit 1
fi

echo "✅ Java 21 encontrado em: $JAVA_21_PATH"

# Verifica se já está configurado no .zshrc
if grep -q "JAVA_HOME.*microsoft-21.jdk" ~/.zshrc; then
    echo "⚠️  JAVA_HOME já está configurado no ~/.zshrc"
    echo "Removendo configurações antigas..."
    
    # Remove configurações antigas
    grep -v "JAVA_HOME.*microsoft-21.jdk" ~/.zshrc > ~/.zshrc.temp
    grep -v "PATH.*JAVA_HOME" ~/.zshrc.temp > ~/.zshrc.clean
    mv ~/.zshrc.clean ~/.zshrc
    rm -f ~/.zshrc.temp
fi

# Adiciona nova configuração
echo "" >> ~/.zshrc
echo "# Java 21 Configuration for Conexao de Sorte" >> ~/.zshrc
echo "export JAVA_HOME=$JAVA_21_PATH" >> ~/.zshrc
echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.zshrc

echo "✅ JAVA_HOME configurado com sucesso!"
echo "📝 Configuração adicionada ao ~/.zshrc"

# Carrega a configuração no terminal atual
export JAVA_HOME="$JAVA_21_PATH"
export PATH="$JAVA_HOME/bin:$PATH"

echo "🔄 Configuração carregada no terminal atual"
echo "💡 Para novos terminais, execute: source ~/.zshrc"

# Testa a configuração
echo ""
echo "🧪 Testando configuração..."
echo "JAVA_HOME: $JAVA_HOME"
java -version

echo ""
echo "🎉 Configuração concluída! Agora você pode executar:"
echo "   ./mvnw clean"
echo "   ./mvnw compile"
echo "   ./mvnw test"
echo "   ./mvnw package"
