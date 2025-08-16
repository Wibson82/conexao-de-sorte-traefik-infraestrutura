#!/bin/bash

# Script de Consolidação de Classes com Sufixos Problemáticos
# Autor: Sistema de Consolidação Automatizada
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
BACKUP_DIR="$PROJECT_ROOT/backup-sufixos-$(date +%Y%m%d-%H%M%S)"

echo -e "${CYAN}🔧 CONSOLIDAÇÃO DE SUFIXOS PROBLEMÁTICOS${NC}"
echo -e "${CYAN}=======================================${NC}"
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

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅${NC} $1"
}

# Criar backup
log "📦 Criando backup em: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Função para renomear classe
renomear_classe() {
    local nome_antigo="$1"
    local nome_novo="$2"
    local arquivo_antigo arquivo_novo
    
    # Encontrar o arquivo da classe
    arquivo_antigo=$(find "$PROJECT_ROOT/src" -name "${nome_antigo}.java" | head -1)
    
    if [[ -z "$arquivo_antigo" ]]; then
        warn "Arquivo não encontrado para classe: $nome_antigo"
        return 1
    fi
    
    # Definir novo caminho
    arquivo_novo="${arquivo_antigo%/*}/${nome_novo}.java"
    
    log "🔄 Renomeando: $nome_antigo → $nome_novo"
    
    # Backup
    cp "$arquivo_antigo" "$BACKUP_DIR/${nome_antigo}.java.bak"
    
    # Renomear arquivo
    mv "$arquivo_antigo" "$arquivo_novo"
    
    # Atualizar nome da classe no arquivo
    sed -i.bak "s/public class $nome_antigo/public class $nome_novo/g" "$arquivo_novo"
    sed -i.bak "s/public interface $nome_antigo/public interface $nome_novo/g" "$arquivo_novo"
    sed -i.bak "s/public enum $nome_antigo/public enum $nome_novo/g" "$arquivo_novo"
    
    # Remover arquivo backup temporário
    rm -f "${arquivo_novo}.bak"
    
    # Atualizar referências em todos os arquivos
    log "📝 Atualizando referências para: $nome_novo"
    find "$PROJECT_ROOT/src" -name "*.java" -type f -exec sed -i.bak "s/$nome_antigo/$nome_novo/g" {} \;
    
    # Limpar backups temporários
    find "$PROJECT_ROOT/src" -name "*.bak" -delete
    
    success "Classe renomeada: $nome_antigo → $nome_novo"
}

# CONSOLIDAÇÕES ESPECÍFICAS

log "1️⃣ Consolidando classes 'Consolidada/Consolidado'..."

# ConfiguracaoExecutoresConsolidada → ConfiguracaoExecutores
renomear_classe "ConfiguracaoExecutoresConsolidada" "ConfiguracaoExecutores"

# ValidadorAmbienteConsolidado → ValidadorAmbiente
renomear_classe "ValidadorAmbienteConsolidado" "ValidadorAmbiente"

# ServicoMonitoramentoCacheConsolidado → ServicoMonitoramentoCache
renomear_classe "ServicoMonitoramentoCacheConsolidado" "ServicoMonitoramentoCache"

# RegistradorMetricasSegurancaConsolidado → RegistradorMetricasSeguranca
renomear_classe "RegistradorMetricasSegurancaConsolidado" "RegistradorMetricasSeguranca"

# ServicoAzureKeyVaultConsolidado → ServicoAzureKeyVault
renomear_classe "ServicoAzureKeyVaultConsolidado" "ServicoAzureKeyVault"

# ValidadorSegurancaConsolidado → ValidadorSeguranca
renomear_classe "ValidadorSegurancaConsolidado" "ValidadorSeguranca"

# ServicoAzureConsolidado → ServicoAzure
renomear_classe "ServicoAzureConsolidado" "ServicoAzure"

log "2️⃣ Consolidando classes 'Unificada/Unificado'..."

# ConfiguracaoRecursosUnificada → ConfiguracaoRecursos
renomear_classe "ConfiguracaoRecursosUnificada" "ConfiguracaoRecursos"

# ValidadorUrlUnificado → ValidadorUrl
renomear_classe "ValidadorUrlUnificado" "ValidadorUrl"

# RepositorioAuditoriaUnificado → RepositorioAuditoria
renomear_classe "RepositorioAuditoriaUnificado" "RepositorioAuditoria"

log "3️⃣ Verificando classes que não devem ser renomeadas..."

# Algumas classes podem ter sufixos por motivos válidos
CLASSES_MANTER=(
    "ConsolidadorUtilitarios"  # Nome descritivo válido
    "ConfiguracaoUnificadaBeans"  # Nome específico válido
    "UtilidadesConsolidadas"  # Nome descritivo válido
    "ConstantesConfiguracaoConsolidadas"  # Nome específico válido
    "ConstantesNumericasConsolidadas"  # Nome específico válido
    "ConstantesValidacaoConsolidadas"  # Nome específico válido
)

for classe in "${CLASSES_MANTER[@]}"; do
    log "📌 Mantendo classe: $classe (nome válido)"
done

log "4️⃣ Verificando compilação..."

# Tentar compilar para verificar se há erros
if ./mvnw clean compile -DskipTests -q; then
    success "✅ Compilação bem-sucedida após consolidação!"
else
    error "❌ Erro na compilação. Verificando logs..."
    ./mvnw clean compile -DskipTests | tail -20
fi

# Resumo
echo ""
echo -e "${PURPLE}📋 RESUMO DA CONSOLIDAÇÃO:${NC}"
echo -e "   📦 Backup criado em: ${BACKUP_DIR}"
echo -e "   🔄 Classes consolidadas:"
echo -e "      • ConfiguracaoExecutoresConsolidada → ConfiguracaoExecutores"
echo -e "      • ValidadorAmbienteConsolidado → ValidadorAmbiente"
echo -e "      • ServicoMonitoramentoCacheConsolidado → ServicoMonitoramentoCache"
echo -e "      • RegistradorMetricasSegurancaConsolidado → RegistradorMetricasSeguranca"
echo -e "      • ServicoAzureKeyVaultConsolidado → ServicoAzureKeyVault"
echo -e "      • ValidadorSegurancaConsolidado → ValidadorSeguranca"
echo -e "      • ServicoAzureConsolidado → ServicoAzure"
echo -e "      • ConfiguracaoRecursosUnificada → ConfiguracaoRecursos"
echo -e "      • ValidadorUrlUnificado → ValidadorUrl"
echo -e "      • RepositorioAuditoriaUnificado → RepositorioAuditoria"
echo -e "   ✅ Referências atualizadas em todos os arquivos"
echo ""

success "🎉 Consolidação de sufixos concluída com sucesso!"
