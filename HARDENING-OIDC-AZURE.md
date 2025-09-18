# 🔐 Hardening OIDC Azure - Configuração de Segurança

**Status:** ✅ IMPLEMENTADO
**Última Atualização:** 2025-01-31
**Objetivo:** Fortalecer a autenticação OIDC entre GitHub Actions e Azure

## 🛡️ Melhorias de Segurança Implementadas

### 1. **🎯 Validação de Claims OIDC**

#### **Validações Implementadas:**
```yaml
# Validação obrigatória de contexto
- Repository: Deve conter "traefik-infraestrutura"
- Branch: Apenas "refs/heads/main" autorizada
- Actor: Logged para auditoria
- Run ID/Number: Tracked para rastreabilidade
```

#### **Código de Validação:**
```bash
# Branch validation
if [[ "${{ github.ref }}" != "refs/heads/main" ]]; then
  echo "❌ SECURITY VIOLATION: Deploy permitido apenas da branch main"
  exit 1
fi

# Repository validation
if [[ "${{ github.repository }}" != *"traefik-infraestrutura"* ]]; then
  echo "❌ SECURITY VIOLATION: Repositório não autorizado"
  exit 1
fi
```

---

### 2. **🔑 Least Privilege Key Vault Access**

#### **Segredos Autorizados para Domínio Infra:**
```yaml
REQUIRED_SECRETS:
  - conexao-de-sorte-traefik-basicauth-password
  - conexao-de-sorte-ssl-cert-password
  - conexao-de-sorte-acme-email
```

#### **Validação de Acesso:**
- ✅ Testa acesso apenas aos segredos necessários
- ⚠️ Continua execução mesmo se alguns segredos não existirem
- ❌ Falha se NENHUM segredo estiver acessível

---

### 3. **🎭 Configuração OIDC Hardened**

#### **azure/login@v2 com Segurança:**
```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    # 🛡️ SECURITY: Enable audience validation
    audience: api://AzureADTokenExchange
    # 🛡️ SECURITY: Strict subscription validation
    allow-no-subscriptions: false
```

---

## ⚙️ Configuração da Service Principal no Azure

### **Condições de Acesso Recomendadas**

#### **1. Conditional Access Policy**
```json
{
  "displayName": "GitHub Actions OIDC - Traefik Infra",
  "conditions": {
    "applications": ["GitHub-Actions-OIDC-App"],
    "clientApplications": ["specific-client-id"],
    "locations": {
      "includeLocations": ["Trusted-GitHub-Runners"]
    }
  },
  "grantControls": {
    "operator": "AND",
    "builtInControls": ["requireCompliantDevice"]
  }
}
```

#### **2. Claims Validation**
```json
{
  "repository": "conexao-de-sorte/*/traefik-infraestrutura",
  "ref": "refs/heads/main",
  "environment": "production"
}
```

---

### **Permissões Mínimas da Service Principal**

#### **Key Vault Permissions (Least Privilege):**
```json
{
  "permissions": {
    "secrets": [
      "get"
    ],
    "keys": [],
    "certificates": []
  },
  "secretPermissions": {
    "allowedSecrets": [
      "conexao-de-sorte-traefik-basicauth-password",
      "conexao-de-sorte-ssl-cert-password",
      "conexao-de-sorte-acme-email"
    ]
  }
}
```

#### **Azure RBAC Roles:**
```bash
# Papel mínimo necessário
az role assignment create \
  --assignee <service-principal-id> \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault-name>"
```

---

## 🔍 Auditoria e Monitoramento

### **Logs de Segurança Habilitados:**

#### **1. Azure AD Sign-ins**
- ✅ OIDC token requests
- ✅ Claims validation
- ✅ Failed authentication attempts

#### **2. Key Vault Audit Logs**
- ✅ Secret access attempts
- ✅ Unauthorized access attempts
- ✅ Bulk secret enumeration

#### **3. GitHub Actions Audit**
- ✅ Workflow execution logs
- ✅ Runner assignment logs
- ✅ Secret access patterns

---

### **Alertas de Segurança:**

#### **High Priority Alerts:**
```yaml
- Acesso de repositório não autorizado
- Tentativa de acesso de branch não main
- Falha repetida na validação OIDC
- Acesso a segredos fora do escopo
```

#### **Medium Priority Alerts:**
```yaml
- Segredos não encontrados (pode indicar rotação)
- Execução fora do horário comercial
- Actor não reconhecido
```

---

## 🧪 Testes de Segurança

### **Cenários de Teste Implementados:**

#### **1. Positive Tests ✅**
- Deploy de branch main com repository correto
- Acesso a segredos autorizados
- Claims OIDC válidos

#### **2. Negative Tests ❌**
- Tentativa de deploy de branch feature
- Acesso de repositório não autorizado
- Token OIDC com claims inválidos

#### **3. Edge Cases ⚠️**
- Segredos parcialmente disponíveis
- Network timeouts durante validação
- Service Principal com permissões reduzidas

---

## 📊 Métricas de Segurança

### **KPIs de Monitoramento:**
- **Authentication Success Rate:** >99%
- **Unauthorized Access Attempts:** 0
- **Secret Access Outside Scope:** 0
- **Failed Claims Validation:** <1%

### **SLAs de Segurança:**
- **OIDC Token Validation:** <30s
- **Key Vault Access:** <10s
- **Security Incident Response:** <15min

---

## 🔧 Próximos Passos de Hardening

### **Fase 2 - Melhorias Avançadas:**
1. **🌐 Network Restrictions:** Limitar IPs dos runners
2. **⏰ Time-based Access:** Restringir horários de deploy
3. **🔄 Secret Rotation:** Automação de rotação de segredos
4. **📱 MFA Integration:** Aprovação manual para deploys críticos

### **Fase 3 - Zero Trust:**
1. **🛡️ Device Compliance:** Validação de compliance do runner
2. **🔍 Behavioral Analytics:** Detecção de anomalias
3. **📋 Just-in-Time Access:** Permissões temporárias
4. **🔐 Hardware Security Modules:** Proteção de chaves críticas

---

**✅ STATUS:** Hardening OIDC implementado com sucesso. Pipeline agora inclui validação rigorosa de claims, acesso com menor privilégio ao Key Vault, e auditoria completa de segurança.