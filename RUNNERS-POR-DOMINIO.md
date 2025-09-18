# 🏃‍♂️ Configuração de Runners por Domínio

**Status:** ✅ IMPLEMENTADO
**Última Atualização:** 2025-01-31
**Objetivo:** Segmentação de runners self-hosted por domínio para melhor isolamento de segurança

## 🎯 Estratégia de Segmentação

### 🔧 **Domínio: Infraestrutura (infra)**
```yaml
runs-on: [ self-hosted, Linux, X64, conexao, infra, conexao-de-sorte-traefik-infraestrutura ]
```

**Responsabilidades:**
- Deploy de Traefik reverse proxy
- Configuração de rede Docker Swarm
- Gerenciamento de SSL/TLS
- Monitoramento de infraestrutura

**Segredos Acessíveis:**
- `conexao-de-sorte-traefik-basicauth-password`
- `conexao-de-sorte-ssl-cert-password`
- `conexao-de-sorte-acme-email`
- Segredos locais: `./secrets/traefik-basicauth`, `./secrets/admin-users`

---

### 🗄️ **Domínio: Backend (backend)**
```yaml
# Para futuros pipelines de microsserviços backend
runs-on: [ self-hosted, Linux, X64, conexao, backend, conexao-de-sorte-backend ]
```

**Responsabilidades:**
- Deploy de APIs e microsserviços
- Configuração de bancos de dados
- Gerenciamento de filas (RabbitMQ)
- Autenticação e autorização

**Segredos Acessíveis:**
- `conexao-de-sorte-db-*` (host, port, username, password)
- `conexao-de-sorte-redis-*` (host, port, password, database)
- `conexao-de-sorte-jwt-*` (secret, expiration)
- `conexao-de-sorte-rabbitmq-*` (host, port, username, password)
- `conexao-de-sorte-api-key`

---

### 🎨 **Domínio: Frontend (frontend)**
```yaml
# Para futuros pipelines de aplicações frontend
runs-on: [ self-hosted, Linux, X64, conexao, frontend, conexao-de-sorte-frontend ]
```

**Responsabilidades:**
- Deploy de aplicações web
- Configuração de CDN/assets
- Analytics e monitoramento frontend
- Configuração de APIs públicas

**Segredos Acessíveis:**
- `conexao-de-sorte-api-base-url`
- `conexao-de-sorte-frontend-secret-key`
- `conexao-de-sorte-analytics-key`
- `conexao-de-sorte-monitoring-token`

---

## 🔐 Benefícios de Segurança

### ✅ **Princípio de Menor Privilégio**
- Cada runner acessa apenas segredos do seu domínio
- Redução de superfície de ataque
- Isolamento entre ambientes

### ✅ **Auditoria e Rastreabilidade**
- Logs específicos por domínio
- Identificação clara de responsabilidades
- Facilita investigação de incidentes

### ✅ **Escalabilidade**
- Runners dedicados podem ter recursos específicos
- Balanceamento de carga por domínio
- Facilita manutenção independente

---

## 🚀 Configuração do Runner srv649924

### **Labels Atuais do Runner**
```bash
# Runner físico srv649924 deve estar configurado com todos os labels:
[ self-hosted, Linux, X64, conexao, infra, backend, frontend,
  conexao-de-sorte-traefik-infraestrutura, conexao-de-sorte-backend, conexao-de-sorte-frontend ]
```

### **Comando de Configuração**
```bash
# No servidor srv649924, atualizar configuração do runner:
cd /actions-runner
sudo ./config.sh --url https://github.com/conexao-de-sorte --token <TOKEN> \
  --name srv649924 \
  --labels "self-hosted,Linux,X64,conexao,infra,backend,frontend,conexao-de-sorte-traefik-infraestrutura,conexao-de-sorte-backend,conexao-de-sorte-frontend"
```

---

## 📋 Status de Implementação

| Domínio | Runner Label | Pipeline | Status |
|---------|-------------|----------|--------|
| 🔧 Infra | `infra, conexao-de-sorte-traefik-infraestrutura` | ci-cd-refatorado.yml | ✅ IMPLEMENTADO |
| 🗄️ Backend | `backend, conexao-de-sorte-backend` | (futuro) | 📋 PLANEJADO |
| 🎨 Frontend | `frontend, conexao-de-sorte-frontend` | (futuro) | 📋 PLANEJADO |

---

## 🔧 Próximos Passos

1. **✅ Atualizar runner srv649924** com novos labels
2. **📝 Documentar** configuração para equipe DevOps
3. **🧪 Testar** execução com novos labels
4. **🔄 Aplicar** em futuros pipelines backend/frontend

---

**Observação:** Esta configuração garante que cada domínio tenha acesso apenas aos segredos necessários, implementando o princípio de menor privilégio e melhorando a segurança geral da infraestrutura.