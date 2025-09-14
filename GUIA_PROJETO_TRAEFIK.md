# 🌐 Guia do Projeto: Traefik Infrastructure
## Reverse Proxy e Load Balancer

> **🎯 Contexto**: Infraestrutura crítica responsável por roteamento HTTP/HTTPS, terminação SSL, load balancing e gateway de entrada para todos os microserviços da plataforma.

---

## 📋 INFORMAÇÕES DO PROJETO

### **Identificação:**
- **Nome**: conexao-de-sorte-traefik-infraestrutura
- **Portas**: 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Redes**: conexao-network-swarm (principal) + conexao-network (legado)
- **Versão**: Traefik v3.5.2
- **Runner**: `[self-hosted, Linux, X64, conexao, conexao-de-sorte-traefik-infraestrutura]`

### **Tecnologias Específicas:**
- Traefik v3.5.2 (Edge Router)
- Docker Swarm Services (orquestração)
- Let's Encrypt (certificados automáticos)
- Azure Key Vault (secrets management)
- Configuração dinâmica via arquivos

---

## 🏗️ ARQUITETURA DE REDE

### **Estratégia Híbrida:**
- **Swarm Provider**: Detecta novos serviços Docker Swarm
- **Docker Provider**: Suporte a containers legados
- **File Provider**: Configurações estáticas e dinâmicas

### **Redes Docker:**
```yaml
# Principal (Swarm)
conexao-network-swarm:
  driver: overlay
  scope: swarm
  
# Legado (Bridge) - conectado manualmente pós-deploy  
conexao-network:
  driver: bridge
  scope: local
```

### **Estratégia de Conectividade:**
1. **Deploy**: Traefik inicia na rede Swarm
2. **Pós-Deploy**: Conecta manualmente à rede legado
3. **Auto-Discovery**: Detecta serviços em ambas as redes

---

## 🔐 SECRETS ESPECÍFICOS

### **Azure Key Vault Secrets Utilizados:**
```yaml
# Traefik Authentication
conexao-de-sorte-traefik-admin-password
conexao-de-sorte-traefik-dashboard-password
conexao-de-sorte-traefik-crypto-password
conexao-de-sorte-traefik-audit-password

# SSL/TLS
conexao-de-sorte-letsencrypt-email
conexao-de-sorte-ssl-enabled
conexao-de-sorte-ssl-keystore-password
conexao-de-sorte-ssl-keystore-path

# OIDC & Azure
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID  
AZURE_KEYVAULT_ENDPOINT
```

### **Docker Swarm Secrets:**
```bash
# Gerados automaticamente no pipeline:
traefik_dashboard_user
traefik_dashboard_password
letsencrypt_email
domain_name
```

---

## 🌍 DOMÍNIOS E ROTEAMENTO

### **Domínios Configurados:**
```yaml
# Frontend
conexaodesorte.com.br → Frontend (port 3000)

# Backend APIs  
api.conexaodesorte.com.br → Gateway (port 8080)

# Backend Legado
conexaodesorte.com.br/rest/ → Backend Legado (port 8080)
www.conexaodesorte.com.br/rest/ → Backend Legado (port 8080)

# Infrastructure
traefik.conexaodesorte.com.br → Traefik Dashboard (port 8080)
```

### **Certificados SSL:**
- **Provider**: Let's Encrypt (ACME HTTP-01)
- **Renewal**: Automático via Traefik
- **Storage**: `/etc/traefik/certs/acme.json`
- **Wildcard**: Não configurado (subdomínios específicos)

---

## ⚙️ CONFIGURAÇÃO TRAEFIK

### **Providers Configurados:**
```yaml
# Swarm Provider (novos serviços)
--providers.swarm=true
--providers.swarm.network=conexao-network-swarm
--providers.swarm.exposedbydefault=false

# Docker Provider (containers legados)
--providers.docker=true  
--providers.docker.exposedbydefault=false
--providers.docker.watch=true

# File Provider (configurações estáticas)
--providers.file.directory=/etc/traefik/dynamic
--providers.file.watch=true
```

### **Entrypoints:**
```yaml
# HTTP (redirect to HTTPS)
--entrypoints.web.address=:80

# HTTPS (principal)  
--entrypoints.websecure.address=:443

# ACME Challenge
--certificatesresolvers.letsencrypt.acme.httpchallenge=true
--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
```

---

## 🛡️ SEGURANÇA CONFIGURADA

### **Security Score Validation:**
O pipeline valida configurações obrigatórias:
- ✅ HTTPS obrigatório (websecure)
- ✅ Let's Encrypt configurado  
- ✅ Security headers
- ✅ Rate limiting
- ✅ TLS versão mínima (1.2)
- ✅ Access logs habilitados

### **Middlewares de Segurança:**
```yaml
# Security Headers
security-headers:
  headers:
    frameDeny: true
    contentTypeNosniff: true
    referrerPolicy: "strict-origin-when-cross-origin"
    
# Rate Limiting
rate-limit:
  rateLimit:
    burst: 100
    average: 50
    
# Authentication (para serviços críticos)
crypto-auth:
  basicAuth:
    users: ["crypto:$bcrypt_hash"]
```

---

## 📊 MÉTRICAS E OBSERVABILIDADE

### **Endpoints Monitorados:**
```yaml
# Traefik API
http://localhost:8080/api/overview
http://localhost:8080/api/routers
http://localhost:8080/api/services
http://localhost:8080/api/middlewares

# Health Check
http://localhost:8080/ping

# Metrics (se habilitado)
http://localhost:8080/metrics
```

### **Custom Metrics:**
- `traefik_router_requests_total{router}` - Requests por rota
- `traefik_service_requests_total{service}` - Requests por serviço
- `traefik_http_request_duration_seconds` - Latência HTTP
- `traefik_config_reloads_total` - Reloads de configuração
- `traefik_tls_certs_not_after` - Expiração certificados

---

## 🔧 CONFIGURAÇÕES DINÂMICAS

### **Estrutura de Arquivos:**
```bash
traefik/
├── traefik.yml                 # Configuração principal
└── dynamic/
    ├── middlewares.yml         # Middlewares globais
    ├── security-headers.yml    # Headers de segurança
    ├── tls.yml                 # Configuração TLS
    └── legacy-backend.yml      # Roteamento backend legado (gerado)
```

### **Configuração Legado (Gerada Dinamicamente):**
```yaml
# legacy-backend.yml (gerado pelo pipeline)
http:
  routers:
    backend-legacy:
      rule: "Host(`conexaodesorte.com.br`) && PathPrefix(`/rest/`)"
      service: backend-legacy-service
      tls:
        certresolver: letsencrypt
  services:
    backend-legacy-service:
      loadBalancer:
        servers:
          - url: "http://[BACKEND_IP]:8080"
```

---

## 🚀 PROCESSO DE DEPLOY

### **Pipeline Steps:**
1. **validate-environment** - Verifica arquivos obrigatórios
2. **build-test-validate** - Valida YAML e Docker Compose
3. **security-analysis** - Score de segurança (min 4/6)
4. **deploy-selfhosted** - Deploy no Docker Swarm

### **Deploy Sequence:**
```bash
# 1. Cleanup anterior
docker stop traefik-microservices  # Remove container legado
docker stack rm conexao-traefik    # Remove stack anterior

# 2. Deploy novo
docker stack deploy conexao-traefik

# 3. Conectividade híbrida
docker network connect conexao-network $TRAEFIK_CONTAINER

# 4. Configuração dinâmica
# Gera legacy-backend.yml com IP do backend legado
```

---

## ⚠️ TROUBLESHOOTING

### **Problema: Serviço Não Readiness**
```bash
# 1. Verificar status stack
docker service ls | grep traefik

# 2. Verificar logs
docker service logs conexao-traefik_traefik --tail 50

# 3. Verificar configuração
curl -f http://localhost:8080/api/overview
```

### **Problema: SSL Certificate Issues**
```bash
# 1. Verificar ACME storage
docker exec $TRAEFIK_CONTAINER ls -la /etc/traefik/certs/

# 2. Verificar logs ACME
docker service logs conexao-traefik_traefik | grep acme

# 3. Force renewal (se necessário)
docker exec $TRAEFIK_CONTAINER rm /etc/traefik/certs/acme.json
```

### **Problema: Backend Legado 504**
```bash
# 1. Verificar conectividade de rede
docker inspect $TRAEFIK_CONTAINER | jq '.NetworkSettings.Networks'

# 2. Verificar IP backend legado  
docker inspect $BACKEND_CONTAINER | jq '.NetworkSettings.Networks["conexao-network"].IPAddress'

# 3. Verificar arquivo dinâmico
docker exec $TRAEFIK_CONTAINER cat /etc/traefik/dynamic/legacy-backend.yml
```

---

## 📋 CHECKLIST PRÉ-DEPLOY

### **Configuração:**
- [ ] Arquivos Traefik (traefik.yml, middlewares.yml, etc.)
- [ ] Secrets OIDC configurados no GitHub repo
- [ ] Azure Key Vault acessível
- [ ] Docker Swarm inicializado

### **Rede:**
- [ ] Rede `conexao-network-swarm` criada
- [ ] Rede `conexao-network` existe (para legado)
- [ ] Portas 80/443/8080 disponíveis
- [ ] DNS apontando para servidor

### **Segurança:**
- [ ] Let's Encrypt email configurado
- [ ] Security score >= 4/6
- [ ] TLS 1.2+ obrigatório
- [ ] Access logs habilitados

---

## 🔄 DISASTER RECOVERY

### **Backup Critical:**
- Certificados SSL (`/etc/traefik/certs/`)
- Configurações dinâmicas (`/etc/traefik/dynamic/`)
- Docker Swarm secrets
- DNS configuration

### **Recovery Procedure:**
1. Recreate Docker Swarm networks
2. Restore Traefik configuration files
3. Deploy Traefik stack
4. Restore SSL certificates (ou permitir regeneração)
5. Verify all routes working
6. Update DNS if necessary

### **Monitoring Critical:**
- Certificate expiration (< 30 days)
- Response time P95 > 2s
- Error rate > 1%
- Backend availability < 99%

---

## 💡 OPERATIONAL NOTES

### **Manutenção:**
- **SSL Renewal**: Automático via ACME
- **Config Reload**: Automático (file watcher)
- **Rolling Update**: Suportado via Docker Swarm
- **Zero Downtime**: Garantido com Swarm

### **Performance Tuning:**
```yaml
# Connection limits
--entrypoints.web.transport.lifeCycle.graceTimeOut=10s
--entrypoints.web.transport.respondingTimeouts.writeTimeout=10s

# Resource limits (Docker)
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 256M
```

---

**📅 Última Atualização**: Setembro 2025  
**🏷️ Versão**: 1.0  
**🌐 Criticidade**: CRÍTICA - Gateway de entrada para toda plataforma