# 🏥 Health Monitor Centralizado - Traefik

## 📋 Visão Geral

O Health Monitor Centralizado é uma extensão do Traefik que fornece endpoints HTTPS seguros para monitoramento do status de todos os microserviços e infraestrutura do projeto Conexão de Sorte.

### ✅ Benefícios

- **🔗 Integração GitHub Actions**: Workflows podem validar deploys automaticamente
- **📊 Monitoramento Centralizado**: Um ponto único para verificar todos os serviços
- **🚀 Deploy Inteligente**: Rollback automático em caso de falha de health check
- **📈 Observabilidade**: Dashboard consolidado do status da infraestrutura
- **🔒 Seguro**: Endpoints HTTPS com certificados Let's Encrypt

## 🌐 Endpoints Disponíveis

### 1. Status Geral
```bash
GET https://traefik.conexaodesorte.com.br/health/overall
```
**Retorna:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "services": 15,
  "healthy": 12,
  "starting": 2,
  "down": 1,
  "uptime_threshold": 80
}
```

### 2. Infraestrutura
```bash
GET https://traefik.conexaodesorte.com.br/health/infrastructure
```
**Retorna:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "services": 6,
  "healthy": 6,
  "mysql": "healthy",
  "redis": "healthy",
  "rabbitmq": "healthy",
  "kafka": "healthy",
  "zookeeper": "healthy",
  "traefik": "healthy"
}
```

### 3. Backend Services
```bash
GET https://traefik.conexaodesorte.com.br/health/backend
```
**Retorna:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "degraded",
  "services": 11,
  "healthy": 7,
  "gateway": "healthy",
  "resultados": "healthy",
  "autenticacao": "starting",
  "usuario": "down"
}
```

### 4. Serviço Individual
```bash
GET https://traefik.conexaodesorte.com.br/health/service/{service_name}
```
**Exemplo:**
```bash
GET https://traefik.conexaodesorte.com.br/health/service/resultados
```
**Retorna:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy",
  "service": "resultados",
  "uptime": "2h30m",
  "version": "1.0.0",
  "url": "conexao-resultados:8083"
}
```

## 🔧 Estados Possíveis

| Estado | Descrição | Ação Recomendada |
|--------|-----------|------------------|
| `healthy` | Serviço funcionando normalmente | ✅ Nenhuma |
| `starting` | Serviço iniciando (health check em progresso) | ⏳ Aguardar |
| `degraded` | Alguns serviços indisponíveis | ⚠️ Investigar |
| `down` | Serviço indisponível | ❌ Correção urgente |
| `critical` | Sistema em falha crítica | 🚨 Ação imediata |

## 🚀 Integração GitHub Actions

### Exemplo Básico
```yaml
- name: 🏥 Validate deployment
  run: |
    SERVICE_NAME="resultados"
    HEALTH_URL="https://traefik.conexaodesorte.com.br/health/service/${SERVICE_NAME}"

    # Wait for service to become healthy (max 5 minutes)
    timeout 300 bash -c "
      while true; do
        response=\$(curl -s -f '$HEALTH_URL' || echo '{\"status\":\"error\"}')
        status=\$(echo \"\$response\" | jq -r '.status // \"error\"')

        case \"\$status\" in
          'healthy')
            echo '✅ Service is healthy'
            exit 0
            ;;
          'starting')
            echo '⏳ Service starting... waiting 10s'
            sleep 10
            ;;
          *)
            echo '❌ Service failed health check'
            exit 1
            ;;
        esac
      done
    "
```

### Exemplo Avançado com Rollback
```yaml
- name: 🏥 Advanced health check with rollback
  run: |
    OVERALL_URL="https://traefik.conexaodesorte.com.br/health/overall"

    # Check overall system health
    response=$(curl -s -f "$OVERALL_URL")
    healthy=$(echo "$response" | jq -r '.healthy')
    total=$(echo "$response" | jq -r '.services')
    health_percentage=$((healthy * 100 / total))

    if [[ $health_percentage -ge 80 ]]; then
      echo "✅ System health: $health_percentage% ($healthy/$total services)"
    else
      echo "❌ System degraded: $health_percentage% - initiating rollback"
      docker service update --rollback conexao-resultados_resultados
      exit 1
    fi
```

## 📊 Monitoramento Contínuo

### Cron Job para Monitoramento
```yaml
schedule:
  - cron: '*/15 * * * *'  # Every 15 minutes

jobs:
  health_monitoring:
    steps:
      - name: 🏥 System health check
        run: |
          response=$(curl -s https://traefik.conexaodesorte.com.br/health/overall)
          status=$(echo "$response" | jq -r '.status')

          if [[ "$status" == "critical" ]]; then
            # Create GitHub issue for critical failures
            gh issue create \
              --title "🚨 CRITICAL: System Health Failure" \
              --body "Critical system failure detected. Response: $response" \
              --label "critical,infrastructure"
          fi
```

## 🔧 Configuração

### 1. Deploy do Health Monitor
```bash
# 1. Navegar para o diretório do Traefik
cd /caminho/para/conexao-de-sorte-traefik-infraestrutura

# 2. Verificar configuração
docker compose config -q

# 3. Deploy via Docker Swarm
docker stack deploy -c docker-compose.yml conexao-traefik

# 4. Verificar serviços
docker service ls | grep traefik
```

### 2. Verificar Health Monitor
```bash
# Verificar se o health monitor está rodando
docker service ps conexao-traefik_health-monitor

# Testar endpoints
curl -f https://traefik.conexaodesorte.com.br/health/overall
```

### 3. Configurar DNS (se necessário)
```bash
# Adicionar entrada DNS apontando para o servidor
# traefik.conexaodesorte.com.br -> IP_DO_SERVIDOR
```

## 🛡️ Segurança

### Headers de Segurança
- **CORS**: Configurado para GitHub Actions e domínios autorizados
- **HTTPS**: Obrigatório com certificados Let's Encrypt
- **Rate Limiting**: Proteção contra abuso (implementar se necessário)
- **Cache Control**: No-cache para dados em tempo real

### Autenticação
```bash
# Para endpoints públicos (monitoramento)
GET /health/overall  # Público

# Para endpoints sensíveis (configurar se necessário)
GET /health/admin    # Requer autenticação
```

## 🔍 Troubleshooting

### Health Monitor não responde
```bash
# 1. Verificar se o container está rodando
docker service ps conexao-traefik_health-monitor

# 2. Verificar logs
docker service logs conexao-traefik_health-monitor

# 3. Verificar conectividade de rede
docker exec -it $(docker ps -q -f name=traefik) ping health-monitor
```

### Serviços aparecem como "down" incorretamente
```bash
# 1. Verificar se os containers estão realmente rodando
docker ps | grep conexao

# 2. Verificar health checks dos containers
docker inspect container_name | jq '.[0].State.Health'

# 3. Testar conectividade manual
curl -f http://conexao-resultados:8083/actuator/health
```

### Endpoints retornam erro 404
```bash
# 1. Verificar labels do Traefik
docker service inspect conexao-traefik_health-monitor

# 2. Verificar configuração dinâmica
docker exec -it $(docker ps -q -f name=traefik) cat /etc/traefik/dynamic/health-monitor.yml

# 3. Verificar certificados SSL
curl -I https://traefik.conexaodesorte.com.br/health/overall
```

## 📈 Métricas e Observabilidade

### Prometheus Integration
O health monitor expõe métricas compatíveis com Prometheus:

```bash
# Métricas disponíveis em
GET https://traefik.conexaodesorte.com.br/metrics

# Exemplos de métricas:
# - conexao_services_total{type="infrastructure"}
# - conexao_services_healthy{type="backend"}
# - conexao_health_check_duration_seconds
```

### Dashboard Grafana
```json
{
  "dashboard": {
    "title": "Conexão de Sorte - Health Monitor",
    "panels": [
      {
        "title": "Overall System Health",
        "type": "stat",
        "targets": [
          {
            "expr": "conexao_services_healthy / conexao_services_total * 100"
          }
        ]
      }
    ]
  }
}
```

## 🎯 Próximos Passos

1. **Deploy**: Implementar em produção
2. **Teste**: Validar todos os endpoints
3. **Integração**: Adicionar aos workflows existentes
4. **Monitoramento**: Configurar alertas no Grafana
5. **Documentação**: Treinar equipe no uso dos endpoints

---

**🤖 Generated with Claude Code**
**Co-Authored-By: Claude <noreply@anthropic.com>**