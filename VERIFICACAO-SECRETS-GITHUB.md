# Verificação de Segredos do GitHub para Azure OIDC

## 📋 Objetivo
Este documento verifica se os segredos do GitHub estão configurados corretamente para autenticação via Azure OIDC e acesso ao Key Vault.

## 🔐 Segredos Necessários

Os seguintes segredos DEVEM estar configurados no GitHub Repository Settings:

### Segredos Obrigatórios para OIDC:
- `AZURE_CLIENT_ID` - Client ID da App Registration no Azure AD
- `AZURE_TENANT_ID` - Tenant ID do Azure AD
- `AZURE_SUBSCRIPTION_ID` - Subscription ID do Azure

### Segredos para Key Vault:
- `AZURE_KEYVAULT_NAME` - Nome do Key Vault (sem .vault.azure.net)
- `AZURE_KEYVAULT_ENDPOINT` - (Opcional) Endpoint customizado do Key Vault

## ✅ Verificação Passo a Passo

### 1. Verificar se os Segredos Estão Configurados
```bash
# No GitHub, vá para: Settings > Secrets and variables > Actions
# Verifique se TODOS os segredos listados acima estão presentes
```

### 2. Verificar Valores dos Segredos
```bash
# Client ID (deve ser um GUID)
echo $AZURE_CLIENT_ID
# Exemplo: 12345678-1234-1234-1234-123456789abc

# Tenant ID (deve ser um GUID)
echo $AZURE_TENANT_NAME
# Exemplo: 87654321-4321-4321-4321-210987654321

# Subscription ID (deve ser um GUID)
echo $AZURE_SUBSCRIPTION_ID
# Exemplo: 11111111-2222-3333-4444-555555555555

# Key Vault Name (apenas o nome, sem URL)
echo $AZURE_KEYVAULT_NAME
# Exemplo: meu-keyvault (NÃO: https://meu-keyvault.vault.azure.net)
```

### 3. Verificar Configuração no Azure

#### 3.1 App Registration
```bash
# Verificar se a App Registration existe e está configurada corretamente
az ad app show --id $AZURE_CLIENT_ID
```

#### 3.2 Federated Identity Credential
```bash
# Verificar se o Federated Identity Credential está configurado
az ad app federated-credential list --id $AZURE_CLIENT_ID

# Deve mostrar uma configuração similar a:
# {
#   "name": "github-fic",
#   "issuer": "https://token.actions.githubusercontent.com",
#   "subject": "repo:SEU_USUARIO/SEU_REPO:ref:refs/heads/main",
#   "description": "GitHub OIDC"
# }
```

#### 3.3 Permissões do Key Vault
```bash
# Verificar se a App Registration tem acesso ao Key Vault
az role assignment list --assignee $AZURE_CLIENT_ID --scope /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/NOME_DO_RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$AZURE_KEYVAULT_NAME

# Deve mostrar:
# Key Vault Secrets User (ou similar)
```

### 4. Testar Conectividade Manual
```bash
# Fazer login com as credenciais
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# Testar acesso ao Key Vault
az keyvault secret list --vault-name $AZURE_KEYVAULT_NAME

# Testar acesso a segredos específicos
az keyvault secret show --name conexao-de-sorte-letsencrypt-email --vault-name $AZURE_KEYVAULT_NAME
az keyvault secret show --name conexao-de-sorte-traefik-dashboard-password --vault-name $AZURE_KEYVAULT_NAME
```

## 🚨 Problemas Comuns

### 1. Login OIDC Falha
**Sintoma:** "Login Azure não realizado ou falhou"
**Causa:** Federated Identity Credential não configurado
**Solução:** 
```bash
# Criar Federated Identity Credential
az ad app federated-credential create \
  --id $AZURE_CLIENT_ID \
  --parameters '{
    "name": "github-fic",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:SEU_USUARIO/conexao-de-sorte-traefik-infraestrutura:ref:refs/heads/main",
    "description": "GitHub OIDC",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 2. Acesso ao Key Vault Negado
**Sintoma:** "Não foi possível conectar ao Key Vault"
**Causa:** Permissões RBAC insuficientes
**Solução:**
```bash
# Adicionar permissão de leitura de segredos
az role assignment create \
  --assignee $AZURE_CLIENT_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/NOME_DO_RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$AZURE_KEYVAULT_NAME
```

### 3. Segredos Não Encontrados
**Sintoma:** "Email Let's Encrypt não encontrado" ou "Senha dashboard não encontrada"
**Causa:** Segredos não existem no Key Vault
**Solução:** Criar os segredos no Key Vault
```bash
# Criar segredos essenciais
az keyvault secret set --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-letsencrypt-email --value "seu-email@example.com"
az keyvault secret set --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-traefik-dashboard-password --value "senha-segura-aqui"
```

## 🔧 Configuração Correta dos Segredos no GitHub

1. Acesse: `https://github.com/SEU_USUARIO/conexao-de-sorte-traefik-infraestrutura/settings/secrets/actions`
2. Clique em "New repository secret"
3. Adicione cada segredo:

### AZURE_CLIENT_ID
- **Name:** AZURE_CLIENT_ID
- **Value:** Client ID da App Registration (GUID)
- **Exemplo:** `12345678-1234-1234-1234-123456789abc`

### AZURE_TENANT_ID
- **Name:** AZURE_TENANT_ID
- **Value:** Tenant ID do Azure AD (GUID)
- **Exemplo:** `87654321-4321-4321-4321-210987654321`

### AZURE_SUBSCRIPTION_ID
- **Name:** AZURE_SUBSCRIPTION_ID
- **Value:** Subscription ID do Azure (GUID)
- **Exemplo:** `11111111-2222-3333-4444-555555555555`

### AZURE_KEYVAULT_NAME
- **Name:** AZURE_KEYVAULT_NAME
- **Value:** Nome do Key Vault (sem URL)
- **Exemplo:** `conexao-de-sorte-keyvault`
- **NOTA:** NÃO use a URL completa!

### AZURE_KEYVAULT_ENDPOINT (Opcional)
- **Name:** AZURE_KEYVAULT_ENDPOINT
- **Value:** Endpoint customizado (se usar Key Vault privado)
- **Exemplo:** `https://conexao-de-sorte-keyvault.vault.azure.net/`

## ✅ Checklist Final

Antes de executar o pipeline, verifique:

- [ ] Todos os 5 segredos estão configurados no GitHub
- [ ] App Registration existe no Azure AD
- [ ] Federated Identity Credential está configurado para seu repositório
- [ ] App Registration tem acesso ao Key Vault (RBAC)
- [ ] Key Vault existe e contém os segredos necessários
- [ ] Testou a conectividade manualmente (opcional)

## 🎯 Resultado Esperado

Após configuração correta, o pipeline deve mostrar:
```
✅ Login Azure realizado com sucesso
✅ Conectividade com Key Vault estabelecida
✅ Email Let's Encrypt obtido
✅ Senha dashboard obtida
✅ Todos os secrets obrigatórios estão disponíveis
```

Se ainda houver problemas, o pipeline continuará sem SSL automático (modo desenvolvimento).