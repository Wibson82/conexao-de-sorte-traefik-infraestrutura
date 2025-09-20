# 🔧 Configuração de Variáveis e Segredos para Traefik Infrastructure

## 📋 Visão Geral
Este documento descreve as variáveis e segredos necessários para o pipeline CI/CD do Traefik Infrastructure, seguindo a política de segurança da organização.

## ⚙️ GitHub Variables (Obrigatórias)
Configure estas variáveis em **Settings > Secrets and variables > Actions > Variables**:

```bash
# Identificadores Azure (não são segredos, apenas identificadores)
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_KEYVAULT_NAME=nome-do-keyvault
```

## 🔐 Azure Key Vault Secrets
Os seguintes segredos devem estar configurados no Azure Key Vault:

### Essenciais (obrigatórios)
- `conexao-de-sorte-letsencrypt-email` - Email para registro Let's Encrypt
- `conexao-de-sorte-traefik-dashboard-password` - Senha do dashboard Traefik

### Opcionais (recomendados)
- `conexao-de-sorte-ssl-cert-password` - Senha para certificados SSL
- `conexao-de-sorte-traefik-basicauth-password` - Senha para autenticação básica

## 🚀 Como Configurar

### 1. Configurar GitHub Variables
1. Vá para Settings > Secrets and variables > Actions > Variables
2. Clique em "New repository variable"
3. Adicione cada variável com seus respectivos valores

### 2. Verificar Azure Key Vault
Certifique-se de que os segredos estejam presentes no Key Vault:

```bash
# Listar segredos do Key Vault
az keyvault secret list --vault-name $AZURE_KEYVAULT_NAME --query "[].name" -o tsv

# Verificar segredos essenciais
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-letsencrypt-email
az keyvault secret show --vault-name $AZURE_KEYVAULT_NAME --name conexao-de-sorte-traefik-dashboard-password
```

### 3. Testar Pipeline
Após configurar, execute o pipeline manualmente via Actions > CI/CD Pipeline > Run workflow

## ⚠️ Políticas de Segurança

1. **Identificadores Azure** devem ser configurados como **Variables**, não como Secrets
2. **Segredos de aplicação** devem estar apenas no Azure Key Vault
3. **Princípio do mínimo necessário** - apenas segredos essenciais são obrigatórios
4. **Máscara de segredos** - todos os segredos são mascarados nos logs automaticamente

## 🔄 Migração de Secrets para Variables

Se você tem os identificadores Azure configurados como Secrets:

1. Copie os valores dos Secrets atuais
2. Crie novas Variables com os mesmos nomes e valores
3. Delete os Secrets antigos (após confirmar que tudo funciona)
4. Teste o pipeline para garantir que funciona com Variables

## 📊 Validação

O pipeline validará automaticamente:
- ✅ Presença de todas as Variables obrigatórias
- ✅ Acesso ao Azure Key Vault
- ✅ Presença de segredos essenciais
- ✅ Funcionalidade do Traefik após deploy

## 🆘 Troubleshooting

### Erro: "Variables obrigatórios ausentes"
- Verifique se todas as 4 Variables estão configuradas
- Certifique-se de usar o nome exato (case-sensitive)

### Erro: "Segredos essenciais não retornados"
- Verifique se os segredos essenciais existem no Key Vault
- Confirme que o Service Principal tem acesso ao Key Vault
- Verifique o nome do Key Vault na variável `AZURE_KEYVAULT_NAME`

### Pipeline falha no Azure Login
- Confirme que os valores de AZURE_CLIENT_ID, AZURE_TENANT_ID e AZURE_SUBSCRIPTION_ID estão corretos
- Verifique se o Service Principal tem as permissões necessárias