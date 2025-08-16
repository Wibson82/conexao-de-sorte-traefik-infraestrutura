#!/bin/bash

# ========================================
# SCRIPT DE ANÁLISE COMPLETA DO PROJETO
# Conexão de Sorte - Mapeamento e Auditoria DDD
# ========================================

set -euo pipefail

# Configurações
PROJETO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELATORIO_DIR="$PROJETO_ROOT/docs/analise"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RELATORIO_ARQUIVO="$RELATORIO_DIR/mapeamento-completo-$TIMESTAMP.md"

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

# Criar diretório de relatórios
mkdir -p "$RELATORIO_DIR"

# Inicializar relatório
cat > "$RELATORIO_ARQUIVO" << 'EOF'
# 🔍 ANÁLISE COMPLETA DO PROJETO CONEXÃO DE SORTE

**Data da Análise:** $(date)  
**Versão:** 1.0  
**Objetivo:** Mapeamento completo, identificação de redundâncias, conflitos e oportunidades de melhoria DDD/SOLID

---

## 📊 RESUMO EXECUTIVO

### Estatísticas Gerais
EOF

log "🚀 Iniciando análise completa do projeto..."

# ========================================
# 1. ANÁLISE ESTRUTURAL
# ========================================

log "📁 Analisando estrutura de pacotes..."

# Contar arquivos por tipo
JAVA_FILES=$(find "$PROJETO_ROOT/src" -name "*.java" | wc -l)
CONFIG_FILES=$(find "$PROJETO_ROOT/src" -name "*.yml" -o -name "*.yaml" -o -name "*.properties" | wc -l)
TEST_FILES=$(find "$PROJETO_ROOT/src/test" -name "*.java" 2>/dev/null | wc -l || echo "0")

# Análise de pacotes
PACKAGES=$(find "$PROJETO_ROOT/src/main/java" -type d | grep -v "\.java$" | wc -l)
CONTROLLERS=$(find "$PROJETO_ROOT/src" -name "*Controller*.java" | wc -l)
SERVICES=$(find "$PROJETO_ROOT/src" -name "*Service*.java" -o -name "*Servico*.java" | wc -l)
REPOSITORIES=$(find "$PROJETO_ROOT/src" -name "*Repository*.java" -o -name "*Repositorio*.java" | wc -l)
ENTITIES=$(find "$PROJETO_ROOT/src" -name "*Entity*.java" -o -path "*/entidade/*" -name "*.java" | wc -l)
DTOS=$(find "$PROJETO_ROOT/src" -path "*/dto/*" -name "*.java" | wc -l)

# Adicionar estatísticas ao relatório
cat >> "$RELATORIO_ARQUIVO" << EOF

- **Total de arquivos Java:** $JAVA_FILES
- **Arquivos de configuração:** $CONFIG_FILES  
- **Arquivos de teste:** $TEST_FILES
- **Total de pacotes:** $PACKAGES
- **Controllers:** $CONTROLLERS
- **Services:** $SERVICES
- **Repositories:** $REPOSITORIES
- **Entities:** $ENTITIES
- **DTOs:** $DTOS

---

## 🏗️ MAPEAMENTO ARQUITETURAL

### Estrutura de Pacotes Atual
\`\`\`
EOF

# Gerar árvore de estrutura
tree "$PROJETO_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte" -d -L 3 >> "$RELATORIO_ARQUIVO" 2>/dev/null || {
    find "$PROJETO_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte" -type d | head -50 | sed 's|.*/||' >> "$RELATORIO_ARQUIVO"
}

cat >> "$RELATORIO_ARQUIVO" << 'EOF'
```

### Bounded Contexts Identificados
EOF

# ========================================
# 2. ANÁLISE DE BOUNDED CONTEXTS
# ========================================

log "🎯 Mapeando Bounded Contexts..."

# Identificar contextos pelos pacotes
CONTEXTOS=(
    "aplicacao/autenticacao:👤 Contexto de Autenticação"
    "aplicacao/batepapo:💬 Contexto de Bate-Papo"
    "aplicacao/loteria:🎲 Contexto de Loteria"
    "aplicacao/transacao:💰 Contexto de Transação"
    "aplicacao/monitoramento:📊 Contexto de Monitoramento"
    "aplicacao/seguranca:🔒 Contexto de Segurança"
    "aplicacao/privacidade:🛡️ Contexto de Privacidade"
)

for contexto in "${CONTEXTOS[@]}"; do
    IFS=':' read -r pacote nome <<< "$contexto"
    CAMINHO="$PROJETO_ROOT/src/main/java/br/tec/facilitaservicos/conexaodesorte/$pacote"
    
    if [ -d "$CAMINHO" ]; then
        CLASSES=$(find "$CAMINHO" -name "*.java" | wc -l)
        cat >> "$RELATORIO_ARQUIVO" << EOF

#### $nome
- **Pacote:** \`$pacote\`
- **Classes:** $CLASSES
- **Status:** ✅ Identificado
EOF
        
        # Listar principais classes
        if [ $CLASSES -gt 0 ]; then
            echo "- **Principais Classes:**" >> "$RELATORIO_ARQUIVO"
            find "$CAMINHO" -name "*.java" -exec basename {} .java \; | head -5 | sed 's/^/  - /' >> "$RELATORIO_ARQUIVO"
        fi
    fi
done

# ========================================
# 3. ANÁLISE DE VIOLAÇÕES DDD
# ========================================

log "🔍 Identificando violações DDD..."

cat >> "$RELATORIO_ARQUIVO" << 'EOF'

---

## ⚠️ VIOLAÇÕES E PROBLEMAS IDENTIFICADOS

### Violações de DDD
EOF

# Buscar por violações comuns
VIOLACOES_ENCONTRADAS=0

# 1. Entidades anêmicas (getters/setters sem lógica)
log "   Verificando entidades anêmicas..."
ENTIDADES_ANEMICAS=$(find "$PROJETO_ROOT/src" -path "*/entidade/*" -name "*.java" -exec grep -l "public.*get\|public.*set" {} \; | wc -l)
if [ $ENTIDADES_ANEMICAS -gt 0 ]; then
    cat >> "$RELATORIO_ARQUIVO" << EOF

#### 🚨 Entidades Anêmicas Detectadas
- **Quantidade:** $ENTIDADES_ANEMICAS entidades
- **Problema:** Entidades com apenas getters/setters, sem lógica de domínio
- **Impacto:** Violação do princípio de encapsulamento do DDD
EOF
    VIOLACOES_ENCONTRADAS=$((VIOLACOES_ENCONTRADAS + 1))
fi

# 2. Services com lógica de domínio
log "   Verificando services com lógica de domínio..."
SERVICES_DOMINIO=$(find "$PROJETO_ROOT/src" -path "*/servico/*" -name "*.java" -exec grep -l "@Entity\|@Table" {} \; | wc -l)
if [ $SERVICES_DOMINIO -gt 0 ]; then
    cat >> "$RELATORIO_ARQUIVO" << EOF

#### 🚨 Services com Lógica de Domínio
- **Quantidade:** $SERVICES_DOMINIO services
- **Problema:** Lógica de domínio em services de aplicação
- **Impacto:** Violação da separação de responsabilidades
EOF
    VIOLACOES_ENCONTRADAS=$((VIOLACOES_ENCONTRADAS + 1))
fi

# 3. DTOs sendo usados como entidades
log "   Verificando uso incorreto de DTOs..."
DTOS_COMO_ENTIDADES=$(find "$PROJETO_ROOT/src" -path "*/dto/*" -name "*.java" -exec grep -l "@Entity\|@Table\|@Id" {} \; | wc -l)
if [ $DTOS_COMO_ENTIDADES -gt 0 ]; then
    cat >> "$RELATORIO_ARQUIVO" << EOF

#### 🚨 DTOs Usados como Entidades
- **Quantidade:** $DTOS_COMO_ENTIDADES DTOs
- **Problema:** DTOs com anotações JPA
- **Impacto:** Confusão entre camadas de apresentação e domínio
EOF
    VIOLACOES_ENCONTRADAS=$((VIOLACOES_ENCONTRADAS + 1))
fi

# ========================================
# 4. ANÁLISE DE REDUNDÂNCIAS
# ========================================

log "🔄 Identificando redundâncias..."

cat >> "$RELATORIO_ARQUIVO" << 'EOF'

### Redundâncias Identificadas
EOF

# Buscar classes duplicadas ou similares
log "   Verificando classes duplicadas..."
CLASSES_DUPLICADAS=$(find "$PROJETO_ROOT/src" -name "*.java" -exec basename {} .java \; | sort | uniq -d | wc -l)
if [ $CLASSES_DUPLICADAS -gt 0 ]; then
    cat >> "$RELATORIO_ARQUIVO" << EOF

#### 🔄 Classes com Nomes Duplicados
- **Quantidade:** $CLASSES_DUPLICADAS classes
- **Problema:** Possível duplicação de funcionalidade
EOF
    
    # Listar algumas duplicatas
    echo "- **Exemplos:**" >> "$RELATORIO_ARQUIVO"
    find "$PROJETO_ROOT/src" -name "*.java" -exec basename {} .java \; | sort | uniq -d | head -5 | sed 's/^/  - /' >> "$RELATORIO_ARQUIVO"
fi

# Buscar constantes duplicadas
log "   Verificando constantes duplicadas..."
CONSTANTES_DUPLICADAS=$(find "$PROJETO_ROOT/src" -path "*/constantes/*" -name "*.java" | wc -l)
cat >> "$RELATORIO_ARQUIVO" << EOF

#### 📋 Análise de Constantes
- **Arquivos de constantes:** $CONSTANTES_DUPLICADAS
- **Recomendação:** Consolidar em classes temáticas
EOF

info "✅ Análise estrutural concluída. Relatório salvo em: $RELATORIO_ARQUIVO"

# ========================================
# 5. FINALIZAÇÃO
# ========================================

cat >> "$RELATORIO_ARQUIVO" << 'EOF'

---

## 📋 PRÓXIMOS PASSOS RECOMENDADOS

### 🔥 Prioridade Alta (1-2 semanas)
- [ ] Implementar Adapters Reativos - Isolar JPA em boundaries assíncronos
- [ ] Corrigir Violações de Arquitetura - Separar Entity/Domain Object  
- [ ] Remover EnderecoDTO - Usar Endereco diretamente

### 🔧 Prioridade Média (2-4 semanas)
- [ ] Implementar Value Objects - CPF, Email, Telefone
- [ ] Configurar Domain Events - Infraestrutura completa
- [ ] Melhorar Invariants - Validações de domínio

### 🚀 Prioridade Baixa (1-2 meses)
- [ ] Implementar ArchUnit - Validação automática de regras
- [ ] CQRS Pattern - Separar comandos de consultas
- [ ] Avaliar R2DBC - Migração gradual para reatividade total

---

**Relatório gerado automaticamente em:** $(date)
EOF

echo ""
log "🎉 Análise completa finalizada!"
info "📄 Relatório disponível em: $RELATORIO_ARQUIVO"
info "🔍 Total de violações encontradas: $VIOLACOES_ENCONTRADAS"

# Exibir resumo no terminal
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}           RESUMO DA ANÁLISE${NC}"
echo -e "${PURPLE}========================================${NC}"
echo -e "${CYAN}📊 Arquivos Java:${NC} $JAVA_FILES"
echo -e "${CYAN}🏗️  Controllers:${NC} $CONTROLLERS"
echo -e "${CYAN}⚙️  Services:${NC} $SERVICES"
echo -e "${CYAN}🗄️  Repositories:${NC} $REPOSITORIES"
echo -e "${CYAN}📦 Entities:${NC} $ENTITIES"
echo -e "${CYAN}📋 DTOs:${NC} $DTOS"
echo -e "${RED}⚠️  Violações:${NC} $VIOLACOES_ENCONTRADAS"
echo -e "${PURPLE}========================================${NC}"
