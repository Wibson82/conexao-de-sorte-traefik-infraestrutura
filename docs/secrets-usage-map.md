# 🔐 **SECRETS USAGE MAP - TRAEFIK INFRASTRUCTURE**

## 📊 **INVENTÁRIO ATUAL**

### **🔍 ANÁLISE DO PIPELINE ATUAL**

#### **Arquivo Principal:** `.github/workflows/ci-cd.yml`
- ❌ **Problemas identificados:**
  - Usa `secrets.AZURE_CLIENT_ID` (deveria ser `vars.AZURE_CLIENT_ID`)
  - Usa `secrets.AZURE_TENANT_ID` (deveria ser `vars.AZURE_TENANT_ID`)
  - Usa `secrets.AZURE_KEYVAULT_ENDPOINT` (deveria ser `vars.AZURE_KEYVAULT_ENDPOINT`)
  - Scripts não existem (referências órfãs)
  - Sem limpeza de GHCR
  - Sem otimização de cache

#### **Arquivo Refatorado:** `.github/workflows/ci-cd-refatorado.yml`
- ✅ **Melhor estrutura OIDC**
- ❌ **Ainda usa secrets para identificadores Azure**

---

## 🎯 **CONFIGURAÇÃO CORRETA DE SEGREDOS**

### **📋 GitHub Repository Variables (vars) - OBRIGATÓRIO**
```bash
AZURE_CLIENT_ID=<client-id-da-aplicacao>
AZURE_KEYVAULT_ENDPOINT=https://conexao-traefik-kv.vault.azure.net/
AZURE_KEYVAULT_NAME=conexao-traefik-kv
AZURE_SUBSCRIPTION_ID=<subscription-id>
AZURE_TENANT_ID=<tenant-id-do-azure-ad>

# NOVO: Variáveis de Controle de Limpeza
MAX_VERSIONS_TO_KEEP=3
MAX_AGE_DAYS=7
PROTECTED_TAGS=latest,main,production
```

### **🔐 Azure Key Vault Secrets - POR JOB**

#### **Job: validate-environment**
```bash
# Nenhum segredo necessário
```

#### **Job: deploy-selfhosted**
```bash
# Docker Secrets (2)
TRAEFIK_BASICAUTH_USERS=admin:$2y$10$...
TRAEFIK_API_DASHBOARD_USER=admin

# SSL/TLS (2)
TRAEFIK_ACME_EMAIL=facilitaservicos.tec@gmail.com
LETSENCRYPT_STAGING=false

# TOTAL: 4 segredos específicos
```

---

## 📈 **MAPEAMENTO POR JOB**

### **Job 1: validate-environment**
```yaml
runs-on: ubuntu-latest
secrets-needed: [] # Nenhum
azure-integration: false
description: "Validação de arquivos e configurações Traefik"
```

### **Job 2: deploy-selfhosted**
```yaml
runs-on: [self-hosted, Linux, X64, conexao, conexao-de-sorte-traefik-infraestrutura]
secrets-needed:
  - TRAEFIK_BASICAUTH_USERS
  - TRAEFIK_API_DASHBOARD_USER
  - TRAEFIK_ACME_EMAIL
  - LETSENCRYPT_STAGING
azure-integration: true
oidc-required: true
description: "Deploy Docker Swarm + criação de secrets"
```

---

## 🚨 **PROBLEMAS CRÍTICOS IDENTIFICADOS**

### **❌ Configuração Incorreta de Secrets**
1. **Azure identifiers em secrets:** Devem estar em `vars`
2. **Scripts faltando:** Referências órfãs para scripts inexistentes
3. **Sem OIDC completo:** Implementação incompleta
4. **Sem limpeza GHCR:** Acúmulo desnecessário de imagens
5. **Sem cache otimizado:** Builds lentos e ineficientes

### **❌ Exposição de Segurança**
```yaml
# INCORRETO (atual)
AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}

# CORRETO (deve ser)
AZURE_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
```

---

## ✅ **PLANO DE CORREÇÃO**

### **Etapa 1: Migrar para vars**
- Mover `AZURE_*` de `secrets` para `vars`
- Adicionar variáveis de limpeza
- Remover segredos desnecessários

### **Etapa 2: Implementar OIDC completo**
- Azure login com OIDC
- Busca seletiva do Key Vault
- Permissões mínimas

### **Etapa 3: Limpeza inteligente**
- Função `cleanup_ghcr_safe()`
- Multiple criteria validation
- Protected tags

### **Etapa 4: Cache otimizado**
- Multi-level caching
- Retention policies
- Artifact cleanup

---

## 📋 **RUNNERS CORRETOS**

### **Padrão para Traefik Infrastructure:**
```yaml
# Validação
runs-on: ubuntu-latest

# Deploy
runs-on: [self-hosted, Linux, X64, conexao, conexao-de-sorte-traefik-infraestrutura]
```

---

## 🔍 **AUDITORIA DE CONFORMIDADE**

### **Status Atual: ❌ NÃO CONFORME**

| Critério | Status | Ação Necessária |
|----------|--------|-----------------|
| Identificadores Azure em vars | ❌ | Migrar de secrets para vars |
| OIDC Implementation | ⚠️ | Completar implementação |
| Key Vault seletivo | ❌ | Implementar busca por job |
| Scripts existentes | ❌ | Criar scripts faltantes |
| Limpeza GHCR | ❌ | Implementar função inteligente |
| Cache otimizado | ❌ | Implementar multi-level cache |
| Runners corretos | ✅ | Configuração adequada |

### **Meta: ✅ 100% CONFORME**
- Zero segredos desnecessários no GitHub
- OIDC funcional sem vazamentos
- Limpeza automática eficiente
- Cache inteligente implementado