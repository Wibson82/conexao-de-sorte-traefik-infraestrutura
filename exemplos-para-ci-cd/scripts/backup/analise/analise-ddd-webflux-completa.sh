#!/bin/bash

# Script de Análise Completa DDD + WebFlux
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
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RELATORIO="$REPORT_DIR/analise-ddd-webflux-$TIMESTAMP.md"

echo -e "${CYAN}🔍 ANÁLISE COMPLETA DDD + WEBFLUX${NC}"
echo -e "${CYAN}==================================${NC}"
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

# Inicializar relatório
cat > "$RELATORIO" << EOF
# 🔍 ANÁLISE COMPLETA DDD + WEBFLUX

**Data:** $(date '+%Y-%m-%d %H:%M:%S')  
**Projeto:** Conexão de Sorte Backend  
**Foco:** Conformidade DDD, WebFlux, SOLID e Boas Práticas

---

## 📊 RESUMO EXECUTIVO

EOF

# 1. ANÁLISE DE ENTIDADES JPA
log "1️⃣ Analisando entidades JPA..."

TOTAL_ENTIDADES=$(find "$PROJECT_ROOT/src" -name "*.java" -exec grep -l "@Entity" {} \; | wc -l)
ENTIDADES_ANEMICAS=0
ENTIDADES_GRANDES=0
ENTIDADES_SEM_VALIDACAO=0

echo "### 🏗️ ANÁLISE DE ENTIDADES JPA" >> "$RELATORIO"
echo "" >> "$RELATORIO"
echo "**Total de entidades encontradas:** $TOTAL_ENTIDADES" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# Analisar cada entidade
while IFS= read -r -d '' arquivo; do
    if grep -q "@Entity" "$arquivo"; then
        nome_classe=$(basename "$arquivo" .java)
        linhas=$(wc -l < "$arquivo")
        
        # Verificar se é anêmica (só getters/setters)
        metodos_negocio=$(grep -c "public.*[^g][^e][^t].*(" "$arquivo" 2>/dev/null || echo 0)
        if [[ $metodos_negocio -lt 3 ]]; then
            ENTIDADES_ANEMICAS=$((ENTIDADES_ANEMICAS + 1))
            echo "⚠️ **$nome_classe** - Entidade anêmica (apenas $metodos_negocio métodos de negócio)" >> "$RELATORIO"
        fi
        
        # Verificar se é muito grande
        if [[ $linhas -gt 300 ]]; then
            ENTIDADES_GRANDES=$((ENTIDADES_GRANDES + 1))
            echo "📏 **$nome_classe** - Entidade muito grande ($linhas linhas)" >> "$RELATORIO"
        fi
        
        # Verificar validações
        if ! grep -q "@Valid\|@NotNull\|@NotEmpty\|@Size" "$arquivo"; then
            ENTIDADES_SEM_VALIDACAO=$((ENTIDADES_SEM_VALIDACAO + 1))
            echo "🚫 **$nome_classe** - Sem validações Bean Validation" >> "$RELATORIO"
        fi
    fi
done < <(find "$PROJECT_ROOT/src" -name "*.java" -print0)

echo "" >> "$RELATORIO"
echo "**Problemas identificados:**" >> "$RELATORIO"
echo "- Entidades anêmicas: $ENTIDADES_ANEMICAS" >> "$RELATORIO"
echo "- Entidades muito grandes: $ENTIDADES_GRANDES" >> "$RELATORIO"
echo "- Entidades sem validação: $ENTIDADES_SEM_VALIDACAO" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# 2. ANÁLISE DE REPOSITÓRIOS
log "2️⃣ Analisando repositórios..."

TOTAL_REPOSITORIOS=$(find "$PROJECT_ROOT/src" -name "*Repository*.java" -o -name "*Repositorio*.java" | wc -l)
REPOSITORIOS_GRANDES=0
REPOSITORIOS_COM_LOGICA=0
REPOSITORIOS_NAO_REATIVOS=0

echo "### 🗄️ ANÁLISE DE REPOSITÓRIOS" >> "$RELATORIO"
echo "" >> "$RELATORIO"
echo "**Total de repositórios encontrados:** $TOTAL_REPOSITORIOS" >> "$RELATORIO"
echo "" >> "$RELATORIO"

while IFS= read -r arquivo; do
    nome_classe=$(basename "$arquivo" .java)
    linhas=$(wc -l < "$arquivo")
    
    # Verificar se é muito grande
    if [[ $linhas -gt 200 ]]; then
        REPOSITORIOS_GRANDES=$((REPOSITORIOS_GRANDES + 1))
        echo "📏 **$nome_classe** - Repositório muito grande ($linhas linhas)" >> "$RELATORIO"
    fi
    
    # Verificar se tem lógica de negócio
    if grep -q "if.*then\|for.*do\|while.*do" "$arquivo"; then
        REPOSITORIOS_COM_LOGICA=$((REPOSITORIOS_COM_LOGICA + 1))
        echo "🧠 **$nome_classe** - Contém lógica de negócio (deveria estar em Service)" >> "$RELATORIO"
    fi
    
    # Verificar se não é reativo
    if ! grep -q "Mono\|Flux\|Reactive" "$arquivo"; then
        REPOSITORIOS_NAO_REATIVOS=$((REPOSITORIOS_NAO_REATIVOS + 1))
        echo "⚡ **$nome_classe** - Não é reativo (incompatível com WebFlux)" >> "$RELATORIO"
    fi
    
done < <(find "$PROJECT_ROOT/src" -name "*Repository*.java" -o -name "*Repositorio*.java")

echo "" >> "$RELATORIO"
echo "**Problemas identificados:**" >> "$RELATORIO"
echo "- Repositórios muito grandes: $REPOSITORIOS_GRANDES" >> "$RELATORIO"
echo "- Repositórios com lógica de negócio: $REPOSITORIOS_COM_LOGICA" >> "$RELATORIO"
echo "- Repositórios não reativos: $REPOSITORIOS_NAO_REATIVOS" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# 3. ANÁLISE DE SERVICES
log "3️⃣ Analisando services..."

TOTAL_SERVICES=$(find "$PROJECT_ROOT/src" -name "*Service*.java" -o -name "*Servico*.java" | wc -l)
SERVICES_GRANDES=0
SERVICES_COMPLEXOS=0
SERVICES_NAO_REATIVOS=0

echo "### ⚙️ ANÁLISE DE SERVICES" >> "$RELATORIO"
echo "" >> "$RELATORIO"
echo "**Total de services encontrados:** $TOTAL_SERVICES" >> "$RELATORIO"
echo "" >> "$RELATORIO"

while IFS= read -r arquivo; do
    nome_classe=$(basename "$arquivo" .java)
    linhas=$(wc -l < "$arquivo")
    metodos=$(grep -c "public.*(" "$arquivo" 2>/dev/null || echo 0)
    
    # Verificar se é muito grande
    if [[ $linhas -gt 500 ]]; then
        SERVICES_GRANDES=$((SERVICES_GRANDES + 1))
        echo "📏 **$nome_classe** - Service muito grande ($linhas linhas)" >> "$RELATORIO"
    fi
    
    # Verificar se é muito complexo
    if [[ $metodos -gt 15 ]]; then
        SERVICES_COMPLEXOS=$((SERVICES_COMPLEXOS + 1))
        echo "🧠 **$nome_classe** - Service muito complexo ($metodos métodos)" >> "$RELATORIO"
    fi
    
    # Verificar se não é reativo
    if ! grep -q "Mono\|Flux\|Reactive" "$arquivo"; then
        SERVICES_NAO_REATIVOS=$((SERVICES_NAO_REATIVOS + 1))
        echo "⚡ **$nome_classe** - Não é reativo (incompatível com WebFlux)" >> "$RELATORIO"
    fi
    
done < <(find "$PROJECT_ROOT/src" -name "*Service*.java" -o -name "*Servico*.java")

echo "" >> "$RELATORIO"
echo "**Problemas identificados:**" >> "$RELATORIO"
echo "- Services muito grandes: $SERVICES_GRANDES" >> "$RELATORIO"
echo "- Services muito complexos: $SERVICES_COMPLEXOS" >> "$RELATORIO"
echo "- Services não reativos: $SERVICES_NAO_REATIVOS" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# 4. ANÁLISE DE CONTROLADORES
log "4️⃣ Analisando controladores..."

TOTAL_CONTROLLERS=$(find "$PROJECT_ROOT/src" -name "*Controller*.java" -o -name "*Controlador*.java" | wc -l)
CONTROLLERS_MVC=0
CONTROLLERS_WEBFLUX=0
CONTROLLERS_MISTOS=0

echo "### 🎮 ANÁLISE DE CONTROLADORES" >> "$RELATORIO"
echo "" >> "$RELATORIO"
echo "**Total de controladores encontrados:** $TOTAL_CONTROLLERS" >> "$RELATORIO"
echo "" >> "$RELATORIO"

while IFS= read -r arquivo; do
    nome_classe=$(basename "$arquivo" .java)
    
    tem_mvc=$(grep -c "ResponseEntity\|@RequestMapping\|@GetMapping\|@PostMapping" "$arquivo" 2>/dev/null || echo 0)
    tem_webflux=$(grep -c "Mono\|Flux\|ServerRequest\|ServerResponse" "$arquivo" 2>/dev/null || echo 0)
    
    if [[ $tem_mvc -gt 0 && $tem_webflux -eq 0 ]]; then
        CONTROLLERS_MVC=$((CONTROLLERS_MVC + 1))
        echo "🔄 **$nome_classe** - Controlador MVC (deveria ser WebFlux)" >> "$RELATORIO"
    elif [[ $tem_webflux -gt 0 && $tem_mvc -eq 0 ]]; then
        CONTROLLERS_WEBFLUX=$((CONTROLLERS_WEBFLUX + 1))
        echo "✅ **$nome_classe** - Controlador WebFlux" >> "$RELATORIO"
    elif [[ $tem_mvc -gt 0 && $tem_webflux -gt 0 ]]; then
        CONTROLLERS_MISTOS=$((CONTROLLERS_MISTOS + 1))
        echo "⚠️ **$nome_classe** - Controlador misto (MVC + WebFlux)" >> "$RELATORIO"
    fi
    
done < <(find "$PROJECT_ROOT/src" -name "*Controller*.java" -o -name "*Controlador*.java")

echo "" >> "$RELATORIO"
echo "**Distribuição:**" >> "$RELATORIO"
echo "- Controladores MVC: $CONTROLLERS_MVC" >> "$RELATORIO"
echo "- Controladores WebFlux: $CONTROLLERS_WEBFLUX" >> "$RELATORIO"
echo "- Controladores mistos: $CONTROLLERS_MISTOS" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# 5. ANÁLISE DE ESTRUTURA DE PACOTES
log "5️⃣ Analisando estrutura de pacotes..."

echo "### 📦 ANÁLISE DE ESTRUTURA DE PACOTES" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# Verificar se segue DDD
PACOTES_DOMINIO=$(find "$PROJECT_ROOT/src" -type d -name "dominio" | wc -l)
PACOTES_APLICACAO=$(find "$PROJECT_ROOT/src" -type d -name "aplicacao" | wc -l)
PACOTES_INFRAESTRUTURA=$(find "$PROJECT_ROOT/src" -type d -name "infraestrutura" | wc -l)

echo "**Estrutura DDD:**" >> "$RELATORIO"
echo "- Pacotes 'dominio': $PACOTES_DOMINIO" >> "$RELATORIO"
echo "- Pacotes 'aplicacao': $PACOTES_APLICACAO" >> "$RELATORIO"
echo "- Pacotes 'infraestrutura': $PACOTES_INFRAESTRUTURA" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# Verificar violações de dependência
VIOLACOES_DEPENDENCIA=0

# Domínio não deve depender de infraestrutura
if find "$PROJECT_ROOT/src" -path "*/dominio/*" -name "*.java" -exec grep -l "import.*infraestrutura" {} \; | head -1 > /dev/null; then
    VIOLACOES_DEPENDENCIA=$((VIOLACOES_DEPENDENCIA + 1))
    echo "❌ **Violação:** Domínio depende de Infraestrutura" >> "$RELATORIO"
fi

# Domínio não deve depender de Spring
if find "$PROJECT_ROOT/src" -path "*/dominio/*" -name "*.java" -exec grep -l "import org.springframework" {} \; | head -1 > /dev/null; then
    VIOLACOES_DEPENDENCIA=$((VIOLACOES_DEPENDENCIA + 1))
    echo "❌ **Violação:** Domínio depende do Spring Framework" >> "$RELATORIO"
fi

echo "" >> "$RELATORIO"
echo "**Violações de dependência:** $VIOLACOES_DEPENDENCIA" >> "$RELATORIO"
echo "" >> "$RELATORIO"

# 6. RESUMO E RECOMENDAÇÕES
log "6️⃣ Gerando resumo e recomendações..."

TOTAL_PROBLEMAS=$((ENTIDADES_ANEMICAS + ENTIDADES_GRANDES + REPOSITORIOS_GRANDES + REPOSITORIOS_COM_LOGICA + SERVICES_GRANDES + SERVICES_COMPLEXOS + CONTROLLERS_MVC + VIOLACOES_DEPENDENCIA))

cat >> "$RELATORIO" << EOF

---

## 🎯 RESUMO GERAL

**Total de problemas identificados:** $TOTAL_PROBLEMAS

### 🔥 Problemas Críticos (Prioridade Alta)
- Entidades anêmicas: $ENTIDADES_ANEMICAS
- Repositórios com lógica de negócio: $REPOSITORIOS_COM_LOGICA
- Controladores MVC: $CONTROLLERS_MVC
- Violações de dependência DDD: $VIOLACOES_DEPENDENCIA

### ⚠️ Problemas Importantes (Prioridade Média)
- Entidades muito grandes: $ENTIDADES_GRANDES
- Services muito complexos: $SERVICES_COMPLEXOS
- Repositórios não reativos: $REPOSITORIOS_NAO_REATIVOS

### 📋 Melhorias (Prioridade Baixa)
- Services muito grandes: $SERVICES_GRANDES
- Entidades sem validação: $ENTIDADES_SEM_VALIDACAO
- Controladores mistos: $CONTROLLERS_MISTOS

---

## 🛠️ PLANO DE AÇÃO RECOMENDADO

### 🔥 Fase 1: Correções Críticas (1-2 semanas)
1. **Migrar controladores MVC para WebFlux**
   - Substituir ResponseEntity por Mono/Flux
   - Usar @RestController com tipos reativos
   
2. **Remover lógica de negócio dos repositórios**
   - Mover lógica complexa para Services
   - Manter repositórios apenas com queries
   
3. **Corrigir violações de dependência DDD**
   - Domínio não deve importar infraestrutura
   - Usar inversão de dependência

### ⚠️ Fase 2: Melhorias Importantes (2-4 semanas)
1. **Refatorar entidades anêmicas**
   - Adicionar métodos de negócio
   - Implementar invariantes
   
2. **Dividir services complexos**
   - Aplicar Single Responsibility Principle
   - Criar services especializados
   
3. **Implementar repositórios reativos**
   - Criar adapters reativos
   - Isolar JPA da camada de domínio

### 📋 Fase 3: Otimizações (1-2 meses)
1. **Refatorar classes muito grandes**
   - Dividir responsabilidades
   - Aplicar padrões de design
   
2. **Implementar validações**
   - Bean Validation nas entidades
   - Validações de domínio
   
3. **Padronizar arquitetura**
   - Value Objects
   - Domain Events
   - CQRS pattern

---

**Relatório gerado em:** $(date)
**Arquivo:** $RELATORIO
EOF

success "Análise concluída! Relatório salvo em: $RELATORIO"

# Exibir resumo no terminal
echo ""
echo -e "${PURPLE}📊 RESUMO DA ANÁLISE:${NC}"
echo -e "   🏗️ Entidades anêmicas: $ENTIDADES_ANEMICAS"
echo -e "   🗄️ Repositórios com lógica: $REPOSITORIOS_COM_LOGICA"
echo -e "   ⚙️ Services complexos: $SERVICES_COMPLEXOS"
echo -e "   🎮 Controladores MVC: $CONTROLLERS_MVC"
echo -e "   📦 Violações DDD: $VIOLACOES_DEPENDENCIA"
echo -e "   📄 Relatório: $RELATORIO"
echo ""

if [[ $TOTAL_PROBLEMAS -eq 0 ]]; then
    success "🎉 Projeto em conformidade com DDD + WebFlux!"
    exit 0
else
    warn "⚠️ $TOTAL_PROBLEMAS problemas identificados. Consulte o relatório para detalhes."
    exit 1
fi
