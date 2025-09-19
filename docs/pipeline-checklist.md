# ✅ Checklist de Conformidade – Traefik Infrastructure

- [x] Permissões globais mínimas (`contents: read`, `id-token: write`) definidas no workflow.
- [x] Jobs executam em `[self-hosted, Linux, X64, srv649924, conexao-de-sorte-traefik-infraestrutura]` com limites apropriados.
- [x] `azure/login@v2` usa `${{ vars.AZURE_* }}` e `azure/get-keyvault-secrets@v1` busca apenas os segredos documentados.
- [x] Nenhum segredo de aplicação permanece no repositório; inventário atualizado em `docs/secrets-usage-map.md`.
- [ ] `actionlint`, `docker compose config`, `hadolint` e `docker build` executados ou registrados em `docs/validation-report.md`.
- [x] Deploy Swarm cria arquivos/secrets de forma idempotente, ajusta permissões e configura `update_config`/`rollback_config`.
- [x] Health checks e validações de conectividade registrados sem vazamento de segredos.
- [ ] Limpeza do GHCR (quando aplicada) usa allowlist explícita e publica relatório.
- [x] Documentação (`README`, `docs/`) descreve runners, segredos mínimos e fluxo de validação.
- [ ] Execução em staging/produção registrada com evidências do workflow.
