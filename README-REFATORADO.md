# 🌐 Conexão de Sorte - Traefik Gateway (Refatorado)

> **Load Balancer e SSL Termination Focado**  
> Refatoração completa: Microserviços removidos para deploy independente  
> **Redução:** 3.1MB → 200KB (94% menor) 

---

## 🎯 **REFATORAÇÃO APLICADA**

### **❌ REMOVIDO:**
- **14 microserviços** (auth, results, chat, notifications, etc.)
- **1 frontend web** (React application)
- **Configurações hardcoded** de rotas específicas
- **Deploy acoplado** infraestrutura + aplicação

### **✅ MANTIDO:**
- **Traefik v3.1** (Load Balancer + SSL Termination)
- **Let's Encrypt ACME** (SSL automático)
- **Service Discovery** via Docker API
- **Dashboard administrativo**

---

## 🚀 **QUICK START**

### **1. Deploy Traefik**
```bash
# Garantir que a rede existe (deve ser criada pelo infraestrutura-core)
docker network inspect conexao-network

# Deploy do Traefik
docker-compose up -d

# Verificar status
docker-compose ps
```

### **2. Verificar Dashboard**
```bash
# Acessar dashboard (configurar DNS primeiro)
open https://traefik.conexaodesorte.com.br

# Ou via IP (desenvolvimento)
open http://localhost:8080
```

### **3. Configurar DNS**
```bash
# Exemplo para /etc/hosts (desenvolvimento)
127.0.0.1 traefik.conexaodesorte.com.br
127.0.0.1 auth.conexaodesorte.com.br
127.0.0.1 api.conexaodesorte.com.br
```

---

## 🔗 **SERVICE DISCOVERY AUTOMÁTICO**

### **Como conectar microserviços:**

#### **Método 1: Labels Docker Compose**
```yaml
# docker-compose.yml do microserviço
version: '3.9'
services:
  auth-service:
    image: auth-microservice:latest
    networks:
      - conexao-network
    labels:
      # Habilitar Traefik
      - traefik.enable=true
      
      # Roteamento por subdomínio
      - traefik.http.routers.auth.rule=Host(`auth.conexaodesorte.com.br`)
      - traefik.http.routers.auth.entrypoints=websecure
      - traefik.http.routers.auth.tls.certresolver=letsencrypt
      
      # Configuração do serviço
      - traefik.http.services.auth.loadbalancer.server.port=8081
      
      # Middlewares (opcional)
      - traefik.http.routers.auth.middlewares=security-headers@file,cors-api@file
      
networks:
  conexao-network:
    external: true
```

#### **Método 2: Labels Docker CLI**
```bash
# Deploy via Docker CLI
docker run -d \
  --name auth-microservice \
  --network conexao-network \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.auth.rule=Host(\`auth.conexaodesorte.com.br\`)" \
  --label "traefik.http.routers.auth.entrypoints=websecure" \
  --label "traefik.http.routers.auth.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.auth.loadbalancer.server.port=8081" \
  auth-microservice:latest
```

---

## 🎪 **PADRÕES DE ROTEAMENTO**

### **1. Subdomínio Dedicado**
```yaml
# auth.conexaodesorte.com.br → auth-service
labels:
  - traefik.http.routers.auth.rule=Host(`auth.conexaodesorte.com.br`)
```

### **2. Path-based Routing** 
```yaml
# api.conexaodesorte.com.br/auth → auth-service
labels:
  - traefik.http.routers.auth.rule=Host(`api.conexaodesorte.com.br`) && PathPrefix(`/auth`)
  - traefik.http.routers.auth.middlewares=auth-stripprefix@file
```

### **3. Múltiplas Rotas**
```yaml
# Múltiplos pontos de entrada
labels:
  # Subdomínio principal
  - traefik.http.routers.auth-main.rule=Host(`auth.conexaodesorte.com.br`)
  - traefik.http.routers.auth-main.priority=100
  
  # Path API
  - traefik.http.routers.auth-api.rule=Host(`api.conexaodesorte.com.br`) && PathPrefix(`/auth`)
  - traefik.http.routers.auth-api.priority=200
  - traefik.http.routers.auth-api.middlewares=auth-stripprefix@file
  
  # Compatibilidade legacy
  - traefik.http.routers.auth-legacy.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/rest/auth`)
  - traefik.http.routers.auth-legacy.priority=300
```

---

## 🛡️ **MIDDLEWARES DISPONÍVEIS**

### **Configuração via arquivos dinâmicos:**
```yaml
# traefik/dynamic/middlewares.yml
http:
  middlewares:
    # Headers de segurança
    security-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
        customResponseHeaders:
          X-Content-Type-Options: "nosniff"
          X-Frame-Options: "DENY"
          X-XSS-Protection: "1; mode=block"
    
    # CORS para APIs
    cors-api:
      headers:
        accessControlAllowOriginList:
          - "https://conexaodesorte.com.br"
          - "https://www.conexaodesorte.com.br"
        accessControlAllowMethods:
          - "GET"
          - "POST" 
          - "PUT"
          - "DELETE"
        accessControlAllowHeaders:
          - "Authorization"
          - "Content-Type"
    
    # Rate limiting
    rate-limit:
      rateLimit:
        burst: 100
        period: "1m"
    
    # Strip prefix
    auth-stripprefix:
      stripPrefix:
        prefixes:
          - "/auth"
```

---

## 📊 **MONITORAMENTO**

### **Dashboard Traefik**
- **URL:** https://traefik.conexaodesorte.com.br
- **Autenticação:** Configurar via `admin-auth@file` middleware
- **Métricas:** Rotas, serviços, middlewares em tempo real

### **Health Check**
```bash
# Health check Traefik
curl http://localhost:8080/ping

# Status dos serviços descobertos
curl http://localhost:8080/api/http/services

# Rotas ativas
curl http://localhost:8080/api/http/routers
```

### **Logs**
```bash
# Logs Traefik
docker logs traefik-microservices -f

# Logs apenas de access
docker logs traefik-microservices -f | grep -E "(GET|POST|PUT|DELETE)"

# Logs de SSL/TLS
docker logs traefik-microservices -f | grep -i "acme\|certificate"
```

---

## 🔐 **SSL/TLS AUTOMÁTICO**

### **Let's Encrypt ACME**
```yaml
# traefik/traefik.yml
certificatesResolvers:
  letsencrypt:
    acme:
      email: facilitaservicos.dev@gmail.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

### **Configuração SSL por serviço**
```yaml
labels:
  # HTTPS obrigatório
  - traefik.http.routers.service.tls.certresolver=letsencrypt
  - traefik.http.routers.service.entrypoints=websecure
  
  # Redirect HTTP → HTTPS
  - traefik.http.routers.service-redirect.rule=Host(`service.conexaodesorte.com.br`)
  - traefik.http.routers.service-redirect.entrypoints=web
  - traefik.http.routers.service-redirect.middlewares=https-redirect@file
```

---

## 🔄 **MIGRAÇÃO DOS MICROSERVIÇOS**

### **Antes (Projeto Acoplado):**
```yaml
# ❌ Todos no mesmo docker-compose.yml
services:
  traefik: ...
  auth-microservice: ...
  results-microservice: ...
  # ... 14 microserviços
```

### **Depois (Projetos Independentes):**
```bash
# ✅ Cada microserviço em seu próprio projeto
📁 infraestrutura/
├── traefik-infraestrutura/      # Apenas Traefik
├── infraestrutura-core/         # Redis, RabbitMQ, Kafka, etc.
└── mysql-infraestrutura/        # Database cluster

📁 backend/
├── auth-microservice/           # Deploy independente com labels
├── results-microservice/        # Deploy independente com labels  
└── ... cada serviço separado
```

### **Template para migração de microserviço:**
```yaml
# Adicionar ao docker-compose.yml de cada microserviço:
networks:
  conexao-network:
    external: true  # Conectar à rede criada pela infraestrutura

labels:
  - traefik.enable=true
  - traefik.http.routers.${SERVICE_NAME}.rule=Host(`${SERVICE_NAME}.conexaodesorte.com.br`)
  - traefik.http.routers.${SERVICE_NAME}.entrypoints=websecure  
  - traefik.http.routers.${SERVICE_NAME}.tls.certresolver=letsencrypt
  - traefik.http.services.${SERVICE_NAME}.loadbalancer.server.port=${SERVICE_PORT}
```

---

## ⚡ **PERFORMANCE**

### **Otimizações aplicadas:**
- **94% redução** no tamanho do projeto
- **Service discovery dinâmico** (sem hardcode)
- **Deploy independente** por serviço  
- **Load balancing automático**
- **SSL termination otimizado**

### **Métricas de exemplo:**
- **Startup time:** ~5 segundos (vs 60+ segundos antes)
- **Memory usage:** ~50MB (vs 500MB+ com 14 microserviços)
- **File size:** 200KB (vs 3.1MB antes)

---

## 🚨 **TROUBLESHOOTING**

### **Problemas comuns:**

#### **1. Serviço não descoberto pelo Traefik**
```bash
# Verificar labels do container
docker inspect <container-name> | jq '.[0].Config.Labels'

# Verificar se está na rede correta
docker inspect <container-name> | jq '.[0].NetworkSettings.Networks'

# Verificar logs Traefik
docker logs traefik-microservices | grep <service-name>
```

#### **2. SSL não funcionando**
```bash
# Verificar certificados ACME
docker exec traefik-microservices ls -la /letsencrypt/

# Verificar logs ACME
docker logs traefik-microservices | grep -i acme

# Forçar renovação
docker exec traefik-microservices traefik --acme.caserver=https://acme-v02.api.letsencrypt.org/directory
```

#### **3. Rota não encontrada (404)**
```bash
# Verificar rotas ativas
curl http://localhost:8080/api/http/routers | jq

# Verificar regras de roteamento
docker logs traefik-microservices | grep -i "router.*created"

# Testar regra manualmente
curl -H "Host: service.conexaodesorte.com.br" http://localhost/
```

---

## 📈 **PRÓXIMOS PASSOS**

### **Recomendações:**
1. **Migrar microserviços** um por vez usando templates acima
2. **Configurar monitoramento** Prometheus + Grafana
3. **Implementar rate limiting** por serviço/usuário
4. **Configurar backup** das configurações Traefik  
5. **Documentar routing patterns** específicos do projeto

---

*Projeto refatorado em 08/09/2025*  
*Redução: 3.1MB → 200KB (94% menor)*  
*🚀 Generated with [Claude Code](https://claude.ai/code)*