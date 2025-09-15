# 🔒 Solução para Problemas SSL/TLS - Frontend

## 🚨 Problema Atual

**Erro observado:** `ERR_CERT_AUTHORITY_INVALID` com HSTS ativo
**Sintomas:** Frontend retornando erro 404 e certificado SSL inválido

## ✅ Soluções Implementadas

### 1. **Nova Configuração Frontend**
- ✅ Criado arquivo `traefik/dynamic/frontend-routes.yml` com roteamento específico
- ✅ Configuração SSL/TLS robusta com cipher suites seguros
- ✅ Headers de segurança otimizados para React
- ✅ Redirecionamento HTTP→HTTPS automático

### 2. **Correções de Rede**
- ✅ Padronizado para `conexao-network-swarm` em todos os projetos
- ✅ Docker Swarm mode habilitado no Traefik
- ✅ Service discovery automático configurado

### 3. **Melhorias TLS**
- ✅ Suporte TLS 1.3
- ✅ Cipher suites modernos e seguros
- ✅ ALPN para HTTP/2
- ✅ Configuração HSTS otimizada

## 🔧 Implementação

### Passo 1: Deploy da Nova Configuração

```bash
# 1. Ir para o diretório do Traefik
cd /Volumes/NVME/Projetos/conexao-de-sorte/Microsservicos/infraestrutura/conexao-de-sorte-traefik-infraestrutura/

# 2. Parar Traefik atual
docker-compose down

# 3. Criar rede se não existir
docker network create --driver overlay --attachable conexao-network-swarm || true

# 4. Subir Traefik com nova configuração
docker-compose up -d

# 5. Verificar logs
docker-compose logs -f traefik
```

### Passo 2: Deploy do Frontend

```bash
# 1. Ir para o diretório do frontend
cd /Volumes/NVME/Projetos/conexao-de-sorte/Microsservicos/frontend/conexao-de-sorte-frontend/

# 2. Subir frontend na rede correta
docker-compose up -d

# 3. Verificar se está na rede certa
docker network inspect conexao-network-swarm
```

### Passo 3: Diagnóstico Automático

```bash
# Executar script de diagnóstico
cd /Volumes/NVME/Projetos/conexao-de-sorte/Microsservicos/infraestrutura/conexao-de-sorte-traefik-infraestrutura/
./scripts/ssl-diagnostics.sh conexaodesorte.com.br
```

## 🎯 Configurações Principais

### Headers de Segurança (Frontend)
```yaml
Content-Security-Policy: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: https: blob:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' https://www.google-analytics.com https://api.conexaodesorte.com.br wss://conexaodesorte.com.br; frame-ancestors 'none';"
Strict-Transport-Security: "max-age=31536000; includeSubDomains; preload"
```

### TLS Configuration
```yaml
minVersion: "VersionTLS12"
maxVersion: "VersionTLS13"
cipherSuites:
  - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
  - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
  - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
```

### Routing Rules
```yaml
rule: "Host(`conexaodesorte.com.br`) || Host(`www.conexaodesorte.com.br`)"
middlewares:
  - security-headers-frontend
  - gzip-compress
  - redirect-to-www
```

## 🔍 Verificações de Status

### 1. Verificar Containers
```bash
docker ps | grep -E "(traefik|frontend)"
```

### 2. Verificar Redes
```bash
docker network ls | grep conexao
docker network inspect conexao-network-swarm
```

### 3. Verificar Certificados
```bash
docker exec traefik-microservices cat /letsencrypt/acme.json | jq '.letsencrypt.Certificates'
```

### 4. Testar SSL
```bash
openssl s_client -connect conexaodesorte.com.br:443 -servername conexaodesorte.com.br
curl -I https://www.conexaodesorte.com.br/
```

## 🚨 Resolução de Problemas Comuns

### ERR_CERT_AUTHORITY_INVALID
1. **Limpar certificados corrompidos:**
   ```bash
   docker-compose down
   sudo rm letsencrypt/acme.json
   docker-compose up -d
   ```

2. **Verificar DNS:**
   ```bash
   dig +short conexaodesorte.com.br
   dig +short www.conexaodesorte.com.br
   ```

### HSTS Error
1. **Limpar cache do navegador:** Chrome → DevTools → Application → Clear Storage
2. **Usar modo incógnito** para testar
3. **Verificar headers:** `curl -I https://www.conexaodesorte.com.br/`

### 404 Not Found
1. **Frontend não conectado:**
   ```bash
   docker network connect conexao-network-swarm conexao-frontend
   ```

2. **Verificar service discovery:**
   ```bash
   docker-compose logs traefik | grep -i frontend
   ```

### Certificado não renovando
1. **Verificar portas 80/443 livres**
2. **Forçar renovação:**
   ```bash
   docker exec traefik-microservices traefik healthcheck
   ```

## 📋 Checklist de Implementação

- [ ] Traefik parado
- [ ] Rede `conexao-network-swarm` criada
- [ ] Nova configuração `frontend-routes.yml` aplicada
- [ ] TLS configuration atualizada
- [ ] Traefik reiniciado
- [ ] Frontend deployado na rede correta
- [ ] Script de diagnóstico executado
- [ ] Teste SSL bem-sucedido
- [ ] Frontend acessível via HTTPS

## 🎯 Comandos de Emergência

### Reset Completo SSL
```bash
docker-compose down
sudo rm -rf letsencrypt/*
docker network rm conexao-network-swarm || true
docker network create --driver overlay --attachable conexao-network-swarm
docker-compose up -d
```

### Debug Avançado
```bash
# Logs detalhados
docker-compose logs traefik | grep -E "(error|warn|cert)"

# Verificar configuração carregada
docker exec traefik-microservices cat /etc/traefik/traefik.yml

# Testar conectividade interna
docker exec traefik-microservices wget -qO- http://conexao-frontend:3000/health.json
```

## 🔗 Arquivos Modificados

1. `traefik/dynamic/frontend-routes.yml` - **NOVO** (roteamento frontend)
2. `traefik/dynamic/tls.yml` - **ATUALIZADO** (TLS 1.3 + cipher suites)
3. `traefik/traefik.yml` - **ATUALIZADO** (swarm mode)
4. `docker-compose.yml` - **ATUALIZADO** (rede padronizada)
5. `scripts/ssl-diagnostics.sh` - **NOVO** (diagnóstico automático)

## 📞 Próximos Passos

1. **Testar em produção** com domínio real
2. **Monitorar logs** por 24h após deploy
3. **Configurar alertas** para falhas SSL
4. **Documentar** procedimentos de manutenção

---

**✅ Com essas implementações, o erro `ERR_CERT_AUTHORITY_INVALID` e o 404 do frontend devem ser resolvidos.**