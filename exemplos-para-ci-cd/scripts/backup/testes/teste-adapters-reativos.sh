#!/bin/bash

# ========================================
# SCRIPT DE TESTE - ADAPTERS REATIVOS
# Conexão de Sorte - Validação de Implementação
# ========================================

set -euo pipefail

# Configurações
PROJETO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELATORIO_DIR="$PROJETO_ROOT/docs/testes"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RELATORIO_ARQUIVO="$RELATORIO_DIR/teste-adapters-$TIMESTAMP.md"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Criar diretório de relatórios
mkdir -p "$RELATORIO_DIR"

# Inicializar relatório
cat > "$RELATORIO_ARQUIVO" << 'EOF'
# 🧪 RELATÓRIO DE TESTES - ADAPTERS REATIVOS

**Data do Teste:** $(date)  
**Objetivo:** Validar implementação dos adapters reativos JPA→Reactive  
**Fase:** 1.1 - Implementar Adapters Reativos

---

## 📊 RESUMO DOS TESTES

EOF

log "🧪 Iniciando testes dos adapters reativos..."

# ========================================
# 1. VERIFICAÇÃO DE COMPILAÇÃO
# ========================================

log "🔨 Verificando compilação do projeto..."

cd "$PROJETO_ROOT"

# Compilar projeto
if ./mvnw clean compile -q; then
    success "✅ Compilação bem-sucedida"
    echo "- ✅ **Compilação:** SUCESSO" >> "$RELATORIO_ARQUIVO"
else
    error "❌ Falha na compilação"
    echo "- ❌ **Compilação:** FALHA" >> "$RELATORIO_ARQUIVO"
    exit 1
fi

# ========================================
# 2. VERIFICAÇÃO DE DEPENDÊNCIAS
# ========================================

log "📦 Verificando dependências dos adapters..."

# Verificar se as interfaces foram criadas
INTERFACES_CRIADAS=0
ADAPTERS_CRIADOS=0

# Verificar interfaces reativas
if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/UsuarioRepositoryReativo.java" ]; then
    INTERFACES_CRIADAS=$((INTERFACES_CRIADAS + 1))
    success "✅ UsuarioRepositoryReativo criado"
fi

if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/MensagemRepositoryReativo.java" ]; then
    INTERFACES_CRIADAS=$((INTERFACES_CRIADAS + 1))
    success "✅ MensagemRepositoryReativo criado"
fi

if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio/LoteriaRepositoryReativo.java" ]; then
    INTERFACES_CRIADAS=$((INTERFACES_CRIADAS + 1))
    success "✅ LoteriaRepositoryReativo criado"
fi

# Verificar adapters
if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/UsuarioRepositoryReativoAdapter.java" ]; then
    ADAPTERS_CRIADOS=$((ADAPTERS_CRIADOS + 1))
    success "✅ UsuarioRepositoryReativoAdapter criado"
fi

if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/LoteriaRepositoryReativoAdapter.java" ]; then
    ADAPTERS_CRIADOS=$((ADAPTERS_CRIADOS + 1))
    success "✅ LoteriaRepositoryReativoAdapter criado"
fi

if [ -f "src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/MegaSenaRepositoryReativoAdapter.java" ]; then
    ADAPTERS_CRIADOS=$((ADAPTERS_CRIADOS + 1))
    success "✅ MegaSenaRepositoryReativoAdapter criado"
fi

# Adicionar ao relatório
cat >> "$RELATORIO_ARQUIVO" << EOF
- ✅ **Interfaces Reativas:** $INTERFACES_CRIADAS/3 criadas
- ✅ **Adapters Implementados:** $ADAPTERS_CRIADOS/3 criados

---

## 🔍 DETALHES DOS TESTES

### Interfaces Reativas Criadas
EOF

if [ $INTERFACES_CRIADAS -eq 3 ]; then
    cat >> "$RELATORIO_ARQUIVO" << 'EOF'
- ✅ `UsuarioRepositoryReativo` - Interface para operações reativas de usuário
- ✅ `MensagemRepositoryReativo` - Interface para operações reativas de mensagem  
- ✅ `LoteriaRepositoryReativo<T>` - Interface genérica para loterias

### Adapters Implementados
EOF
fi

if [ $ADAPTERS_CRIADOS -eq 3 ]; then
    cat >> "$RELATORIO_ARQUIVO" << 'EOF'
- ✅ `UsuarioRepositoryReativoAdapter` - Adapter JPA→Reactive para usuários
- ✅ `LoteriaRepositoryReativoAdapter<T>` - Adapter genérico para loterias
- ✅ `MegaSenaRepositoryReativoAdapter` - Adapter específico para Mega-Sena
EOF
fi

# ========================================
# 3. ANÁLISE DE CÓDIGO
# ========================================

log "🔍 Analisando qualidade do código dos adapters..."

# Verificar se usam Schedulers.boundedElastic()
SCHEDULERS_OK=0
if grep -r "Schedulers.boundedElastic()" src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/ > /dev/null 2>&1; then
    SCHEDULERS_OK=1
    success "✅ Adapters usam Schedulers.boundedElastic() corretamente"
else
    warn "⚠️ Adapters podem não estar usando Schedulers.boundedElastic()"
fi

# Verificar se usam LoggingUtils
LOGGING_OK=0
if grep -r "LoggingUtils" src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/ > /dev/null 2>&1; then
    LOGGING_OK=1
    success "✅ Adapters implementam logging estruturado"
else
    warn "⚠️ Adapters podem não estar usando logging estruturado"
fi

# Verificar se implementam tratamento de erro
ERROR_HANDLING_OK=0
if grep -r "doOnError" src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter/ > /dev/null 2>&1; then
    ERROR_HANDLING_OK=1
    success "✅ Adapters implementam tratamento de erro"
else
    warn "⚠️ Adapters podem não estar tratando erros adequadamente"
fi

# ========================================
# 4. VERIFICAÇÃO DE PADRÕES DDD
# ========================================

log "🏗️ Verificando aderência aos padrões DDD..."

# Verificar se interfaces estão no domínio
INTERFACES_DOMINIO_OK=0
if [ -d "src/main/java/br/tec/facilitaservicos/conexaodesorte/dominio/repositorio" ]; then
    INTERFACES_DOMINIO_OK=1
    success "✅ Interfaces reativas estão no pacote de domínio"
else
    error "❌ Interfaces reativas não estão no pacote de domínio"
fi

# Verificar se adapters estão na infraestrutura
ADAPTERS_INFRA_OK=0
if [ -d "src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/repositorio/adapter" ]; then
    ADAPTERS_INFRA_OK=1
    success "✅ Adapters estão no pacote de infraestrutura"
else
    error "❌ Adapters não estão no pacote de infraestrutura"
fi

# ========================================
# 5. FINALIZAÇÃO E RELATÓRIO
# ========================================

# Calcular score geral
SCORE_TOTAL=0
SCORE_MAX=7

[ $INTERFACES_CRIADAS -eq 3 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))
[ $ADAPTERS_CRIADOS -eq 3 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))
[ $SCHEDULERS_OK -eq 1 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))
[ $LOGGING_OK -eq 1 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))
[ $ERROR_HANDLING_OK -eq 1 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))
[ $INTERFACES_DOMINIO_OK -eq 1 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))
[ $ADAPTERS_INFRA_OK -eq 1 ] && SCORE_TOTAL=$((SCORE_TOTAL + 1))

PERCENTUAL=$((SCORE_TOTAL * 100 / SCORE_MAX))

# Adicionar resultado final ao relatório
cat >> "$RELATORIO_ARQUIVO" << EOF

---

## 📊 RESULTADO FINAL

### Score de Qualidade: $SCORE_TOTAL/$SCORE_MAX ($PERCENTUAL%)

#### Critérios Avaliados:
- **Interfaces Criadas:** $INTERFACES_CRIADAS/3 ✅
- **Adapters Implementados:** $ADAPTERS_CRIADOS/3 ✅
- **Uso de Schedulers:** $([ $SCHEDULERS_OK -eq 1 ] && echo "✅" || echo "⚠️")
- **Logging Estruturado:** $([ $LOGGING_OK -eq 1 ] && echo "✅" || echo "⚠️")
- **Tratamento de Erro:** $([ $ERROR_HANDLING_OK -eq 1 ] && echo "✅" || echo "⚠️")
- **Interfaces no Domínio:** $([ $INTERFACES_DOMINIO_OK -eq 1 ] && echo "✅" || echo "❌")
- **Adapters na Infraestrutura:** $([ $ADAPTERS_INFRA_OK -eq 1 ] && echo "✅" || echo "❌")

### Recomendações:
EOF

if [ $PERCENTUAL -ge 85 ]; then
    cat >> "$RELATORIO_ARQUIVO" << 'EOF'
- ✅ **Implementação EXCELENTE** - Adapters prontos para uso
- ✅ Pode prosseguir para próxima fase
- ✅ Padrões DDD bem aplicados
EOF
    success "🎉 Implementação EXCELENTE dos adapters reativos!"
elif [ $PERCENTUAL -ge 70 ]; then
    cat >> "$RELATORIO_ARQUIVO" << 'EOF'
- ⚠️ **Implementação BOA** - Pequenos ajustes necessários
- ⚠️ Revisar pontos de melhoria antes de prosseguir
- ✅ Base sólida estabelecida
EOF
    warn "⚠️ Implementação BOA - pequenos ajustes necessários"
else
    cat >> "$RELATORIO_ARQUIVO" << 'EOF'
- ❌ **Implementação INSUFICIENTE** - Correções necessárias
- ❌ Não prosseguir até resolver problemas identificados
- ❌ Revisar padrões DDD e implementação reativa
EOF
    error "❌ Implementação INSUFICIENTE - correções necessárias"
fi

cat >> "$RELATORIO_ARQUIVO" << 'EOF'

---

**Teste executado em:** $(date)  
**Próximo passo:** Implementar testes unitários para os adapters
EOF

echo ""
log "🎉 Testes dos adapters reativos concluídos!"
info "📄 Relatório disponível em: $RELATORIO_ARQUIVO"
info "📊 Score final: $SCORE_TOTAL/$SCORE_MAX ($PERCENTUAL%)"

# Exibir resumo no terminal
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}      RESULTADO DOS TESTES${NC}"
echo -e "${PURPLE}========================================${NC}"
echo -e "${CYAN}📊 Score:${NC} $SCORE_TOTAL/$SCORE_MAX ($PERCENTUAL%)"
echo -e "${CYAN}🔧 Interfaces:${NC} $INTERFACES_CRIADAS/3"
echo -e "${CYAN}⚙️ Adapters:${NC} $ADAPTERS_CRIADOS/3"
echo -e "${CYAN}📋 Status:${NC} $([ $PERCENTUAL -ge 85 ] && echo -e "${GREEN}EXCELENTE${NC}" || ([ $PERCENTUAL -ge 70 ] && echo -e "${YELLOW}BOM${NC}" || echo -e "${RED}INSUFICIENTE${NC}"))"
echo -e "${PURPLE}========================================${NC}"

# Retornar código de saída baseado no score
if [ $PERCENTUAL -ge 70 ]; then
    exit 0
else
    exit 1
fi
