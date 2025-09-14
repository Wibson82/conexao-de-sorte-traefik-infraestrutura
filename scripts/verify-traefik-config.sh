#!/bin/bash

# =============================================================================
# 🔍 VERIFICADOR DE CONFIGURAÇÃO DO TRAEFIK
# =============================================================================
# Este script verifica se a configuração do Traefik está correta para a versão atual

set -e

TRAEFIK_VERSION=$(docker image ls | grep traefik | awk '{print $2}' | head -n 1)
CONFIG_FILE="./traefik/traefik.yml"
DYNAMIC_DIR="./traefik/dynamic"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 🔍 Verificando compatibilidade da configuração do Traefik ${TRAEFIK_VERSION} ===${NC}"

# Verificar se o arquivo de configuração principal existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Arquivo de configuração principal não encontrado: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Arquivo de configuração principal encontrado: $CONFIG_FILE${NC}"

# Verificar se há referências incompatíveis no arquivo principal
if grep -q "swarmMode:" "$CONFIG_FILE"; then
    echo -e "${RED}❌ Configuração incompatível detectada: swarmMode no arquivo $CONFIG_FILE${NC}"
    echo -e "${YELLOW}⚠️  No Traefik 3.x, o SwarmMode é detectado automaticamente${NC}"
    echo -e "${BLUE}ℹ️  Recomendação: Remover a linha 'swarmMode: true' do arquivo ${CONFIG_FILE}${NC}"
else
    echo -e "${GREEN}✅ Configuração do Docker provider está correta${NC}"
fi

# Verificar configuração do provider Docker
if grep -q "docker:" "$CONFIG_FILE"; then
    echo -e "${GREEN}✅ Provider Docker configurado${NC}"

    # Verificar se o endpoint está configurado
    if grep -q "endpoint:" "$CONFIG_FILE"; then
        echo -e "${GREEN}✅ Endpoint Docker configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  Endpoint Docker não encontrado${NC}"
        echo -e "${BLUE}ℹ️  Recomendação: Adicionar 'endpoint: \"unix:///var/run/docker.sock\"' na seção docker${NC}"
    fi

    # Verificar se a rede está configurada
    if grep -q "network:" "$CONFIG_FILE"; then
        NETWORK=$(grep "network:" "$CONFIG_FILE" | awk '{print $2}' | tr -d '"')
        echo -e "${GREEN}✅ Rede Docker configurada: $NETWORK${NC}"

        # Verificar se a rede existe
        if docker network ls | grep -q "$NETWORK"; then
            echo -e "${GREEN}✅ Rede $NETWORK existe no Docker${NC}"
        else
            echo -e "${RED}❌ Rede $NETWORK não existe no Docker${NC}"
            echo -e "${BLUE}ℹ️  Recomendação: Criar a rede com 'docker network create --driver overlay $NETWORK'${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Rede Docker não configurada${NC}"
        echo -e "${BLUE}ℹ️  Recomendação: Adicionar 'network: conexao-network-swarm' na seção docker${NC}"
    fi
else
    echo -e "${RED}❌ Provider Docker não encontrado no arquivo $CONFIG_FILE${NC}"
    echo -e "${BLUE}ℹ️  Recomendação: Adicionar a seção providers.docker no arquivo ${CONFIG_FILE}${NC}"
fi

# Verificar se os arquivos dinâmicos estão presentes
if [ -d "$DYNAMIC_DIR" ]; then
    echo -e "${GREEN}✅ Diretório de configurações dinâmicas encontrado: $DYNAMIC_DIR${NC}"

    # Verificar arquivos essenciais
    for file in "middlewares.yml" "tls.yml" "security-headers.yml"; do
        if [ -f "${DYNAMIC_DIR}/${file}" ]; then
            echo -e "${GREEN}✅ Arquivo dinâmico encontrado: ${file}${NC}"
        else
            echo -e "${RED}❌ Arquivo dinâmico ausente: ${file}${NC}"
        fi
    done
else
    echo -e "${RED}❌ Diretório de configurações dinâmicas não encontrado: $DYNAMIC_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}=== 🎉 Verificação concluída ===${NC}"
echo -e "${YELLOW}⚠️  Lembre-se de validar o funcionamento do Traefik após qualquer alteração de configuração${NC}"
echo -e "${BLUE}ℹ️  Use 'docker compose up -d' para aplicar as alterações${NC}"