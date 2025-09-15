#!/bin/bash

# =============================================================================
# 🔧 CORRETOR DE CONFIGURAÇÃO DO TRAEFIK
# =============================================================================
# Este script corrige problemas comuns na configuração do Traefik v3.x

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 🔧 Iniciando correção da configuração do Traefik ===${NC}"

# Verificar versão do Traefik no docker-compose.yml
COMPOSE_VERSION=$(grep "image: traefik:" docker-compose.yml | awk -F':' '{print $2}')
echo -e "${BLUE}📋 Versão do Traefik no docker-compose.yml: ${COMPOSE_VERSION}${NC}"

# Verificar versão real do Traefik no contêiner
if docker ps | grep -q "traefik"; then
    CONTAINER_VERSION=$(docker inspect --format='{{range .Config.Image}}{{.}}{{end}}' $(docker ps | grep traefik | awk '{print $1}'))
    echo -e "${BLUE}📋 Versão do Traefik em execução: ${CONTAINER_VERSION}${NC}"

    if [[ "$CONTAINER_VERSION" != *"$COMPOSE_VERSION"* ]]; then
        echo -e "${YELLOW}⚠️  Aviso: Versão do Traefik no docker-compose.yml difere da versão em execução${NC}"
        echo -e "${BLUE}ℹ️  Recomendação: Atualize o docker-compose.yml para usar a mesma versão: ${CONTAINER_VERSION}${NC}"
    fi
fi

# 1. Corrigir regras de PathPrefix
echo -e "\n${BLUE}=== 🛠️  Corrigindo regras de PathPrefix ===${NC}"

# Verificar se o backend-prod tem rótulos (labels) específicos para o PathPrefix
if docker inspect backend-prod &>/dev/null; then
    echo -e "${BLUE}📋 Verificando labels do contêiner backend-prod${NC}"

    # Extrair labels relacionados a regras PathPrefix com múltiplos caminhos
    PROBLEMATIC_LABELS=$(docker inspect backend-prod --format='{{range $k, $v := .Config.Labels}}{{if and (contains $k "traefik.http.routers") (contains $v "PathPrefix")}}{{$k}}={{$v}}{{end}}{{end}}')

    if [[ -n "$PROBLEMATIC_LABELS" ]]; then
        echo -e "${YELLOW}⚠️  Encontrados labels problemáticos no backend-prod:${NC}"
        echo -e "$PROBLEMATIC_LABELS"

        echo -e "\n${BLUE}🔨 Criando arquivo de correção...${NC}"

        # Criar arquivo corrigido para atualizar os labels
        cat > fix-backend-labels.sh << EOF
#!/bin/bash

# Remover labels problemáticos
docker label backend-prod $(echo "$PROBLEMATIC_LABELS" | cut -d= -f1 | sed 's/^/--label-rm /')

# Adicionar labels corrigidos
EOF

        # Para cada PathPrefix com múltiplos caminhos, criar regras separadas
        echo "$PROBLEMATIC_LABELS" | while read -r label; do
            KEY=$(echo "$label" | cut -d= -f1)
            VALUE=$(echo "$label" | cut -d= -f2-)

            if [[ "$VALUE" == *"PathPrefix(\`"*","* ]]; then
                # Extrair parte do Host da regra
                HOST_PART=$(echo "$VALUE" | grep -o "Host(\`[^)]*\`)" || echo "Host(\`conexaodesorte.com.br\`)")

                # Extrair os caminhos do PathPrefix
                PATHS=$(echo "$VALUE" | grep -o "PathPrefix(\`[^)]*\`)" | sed "s/PathPrefix(\`//g" | sed "s/\`//g")

                # Gerar novas regras para cada caminho
                i=1
                echo "$PATHS" | tr ',' '\n' | while read -r path; do
                    ROUTER_NAME=$(echo "$KEY" | sed 's/rule$//')
                    echo "docker label backend-prod ${ROUTER_NAME}${i}.rule=\"${HOST_PART} && PathPrefix(\`${path}\`)\"" >> fix-backend-labels.sh
                    i=$((i+1))
                done
            fi
        done

        chmod +x fix-backend-labels.sh
        echo -e "${GREEN}✅ Arquivo de correção criado: fix-backend-labels.sh${NC}"
        echo -e "${BLUE}ℹ️  Para aplicar as correções, execute: ./fix-backend-labels.sh${NC}"
    else
        echo -e "${GREEN}✅ Não foram encontrados labels problemáticos no backend-prod${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  O contêiner backend-prod não está presente${NC}"
fi

# 2. Corrigir arquivo de autenticação básica ausente
echo -e "\n${BLUE}=== 🛠️  Corrigindo arquivo de autenticação básica ===${NC}"
if [ ! -d "./secrets" ]; then
    mkdir -p ./secrets
    echo -e "${GREEN}✅ Criado diretório ./secrets${NC}"
fi

if [ ! -f "./secrets/traefik-basicauth" ]; then
    echo -e "${YELLOW}⚠️  Arquivo traefik-basicauth não encontrado${NC}"
    echo -e "${BLUE}🔨 Criando arquivo de autenticação básica...${NC}"

    # Gerar credencial segura (admin:admin gerado com htpasswd ou equivalente)
    echo "admin:$(openssl passwd -apr1 admin)" > ./secrets/traefik-basicauth
    chmod 600 ./secrets/traefik-basicauth

    echo -e "${GREEN}✅ Arquivo traefik-basicauth criado com usuário 'admin' e senha 'admin'${NC}"
    echo -e "${YELLOW}⚠️  Recomendação: Altere a senha padrão após o primeiro login${NC}"
else
    echo -e "${GREEN}✅ Arquivo traefik-basicauth já existe${NC}"
fi

# 3. Corrigir mapeamento de volumes no docker-compose.yml
echo -e "\n${BLUE}=== 🛠️  Verificando mapeamentos de volumes no docker-compose.yml ===${NC}"
if grep -q "/secrets:/secrets" docker-compose.yml; then
    echo -e "${GREEN}✅ O volume de secrets já está mapeado corretamente${NC}"
else
    echo -e "${YELLOW}⚠️  O volume de secrets não está mapeado no docker-compose.yml${NC}"
    echo -e "${BLUE}🔨 Adicionando mapeamento no docker-compose.yml...${NC}"

    # Backup do arquivo
    cp docker-compose.yml docker-compose.yml.bak

    # Adicionar mapeamento de volume
    sed -i '' '/volumes:/a\\      - ./secrets:/secrets:ro' docker-compose.yml 2>/dev/null || sed -i '/volumes:/a\\      - ./secrets:/secrets:ro' docker-compose.yml

    echo -e "${GREEN}✅ Volume de secrets adicionado ao docker-compose.yml${NC}"
    echo -e "${BLUE}ℹ️  Foi criado um backup: docker-compose.yml.bak${NC}"
fi

# 4. Corrigir versão do Traefik no docker-compose.yml
echo -e "\n${BLUE}=== 🛠️  Verificando versão do Traefik no docker-compose.yml ===${NC}"
if [[ -n "$CONTAINER_VERSION" && "$CONTAINER_VERSION" != *"$COMPOSE_VERSION"* ]]; then
    echo -e "${YELLOW}⚠️  Versões incompatíveis detectadas${NC}"
    echo -e "${BLUE}🔨 Atualizando versão no docker-compose.yml...${NC}"

    # Backup do arquivo se ainda não existir
    if [ ! -f "docker-compose.yml.bak" ]; then
        cp docker-compose.yml docker-compose.yml.bak
        echo -e "${BLUE}ℹ️  Foi criado um backup: docker-compose.yml.bak${NC}"
    fi

    # Extrair a versão real
    REAL_VERSION=$(echo "$CONTAINER_VERSION" | grep -o "v[0-9]\+\.[0-9]\+\(\.[0-9]\+\)*" || echo "v3.1.7")

    # Atualizar a versão no docker-compose.yml
    sed -i '' "s|image: traefik:.*|image: traefik:${REAL_VERSION}|" docker-compose.yml 2>/dev/null || sed -i "s|image: traefik:.*|image: traefik:${REAL_VERSION}|" docker-compose.yml

    echo -e "${GREEN}✅ Versão do Traefik atualizada para ${REAL_VERSION} no docker-compose.yml${NC}"
fi

echo -e "\n${GREEN}=== 🎉 Correções concluídas ===${NC}"
echo -e "${BLUE}ℹ️  Para aplicar as alterações, reinicie os contêineres:${NC}"
echo -e "${BLUE}   docker-compose down${NC}"
echo -e "${BLUE}   docker-compose up -d${NC}"
echo -e "\n${YELLOW}⚠️  Observe os logs após a reinicialização para verificar se todos os problemas foram resolvidos:${NC}"
echo -e "${BLUE}   docker-compose logs -f traefik${NC}"