# 🚀 Conexão de Sorte - Guia de Deploy Completo

## 📋 Resumo Executivo

Este guia implementa a **ESTRATÉGIA RECOMENDADA** para deploy dos microserviços, corrigindo todos os conflitos de porta identificados e estabelecendo uma ordem lógica de deployment.

## 🔧 Correções Implementadas

### ✅ Conflitos de Porta Resolvidos

| **Serviço** | **Porta Anterior** | **Porta Nova** | **Status** |
|-------------|-------------------|----------------|------------|
| `crypto-kms-microservice` | 8084 (conflito) | **8082** | ✅ Corrigido |
| `scheduler-extractions-microservice` | 8088 (conflito) | **8091** | ✅ Corrigido |
| `observability-diagnostics-microservice` | 8086 (conflito) | **8092** | ✅ Corrigido |
| `chat-microservice` | 8079 (mismatch) | **8083** | ✅ Corrigido |

### ✅ Serviços Adicionados

- **`user-microservice`**: Porta 8089, subdomínio `users.conexaodesorte.com.br`
- **`chatbot-microservice`**: Porta 8087, subdomínio `chatbot.conexaodesorte.com.br`

### ✅ Mapeamento Final de Portas

| **Serviço** | **Porta** | **Subdomínio** | **Status** |
|--------------|-----------|----------------|------------|
| Traefik | 80, 443, 8080 | `traefik.conexaodesorte.com.br` | ✅ |
| Frontend | 3000 | `www.conexaodesorte.com.br` | ✅ |
| Auth | 8081 | `auth.conexaodesorte.com.br` | ✅ |
| Users | 8089 | `users.conexaodesorte.com.br` | ✅ |
| Crypto-KMS | 8082 | `crypto-kms.conexaodesorte.com.br` | ✅ |
| Chat | 8083 | `chat.conexaodesorte.com.br` | ✅ |
| Notifications | 8084 | `notifications.conexaodesorte.com.br` | ✅ |
| Audit | 8085 | `audit.conexaodesorte.com.br` | ✅ |
| Chatbot | 8087 | `chatbot.conexaodesorte.com.br` | ✅ |
| Scheduler-Extractions | 8091 | `scheduler-extractions.conexaodesorte.com.br` | ✅ |
| Observability-Diag | 8092 | `monitoring-diag.conexaodesorte.com.br` | ✅ |

## 🏗️ Ordem de Deploy Implementada

### **FASE 1 - Infraestrutura Base**
```bash
# 1. Traefik (Load Balancer)
docker-compose up -d traefik
```

### **FASE 2 - Serviços Core**
```bash
# 2. Autenticação (primeiro - outros dependem)
docker-compose up -d auth-microservice

# 3. Usuário (dependência para chat/notificações)
docker-compose up -d user-microservice

# 4. Criptografia KMS (dependência de segurança)
docker-compose up -d crypto-kms-microservice
```

### **FASE 3 - Serviços de Aplicação**
```bash
# 5. Notificações
docker-compose up -d notifications-microservice

# 6. Chat/Bate-papo
docker-compose up -d chat-microservice

# 7. Auditoria
docker-compose up -d audit-microservice
```

### **FASE 4 - Aplicações Finais**
```bash
# 8. Frontend
docker-compose up -d frontend-web

# 9. Chatbot
docker-compose up -d chatbot-microservice
```

## 🚀 Executando o Deploy

### **Pré-requisitos**

1. **Docker e Docker Compose** instalados
2. **Rede Docker** criada:
   ```bash
   docker network create conexao-network
   ```

3. **Variáveis de ambiente** configuradas:
   ```bash
   export AZURE_CLIENT_ID="your-client-id"
   export AZURE_TENANT_ID="your-tenant-id"
   export AZURE_KEYVAULT_ENDPOINT="https://your-vault.vault.azure.net/"
   ```

### **Deploy Automático** ⭐

Execute o script de deploy estratégico:

```bash
cd conexao-de-sorte-traefik-infrastructure
./deploy-strategy.sh
```

### **Deploy Manual**

Se preferir controle total, execute fase por fase:

```bash
# FASE 1: Infraestrutura
docker-compose up -d traefik

# FASE 2: Core (aguarde cada serviço ficar healthy)
docker-compose up -d auth-microservice
docker-compose up -d user-microservice  
docker-compose up -d crypto-kms-microservice

# FASE 3: Aplicação
docker-compose up -d notifications-microservice
docker-compose up -d chat-microservice
docker-compose up -d audit-microservice

# FASE 4: Final
docker-compose up -d frontend-web
docker-compose up -d chatbot-microservice
```

## 🔍 Verificação do Deploy

### **Health Checks**
```bash
# Status geral
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Health checks específicos
docker ps --filter health=healthy
docker ps --filter health=unhealthy
```

### **URLs de Teste**

- **Frontend**: https://www.conexaodesorte.com.br
- **API Gateway**: https://api.conexaodesorte.com.br
- **Auth Service**: https://auth.conexaodesorte.com.br
- **Users Service**: https://users.conexaodesorte.com.br
- **Chat Service**: https://chat.conexaodesorte.com.br
- **Notifications**: https://notifications.conexaodesorte.com.br
- **Crypto KMS**: https://crypto-kms.conexaodesorte.com.br
- **Audit Service**: https://audit.conexaodesorte.com.br
- **Chatbot**: https://chatbot.conexaodesorte.com.br
- **Traefik Dashboard**: https://traefik.conexaodesorte.com.br

## 🛡️ Segurança Implementada

### **HTTPS Automático**
- Certificados Let's Encrypt automáticos
- Redirecionamento HTTP → HTTPS
- HSTS headers configurados

### **Rate Limiting**
- Rate limiting por serviço
- Proteção contra DDoS
- Circuit breaker patterns

### **Autenticação**
- Azure Key Vault para secrets
- OIDC para autenticação
- Basic auth para serviços administrativos

### **Security Headers**
- XSS Protection
- Content Security Policy  
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff

## 🔧 Monitoramento

### **Logs**
```bash
# Logs de todos os serviços
docker-compose logs -f

# Logs de serviço específico
docker-compose logs -f auth-microservice

# Logs do Traefik
docker logs traefik-microservices -f
```

### **Métricas**
- Prometheus: http://servidor:9090
- Grafana: http://servidor:3000  
- Health endpoints: `/actuator/health`

## 🚨 Troubleshooting

### **Problemas Comuns**

1. **Conflito de Porta**
   ```bash
   # Verificar portas em uso
   netstat -tlnp | grep :808[0-9]
   
   # Parar serviços conflitantes
   docker stop $(docker ps -q --filter name=conexao)
   ```

2. **Health Check Falhando**
   ```bash
   # Verificar logs do serviço
   docker logs container-name --tail 50
   
   # Testar health endpoint
   curl -f http://localhost:8081/actuator/health
   ```

3. **Azure Key Vault**
   ```bash
   # Verificar variáveis de ambiente
   env | grep AZURE
   
   # Testar conectividade
   az keyvault secret list --vault-name your-vault
   ```

### **Rollback**
```bash
# Parar todos os serviços
docker-compose down

# Remover volumes (cuidado!)
docker-compose down -v

# Deploy da versão anterior
git checkout previous-version
./deploy-strategy.sh
```

## 📞 Suporte

Em caso de problemas:

1. **Consulte logs**: `deploy.log` 
2. **Verifique health checks**: `docker ps`
3. **Teste conectividade**: URLs listadas acima
4. **Rollback se necessário**: Comandos na seção troubleshooting

---

**✨ Deploy implementado com sucesso seguindo todas as melhores práticas de microserviços e DevOps!**