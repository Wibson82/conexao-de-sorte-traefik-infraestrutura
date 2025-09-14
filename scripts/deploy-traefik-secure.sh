#!/bin/bash

# =============================================================================
# 🚀 SCRIPT DE DEPLOY SEGURO PARA TRAEFIK
# =============================================================================
# Este script implementa um deploy seguro do Traefik com verificações

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 🚀 Iniciando deploy seguro do Traefik ===${NC}"

# 1. Verificar se o Docker está em execução
echo -e "\n${BLUE}🔍 Verificando se o Docker está em execução...${NC}"
if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker não está em execução. Inicie o Docker primeiro.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker está em execução${NC}"

# 2. Verificar se o arquivo de configuração do Traefik existe
echo -e "\n${BLUE}🔍 Verificando arquivos de configuração...${NC}"
if [ ! -f "./traefik/traefik.yml" ]; then
    echo -e "${RED}❌ Arquivo de configuração traefik.yml não encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Arquivo de configuração traefik.yml encontrado${NC}"

# 3. Verificar se os diretórios necessários existem
echo -e "\n${BLUE}🔍 Verificando diretórios necessários...${NC}"
for dir in "./traefik/dynamic" "./letsencrypt" "./secrets" "./logs/traefik"; do
    if [ ! -d "$dir" ]; then
        echo -e "${BLUE}📂 Criando diretório $dir...${NC}"
        mkdir -p "$dir"
    fi
done
echo -e "${GREEN}✅ Todos os diretórios estão presentes${NC}"

# 4. Verificar arquivo de autenticação básica
echo -e "\n${BLUE}🔍 Verificando arquivo de autenticação básica...${NC}"
if [ ! -f "./secrets/traefik-basicauth" ]; then
    echo -e "${YELLOW}⚠️  Arquivo de autenticação básica não encontrado${NC}"
    echo -e "${BLUE}🔑 Criando credenciais temporárias...${NC}"

    mkdir -p ./secrets
    echo "admin:$(openssl passwd -apr1 admin)" > ./secrets/traefik-basicauth
    chmod 600 ./secrets/traefik-basicauth

    echo -e "${GREEN}✅ Credenciais temporárias criadas (usuário: admin, senha: admin)${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANTE: Execute ./scripts/create-traefik-auth.sh para definir credenciais seguras${NC}"
else
    echo -e "${GREEN}✅ Arquivo de autenticação básica encontrado${NC}"
fi

# 5. Verificar se a rede Docker existe
echo -e "\n${BLUE}🔍 Verificando rede Docker...${NC}"
NETWORK_NAME="conexao-network-swarm"
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo -e "${YELLOW}⚠️  Rede $NETWORK_NAME não encontrada${NC}"

    echo -e "${BLUE}🌐 Criando rede $NETWORK_NAME...${NC}"
    docker network create --driver overlay "$NETWORK_NAME" || docker network create "$NETWORK_NAME"

    echo -e "${GREEN}✅ Rede $NETWORK_NAME criada${NC}"
else
    echo -e "${GREEN}✅ Rede $NETWORK_NAME já existe${NC}"
fi

# 6. Verificar e corrigir permissões dos diretórios
echo -e "\n${BLUE}🔍 Verificando permissões dos diretórios...${NC}"
chmod 755 ./traefik ./traefik/dynamic
chmod 600 ./secrets/* &>/dev/null || true
echo -e "${GREEN}✅ Permissões dos diretórios ajustadas${NC}"

# 7. Validar a configuração do docker-compose.yml
echo -e "\n${BLUE}🔍 Validando configuração do docker-compose.yml...${NC}"
if ! docker-compose config &>/dev/null; then
    echo -e "${RED}❌ Configuração do docker-compose.yml inválida${NC}"
    docker-compose config
    exit 1
fi
echo -e "${GREEN}✅ Configuração do docker-compose.yml válida${NC}"

# 8. Aplicar configuração do Traefik
echo -e "\n${BLUE}🚀 Aplicando configuração do Traefik...${NC}"
docker-compose down traefik &>/dev/null || true
docker-compose up -d traefik
echo -e "${GREEN}✅ Traefik iniciado com sucesso${NC}"

# 9. Verificar status do serviço
echo -e "\n${BLUE}🔍 Verificando status do Traefik...${NC}"
sleep 5

if ! docker-compose ps traefik | grep -q "Up"; then
    echo -e "${RED}❌ Traefik não está em execução${NC}"
    echo -e "\n${YELLOW}⚠️  Logs do Traefik:${NC}"
    docker-compose logs traefik | tail -n 20
    exit 1
fi
echo -e "${GREEN}✅ Traefik está em execução${NC}"

# 10. Exibir informações úteis
echo -e "\n${BLUE}=== ℹ️  Informações do Traefik ===${NC}"
echo -e "${BLUE}📊 Dashboard: https://traefik.conexaodesorte.com.br/dashboard/${NC}"
echo -e "${BLUE}📋 Credenciais: Verifique em ./secrets/traefik-basicauth${NC}"
echo -e "${BLUE}📝 Logs: docker-compose logs -f traefik${NC}"

echo -e "\n${GREEN}=== 🎉 Deploy concluído com sucesso! ===${NC}"