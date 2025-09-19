# ✅ Checklist de Conformidade – Traefik Infrastructure

- [ ] Permissões globais mínimas (`contents: read`, `id-token: write`) definidas no workflow.
- [ ] Jobs executam em `[self-hosted, Linux, X64, srv649924, conexao-de-sorte-traefik-infraestrutura]` com limites apropriados.
- [ ] `azure/login@v2` usa `${{ vars.AZURE_* }}` e `azure/get-keyvault-secrets@v1` busca apenas os segredos documentados.
- [ ] Nenhum segredo de aplicação permanece no repositório; inventário atualizado em `docs/secrets-usage-map.md`.
- [ ] `actionlint`, `docker compose config`, `hadolint` e `docker build` executados ou registrados em `docs/validation-report.md`.
- [ ] Deploy Swarm cria arquivos/secrets de forma idempotente, ajusta permissões e configura `update_config`/`rollback_config`.
- [ ] Health checks e validações de conectividade registrados sem vazamento de segredos.
- [ ] Limpeza do GHCR (quando aplicada) usa allowlist explícita e publica relatório.
- [ ] Documentação (`README`, `docs/`) descreve runners, segredos mínimos e fluxo de validação.
- [ ] Execução em staging/produção registrada com evidências do workflow.
