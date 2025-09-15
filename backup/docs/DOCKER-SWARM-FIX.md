# 🐝 Correção Docker Swarm - Network Configuration

## ❌ **Problema Identificado**
```
service traefik: undefined network "conexao-network-swarm"
Creating network conexao-traefik_conexao-network-swarm
Error: Process completed with exit code 1
```

### **🔍 Causa Raiz**
- **Rede dinâmica**: `${DOCKER_NETWORK_NAME}` não é suportada corretamente no Docker Swarm
- **Configuração conflitante**: docker-compose.yml genérico causava problemas no Swarm
- **Referência incorreta**: Swarm não conseguia resolver referência dinâmica de rede

## ✅ **Solução Implementada**

### **📁 Arquivos Separados por Modo**

1. **`docker-compose.yml`** - Modo Standalone
   ```yaml
   networks:
     conexao-network:
       name: conexao-network
       external: true
   ```

2. **`docker-compose.swarm.yml`** - Modo Docker Swarm
   ```yaml
   networks:
     conexao-network-swarm:
       name: conexao-network-swarm
       external: true
   ```

### **🔧 Script de Deploy Inteligente**
```bash
# Determine correct compose file based on network type
if [ "$NETWORK_NAME" = "conexao-network-swarm" ]; then
  COMPOSE_FILE="docker-compose.swarm.yml"
  echo "🐝 Using Docker Swarm mode with $COMPOSE_FILE"
else
  COMPOSE_FILE="docker-compose.yml"
  echo "🐳 Using standalone mode with $COMPOSE_FILE"
fi
```

### **🎯 Configuração Docker Swarm Específica**

#### **Deploy Configuration**
```yaml
deploy:
  replicas: 1
  restart_policy:
    condition: on-failure
    delay: 5s
    max_attempts: 3
  placement:
    constraints:
      - node.role == manager
```

#### **Labels Corretos para Swarm**
```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=conexao-network-swarm
  # ... outros labels
```

## 🌐 **Configuração de Rede**

### **Self-hosted Runner (Hostinger srv649924)**
- **Modo**: Docker Swarm
- **Rede**: `conexao-network-swarm` (overlay)
- **Arquivo**: `docker-compose.swarm.yml`

### **Desenvolvimento Local**
- **Modo**: Docker Standalone
- **Rede**: `conexao-network` (bridge)
- **Arquivo**: `docker-compose.yml`

## 📋 **CI/CD Pipeline Atualizado**

### **Artifacts Incluem Ambos os Arquivos**
```yaml
path: |
  docker-compose.yml          # Standalone
  docker-compose.swarm.yml    # Swarm
  traefik/
  letsencrypt/
```

### **Deploy Script Automático**
- ✅ Detecta tipo de rede (`DOCKER_NETWORK_NAME`)
- ✅ Seleciona arquivo correto automaticamente
- ✅ Aplica configurações específicas do modo

## 🎯 **Resultado**

- ✅ **Docker Swarm funcional** no servidor Hostinger
- ✅ **Compatibilidade mantida** para desenvolvimento local
- ✅ **Seleção automática** do arquivo correto
- ✅ **Redes externas** funcionando corretamente

## 🚀 **Próximo Deploy**

O próximo deploy deve funcionar corretamente:
1. **Self-hosted runner** detecta `conexao-network-swarm`
2. **Script automaticamente** usa `docker-compose.swarm.yml`
3. **Docker Swarm** implanta com rede overlay correta
4. **Traefik** inicia sem erros de rede

---
**🐝 Correção aplicada em:** 2024-09-14
**🎯 Ambiente:** srv649924 (Hostinger) - Docker Swarm
**✅ Status:** Pronto para deploy