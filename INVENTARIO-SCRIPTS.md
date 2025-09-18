# 📋 INVENTÁRIO E MAPEAMENTO DE SCRIPTS - PIPELINE CI/CD

## 🎯 **RESUMO EXECUTIVO**

**Objetivo**: Migrar todos os scripts externos para blocos inline no workflow YAML
**Status**: Análise completa realizada
**Scripts identificados**: 7 scripts ativos no pipeline atual

## 🔍 **SCRIPTS ATIVOS NO PIPELINE**

### **FASE 1: VALIDAÇÃO (validate-and-build job)**

#### **1. validate-traefik.sh**
- **Localização**: `.github/workflows/scripts/validate-traefik.sh`
- **Função**: Validação de sintaxe YAML e arquivos obrigatórios
- **Fase**: Validação estática
- **Ordem**: 1º script executado
- **Dependências**: python3, python3-yaml
- **Tamanho**: 69 linhas

#### **2. security-validation.sh**
- **Localização**: `.github/workflows/scripts/security-validation.sh`
- **Função**: Validação de configurações de segurança do Traefik
- **Fase**: Validação de segurança
- **Ordem**: 2º script executado
- **Dependências**: bash, grep
- **Tamanho**: 150 linhas

### **FASE 2: DEPLOY (deploy-selfhosted job)**

#### **3. create-docker-secrets.sh**
- **Localização**: `.github/workflows/scripts/create-docker-secrets.sh`
- **Função**: Criação de Docker Secrets para autenticação
- **Fase**: Preparação de deploy
- **Ordem**: 3º script executado
- **Dependências**: docker, Azure Key Vault (OIDC)
- **Tamanho**: ~100 linhas (estimado)

#### **4. validate-secrets.sh**
- **Localização**: `.github/workflows/scripts/validate-secrets.sh`
- **Função**: Validação de secrets do Azure Key Vault
- **Fase**: Validação de secrets
- **Ordem**: 4º script executado
- **Dependências**: Azure CLI, OIDC
- **Tamanho**: ~80 linhas (estimado)

#### **5. deploy-traefik.sh**
- **Localização**: `.github/workflows/scripts/deploy-traefik.sh`
- **Função**: Deploy do stack Traefik no Docker Swarm
- **Fase**: Deploy principal
- **Ordem**: 5º script executado
- **Dependências**: docker stack deploy
- **Tamanho**: 131 linhas

#### **6. healthcheck-traefik.sh**
- **Localização**: `.github/workflows/scripts/healthcheck-traefik.sh`
- **Função**: Verificação de saúde do serviço deployado
- **Fase**: Validação pós-deploy
- **Ordem**: 6º script executado
- **Dependências**: docker service logs
- **Tamanho**: ~50 linhas (estimado)

#### **7. connectivity-validation.sh**
- **Localização**: `.github/workflows/scripts/connectivity-validation.sh`
- **Função**: Validação de conectividade HTTP/HTTPS
- **Fase**: Teste de integração
- **Ordem**: 7º script executado (final)
- **Dependências**: curl, docker
- **Tamanho**: ~100 linhas (estimado)

## 📊 **MAPEAMENTO DE DEPENDÊNCIAS**

```
validate-traefik.sh → security-validation.sh
        ↓
    [Artifact Upload]
        ↓
create-docker-secrets.sh → validate-secrets.sh → deploy-traefik.sh → healthcheck-traefik.sh → connectivity-validation.sh
```

## 🏗️ **CLASSIFICAÇÃO POR FASE**

### **🔍 Validação (2 scripts)**
- `validate-traefik.sh` - Validação sintática
- `security-validation.sh` - Validação de segurança

### **🔐 Preparação (2 scripts)**
- `create-docker-secrets.sh` - Criação de secrets
- `validate-secrets.sh` - Validação de secrets

### **🚀 Deploy (1 script)**
- `deploy-traefik.sh` - Deploy principal

### **✅ Validação Pós-Deploy (2 scripts)**
- `healthcheck-traefik.sh` - Health check
- `connectivity-validation.sh` - Teste de conectividade

## 🎯 **PRÓXIMAS ETAPAS DA MIGRAÇÃO**

1. **Migrar scripts de validação** (validate-traefik.sh, security-validation.sh)
2. **Migrar scripts de preparação** (create-docker-secrets.sh, validate-secrets.sh)
3. **Migrar script de deploy** (deploy-traefik.sh)
4. **Migrar scripts de validação pós-deploy** (healthcheck-traefik.sh, connectivity-validation.sh)
5. **Configurar segurança OIDC + Azure Key Vault**
6. **Validação completa do pipeline refatorado**

## 📈 **MÉTRICAS**

- **Total de scripts**: 7
- **Linhas estimadas**: ~700 linhas
- **Jobs afetados**: 2 (validate-and-build, deploy-selfhosted)
- **Steps afetados**: 7
- **Dependências externas**: docker, python3, Azure CLI (OIDC)

---
**Status**: ✅ Inventário completo | **Próximo**: Migração inline por fases