#!/bin/bash

# =============================================================================
# 🚀 SCRIPT DE INICIALIZAÇÃO DOS VOLUMES DO TRAEFIK
# =============================================================================
# Este script garante que todos os diretórios e arquivos necessários para o
# Traefik existam e tenham as permissões corretas antes da inicialização.
# Isso evita problemas com certificados SSL e configurações dinâmicas.

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 🚀 Inicializando volumes do Traefik ===${NC}"

# Diretórios necessários
DIRS=(
  "./letsencrypt"
  "./traefik/dynamic"
  "./secrets"
  "./logs/traefik"
)

# 1. Verificar e criar diretórios necessários
echo -e "\n${BLUE}🔍 Verificando diretórios necessários...${NC}"
for dir in "${DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    echo -e "${YELLOW}⚠️ Diretório $dir não encontrado. Criando...${NC}"
    mkdir -p "$dir"
    echo -e "${GREEN}✅ Diretório $dir criado${NC}"
  else
    echo -e "${GREEN}✅ Diretório $dir já existe${NC}"
  fi
done

# 2. Verificar e criar arquivo acme.json
echo -e "\n${BLUE}🔍 Verificando arquivo acme.json...${NC}"
if [ ! -f "./letsencrypt/acme.json" ]; then
  echo -e "${YELLOW}⚠️ Arquivo acme.json não encontrado. Criando...${NC}"
  touch "./letsencrypt/acme.json"
  chmod 600 "./letsencrypt/acme.json"
  echo -e "${GREEN}✅ Arquivo acme.json criado com permissões 600${NC}"
else
  echo -e "${GREEN}✅ Arquivo acme.json já existe${NC}"
  # Garantir permissões corretas
  chmod 600 "./letsencrypt/acme.json"
fi

# 3. Verificar arquivos de configuração dinâmica
echo -e "\n${BLUE}🔍 Verificando arquivos de configuração dinâmica...${NC}"
DYNAMIC_FILES=(
  "backend-routes.yml"
  "frontend-routes.yml"
  "microservices-routes.yml"
  "middlewares.yml"
  "security-headers.yml"
  "tls.yml"
)

for file in "${DYNAMIC_FILES[@]}"; do
  if [ ! -f "./traefik/dynamic/$file" ]; then
    echo -e "${RED}❌ Arquivo de configuração $file não encontrado${NC}"
    echo -e "${YELLOW}⚠️ Verifique se todos os arquivos de configuração estão presentes${NC}"
  else
    echo -e "${GREEN}✅ Arquivo de configuração $file encontrado${NC}"
  fi
done

# 4. Verificar arquivo de autenticação básica
echo -e "\n${BLUE}🔍 Verificando arquivo de autenticação básica...${NC}"
if [ ! -f "./secrets/traefik-basicauth" ]; then
  echo -e "${YELLOW}⚠️ Arquivo de autenticação básica não encontrado. Criando temporário...${NC}"
  mkdir -p ./secrets
  echo "admin:$(openssl passwd -apr1 admin)" > ./secrets/traefik-basicauth
  chmod 600 ./secrets/traefik-basicauth
  echo -e "${GREEN}✅ Arquivo de autenticação básica temporário criado${NC}"
  echo -e "${YELLOW}⚠️ IMPORTANTE: Execute ./scripts/create-traefik-auth.sh para definir credenciais seguras${NC}"
else
  echo -e "${GREEN}✅ Arquivo de autenticação básica encontrado${NC}"
  # Garantir permissões corretas
  chmod 600 ./secrets/traefik-basicauth
fi

# 5. Verificar permissões dos diretórios
echo -e "\n${BLUE}🔍 Ajustando permissões dos diretórios...${NC}"
chmod 755 ./traefik ./traefik/dynamic
chmod -R 700 ./secrets
chmod 700 ./letsencrypt
echo -e "${GREEN}✅ Permissões dos diretórios ajustadas${NC}"

echo -e "\n${GREEN}=== 🎉 Inicialização dos volumes concluída com sucesso! ===${NC}"
echo -e "${BLUE}Agora você pode iniciar o Traefik com segurança.${NC}"