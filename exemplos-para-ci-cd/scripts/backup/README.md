# Scripts de Automação - Conexão de Sorte Backend

Este diretório contém scripts de automação para gerenciamento, monitoramento e deploy do sistema Conexão de Sorte Backend.

## 📋 Índice

- [Scripts Disponíveis](#scripts-disponíveis)
- [Configuração Inicial](#configuração-inicial)
- [Ambiente de Desenvolvimento](#ambiente-de-desenvolvimento)
- [Produção](#produção)
- [Monitoramento](#monitoramento)
- [Backup e Recuperação](#backup-e-recuperação)
- [Troubleshooting](#troubleshooting)

## 🚀 Scripts Disponíveis

### 1. Setup e Configuração

#### `setup-dev-environment.sh`
**Função:** Configurar ambiente de desenvolvimento local

```bash
# Configurar ambiente completo
./scripts/setup-dev-environment.sh
```

**O que faz:**
- Verifica pré-requisitos (Java 21+, Maven, Docker, Git)
- Cria estrutura de diretórios
- Configura arquivos de ambiente (.env.dev, .env.test)
- Configura Maven e Docker
- Configura Git hooks
- Cria scripts auxiliares

#### `setup-volumes.sh`
**Função:** Gerenciar volumes Docker

```bash
# Criar todos os volumes
./scripts/setup-volumes.sh create

# Verificar volumes existentes
./scripts/setup-volumes.sh verify

# Mostrar informações dos volumes
./scripts/setup-volumes.sh info

# Fazer backup dos volumes
./scripts/setup-volumes.sh backup

# Restaurar volumes do backup
./scripts/setup-volumes.sh restore /path/to/backup

# Limpar todos os volumes (PERIGOSO)
./scripts/setup-volumes.sh cleanup

# Menu interativo
./scripts/setup-volumes.sh
```

### 2. Desenvolvimento

#### `start-dev.sh`
**Função:** Iniciar ambiente de desenvolvimento

```bash
./scripts/start-dev.sh
```

**Serviços iniciados:**
- Aplicação: http://localhost:8080
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090
- SonarQube: http://localhost:9000 (admin/admin)

#### `stop-dev.sh`
**Função:** Parar ambiente de desenvolvimento

```bash
./scripts/stop-dev.sh
```

#### `run-tests.sh`
**Função:** Executar testes e gerar relatórios

```bash
./scripts/run-tests.sh
```

**O que executa:**
- Testes unitários
- Testes de integração
- Relatório de cobertura (target/site/jacoco/index.html)

#### `build-app.sh`
**Função:** Build completo da aplicação

```bash
./scripts/build-app.sh
```

**O que faz:**
- Compila o código
- Executa testes
- Gera JAR
- Constrói imagem Docker

### 3. Produção

#### `deploy-production.sh`
**Função:** Deploy automatizado com Blue-Green deployment

```bash
# Deploy com tag latest
./scripts/deploy-production.sh deploy

# Deploy com tag específica
./scripts/deploy-production.sh deploy v1.2.3

# Verificar status
./scripts/deploy-production.sh status

# Criar backup manual
./scripts/deploy-production.sh backup

# Rollback
./scripts/deploy-production.sh rollback /path/to/backup
```

**Processo de Deploy:**
1. Verificação de pré-requisitos
2. Backup automático
3. Deploy no ambiente inativo
4. Verificação de saúde
5. Troca de tráfego
6. Verificações pós-deploy
7. Limpeza do ambiente antigo

### 4. Backup

#### `backup-automatizado.sh`
**Função:** Sistema completo de backup automatizado

```bash
# Backup completo
./scripts/backup-automatizado.sh full

# Backup incremental do MySQL
./scripts/backup-automatizado.sh mysql-incremental

# Backup do Key Vault
./scripts/backup-automatizado.sh keyvault

# Verificar integridade
./scripts/backup-automatizado.sh verify

# Limpeza de backups antigos
./scripts/backup-automatizado.sh cleanup

# Relatório de status
./scripts/backup-automatizado.sh report

# Restaurar backup
./scripts/backup-automatizado.sh restore /path/to/backup

# Monitoramento de espaço
./scripts/backup-automatizado.sh monitor-space
```

**Tipos de Backup:**
- **Completo:** MySQL, Key Vault, configurações, volumes, logs
- **Incremental:** Apenas mudanças desde último backup
- **Key Vault:** Secrets e certificados do Azure

### 5. Monitoramento

#### `health-check.sh`
**Função:** Monitoramento de saúde do sistema

```bash
# Relatório completo
./scripts/health-check.sh

# Verificações específicas
./scripts/health-check.sh system      # Recursos do sistema
./scripts/health-check.sh docker      # Serviços Docker
./scripts/health-check.sh endpoints   # Endpoints de saúde
./scripts/health-check.sh database    # Banco de dados
./scripts/health-check.sh volumes     # Volumes Docker
./scripts/health-check.sh logs        # Logs do sistema
./scripts/health-check.sh security    # Aspectos de segurança

# Monitoramento contínuo
./scripts/health-check.sh monitor 60  # Intervalo de 60 segundos
```

**Verificações Realizadas:**
- Uso de CPU, memória e disco
- Status dos containers Docker
- Saúde dos endpoints
- Conectividade do banco
- Integridade dos volumes
- Análise de logs
- Verificações de segurança

## ⚙️ Configuração Inicial

### 1. Primeiro Setup

```bash
# 1. Configurar ambiente de desenvolvimento
./scripts/setup-dev-environment.sh

# 2. Criar volumes Docker
./scripts/setup-volumes.sh create

# 3. Configurar arquivos .env
vim .env.dev
vim .env.test
```

### 2. Variáveis de Ambiente

#### `.env.dev` (Desenvolvimento)
```bash
# Aplicação
SPRING_PROFILES_ACTIVE=dev
SERVER_PORT=8080

# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=conexao_sorte_dev
DB_USERNAME=dev_user
DB_PASSWORD=dev_password

# Azure Key Vault
AZURE_KEYVAULT_URI=https://dev-conexao-sorte-kv.vault.azure.net/
AZURE_CLIENT_ID=your_dev_client_id
AZURE_CLIENT_SECRET=your_dev_client_secret
AZURE_TENANT_ID=your_tenant_id

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
ALERTMANAGER_PORT=9093
```

#### `.env.prod` (Produção)
```bash
# Aplicação
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080

# Database
DB_HOST=mysql
DB_PORT=3306
DB_NAME=conexao_sorte_prod
DB_USERNAME=prod_user
DB_PASSWORD=secure_prod_password

# Azure Key Vault
AZURE_KEYVAULT_URI=https://prod-conexao-sorte-kv.vault.azure.net/
AZURE_CLIENT_ID=your_prod_client_id
AZURE_CLIENT_SECRET=your_prod_client_secret
AZURE_TENANT_ID=your_tenant_id

# Backup
BACKUP_RETENTION_DAYS=90
BACKUP_ENCRYPTION_KEY=your_backup_encryption_key
```

## 🔧 Ambiente de Desenvolvimento

### Workflow Típico

```bash
# 1. Iniciar ambiente
./scripts/start-dev.sh

# 2. Desenvolver código...

# 3. Executar testes
./scripts/run-tests.sh

# 4. Build da aplicação
./scripts/build-app.sh

# 5. Verificar saúde
./scripts/health-check.sh

# 6. Parar ambiente
./scripts/stop-dev.sh
```

### Debugging

```bash
# Ver logs da aplicação
docker logs backend-green -f

# Ver logs do banco
docker logs mysql -f

# Executar health check específico
./scripts/health-check.sh endpoints

# Verificar volumes
./scripts/setup-volumes.sh info
```

## 🚀 Produção

### Deploy Process

```bash
# 1. Build da nova versão
./scripts/build-app.sh

# 2. Tag da imagem
docker tag conexao-de-sorte-backend:latest conexao-de-sorte-backend:v1.2.3

# 3. Deploy
./scripts/deploy-production.sh deploy v1.2.3

# 4. Verificar status
./scripts/health-check.sh
```

### Rollback

```bash
# Listar backups disponíveis
ls -la backups/deploy-*/

# Fazer rollback
./scripts/deploy-production.sh rollback backups/deploy-20231201_143022
```

### Monitoramento Contínuo

```bash
# Monitoramento em tempo real
./scripts/health-check.sh monitor 30

# Backup automático (configurar no cron)
./scripts/backup-automatizado.sh full
```

## 📊 Monitoramento

### Dashboards Disponíveis

- **Grafana:** http://localhost:3000
  - Application Metrics
  - Infrastructure Metrics
  - Business Metrics
  - LGPD Compliance

- **Prometheus:** http://localhost:9090
  - Métricas em tempo real
  - Alertas configurados

### Alertas Configurados

- **Críticos:**
  - Aplicação down
  - Banco de dados down
  - Uso crítico de memória
  - Falhas de processamento LGPD

- **Warning:**
  - Alta latência
  - Alto uso de CPU/memória
  - Taxa de erro elevada
  - Muitas conexões no banco

### Health Checks

```bash
# Verificação completa
./scripts/health-check.sh report

# Verificações específicas
./scripts/health-check.sh system
./scripts/health-check.sh database
./scripts/health-check.sh security
```

## 💾 Backup e Recuperação

### Estratégia de Backup

- **Diário:** Backup completo às 02:00
- **A cada 6h:** Backup incremental do MySQL
- **Diário:** Backup do Azure Key Vault
- **Semanal:** Verificação de integridade
- **Mensal:** Relatório de backup

### Configuração do Cron

```bash
# Instalar crontab
crontab deploy/cron/backup-crontab

# Verificar cron instalado
crontab -l
```

### Restauração

```bash
# Listar backups
ls -la backups/

# Restaurar backup específico
./scripts/backup-automatizado.sh restore backups/backup-20231201_020000

# Restaurar apenas banco
./scripts/backup-automatizado.sh restore-mysql backups/backup-20231201_020000
```

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Container não inicia
```bash
# Verificar logs
docker logs container_name

# Verificar recursos
./scripts/health-check.sh system

# Verificar volumes
./scripts/setup-volumes.sh verify
```

#### 2. Banco de dados inacessível
```bash
# Verificar status do MySQL
./scripts/health-check.sh database

# Verificar logs do MySQL
docker logs mysql

# Verificar conectividade
docker exec mysql mysqladmin ping
```

#### 3. Deploy falha
```bash
# Verificar pré-requisitos
./scripts/deploy-production.sh status

# Verificar logs de deploy
tail -f logs/deploy-*.log

# Fazer rollback se necessário
./scripts/deploy-production.sh rollback /path/to/backup
```

#### 4. Backup falha
```bash
# Verificar espaço em disco
df -h

# Verificar logs de backup
tail -f logs/backup-*.log

# Verificar permissões
ls -la backups/
```

### Logs Importantes

```bash
# Logs da aplicação
logs/application.log
logs/deploy-*.log
logs/backup-*.log
logs/health-*.log

# Logs do Docker
docker logs container_name

# Logs do sistema
/var/log/syslog
/var/log/docker.log
```

### Comandos Úteis

```bash
# Status geral do sistema
docker ps -a
docker images
docker volume ls

# Uso de recursos
top
df -h
free -h

# Rede
netstat -tulpn
ss -tulpn

# Processos
ps aux | grep java
ps aux | grep docker
```

## 📝 Logs e Relatórios

### Estrutura de Logs

```
logs/
├── application.log          # Logs da aplicação
├── deploy-YYYYMMDD_HHMMSS.log    # Logs de deploy
├── backup-YYYYMMDD_HHMMSS.log    # Logs de backup
├── health-check.log         # Logs de health check
├── health-report-*.json     # Relatórios de saúde
└── deploy-notification-*.json    # Notificações de deploy
```

### Relatórios Automáticos

- **Health Reports:** JSON com status detalhado
- **Deploy Notifications:** Status de deploys
- **Backup Reports:** Status e estatísticas de backup

## 🔐 Segurança

### Boas Práticas

1. **Nunca commitar arquivos .env**
2. **Usar Azure Key Vault para secrets**
3. **Rotacionar senhas regularmente**
4. **Monitorar logs de segurança**
5. **Manter backups criptografados**

### Verificações de Segurança

```bash
# Verificar aspectos de segurança
./scripts/health-check.sh security

# Verificar containers rodando como root
docker ps --format "{{.Names}}" | xargs -I {} docker exec {} whoami

# Verificar portas expostas
docker ps --format "{{.Ports}}"
```

## 📞 Suporte

Para problemas ou dúvidas:

1. Verificar logs relevantes
2. Executar health check
3. Consultar este README
4. Verificar documentação do projeto

---

**Versão:** 1.0.0  
**Última atualização:** $(date +"%d/%m/%Y")  
**Projeto:** Conexão de Sorte - Backend