#!/bin/bash

# =============================================================================
# 🚀 SCRIPT DE MIGRAÇÃO SEGURA DO TRAEFIK
# =============================================================================
# Este script realiza uma migração segura do Traefik, garantindo que:
# 1. Os volumes e arquivos necessários existam
# 2. A rede Docker seja preservada
# 3. Outros serviços não sejam impactados
# 4. O estado do certificado seja preservado (se possível)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 🚀 Iniciando migração segura do Traefik ===${NC}"

# 1. Verificar se o Docker está em execução
echo -e "\n${BLUE}🔍 Verificando se o Docker está em execução...${NC}"
if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker não está em execução. Inicie o Docker primeiro.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker está em execução${NC}"

# 2. Inicializar volumes e diretórios
echo -e "\n${BLUE}🔍 Inicializando volumes e diretórios...${NC}"
if [ -f "./scripts/init-traefik-volumes.sh" ]; then
    ./scripts/init-traefik-volumes.sh
else
    echo -e "${RED}❌ Script de inicialização não encontrado. Verifique se o arquivo ./scripts/init-traefik-volumes.sh existe.${NC}"
    exit 1
fi

# 3. Verificar se o Traefik está em execução
echo -e "\n${BLUE}🔍 Verificando se o Traefik está em execução...${NC}"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)

if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️ Traefik está em execução no container: $TRAEFIK_CONTAINER${NC}"
    
    # 3.1. Fazer backup do acme.json se existir
    echo -e "\n${BLUE}🔍 Verificando se existe arquivo acme.json para backup...${NC}"
    if [ -f "./letsencrypt/acme.json" ]; then
        echo -e "${BLUE}📦 Fazendo backup do arquivo acme.json...${NC}"
        cp ./letsencrypt/acme.json ./letsencrypt/acme.json.backup.$(date +%Y%m%d%H%M%S)
        echo -e "${GREEN}✅ Backup do arquivo acme.json realizado${NC}"
    else
        echo -e "${YELLOW}⚠️ Arquivo acme.json não encontrado. Será criado um novo.${NC}"
    fi
    
    # 3.2. Parar o Traefik atual
    echo -e "\n${BLUE}🛑 Parando o Traefik atual...${NC}"
    if [[ "$TRAEFIK_CONTAINER" == *"_traefik"* ]] || [[ "$TRAEFIK_CONTAINER" == *".traefik"* ]]; then
        # Container gerenciado pelo Docker Compose ou Swarm
        echo -e "${BLUE}🔄 Container gerenciado pelo Docker Compose/Swarm. Usando docker-compose down...${NC}"
        docker-compose down traefik
    else
        # Container standalone
        echo -e "${BLUE}🔄 Container standalone. Usando docker stop...${NC}"
        docker stop "$TRAEFIK_CONTAINER"
    fi
    echo -e "${GREEN}✅ Traefik parado com sucesso${NC}"
else
    echo -e "${GREEN}✅ Nenhum container Traefik em execução${NC}"
fi

# 4. Verificar a rede Docker
echo -e "\n${BLUE}🔍 Verificando rede Docker...${NC}"
NETWORK_NAME="conexao-network-swarm"
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo -e "${YELLOW}⚠️ Rede $NETWORK_NAME não encontrada${NC}"

    echo -e "${BLUE}🌐 Criando rede $NETWORK_NAME...${NC}"
    docker network create --driver overlay "$NETWORK_NAME" || docker network create "$NETWORK_NAME"

    echo -e "${GREEN}✅ Rede $NETWORK_NAME criada${NC}"
else
    echo -e "${GREEN}✅ Rede $NETWORK_NAME já existe${NC}"
fi

# 5. Iniciar o novo Traefik
echo -e "\n${BLUE}🚀 Iniciando o novo Traefik...${NC}"
docker-compose up -d traefik
echo -e "${GREEN}✅ Novo Traefik iniciado${NC}"

# 6. Verificar status do serviço
echo -e "\n${BLUE}🔍 Verificando status do novo Traefik...${NC}"
sleep 5

if ! docker-compose ps traefik | grep -q "Up"; then
    echo -e "${RED}❌ Novo Traefik não está em execução${NC}"
    echo -e "\n${YELLOW}⚠️ Logs do Traefik:${NC}"
    docker-compose logs traefik | tail -n 20
    
    echo -e "\n${YELLOW}⚠️ Tentando restaurar o backup do acme.json...${NC}"
    LATEST_BACKUP=$(ls -t ./letsencrypt/acme.json.backup.* 2>/dev/null | head -n 1)
    if [ -n "$LATEST_BACKUP" ]; then
        cp "$LATEST_BACKUP" ./letsencrypt/acme.json
        chmod 600 ./letsencrypt/acme.json
        echo -e "${GREEN}✅ Backup do acme.json restaurado: $LATEST_BACKUP${NC}"
        
        echo -e "\n${BLUE}🔄 Tentando iniciar o Traefik novamente...${NC}"
        docker-compose up -d traefik
        sleep 5
        
        if ! docker-compose ps traefik | grep -q "Up"; then
            echo -e "${RED}❌ Falha ao iniciar o Traefik mesmo após restaurar o backup${NC}"
            exit 1
        else
            echo -e "${GREEN}✅ Traefik iniciado com sucesso após restaurar o backup${NC}"
        fi
    else
        echo -e "${RED}❌ Nenhum backup do acme.json encontrado${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Novo Traefik está em execução${NC}"
fi

# 7. Verificar conectividade com outros serviços
echo -e "\n${BLUE}🔍 Verificando conectividade com outros serviços...${NC}"
BACKEND_CONTAINER=$(docker ps --filter "name=backend-prod" --format "{{.Names}}" | head -n 1)
FRONTEND_CONTAINER=$(docker ps --filter "name=conexao-frontend" --format "{{.Names}}" | head -n 1)

if [ -n "$BACKEND_CONTAINER" ]; then
    echo -e "${BLUE}🔄 Verificando conectividade com o backend...${NC}"
    if docker exec -it $(docker-compose ps -q traefik) wget -q --spider --timeout=5 http://backend-prod:8080/actuator/health 2>/dev/null; then
        echo -e "${GREEN}✅ Conectividade com o backend OK${NC}"
    else
        echo -e "${YELLOW}⚠️ Não foi possível conectar ao backend. Verifique a rede.${NC}"
    fi
fi

if [ -n "$FRONTEND_CONTAINER" ]; then
    echo -e "${BLUE}🔄 Verificando conectividade com o frontend...${NC}"
    if docker exec -it $(docker-compose ps -q traefik) wget -q --spider --timeout=5 http://conexao-frontend:3000/health.json 2>/dev/null; then
        echo -e "${GREEN}✅ Conectividade com o frontend OK${NC}"
    else
        echo -e "${YELLOW}⚠️ Não foi possível conectar ao frontend. Verifique a rede.${NC}"
    fi
fi

# 8. Exibir informações úteis
echo -e "\n${BLUE}=== ℹ️  Informações do Traefik ===${NC}"
echo -e "${BLUE}📊 Dashboard: https://traefik.conexaodesorte.com.br/dashboard/${NC}"
echo -e "${BLUE}📋 Credenciais: Verifique em ./secrets/traefik-basicauth${NC}"
echo -e "${BLUE}📝 Logs: docker-compose logs -f traefik${NC}"

echo -e "\n${GREEN}=== 🎉 Migração concluída com sucesso! ===${NC}"
echo -e "${BLUE}O Traefik foi atualizado sem impactar outros serviços.${NC}"
echo -e "${YELLOW}⚠️ Importante: Pode levar alguns minutos para que os certificados SSL sejam emitidos pelo Let's Encrypt.${NC}"