# 🌐 Conexão de Sorte - Traefik Infrastructure

Projeto independente para gerenciamento de proxy reverso, load balancer e terminação SSL para toda a infraestrutura do Conexão de Sorte.

## 📋 Visão Geral

Este projeto centraliza toda a configuração de roteamento HTTP/HTTPS, certificados SSL e políticas de segurança para os serviços do Conexão de Sorte, seguindo o princípio de responsabilidade única e facilitando o gerenciamento de infraestrutura.

### 🎯 Responsabilidades

- **Proxy Reverso**: Roteamento inteligente para backend e frontend
- **Terminação SSL**: Certificados automáticos via Let's Encrypt
- **Load Balancing**: Distribuição de carga e health checks
- **Segurança**: Headers de segurança, CORS, rate limiting
- **Monitoramento**: Métricas e observabilidade da infraestrutura

## 🏗️ Arquitetura

```
Internet
    ↓
┌─────────────────┐
│   Traefik       │ ← Proxy Reverso Principal
│   (Port 80/443) │
└─────────────────┘
    ↓
┌─────────────────┐
│   Roteamento    │
│   Inteligente   │
└─────────────────┘
    ↓
┌─────────┬───────────┬─────────────┐
│Frontend │  Backend  │ Monitoring  │
│:3000    │  :8080    │ :9090/:3001 │
└─────────┴───────────┴─────────────┘
```

## 🚀 Início Rápido

### Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- Domínio configurado apontando para o servidor
- Portas 80 e 443 liberadas

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/Wibson82/conexao-traefik-infrastructure.git
   cd conexao-traefik-infrastructure
   ```

2. **Configure as variáveis de ambiente**
   ```bash
   cp .env.example .env
   nano .env  # Configure os valores apropriados
   ```

3. **Crie a rede Docker externa**
   ```bash
   docker network create conexao-network
   ```

4. **Inicie os serviços**
   ```bash
   docker-compose up -d
   ```

5. **Verifique o status**
   ```bash
   docker-compose ps
   docker-compose logs traefik
   ```

## 📁 Estrutura do Projeto

```
conexao-traefik-infrastructure/
├── README.md                          # Este arquivo
├── docker-compose.yml                 # Configuração principal
├── docker-compose.override.yml        # Configurações locais
├── .env.example                       # Exemplo de variáveis
├── config/
│   └── traefik.yml                    # Configuração estática
├── dynamic/                           # Configurações dinâmicas
│   ├── middlewares.yml                # Middlewares reusáveis
│   └── services.yml                   # Definições de serviços
├── scripts/
│   ├── README.md                      # Documentação dos scripts
│   ├── diagnostico-completo.sh        # Diagnóstico detalhado
│   ├── diagnostico-rapido.sh          # Diagnóstico essencial
│   └── test-ssh-connectivity.sh       # Teste de conectividade SSH
├── monitoring/
│   ├── prometheus.yml                 # Configuração Prometheus
│   └── grafana-dashboard.json/        # Dashboard Grafana
├── backup-roteamento/                 # ⚠️ Configurações obsoletas
│   └── README.md                      # Aviso sobre obsolescência
├── .github/
│   ├── SSH_SETUP.md                   # Configuração SSH para CI/CD
│   └── workflows/
│       └── main.yml                   # Pipeline CI/CD com diagnósticos
├── ANALISE-ARQUITETURA-TRAEFIK.md     # Análise da arquitetura
├── DIAGNOSTICOS-AUTOMATIZADOS.md      # Guia de diagnósticos
├── SOLUCAO-PROBLEMAS-SSL-404.md       # Soluções de problemas
└── test-local.sh                      # Testes locais
```

## 🔧 Configuração

### Variáveis de Ambiente Principais

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `DOMAIN` | Domínio principal | `conexaodesorte.com.br` |
| `ACME_EMAIL` | Email para Let's Encrypt | `admin@conexaodesorte.com.br` |
| `DASHBOARD_AUTH` | Credenciais do dashboard | `admin:$2y$10$...` |
| `LOG_LEVEL` | Nível de log | `INFO` |

### Configurações Avançadas

Consulte o arquivo `.env.example` para todas as opções disponíveis.

## 🌐 Roteamento

### Rotas Configuradas

| Rota | Destino | Descrição |
|------|---------|-----------|
| `conexaodesorte.com.br` | Frontend | Aplicação principal |
| `conexaodesorte.com.br/rest/*` | Backend | API REST |
| `conexaodesorte.com.br/actuator/*` | Backend | Health checks |
| `traefik.conexaodesorte.com.br` | Dashboard | Painel do Traefik |
| `prometheus.conexaodesorte.com.br` | Prometheus | Métricas |
| `grafana.conexaodesorte.com.br` | Grafana | Dashboards |

### Middlewares Disponíveis

- **security-headers**: Headers de segurança padrão
- **cors-api**: CORS para APIs
- **rate-limit**: Limitação de taxa
- **compression**: Compressão gzip
- **circuit-breaker**: Proteção contra falhas

## 🔒 Segurança

### Certificados SSL

- **Automático**: Let's Encrypt com renovação automática
- **Staging**: Disponível para testes
- **Backup**: Certificados salvos automaticamente

### Headers de Segurança

- HSTS (HTTP Strict Transport Security)
- CSP (Content Security Policy)
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection

### Rate Limiting

- **Padrão**: 100 req/min por IP
- **API**: 50 req/min por IP
- **Auth**: 5 req/min por IP

## 📊 Monitoramento

### Métricas Disponíveis

- **Traefik**: Métricas nativas via Prometheus
- **HTTP**: Latência, throughput, códigos de status
- **SSL**: Status dos certificados
- **Health Checks**: Status dos serviços

### Dashboards

- **Traefik Dashboard**: Interface web nativa
- **Grafana**: Dashboards customizados
- **Prometheus**: Métricas detalhadas

## 🔧 Integração de Novos Serviços

Para integrar um novo serviço ao Traefik:

1. **Adicione labels ao docker-compose do serviço**:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.docker.network=conexao-network"
     - "traefik.http.routers.meu-servico.rule=Host(`meuservico.conexaodesorte.com.br`)"
     - "traefik.http.routers.meu-servico.entrypoints=websecure"
     - "traefik.http.routers.meu-servico.tls.certresolver=letsencrypt"
     - "traefik.http.services.meu-servico.loadbalancer.server.port=8080"
   ```

2. **Conecte à rede externa**:
   ```yaml
   networks:
     - conexao-network
   ```

3. **Configure middlewares se necessário**:
   ```yaml
   labels:
     - "traefik.http.routers.meu-servico.middlewares=security-headers@file,rate-limit@file"
   ```

## 🚀 Deploy

### ⚠️ IMPORTANTE: Containers Backend e Frontend

Os containers `conexao-backend` e `conexao-frontend` **NÃO** são gerenciados por este projeto. Eles devem ser iniciados pelos seus respectivos projetos antes de iniciar o Traefik.

### Ordem de Inicialização

1. **Primeiro**: Inicie os containers backend e frontend pelos seus projetos:
   ```bash
   # No projeto backend
   docker-compose up -d
   
   # No projeto frontend  
   docker-compose up -d
   ```

2. **Depois**: Inicie o Traefik:
   ```bash
   # Produção (apenas Traefik + monitoramento)
   docker-compose up -d
   
   # Desenvolvimento local (com override)
   docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
   ```

### Verificação

Para verificar se todos os containers estão rodando corretamente:
```bash
# Verificar containers
docker ps --filter "name=conexao"

# Verificar rede
docker network inspect conexao-network
```

### Deploy Automatizado

```bash
# Deploy completo
./scripts/deploy.sh

# Ou manualmente
docker-compose -f docker-compose.yml up -d
```

## 🔍 Diagnósticos e Troubleshooting

### 🚀 Diagnósticos Automatizados

**Executar diagnósticos rápidos**:
```bash
# Diagnóstico essencial (conectividade, containers, redes)
./scripts/diagnostico-rapido.sh

# Diagnóstico completo (detalhado com logs e métricas)
./scripts/diagnostico-completo.sh
```

**Executar via GitHub Actions**:
- **Manual**: Workflow Dispatch no repositório
- **Automático**: Commits com `[diagnostics]` na mensagem
- **Agendado**: Execução diária para verificações de segurança

### Problemas Comuns

1. **Certificado não gerado**
   - Execute: `./scripts/diagnostico-rapido.sh`
   - Verifique se o domínio aponta para o servidor
   - Confirme que as portas 80/443 estão abertas
   - Verifique os logs: `docker-compose logs traefik`

2. **Serviço não roteado**
   - Execute: `./scripts/diagnostico-completo.sh`
   - Confirme que o serviço está na rede `conexao-network`
   - Verifique as labels do Docker
   - Consulte a API do Traefik: `http://localhost:8090/api/rawdata`

3. **Performance lenta**
   - Verifique health checks dos serviços
   - Analise métricas no Grafana
   - Execute diagnósticos para identificar gargalos

### Status Atual da Infraestrutura

- ✅ **Traefik**: Funcionando corretamente (v3.0)
- ✅ **Conectividade**: Backend e Frontend conectados
- ✅ **Rede Docker**: `conexao-network` ativa
- ✅ **API Traefik**: Acessível na porta 8090
- ✅ **Monitoramento**: Grafana e Prometheus ativos
- ✅ **Diagnósticos**: Automatizados via GitHub Actions

### Logs

```bash
# Logs do Traefik
docker-compose logs -f traefik

# Status dos containers
docker ps --filter name=conexao

# Verificar rede
docker network inspect conexao-network
```

## 📚 Documentação Adicional

- [📊 Diagnósticos Automatizados](DIAGNOSTICOS-AUTOMATIZADOS.md) - Guia completo de diagnósticos
- [🔧 Solução de Problemas SSL/404](SOLUCAO-PROBLEMAS-SSL-404.md) - Problemas resolvidos
- [🏗️ Análise da Arquitetura](ANALISE-ARQUITETURA-TRAEFIK.md) - Arquitetura detalhada
- [📝 Scripts de Diagnóstico](scripts/README.md) - Documentação dos scripts
- [🔐 Configuração SSH](/.github/SSH_SETUP.md) - Setup para CI/CD
- [📖 Documentação Oficial do Traefik](https://doc.traefik.io/traefik/)

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/Wibson82/conexao-traefik-infrastructure/issues)
- **Email**: admin@conexaodesorte.com.br
- **Documentação**: [Wiki do Projeto](https://github.com/Wibson82/conexao-traefik-infrastructure/wiki)

---

**⚠️ Importante**: Este é um componente crítico da infraestrutura. Sempre teste mudanças em ambiente de desenvolvimento antes de aplicar em produção.
