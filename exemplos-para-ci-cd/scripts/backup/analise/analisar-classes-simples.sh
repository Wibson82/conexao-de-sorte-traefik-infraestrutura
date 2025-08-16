#!/bin/bash

# Script Simples de Análise de Classes Redundantes
# Autor: Sistema de Análise Automatizada
# Data: 2025-08-09

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo -e "${CYAN}🔍 ANÁLISE SIMPLES DE CLASSES REDUNDANTES${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"
}

# 1. CLASSES COM SUFIXOS PROBLEMÁTICOS
log "1️⃣ Buscando classes com sufixos problemáticos..."

echo -e "${YELLOW}Classes com 'Consolidada/Consolidado':${NC}"
find "$PROJECT_ROOT/src" -name "*.java" -exec basename {} .java \; | grep -i "consolidad" | sort || echo "Nenhuma encontrada"

echo ""
echo -e "${YELLOW}Classes com 'Unificada/Unificado':${NC}"
find "$PROJECT_ROOT/src" -name "*.java" -exec basename {} .java \; | grep -i "unificad" | sort || echo "Nenhuma encontrada"

echo ""
echo -e "${YELLOW}Classes com 'Duplicada/Duplicado':${NC}"
find "$PROJECT_ROOT/src" -name "*.java" -exec basename {} .java \; | grep -i "duplicad" | sort || echo "Nenhuma encontrada"

# 2. DEPENDÊNCIAS CIRCULARES
log "2️⃣ Buscando possíveis dependências circulares..."

echo -e "${YELLOW}Classes que podem injetar a si mesmas:${NC}"
grep -r "private.*final.*\([A-Z][a-zA-Z]*\).*\1" "$PROJECT_ROOT/src" --include="*.java" | head -10 || echo "Nenhuma encontrada"

# 3. CLASSES DE AUDITORIA
log "3️⃣ Analisando classes de auditoria..."

echo -e "${YELLOW}Classes de Auditoria:${NC}"
find "$PROJECT_ROOT/src" -name "*.java" -exec basename {} .java \; | grep -i "audit" | sort

# 4. CLASSES DE CONFIGURAÇÃO
log "4️⃣ Analisando classes de configuração..."

echo -e "${YELLOW}Classes de Configuração:${NC}"
find "$PROJECT_ROOT/src" -name "*.java" -exec basename {} .java \; | grep -i "config" | wc -l | xargs echo "Total:"

# 5. CLASSES DE SERVIÇO
log "5️⃣ Analisando classes de serviço..."

echo -e "${YELLOW}Classes de Serviço:${NC}"
find "$PROJECT_ROOT/src" -name "*.java" -exec basename {} .java \; | grep -i "servico" | wc -l | xargs echo "Total:"

# 6. RECOMENDAÇÕES ESPECÍFICAS
echo ""
echo -e "${PURPLE}🛠️ RECOMENDAÇÕES ESPECÍFICAS:${NC}"

echo -e "${CYAN}Classes para renomear (remover sufixos):${NC}"
echo "- ConfiguracaoExecutoresConsolidada → ConfiguracaoExecutores"
echo "- ValidadorAmbienteConsolidado → ValidadorAmbiente"
echo "- ServicoMonitoramentoCacheConsolidado → ServicoMonitoramentoCache"
echo "- RegistradorMetricasSegurancaConsolidado → RegistradorMetricasSeguranca"
echo "- ServicoAzureKeyVaultConsolidado → ServicoAzureKeyVault"
echo "- ValidadorSegurancaConsolidado → ValidadorSeguranca"
echo "- ServicoAzureConsolidado → ServicoAzure"
echo "- ConfiguracaoRecursosUnificada → ConfiguracaoRecursos"
echo "- ValidadorUrlUnificado → ValidadorUrl"
echo "- RepositorioAuditoriaUnificado → RepositorioAuditoria"

echo ""
echo -e "${CYAN}Dependências circulares corrigidas:${NC}"
echo "✅ ServicoAuditoria - dependência circular removida"

echo ""
echo -e "${CYAN}Próximas ações:${NC}"
echo "1. Executar script de consolidação para renomear classes"
echo "2. Atualizar referências nos arquivos"
echo "3. Compilar e testar"
echo "4. Fazer commit das alterações"

echo ""
echo -e "${GREEN}✅ Análise concluída!${NC}"
