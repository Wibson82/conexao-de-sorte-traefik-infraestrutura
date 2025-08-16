#!/bin/bash

# ===== GERADOR DE TAG DE VERSÃO =====
# Sistema: Conexão de Sorte - Backend
# Função: Gerar tags consistentes baseadas na data brasileira
# Formato: DD-MM-AAAA-HH (padrão brasileiro)
# Versão: 1.0.0

set -euo pipefail

# ===== CONFIGURAÇÕES =====
REGISTRY="docker.io"
REGISTRY_NAMESPACE="facilita"
IMAGE_NAME="conexao-de-sorte-backend"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ===== FUNÇÕES =====
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Gerar tag baseada na data brasileira
generate_date_tag() {
    local brazil_date
    brazil_date=$(TZ='America/Sao_Paulo' date +'%d-%m-%Y-%H')
    echo "$brazil_date"
}

# Gerar tag completa da imagem
generate_image_tag() {
    local date_tag="$1"
    echo "$REGISTRY/$REGISTRY_NAMESPACE/$IMAGE_NAME:$date_tag"
}

# Mostrar informações da tag
show_tag_info() {
    local date_tag="$1"
    local image_tag="$2"
    
    log_info "Tag de versão gerada:"
    echo "  📅 Data/Hora: $date_tag"
    echo "  🏷️ Tag: $date_tag"
    echo "  🐳 Imagem: $image_tag"
    echo "  🌎 Timezone: America/Sao_Paulo"
}

# Validar formato da tag
validate_tag_format() {
    local tag="$1"
    
    if [[ $tag =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}-[0-9]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    local action="${1:-generate}"
    
    case "$action" in
        "generate")
            local date_tag
            date_tag=$(generate_date_tag)
            local image_tag
            image_tag=$(generate_image_tag "$date_tag")
            
            show_tag_info "$date_tag" "$image_tag"
            
            # Output para uso em scripts
            echo "DATE_TAG=$date_tag"
            echo "IMAGE_TAG=$image_tag"
            ;;
            
        "date-only")
            generate_date_tag
            ;;
            
        "image-only")
            local date_tag
            date_tag=$(generate_date_tag)
            generate_image_tag "$date_tag"
            ;;
            
        "validate")
            local tag_to_validate="${2:-}"
            if [[ -z "$tag_to_validate" ]]; then
                echo "Erro: Tag não fornecida para validação"
                exit 1
            fi
            
            if validate_tag_format "$tag_to_validate"; then
                log_success "Tag '$tag_to_validate' está no formato correto"
                exit 0
            else
                log_warning "Tag '$tag_to_validate' não está no formato correto (DD-MM-AAAA-HH)"
                exit 1
            fi
            ;;
            
        "help")
            echo "Uso: $0 [generate|date-only|image-only|validate <tag>|help]"
            echo ""
            echo "Comandos:"
            echo "  generate     - Gerar tag completa com informações (padrão)"
            echo "  date-only    - Gerar apenas a tag de data"
            echo "  image-only   - Gerar apenas a tag completa da imagem"
            echo "  validate     - Validar formato de uma tag"
            echo "  help         - Mostrar esta ajuda"
            echo ""
            echo "Formato da tag: DD-MM-AAAA-HH (padrão brasileiro)"
            echo "Timezone: America/Sao_Paulo"
            echo ""
            echo "Exemplos:"
            echo "  $0                           # Gerar tag completa"
            echo "  $0 date-only                # Apenas: 15-03-2024-14"
            echo "  $0 image-only               # Apenas: facilita/conexao-de-sorte-backend:15-03-2024-14"
            echo "  $0 validate 15-03-2024-14   # Validar formato"
            ;;
            
        *)
            echo "Comando inválido: $action"
            echo "Use '$0 help' para ver os comandos disponíveis"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"