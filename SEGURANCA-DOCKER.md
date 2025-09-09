# Guia de Segurança Docker - Conexão de Sorte

Este documento descreve as melhorias de segurança implementadas nos arquivos Docker e workflows do GitHub Actions do projeto Conexão de Sorte.

## 1. Melhorias Implementadas

### 1.1 Gestão de Segredos

- **Eliminação de segredos hardcoded**:
  - Removidos segredos hardcoded do `docker-compose.yml` e workflows
  - Migrados para Docker Secrets e Azure Key Vault

- **Uso de Docker Secrets**:
  - Implementado suporte a Docker Secrets para credenciais sensíveis
  - Arquivos de secrets armazenados com permissões restritas (600)
  - Secrets temporários removidos após deploy

- **Variáveis de ambiente**:
  - Uso de arquivo `.env` para variáveis não sensíveis
  - Valores padrão para variáveis opcionais

### 1.2 Segurança de Imagens

- **Multi-stage builds**:
  - Implementado multi-stage build no Dockerfile
  - Estágio de validação de configurações
  - Redução do tamanho final da imagem

- **BuildKit**:
  - Habilitado BuildKit para builds seguros
  - Uso de `--secret` para injeção segura de segredos durante build
  - Provenance e SBOM habilitados

- **Labels OCI**:
  - Adicionados labels OCI para metadados da imagem
  - Informações de versão, data de build, fonte e mantenedor

- **Usuário não-root**:
  - Container executado com usuário não-root (UID 1000)

### 1.3 CI/CD Seguro

- **OIDC com Azure**:
  - Autenticação OIDC para Azure Key Vault
  - Sem armazenamento de credenciais estáticas

- **Validações de segurança**:
  - Verificação de configurações obrigatórias
  - Scan de segredos com gitleaks
  - Validação de configurações HTTPS e TLS

## 2. Como Usar

### 2.1 Configuração Local

1. Copie o arquivo `.env.example` para `.env` e preencha os valores:
   ```bash
   cp .env.example .env
   ```

2. Crie o diretório de secrets e os arquivos necessários:
   ```bash
   mkdir -p ./secrets
   echo "senha_segura" > ./secrets/traefik_dashboard_password.txt
   echo "seu_email@exemplo.com" > ./secrets/letsencrypt_email.txt
   chmod 600 ./secrets/*.txt
   ```

3. Copie o arquivo `docker-compose.override.yml.example` para `docker-compose.override.yml`:
   ```bash
   cp docker-compose.override.yml.example docker-compose.override.yml
   ```

### 2.2 Build da Imagem

Use o script `build-image.sh` para construir a imagem com BuildKit e secrets:

```bash
chmod +x build-image.sh
./build-image.sh
```

### 2.3 Deploy

Execute o deploy com Docker Compose:

```bash
docker compose up -d
```

## 3. Boas Práticas Adicionais

- **Rotação de segredos**: Implemente rotação regular de senhas e tokens
- **Monitoramento**: Configure alertas para tentativas de acesso não autorizadas
- **Atualizações**: Mantenha as imagens base atualizadas
- **Scan de vulnerabilidades**: Execute scans regulares nas imagens
- **Backup**: Mantenha backup seguro das configurações e certificados

## 4. Referências

- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [BuildKit Secret Mounts](https://docs.docker.com/build/buildkit/)
- [OCI Image Format](https://github.com/opencontainers/image-spec)
- [GitHub OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)