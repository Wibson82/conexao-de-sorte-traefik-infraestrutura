# 🔧 Diagnósticos Automatizados - Traefik Infrastructure

## 📋 Visão Geral

Este documento descreve como executar diagnósticos automatizados da infraestrutura Traefik, tanto via GitHub Actions quanto diretamente no servidor.

## 🚀 Métodos de Execução

### 1. Via GitHub Actions (Recomendado)

#### Execução Manual
1. Acesse o repositório no GitHub
2. Vá para a aba **Actions**
3. Selecione o workflow **"🚀 Traefik Infrastructure - Pipeline Principal"**
4. Clique em **"Run workflow"**
5. Selecione a branch `main`
6. Clique em **"Run workflow"**

#### Execução Automática
Os diagnósticos são executados automaticamente:
- **Diariamente às 02:00 UTC** (verificações de segurança)
- **Em commits com `[diagnostics]`** na mensagem
- **Em pushes para a branch main**

### 2. Via SSH Direto no Servidor

```bash
# Conectar ao servidor
ssh root@srv649924.hostgator.com.br

# Executar diagnóstico rápido (30 segundos)
~/diagnostico-rapido.sh

# OU executar diagnóstico completo (2-3 minutos)
~/diagnostico-completo.sh
```

## 📊 Resultados dos Diagnósticos

### ✅ Status Confirmado (Baseado nos Testes Realizados)

**Conectividade Interna:**
- ✅ Traefik → Backend: `http://backend-prod:8080/actuator/health`
- ✅ Traefik → Frontend: `http://conexao-frontend:3000`
- ✅ Containers conectados à rede `conexao-network`
- ✅ Health check do backend retornando status "UP"

**Containers Ativos:**
```
NAMES                STATUS                PORTS
conexao-frontend     Up 42 minutes (healthy)  0.0.0.0:3000->3000/tcp
conexao-traefik      Up 52 minutes (healthy)  0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8090->8080/tcp
backend-prod         Up 2 days (healthy)       8080/tcp
conexao-mysql        Up 2 days                 0.0.0.0:3306->3306/tcp
conexao-prometheus   Up 2 days                 0.0.0.0:9090->9090/tcp
```

**Health Check do Backend:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"],
  "components": {
    "armazenamento": {"status": "UP"},
    "azureKeyVault": {"status": "UP"},
    "bancoDados": {"status": "UP"},
    "db": {"status": "UP"},
    "diskSpace": {"status": "UP"},
    "performance": {"status": "UP"},
    "securityCompliance": {"status": "UP"}
  }
}
```

## 🔍 Comandos de Diagnóstico Validados

Estes comandos foram testados e confirmados como funcionais:

### Verificação de Containers
```bash
docker container ps
```

### Teste de Conectividade Interna
```bash
# Backend health check
docker exec conexao-traefik wget -qO- http://backend-prod:8080/actuator/health

# Frontend connectivity
docker exec conexao-traefik wget -qO- http://conexao-frontend:3000
```

### Verificação de Redes
```bash
# Listar redes
docker network ls

# Inspecionar rede específica
docker network inspect conexao-network

# Conectar containers (se necessário)
docker network connect conexao-network backend-prod
docker network connect conexao-network conexao-frontend
```

## 📋 Interpretação dos Resultados

### 🟢 Sinais de Saúde (Tudo OK)
- ✅ Todos os containers principais estão "Up" e "healthy"
- ✅ Health check do backend retorna `{"status": "UP"}`
- ✅ Conectividade interna Traefik → Backend/Frontend funciona
- ✅ Containers estão conectados à rede `conexao-network`
- ✅ API do Traefik acessível na porta 8090

### 🟡 Sinais de Atenção
- ⚠️ Containers com status "Restarting"
- ⚠️ Health check com warnings (mas status "UP")
- ⚠️ Certificados SSL próximos do vencimento
- ⚠️ Logs com mensagens de erro não críticas

### 🔴 Sinais de Problema
- ❌ Containers com status "Exited" ou "Dead"
- ❌ Health check retornando `{"status": "DOWN"}`
- ❌ Falha na conectividade interna
- ❌ API do Traefik inacessível
- ❌ Certificados SSL expirados

## 🛠️ Ações Corretivas Automáticas

### Problemas de Rede
```bash
# Reconectar containers à rede
docker network connect conexao-network backend-prod
docker network connect conexao-network conexao-frontend
```

### Restart de Containers
```bash
# Restart do Traefik
docker restart conexao-traefik

# Restart de todos os serviços
cd ~/traefik-deploy/current
docker compose restart
```

### Verificação de Logs
```bash
# Logs do Traefik
docker logs conexao-traefik --tail=50

# Logs do Backend
docker logs backend-prod --tail=50
```

## 📊 Monitoramento Contínuo

### Execução Programada
Os diagnósticos são executados automaticamente:
- **Diariamente às 02:00 UTC** via GitHub Actions
- **A cada deploy** para validar a infraestrutura
- **Em caso de problemas reportados** via trigger manual

### Alertas e Notificações
- Falhas nos diagnósticos geram logs detalhados no GitHub Actions
- Problemas críticos são destacados nos relatórios
- Recomendações específicas são fornecidas para cada tipo de problema

## 🎯 Próximos Passos

Com base nos resultados dos diagnósticos confirmados:

1. **✅ Infraestrutura Funcional**: A conectividade entre Traefik e os serviços está OK
2. **🔍 Foco em SSL**: Próxima prioridade é resolver os certificados SSL vazios
3. **📋 Monitoramento**: Manter execução regular dos diagnósticos
4. **🔧 Otimização**: Considerar melhorias baseadas nos relatórios

## 📞 Suporte

Em caso de problemas:
1. Execute primeiro o diagnóstico rápido: `~/diagnostico-rapido.sh`
2. Se necessário, execute o diagnóstico completo: `~/diagnostico-completo.sh`
3. Verifique os logs detalhados no GitHub Actions
4. Consulte a documentação em `ANALISE-ARQUITETURA-TRAEFIK.md`

---

**Última atualização:** $(date -u +%Y-%m-%dT%H:%M:%SZ)  
**Status da infraestrutura:** ✅ Conectividade confirmada  
**Próxima verificação automática:** Diariamente às 02:00 UTC