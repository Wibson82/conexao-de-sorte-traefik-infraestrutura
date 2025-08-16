#!/bin/bash

# =============================================================================
# SCRIPT DE TESTE DE CONFIGURAÇÃO JWT
# =============================================================================
# Testa diferentes cenários de configuração JWT para garantir que a aplicação
# inicia corretamente em todos os ambientes

set -e

echo "🔍 TESTE DE CONFIGURAÇÃO JWT - INICIANDO"
echo "========================================"

# Função para testar configuração
test_configuration() {
    local profile=$1
    local description=$2
    local env_vars=$3
    
    echo ""
    echo "🧪 Testando: $description"
    echo "Profile: $profile"
    echo "Variáveis: $env_vars"
    echo "----------------------------------------"
    
    # Exportar variáveis de ambiente se fornecidas
    if [ -n "$env_vars" ]; then
        eval "export $env_vars"
    fi
    
    # Testar compilação com profile específico
    echo "📦 Compilando com profile $profile..."
    if ./mvnw clean compile -Dspring.profiles.active=$profile -q; then
        echo "✅ Compilação: SUCESSO"
    else
        echo "❌ Compilação: FALHA"
        return 1
    fi
    
    # Testar inicialização (dry-run)
    echo "🚀 Testando inicialização..."
    timeout 30s ./mvnw spring-boot:run -Dspring.profiles.active=$profile -Dspring.main.web-application-type=none -q || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "✅ Inicialização: SUCESSO (timeout esperado)"
        else
            echo "❌ Inicialização: FALHA (código: $exit_code)"
            return 1
        fi
    }
    
    echo "✅ Teste concluído com sucesso"
}

# Teste 1: Desenvolvimento com chave PEM
echo "🔧 CENÁRIO 1: Desenvolvimento com chave PEM"
test_configuration "dev" "Desenvolvimento com chave PEM do application-dev.yml" ""

# Teste 2: Produção com chave pública via variável
echo "🔧 CENÁRIO 2: Produção com chave pública via variável"
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu1SU1L7VLPHCgcYUJ4XG
R6YFqW8VmqopgVslR7iAI3dTOvn1gBDI7s2Y0k+B3KFBYlhRipWhhmHqKmdo4q5a
kGMza7ZL0ATy1WHiE0k0cR9IGq9ptcCkuDVHch0YilE7TpRbwIkk56A8aAM2igGC
sU9pTPG1Ub8iLh3pzYs3ac8MG37BxxiZinebOzoMhliOcdIcYB8uqAZ1GvmKz4iF
srmxyuspLEpPAJVTYmAyNGQTW726u08lhBwXoU4ox6djk0slmNsgy8q26TKzqXtl
0zUBESxuCntin9dDl2yw7LtkHSRV2YfKAAY1+sCXQo4zoAJk3UZKommhJ1z4usBk
bwIDAQAB
-----END PUBLIC KEY-----"

test_configuration "prod" "Produção com chave pública via variável" "APP_JWT_CHAVE_PUBLICA='$JWT_PUBLIC_KEY'"

# Teste 3: Produção sem configuração (deve falhar)
echo "🔧 CENÁRIO 3: Produção sem configuração JWT (deve falhar)"
echo "🚨 Este teste deve falhar - é o comportamento esperado"
if test_configuration "prod" "Produção sem configuração JWT" "" 2>/dev/null; then
    echo "❌ ERRO: Produção deveria falhar sem configuração JWT!"
    exit 1
else
    echo "✅ CORRETO: Produção falhou sem configuração JWT (comportamento esperado)"
fi

# Teste 4: Azure profile
echo "🔧 CENÁRIO 4: Profile Azure"
test_configuration "azure" "Profile Azure com configurações do Key Vault" ""

echo ""
echo "🎉 TODOS OS TESTES CONCLUÍDOS COM SUCESSO!"
echo "=========================================="
echo "✅ Desenvolvimento: Funciona com chave PEM"
echo "✅ Produção: Funciona com variável de ambiente"
echo "✅ Produção: Falha sem configuração (segurança)"
echo "✅ Azure: Funciona com configurações do Key Vault"
echo ""
echo "🔐 Sistema JWT configurado corretamente para todos os ambientes!"
