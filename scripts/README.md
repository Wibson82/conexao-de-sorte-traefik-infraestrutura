# Scripts de Automação - Traefik Infrastructure

Este diretório contém scripts para automação, diagnóstico e manutenção da infraestrutura Traefik.

## Scripts Disponíveis

### 🔧 Scripts de Diagnóstico

#### `diagnostico-completo.sh`
**Script principal de diagnóstico completo da infraestrutura Traefik.**

**Uso:**
```bash
./diagnostico-completo.sh
```

**Funcionalidades:**
- ✅ Verificação completa de containers Docker
- 🔗 Análise detalhada de redes Docker
- 📡 Testes de conectividade interna e externa
- 🔐 Verificação de certificados SSL
- 📊 Análise da API do Traefik
- 📋 Verificação de logs recentes
- 🎯 Recomendações automáticas para problemas

#### `diagnostico-rapido.sh`
**Script de diagnóstico rápido baseado nos testes manuais validados.**

**Uso:**
```bash
./diagnostico-rapido.sh
```

**Funcionalidades:**
- 🚀 Execução rápida (< 30 segundos)
- 📋 Status dos containers principais
- 📡 Testes de conectividade essenciais
- 🌐 Verificação de endpoints HTTPS
- 📊 Status da API do Traefik
- 🎯 Resumo executivo com próximos passos

### 🔌 Scripts de Conectividade

#### 🧪 test-ssh-connectivity.sh

**Script para testar conectividade SSH com servidores remotos antes do deploy.**

### Funcionalidades

- ✅ **Teste de DNS** - Verifica se o hostname resolve corretamente
- ✅ **Teste de Ping** - Valida conectividade de rede
- ✅ **Teste de Porta SSH** - Confirma que o serviço SSH está rodando
- ✅ **Obtenção de Chaves** - Lista chaves SSH disponíveis no servidor
- ✅ **Teste de Autenticação** - Valida autenticação SSH (se chave privada disponível)
- 🎨 **Output Colorido** - Interface amigável com cores e emojis
- 🤖 **Integração GitHub Actions** - Suporte nativo para workflows

### Uso Local

```bash
# Teste básico
./scripts/test-ssh-connectivity.sh <host> <user>

# Com timeout customizado
./scripts/test-ssh-connectivity.sh <host> <user> <timeout>

# Exemplo
./scripts/test-ssh-connectivity.sh 145.223.31.87 root 10
```

### Uso no GitHub Actions

```yaml
- name: 🧪 Teste de Conectividade SSH
  run: |
    GITHUB_ACTIONS=true ./scripts/test-ssh-connectivity.sh "${{ secrets.SSH_HOST }}" "${{ secrets.SSH_USER }}"
```

### Saída de Exemplo

```
ℹ️  Iniciando testes de conectividade SSH para root@145.223.31.87

ℹ️  1. Testando resolução DNS...
✅ DNS resolve corretamente
   Address: 2804:56c:200::103#53
   87.31.223.145.in-addr.arpa name = srv649924.hstgr.cloud.

ℹ️  2. Testando conectividade de rede...
✅ Host responde ao ping
   round-trip min/avg/max/stddev = 11.317/11.799/12.328/0.414 ms

ℹ️  3. Testando porta SSH (22)...
✅ Porta SSH está acessível
   Servidor SSH: SSH-2.0-OpenSSH_9.6p1

ℹ️  4. Obtendo chaves SSH do servidor...
✅ Chaves SSH obtidas com sucesso
   🔑 RSA key disponível
   🔑 ECDSA key disponível
   🔑 ED25519 key disponível

ℹ️  5. Pulando teste de autenticação (chave privada não encontrada)

✅ Testes de conectividade concluídos com sucesso!
ℹ️  O host 145.223.31.87 está pronto para receber conexões SSH
```

### Códigos de Retorno

- `0` - Todos os testes passaram
- `1` - Falha em algum teste crítico

### Integração no Workflow

O script está integrado no workflow principal (`main.yml`) e é executado automaticamente antes do setup SSH para validar a conectividade com o servidor de destino.

### Troubleshooting

**DNS não resolve:**
- Verifique se o hostname está correto
- Teste manualmente: `nslookup <hostname>`

**Ping falha:**
- Servidor pode estar bloqueando ICMP
- Não é crítico se SSH funcionar

**SSH não conecta:**
- Verifique se o serviço SSH está rodando
- Confirme que a porta 22 está aberta
- Teste manualmente: `telnet <host> 22`

**Autenticação falha:**
- Verifique se a chave privada está correta
- Confirme se a chave pública está no servidor
- Teste manualmente: `ssh -i <key> user@host`