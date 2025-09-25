# 📊 Log Server - Monitoramento Completo do Sistema

## 🎯 Visão Geral

Sistema completo de monitoramento de logs e status de todos os containers backend e infraestrutura, disponível através do endpoint `conexaodesorte.com.br/rest/v1/log-servidor`.

## 🌐 Endpoint Principal

```
GET https://conexaodesorte.com.br/rest/v1/log-servidor
```

### 🔐 Autenticação Condicional

- **🟢 Acesso Público**: Enquanto o sistema não estiver 100% funcional
- **🔒 Autenticação Requerida**: Quando todos os serviços estiverem executando sem erros
  - **Usuário**: `admin`
  - **Senha**: `senha`
  - **Método**: HTTP Basic Authentication

## 📋 Funcionalidades

### 🔍 Monitoramento Automático
- ✅ Execução automática a cada minuto via crontab
- ✅ Análise de todos os containers backend e infraestrutura
- ✅ Detecção de containers em loop, crashados, starting
- ✅ Identificação de projetos com problemas de health check
- ✅ Extração de logs de erro dos últimos 50 registros

### 📊 Informações Fornecidas

#### Backend Projects
- conexao-gateway
- conexao-autenticacao
- conexao-resultados
- conexao-scheduler
- conexao-notificacoes
- conexao-batepapo
- conexao-chatbot
- conexao-observabilidade
- conexao-financeiro
- conexao-auditoria-compliance
- conexao-criptografia-kms

#### Infrastructure Projects
- conexao-mysql
- conexao-redis
- conexao-kafka
- conexao-zookeeper
- conexao-rabbitmq
- conexao-traefik
- conexao-jaeger

### 📈 Métricas por Container
```json
{
  "name": "conexao-gateway",
  "state": "running",
  "health": "healthy",
  "restart_count": 0,
  "uptime": "3600s",
  "errors": ["error message 1", "error message 2"],
  "checked_at": "2025-09-25T14:30:00Z"
}
```

### 📊 Resumo do Sistema
```json
{
  "summary": {
    "total_expected": 18,
    "running": 15,
    "unhealthy": 2,
    "success_rate": 83.33,
    "system_status": "degraded",
    "auth_required": false
  }
}
```

## 🔧 Arquitetura Técnica

### 🐳 Container: log-server
- **Base**: Python 3.11 Alpine
- **Porta**: 9090
- **Usuário**: 1000:1000 (não-privilegiado)
- **Resources**:
  - **Limits**: 256MB RAM, 0.2 CPU
  - **Reservations**: 128MB RAM, 0.1 CPU

### 📁 Estrutura de Arquivos
```
/app/
├── scripts/
│   ├── server-monitor.sh      # Script principal de monitoramento
│   └── cronjob-monitor.sh     # Script de execução via cron
├── health-server/
│   ├── log-server.py          # Servidor HTTP Python
│   └── entrypoint.sh          # Script de inicialização
└── logs/
    ├── server-monitor.json    # Dados de monitoramento atualizados
    ├── cron-monitor.log       # Logs de execução do cron
    └── monitor-execution.log  # Logs de execução do monitor
```

### 🔄 Processo de Monitoramento

1. **Cron Job**: Executa `cronjob-monitor.sh` a cada minuto
2. **Monitor Script**: `server-monitor.sh` coleta dados dos containers
3. **Data Processing**: Gera JSON estruturado com todas as informações
4. **API Server**: `log-server.py` serve os dados via HTTP
5. **Traefik Routing**: Rota `conexaodesorte.com.br/rest/v1/log-servidor`

## 🚀 Deploy

### Via Docker Swarm
```bash
# O serviço está integrado ao docker-compose.yml do Traefik
docker stack deploy -c docker-compose.yml traefik-stack
```

### Verificação
```bash
# Verificar se o serviço está rodando
docker service ls | grep log-server

# Verificar logs do serviço
docker service logs traefik-stack_log-server

# Testar endpoint localmente
curl http://localhost:9090/health
curl http://localhost:9090/rest/v1/log-servidor
```

## 🔍 Endpoints Disponíveis

### Principais
- `GET /rest/v1/log-servidor` - Dados completos de monitoramento
- `GET /health` - Health check do log server
- `GET /` - Informações básicas do serviço

### Dados de Resposta
```json
{
  "server_logs": {
    "timestamp": "2025-09-25T14:30:00Z",
    "monitoring": {
      "backend_projects": [...],
      "infrastructure_projects": [...]
    },
    "summary": {...},
    "docker_info": {...}
  },
  "endpoint_info": {
    "path": "/rest/v1/log-servidor",
    "auth_required": false,
    "auth_note": "Acesso público enquanto sistema não está 100% funcional...",
    "generated_at": "2025-09-25T14:30:00Z"
  },
  "domain": "conexaodesorte.com.br"
}
```

## 🔒 Segurança

### 🔐 Controle de Acesso Inteligente
- **Público**: Durante desenvolvimento e correção de problemas
- **Privado**: Quando sistema estiver 100% operacional (todos os containers running e healthy)

### 🛡️ Medidas de Segurança
- ✅ Container não-privilegiado (user 1000:1000)
- ✅ Docker socket read-only
- ✅ CORS configurado para domínios específicos
- ✅ Health checks para monitoramento de status
- ✅ Logs estruturados e limitados

## 📝 Logs e Troubleshooting

### Verificar Status
```bash
# Status do container
docker ps | grep log-server

# Logs em tempo real
docker logs -f <container_id>

# Verificar arquivos de log
docker exec <container_id> ls -la /app/logs/

# Ver dados de monitoramento
docker exec <container_id> cat /app/logs/server-monitor.json
```

### Problemas Comuns

#### ❌ "Monitor data not available"
```bash
# Verificar se o script está executando
docker exec <container_id> /app/scripts/server-monitor.sh
```

#### ❌ "Authentication required" (inesperado)
```bash
# Verificar se todos os serviços estão realmente healthy
curl -s https://conexaodesorte.com.br/rest/v1/log-servidor | jq '.server_logs.summary'
```

#### ❌ Container não inicia
```bash
# Verificar logs de build
docker logs <container_id>

# Verificar permissões
docker exec <container_id> ls -la /app/
```

## 🔄 Atualizações e Manutenção

### Atualizar Scripts
1. Modificar scripts em `/scripts/`
2. Rebuild da imagem
3. Deploy via Docker Swarm

### Modificar Frequência de Monitoramento
- Editar crontab em `entrypoint.sh`
- Atualmente: `* * * * *` (a cada minuto)
- Exemplo para a cada 30 segundos: Adicionar segundo cron job

### Ajustar Configurações
- **Timeout**: Modificar em `server-monitor.sh`
- **Logs de erro**: Ajustar `--tail=50` conforme necessário
- **Resources**: Modificar limits no `docker-compose.yml`

---

## 📞 Suporte

Para problemas ou melhorias no sistema de monitoramento, verificar:
1. Logs do container log-server
2. Arquivo `/app/logs/server-monitor.json`
3. Conectividade com Docker daemon
4. Status dos containers monitorados

**Versão**: 1.0.0
**Data**: 2025-09-25
**Autor**: Sistema de Monitoramento Conexão de Sorte