# Reverse Proxy - Traefik v3.1

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

| Serviço | Domínios/Paths |
|---------|----------------|
| **Frontend Principal** | `conexaodesorte.com.br` e `www.conexaodesorte.com.br` |
| **Backend Produção** | `conexaodesorte.com.br/rest` e `www.conexaodesorte.com.br/rest` |
| **Backend Teste** | `conexaodesorte.com.br/teste/rest` e `www.conexaodesorte.com.br/teste/rest` |
| **Frontend Teste** | `conexaodesorte.com.br/teste` e `www.conexaodesorte.com.br/teste` |
| **Frontend Frete** | `conexaodesorte.com.br/teste/frete` e `www.conexaodesorte.com.br/teste/frete` |
| **Traefik Dashboard** | `traefik.conexaodesorte.com.br` |

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
      - "traefik.http.routers.frontend-main.priority=1"
      # Rota com www (redirecionamento)
      - "traefik.http.routers.frontend-www.rule=Host(`www.conexaodesorte.com.br`)"
      - "traefik.http.routers.frontend-www.entrypoints=websecure"
      - "traefik.http.routers.frontend-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.frontend-www.middlewares=redirect-www-to-non-www@file"
      # Configuração do serviço
      - "traefik.http.services.frontend.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend-main.middlewares=gzip-compress@file,security-headers@file"

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
      - "traefik.http.routers.backend-prod-main.priority=100"
      # Rota com www
      - "traefik.http.routers.backend-prod-www.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/rest`)"
      - "traefik.http.routers.backend-prod-www.entrypoints=websecure"
      - "traefik.http.routers.backend-prod-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.backend-prod-www.priority=100"
      # Configuração do serviço
      - "traefik.http.services.backend-prod.loadbalancer.server.port=8080"
      - "traefik.http.routers.backend-prod-main.middlewares=gzip-compress@file,cors-api@file"
      - "traefik.http.routers.backend-prod-www.middlewares=gzip-compress@file,cors-api@file"

networks:
  conexao-network:
    external: true
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
      - "traefik.http.routers.backend-teste-main.priority=200"
      # Rota com www
      - "traefik.http.routers.backend-teste-www.rule=Host(`www.conexaodesorte.com.br`) && PathPrefix(`/teste/rest`)"
      - "traefik.http.routers.backend-teste-www.entrypoints=websecure"
      - "traefik.http.routers.backend-teste-www.tls.certresolver=letsencrypt"
      - "traefik.http.routers.backend-teste-www.priority=200"
      # Configuração do serviço
      - "traefik.http.services.backend-teste.loadbalancer.server.port=8080"
      - "traefik.http.routers.backend-teste-main.middlewares=gzip-compress@file,cors-api@file"
      - "traefik.http.routers.backend-teste-www.middlewares=gzip-compress@file,cors-api@file"

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
- `security-headers@file` - Cabeçalhos de segurança (CSP, HSTS, etc.)
- `gzip-compress@file` - Compressão GZIP
- `cors-api@file` - CORS para APIs
- `ip-allow-local@file` - Whitelist de IPs locais

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

### Certificados SSL
- Certificados automáticos via Let's Encrypt
- Suporte para ambos os domínios (`conexaodesorte.com.br` e `www.conexaodesorte.com.br`)
- Redirecionamento automático HTTP → HTTPS

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
