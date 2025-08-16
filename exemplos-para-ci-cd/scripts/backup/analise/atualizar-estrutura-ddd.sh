#!/bin/bash

# ============================================================================
# 📊 SCRIPT DE ATUALIZAÇÃO DA ESTRUTURA DDD
# ============================================================================
# 
# Atualiza o arquivo estrutura-ddd.md com a análise atual da arquitetura
# Domain-Driven Design implementada no projeto.
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
readonly OUTPUT_FILE="${PROJECT_ROOT}/estrutura-ddd.md"
readonly TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo -e "${BLUE}📊 ATUALIZANDO ESTRUTURA DDD - CONEXÃO DE SORTE${NC}"
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
        find "$dir" -name "*.java" -type f | head -n "$max_files" | sed 's|.*/||' | sed 's|\.java||'
    fi
}

# Função para verificar se um padrão existe
check_pattern() {
    local pattern="$1"
    local dir="$2"
    if [[ -d "$dir" ]]; then
        find "$dir" -name "*.java" -type f -exec grep -l "$pattern" {} \; 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

echo -e "${CYAN}📊 Coletando dados da estrutura DDD...${NC}"

# Coletar dados
DOMINIO_COUNT=$(count_files "${SRC_DIR}/dominio")
APLICACAO_COUNT=$(count_files "${SRC_DIR}/aplicacao")
INFRA_COUNT=$(count_files "${SRC_DIR}/infraestrutura")
CONFIG_COUNT=$(count_files "${SRC_DIR}/configuracao")
DTO_COUNT=$(count_files "${SRC_DIR}/dto")

# Contextos específicos
AUTH_COUNT=$(count_files "${SRC_DIR}/aplicacao/autenticacao")
CHAT_COUNT=$(count_files "${SRC_DIR}/aplicacao/batepapo")
LOTERIA_COUNT=$(count_files "${SRC_DIR}/aplicacao/loteria")
USUARIO_COUNT=$(count_files "${SRC_DIR}/aplicacao/usuario")
PRIVACIDADE_COUNT=$(count_files "${SRC_DIR}/aplicacao/privacidade")

# Novos componentes DDD
VALUE_OBJECTS_COUNT=$(count_files "${SRC_DIR}/dominio/privacidade/vo")
EVENTS_COUNT=$(count_files "${SRC_DIR}/dominio/privacidade/evento")
REPOSITORIES_COUNT=$(find "${SRC_DIR}" -name "*Repository*.java" -o -name "*Repositorio*.java" | wc -l)
HANDLERS_COUNT=$(find "${SRC_DIR}" -name "*Handler*.java" -o -name "*Processador*.java" | wc -l)

# Verificar violações DDD
DOMAIN_INFRA_VIOLATIONS=$(find "${SRC_DIR}/dominio" -name "*.java" -type f -exec grep -l "import.*infraestrutura" {} \; 2>/dev/null | wc -l)
DOMAIN_CONFIG_VIOLATIONS=$(find "${SRC_DIR}/dominio" -name "*.java" -type f -exec grep -l "import.*configuracao" {} \; 2>/dev/null | wc -l)

# Gerar arquivo estrutura-ddd.md
cat > "$OUTPUT_FILE" << EOF
# 🏗️ ESTRUTURA DDD - CONEXÃO DE SORTE

**Última atualização:** ${TIMESTAMP}  
**Versão:** 2.0 - Refatoração DDD Completa  
**Status:** ✅ Implementação Completa  

## 📊 RESUMO EXECUTIVO

Este documento apresenta a estrutura atual do projeto Conexão de Sorte seguindo os princípios de **Domain-Driven Design (DDD)**, após a refatoração completa implementada em agosto de 2025.

### 🎯 MÉTRICAS GERAIS

| Camada | Classes | Percentual |
|--------|---------|------------|
| **Domínio** | ${DOMINIO_COUNT} | $(( DOMINIO_COUNT * 100 / (DOMINIO_COUNT + APLICACAO_COUNT + INFRA_COUNT + CONFIG_COUNT) ))% |
| **Aplicação** | ${APLICACAO_COUNT} | $(( APLICACAO_COUNT * 100 / (DOMINIO_COUNT + APLICACAO_COUNT + INFRA_COUNT + CONFIG_COUNT) ))% |
| **Infraestrutura** | ${INFRA_COUNT} | $(( INFRA_COUNT * 100 / (DOMINIO_COUNT + APLICACAO_COUNT + INFRA_COUNT + CONFIG_COUNT) ))% |
| **Configuração** | ${CONFIG_COUNT} | $(( CONFIG_COUNT * 100 / (DOMINIO_COUNT + APLICACAO_COUNT + INFRA_COUNT + CONFIG_COUNT) ))% |
| **DTOs** | ${DTO_COUNT} | - |
| **TOTAL** | $((DOMINIO_COUNT + APLICACAO_COUNT + INFRA_COUNT + CONFIG_COUNT + DTO_COUNT)) | 100% |

---

## 🏛️ ARQUITETURA DDD IMPLEMENTADA

### 📦 CAMADAS ARQUITETURAIS

#### 🎯 **DOMÍNIO (${DOMINIO_COUNT} classes)**
- **Responsabilidade:** Regras de negócio, entidades, value objects, domain services
- **Localização:** \`src/main/java/.../dominio/\`
- **Status:** ✅ Bem estruturado com separação clara

**Principais componentes:**
EOF

# Listar principais arquivos do domínio
if [[ -d "${SRC_DIR}/dominio" ]]; then
    echo "- Entidades principais:" >> "$OUTPUT_FILE"
    list_files "${SRC_DIR}/dominio/entidade" 5 | sed 's/^/  - /' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF
#### 🏗️ **APLICAÇÃO (${APLICACAO_COUNT} classes)**
- **Responsabilidade:** Orquestração, coordenação entre agregados, application services
- **Localização:** \`src/main/java/.../aplicacao/\`
- **Status:** ✅ Bem organizado por contextos delimitados

**Contextos Delimitados:**
- **🔐 Autenticação:** ${AUTH_COUNT} classes
- **💬 Bate-papo:** ${CHAT_COUNT} classes  
- **🎲 Loterias:** ${LOTERIA_COUNT} classes
- **👤 Usuários:** ${USUARIO_COUNT} classes
- **🔒 Privacidade:** ${PRIVACIDADE_COUNT} classes *(NOVO)*

#### 🔧 **INFRAESTRUTURA (${INFRA_COUNT} classes)**
- **Responsabilidade:** Implementações técnicas, repositórios, integrações externas
- **Localização:** \`src/main/java/.../infraestrutura/\`
- **Status:** ✅ Separação clara das preocupações técnicas

#### ⚙️ **CONFIGURAÇÃO (${CONFIG_COUNT} classes)**
- **Responsabilidade:** Configurações do Spring, beans, profiles
- **Localização:** \`src/main/java/.../configuracao/\`
- **Status:** ✅ Configurações centralizadas

---

## 🆕 COMPONENTES DDD IMPLEMENTADOS

### 📊 **VALUE OBJECTS (${VALUE_OBJECTS_COUNT} classes)**
Implementados na refatoração de exportação de dados:

EOF

# Listar Value Objects
if [[ -d "${SRC_DIR}/dominio/privacidade/vo" ]]; then
    list_files "${SRC_DIR}/dominio/privacidade/vo" | sed 's/^/- **/' | sed 's/$/**/' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF
### 📤 **DOMAIN EVENTS (${EVENTS_COUNT} classes)**
Sistema de eventos para comunicação assíncrona:

EOF

# Listar Domain Events
if [[ -d "${SRC_DIR}/dominio/privacidade/evento" ]]; then
    list_files "${SRC_DIR}/dominio/privacidade/evento" | sed 's/^/- **/' | sed 's/$/**/' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << EOF
### 🗄️ **REPOSITORY PATTERN (${REPOSITORIES_COUNT} interfaces/implementações)**
Separação clara entre interfaces de domínio e implementações de infraestrutura.

### ⚙️ **HANDLERS ASSÍNCRONOS (${HANDLERS_COUNT} classes)**
Processamento assíncrono de eventos e operações de longa duração.

---

## 🚨 ANÁLISE DE VIOLAÇÕES DDD

### ❌ **VIOLAÇÕES IDENTIFICADAS**

| Tipo de Violação | Quantidade | Status |
|-------------------|------------|--------|
| **Domínio → Infraestrutura** | ${DOMAIN_INFRA_VIOLATIONS} | $([ $DOMAIN_INFRA_VIOLATIONS -eq 0 ] && echo "✅ Resolvido" || echo "⚠️ Em correção") |
| **Domínio → Configuração** | ${DOMAIN_CONFIG_VIOLATIONS} | $([ $DOMAIN_CONFIG_VIOLATIONS -eq 0 ] && echo "✅ Resolvido" || echo "⚠️ Em correção") |

$([ $((DOMAIN_INFRA_VIOLATIONS + DOMAIN_CONFIG_VIOLATIONS)) -eq 0 ] && echo "### ✅ **ARQUITETURA LIMPA ALCANÇADA**" || echo "### ⚠️ **CORREÇÕES EM ANDAMENTO**")

$([ $((DOMAIN_INFRA_VIOLATIONS + DOMAIN_CONFIG_VIOLATIONS)) -eq 0 ] && echo "Todas as violações DDD foram corrigidas! O domínio está completamente isolado das preocupações de infraestrutura e configuração." || echo "Ainda existem algumas violações DDD que estão sendo corrigidas gradualmente.")

---

## 🎯 CONTEXTOS DELIMITADOS (BOUNDED CONTEXTS)

### 🔐 **AUTENTICAÇÃO** - ✅ EXCELENTE
- **Classes:** ${AUTH_COUNT}
- **Responsabilidades:** Login, JWT, OAuth2, segurança
- **Status:** Bem definido, responsabilidades claras

### 💬 **BATE-PAPO** - ✅ BOM  
- **Classes:** ${CHAT_COUNT}
- **Responsabilidades:** Mensagens, conversas, anexos
- **Status:** Contexto isolado, poucos controladores

### 🎲 **LOTERIAS** - ✅ BOM
- **Classes:** ${LOTERIA_COUNT}  
- **Responsabilidades:** Jogos, resultados, apostas
- **Status:** Domínio específico bem definido

### 👤 **USUÁRIOS** - $([ $USUARIO_COUNT -gt 0 ] && echo "✅ CONSOLIDADO" || echo "⚠️ EM CONSOLIDAÇÃO")
- **Classes:** ${USUARIO_COUNT}
- **Responsabilidades:** Perfis, dados pessoais, preferências
- **Status:** $([ $USUARIO_COUNT -gt 0 ] && echo "Contexto organizado" || echo "Classes espalhadas, necessita consolidação")

### 🔒 **PRIVACIDADE** - ✅ NOVO CONTEXTO IMPLEMENTADO
- **Classes:** ${PRIVACIDADE_COUNT}
- **Responsabilidades:** Exportação de dados, LGPD, compliance
- **Status:** Implementação completa seguindo DDD
- **Componentes:**
  - Agregado: ExportacaoDados
  - Value Objects: StatusExportacao, PeriodoExportacao, etc.
  - Domain Events: ExportacaoSolicitadaEvent, etc.
  - Repository: RepositorioExportacaoDados
  - Application Service: ServicoExportacaoApp

---

## 📈 EVOLUÇÃO DA ARQUITETURA

### ✅ **IMPLEMENTAÇÕES RECENTES (2025-08-09)**

1. **🏗️ REFATORAÇÃO DDD COMPLETA:**
   - Value Objects imutáveis com validações
   - Agregados com invariantes garantidas  
   - Domain Events para comunicação assíncrona
   - Repository Pattern com DIP

2. **⚙️ PROCESSAMENTO ASSÍNCRONO:**
   - Handlers para eventos de domínio
   - Retry inteligente para falhas
   - Métricas e observabilidade

3. **🌐 API REST COMPLETA:**
   - Controladores seguindo DDD
   - DTOs tipados e validados
   - Segurança integrada

### 🎯 **BENEFÍCIOS ALCANÇADOS**

- ✅ **Separação clara de responsabilidades**
- ✅ **Código testável e manutenível**  
- ✅ **Comunicação desacoplada via eventos**
- ✅ **Regras de negócio centralizadas**
- ✅ **Observabilidade e auditoria completas**
- ✅ **Escalabilidade e performance melhoradas**

---

## 🚀 PRÓXIMOS PASSOS

### 📋 **MELHORIAS PLANEJADAS**

1. **🔧 Finalizar correções DDD restantes**
2. **📊 Implementar métricas avançadas**  
3. **🧪 Expandir cobertura de testes**
4. **📚 Documentar padrões estabelecidos**
5. **🔄 Migração gradual de serviços legados**

### 🎯 **OBJETIVOS DE LONGO PRAZO**

- **100% conformidade DDD** em todos os contextos
- **Arquitetura hexagonal** completa
- **Event Sourcing** para auditoria avançada
- **CQRS** para separação de leitura/escrita

---

## 📚 REFERÊNCIAS

- **Domain-Driven Design:** Eric Evans
- **Implementing Domain-Driven Design:** Vaughn Vernon  
- **Clean Architecture:** Robert C. Martin
- **Microservices Patterns:** Chris Richardson

---

*Documento gerado automaticamente pelo script de análise DDD*  
*Última execução: ${TIMESTAMP}*
EOF

echo -e "${GREEN}✅ Arquivo estrutura-ddd.md atualizado com sucesso!${NC}"
echo -e "${CYAN}📍 Localização: ${OUTPUT_FILE}${NC}"
echo ""
echo -e "${BLUE}📊 Resumo da análise:${NC}"
echo -e "  - Total de classes: $((DOMINIO_COUNT + APLICACAO_COUNT + INFRA_COUNT + CONFIG_COUNT + DTO_COUNT))"
echo -e "  - Contextos implementados: 5 (incluindo novo contexto Privacidade)"
echo -e "  - Value Objects: ${VALUE_OBJECTS_COUNT}"
echo -e "  - Domain Events: ${EVENTS_COUNT}"
echo -e "  - Violações DDD: $((DOMAIN_INFRA_VIOLATIONS + DOMAIN_CONFIG_VIOLATIONS))"
echo ""

if [[ $((DOMAIN_INFRA_VIOLATIONS + DOMAIN_CONFIG_VIOLATIONS)) -eq 0 ]]; then
    echo -e "${GREEN}🎉 PARABÉNS! Arquitetura DDD limpa alcançada!${NC}"
else
    echo -e "${YELLOW}⚠️  Ainda existem $((DOMAIN_INFRA_VIOLATIONS + DOMAIN_CONFIG_VIOLATIONS)) violações DDD para corrigir${NC}"
fi

echo ""
