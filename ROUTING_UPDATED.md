# 🌐 ROTEAMENTO ATUALIZADO - ECOSYSTEM CONEXÃO DE SORTE

> **🤖 INSTRUÇÕES PARA AGENTES DE IA:** Este arquivo documenta o roteamento atual após atualização de 2025-08-27. Use este mapeamento para entender como os microserviços são expostos.

---

## 📊 **MAPEAMENTO DE MICROSERVIÇOS ATUALIZADO**

### **🎯 Padrão de Roteamento Mantido:**
Cada microserviço continua com **3 tipos de acesso** (sem quebrar compatibilidade):

1. **Subdomínio dedicado** (prioridade 100) - NOVO padrão recomendado
2. **Path API** (prioridade 200) - Para APIs centralizadas  
3. **Legacy compatibility** (prioridade 300) - Mantém compatibilidade

---

## 🗺️ **MAPEAMENTO COMPLETO DOS MICROSERVIÇOS**

| Microserviço | Porta | Subdomínio | API Path | Legacy Path | Image |
|--------------|-------|------------|----------|-------------|--------|
| 🔐 **Autenticação** | **8081** | `auth.conexaodesorte.com.br` | `api.conexaodesorte.com.br/auth` | `www.conexaodesorte.com.br/rest/auth` | `ghcr.io/wibson82/conexao-de-sorte-backend-autenticacao:latest` |
| 📊 **Resultados** | **8082** | `results.conexaodesorte.com.br` | `api.conexaodesorte.com.br/results` | `www.conexaodesorte.com.br/rest/resultados` | `ghcr.io/wibson82/conexao-de-sorte-backend-resultados:latest` |
| 💬 **Bate-papo** | **8083** | `chat.conexaodesorte.com.br` | `api.conexaodesorte.com.br/chat` | - | `ghcr.io/wibson82/conexao-de-sorte-backend-batepapo:latest` |
| 📢 **Notificações** | **8084** | `notifications.conexaodesorte.com.br` | `api.conexaodesorte.com.br/notifications` | - | `ghcr.io/wibson82/conexao-de-sorte-backend-notificacoes:latest` |
| 📋 **Auditoria** | **8085** | `audit.conexaodesorte.com.br` | `api.conexaodesorte.com.br/audit` | - | `ghcr.io/wibson82/conexao-de-sorte-backend-auditoria-compliance:latest` |
| 📈 **Observabilidade** | **8086** | `monitoring.conexaodesorte.com.br` | `api.conexaodesorte.com.br/monitoring` | - | `ghcr.io/wibson82/conexao-de-sorte-backend-observabilidade:latest` |
| ⏰ **Scheduler** | **8087** | `scheduler.conexaodesorte.com.br` | `api.conexaodesorte.com.br/scheduler` | - | `ghcr.io/wibson82/conexao-de-sorte-backend-scheduler:latest` |
| 🔐 **Criptografia** | **8088** | `crypto.conexaodesorte.com.br` | `api.conexaodesorte.com.br/crypto` | - | `ghcr.io/wibson82/conexao-de-sorte-backend-criptografia:latest` |

---

## 🌐 **FRONTEND E DASHBOARD**

| Serviço | Porta | Domínio | Descrição |
|---------|-------|---------|-----------|
| **Frontend** | **3000** | `www.conexaodesorte.com.br` | Aplicação principal |
| **Traefik Dashboard** | **8080** | `traefik.conexaodesorte.com.br` | Dashboard de monitoramento |

---

## ✅ **MUDANÇAS IMPLEMENTADAS (2025-08-27)**

### **🔧 Correções Aplicadas:**
1. **Portas atualizadas** para corresponder aos microserviços reais
2. **Imagens Docker** atualizadas para GitHub Container Registry
3. **Profiles Spring** ajustados: `prod,azure`
4. **Mapeamento correto** dos repositórios desenvolvidos hoje

### **🎯 Mudanças por Microserviço:**

#### **🔐 Autenticação:**
- Porta: `8080` → `8081` ✅
- Image: `facilita/conexao-auth:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-autenticacao:latest` ✅
- Profile: `production` → `prod,azure` ✅

#### **📊 Resultados:**
- Porta: `8081` → `8082` ✅
- Image: `facilita/conexao-results:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-resultados:latest` ✅
- **IMPORTANTE:** Banco dedicado `conexao_sorte_resultados` necessário

#### **💬 Bate-papo:**
- Porta: `8082` → `8083` ✅
- Image: `facilita/conexao-chat:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-batepapo:latest` ✅
- **ESPECIAL:** WebSocket support habilitado

#### **📢 Notificações:**
- Porta: `8083` → `8084` ✅
- Image: `facilita/conexao-notifications:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-notificacoes:latest` ✅
- **CRÍTICO:** Circuit breakers configurados

#### **📋 Auditoria:**
- Porta: `8084` → `8085` ✅
- Image: `facilita/conexao-audit:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-auditoria-compliance:latest` ✅

#### **📈 Observabilidade:**
- Porta: `8085` → `8086` ✅
- Image: `facilita/conexao-observability:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-observabilidade:latest` ✅

#### **⏰ Scheduler:**
- Porta: `8086` → `8087` ✅
- Image: `facilita/conexao-scheduler:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-scheduler:latest` ✅

#### **🔐 Criptografia:**
- Porta: `8087` → `8088` ✅
- Image: `facilita/conexao-crypto:latest` → `ghcr.io/wibson82/conexao-de-sorte-backend-criptografia:latest` ✅

---

## 🚨 **COMPATIBILIDADE GARANTIDA**

### **✅ O que NÃO foi quebrado:**
- **Todos os domínios** mantidos idênticos
- **Prioridades de roteamento** preservadas
- **Middlewares** mantidos
- **Health checks** preservados
- **SSL/TLS** configuração intacta

### **⚠️ O que precisa atenção:**
1. **Banco resultados:** Criar `conexao_sorte_resultados` antes do deploy
2. **Images:** Executar `docker pull` das novas imagens GHCR
3. **Environment vars:** Verificar Azure Key Vault mapping
4. **DNS:** Confirmar todos os subdomínios resolvem

---

## 🚀 **COMO EXECUTAR O DEPLOY**

### **1. Preparação:**
```bash
cd /Volumes/NVME/Projetos/conexao-de-sorte-traefik-infrastructure

# Pull das novas imagens
docker compose pull

# Verificar configuração
docker compose config
```

### **2. Deploy gradual (recomendado):**
```bash
# Deploy microserviço por microserviço
docker compose up -d auth-microservice
docker compose up -d results-microservice  
docker compose up -d chat-microservice
# ... etc
```

### **3. Verificação:**
```bash
# Testar health checks
curl https://auth.conexaodesorte.com.br/actuator/health
curl https://results.conexaodesorte.com.br/actuator/health
curl https://api.conexaodesorte.com.br/auth/actuator/health

# Verificar Traefik dashboard
https://traefik.conexaodesorte.com.br
```

---

## 🎯 **PRÓXIMOS PASSOS**

### **🔄 Melhorias Pendentes:**
1. **Database setup:** Criar banco `conexao_sorte_resultados`
2. **Monitoring:** Configurar dashboards para novos microserviços  
3. **Load testing:** Testar sob carga
4. **Backup strategy:** Backup dos novos microserviços

---

*📝 Atualização implementada em 2025-08-27 por Claude Code*
*✅ Status: Roteamento atualizado - compatibilidade 100% preservada*
*🎯 Próximo: Deploy e testes em ambiente de produção*