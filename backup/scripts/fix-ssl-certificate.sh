#!/bin/bash
# =============================================================================
# 🔒 CORREÇÃO DE CERTIFICADOS SSL PARA TRAEFIK
# =============================================================================
# Este script verifica e corrige problemas comuns com certificados SSL
# que podem causar erros como "ERR_CERT_AUTHORITY_INVALID" no frontend

set -e

# Definição de cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
ACME_FILE="$PROJECT_DIR/letsencrypt/acme.json"
TRAEFIK_CONFIG="$PROJECT_DIR/traefik/traefik.yml"
DOMAIN="conexaodesorte.com.br"
WILDCARD_DOMAIN="*.$DOMAIN"

# Funções de utilidade
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Banner
echo ""
echo "==================================================================="
echo "🔒 CORREÇÃO DE CERTIFICADOS SSL PARA TRAEFIK"
echo "==================================================================="
echo "Domínio: $DOMAIN"
echo "Arquivo ACME: $ACME_FILE"
echo "==================================================================="
echo ""

# Verificar se o Docker está rodando
log "Verificando se o Docker está em execução..."
if ! docker info &>/dev/null; then
    error "Docker não está em execução. Por favor, inicie o Docker e tente novamente."
    exit 1
else
    success "Docker está em execução."
fi

# Verificar arquivo acme.json
log "Verificando arquivo acme.json..."
if [ ! -f "$ACME_FILE" ]; then
    warning "Arquivo acme.json não encontrado. Criando arquivo vazio..."
    mkdir -p "$(dirname "$ACME_FILE")"
    touch "$ACME_FILE"
    chmod 600 "$ACME_FILE"
    success "Arquivo acme.json criado com permissões 600."
else
    # Verificar permissões
    PERMS=$(stat -f "%A" "$ACME_FILE")
    if [ "$PERMS" != "600" ]; then
        warning "Permissões incorretas no arquivo acme.json: $PERMS. Corrigindo para 600..."
        chmod 600 "$ACME_FILE"
        success "Permissões corrigidas para 600."
    else
        success "Arquivo acme.json existe com permissões corretas."
    fi

    # Verificar tamanho
    SIZE=$(stat -f "%z" "$ACME_FILE")
    if [ "$SIZE" -lt 100 ]; then
        warning "Arquivo acme.json parece estar vazio ou corrompido (tamanho: $SIZE bytes)."
    else
        success "Arquivo acme.json parece válido (tamanho: $SIZE bytes)."
    fi
fi

# Verificar configuração do Traefik
log "Verificando configuração do certificado no Traefik..."
if [ ! -f "$TRAEFIK_CONFIG" ]; then
    error "Arquivo de configuração Traefik não encontrado: $TRAEFIK_CONFIG"
    exit 1
fi

# Verificar se o resolvedor de certificado está configurado
if ! grep -q "certificatesResolvers" "$TRAEFIK_CONFIG"; then
    error "Configuração de certificatesResolvers não encontrada no arquivo Traefik."
    exit 1
else
    success "Configuração de certificatesResolvers encontrada."
fi

# Verificar inconsistências entre arquivos
log "Verificando consistência de configuração..."

# Verificar versões do Traefik
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
if [ -f "$COMPOSE_FILE" ]; then
    TRAEFIK_VERSION=$(grep "traefik:" "$COMPOSE_FILE" | grep -o "v[0-9.]*" || echo "não encontrada")
    log "Versão do Traefik no docker-compose.yml: $TRAEFIK_VERSION"

    # Verificar se existem múltiplos arquivos docker-compose
    if [ -f "$PROJECT_DIR/docker-compose-sem-conflitos.yml" ]; then
        TRAEFIK_VERSION_ALT=$(grep "traefik:" "$PROJECT_DIR/docker-compose-sem-conflitos.yml" | grep -o "v[0-9.]*" || echo "não encontrada")
        if [ "$TRAEFIK_VERSION" != "$TRAEFIK_VERSION_ALT" ]; then
            warning "Inconsistência de versões do Traefik entre docker-compose.yml ($TRAEFIK_VERSION) e docker-compose-sem-conflitos.yml ($TRAEFIK_VERSION_ALT)."
            read -p "Deseja padronizar para a versão mais recente? (s/n): " STANDARDIZE
            if [[ "$STANDARDIZE" == "s" ]]; then
                # Determinar a versão mais recente
                if [[ "$TRAEFIK_VERSION" > "$TRAEFIK_VERSION_ALT" ]]; then
                    LATEST_VERSION="$TRAEFIK_VERSION"
                else
                    LATEST_VERSION="$TRAEFIK_VERSION_ALT"
                fi

                # Atualizar versão em ambos os arquivos
                sed -i '' "s|traefik:v[0-9.]*|traefik:$LATEST_VERSION|g" "$COMPOSE_FILE" || true
                sed -i '' "s|traefik:v[0-9.]*|traefik:$LATEST_VERSION|g" "$PROJECT_DIR/docker-compose-sem-conflitos.yml" || true
                success "Versões padronizadas para $LATEST_VERSION."
            fi
        else
            success "Versões do Traefik são consistentes entre os arquivos docker-compose."
        fi
    fi
fi

# Verificar consistência do resolvedor de certificado
log "Verificando consistência do resolvedor de certificado..."
CERT_RESOLVER_NAME=$(grep -A3 "certificatesResolvers:" "$TRAEFIK_CONFIG" | grep -o '[a-zA-Z0-9]*:' | tr -d ':' | head -1)
log "Nome do resolvedor de certificado no traefik.yml: $CERT_RESOLVER_NAME"

# Verificar arquivos de rotas
ROUTES_FILES=("$PROJECT_DIR/traefik/dynamic/backend-routes.yml" "$PROJECT_DIR/traefik/dynamic/microservices-routes.yml")
INCONSISTENT_RESOLVERS=false

for ROUTE_FILE in "${ROUTES_FILES[@]}"; do
    if [ -f "$ROUTE_FILE" ]; then
        # Extrair todos os resolvedores de certificados usados
        RESOLVERS_USED=$(grep -A1 "tls:" "$ROUTE_FILE" | grep "certresolver:" | awk '{print $2}' | sort -u)

        for RESOLVER in $RESOLVERS_USED; do
            if [ "$RESOLVER" != "$CERT_RESOLVER_NAME" ]; then
                warning "Inconsistência de resolvedor no arquivo $ROUTE_FILE. Usando: $RESOLVER, deveria ser: $CERT_RESOLVER_NAME"
                INCONSISTENT_RESOLVERS=true
            fi
        done
    fi
done

if [ "$INCONSISTENT_RESOLVERS" = true ]; then
    read -p "Deseja corrigir inconsistências no resolvedor de certificado? (s/n): " FIX_RESOLVERS
    if [[ "$FIX_RESOLVERS" == "s" ]]; then
        for ROUTE_FILE in "${ROUTES_FILES[@]}"; do
            if [ -f "$ROUTE_FILE" ]; then
                sed -i '' "s/certresolver: [a-zA-Z0-9]*/certresolver: $CERT_RESOLVER_NAME/g" "$ROUTE_FILE" || true
            fi
        done
        success "Resolvedores de certificado padronizados para '$CERT_RESOLVER_NAME' em todos os arquivos."
    fi
else
    success "Resolvedores de certificado são consistentes entre os arquivos."
fi

# Opção para renovar certificado
echo ""
log "Deseja tentar renovar o certificado?"
read -p "Renovar certificado SSL (isso reiniciará o Traefik)? (s/n): " RENEW_CERT

if [[ "$RENEW_CERT" == "s" ]]; then
    log "Preparando para renovar certificado..."

    # Backup do acme.json
    BACKUP_TIME=$(date +"%Y%m%d%H%M%S")
    BACKUP_FILE="$PROJECT_DIR/letsencrypt/acme.json.backup-$BACKUP_TIME"
    cp "$ACME_FILE" "$BACKUP_FILE" 2>/dev/null || true
    success "Backup do acme.json criado: $BACKUP_FILE"

    # Opções de renovação
    echo ""
    echo "Selecione o método de renovação:"
    echo "1) Remover acme.json e deixar o Traefik gerar novo certificado"
    echo "2) Usar script setup-ssl-wildcard.sh para certificado wildcard"
    echo "3) Forçar renovação sem remover acme.json (recomendado se tiver problemas específicos)"
    echo ""
    read -p "Opção (1-3): " RENEW_METHOD

    case $RENEW_METHOD in
        1)
            log "Removendo acme.json para renovação completa..."
            rm -f "$ACME_FILE"
            touch "$ACME_FILE"
            chmod 600 "$ACME_FILE"
            ;;
        2)
            if [ -f "$PROJECT_DIR/setup-ssl-wildcard.sh" ]; then
                log "Executando script de configuração de certificado wildcard..."
                bash "$PROJECT_DIR/setup-ssl-wildcard.sh"
            else
                error "Script setup-ssl-wildcard.sh não encontrado."
                exit 1
            fi
            ;;
        3)
            log "Preparando para forçar renovação sem remover configuração..."
            # Não faz nada com o arquivo acme.json
            ;;
        *)
            error "Opção inválida. Saindo."
            exit 1
            ;;
    esac

    # Reiniciar o Traefik
    log "Tentando reiniciar o Traefik..."
    if docker ps -a | grep -q traefik; then
        if docker-compose -f "$COMPOSE_FILE" restart traefik; then
            success "Traefik reiniciado com sucesso."
        else
            warning "Falha ao reiniciar com docker-compose. Tentando método alternativo..."
            docker restart $(docker ps -q --filter "name=traefik") 2>/dev/null || true
        fi
    else
        warning "Nenhum container Traefik encontrado em execução. Verifique se o serviço está rodando."
    fi

    log "Aguardando emissão do certificado (30 segundos)..."
    sleep 30

    # Verificar novo tamanho do acme.json
    NEW_SIZE=$(stat -f "%z" "$ACME_FILE" 2>/dev/null || echo "0")
    log "Tamanho atual do acme.json: $NEW_SIZE bytes"

    echo ""
    log "A renovação foi concluída. Verifique o frontend para confirmar se o erro foi resolvido."
    log "Se o problema persistir, considere verificar os logs do Traefik com: docker logs <traefik-container-id>"
fi

echo ""
echo "==================================================================="
echo "🔍 RECOMENDAÇÕES ADICIONAIS:"
echo "==================================================================="
echo "1. Verifique a configuração de CORS no arquivo middlewares.yml"
echo "2. Certifique-se de que o domínio e subdomínios estão apontados"
echo "   corretamente para o servidor nos registros DNS"
echo "3. Verifique logs do Traefik para detalhes específicos sobre erros"
echo "4. Considere utilizar Cloudflare DNS Challenge para certificados wildcard"
echo "==================================================================="

exit 0