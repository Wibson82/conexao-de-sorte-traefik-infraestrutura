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

### 3. Conectar outros projetos
Para conectar outros projetos Docker ao Traefik, adicione as labels apropriadas aos seus serviços no docker-compose.yml:

```yaml
services:
  meu-app:
    image: nginx
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.meu-app.rule=Host(`meuapp.exemplo.com`)"
      - "traefik.http.routers.meu-app.entrypoints=websecure"
      - "traefik.http.routers.meu-app.tls.certresolver=letsencrypt"
      - "traefik.http.services.meu-app.loadbalancer.server.port=80"

networks:
  conexao-network:
    external: true
```

## 📋 Configuração para Outros Projetos

### Labels Obrigatórias
Todo serviço que deve ser roteado pelo Traefik precisa das seguintes labels:

```yaml
labels:
  # Habilitar o Traefik para este serviço
  - "traefik.enable=true"
  
  # Definir a regra de roteamento (substitua pelo seu domínio)
  - "traefik.http.routers.NOME-DO-SERVICO.rule=Host(`seu-dominio.com`)"
  
  # Usar HTTPS (websecure)
  - "traefik.http.routers.NOME-DO-SERVICO.entrypoints=websecure"
  
  # Certificado SSL automático
  - "traefik.http.routers.NOME-DO-SERVICO.tls.certresolver=letsencrypt"
  
  # Porta interna do container (ajuste conforme necessário)
  - "traefik.http.services.NOME-DO-SERVICO.loadbalancer.server.port=PORTA"
```

### Middlewares Disponíveis
Você pode usar os middlewares configurados adicionando:

```yaml
labels:
  # Middlewares de segurança e compressão
  - "traefik.http.routers.NOME-DO-SERVICO.middlewares=gzip-compress@file,security-headers@file"
  
  # Para APIs, use CORS:
  - "traefik.http.routers.NOME-DO-SERVICO.middlewares=gzip-compress@file,cors-api@file"
  
  # Para desenvolvimento local, use CORS mais permissivo:
  - "traefik.http.routers.NOME-DO-SERVICO.middlewares=gzip-compress@file,cors-dev@file"
```

### Exemplo Completo - Frontend React
```yaml
services:
  frontend:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`meusite.com`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend.middlewares=gzip-compress@file,security-headers@file"

networks:
  conexao-network:
    external: true
```

### Exemplo Completo - Backend API
```yaml
services:
  backend:
    build: .
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=Host(`api.meusite.com`)"
      - "traefik.http.routers.backend.entrypoints=websecure"
      - "traefik.http.routers.backend.tls.certresolver=letsencrypt"
      - "traefik.http.services.backend.loadbalancer.server.port=8080"
      - "traefik.http.routers.backend.middlewares=gzip-compress@file,cors-api@file"

networks:
  conexao-network:
    external: true
```

### Exemplo Completo - Múltiplos Serviços
```yaml
services:
  frontend:
    build: ./frontend
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app-frontend.rule=Host(`meuapp.com`)"
      - "traefik.http.routers.app-frontend.entrypoints=websecure"
      - "traefik.http.routers.app-frontend.tls.certresolver=letsencrypt"
      - "traefik.http.services.app-frontend.loadbalancer.server.port=80"
      - "traefik.http.routers.app-frontend.middlewares=gzip-compress@file,security-headers@file"

  backend:
    build: ./backend
    networks:
      - conexao-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app-backend.rule=Host(`api.meuapp.com`)"
      - "traefik.http.routers.app-backend.entrypoints=websecure"
      - "traefik.http.routers.app-backend.tls.certresolver=letsencrypt"
      - "traefik.http.services.app-backend.loadbalancer.server.port=3000"
      - "traefik.http.routers.app-backend.middlewares=gzip-compress@file,cors-api@file"

  database:
    image: postgres:15
    networks:
      - conexao-network
    # Sem labels do Traefik - não será exposto externamente
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password

networks:
  conexao-network:
    external: true
```

## 📊 Dashboard
- **URL**: https://traefik.conexaodesorte.com.br
- **Usuário**: admin
- **Senha**: Configurada no arquivo `secrets/traefik-basicauth`

## 🌐 Domínios configurados
- **Frontend**: https://conexaodesorte.com.br
- **Backend API**: https://api.conexaodesorte.com.br
- **Traefik Dashboard**: https://traefik.conexaodesorte.com.br
- **Prometheus**: https://prometheus.conexaodesorte.com.br
- **Grafana**: https://grafana.conexaodesorte.com.br
