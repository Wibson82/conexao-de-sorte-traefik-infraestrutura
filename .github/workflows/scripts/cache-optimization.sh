#!/bin/bash
# =============================================================================
# 🚀 CACHE OPTIMIZATION SCRIPT - TRAEFIK INFRASTRUCTURE
# =============================================================================
# Implementa cache inteligente multi-nível para acelerar builds e deploys

set -euo pipefail
IFS=$'\n\t'

# Configurações
CACHE_DIR="/tmp/.traefik-cache"
CACHE_KEY_PREFIX="${CACHE_KEY_PREFIX:-traefik-infra}"
CACHE_RETENTION_DAYS="${CACHE_RETENTION_DAYS:-7}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
}

# =============================================================================
# 🔧 SETUP CACHE ENVIRONMENT
# =============================================================================
setup_cache_environment() {
    log "🔧 Configurando ambiente de cache..."

    # Criar diretórios de cache
    mkdir -p "$CACHE_DIR"/{configs,secrets,compose}

    # Verificar espaço disponível
    available_space=$(df /tmp | awk 'NR==2 {print $4}')
    available_gb=$((available_space / 1024 / 1024))

    if [[ $available_gb -lt 1 ]]; then
        log_warning "Pouco espaço disponível em /tmp: ${available_gb}GB"
        log "🧹 Executando limpeza prévia..."
        cleanup_old_cache
    fi

    log_success "Ambiente de cache configurado"
}

# =============================================================================
# 🔍 GENERATE CACHE KEYS
# =============================================================================
generate_cache_keys() {
    log "🔍 Gerando chaves de cache..."

    # Cache key para configurações
    local config_files=(
        "docker-compose.yml"
        "traefik/traefik.yml"
        "traefik/dynamic/*.yml"
        ".env.ci"
    )

    local config_hash=""
    for pattern in "${config_files[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                config_hash+=$(sha256sum "$file" | cut -d' ' -f1)
            fi
        done
    done

    CONFIG_CACHE_KEY="${CACHE_KEY_PREFIX}-config-$(echo "$config_hash" | sha256sum | cut -d' ' -f1 | head -c 12)"

    # Cache key para compose
    if [[ -f "docker-compose.yml" ]]; then
        COMPOSE_CACHE_KEY="${CACHE_KEY_PREFIX}-compose-$(sha256sum docker-compose.yml | cut -d' ' -f1 | head -c 12)"
    fi

    # Cache key para secrets
    SECRET_CACHE_KEY="${CACHE_KEY_PREFIX}-secrets-$(date +%Y%m%d)"

    log_success "Chaves de cache geradas:"
    log "  📋 Config: $CONFIG_CACHE_KEY"
    log "  🐳 Compose: $COMPOSE_CACHE_KEY"
    log "  🔐 Secrets: $SECRET_CACHE_KEY"
}

# =============================================================================
# 💾 CACHE OPERATIONS
# =============================================================================
save_to_cache() {
    local cache_type="$1"
    local cache_key="$2"
    local source_path="$3"

    log "💾 Salvando no cache: $cache_type"

    local cache_path="$CACHE_DIR/$cache_type/$cache_key"
    mkdir -p "$cache_path"

    if [[ -d "$source_path" ]]; then
        cp -r "$source_path"/* "$cache_path/"
    elif [[ -f "$source_path" ]]; then
        cp "$source_path" "$cache_path/"
    else
        log_warning "Fonte não encontrada: $source_path"
        return 1
    fi

    # Adicionar metadados
    cat > "$cache_path/.cache-metadata" <<EOF
{
  "cache_key": "$cache_key",
  "cache_type": "$cache_type",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source_path": "$source_path",
  "size_bytes": $(du -sb "$cache_path" | cut -f1)
}
EOF

    log_success "Cache salvo: $cache_key"
}

load_from_cache() {
    local cache_type="$1"
    local cache_key="$2"
    local dest_path="$3"

    log "📥 Carregando do cache: $cache_type"

    local cache_path="$CACHE_DIR/$cache_type/$cache_key"

    if [[ ! -d "$cache_path" ]]; then
        log_warning "Cache não encontrado: $cache_key"
        return 1
    fi

    # Verificar idade do cache
    if [[ -f "$cache_path/.cache-metadata" ]]; then
        local created_at=$(jq -r '.created_at' "$cache_path/.cache-metadata" 2>/dev/null || echo "")
        if [[ -n "$created_at" ]]; then
            local cache_age_days=$(( ($(date +%s) - $(date -d "$created_at" +%s)) / 86400 ))
            if [[ $cache_age_days -gt $CACHE_RETENTION_DAYS ]]; then
                log_warning "Cache expirado (${cache_age_days} dias): $cache_key"
                rm -rf "$cache_path"
                return 1
            fi
        fi
    fi

    # Restaurar do cache
    mkdir -p "$dest_path"
    cp -r "$cache_path"/* "$dest_path/"

    log_success "Cache carregado: $cache_key"
    return 0
}

# =============================================================================
# 🧹 CACHE CLEANUP
# =============================================================================
cleanup_old_cache() {
    log "🧹 Limpando cache antigo..."

    local deleted_count=0
    local total_size=0

    find "$CACHE_DIR" -type d -name "*-*-*" | while read -r cache_dir; do
        if [[ -f "$cache_dir/.cache-metadata" ]]; then
            local created_at=$(jq -r '.created_at' "$cache_dir/.cache-metadata" 2>/dev/null || echo "")
            if [[ -n "$created_at" ]]; then
                local cache_age_days=$(( ($(date +%s) - $(date -d "$created_at" +%s)) / 86400 ))
                if [[ $cache_age_days -gt $CACHE_RETENTION_DAYS ]]; then
                    local size_bytes=$(jq -r '.size_bytes' "$cache_dir/.cache-metadata" 2>/dev/null || echo "0")
                    total_size=$((total_size + size_bytes))

                    log "🗑️ Removendo cache expirado: $(basename "$cache_dir") (${cache_age_days} dias)"
                    rm -rf "$cache_dir"
                    deleted_count=$((deleted_count + 1))
                fi
            fi
        fi
    done

    if [[ $deleted_count -gt 0 ]]; then
        local size_mb=$((total_size / 1024 / 1024))
        log_success "Cache limpo: $deleted_count diretórios, ${size_mb}MB liberados"
    else
        log "ℹ️ Nenhum cache antigo encontrado"
    fi
}

# =============================================================================
# 📊 CACHE STATISTICS
# =============================================================================
show_cache_stats() {
    log "📊 Estatísticas do cache:"

    if [[ ! -d "$CACHE_DIR" ]]; then
        log "ℹ️ Nenhum cache encontrado"
        return 0
    fi

    local total_dirs=0
    local total_size=0
    local cache_types=()

    find "$CACHE_DIR" -type d -name "*-*-*" | while read -r cache_dir; do
        if [[ -f "$cache_dir/.cache-metadata" ]]; then
            local cache_type=$(jq -r '.cache_type' "$cache_dir/.cache-metadata" 2>/dev/null || echo "unknown")
            local size_bytes=$(jq -r '.size_bytes' "$cache_dir/.cache-metadata" 2>/dev/null || echo "0")

            cache_types+=("$cache_type")
            total_size=$((total_size + size_bytes))
            total_dirs=$((total_dirs + 1))
        fi
    done

    if [[ $total_dirs -gt 0 ]]; then
        local size_mb=$((total_size / 1024 / 1024))
        log "  📁 Total de caches: $total_dirs"
        log "  💾 Tamanho total: ${size_mb}MB"

        # Mostrar por tipo
        printf '%s\n' "${cache_types[@]}" | sort | uniq -c | while read -r count type; do
            log "  📋 $type: $count caches"
        done
    else
        log "ℹ️ Nenhum cache válido encontrado"
    fi
}

# =============================================================================
# 🚀 MAIN FUNCTION
# =============================================================================
main() {
    local action="${1:-help}"

    case "$action" in
        "setup")
            setup_cache_environment
            generate_cache_keys
            ;;
        "save")
            local cache_type="${2:-}"
            local source_path="${3:-}"
            if [[ -z "$cache_type" ]] || [[ -z "$source_path" ]]; then
                log_error "Uso: $0 save <tipo> <caminho_fonte>"
                exit 1
            fi
            generate_cache_keys
            local cache_key_var="${cache_type^^}_CACHE_KEY"
            save_to_cache "$cache_type" "${!cache_key_var}" "$source_path"
            ;;
        "load")
            local cache_type="${2:-}"
            local dest_path="${3:-}"
            if [[ -z "$cache_type" ]] || [[ -z "$dest_path" ]]; then
                log_error "Uso: $0 load <tipo> <caminho_destino>"
                exit 1
            fi
            generate_cache_keys
            local cache_key_var="${cache_type^^}_CACHE_KEY"
            load_from_cache "$cache_type" "${!cache_key_var}" "$dest_path"
            ;;
        "cleanup")
            cleanup_old_cache
            ;;
        "stats")
            show_cache_stats
            ;;
        "help"|*)
            cat <<EOF
🚀 Cache Optimization Script - Traefik Infrastructure

Uso: $0 <ação> [argumentos]

Ações disponíveis:
  setup                     - Configurar ambiente de cache
  save <tipo> <fonte>       - Salvar no cache
  load <tipo> <destino>     - Carregar do cache
  cleanup                   - Limpar cache antigo
  stats                     - Mostrar estatísticas
  help                      - Mostrar esta ajuda

Tipos de cache suportados:
  - config    (configurações Traefik)
  - compose   (arquivo docker-compose)
  - secrets   (Docker secrets)

Exemplos:
  $0 setup
  $0 save config ./traefik
  $0 load config ./traefik-restored
  $0 cleanup
  $0 stats

Variáveis de ambiente:
  CACHE_KEY_PREFIX         - Prefixo das chaves (padrão: traefik-infra)
  CACHE_RETENTION_DAYS     - Dias para reter cache (padrão: 7)
EOF
            ;;
    esac
}

# Executar função principal se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi