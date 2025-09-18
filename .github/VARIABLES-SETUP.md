# 🔧 **CONFIGURAÇÃO OBRIGATÓRIA: GITHUB VARIABLES & SECRETS**

## ⚠️ **AÇÃO NECESSÁRIA: CONFIGURAR MANUALMENTE NO GITHUB**

### **📍 Localização:**
`GitHub Repository → Settings → Secrets and variables → Actions`

---

## 📋 **VARIABLES (vars) - MIGRAR/CONFIGURAR**

### **🔧 Aba "Variables"**
```bash
# Azure OIDC Identifiers (MIGRAR de secrets se existirem)
AZURE_CLIENT_ID=<client-id-da-aplicacao>
AZURE_KEYVAULT_ENDPOINT=https://conexao-traefik-kv.vault.azure.net/
AZURE_KEYVAULT_NAME=conexao-traefik-kv
AZURE_SUBSCRIPTION_ID=<subscription-id>
AZURE_TENANT_ID=<tenant-id-do-azure-ad>

# NOVO: Variáveis de Controle de Limpeza GHCR
MAX_VERSIONS_TO_KEEP=3
MAX_AGE_DAYS=7
PROTECTED_TAGS=latest,main,production

# Cache Configuration
CACHE_KEY_PREFIX=traefik-infra
CACHE_RETENTION_DAYS=7
```

---

## 🔐 **SECRETS (secrets) - REMOVER IDENTIFICADORES AZURE**

### **🗑️ REMOVER (se existirem):**
```bash
# INCORRETO: Estes devem estar em vars, não secrets
AZURE_CLIENT_ID          # → mover para vars
AZURE_TENANT_ID          # → mover para vars
AZURE_SUBSCRIPTION_ID    # → mover para vars
AZURE_KEYVAULT_ENDPOINT  # → mover para vars
AZURE_KEYVAULT_NAME      # → mover para vars
```

### **✅ MANTER APENAS (se necessário para outros workflows):**
```bash
# Apenas se houver outros workflows que necessitem
GITHUB_TOKEN  # (automático)
```

---

## 🔑 **AZURE KEY VAULT SECRETS (configurar no Azure)**

### **📍 Key Vault:** `conexao-traefik-kv`
```bash
# Docker Secrets para Traefik (4 segredos)
TRAEFIK-BASICAUTH-USERS=admin:$2y$10$rQ.0eEWJx7mQ8k4yR4x9/.2l0JUqN7zYTHmFePXkz1YRkFvqRZ5hW
TRAEFIK-API-DASHBOARD-USER=admin
TRAEFIK-ACME-EMAIL=facilitaservicos.tec@gmail.com
LETSENCRYPT-STAGING=false
```

---

## 🚀 **COMANDOS DE VERIFICAÇÃO**

### **Após configuração, verificar:**
```bash
# 1. Verificar vars configuradas
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/Wibson82/conexao-de-sorte-traefik-infraestrutura/actions/variables

# 2. Verificar secrets removidos
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/Wibson82/conexao-de-sorte-traefik-infraestrutura/actions/secrets

# 3. Verificar Azure Key Vault
az keyvault secret list --vault-name conexao-traefik-kv --query "[].name" -o table
```

---

## ⚠️ **MIGRAÇÃO PASSO A PASSO**

### **1. Backup atual**
```bash
# Anotar valores atuais dos secrets antes de remover
```

### **2. Criar vars**
```bash
# No GitHub UI: Settings → Secrets and variables → Actions → Variables
# Adicionar todas as variáveis listadas acima
```

### **3. Remover secrets desnecessários**
```bash
# No GitHub UI: Settings → Secrets and variables → Actions → Secrets
# Remover: AZURE_CLIENT_ID, AZURE_TENANT_ID, etc.
```

### **4. Verificar Azure Key Vault**
```bash
# Confirmar que os 4 segredos existem no Key Vault
az keyvault secret show --vault-name conexao-traefik-kv --name TRAEFIK-BASICAUTH-USERS
```

---

## ✅ **CHECKLIST DE CONFIGURAÇÃO**

- [ ] **Vars criadas:** 8 variáveis (Azure + Limpeza + Cache)
- [ ] **Secrets removidos:** Azure identifiers migrados para vars
- [ ] **Key Vault:** 4 segredos específicos do Traefik confirmados
- [ ] **Verificação:** APIs GitHub + Azure respondem corretamente
- [ ] **Teste:** Pipeline consegue acessar vars e Key Vault

---

**⚠️ IMPORTANTE:** Esta configuração é **obrigatória** antes do próximo push. O pipeline falhará se não estiver configurado corretamente.