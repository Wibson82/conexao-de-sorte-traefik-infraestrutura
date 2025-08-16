#!/bin/bash

# ============================================================================
# 🏗️ SCRIPT DE ANÁLISE DA ESTRUTURA DDD
# ============================================================================
# 
# Analisa a estrutura do projeto seguindo os princípios de Domain-Driven Design
# e identifica possíveis melhorias na organização dos pacotes e responsabilidades.
#
# Autor: Conexão de Sorte Team
# Data: 2025-08-09
# ============================================================================

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Diretórios
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly SRC_DIR="${PROJECT_ROOT}/src/main/java/br/tec/facilitaservicos/conexaodesorte"
readonly REPORT_DIR="${PROJECT_ROOT}/analysis-reports"
readonly TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly REPORT_FILE="${REPORT_DIR}/analise-estrutura-ddd-${TIMESTAMP}.md"

# Criar diretório de relatórios se não existir
mkdir -p "${REPORT_DIR}"

echo -e "${BLUE}🏗️ ANÁLISE DA ESTRUTURA DDD - CONEXÃO DE SORTE${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Função para contar arquivos em um diretório
count_files() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        find "$dir" -name "*.java" -type f | wc -l
    else
        echo "0"
    fi
}

# Função para listar arquivos em um diretório
list_files() {
    local dir="$1"
    local max_files="${2:-10}"
    if [[ -d "$dir" ]]; then
        find "$dir" -name "*.java" -type f | head -n "$max_files" | sed 's|.*/||'
    fi
}

# Iniciar relatório
cat > "$REPORT_FILE" << EOF
# 🏗️ ANÁLISE DA ESTRUTURA DDD - CONEXÃO DE SORTE

**Data:** $(date '+%d/%m/%Y %H:%M:%S')  
**Projeto:** Conexão de Sorte Backend  
**Versão:** 1.0  

## 📋 RESUMO EXECUTIVO

Esta análise avalia a estrutura do projeto seguindo os princípios de Domain-Driven Design (DDD) e identifica oportunidades de melhoria na organização dos pacotes e separação de responsabilidades.

---

## 🎯 ESTRUTURA ATUAL DO PROJETO

### 📁 Pacotes Principais

EOF

echo -e "${CYAN}📊 Analisando estrutura de pacotes...${NC}"

# Analisar estrutura principal
echo "#### 🏛️ Camadas Arquiteturais" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Domínio
DOMINIO_COUNT=$(count_files "${SRC_DIR}/dominio")
echo "- **Domínio:** ${DOMINIO_COUNT} classes" >> "$REPORT_FILE"

# Aplicação
APLICACAO_COUNT=$(count_files "${SRC_DIR}/aplicacao")
echo "- **Aplicação:** ${APLICACAO_COUNT} classes" >> "$REPORT_FILE"

# Infraestrutura
INFRA_COUNT=$(count_files "${SRC_DIR}/infraestrutura")
echo "- **Infraestrutura:** ${INFRA_COUNT} classes" >> "$REPORT_FILE"

# Configuração
CONFIG_COUNT=$(count_files "${SRC_DIR}/configuracao")
echo "- **Configuração:** ${CONFIG_COUNT} classes" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

# Analisar subdomínios/contextos
echo "#### 🎯 Contextos Delimitados (Bounded Contexts)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Autenticação
AUTH_COUNT=$(count_files "${SRC_DIR}/aplicacao/autenticacao")
echo "- **Autenticação:** ${AUTH_COUNT} classes" >> "$REPORT_FILE"

# Bate-papo
CHAT_COUNT=$(count_files "${SRC_DIR}/aplicacao/batepapo")
echo "- **Bate-papo:** ${CHAT_COUNT} classes" >> "$REPORT_FILE"

# Loterias
LOTERIA_COUNT=$(count_files "${SRC_DIR}/aplicacao/loteria")
echo "- **Loterias:** ${LOTERIA_COUNT} classes" >> "$REPORT_FILE"

# Usuários
USUARIO_COUNT=$(count_files "${SRC_DIR}/aplicacao/usuario")
echo "- **Usuários:** ${USUARIO_COUNT} classes" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

# Analisar DTOs
echo "#### 📦 Data Transfer Objects (DTOs)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

DTO_COUNT=$(count_files "${SRC_DIR}/dto")
echo "- **Total de DTOs:** ${DTO_COUNT} classes" >> "$REPORT_FILE"

# DTOs por contexto
DTO_AUTH_COUNT=$(count_files "${SRC_DIR}/aplicacao/autenticacao/dto")
DTO_CHAT_COUNT=$(count_files "${SRC_DIR}/aplicacao/batepapo/dto")
DTO_LOTERIA_COUNT=$(count_files "${SRC_DIR}/dto/loteria")

echo "- **DTOs Autenticação:** ${DTO_AUTH_COUNT} classes" >> "$REPORT_FILE"
echo "- **DTOs Bate-papo:** ${DTO_CHAT_COUNT} classes" >> "$REPORT_FILE"
echo "- **DTOs Loterias:** ${DTO_LOTERIA_COUNT} classes" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"

echo -e "${GREEN}✅ Análise de estrutura concluída${NC}"

# Analisar violações DDD
echo -e "${YELLOW}🔍 Identificando violações DDD...${NC}"

echo "## 🚨 VIOLAÇÕES DDD IDENTIFICADAS" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Procurar imports problemáticos
echo "### ❌ Dependências Problemáticas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Domínio importando infraestrutura
DOMAIN_INFRA_VIOLATIONS=$(find "${SRC_DIR}/dominio" -name "*.java" -type f -exec grep -l "import.*infraestrutura" {} \; 2>/dev/null | wc -l)
if [[ $DOMAIN_INFRA_VIOLATIONS -gt 0 ]]; then
    echo "- **🔴 CRÍTICO:** ${DOMAIN_INFRA_VIOLATIONS} classes do domínio importam infraestrutura" >> "$REPORT_FILE"
fi

# Domínio importando configuração
DOMAIN_CONFIG_VIOLATIONS=$(find "${SRC_DIR}/dominio" -name "*.java" -type f -exec grep -l "import.*configuracao" {} \; 2>/dev/null | wc -l)
if [[ $DOMAIN_CONFIG_VIOLATIONS -gt 0 ]]; then
    echo "- **🟡 IMPORTANTE:** ${DOMAIN_CONFIG_VIOLATIONS} classes do domínio importam configuração" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# Analisar separação de responsabilidades
echo "## 📊 ANÁLISE DE RESPONSABILIDADES" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 🎯 Contextos Identificados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Listar contextos principais
for context in autenticacao batepapo loteria usuario; do
    if [[ -d "${SRC_DIR}/aplicacao/${context}" ]]; then
        CONTEXT_COUNT=$(count_files "${SRC_DIR}/aplicacao/${context}")
        echo "#### 📁 $(echo ${context} | sed 's/./\U&/')" >> "$REPORT_FILE"
        echo "- **Total:** ${CONTEXT_COUNT} classes" >> "$REPORT_FILE"
        
        # Analisar subcomponentes
        for subdir in controle servico dto repositorio; do
            if [[ -d "${SRC_DIR}/aplicacao/${context}/${subdir}" ]]; then
                SUB_COUNT=$(count_files "${SRC_DIR}/aplicacao/${context}/${subdir}")
                echo "- **$(echo ${subdir} | sed 's/./\U&/'):** ${SUB_COUNT} classes" >> "$REPORT_FILE"
            fi
        done
        echo "" >> "$REPORT_FILE"
    fi
done

echo -e "${GREEN}✅ Análise de responsabilidades concluída${NC}"

# Recomendações
echo "## 💡 RECOMENDAÇÕES DE MELHORIA" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 🏗️ Estrutura Arquitetural" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **Consolidar DTOs por contexto:** Mover DTOs para dentro dos respectivos contextos" >> "$REPORT_FILE"
echo "2. **Criar interfaces de domínio:** Abstrair dependências de infraestrutura" >> "$REPORT_FILE"
echo "3. **Separar configurações:** Distinguir configurações globais de específicas" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 🎯 Contextos Delimitados" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **Definir boundaries claros:** Cada contexto deve ter suas próprias entidades, DTOs e serviços" >> "$REPORT_FILE"
echo "2. **Implementar Anti-Corruption Layer:** Para integração entre contextos" >> "$REPORT_FILE"
echo "3. **Criar Domain Events:** Para comunicação assíncrona entre contextos" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Finalizar relatório
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Relatório gerado em:** $(date '+%d/%m/%Y %H:%M:%S')" >> "$REPORT_FILE"
echo "**Ferramenta:** Análise Estrutura DDD v1.0" >> "$REPORT_FILE"

echo -e "${GREEN}✅ Relatório gerado: ${REPORT_FILE}${NC}"
echo -e "${BLUE}📋 Resumo da análise:${NC}"
echo -e "  - Domínio: ${DOMINIO_COUNT} classes"
echo -e "  - Aplicação: ${APLICACAO_COUNT} classes"
echo -e "  - Infraestrutura: ${INFRA_COUNT} classes"
echo -e "  - Configuração: ${CONFIG_COUNT} classes"
echo -e "  - DTOs: ${DTO_COUNT} classes"
echo ""
echo -e "${YELLOW}⚠️  Violações DDD encontradas: $((DOMAIN_INFRA_VIOLATIONS + DOMAIN_CONFIG_VIOLATIONS))${NC}"
echo ""
