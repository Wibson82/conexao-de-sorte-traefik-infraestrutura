# 🔧 Guia de Troubleshooting - Erro "Segredos obrigatórios não retornados pelo Key Vault"

## 🚨 Problema
O pipeline CI/CD falha com a mensagem:
```
❌ Segredos obrigatórios não retornados pelo Key Vault
```

## 🎯 Causa Raiz
O workflow está configurado corretamente para buscar **apenas 2 segredos essenciais** do Traefik Infrastructure, mas eles **não existem** no Azure Key Vault.

## 🔍 Diagnóstico Rápido

Execute o script de validação:
```bash
./validate-config.sh
```

Ou verifique manualmente os segredos essenciais:
```bash
# Verificar se os segredos essenciais existem
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-letsencrypt-email
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-traefik-dashboard-password
```

## 📋 Segredos Necessários para Traefik Infrastructure

### ✅ **ESSENCIAIS** (Obrigatórios - Pipeline falha sem eles)
1. `conexao-de-sorte-letsencrypt-email` - Email para registro Let's Encrypt
2. `conexao-de-sorte-traefik-dashboard-password` - Senha do dashboard Traefik

### 🔶 **OPCIONAIS** (Pipeline continua se faltarem)
3. `conexao-de-sorte-ssl-cert-password` - Senha para certificados SSL
4. `conexao-de-sorte-traefik-admin-password` - Senha admin Traefik
5. `conexao-de-sorte-traefik-audit-password` - Senha de auditoria Traefik
6. `conexao-de-sorte-traefik-crypto-password` - Senha criptográfica Traefik

## 🛠️ Solução Completa

### Passo 1: Verificar Configuração Atual
```bash
# Listar TODOS os segredos do Key Vault
az keyvault secret list --vault-name $AZURE_KEYVAULT_NAME --query "[].name" -o tsv | grep conexao-de-sorte

# Verificar especificamente os segredos do Traefik
echo "=== Verificando segredos ESSENCIAIS ==="
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-letsencrypt-email --query "name,id" -o tsv || echo "❌ FALTANDO: conexao-de-sorte-letsencrypt-email"
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-traefik-dashboard-password --query "name,id" -o tsv || echo "❌ FALTANDO: conexao-de-sorte-traefik-dashboard-password"
```

### Passo 2: Criar Segredos Essenciais (se faltarem)
```bash
# Criar segredo do email Let's Encrypt
az keyvault secret set \
  --vault-name $AZURE_KEYVAULT_NAME \
  --name conexao-de-sorte-letsencrypt-email \
  --value "seu-email@dominio.com" \
  --description "Email para registro Let's Encrypt no Traefik Infrastructure"

# Criar segredo da senha do dashboard
az keyvault secret set \
  --vault-name $AZURE_KEYVAULT_NAME \
  --name conexao-de-sorte-traefik-dashboard-password \
  --value "$(openssl rand -base64 32)" \
  --description "Senha do dashboard Traefik Infrastructure"
```

### Passo 3: Verificar Permissões do Service Principal
```bash
# Obter ID do Service Principal
SP_ID=$(az ad sp list --display-name "github-actions-traefik" --query "[0].id" -o tsv)

# Verificar permissões no Key Vault
az keyvault show --name $AZURE_KEYVAULT_NAME --query "properties.accessPolicies[?objectId=='$SP_ID'].permissions.secrets" -o tsv

# Se necessário, adicionar permissões
az keyvault set-policy --name $AZURE_KEYVAULT_NAME \
  --object-id $SP_ID \
  --secret-permissions get list
```

### Passo 4: Testar Acesso
```bash
# Testar recuperação de segredos (como o pipeline faz)
echo "=== Testando recuperação de segredos ==="
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-letsencrypt-email --query value -o tsv
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-traefik-dashboard-password --query value -o tsv
```

### Passo 5: Executar Pipeline
Após criar os segredos, execute o pipeline manualmente:
1. Vá para Actions > CI/CD Pipeline
2. Clique em "Run workflow"
3. Selecione a branch main
4. Clique em "Run workflow"

## 🔍 Debug Detalhado

Se o erro persistir, adicione debug ao workflow:

```yaml
- name: Debug Key Vault Access
  run: |
    echo "=== Debug Key Vault ==="
    echo "Key Vault Name: ${{ vars.AZURE_KEYVAULT_NAME }}"
    echo "Testing connection..."
    az keyvault secret list --vault-name "${{ vars.AZURE_KEYVAULT_NAME }}" --query "[].name" -o tsv | grep conexao-de-sorte || echo "No conexao-de-sorte secrets found"
    echo "=== Testing essential secrets ==="
    az keyvault secret show --vault-name "${{ vars.AZURE_KEYVAULT_NAME }}" --name conexao-de-sorte-letsencrypt-email --query "name" -o tsv || echo "❌ Email secret not found"
    az keyvault secret show --vault-name "${{ vars.AZURE_KEYVAULT_NAME }}" --name conexao-de-sorte-traefik-dashboard-password --query "name" -o tsv || echo "❌ Dashboard password not found"
```

## ⚠️ Erros Comuns e Soluções

### Erro: "The user, group or application does not have permissions"
**Solução**: Adicione permissões de leitura ao Service Principal
```bash
az keyvault set-policy --name $AZURE_KEYVAULT_NAME \
  --object-id $SP_ID \
  --secret-permissions get list
```

### Erro: "Secret not found"
**Solução**: Crie o segredo com o nome exato (case-sensitive)
```bash
az keyvault secret set --vault-name $AZURE_KEYVAULT_NAME --name NOME_EXATO --value "valor"
```

### Erro: "Vault not found"
**Solução**: Verifique o nome do Key Vault na variável AZURE_KEYVAULT_NAME
```bash
echo "AZURE_KEYVAULT_NAME: ${{ vars.AZURE_KEYVAULT_NAME }}"
```

## 📊 Verificação Final

Execute este comando para verificar tudo:
```bash
#!/bin/bash
echo "=== Verificação Completa do Key Vault ==="
echo "Key Vault: $AZURE_KEYVAULT_NAME"
echo

echo "1. Segredos ESSENCIAIS do Traefik Infrastructure:"
for secret in conexao-de-sorte-letsencrypt-email conexao-de-sorte-traefik-dashboard-password; do
    if az keyvault secret show --vault-name "$AZURE_KEYVAULT_NAME" --name "$secret" &>/dev/null; then
        echo "✅ $secret - PRESENTE"
    else
        echo "❌ $secret - FALTANDO"
    fi
done

echo
echo "2. Segredos OPCIONAIS do Traefik Infrastructure:"
for secret in conexao-de-sorte-ssl-cert-password conexao-de-sorte-traefik-admin-password conexao-de-sorte-traefik-audit-password conexao-de-sorte-traefik-crypto-password; do
    if az keyvault secret show --vault-name "$AZURE_KEYVAULT_NAME" --name "$secret" &>/dev/null; then
        echo "✅ $secret - PRESENTE"
    else
        echo "⚠️  $secret - AUSENTE (opcional)"
    fi
done

echo
echo "3. Total de segredos conexao-de-sorte no Key Vault:"
az keyvault secret list --vault-name "$AZURE_KEYVAULT_NAME" --query "[].name" -o tsv | grep -c "conexao-de-sorte" || echo "0"
```

## 🎯 Resumo

- ✅ **O workflow está correto**: Busca apenas 2 segredos essenciais
- 🔧 **Problema**: Os segredos essenciais não existem no Key Vault
- 💡 **Solução**: Criar os 2 segredos essenciais listados acima
- 📋 **Total necessário**: Apenas 2 segredos (não os 50+ da lista completa)