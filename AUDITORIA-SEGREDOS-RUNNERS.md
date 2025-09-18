# 🔍 AUDITORIA DE SEGREDOS E RUNNERS - PIPELINE CI/CD

## 📋 **ESTADO ATUAL IDENTIFICADO**

### **🔑 GitHub Secrets Identificados no Código**
```yaml
# Secrets OIDC Azure (CORRETOS):
secrets.AZURE_CLIENT_ID
secrets.AZURE_TENANT_ID  
secrets.AZURE_SUBSCRIPTION_ID
secrets.AZURE_KEYVAULT_NAME

# Análise: ✅ Apenas secrets de conexão Azure OIDC
```

### **🏃‍♂️ Runners Identificados**
```yaml
# Jobs atuais:
validate-and-build: ubuntu-latest          ← Validação pode ser GitHub hosted
approval-gate: ubuntu-latest               ← Approval pode ser GitHub hosted  
deploy-selfhosted: self-hosted             ← ✅ CORRETO para infraestrutura
post-deploy-monitoring: ubuntu-latest      ← Monitoring pode ser GitHub hosted
```

### **🔍 Problemas Identificados**

#### **❌ Runner Incorreto**
- **deploy-selfhosted**: Usando `conexao-de-sorte-traefik-infraestrutura`
- **Esperado para infraestrutura**: `conexao-de-sorte-*-infraestrutura`

#### **❓ Verificações Necessárias**
- Confirmar se existem secrets adicionais não mapeados
- Validar se todos os segredos do projeto estão no Key Vault
- Verificar permissões OIDC mínimas

---

## 🎯 **PLANO DE CORREÇÕES**

### **1. Auditoria GitHub Secrets** ✅
- Secrets OIDC corretos identificados
- Nenhum secret adicional encontrado no código

### **2. Auditoria Key Vault** 🔄
- Verificar segredos específicos do Traefik
- Ajustar busca apenas dos segredos necessários

### **3. Integração OIDC** 🔄  
- Validar permissões mínimas
- Confirmar azure/login@v2

### **4. Correção Runners** ❌
- Ajustar runner de infraestrutura
- Manter padrão: `srv649924 self-hosted Linux X64 conexao conexao-de-sorte-*-infraestrutura`

### **5. Validação Final** 🔄
- Teste de conectividade OIDC
- Validação YAML

### **6. Documentação** 🔄
- Atualizar docs sobre segredos e runners