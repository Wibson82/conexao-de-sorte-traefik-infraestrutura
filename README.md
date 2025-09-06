# Reverse Proxy - Traefik v3.1

Nota de migração: este diretório consolida e padroniza o antigo `conexao-traefik-infrastructure` sob o padrão `conexao-de-sorte-*`. Conteúdos foram copiados de forma segura e preservamos a compatibilidade.

Repositório isolado com Traefik v3.1, rede Docker externa única e configurações separadas em estática e dinâmica.

## Estrutura do Projeto

```
reverse-proxy/
├─ docker-compose.yml
├─ .env
├─ traefik/
│  ├─ traefik.yml              # configuração estática
│  └─ dynamic/                 # configuração dinâmica (file provider)
│     ├─ security-headers.yml
│     ├─ tls.yml
│     └─ middlewares.yml
├─ letsencrypt/
│  └─ acme.json                # chmod 600
├─ secrets/
│  └─ traefik-basicauth        # htpasswd
├─ .gitignore
└─ README.md
```

## 🚀 Como usar

### 1. Criar a rede externa

```bash
docker network create conexao-network
```

### 2. Iniciar o Traefik

```bash
docker-compose up -d
```

## 🌐 Mapeamento de Rotas - Conexão de Sorte

O Traefik está configurado para gerenciar as seguintes rotas:

| Serviço | Domínio/Path | Descrição |
|---------|--------------|----------|
| Frontend Principal | `conexaodesorte.com.br` | Site principal |
| Frontend Principal | `www.conexaodesorte.com.br` | Site principal (aceita diretamente) |
| Backend Produção | `conexaodesorte.com.br/rest` | API de produção |
| Backend Produção | `www.conexaodesorte.com.br/rest` | API de produção (com www) |
| Backend Teste | `conexaodesorte.com.br/teste/rest` | API de teste |
| Backend Teste | `www.conexaodesorte.com.br/teste/rest` | API de teste (com www) |
| Frontend Teste | `conexaodesorte.com.br/teste` | Ambiente de teste do frontend |
| Frontend Teste | `www.conexaodesorte.com.br/teste` | Ambiente de teste do frontend (com www) |
| Frontend Frete | `conexaodesorte.com.br/teste/frete` | Sistema de frete |
| Frontend Frete | `www.conexaodesorte.com.br/teste/frete` | Sistema de frete (com www) |
| Traefik Dashboard | `traefik.conexaodesorte.com.br` | Dashboard do Traefik |

## 📋 Configuração dos Projetos

### 1. Frontend Principal
**Domínios**: `conexaodesorte.com.br` e `www.conexaodesorte.com.br`

```yaml
services:
  frontend:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      # Rota principal (sem www)
      - "traefik.http.routers.frontend-main.rule=Host(`conexaodesorte.com.br`)"
      - "traefik.http.routers.frontend-main.entrypoints=websecure"
      - "traefik.http.routers.frontend-main.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-main.middlewares=security-headers@file,gzip-compress@file"
      - "traefik.http.routers.frontend-main.priority=1"
      # Rota com www (aceita diretamente)
      - "traefik.http.routers.frontend-www.rule=Host(`www.conexaodesorte.com.br`)"
      - "traefik.http.routers.frontend-www.entrypoints=websecure"
      - "traefik.http.routers.frontend-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-www.middlewares=security-headers@file,gzip-compress@file"
      - "traefik.http.routers.frontend-www.priority=1"
      # Configuração do serviço
      - "traefik.http.services.frontend.loadbalancer.server.port=3000"

networks:
  conexao-network:
    external: true
```

### 2. Backend Produção
**Paths**: `/rest` em ambos os domínios

```yaml
services:
  backend-prod:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      # Rota principal (sem www)
      - "traefik.http.routers.backend-prod-main.rule=Host(`conexaodesorte.com.br`) && PathPrefix(`/rest`)"
      - "traefik.http.routers.backend-prod-main.entrypoints=websecure"
      - "traefik.http.routers.backend-prod-main.tls.certresolver=letsencrypt"
      - "traefik.http.routers.backend-prod-main.middlewares=security-headers-api@file,gzip-compress@file,cors-api@file"
      - "traefik.http.routers.backend-prod-main.priority=100"
      # Rota com www
      - "traefik.http.routers.backend-prod-www.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/rest`)"
      - "traefik.http.routers.backend-prod-www.entrypoints=websecure"
      - "traefik.http.routers.backend-prod-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.backend-prod-www.middlewares=security-headers-api@file,gzip-compress@file,cors-api@file"
      - "traefik.http.routers.backend-prod-www.priority=100"
      # Configuração do serviço
      - "traefik.http.services.backend-prod.loadbalancer.server.port=8080"

networks:
  conexao-network:
    external: true
```

⚠️ **IMPORTANTE**: Se você estiver usando múltiplos paths, cada PathPrefix deve ser uma regra separada:
```yaml
# ❌ INCORRETO - Múltiplos parâmetros em um PathPrefix
- "traefik.http.routers.backend.rule=Host(`example.com`) && PathPrefix(`/api`, `/v1`, `/public`)"

# ✅ CORRETO - PathPrefix separados com OR
- "traefik.http.routers.backend.rule=Host(`example.com`) && (PathPrefix(`/api`) || PathPrefix(`/v1`) || PathPrefix(`/public`))"
```

### 3. Backend Teste
**Paths**: `/teste/rest` em ambos os domínios

```yaml
services:
  backend-teste:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      # Rota principal (sem www)
      - "traefik.http.routers.backend-teste-main.rule=Host(`conexaodesorte.com.br`) && PathPrefix(`/teste/rest`)"
      - "traefik.http.routers.backend-teste-main.entrypoints=websecure"
      - "traefik.http.routers.backend-teste-main.tls.certresolver=letsencrypt"
      - "traefik.http.routers.backend-teste-main.middlewares=security-headers-api@file,gzip-compress@file,cors-api@file,rate-limit-strict@file"
      - "traefik.http.routers.backend-teste-main.priority=200"
      # Rota com www
      - "traefik.http.routers.backend-teste-www.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/teste/rest`)"
      - "traefik.http.routers.backend-teste-www.entrypoints=websecure"
      - "traefik.http.routers.backend-teste-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.backend-teste-www.middlewares=security-headers-api@file,gzip-compress@file,cors-api@file,rate-limit-strict@file"
      - "traefik.http.routers.backend-teste-www.priority=200"
      # Configuração do serviço
      - "traefik.http.services.backend-teste.loadbalancer.server.port=8081"

networks:
  conexao-network:
    external: true
```

### 4. Frontend Teste
**Paths**: `/teste` em ambos os domínios

```yaml
services:
  frontend-teste:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      # Rota principal (sem www)
      - "traefik.http.routers.frontend-teste-main.rule=Host(`conexaodesorte.com.br`) && PathPrefix(`/teste`) && !PathPrefix(`/teste/rest`) && !PathPrefix(`/teste/frete`)"
      - "traefik.http.routers.frontend-teste-main.entrypoints=websecure"
      - "traefik.http.routers.frontend-teste-main.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-teste-main.priority=50"
      # Rota com www
      - "traefik.http.routers.frontend-teste-www.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/teste`) && !PathPrefix(`/teste/rest`) && !PathPrefix(`/teste/frete`)"
      - "traefik.http.routers.frontend-teste-www.entrypoints=websecure"
      - "traefik.http.routers.frontend-teste-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-teste-www.priority=50"
      # Configuração do serviço
      - "traefik.http.services.frontend-teste.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend-teste-main.middlewares=gzip-compress@file,security-headers@file"
      - "traefik.http.routers.frontend-teste-www.middlewares=gzip-compress@file,security-headers@file"

networks:
  conexao-network:
    external: true
```

### 5. Frontend Frete
**Paths**: `/teste/frete` em ambos os domínios

```yaml
services:
  frontend-frete:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      # Rota principal (sem www)
      - "traefik.http.routers.frontend-frete-main.rule=Host(`conexaodesorte.com.br`) && PathPrefix(`/teste/frete`)"
      - "traefik.http.routers.frontend-frete-main.entrypoints=websecure"
      - "traefik.http.routers.frontend-frete-main.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-frete-main.priority=300"
      # Rota com www
      - "traefik.http.routers.frontend-frete-www.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/teste/frete`)"
      - "traefik.http.routers.frontend-frete-www.entrypoints=websecure"
      - "traefik.http.routers.frontend-frete-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-frete-www.priority=300"
      # Configuração do serviço
      - "traefik.http.services.frontend-frete.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend-frete-main.middlewares=gzip-compress@file,security-headers@file"
      - "traefik.http.routers.frontend-frete-www.middlewares=gzip-compress@file,security-headers@file"

networks:
  conexao-network:
    external: true
```

## 🔧 Middlewares Disponíveis

### Middlewares de Segurança
- `security-headers@file` - Cabeçalhos de segurança completos (CSP, HSTS, XSS, etc.)
- `security-headers-api@file` - Cabeçalhos de segurança específicos para APIs
- `injection-protection@file` - Proteção contra ataques de injeção
- `gzip-compress@file` - Compressão GZIP
- `cors-api@file` - CORS para APIs
- `ip-allow-local@file` - Whitelist de IPs locais

### Middlewares de Rate Limiting
- `rate-limit-general@file` - Rate limiting geral (100 req/min)
- `rate-limit-api@file` - Rate limiting para APIs (50 req/min)
- `rate-limit-strict@file` - Rate limiting rigoroso (20 req/min)
- `rate-limit-auth@file` - Rate limiting para autenticação (5 req/min)

### Middlewares de Resiliência
- `circuit-breaker@file` - Circuit breaker para proteção contra sobrecarga
- `retry-policy@file` - Política de retry automático

### Middlewares de Redirecionamento
- `redirect-to-https@file` - Redirecionamento HTTP → HTTPS
- `redirect-www-to-non-www@file` - Redirecionamento www → sem www
- `redirect-non-www-to-www@file` - Redirecionamento sem www → www

## 📊 Dashboard
- **URL**: https://traefik.conexaodesorte.com.br
- **Usuário**: admin
- **Senha**: Configurada no arquivo `secrets/traefik-basicauth`

## ⚠️ Observações Importantes

### Prioridades de Roteamento
As prioridades estão configuradas para garantir o roteamento correto:
- **Frontend Frete** (300) - Mais específico: `/teste/frete`
- **Backend Teste** (200) - Específico: `/teste/rest`
- **Backend Produção** (100) - Específico: `/rest`
- **Frontend Teste** (50) - Menos específico: `/teste` (excluindo `/teste/rest` e `/teste/frete`)
- **Frontend Principal** (1) - Catch-all para o domínio principal

### Estratégia de Domínios
- **Frontend**: Aceita tanto `conexaodesorte.com.br` quanto `www.conexaodesorte.com.br` diretamente
- **APIs**: Funcionam em ambos os domínios (com e sem www)
- **Sem redirecionamentos**: Ambas as versões são tratadas como válidas

### Certificados SSL
- Certificados automáticos via Let's Encrypt
- Suporte para ambos os domínios (`conexaodesorte.com.br` e `www.conexaodesorte.com.br`)
- Redirecionamento automático HTTP → HTTPS
- Certificados gerados para ambas as versões dos domínios

### Rede Docker
Todos os projetos devem usar a rede externa `conexao-network`:

```bash
docker network create conexao-network
```

### Estrutura de Arquivos nos Projetos
Cada projeto deve ter seu `docker-compose.yml` configurado conforme os exemplos acima, sempre incluindo:
1. A rede `conexao-network` como externa
2. As labels do Traefik apropriadas
3. As prioridades corretas para evitar conflitos de roteamento
