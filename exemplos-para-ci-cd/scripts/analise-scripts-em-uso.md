# Análise de Scripts em Uso - Conexão de Sorte

## 📋 Scripts Ativamente Utilizados

### **✅ SCRIPTS CRÍTICOS EM USO**

#### **1. Scripts de Deploy e Inicialização**
- `scripts/utils/backend-init.sh` ✅ **CRÍTICO** - Usado no Dockerfile
- `scripts/utils/backend-init-test.sh` ✅ **CRÍTICO** - Usado no docker-compose.yml
- `deploy/scripts/deploy-manual.sh` ✅ **EM USO** - Referenciado na documentação
- `scripts/deploy/stop-loop.sh` ✅ **EM USO** - Criado recentemente para produção

#### **2. Scripts de Validação e Health Check**
- `scripts/utils/validate-health-endpoint.sh` ✅ **EM USO** - Validação de endpoints
- `scripts/utils/validate-port.sh` ✅ **EM USO** - Validação de portas
- `scripts/deploy/run-validation.sh` ✅ **EM USO** - Validação de deploy

#### **3. Scripts de Configuração Azure**
- `scripts/azure/setup-jwt-keys.sh` ✅ **EM USO** - Configuração JWT
- `ops/update-secrets.sh` ✅ **EM USO** - Sincronização de segredos

#### **4. Scripts de Geração de Configuração**
- `config/traefik/generate-traefik-config.sh` ✅ **EM USO** - Geração Traefik

### **❌ SCRIPTS DESNECESSÁRIOS (MOVER PARA BACKUP)**

#### **1. Scripts Duplicados/Obsoletos**
- Todos os scripts em `scripts/backup/` ❌ **JÁ EM BACKUP**
- `backup/` (pasta inteira) ❌ **JÁ EM BACKUP**
- `migration-plans/` ❌ **OBSOLETO**
- `ops/agent/` ❌ **NÃO USADO**

#### **2. Scripts de Desenvolvimento/Teste Obsoletos**
- `.vscode/setup-java-home.sh` ❌ **DESENVOLVIMENTO**
- `tools/owasp/` ❌ **FERRAMENTAS EXTERNAS**

### **🔧 SCRIPTS PARA ANÁLISE DETALHADA**

#### **1. Scripts Possivelmente Úteis**
- `ops/run_automation.sh` ⚠️ **VERIFICAR USO**
- `scripts/atualizar-estrutura-ddd.sh` ⚠️ **VERIFICAR USO**

## 📊 Resumo da Análise

### **Estatísticas**
- **Total de scripts encontrados**: 150+
- **Scripts críticos em uso**: 8
- **Scripts em backup**: 120+
- **Scripts para análise**: 2
- **Scripts para mover**: 20+

### **Ações Recomendadas**

#### **1. Manter (8 scripts)**
```bash
scripts/utils/backend-init.sh
scripts/utils/backend-init-test.sh
scripts/utils/validate-health-endpoint.sh
scripts/utils/validate-port.sh
scripts/deploy/run-validation.sh
scripts/deploy/stop-loop.sh
scripts/azure/setup-jwt-keys.sh
config/traefik/generate-traefik-config.sh
```

#### **2. Mover para Backup**
```bash
.vscode/
migration-plans/
ops/agent/
tools/owasp/
deploy/scripts/ (exceto deploy-manual.sh)
```

#### **3. Verificar Uso**
```bash
ops/run_automation.sh
ops/update-secrets.sh
scripts/atualizar-estrutura-ddd.sh
```

## 🎯 Plano de Limpeza

### **Fase 1: Backup Seguro**
1. Criar `scripts/backup-limpeza/`
2. Mover scripts não utilizados
3. Manter estrutura de referência

### **Fase 2: Validação**
1. Compilar projeto
2. Executar testes
3. Validar funcionalidade

### **Fase 3: Commit**
1. Commit das mudanças
2. Push para validação
3. Monitorar produção
