# 🛡️ Traefik Infrastructure – Conexão de Sorte

Infraestrutura Traefik executada no Swarm da Hostinger (`srv649924`) com autenticação via Azure OIDC, consumo seletivo de segredos no Key Vault e deploy automatizado pelo GitHub Actions.

## 📦 Componentes Principais
- `docker-compose.yml`: serviço Traefik v3.5 rootless (`user: 999`), logging rotacionado, `update_config`/`rollback_config` configurados e volumes ajustados para produção.
- `.env`: apenas variáveis funcionais; identificadores Azure permanecem no GitHub (`vars`).
- `.github/workflows/ci-cd.yml`: workflow enxuto com jobs `validate` e `deploy`, OIDC mínimo e criação idempotente de secrets Swarm.
- `.github/actionlint.yaml`: configuração para validar labels customizados do runner.
- `docs/`: checklist e mapa de segredos atualizados.

## 🚀 Fluxo de Deploy
1. **Validate** – roda em `[self-hosted, Linux, X64, srv649924, conexao-de-sorte-traefik-infraestrutura]`, verifica presence de `vars.AZURE_*`, executa validação YAML/compose e grep de secrets.
2. **Deploy** – usa `azure/login@v2`, busca apenas `conexao-de-sorte-traefik-dashboard-password` e `conexao-de-sorte-letsencrypt-email` via `azure/get-keyvault-secrets@v1`, cria secrets Swarm e aplica o stack.

```bash
# CI/CD automático
git push origin main

# Deploy manual
cp .env.ci .env
# Ajustar domains se necessário e criar `secrets/traefik-basicauth`
docker stack deploy -c docker-compose.yml conexao-traefik
```

## 🔐 Segredos
- **Repository Variables**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_KEYVAULT_NAME`, `AZURE_KEYVAULT_ENDPOINT` (opcional), `MAX_VERSIONS_TO_KEEP`, `MAX_AGE_DAYS`, `PROTECTED_TAGS`.
- **Azure Key Vault**: `conexao-de-sorte-traefik-dashboard-password`, `conexao-de-sorte-letsencrypt-email`.
- **GitHub Secrets**: apenas `GITHUB_TOKEN` padrão.

Mapeamento completo em `docs/secrets-usage-map.md`.

## 🧪 Validações
- `actionlint -config-file .github/actionlint.yaml --shellcheck=`
- `docker compose -f docker-compose.yml config -q`
- `hadolint` e `docker build` pendentes (executar nos runners autorizados e registrar em `docs/validation-report.md`).

## 📝 Documentação Auxiliar
- `docs/pipeline-checklist.md` – checklist de conformidade.
- `docs/validation-report.md` – evidências registradas.
- `HISTORICO-MUDANCAS.md` – histórico da auditoria.

## 🔍 Troubleshooting rápido
```bash
# Logs do serviço
docker service logs conexao-traefik_traefik --tail 50

# Health ping
curl -fsS http://localhost:8080/ping

# Secrets ativos
docker secret ls | grep traefik
```

## ✅ Status atual
- Workflow OIDC mínimo ativo.
- Segredos somente via Key Vault.
- Compose rootless com rollback configurado.
- Documentação sincronizada com a nova auditoria.
