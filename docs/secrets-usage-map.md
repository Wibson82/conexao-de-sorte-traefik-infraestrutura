# Secrets Usage Map – Traefik Infrastructure

## Repository Variables (`vars`)
- `AZURE_CLIENT_ID` – Identificador federado usado por `azure/login@v2`.
- `AZURE_TENANT_ID` – Diretório Azure AD utilizado durante a autenticação.
- `AZURE_SUBSCRIPTION_ID` – Assinatura com acesso de leitura ao Key Vault.
- `AZURE_KEYVAULT_NAME` – Nome lógico do Key Vault que armazena as credenciais do Traefik.
- `AZURE_KEYVAULT_ENDPOINT` *(opcional)* – Endpoint HTTPS completo, quando necessário para tooling.
- `MAX_VERSIONS_TO_KEEP` *(opcional)* – Parâmetro para eventuais limpezas do GHCR.
- `MAX_AGE_DAYS` *(opcional)* – Idade mínima (dias) para elegibilidade de remoção no GHCR.
- `PROTECTED_TAGS` *(opcional)* – Tags imunes à limpeza (`latest,main,production` por padrão).

> Apenas identificadores ficam no GitHub. Valores sensíveis são obtidos dinamicamente do Azure Key Vault.

## GitHub Secrets
- `GITHUB_TOKEN` – Token padrão do GitHub Actions (escopos reduzidos para artefatos/GHCR).

## Azure Key Vault
- `conexao-de-sorte-traefik-dashboard-password` – Hash `user:password` utilizado no `dashboard-auth`.
- `conexao-de-sorte-letsencrypt-email` – E-mail usado pelo Let's Encrypt/ACME.

## Jobs × Secret Usage (estado alvo)
| Job | Propósito | Segredos/Variáveis | Observações |
| --- | --- | --- | --- |
| `validate` | Validações de compose/YAML e auditoria básica | `AZURE_*` (vars), `GITHUB_TOKEN` | Não consulta o Key Vault; apenas confirma presença das vars obrigatórias. |
| `deploy` | Deploy Swarm no runner Hostinger + health checks | `AZURE_*`, `conexao-de-sorte-traefik-dashboard-password`, `conexao-de-sorte-letsencrypt-email`, `GITHUB_TOKEN` | Busca seletiva via `azure/get-keyvault-secrets@v1`; gera arquivo `secrets/traefik-basicauth` e injeta variáveis antes do deploy. |

## Notas Operacionais
- Atualize este documento antes de adicionar novos segredos ao pipeline.
- Sempre masque valores retornados do Key Vault (`::add-mask::`) antes de gravá-los em arquivos temporários ou outputs.
- Variáveis opcionais (`MAX_*`, `PROTECTED_TAGS`) só precisam ser definidas se a limpeza do GHCR for habilitada.
