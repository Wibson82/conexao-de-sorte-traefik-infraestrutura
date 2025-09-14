# 🌐 Conexão de Sorte - Traefik Infrastructure

[![Security Score](https://img.shields.io/badge/Security%20Score-100%25-brightgreen)](./SECURITY-IMPROVEMENTS.md)
[![Docker](https://img.shields.io/badge/Docker-Swarm%20Ready-blue)](https://docs.docker.com/engine/swarm/)
[![Traefik](https://img.shields.io/badge/Traefik-v3.5.2-orange)](https://traefik.io/)
[![HTTP/3](https://img.shields.io/badge/HTTP%2F3-Enabled-green)](https://en.wikipedia.org/wiki/HTTP/3)

Infraestrutura Traefik robusta e segura para o projeto Conexão de Sorte, implementando load balancing, SSL termination e service discovery para microserviços.

## 🚀 Funcionalidades Principais

### ✅ **Segurança Robusta**
- 🔒 **Score de Segurança 100%** com validações automatizadas
- 🛡️ **HTTPS obrigatório** com redirecionamento automático
- 🔐 **Let's Encrypt automático** para certificados SSL/TLS
- 📊 **Security Headers completos** (HSTS, CSP, XSS Protection)
- 🚦 **Rate Limiting avançado** por tipo de serviço
- 🔍 **Logs de acesso JSON** para auditoria

### ⚡ **Performance Otimizada**
- 🚀 **HTTP/3 support** para conexões mais rápidas
- 💨 **Gzip compression** automática
- 🔄 **Health checks** com retry automático
- 🌐 **Service discovery** dinâmico
- ⚖️ **Load balancing** inteligente

### 🛠️ **DevOps & Monitoramento**
- 📋 **Pipeline CI/CD completo** com validações
- 🏥 **Health checks Docker** robustos
- 🔍 **Validações de conectividade** automatizadas
- 📊 **Monitoramento contínuo** de saúde
- 🐳 **Docker Swarm ready** para alta disponibilidade

## 📋 Pré-requisitos

- 🐳 **Docker Engine** 20.10+
- 🔧 **Docker Compose** 2.0+
- 🌐 **Docker Swarm** (para produção)
- 🌍 **Domínios configurados** (DNS)

## 🚀 Instalação & Deploy

### 1. **Configuração Inicial**

```bash
# Clone o repositório
git clone https://github.com/Wibson82/conexao-de-sorte-traefik-infraestrutura.git
cd conexao-de-sorte-traefik-infraestrutura

# Configure variáveis de ambiente
cp .env.example .env
nano .env  # Configure domínios e emails
```

### 2. **Deploy Local (Desenvolvimento)**

```bash
# Criar rede externa
docker network create conexao-network-swarm

# Deploy com Docker Compose
docker compose up -d

# Verificar status
docker compose ps

# Verificar logs
docker compose logs -f traefik
```

### 3. **Deploy Produção (Docker Swarm)**

```bash
# Inicializar Swarm (se necessário)
docker swarm init

# Criar rede overlay
docker network create --driver overlay conexao-network-swarm

# Deploy via script automatizado
./.github/workflows/scripts/deploy-traefik.sh

# Verificar status
docker service ls
docker service logs conexao-traefik_traefik
```

### 4. **Validações de Segurança**

```bash
# Executar validação de segurança completa
./.github/workflows/scripts/security-validation.sh

# Executar validação de conectividade
./.github/workflows/scripts/connectivity-validation.sh

# Executar healthcheck
./.github/workflows/scripts/healthcheck-traefik.sh
```

## 🌐 Endpoints & Rotas

### **Principais Endpoints**
- **Frontend**: `https://conexaodesorte.com.br`
- **Frontend (www)**: `https://www.conexaodesorte.com.br`
- **API Produção**: `https://conexaodesorte.com.br/rest`
- **API Teste**: `https://conexaodesorte.com.br/teste/rest`
- **Frontend Teste**: `https://conexaodesorte.com.br/teste`
- **Sistema Frete**: `https://conexaodesorte.com.br/teste/frete`
- **Dashboard**: `https://traefik.conexaodesorte.com.br` (protegido)

### **Microserviços Suportados**
- 🔐 **Auth API**: `/auth/*`
- 👤 **User API**: `/users/*`
- 🎯 **Results API**: `/results/*`
- 💬 **Chat API**: `/chat/*`
- 🔔 **Notifications API**: `/notifications/*`
- 📊 **Observability API**: `/observability/*`
- 🔐 **Crypto API**: `/crypto/*`

## 📊 Monitoramento & Logs

### **Logs de Acesso**
```bash
# Visualizar logs em tempo real
tail -f logs/traefik/access.log

# Analisar logs JSON
cat logs/traefik/access.log | jq '.'
```

### **Health Checks**
```bash
# Status do serviço
docker service ls | grep traefik

# Health check manual
curl -f http://localhost:80/ping || echo "Health check failed"
```

### **Métricas Docker**
```bash
# Uso de recursos
docker stats conexao-traefik_traefik

# Status detalhado
docker service inspect conexao-traefik_traefik
```

## 🔧 Configuração Avançada

### **Variáveis de Ambiente (.env)**

```env
# Domínios
DOMAIN_NAME=conexaodesorte.com.br
API_DOMAIN=api.conexaodesorte.com.br
TRAEFIK_DOMAIN=traefik.conexaodesorte.com.br

# Let's Encrypt
TRAEFIK_ACME_EMAIL=seu-email@dominio.com

# Segurança
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASSWORD=senha-segura-aqui

# Performance
HTTP3_ENABLED=true
COMPRESSION_ENABLED=true
RATE_LIMIT_AVERAGE=100
RATE_LIMIT_BURST=200
```

### **Labels para Microserviços**

Para adicionar um novo microserviço ao roteamento do Traefik:

```yaml
# docker-compose.yml do microserviço
services:
  meu-microservico:
    image: minha-imagem:latest
    networks:
      - conexao-network-swarm
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.meu-service.rule=Host(`conexaodesorte.com.br`) && PathPrefix(`/meu-path`)"
      - "traefik.http.routers.meu-service.entrypoints=websecure"
      - "traefik.http.routers.meu-service.tls.certresolver=letsencrypt"
      - "traefik.http.routers.meu-service.middlewares=security-headers@file,rate-limit-api@file"
      - "traefik.http.services.meu-service.loadbalancer.server.port=8080"

networks:
  conexao-network-swarm:
    external: true
```

## 🔒 Segurança & Compliance

### **Score de Segurança Automatizado**
- ✅ **HTTPS obrigatório** (100%)
- ✅ **Let's Encrypt automático** (100%)
- ✅ **Security Headers** (100%)
- ✅ **Rate Limiting** (100%)
- ✅ **TLS 1.2+ mínimo** (100%)
- ✅ **Logs de auditoria** (100%)
- ✅ **Dashboard seguro** (100%)
- ✅ **Health checks** (100%)

### **Middlewares de Segurança Disponíveis**

```yaml
# Security Headers
security-headers@file        # Headers completos (CSP, HSTS, XSS)
security-headers-api@file    # Headers específicos para APIs
injection-protection@file    # Proteção contra injeção

# Rate Limiting
rate-limit-general@file      # 100 req/min geral
rate-limit-api@file          # 50 req/min para APIs
rate-limit-strict@file       # 20 req/min rigoroso
rate-limit-auth@file         # 5 req/min para autenticação

# Resiliência
circuit-breaker@file         # Circuit breaker
retry-policy@file            # Política de retry

# Compressão & CORS
gzip-compress@file           # Compressão GZIP
cors-api@file               # CORS para APIs
```

## 🚨 Troubleshooting

### **Problemas Comuns**

#### **Service não inicia (0/1 replicas)**
```bash
# Verificar logs do serviço
docker service logs conexao-traefik_traefik

# Verificar configuração
./.github/workflows/scripts/security-validation.sh

# Verificar rede
docker network ls | grep conexao-network-swarm
```

#### **Certificado SSL não funciona**
```bash
# Verificar permissões do acme.json
ls -la letsencrypt/acme.json  # Deve ter permissões 600

# Verificar logs do ACME
docker service logs conexao-traefik_traefik | grep -i acme

# Recrear certificados
rm letsencrypt/acme.json
docker service update --force conexao-traefik_traefik
```

#### **Erro "field not found, node: swarmMode"**
```bash
# Este erro foi corrigido na versão atual
# No Traefik 3.x, o SwarmMode é detectado automaticamente quando o Docker está em modo Swarm
# Configuração correta:
grep -A 10 "docker:" traefik/traefik.yml
```

### **Validações de Diagnóstico**
```bash
# Validação completa do sistema
./.github/workflows/scripts/connectivity-validation.sh

# Teste de conectividade
curl -f http://localhost:80/ping

# Verificar configuração
docker compose config

# Verificação de compatibilidade do Traefik
./scripts/verify-traefik-config.sh
```

## 📈 Pipeline CI/CD

### **Etapas Automatizadas**
1. 🔍 **Validação de arquivos** obrigatórios
2. 🔒 **Validação de segurança** (score 100%)
3. 🚀 **Deploy automatizado** no Swarm
4. 🏥 **Health check** do serviço
5. 🌐 **Validação de conectividade** completa

### **Scripts Disponíveis**
- `validate-traefik.sh` - Validação básica de arquivos
- `security-validation.sh` - Score de segurança automatizado
- `deploy-traefik.sh` - Deploy com preparação de ambiente
- `healthcheck-traefik.sh` - Verificação de saúde
- `connectivity-validation.sh` - Testes de conectividade

## 🔧 Estrutura de Prioridades

As rotas estão configuradas com prioridades para garantir roteamento correto:

| Serviço | Prioridade | Regra |
|---------|------------|-------|
| Frontend Frete | 300 | `/teste/frete` |
| Backend Teste | 200 | `/teste/rest` |
| Backend Produção | 100 | `/rest` |
| Frontend Teste | 50 | `/teste` (excl. sub-paths) |
| Frontend Principal | 1 | Catch-all domain |

## 📚 Documentação Adicional

- 📋 [**Melhorias de Segurança**](SECURITY-IMPROVEMENTS.md) - Detalhes das implementações
- 🔧 [**Guia do Projeto**](GUIA_PROJETO_TRAEFIK.md) - Documentação técnica
- 🐳 [**Deploy Strategy**](README-DEPLOY.md) - Estratégias de deploy
- 🔒 [**Segurança Docker**](SEGURANCA-DOCKER.md) - Boas práticas
- 📊 [**Routing Updates**](ROUTING_UPDATED.md) - Atualizações de roteamento

## 🎯 Melhorias Implementadas

### **Vs. Commit 4fee653**
- ✅ **Healthcheck restaurado** - Container health monitoring
- ✅ **Security validation** - Score automatizado de 100%
- ✅ **Secrets management** - Gerenciamento seguro via env vars
- ✅ **Access logs** - Auditoria JSON estruturada
- ✅ **HTTP/3 support** - Performance moderna
- ✅ **Explicit routes** - Roteamento de microserviços
- ✅ **Connectivity validation** - Testes automatizados
- ✅ **Docker Swarm fixes** - Configuração corrigida

### **Benefícios Alcançados**
- 🔒 **100% Security Score** - Validação automatizada
- ⚡ **HTTP/3 Performance** - Conexões mais rápidas
- 🛡️ **Production Ready** - Configuração robusta
- 📊 **Full Monitoring** - Logs e health checks
- 🔄 **Auto Validation** - Pipeline de qualidade

---

**⚡ Status**: ✅ Produção Ready | 🔒 100% Security Score | 🚀 HTTP/3 Enabled