# 🔐 Configuração SSH para Deploy

Este documento descreve como configurar os secrets necessários para o deploy via SSH.

## 📋 Secrets Necessários

Configure os seguintes secrets no GitHub (Settings → Secrets and variables → Actions):

### 🔑 SSH Configuration

| Secret Name | Descrição | Exemplo |
|-------------|-----------|----------|
| `SSH_PRIVATE_KEY` | Chave privada SSH (formato OpenSSH) | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |
| `SSH_USER` | Usuário SSH do servidor | `root` ou `ubuntu` |
| `SERVER_HOST` | IP ou hostname do servidor | `192.168.1.100` ou `servidor.exemplo.com` |

## 🛠️ Como Gerar e Configurar SSH

### 1. Gerar Par de Chaves SSH

```bash
# Gerar nova chave SSH (recomendado: ed25519)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/traefik_deploy

# Ou RSA se ed25519 não for suportado
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/traefik_deploy
```

### 2. Configurar Chave Pública no Servidor

```bash
# Copiar chave pública para o servidor
ssh-copy-id -i ~/.ssh/traefik_deploy.pub user@servidor.com

# Ou manualmente:
cat ~/.ssh/traefik_deploy.pub | ssh user@servidor.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Configurar Secrets no GitHub

1. **SSH_PRIVATE_KEY**: Copie o conteúdo da chave privada
   ```bash
   cat ~/.ssh/traefik_deploy
   ```

2. **SSH_USER**: Nome do usuário SSH (ex: `root`, `ubuntu`, `deploy`)

3. **SERVER_HOST**: IP ou hostname do servidor

### 4. Testar Conexão

```bash
# Testar conexão SSH
ssh -i ~/.ssh/traefik_deploy user@servidor.com "echo 'Conexão SSH funcionando!'"
```

## 📁 Estrutura no Servidor

O deploy criará a seguinte estrutura no servidor:

```
~/traefik-deploy/
├── current/                 # Deploy atual
│   ├── config/
│   ├── dynamic/
│   ├── docker-compose.yml
│   └── .env
├── backup-YYYYMMDD_HHMMSS/ # Backups automáticos
└── deploy-package.tar.gz   # Pacote temporário
```

## 🔒 Segurança

### Recomendações:

1. **Use chaves ed25519** (mais seguras e rápidas)
2. **Crie usuário específico** para deploy (não use root)
3. **Configure sudo sem senha** apenas para comandos Docker:
   ```bash
   # /etc/sudoers.d/deploy-user
   deploy ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose
   ```
4. **Restrinja acesso SSH** no `/etc/ssh/sshd_config`:
   ```
   AllowUsers deploy
   PasswordAuthentication no
   PubkeyAuthentication yes
   ```

### Exemplo de Usuário Deploy:

```bash
# Criar usuário específico para deploy
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# Configurar diretório SSH
sudo mkdir -p /home/deploy/.ssh
sudo chown deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Adicionar chave pública
sudo tee /home/deploy/.ssh/authorized_keys << EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... github-actions-deploy
EOF

sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

## 🚨 Troubleshooting

### Problemas Comuns:

1. **Permission denied (publickey)**
   - Verifique se a chave pública está no `~/.ssh/authorized_keys`
   - Confirme permissões: `chmod 600 ~/.ssh/authorized_keys`

2. **Host key verification failed**
   - Execute: `ssh-keyscan -H servidor.com >> ~/.ssh/known_hosts`

3. **Docker permission denied**
   - Adicione usuário ao grupo docker: `sudo usermod -aG docker $USER`

4. **Deploy directory not found**
   - Crie o diretório: `mkdir -p ~/traefik-deploy`

### Logs de Debug:

```bash
# Testar SSH com debug
ssh -vvv -i ~/.ssh/traefik_deploy user@servidor.com

# Verificar logs do servidor
sudo tail -f /var/log/auth.log
```

## ✅ Checklist de Configuração

- [ ] Chave SSH gerada
- [ ] Chave pública configurada no servidor
- [ ] Secrets configurados no GitHub
- [ ] Conexão SSH testada
- [ ] Usuário tem acesso ao Docker
- [ ] Diretório `~/traefik-deploy` criado
- [ ] Permissões corretas configuradas

---

**⚠️ Importante**: Nunca commite chaves privadas no repositório. Use sempre os GitHub Secrets.