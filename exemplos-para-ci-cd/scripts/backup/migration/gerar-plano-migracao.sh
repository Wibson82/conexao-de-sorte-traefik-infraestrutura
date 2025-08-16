#!/bin/bash

# Script para gerar plano detalhado de migração de constantes
# Baseado nas análises realizadas, cria um plano estruturado de migração

set -e

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/analysis-reports"
MIGRATION_DIR="$PROJECT_ROOT/migration-plans"
PLAN_FILE="$MIGRATION_DIR/plano-migracao-constantes-$(date +%Y%m%d-%H%M%S).md"
SOURCE_DIR="$PROJECT_ROOT/src/main/java"

# Criar diretórios se não existirem
mkdir -p "$MIGRATION_DIR"

echo "Gerando plano de migração de constantes..."

# Cabeçalho do plano
cat > "$PLAN_FILE" << 'EOF'
# Plano de Migração de Constantes

## Visão Geral

Este documento apresenta um plano detalhado para migração das constantes dispersas no código para uma estrutura consolidada e organizada.

### Objetivos
- Centralizar constantes dispersas em arquivos organizados
- Eliminar duplicação de valores
- Melhorar manutenibilidade do código
- Padronizar nomenclatura e organização
- Facilitar futuras alterações de configuração

### Estrutura de Destino

As constantes serão organizadas nos seguintes arquivos:

1. **ConstantesNumericasConsolidadas.java** - Valores numéricos
2. **ConstantesMensagensConsolidadas.java** - Mensagens do sistema
3. **ConstantesConfiguracaoConsolidadas.java** - Configurações
4. **ConstantesValidacaoConsolidadas.java** - Padrões de validação

---

## Fase 1: Migração de Alta Prioridade

### 1.1 Status HTTP (CRÍTICO)

**Problema Identificado:**
- Status HTTP hardcoded espalhados pelo código
- Inconsistência entre string e int
- Dificuldade de manutenção

**Solução:**
```java
// De:
responseCode = "200"
HttpStatus.valueOf(500)
status = 404

// Para:
ConstantesNumericasConsolidadas.StatusHTTP.OK
ConstantesNumericasConsolidadas.StatusHTTP.INTERNAL_SERVER_ERROR
ConstantesNumericasConsolidadas.StatusHTTP.NOT_FOUND
```

**Arquivos Afetados:**
- Controllers (respostas de API)
- DTOs (códigos de resposta)
- Configurações OpenAPI
- Handlers de exceção

**Estimativa:** 2-3 dias
**Risco:** Baixo
**Impacto:** Alto

### 1.2 Mensagens de Erro Frequentes (CRÍTICO)

**Problema Identificado:**
- Mensagens de erro duplicadas
- Inconsistência na linguagem
- Dificuldade para internacionalização

**Solução:**
```java
// De:
"Erro de validação"
"Erro interno do sistema"
"Acesso negado"

// Para:
ConstantesMensagensConsolidadas.Erro.ERRO_VALIDACAO
ConstantesMensagensConsolidadas.Erro.ERRO_INTERNO_SERVIDOR
ConstantesMensagensConsolidadas.Erro.ERRO_ACESSO_NEGADO
```

**Arquivos Afetados:**
- Services (logs e exceções)
- Controllers (respostas de erro)
- Validators (mensagens de validação)
- Exception handlers

**Estimativa:** 3-4 dias
**Risco:** Baixo
**Impacto:** Alto

### 1.3 Validações de Tamanho (@Size) (ALTO)

**Problema Identificado:**
- Valores hardcoded em anotações @Size
- Inconsistência entre DTOs similares
- Dificuldade para ajustar limites globalmente

**Solução:**
```java
// De:
@Size(max = 100)
@Size(max = 200)
@Size(max = 500)

// Para:
@Size(max = ConstantesNumericasConsolidadas.Tamanhos.CAMPO_CURTO)
@Size(max = ConstantesNumericasConsolidadas.Tamanhos.CAMPO_MEDIO)
@Size(max = ConstantesNumericasConsolidadas.Tamanhos.CAMPO_LONGO)
```

**Arquivos Afetados:**
- DTOs de entrada
- DTOs de resposta
- Entidades JPA
- Classes de validação

**Estimativa:** 2-3 dias
**Risco:** Médio (pode afetar validações)
**Impacto:** Alto

### 1.4 Timeouts Críticos (ALTO)

**Problema Identificado:**
- Timeouts hardcoded em configurações críticas
- Valores inconsistentes para operações similares
- Dificuldade para ajustar performance

**Solução:**
```java
// De:
timeout = 5000
connectionTimeout = 1000
readTimeout = 500

// Para:
ConstantesNumericasConsolidadas.Timeouts.PROCESSAMENTO_DADOS_MS
ConstantesNumericasConsolidadas.Timeouts.DELAY_RETRY_MS
ConstantesNumericasConsolidadas.Timeouts.VALIDACAO_URL_MS
```

**Arquivos Afetados:**
- Configurações de cliente HTTP
- Configurações de banco de dados
- Configurações de cache
- Configurações de thread pool

**Estimativa:** 2 dias
**Risco:** Alto (pode afetar performance)
**Impacto:** Alto

---

## Fase 2: Migração de Prioridade Média

### 2.1 Configurações de Cache e Thread Pool (MÉDIO)

**Problema Identificado:**
- Configurações dispersas em múltiplos arquivos
- Valores inconsistentes entre ambientes
- Dificuldade para otimização de performance

**Solução:**
```java
// De:
corePoolSize = 10
maxPoolSize = 50
queueCapacity = 100
cacheSize = 1000

// Para:
ConstantesNumericasConsolidadas.Threads.FILA_PRINCIPAL
ConstantesNumericasConsolidadas.Capacidades.CACHE_PADRAO
```

**Estimativa:** 3 dias
**Risco:** Médio
**Impacto:** Médio

### 2.2 Padrões Regex de Validação (MÉDIO)

**Problema Identificado:**
- Regex hardcoded em múltiplos locais
- Padrões similares com pequenas diferenças
- Dificuldade para manutenção e teste

**Solução:**
```java
// De:
Pattern.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
matches("^\\d{11}$")

// Para:
ConstantesValidacaoConsolidadas.Contato.EMAIL
ConstantesValidacaoConsolidadas.Documentos.CPF_NUMEROS
```

**Estimativa:** 4 dias
**Risco:** Alto (pode quebrar validações)
**Impacto:** Alto

### 2.3 URLs e Endpoints de Integração (MÉDIO)

**Problema Identificado:**
- URLs hardcoded em código
- Endpoints duplicados
- Dificuldade para mudança de ambiente

**Solução:**
```java
// De:
"https://api.exemplo.com/v1/"
"/usuarios"
"localhost:8080"

// Para:
ConstantesConfiguracaoConsolidadas.IntegracaoExterna.LOTERIA_API_BASE_URL
ConstantesConfiguracaoConsolidadas.API.PREFIX
```

**Estimativa:** 2 dias
**Risco:** Médio
**Impacto:** Médio

---

## Fase 3: Migração de Prioridade Baixa

### 3.1 Constantes Específicas de Negócio (BAIXO)

**Problema Identificado:**
- Regras de negócio hardcoded
- Valores específicos de loteria dispersos
- Configurações de domínio espalhadas

**Solução:**
```java
// De:
maxNumeroMegaSena = 60
maxDezenasLotofacil = 25

// Para:
ConstantesNumericasConsolidadas.Loteria.MEGA_SENA_MAX
ConstantesNumericasConsolidadas.Loteria.LOTOFACIL_MAX
```

**Estimativa:** 2 dias
**Risco:** Baixo
**Impacto:** Baixo

---

## Cronograma de Execução

### Semana 1: Preparação e Fase 1
- **Dia 1-2:** Status HTTP e mensagens de erro
- **Dia 3-4:** Validações de tamanho
- **Dia 5:** Timeouts críticos

### Semana 2: Fase 2
- **Dia 1-2:** Configurações de cache e thread pool
- **Dia 3-4:** Padrões regex
- **Dia 5:** URLs e endpoints

### Semana 3: Fase 3 e Finalização
- **Dia 1-2:** Constantes de negócio
- **Dia 3-4:** Testes e validação
- **Dia 5:** Documentação e cleanup

---

## Estratégia de Implementação

### Passo 1: Criar Estrutura Base
1. Criar arquivos de constantes consolidadas ✅
2. Definir estrutura de classes internas ✅
3. Documentar padrões de nomenclatura ✅

### Passo 2: Migração Incremental
1. Identificar constantes por prioridade
2. Migrar uma categoria por vez
3. Atualizar imports e referências
4. Executar testes de regressão
5. Remover constantes antigas

### Passo 3: Validação
1. Executar suite completa de testes
2. Verificar funcionalidade em ambiente de teste
3. Validar performance
4. Revisar código migrado

### Passo 4: Cleanup
1. Remover arquivos de constantes obsoletos
2. Atualizar documentação
3. Criar guias de uso
4. Treinar equipe

---

## Riscos e Mitigações

### Riscos Identificados

1. **Quebra de Funcionalidade**
   - **Risco:** Alto para validações e timeouts
   - **Mitigação:** Testes extensivos, migração incremental

2. **Impacto na Performance**
   - **Risco:** Médio para configurações de thread pool
   - **Mitigação:** Monitoramento contínuo, rollback plan

3. **Conflitos de Merge**
   - **Risco:** Médio em desenvolvimento ativo
   - **Mitigação:** Comunicação com equipe, feature flags

4. **Regressões em Validação**
   - **Risco:** Alto para mudanças em regex
   - **Mitigação:** Testes unitários específicos

### Plano de Rollback

1. **Backup de Código**
   - Criar branch específica antes da migração
   - Manter versões antigas comentadas temporariamente

2. **Monitoramento**
   - Alertas para erros de validação
   - Métricas de performance
   - Logs detalhados durante migração

3. **Rollback Rápido**
   - Scripts automatizados para reverter mudanças
   - Procedimento documentado
   - Responsáveis definidos

---

## Critérios de Sucesso

### Métricas Quantitativas
- [ ] 100% das constantes de alta prioridade migradas
- [ ] 0 testes quebrados após migração
- [ ] Redução de 80% na duplicação de constantes
- [ ] Tempo de build mantido ou melhorado

### Métricas Qualitativas
- [ ] Código mais legível e manutenível
- [ ] Facilidade para mudanças de configuração
- [ ] Melhor organização do código
- [ ] Documentação atualizada

---

## Recursos Necessários

### Equipe
- **Desenvolvedor Senior:** 2 semanas (lead da migração)
- **Desenvolvedor Pleno:** 1 semana (suporte e testes)
- **QA:** 3 dias (testes de regressão)

### Ferramentas
- IDE com refactoring avançado
- Scripts de análise de código
- Suite de testes automatizados
- Ferramentas de monitoramento

### Ambiente
- Ambiente de desenvolvimento isolado
- Ambiente de teste dedicado
- Acesso a logs e métricas

---

## Próximos Passos

1. **Aprovação do Plano**
   - Revisar com arquiteto de software
   - Validar com tech lead
   - Aprovar cronograma

2. **Preparação**
   - Configurar ambiente de desenvolvimento
   - Preparar scripts de migração
   - Definir responsabilidades

3. **Execução**
   - Iniciar Fase 1 conforme cronograma
   - Monitorar progresso diariamente
   - Ajustar plano conforme necessário

4. **Acompanhamento**
   - Reuniões diárias de status
   - Relatórios de progresso
   - Documentação de lições aprendidas

---

## Anexos

### A. Lista Completa de Arquivos Afetados
(Será preenchida durante a execução)

### B. Scripts de Migração
(Serão desenvolvidos durante a implementação)

### C. Casos de Teste
(Serão criados para validar cada migração)

### D. Documentação de API
(Será atualizada após migração)

---

**Documento gerado em:** $(date)
**Versão:** 1.0
**Responsável:** Sistema de Consolidação de Constantes
EOF

# Adicionar informações específicas baseadas nas análises
echo "" >> "$PLAN_FILE"
echo "## Análises Realizadas" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"
echo "Este plano foi baseado nas seguintes análises:" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

# Listar relatórios de análise disponíveis
if [ -d "$REPORT_DIR" ]; then
    echo "### Relatórios de Análise Disponíveis" >> "$PLAN_FILE"
    echo "" >> "$PLAN_FILE"
    
    for report in "$REPORT_DIR"/*.txt; do
        if [ -f "$report" ]; then
            filename=$(basename "$report")
            filesize=$(wc -l < "$report" 2>/dev/null || echo "N/A")
            echo "- **$filename** ($filesize linhas)" >> "$PLAN_FILE"
        fi
    done
    
    echo "" >> "$PLAN_FILE"
fi

# Adicionar estatísticas do projeto
echo "### Estatísticas do Projeto" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

if [ -d "$SOURCE_DIR" ]; then
    java_files=$(find "$SOURCE_DIR" -name "*.java" | wc -l)
    echo "- **Arquivos Java:** $java_files" >> "$PLAN_FILE"
    
    # Contar constantes existentes
    constant_files=$(find "$SOURCE_DIR" -name "*Constant*.java" -o -name "*Constante*.java" | wc -l)
    echo "- **Arquivos de Constantes Existentes:** $constant_files" >> "$PLAN_FILE"
    
    # Estimar constantes dispersas
    magic_numbers=$(grep -r "= [0-9]\+" "$SOURCE_DIR" --include="*.java" | wc -l 2>/dev/null || echo "N/A")
    echo "- **Números Mágicos Estimados:** $magic_numbers" >> "$PLAN_FILE"
    
    hardcoded_strings=$(grep -r '"[A-Za-z]' "$SOURCE_DIR" --include="*.java" | wc -l 2>/dev/null || echo "N/A")
    echo "- **Strings Hardcoded Estimadas:** $hardcoded_strings" >> "$PLAN_FILE"
fi

echo "" >> "$PLAN_FILE"
echo "---" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"
echo "*Plano gerado automaticamente em $(date)*" >> "$PLAN_FILE"

echo "Plano de migração gerado com sucesso!"
echo "Arquivo: $PLAN_FILE"
echo "Tamanho: $(wc -l < "$PLAN_FILE") linhas"

# Criar um resumo executivo
SUMMARY_FILE="$MIGRATION_DIR/resumo-executivo-$(date +%Y%m%d-%H%M%S).md"

cat > "$SUMMARY_FILE" << 'EOF'
# Resumo Executivo - Migração de Constantes

## Situação Atual
- Constantes dispersas em múltiplos arquivos
- Duplicação de valores e inconsistências
- Dificuldade de manutenção e evolução

## Solução Proposta
- Consolidação em 4 arquivos organizados
- Migração em 3 fases por prioridade
- Cronograma de 3 semanas

## Benefícios Esperados
- ✅ Redução de 80% na duplicação
- ✅ Melhoria na manutenibilidade
- ✅ Facilidade para mudanças futuras
- ✅ Padronização do código

## Investimento
- **Tempo:** 3 semanas
- **Recursos:** 1 dev senior + 1 dev pleno + QA
- **Risco:** Baixo a médio

## ROI
- Redução significativa no tempo de manutenção
- Menor probabilidade de bugs por inconsistência
- Facilidade para implementar mudanças globais
- Melhoria na qualidade do código

## Próximos Passos
1. Aprovação do plano
2. Alocação de recursos
3. Início da Fase 1

**Recomendação:** Aprovação imediata para início na próxima sprint
EOF

echo "Resumo executivo criado: $SUMMARY_FILE"

echo "Geração do plano de migração concluída com sucesso!"