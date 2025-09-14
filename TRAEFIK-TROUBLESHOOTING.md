# Traefik v3.x - Resolução de Problemas

Este documento contém informações para resolver os problemas mais comuns encontrados com o Traefik v3.x no ambiente de produção.

## Problemas Identificados no Log

Analisando os logs do servidor, foram identificados os seguintes problemas:

### 1. Erro com múltiplos caminhos em PathPrefix

```
error="error while adding rule (Host(`conexaodesorte.com.br`) || Host(`www.conexaodesorte.com.br`)) && PathPrefix(`/v1/publico`, `/v1/resultados/publico`, `/v1/horario/publico`, `/v1/usuarios/publico`, `/v1/info`): error while adding rule PathPrefix: unexpected number of parameters; got 5, expected one of [1]"
```

**Causa:** No Traefik v3.x, a sintaxe para múltiplos caminhos em `PathPrefix` mudou. Agora cada caminho precisa ter seu próprio `PathPrefix`.

**Solução:** Foi criado o arquivo `traefik/dynamic/backend-routes.yml` com regras separadas para cada caminho.

### 2. Arquivo de autenticação básica ausente

```
error="open /secrets/traefik-basicauth: no such file or directory"
```

**Causa:** O diretório `/secrets` não está mapeado corretamente ou o arquivo de autenticação básica não existe.

**Solução:** Foi criado o script `scripts/create-traefik-auth.sh` para gerar o arquivo de autenticação e o volume foi mapeado corretamente.

### 3. Incompatibilidade de versão do Traefik

Enquanto o `docker-compose.yml` especifica Traefik v3.5.2, o contêiner está rodando Traefik v3.1.7.

**Solução:** O script `scripts/fix-traefik-issues.sh` atualiza o `docker-compose.yml` para usar a mesma versão que está em execução.

### 4. Problemas com certificados Let's Encrypt

```
error="unable to generate a certificate for the domains [conexaodesorte.com.br www.conexaodesorte.com.br]: acme: error: 429 :: POST :: https://acme-v02.api.letsencrypt.org/acme/new-order :: urn:ietf:params:acme:error:rateLimited
```

**Causa:** Excedido o limite de taxa do Let's Encrypt para os domínios.

**Solução:** Aguardar o período indicado na mensagem de erro ou usar certificados existentes.

## Scripts de Resolução

Foram criados três scripts para resolver esses problemas:

1. `scripts/fix-traefik-issues.sh` - Corrige problemas de configuração
2. `scripts/create-traefik-auth.sh` - Cria credenciais de autenticação para o dashboard
3. `scripts/deploy-traefik-secure.sh` - Realiza o deploy seguro do Traefik

### Como usar os scripts

1. **Para corrigir problemas de configuração:**
   ```bash
   ./scripts/fix-traefik-issues.sh
   ```

2. **Para criar credenciais de autenticação:**
   ```bash
   ./scripts/create-traefik-auth.sh
   ```

3. **Para fazer o deploy seguro:**
   ```bash
   ./scripts/deploy-traefik-secure.sh
   ```

## Configuração Recomendada

### Docker Compose

Certifique-se de que o `docker-compose.yml` inclui:

```yaml
volumes:
  - ./secrets:/secrets:ro
  - ./traefik/dynamic:/etc/traefik/dynamic:ro
```

### PathPrefix com múltiplos caminhos

No Traefik v3.x, use regras separadas para cada caminho:

```yaml
# Incorreto
rule: "Host(`example.com`) && PathPrefix(`/api`, `/v1`, `/public`)"

# Correto
rule1: "Host(`example.com`) && PathPrefix(`/api`)"
rule2: "Host(`example.com`) && PathPrefix(`/v1`)"
rule3: "Host(`example.com`) && PathPrefix(`/public`)"
```

## Verificação de Funcionamento

Após aplicar as correções, verifique se o Traefik está funcionando corretamente:

```bash
docker-compose logs -f traefik
```

Você deve ver mensagens indicando que o Traefik inicializou sem erros.