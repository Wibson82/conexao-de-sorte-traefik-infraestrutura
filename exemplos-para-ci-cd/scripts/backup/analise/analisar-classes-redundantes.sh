#!/bin/bash

# Script de Análise de Classes Redundantes e Duplicadas
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
REPORT_DIR="$PROJECT_ROOT/scripts/analise/relatorios"

echo -e "${CYAN}🔍 ANÁLISE DE CLASSES REDUNDANTES E DUPLICADAS${NC}"
echo -e "${CYAN}===============================================${NC}"
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

# Criar diretório de relatórios
mkdir -p "$REPORT_DIR"

# 1. ANÁLISE DE CLASSES COM SUFIXOS PROBLEMÁTICOS
log "1️⃣ Analisando classes com sufixos problemáticos..."

SUFIXOS_PROBLEMATICOS=("Consolidada" "Consolidado" "Unificada" "Unificado" "Duplicada" "Duplicado" "Temp" "Backup" "Old" "Legacy")
CLASSES_PROBLEMATICAS=()

for sufixo in "${SUFIXOS_PROBLEMATICOS[@]}"; do
    while IFS= read -r -d '' arquivo; do
        if [[ -f "$arquivo" ]]; then
            nome_classe=$(basename "$arquivo" .java)
            if [[ "$nome_classe" == *"$sufixo" ]]; then
                CLASSES_PROBLEMATICAS+=("$arquivo:$sufixo")
                warn "Classe com sufixo problemático: $nome_classe ($sufixo)"
            fi
        fi
    done < <(find "$PROJECT_ROOT/src" -name "*.java" -print0)
done

# 2. ANÁLISE DE CLASSES DUPLICADAS POR NOME
log "2️⃣ Analisando classes duplicadas por nome..."

declare -A NOMES_CLASSES
CLASSES_DUPLICADAS=()

while IFS= read -r -d '' arquivo; do
    if [[ -f "$arquivo" ]]; then
        nome_classe=$(basename "$arquivo" .java)
        if [[ -n "${NOMES_CLASSES[$nome_classe]:-}" ]]; then
            CLASSES_DUPLICADAS+=("$nome_classe:${NOMES_CLASSES[$nome_classe]}:$arquivo")
            warn "Classe duplicada encontrada: $nome_classe"
        else
            NOMES_CLASSES[$nome_classe]="$arquivo"
        fi
    fi
done < <(find "$PROJECT_ROOT/src" -name "*.java" -print0)

# 3. ANÁLISE DE DEPENDÊNCIAS CIRCULARES
log "3️⃣ Analisando possíveis dependências circulares..."

DEPENDENCIAS_CIRCULARES=()

while IFS= read -r -d '' arquivo; do
    if [[ -f "$arquivo" ]]; then
        nome_classe=$(basename "$arquivo" .java)
        # Verificar se a classe injeta a si mesma
        if grep -q "private.*final.*$nome_classe.*$nome_classe" "$arquivo" 2>/dev/null; then
            DEPENDENCIAS_CIRCULARES+=("$arquivo:AUTO_INJECAO")
            error "Dependência circular (auto-injeção): $nome_classe"
        fi
        
        # Verificar se o construtor recebe a própria classe
        if grep -A 10 "public $nome_classe(" "$arquivo" 2>/dev/null | grep -q "$nome_classe.*$nome_classe"; then
            DEPENDENCIAS_CIRCULARES+=("$arquivo:CONSTRUTOR_CIRCULAR")
            error "Dependência circular (construtor): $nome_classe"
        fi
    fi
done < <(find "$PROJECT_ROOT/src" -name "*.java" -print0)

# 4. ANÁLISE DE CLASSES COM FUNCIONALIDADES SIMILARES
log "4️⃣ Analisando classes com funcionalidades similares..."

GRUPOS_SIMILARES=()
declare -A PALAVRAS_CHAVE

# Definir grupos de palavras-chave que indicam funcionalidades similares
GRUPOS_FUNCIONALIDADE=(
    "Auditoria:auditoria,audit,log,evento"
    "Configuracao:config,configuracao,setup,properties"
    "Servico:service,servico,manager,gerenciador"
    "Repositorio:repository,repositorio,dao,data"
    "Controller:controller,controlador,rest,api"
    "Seguranca:security,seguranca,auth,authentication"
    "Cache:cache,memoria,temp,temporario"
    "Email:email,mail,notificacao,notification"
)

for grupo in "${GRUPOS_FUNCIONALIDADE[@]}"; do
    IFS=':' read -r nome_grupo palavras <<< "$grupo"
    IFS=',' read -ra PALAVRAS_ARRAY <<< "$palavras"
    
    CLASSES_GRUPO=()
    
    while IFS= read -r -d '' arquivo; do
        if [[ -f "$arquivo" ]]; then
            nome_classe=$(basename "$arquivo" .java | tr '[:upper:]' '[:lower:]')
            for palavra in "${PALAVRAS_ARRAY[@]}"; do
                if [[ "$nome_classe" == *"$palavra"* ]]; then
                    CLASSES_GRUPO+=("$arquivo")
                    break
                fi
            done
        fi
    done < <(find "$PROJECT_ROOT/src" -name "*.java" -print0)
    
    if [[ ${#CLASSES_GRUPO[@]} -gt 3 ]]; then
        warn "Grupo $nome_grupo tem ${#CLASSES_GRUPO[@]} classes (possível redundância)"
        GRUPOS_SIMILARES+=("$nome_grupo:${#CLASSES_GRUPO[@]}")
    fi
done

# 5. GERAR RELATÓRIO
log "5️⃣ Gerando relatório..."

RELATORIO="$REPORT_DIR/classes-redundantes-$(date +%Y%m%d-%H%M%S).md"

cat > "$RELATORIO" << EOF
# 🔍 RELATÓRIO DE ANÁLISE DE CLASSES REDUNDANTES

**Data:** $(date '+%Y-%m-%d %H:%M:%S')  
**Projeto:** Conexão de Sorte Backend  

## 📊 RESUMO EXECUTIVO

- **Classes com sufixos problemáticos:** ${#CLASSES_PROBLEMATICAS[@]}
- **Classes duplicadas:** ${#CLASSES_DUPLICADAS[@]}
- **Dependências circulares:** ${#DEPENDENCIAS_CIRCULARES[@]}
- **Grupos com possível redundância:** ${#GRUPOS_SIMILARES[@]}

## 🚨 CLASSES COM SUFIXOS PROBLEMÁTICOS

EOF

if [[ ${#CLASSES_PROBLEMATICAS[@]} -gt 0 ]]; then
    for classe in "${CLASSES_PROBLEMATICAS[@]}"; do
        IFS=':' read -r arquivo sufixo <<< "$classe"
        nome_classe=$(basename "$arquivo" .java)
        echo "- **$nome_classe** (sufixo: $sufixo) → \`$arquivo\`" >> "$RELATORIO"
    done
else
    echo "✅ Nenhuma classe com sufixos problemáticos encontrada." >> "$RELATORIO"
fi

cat >> "$RELATORIO" << EOF

## 🔄 CLASSES DUPLICADAS

EOF

if [[ ${#CLASSES_DUPLICADAS[@]} -gt 0 ]]; then
    for duplicada in "${CLASSES_DUPLICADAS[@]}"; do
        IFS=':' read -r nome arquivo1 arquivo2 <<< "$duplicada"
        echo "- **$nome**" >> "$RELATORIO"
        echo "  - \`$arquivo1\`" >> "$RELATORIO"
        echo "  - \`$arquivo2\`" >> "$RELATORIO"
    done
else
    echo "✅ Nenhuma classe duplicada encontrada." >> "$RELATORIO"
fi

cat >> "$RELATORIO" << EOF

## ⚠️ DEPENDÊNCIAS CIRCULARES

EOF

if [[ ${#DEPENDENCIAS_CIRCULARES[@]} -gt 0 ]]; then
    for circular in "${DEPENDENCIAS_CIRCULARES[@]}"; do
        IFS=':' read -r arquivo tipo <<< "$circular"
        nome_classe=$(basename "$arquivo" .java)
        echo "- **$nome_classe** ($tipo) → \`$arquivo\`" >> "$RELATORIO"
    done
else
    echo "✅ Nenhuma dependência circular encontrada." >> "$RELATORIO"
fi

cat >> "$RELATORIO" << EOF

## 📦 GRUPOS COM POSSÍVEL REDUNDÂNCIA

EOF

if [[ ${#GRUPOS_SIMILARES[@]} -gt 0 ]]; then
    for grupo in "${GRUPOS_SIMILARES[@]}"; do
        IFS=':' read -r nome_grupo quantidade <<< "$grupo"
        echo "- **$nome_grupo:** $quantidade classes" >> "$RELATORIO"
    done
else
    echo "✅ Nenhum grupo com redundância excessiva encontrado." >> "$RELATORIO"
fi

cat >> "$RELATORIO" << EOF

## 🛠️ RECOMENDAÇÕES

### Ações Imediatas:
1. **Remover sufixos problemáticos** das classes identificadas
2. **Consolidar classes duplicadas** mantendo apenas uma versão
3. **Corrigir dependências circulares** usando injeção adequada
4. **Revisar grupos com muitas classes** para identificar redundâncias

### Ações de Médio Prazo:
1. Implementar linting rules para prevenir novos problemas
2. Criar documentação de arquitetura para evitar duplicações
3. Estabelecer convenções de nomenclatura claras
4. Implementar revisão de código focada em arquitetura

---
*Relatório gerado automaticamente pelo sistema de análise*
EOF

success "Relatório gerado: $RELATORIO"

# 6. EXIBIR RESUMO
echo ""
echo -e "${PURPLE}📋 RESUMO DA ANÁLISE:${NC}"
echo -e "   🚨 Classes com sufixos problemáticos: ${#CLASSES_PROBLEMATICAS[@]}"
echo -e "   🔄 Classes duplicadas: ${#CLASSES_DUPLICADAS[@]}"
echo -e "   ⚠️ Dependências circulares: ${#DEPENDENCIAS_CIRCULARES[@]}"
echo -e "   📦 Grupos com possível redundância: ${#GRUPOS_SIMILARES[@]}"
echo -e "   📄 Relatório: $RELATORIO"
echo ""

# Determinar status de saída
TOTAL_PROBLEMAS=$((${#CLASSES_PROBLEMATICAS[@]} + ${#CLASSES_DUPLICADAS[@]} + ${#DEPENDENCIAS_CIRCULARES[@]}))

if [[ $TOTAL_PROBLEMAS -eq 0 ]]; then
    success "🎉 Análise concluída: Nenhum problema crítico encontrado!"
    exit 0
else
    warn "⚠️ Análise concluída: $TOTAL_PROBLEMAS problemas encontrados!"
    exit 1
fi
