# 🚀 Guia de Implantação Segura do Traefik

Este guia contém instruções detalhadas para implantar e manter o Traefik de forma segura, evitando problemas comuns com certificados SSL, configurações e integração com outros serviços.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Acesso ao servidor de produção
- Permissões para criar e modificar arquivos e diretórios
- Domínios configurados no DNS apontando para o servidor

## 🔧 Estrutura de Diretórios

A estrutura de diretórios correta é essencial para o funcionamento do Traefik:

```
conexao-de-sorte-traefik-infraestrutura/
├── letsencrypt/           # Certificados SSL
│   └── acme.json          # Arquivo de certificados (permissão 600)
├── logs/
│   └── traefik/           # Logs do Traefik
├── secrets/
│   └── traefik-basicauth  # Credenciais do dashboard (permissão 600)
├── traefik/
│   ├── dynamic/           # Configurações dinâmicas
│   │   ├── backend-routes.yml
│   │   ├── frontend-routes.yml
│   │   ├── microservices-routes.yml
│   │   ├── middlewares.yml
│   │   ├── security-headers.yml
│   │   └── tls.yml
│   └── traefik.yml        # Configuração estática
└── docker-compose.yml     # Definição dos serviços
```

## 🚀 Implantação Inicial

Para uma implantação inicial segura, siga estes passos:

1. **Preparar o ambiente**:
   ```bash
   # Clone o repositório
   git clone https://github.com/Wibson82/conexao-de-sorte-traefik-infraestrutura.git
   cd conexao-de-sorte-traefik-infraestrutura
   
   # Inicializar volumes e diretórios
   ./scripts/init-traefik-volumes.sh
   
   # Criar credenciais seguras para o dashboard
   ./scripts/create-traefik-auth.sh
   ```

2. **Implantar o Traefik**:
   ```bash
   # Iniciar o Traefik
   ./scripts/deploy-traefik-secure.sh
   ```

## 🔄 Atualização Segura

Para atualizar o Traefik sem impactar outros serviços:

```bash
# Executar a migração segura
./scripts/migrate-traefik-safely.sh
```

Este script:
- Faz backup do arquivo acme.json
- Para o Traefik atual
- Inicia o novo Traefik
- Verifica a conectividade com outros serviços
- Restaura o backup em caso de falha

## ⚠️ Problemas Comuns e Soluções

### 1. Certificados SSL não são emitidos

**Problema**: O Traefik não consegue emitir certificados SSL.

**Solução**:
- Verifique se o arquivo `acme.json` existe e tem permissão 600:
  ```bash
  ls -la ./letsencrypt/acme.json
  chmod 600 ./letsencrypt/acme.json
  ```
- Verifique se o domínio está apontando corretamente para o servidor:
  ```bash
  dig +short conexaodesorte.com.br
  ```
- Verifique os logs do Traefik:
  ```bash
  docker-compose logs -f traefik | grep -i "acme"
  ```

### 2. Erro "middleware does not exist"

**Problema**: O Traefik não encontra os middlewares definidos.

**Solução**:
- Verifique se o diretório de configurações dinâmicas está montado corretamente:
  ```bash
  docker exec -it $(docker-compose ps -q traefik) ls -la /etc/traefik/dynamic/
  ```
- Verifique se os nomes dos middlewares estão corretos nos arquivos de rota:
  ```bash
  grep -r "middlewares:" ./traefik/dynamic/
  ```

### 3. Erro "PathPrefix: unexpected number of parameters"

**Problema**: Sintaxe incorreta nas regras de PathPrefix.

**Solução**:
- Cada PathPrefix deve ser definido separadamente:
  ```yaml
  # Incorreto
  rule: "Host(`conexaodesorte.com.br`) && PathPrefix(`/v1/publico`, `/v1/resultados/publico`)"

  # Correto
  rule: "Host(`conexaodesorte.com.br`) && (PathPrefix(`/v1/publico`) || PathPrefix(`/v1/resultados/publico`))"
  ```

## 🔒 Melhores Práticas de Segurança

1. **Permissões de Arquivos**:
   - `acme.json`: permissão 600
   - `traefik-basicauth`: permissão 600
   - Diretórios de configuração: permissão 755

2. **Montagem de Volumes**:
   - Arquivos de configuração: montar como read-only (`:ro`)
   - Docker socket: montar como read-only (`:ro`)
   - Diretório de certificados: montar com permissão de escrita

3. **Rede Docker**:
   - Usar rede dedicada para o Traefik
   - Não expor portas desnecessárias

4. **Monitoramento**:
   - Verificar regularmente os logs do Traefik
   - Configurar alertas para erros de certificado

## 📝 Checklist de Implantação

- [ ] Diretórios e arquivos necessários criados
- [ ] Permissões de arquivos configuradas corretamente
- [ ] Rede Docker criada
- [ ] Traefik iniciado com sucesso
- [ ] Certificados SSL emitidos corretamente
- [ ] Dashboard acessível e protegido
- [ ] Conectividade com outros serviços verificada

## 🔍 Verificação de Funcionamento

Após a implantação, verifique se tudo está funcionando corretamente:

```bash
# Verificar status do Traefik
docker-compose ps traefik

# Verificar logs
docker-compose logs -f traefik

# Verificar certificados
curl -I https://www.conexaodesorte.com.br
curl -I https://api.conexaodesorte.com.br
curl -I https://traefik.conexaodesorte.com.br
```

## 📚 Recursos Adicionais

- [Documentação oficial do Traefik](https://doc.traefik.io/traefik/)
- [Guia de solução de problemas do Let's Encrypt](https://letsencrypt.org/docs/troubleshooting/)
- [Melhores práticas de segurança para Docker](https://docs.docker.com/engine/security/security/)