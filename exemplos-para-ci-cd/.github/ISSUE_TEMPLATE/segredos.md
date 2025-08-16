---
name: 🔐 Configuração de Segredos
about: Checklist para configuração de segredos Azure Key Vault e GitHub Actions
title: '[SEGREDOS] Configurar segredos para ambiente [DEV/PROD]'
labels: ['segurança', 'configuração', 'azure', 'github-actions']
assignees: ''
---

# 🔐 Checklist de Configuração de Segredos

## 📋 Informações do Issue

**Ambiente:** [ ] Desenvolvimento [ ] Produção [ ] Ambos  
**Prioridade:** [ ] Baixa [ ] Média [ ] Alta [ ] Crítica  
**Data Limite:** ___/___/____  

---

## 🎯 Azure Key Vault

### **Pré-requisitos**
- [ ] Azure CLI instalado e autenticado
- [ ] Permissões no Azure Key Vault
- [ ] Service Principal criado
- [ ] Variáveis de ambiente Azure configuradas

### **Configuração do Service Principal**
```bash
# Executar no Azure CLI
az ad sp create-for-rbac --name "conexao-de-sorte-[env]" \
  --role "Key Vault Secrets User" \
  --scopes "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<vault-name>"
```

**Resultado:**
- [ ] `AZURE_TENANT_ID` obtido
- [ ] `AZURE_CLIENT_ID` obtido  
- [ ] `AZURE_CLIENT_SECRET` obtido
- [ ] `AZURE_KEYVAULT_ENDPOINT` configurado

### **Segredos JWT**
- [ ] `jwt-secret` - Chave secreta JWT (256 bits)
- [ ] `jwt-private-key` - Chave privada RSA (2048 bits)
- [ ] `jwt-public-key` - Chave pública RSA
- [ ] `conexao-de-sorte-jwt-algorithm` - Algoritmo (RS256)
- [ ] `conexao-de-sorte-jwt-issuer` - Emissor JWT
- [ ] `conexao-de-sorte-jwt-audience` - Audiência JWT

**Comandos para gerar chaves JWT:**
```bash
# Gerar par de chaves RSA
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem

# Adicionar ao Key Vault
az keyvault secret set --vault-name <vault> --name "jwt-private-key" --file private.pem
az keyvault secret set --vault-name <vault> --name "jwt-public-key" --file public.pem
az keyvault secret set --vault-name <vault> --name "jwt-secret" --value "<random-256-bit-key>"
```

### **Segredos de Banco de Dados**
- [ ] `conexao-de-sorte-database-username` - Usuário do banco
- [ ] `conexao-de-sorte-database-password` - Senha do banco
- [ ] `conexao-de-sorte-database-url` - URL de conexão (se necessário)

### **Segredos OAuth2**
- [ ] `conexao-de-sorte-security-oauth2-client-id` - Client ID OAuth2
- [ ] `conexao-de-sorte-security-oauth2-client-secret` - Client Secret OAuth2

---

## 🐙 GitHub Actions Secrets

### **Pré-requisitos**
- [ ] GitHub CLI instalado e autenticado
- [ ] Permissões no repositório GitHub
- [ ] Acesso aos segredos do Azure Key Vault

### **Segredos Azure (para CI/CD)**
- [ ] `AZURE_TENANT_ID`
- [ ] `AZURE_CLIENT_ID`
- [ ] `AZURE_CLIENT_SECRET`
- [ ] `AZURE_KEYVAULT_ENDPOINT`

### **Segredos de Banco de Dados (Fallback)**
- [ ] `CONEXAO_DE_SORTE_DATABASE_USERNAME`
- [ ] `CONEXAO_DE_SORTE_DATABASE_PASSWORD`

### **Segredos JWT (Fallback)**
- [ ] `JWT_SECRET`
- [ ] `JWT_PRIVATE_KEY`
- [ ] `JWT_PUBLIC_KEY`

### **Segredos Docker Hub**
- [ ] `DOCKER_USERNAME`
- [ ] `DOCKER_PASSWORD`

### **Segredos de Qualidade (Opcional)**
- [ ] `SONAR_TOKEN`
- [ ] `CODECOV_TOKEN`

### **Segredos de Deploy (se aplicável)**
- [ ] `SSH_PRIVATE_KEY`
- [ ] `VPS_HOST`
- [ ] `VPS_USER`

**Comandos para configurar GitHub Secrets:**
```bash
# Instalar GitHub CLI
brew install gh  # macOS
sudo apt install gh  # Linux

# Autenticar
gh auth login

# Definir secrets
gh secret set AZURE_TENANT_ID --body "<tenant-id>" --repo <user>/<repo>
gh secret set AZURE_CLIENT_ID --body "<client-id>" --repo <user>/<repo>
# ... outros secrets
```

---

## 🔄 Sincronização Automatizada

### **Script de Sincronização**
- [ ] Executar `chmod +x ops/update-secrets.sh`
- [ ] Testar com `./ops/update-secrets.sh check`
- [ ] Sincronizar com `./ops/update-secrets.sh sync`
- [ ] Gerar relatório com `./ops/update-secrets.sh report`

### **Validação**
- [ ] Pipeline CI/CD executando sem erros
- [ ] Aplicação conectando ao Azure Key Vault
- [ ] JWT funcionando corretamente
- [ ] Banco de dados acessível
- [ ] OAuth2 configurado (se aplicável)

---

## 🧪 Testes de Validação

### **Ambiente Local**
```bash
# Testar profile dev
./mvnw spring-boot:run -Dspring.profiles.active=dev

# Testar conexão com Key Vault
curl -H "Authorization: Bearer <token>" http://localhost:8080/actuator/health
```

### **Pipeline CI/CD**
```bash
# Executar pipeline manualmente
gh workflow run ci.yml

# Verificar logs
gh run list --limit 1
gh run view <run-id>
```

### **Testes de Integração**
```bash
# Executar testes com Testcontainers
./mvnw clean verify -Dspring.profiles.active=test

# Verificar cobertura
./mvnw jacoco:report
```

---

## 📚 Documentação

### **Links Úteis**
- [Azure Key Vault Spring Boot](https://docs.microsoft.com/en-us/azure/developer/java/spring-framework/configure-spring-boot-starter-java-app-with-azure-key-vault)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)

### **Arquivos Relacionados**
- `src/main/resources/application-azure.yml`
- `src/main/resources/application-dev.yml`
- `ops/update-secrets.sh`
- `.github/workflows/ci.yml`

---

## ✅ Critérios de Aceitação

- [ ] Todos os segredos necessários configurados no Azure Key Vault
- [ ] Todos os segredos necessários configurados no GitHub Actions
- [ ] Script de sincronização funcionando
- [ ] Pipeline CI/CD executando sem erros relacionados a segredos
- [ ] Aplicação funcionando em ambiente de desenvolvimento
- [ ] Aplicação funcionando em ambiente de produção
- [ ] Documentação atualizada
- [ ] Testes de validação passando

---

## 🚨 Observações de Segurança

⚠️ **IMPORTANTE:**
- Nunca commitar segredos no código
- Usar princípio do menor privilégio
- Rotacionar chaves regularmente
- Monitorar acesso aos segredos
- Usar HTTPS sempre
- Validar certificados SSL/TLS

---

## 📞 Suporte

**Em caso de problemas:**
1. Verificar logs da aplicação
2. Verificar logs do pipeline CI/CD
3. Verificar permissões no Azure
4. Verificar permissões no GitHub
5. Consultar documentação oficial
6. Abrir issue de suporte se necessário
