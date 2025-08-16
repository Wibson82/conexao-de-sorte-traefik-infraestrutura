# 📁 Reorganização dos Scripts

## 🔄 Mudanças Realizadas

Esta pasta foi reorganizada para otimizar o pipeline `deploy-unified.yml` e melhorar a manutenibilidade do projeto.

## 📋 Scripts Essenciais Migrados

Os scripts essenciais para o pipeline foram movidos para `.github/workflows/scripts/`:

- `deploy-github-actions.sh` - Script principal de deploy
- `deploy-production.sh` - Deploy de produção
- `deploy-test-environment.sh` - Deploy de teste
- `health-check.sh` - Verificação de saúde
- `check-status.sh` - Status dos serviços
- `cleanup-old-containers.sh` - Limpeza de containers

## 📦 Scripts em Backup

Todos os demais scripts foram movidos para `scripts/backup/` para preservação:

- Scripts de análise e testes
- Scripts de diagnóstico e troubleshooting
- Scripts de desenvolvimento e validação
- Scripts de monitoramento e segurança
- Scripts específicos do Azure e Traefik

## 🎯 Benefícios da Reorganização

1. **Pipeline Otimizado**: Scripts essenciais estão próximos ao workflow
2. **Manutenibilidade**: Separação clara entre scripts ativos e legados
3. **Organização**: Estrutura mais limpa e focada
4. **Preservação**: Scripts legados mantidos para referência

## 🔧 Acesso aos Scripts

- **Scripts Ativos**: `.github/workflows/scripts/`
- **Scripts Legados**: `scripts/backup/`
- **Documentação**: README em cada pasta

## 📝 Notas Importantes

- O pipeline `deploy-unified.yml` executa comandos diretamente via SSH
- Scripts essenciais podem ser executados manualmente quando necessário
- Scripts legados estão preservados para debugging e referência
- Nova estrutura facilita manutenção e desenvolvimento futuro
