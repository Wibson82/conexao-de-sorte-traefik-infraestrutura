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

## Como usar

### 1. Criar a rede externa

```bash
docker network create reverse-proxy
```

### 2. Iniciar o Traefik

```bash
docker-compose up -d
```

### 3. Como outros projetos se conectam

Em cada `docker-compose.yml` de projeto backend, adicione:

```yaml
networks:
  default:
    external: true
    name: reverse-proxy
```

No serviço que deve receber tráfego, adicione labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=reverse-proxy
  - traefik.http.routers.app.rule=Host(`app.conexaodesorte.com.br`)
  - traefik.http.routers.app.entrypoints=websecure
  - traefik.http.routers.app.tls.certresolver=letsencrypt
  - traefik.http.services.app.loadbalancer.server.port=8080
  - traefik.http.routers.app.middlewares=gzip-compress@file,security-headers@file
```

## Configuração

- **Dashboard**: Acesse `https://traefik.conexaodesorte.com.br`
- **Usuário**: admin
- **Senha**: Configurada no arquivo `secrets/traefik-basicauth`

## Domínios configurados

- `conexaodesorte.com.br` - Aplicação principal
- `www.conexaodesorte.com.br` - Redirecionamento
- `traefik.conexaodesorte.com.br` - Dashboard do Traefik
