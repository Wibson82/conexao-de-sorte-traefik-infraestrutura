# 📋 Scripts Essenciais para Pipeline Deploy-Unified

Esta pasta contém os scripts essenciais utilizados pelo pipeline `deploy-unified.yml` e outros workflows do GitHub Actions.

## 🚀 Scripts de Deploy

### `deploy-github-actions.sh`
Script principal para deploy via GitHub Actions. Contém lógica para deploy de produção e teste.

### `deploy-production.sh`
Script específico para deploy de produção com configurações otimizadas.

### `deploy-test-environment.sh`
Script para configuração e deploy do ambiente de teste.

## 🔍 Scripts de Monitoramento

### `health-check.sh`
Script abrangente para verificação de saúde da aplicação, incluindo endpoints, banco de dados e serviços.

### `check-status.sh`
Script para verificação rápida do status dos containers e serviços.

### `cleanup-old-containers.sh`
Script para limpeza de containers antigos e otimização de recursos.

### `analisar-falha-127.sh`
Analisa logs do projeto e identifica a causa real quando o workflow falha com código de saída `127`.

## 📁 Estrutura

```
.github/workflows/scripts/
├── README.md                           # Este arquivo
├── deploy-github-actions.sh            # Deploy principal
├── deploy-production.sh                # Deploy de produção
├── deploy-test-environment.sh          # Deploy de teste
├── health-check.sh                     # Verificação de saúde
├── check-status.sh                     # Status dos serviços
├── cleanup-old-containers.sh           # Limpeza de containers
└── analisar-falha-127.sh               # Diagnóstico de falhas exit 127
```

## 🔧 Uso

Estes scripts são executados automaticamente pelo pipeline `deploy-unified.yml` e podem ser executados manualmente quando necessário.

## 📝 Notas

- Todos os scripts são compatíveis com o ambiente de CI/CD do GitHub Actions
- Scripts incluem tratamento de erros e logging detalhado
- Configurados para funcionar com as variáveis de ambiente do pipeline

## 🔗 Relacionamento com Pipeline

O pipeline `deploy-unified.yml` executa comandos diretamente via SSH no servidor, mas estes scripts podem ser referenciados para:
- Debugging de problemas
- Execução manual de operações específicas
- Manutenção e troubleshooting
