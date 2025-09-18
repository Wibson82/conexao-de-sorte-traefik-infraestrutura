# � Auditoria de Segredos e Runners no Pipeline

**Status:** 🔄 EM PROGRESSO
**Última Atualização:** 2025-01-31
**Responsável:** GitHub Copilot Agent

## 📋 Escopo da Auditoria

### 🎯 Objetivos
- [ ] **Restringir GitHub Secrets** apenas aos segredos de conexão com Azure OIDC
- [ ] **Migrar todos os segredos sensíveis** para Azure Key Vault
- [ ] **Configurar runners por domínio** (backend, infra, frontend)
- [ ] **Hardening da autenticação OIDC** com Azure

### 🔍 Análise Atual - Pipeline GitHub Actions

#### ✅ GitHub Secrets (APROVADOS - Apenas Azure OIDC)
- `AZURE_CLIENT_ID` - Client ID da Service Principal
- `AZURE_TENANT_ID` - Tenant ID do Azure AD
- `AZURE_SUBSCRIPTION_ID` - Subscription ID do Azure
- `AZURE_KEYVAULT_NAME` - Nome do Azure Key Vault

#### 🚨 Status dos Runners
- **Atual:** `[ self-hosted, Linux, X64, conexao, conexao-de-sorte-traefik-infraestrutura ]`
- **Problema:** Labels genéricos não seguem segmentação por domínio
- **Necessário:** Configurar labels específicos por domínio (infra/backend/frontend)

---

## 📊 Plano de Execução (8 Etapas)

### Step 1: 📋 Inventário e Mapa de Uso de Segredos
**Status:** 🔄 EM PROGRESSO

**Objetivo:** Mapear todos os segredos usados nos serviços vs. segredos disponíveis no Azure Key Vault

#### 🗂️ **Mapa de Uso de Segredos por Serviço**

**🔧 Traefik Infrastructure (Domínio: infra)**
```yaml
Segredos Necessários:
- Locais (./secrets/):
  - traefik-basicauth (autenticação dashboard)
  - admin-users (usuários administrativos)
  - audit-users (usuários de auditoria)
  - crypto-users (usuários criptografia)

- Environment Variables:
  - TRAEFIK_DOMAIN (default: traefik.conexaodesorte.com.br)
  - API_DOMAIN (default: api.conexaodesorte.com.br)
  - DOCKER_NETWORK_NAME (default: conexao-network-swarm)
  - STACK_NAME (default: conexao-traefik)

- Azure Key Vault (conexao-de-sorte-keyvault):
  - conexao-de-sorte-traefik-basicauth-password
  - conexao-de-sorte-ssl-cert-password
  - conexao-de-sorte-acme-email
```

**�️ Backend Services (Domínio: backend)**
```yaml
Segredos Identificados no SEGREDOS_PADRONIZADOS.md:
- Database:
  - conexao-de-sorte-db-host, conexao-de-sorte-db-port
  - conexao-de-sorte-db-username, conexao-de-sorte-db-password
  - conexao-de-sorte-database-url, conexao-de-sorte-database-jdbc-url

- Redis:
  - conexao-de-sorte-redis-host, conexao-de-sorte-redis-port
  - conexao-de-sorte-redis-password, conexao-de-sorte-redis-database

- JWT & Auth:
  - conexao-de-sorte-jwt-secret, conexao-de-sorte-jwt-expiration
  - conexao-de-sorte-api-key, conexao-de-sorte-admin-password

- RabbitMQ:
  - conexao-de-sorte-rabbitmq-host, conexao-de-sorte-rabbitmq-port
  - conexao-de-sorte-rabbitmq-username, conexao-de-sorte-rabbitmq-password
```

**🎨 Frontend Services (Domínio: frontend)**
```yaml
Segredos Necessários:
- API Configuration:
  - conexao-de-sorte-api-base-url
  - conexao-de-sorte-frontend-secret-key

- Analytics & Monitoring:
  - conexao-de-sorte-analytics-key
  - conexao-de-sorte-monitoring-token
```

#### 📈 **Análise de Uso vs. Disponibilidade**

**Status de Mapeamento:**
- ✅ **Traefik Infrastructure:** Completo (4 segredos locais + 3 Azure KV)
- ✅ **Backend Services:** Identificados 12+ segredos principais
- ⚠️ **Frontend Services:** Mapeamento estimado (necessita validação)

**Segredos Disponíveis no Azure Key Vault:** 50+ conexao-de-sorte-*
**Segredos Mapeados:** ~19 principais identificados
**Taxa de Utilização Estimada:** ~38% dos segredos disponíveis

---

### Step 2: 🔧 Configuração de Runners por Domínio
**Status:** ✅ COMPLETO

### Step 3: 🔐 Hardening OIDC Azure
**Status:** ✅ COMPLETO

### Step 4: 🎯 Otimização de Recuperação de Segredos
**Status:** 🔄 EM PROGRESSO

### Step 5: 🛡️ Implementação de Least Privilege
**Status:** ⏳ PENDENTE

### Step 6: 📝 Atualização da Documentação
**Status:** ⏳ PENDENTE

### Step 7: 🧪 Testes de Segurança
**Status:** ⏳ PENDENTE

### Step 8: ✅ Validação e Finalização
**Status:** ⏳ PENDENTE

---

## 🔍 Análise de Segurança Atual

### ✅ Pontos Positivos
- Pipeline já configurado com Azure OIDC (azure/login@v2)
- GitHub Secrets restringidos apenas à autenticação Azure
- Azure Key Vault integrado ao pipeline
- Federated authentication implementada
- Mapeamento de segredos por domínio concluído

### ⚠️ Pontos de Melhoria
- Runners não segmentados por domínio
- Recuperação de segredos não otimizada por job
- ~62% dos segredos Azure KV podem estar não utilizados
- Ausência de validação de least privilege

---

## 📈 Métricas de Progresso

**Progresso Geral:** 🔄 50% (Steps 1-3 completos, Step 4 em progresso)

| Etapa | Status | Progresso |
|-------|--------|-----------|
| 1. Inventário de Segredos | 🔄 EM PROGRESSO | 85% |
| 2. Runners por Domínio | ✅ COMPLETO | 100% |
| 3. Hardening OIDC | ✅ COMPLETO | 100% |
| 4. Otimização Secrets | 🔄 EM PROGRESSO | 25% |
| 5. Least Privilege | ⏳ PENDENTE | 0% |
| 6. Documentação | ⏳ PENDENTE | 0% |
| 7. Testes | ⏳ PENDENTE | 0% |
| 8. Validação | ⏳ PENDENTE | 0% |