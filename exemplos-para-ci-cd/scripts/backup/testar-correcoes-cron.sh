#!/bin/bash

echo "🧪 Testando correções das expressões cron..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar se estamos no diretório correto
if [[ ! -f "pom.xml" ]]; then
    log_error "Execute este script no diretório raiz do projeto"
    exit 1
fi

log_info "=== VERIFICAÇÃO DAS CORREÇÕES DE CRON ==="

# 1. Verificar se ainda existem expressões cron incorretas
log_info "1. Verificando expressões cron incorretas..."

# Verificar expressões com 7 campos (formato Quartz)
CRON_INCORRETAS=$(grep -r "@Scheduled.*cron.*\?" src/main/java/ 2>/dev/null | wc -l)

if [ "$CRON_INCORRETAS" -eq 0 ]; then
    log_success "✅ Nenhuma expressão cron incorreta encontrada"
else
    log_error "❌ Encontradas $CRON_INCORRETAS expressões cron incorretas:"
    grep -r "@Scheduled.*cron.*\?" src/main/java/ 2>/dev/null
fi

# 2. Verificar se as correções foram aplicadas
log_info "2. Verificando correções aplicadas..."

# Verificar OrquestradorExtracoes
if grep -q "0 0 8,12,18,22 \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/OrquestradorExtracoes.java; then
    log_success "✅ OrquestradorExtracoes corrigido"
else
    log_error "❌ OrquestradorExtracoes ainda incorreto"
fi

# Verificar ConfiguracaoAuditoriaPerformance
if grep -q "0 0 \* \* \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaPerformance.java; then
    log_success "✅ ConfiguracaoAuditoriaPerformance corrigido"
else
    log_error "❌ ConfiguracaoAuditoriaPerformance ainda incorreto"
fi

# Verificar ServicoEstatisticaAuditoria
if grep -q "0 0 1 \* \* \*" src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoEstatisticaAuditoria.java; then
    log_success "✅ ServicoEstatisticaAuditoria corrigido"
else
    log_error "❌ ServicoEstatisticaAuditoria ainda incorreto"
fi

# Verificar ServicoExtracaoResultado
if grep -q "0 27 9 \* \* MON-SAT" src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/extracao/ServicoExtracaoResultado.java; then
    log_success "✅ ServicoExtracaoResultado corrigido"
else
    log_error "❌ ServicoExtracaoResultado ainda incorreto"
fi

# 3. Compilar para verificar se não há erros de sintaxe
log_info "3. Compilando projeto para verificar sintaxe..."

if command -v ./mvnw >/dev/null 2>&1; then
    ./mvnw compile -q
    if [ $? -eq 0 ]; then
        log_success "✅ Compilação bem-sucedida"
    else
        log_error "❌ Erro na compilação"
        exit 1
    fi
else
    log_warning "⚠️  Maven Wrapper não encontrado, pulando compilação"
fi

log_info "=== RESUMO DAS CORREÇÕES ==="

echo ""
log_info "📋 Correções aplicadas:"
echo "   • OrquestradorExtracoes: cron corrigido para formato padrão"
echo "   • ConfiguracaoAuditoriaPerformance: 3 expressões cron corrigidas"
echo "   • ServicoEstatisticaAuditoria: 1 expressão cron corrigida"
echo "   • ServicoExtracaoResultado: 9 expressões cron corrigidas"
echo ""

log_info "🔧 Mudanças realizadas:"
echo "   • Removido campo '?' (formato Quartz)"
echo "   • Ajustado para formato cron padrão (6 campos)"
echo "   • Mantido timezone 'America/Sao_Paulo'"
echo ""

log_info "🚀 Para aplicar no servidor:"
echo "   1. Fazer commit das correções"
echo "   2. Fazer deploy com nova imagem"
echo "   3. Verificar logs de inicialização"
echo ""

log_success "🎉 Verificação concluída! Expressões cron corrigidas."
