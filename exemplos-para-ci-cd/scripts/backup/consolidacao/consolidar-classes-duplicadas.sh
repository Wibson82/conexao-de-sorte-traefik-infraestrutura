#!/bin/bash

# Script de Consolidação de Classes Duplicadas
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
BACKUP_DIR="$PROJECT_ROOT/backup-consolidacao-$(date +%Y%m%d-%H%M%S)"

echo -e "${CYAN}🔧 CONSOLIDAÇÃO DE CLASSES DUPLICADAS${NC}"
echo -e "${CYAN}====================================${NC}"
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

# Criar backup
log "📦 Criando backup em: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 1. CONSOLIDAR CLASSES COM SUFIXOS PROBLEMÁTICOS
log "1️⃣ Consolidando classes com sufixos problemáticos..."

# ConfiguracaoJpaConsolidada -> ConfiguracaoJpa
if [[ -f "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpaConsolidada.java" ]]; then
    log "🔄 Renomeando ConfiguracaoJpaConsolidada -> ConfiguracaoJpa"
    
    # Backup
    cp "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpaConsolidada.java" \
       "$BACKUP_DIR/ConfiguracaoJpaConsolidada.java.bak"
    
    # Renomear arquivo
    mv "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpaConsolidada.java" \
       "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpa.java"
    
    # Atualizar nome da classe no arquivo
    sed -i.bak 's/public class ConfiguracaoJpaConsolidada/public class ConfiguracaoJpa/g' \
        "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/infraestrutura/jpa/ConfiguracaoJpa.java"
    
    log "✅ ConfiguracaoJpaConsolidada renomeada para ConfiguracaoJpa"
fi

# ConfiguracaoWebSocketConsolidada -> ConfiguracaoWebSocket
if [[ -f "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/web/websocket/ConfiguracaoWebSocketConsolidada.java" ]]; then
    log "🔄 Renomeando ConfiguracaoWebSocketConsolidada -> ConfiguracaoWebSocket"
    
    # Backup
    cp "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/web/websocket/ConfiguracaoWebSocketConsolidada.java" \
       "$BACKUP_DIR/ConfiguracaoWebSocketConsolidada.java.bak"
    
    # Renomear arquivo
    mv "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/web/websocket/ConfiguracaoWebSocketConsolidada.java" \
       "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/web/websocket/ConfiguracaoWebSocket.java"
    
    # Atualizar nome da classe no arquivo
    sed -i.bak 's/public class ConfiguracaoWebSocketConsolidada/public class ConfiguracaoWebSocket/g' \
        "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/web/websocket/ConfiguracaoWebSocket.java"
    
    log "✅ ConfiguracaoWebSocketConsolidada renomeada para ConfiguracaoWebSocket"
fi

# ConfiguracaoAuditoriaConsolidada -> ConfiguracaoAuditoria
if [[ -f "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaConsolidada.java" ]]; then
    log "🔄 Renomeando ConfiguracaoAuditoriaConsolidada -> ConfiguracaoAuditoria"
    
    # Backup
    cp "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaConsolidada.java" \
       "$BACKUP_DIR/ConfiguracaoAuditoriaConsolidada.java.bak"
    
    # Renomear arquivo
    mv "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoriaConsolidada.java" \
       "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoria.java"
    
    # Atualizar nome da classe no arquivo
    sed -i.bak 's/public class ConfiguracaoAuditoriaConsolidada/public class ConfiguracaoAuditoria/g' \
        "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/auditoria/ConfiguracaoAuditoria.java"
    
    log "✅ ConfiguracaoAuditoriaConsolidada renomeada para ConfiguracaoAuditoria"
fi

# ServicoAuditoriaUnificada -> ServicoAuditoria
if [[ -f "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java" ]]; then
    log "🔄 Renomeando ServicoAuditoriaUnificada -> ServicoAuditoria"
    
    # Backup
    cp "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java" \
       "$BACKUP_DIR/ServicoAuditoriaUnificada.java.bak"
    
    # Renomear arquivo
    mv "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoriaUnificada.java" \
       "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoria.java"
    
    # Atualizar nome da classe no arquivo
    sed -i.bak 's/public class ServicoAuditoriaUnificada/public class ServicoAuditoria/g' \
        "$PROJECT_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/auditoria/ServicoAuditoria.java"
    
    log "✅ ServicoAuditoriaUnificada renomeada para ServicoAuditoria"
fi

# 2. ATUALIZAR REFERÊNCIAS NOS ARQUIVOS
log "2️⃣ Atualizando referências nos arquivos..."

# Buscar e substituir referências
find "$PROJECT_ROOT/src" -name "*.java" -type f -exec grep -l "ConfiguracaoJpaConsolidada" {} \; | while read -r file; do
    log "🔄 Atualizando referências em: $(basename "$file")"
    sed -i.bak 's/ConfiguracaoJpaConsolidada/ConfiguracaoJpa/g' "$file"
done

find "$PROJECT_ROOT/src" -name "*.java" -type f -exec grep -l "ConfiguracaoWebSocketConsolidada" {} \; | while read -r file; do
    log "🔄 Atualizando referências em: $(basename "$file")"
    sed -i.bak 's/ConfiguracaoWebSocketConsolidada/ConfiguracaoWebSocket/g' "$file"
done

find "$PROJECT_ROOT/src" -name "*.java" -type f -exec grep -l "ConfiguracaoAuditoriaConsolidada" {} \; | while read -r file; do
    log "🔄 Atualizando referências em: $(basename "$file")"
    sed -i.bak 's/ConfiguracaoAuditoriaConsolidada/ConfiguracaoAuditoria/g' "$file"
done

find "$PROJECT_ROOT/src" -name "*.java" -type f -exec grep -l "ServicoAuditoriaUnificada" {} \; | while read -r file; do
    log "🔄 Atualizando referências em: $(basename "$file")"
    sed -i.bak 's/ServicoAuditoriaUnificada/ServicoAuditoria/g' "$file"
done

# 3. LIMPAR ARQUIVOS BACKUP TEMPORÁRIOS
log "3️⃣ Limpando arquivos temporários..."
find "$PROJECT_ROOT/src" -name "*.bak" -delete

log "✅ Consolidação de classes concluída!"
echo ""
echo -e "${PURPLE}📋 RESUMO DA CONSOLIDAÇÃO:${NC}"
echo -e "   📦 Backup criado em: ${BACKUP_DIR}"
echo -e "   🔄 ConfiguracaoJpaConsolidada → ConfiguracaoJpa"
echo -e "   🔄 ConfiguracaoWebSocketConsolidada → ConfiguracaoWebSocket"
echo -e "   🔄 ConfiguracaoAuditoriaConsolidada → ConfiguracaoAuditoria"
echo -e "   🔄 ServicoAuditoriaUnificada → ServicoAuditoria"
echo -e "   ✅ Referências atualizadas em todos os arquivos"
echo ""
