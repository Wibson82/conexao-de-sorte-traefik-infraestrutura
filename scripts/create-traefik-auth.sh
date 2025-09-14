#!/bin/bash

# =============================================================================
# 🔒 CRIAÇÃO DE CREDENCIAIS BÁSICAS PARA TRAEFIK
# =============================================================================
# Este script cria credenciais para acesso ao dashboard do Traefik

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SECRETS_DIR="./secrets"
AUTH_FILE="${SECRETS_DIR}/traefik-basicauth"

echo -e "${BLUE}=== 🔑 Configuração de autenticação básica para Traefik ===${NC}"

# Verificar se o diretório de secrets existe
if [ ! -d "$SECRETS_DIR" ]; then
    echo -e "${BLUE}📂 Criando diretório $SECRETS_DIR...${NC}"
    mkdir -p "$SECRETS_DIR"
fi

# Solicitar credenciais
read -p "Digite o nome de usuário [admin]: " USERNAME
USERNAME=${USERNAME:-admin}

# Gerar senha aleatória ou solicitar do usuário
RANDOM_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
read -p "Digite a senha (deixe em branco para usar uma senha aleatória): " PASSWORD
PASSWORD=${PASSWORD:-$RANDOM_PASSWORD}

if [ -z "$PASSWORD" ]; then
    echo -e "${RED}❌ Senha não pode ser vazia${NC}"
    exit 1
fi

# Gerar hash da senha
HASHED_PASSWORD=$(openssl passwd -apr1 "$PASSWORD")

# Criar arquivo de autenticação
echo "$USERNAME:$HASHED_PASSWORD" > "$AUTH_FILE"
chmod 600 "$AUTH_FILE"

echo -e "${GREEN}✅ Arquivo de autenticação criado: $AUTH_FILE${NC}"
echo -e "${YELLOW}⚠️  Credenciais:${NC}"
echo -e "${YELLOW}   Usuário: $USERNAME${NC}"
if [ "$PASSWORD" == "$RANDOM_PASSWORD" ]; then
    echo -e "${YELLOW}   Senha: $PASSWORD (SENHA ALEATÓRIA - ANOTE E GUARDE COM SEGURANÇA!)${NC}"
else
    echo -e "${YELLOW}   Senha: (senha personalizada configurada)${NC}"
fi

echo -e "\n${BLUE}ℹ️  Para usar essas credenciais:${NC}"
echo -e "1. Certifique-se de que o volume dos secrets está mapeado no docker-compose.yml:"
echo -e "   - ./secrets:/secrets:ro"
echo -e "2. Verifique se a configuração do dashboard está correta no arquivo traefik.yml:"
echo -e "   api:"
echo -e "     dashboard: true"
echo -e "     insecure: false"
echo -e "3. Reinicie o Traefik:"
echo -e "   docker-compose restart traefik"
echo -e "\n${GREEN}🎉 Configuração concluída!${NC}"