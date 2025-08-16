# 📋 Documentação dos Scripts de Teste

Este documento explica as diferenças entre os scripts de teste refatorados para evitar conflitos e melhorar a organização.

## 🎯 Scripts de Teste Disponíveis

### 1. `test-domain-routing.sh` - Teste de Roteamento de Domínios
**Foco**: Verificar se o Traefik está roteando corretamente os domínios para frontend e backend.

**Funcionalidades**:
- ✅ Testa redirecionamento HTTP→HTTPS
- ✅ Verifica roteamento frontend (React na porta 3000)
- ✅ Verifica roteamento backend (API na porta 8080/rest)
- ✅ Verifica containers Docker (traefik, frontend, backend)
- ✅ Verifica configuração do Traefik via API
- ✅ Testa ambos domínios: `conexaodesorte.com.br` e `www.conexaodesorte.com.br`

**Uso**:
```bash
./scripts/test-domain-routing.sh
```

**Quando usar**: Quando você precisa verificar se o roteamento de domínios está funcionando corretamente.

---

### 2. `test-api-endpoints.sh` - Teste de Endpoints da API
**Foco**: Validar a funcionalidade dos endpoints específicos da API REST.

**Funcionalidades**:
- ✅ Testa endpoints específicos da API (health, info, resultados, etc.)
- ✅ Valida respostas JSON
- ✅ Testa performance da API
- ✅ Verifica conectividade básica da API
- ✅ Analisa estrutura da API

**Endpoints testados**:
- `/rest/actuator/health`
- `/rest/v1/publico/teste`
- `/rest/v1/info`
- `/rest/v1/resultados/publico/ultimo/rio`
- `/rest/v1/resultados/publico/ultimo/boa%20sorte`
- `/rest/v1/resultados/publico`
- `/rest/v1/estatisticas/publico`
- `/rest/v1/horarios/validos`

**Uso**:
```bash
./scripts/test-api-endpoints.sh
```

**Quando usar**: Quando você precisa verificar se os endpoints da API estão funcionando corretamente.

---

### 3. `test-specific-endpoint.sh` - Teste de Endpoints de Resultados de Loteria
**Foco**: Validar especificamente os endpoints de resultados de loteria.

**Funcionalidades**:
- ✅ Testa endpoints de resultados de loteria específicos
- ✅ Valida dados de loteria (horário, data, números, modalidade)
- ✅ Testa múltiplos horários (rio, boa sorte)
- ✅ Testa ambos domínios e protocolos (HTTP/HTTPS)
- ✅ Análise detalhada de respostas de loteria

**Endpoints testados**:
- `/rest/v1/resultados/publico/ultimo/rio`
- `/rest/v1/resultados/publico/ultimo/boa%20sorte`

**Uso**:
```bash
./scripts/test-specific-endpoint.sh
```

**Quando usar**: Quando você precisa verificar especificamente os endpoints de resultados de loteria.

---

### 4. `test-endpoint-specific.sh` - Teste de Endpoint Crítico
**Foco**: Teste focado em um endpoint crítico específico.

**Funcionalidades**:
- ✅ Testa um endpoint crítico específico
- ✅ Análise detalhada de um único endpoint
- ✅ Diagnóstico específico de problemas

**Uso**:
```bash
./scripts/test-endpoint-specific.sh
```

**Quando usar**: Quando você precisa focar em um endpoint específico que está com problemas.

---

## 🔄 Diferenças Principais

| Aspecto         | Domain Routing        | API Endpoints      | Lottery Results    | Endpoint Specific |
| --------------- | --------------------- | ------------------ | ------------------ | ----------------- |
| **Foco**        | Roteamento Traefik    | Funcionalidade API | Resultados Loteria | Endpoint Crítico  |
| **Domínios**    | Ambos (com e sem www) | Apenas www         | Ambos              | Apenas www        |
| **Protocolos**  | HTTP/HTTPS            | Apenas HTTPS       | HTTP/HTTPS         | Apenas HTTPS      |
| **Containers**  | Verifica Docker       | Não verifica       | Não verifica       | Não verifica      |
| **Traefik**     | Verifica API          | Não verifica       | Não verifica       | Não verifica      |
| **Performance** | Não testa             | Testa              | Não testa          | Não testa         |
| **Dados**       | Content-Type          | JSON completo      | Dados loteria      | Análise detalhada |

## 🚀 Fluxo de Testes Recomendado

### Para problemas de roteamento:
1. `test-domain-routing.sh` - Verificar se o Traefik está roteando corretamente
2. Se OK, usar `test-api-endpoints.sh` - Verificar se a API está funcionando

### Para problemas de API:
1. `test-api-endpoints.sh` - Verificar todos os endpoints da API
2. Se problemas específicos, usar `test-endpoint-specific.sh`

### Para problemas de loteria:
1. `test-specific-endpoint.sh` - Verificar endpoints de resultados de loteria
2. Se problemas gerais, usar `test-api-endpoints.sh`

### Para diagnóstico geral:
1. `test-domain-routing.sh` - Verificar infraestrutura
2. `test-api-endpoints.sh` - Verificar API
3. `test-specific-endpoint.sh` - Verificar loteria

## 🔧 Dependências

Todos os scripts requerem:
- `curl` - Para fazer requisições HTTP
- `jq` - Para processar JSON (opcional, mas recomendado)
- `bc` - Para cálculos de performance (opcional)

## 📊 Saídas

Cada script fornece:
- ✅ Logs coloridos e organizados
- 📊 Estatísticas de sucesso/falha
- 🔗 URLs para teste manual
- 💡 Sugestões de diagnóstico

## 🎯 Resultado Final

Após a refatoração, os scripts não têm mais conflitos e cada um tem um propósito específico e bem definido, facilitando o diagnóstico e manutenção do sistema.
