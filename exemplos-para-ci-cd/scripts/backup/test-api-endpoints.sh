#!/bin/bash

# 🧪 TESTE ESPECÍFICO DE ENDPOINTS DA API
# ✅ Testa endpoints específicos da API REST que devem funcionar
# 🎯 Foco: Validação de funcionalidade dos endpoints, não roteamento

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações específicas para API
DOMAIN="conexaodesorte.com.br"
BASE_URL="https://www.$DOMAIN"
API_BASE="/rest"

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Endpoints específicos da API para testar
declare -A API_ENDPOINTS=(
    ["Health Check"]="/actuator/health"
    ["Teste Público"]="/v1/publico/teste"
    ["Info Aplicação"]="/v1/info"
    ["Último Resultado RIO"]="/v1/resultados/publico/ultimo/rio"
    ["Último Resultado BOA SORTE"]="/v1/resultados/publico/ultimo/boa%20sorte"
    ["Resultados Públicos"]="/v1/resultados/publico"
    ["Estatísticas"]="/v1/estatisticas/publico"
    ["Horários Válidos"]="/v1/horarios/validos"
)

# Função para testar endpoint específico da API
test_api_endpoint() {
    local name="$1"
    local endpoint="$2"
    local full_url="$BASE_URL$API_BASE$endpoint"

    log_step "Testando endpoint da API: $name"
    log_info "URL: $full_url"

    # Teste HTTP com headers apropriados para API
    local http_response=$(curl -s -w "%{http_code}|%{content_type}|%{time_total}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "User-Agent: ConexaoDeSorte-API-Test/1.0" \
        -o /tmp/api_response.txt \
        "$full_url" 2>/dev/null || echo "000|||")

    local http_code=$(echo "$http_response" | cut -d'|' -f1)
    local content_type=$(echo "$http_response" | cut -d'|' -f2)
    local time_total=$(echo "$http_response" | cut -d'|' -f3)
    local http_content=$(cat /tmp/api_response.txt 2>/dev/null || echo "")

    log_info "HTTP Code: $http_code, Content-Type: $content_type, Tempo: ${time_total}s"

    case "$http_code" in
        "200")
            log_success "HTTP 200 - Endpoint funcionando"

        # Verificar se é JSON válido
        if echo "$http_content" | jq . >/dev/null 2>&1; then
            log_success "Resposta JSON válida"

                # Extrair informações específicas baseadas no endpoint
                case "$endpoint" in
                    "/actuator/health")
                        local status=$(echo "$http_content" | jq -r '.status // "N/A"' 2>/dev/null)
                        log_info "Status da aplicação: $status"
                        ;;
                    "/v1/resultados/publico/ultimo/"*)
                        local horario=$(echo "$http_content" | jq -r '.horario // "N/A"' 2>/dev/null)
                        local numeros=$(echo "$http_content" | jq -r '.numeros // [] | length' 2>/dev/null)
                        log_info "Horário: $horario, Números: $numeros"
                        ;;
                    "/v1/publico/teste")
                        log_info "Resposta de teste: $http_content"
                        ;;
                    *)
                        # Mostrar preview genérico
            local preview=$(echo "$http_content" | jq -c . | head -c 100)
            log_info "Preview: $preview..."
                        ;;
                esac

        elif [[ "$http_content" == "teste" ]]; then
            log_success "Resposta texto válida: $http_content"
        else
            log_warn "Resposta não é JSON válido"
            log_info "Conteúdo: $(echo "$http_content" | head -c 100)..."
        fi
            ;;

        "404")
        log_error "HTTP 404 - Endpoint não encontrado"
            log_info "Possíveis causas:"
            log_info "  • Endpoint não implementado"
            log_info "  • Path incorreto"
            log_info "  • Controller não mapeado"
            log_info "Conteúdo: $(echo "$http_content" | head -c 200)"
            ;;

        "401"|"403")
            log_error "HTTP $http_code - Problema de autenticação/autorização"
            log_info "Possíveis causas:"
            log_info "  • Endpoint requer autenticação"
            log_info "  • Configuração de segurança incorreta"
        log_info "Conteúdo: $(echo "$http_content" | head -c 200)"
            ;;

        "500")
        log_error "HTTP 500 - Erro interno do servidor"
            log_info "Possíveis causas:"
            log_info "  • Exceção não tratada"
            log_info "  • Problema com banco de dados"
            log_info("  • Configuração incorreta"
        log_info "Conteúdo: $(echo "$http_content" | head -c 200)"
            ;;

        "000")
        log_error "Falha na conexão - Servidor não responde"
            ;;

        *)
            log_warn "HTTP $http_code - Status inesperado"
        log_info "Conteúdo: $(echo "$http_content" | head -c 200)"
            ;;
    esac

    echo ""
    return $([ "$http_code" = "200" ] && echo 0 || echo 1)
}

# Função para testar conectividade básica da API
test_api_connectivity() {
    log_step "Testando conectividade básica da API..."

    # Teste DNS
    if nslookup "$DOMAIN" >/dev/null 2>&1; then
        log_success "DNS resolve corretamente"
    else
        log_error "Falha na resolução DNS"
        return 1
    fi

    # Teste HTTPS básico para API
    if curl -s -k --connect-timeout 10 "$BASE_URL$API_BASE/actuator/health" >/dev/null 2>&1; then
        log_success "API HTTPS básico funciona"
    else
        log_warn "API HTTPS básico não responde"
    fi

    echo ""
}

# Função para testar estrutura da API
test_api_structure() {
    log_step "Testando estrutura da API..."

    # Testar base da API
    local api_base_url="$BASE_URL$API_BASE"
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$api_base_url" 2>/dev/null || echo "000")

    if [[ "$response" == "404" ]]; then
        log_info "Base da API retorna 404 (normal - sem endpoint raiz)"
    elif [[ "$response" == "200" ]]; then
        log_success "Base da API responde"
    else
        log_warn "Base da API retorna: $response"
    fi

    # Testar se API está roteando corretamente
    local api_test=$(curl -s "$BASE_URL$API_BASE/actuator/health" | head -c 50 2>/dev/null || echo "")
    if [[ "$api_test" == *"status"* ]]; then
        log_success "API roteando corretamente"
    else
        log_error "API não está roteando corretamente"
        log_info "Resposta: $api_test"
    fi

    echo ""
}

# Função para verificar performance da API
test_api_performance() {
    log_step "Testando performance da API..."

    local endpoint="/actuator/health"
    local full_url="$BASE_URL$API_BASE$endpoint"
    local total_time=0
    local success_count=0
    local test_count=5

    log_info "Executando $test_count testes de performance em $full_url"

    for i in $(seq 1 $test_count); do
        local response=$(curl -s -w "%{http_code}|%{time_total}" \
            -H "Accept: application/json" \
            -o /dev/null \
            "$full_url" 2>/dev/null || echo "000|0")

        local http_code=$(echo "$response" | cut -d'|' -f1)
        local time_total=$(echo "$response" | cut -d'|' -f2)

        if [[ "$http_code" == "200" ]]; then
            total_time=$(echo "$total_time + $time_total" | bc -l 2>/dev/null || echo "$total_time")
            ((success_count++))
            log_info "Teste $i: ${time_total}s"
        else
            log_warn "Teste $i: HTTP $http_code"
        fi
    done

    if [[ $success_count -gt 0 ]]; then
        local avg_time=$(echo "scale=3; $total_time / $success_count" | bc -l 2>/dev/null || echo "N/A")
        log_success "Performance: $success_count/$test_count sucessos, tempo médio: ${avg_time}s"
    else
        log_error "Nenhum teste de performance bem-sucedido"
    fi

    echo ""
}

# Função para mostrar resumo específico da API
show_api_summary() {
    log_header "RESUMO DOS TESTES DA API"

    local total_tests=${#API_ENDPOINTS[@]}
    local successful_tests=0

    echo -e "${BLUE}📊 Resultados dos endpoints:${NC}"

    # Recontar sucessos
    for name in "${!API_ENDPOINTS[@]}"; do
        local endpoint="${API_ENDPOINTS[$name]}"
        local full_url="$BASE_URL$API_BASE$endpoint"
        local response=$(curl -s -w "%{http_code}" -o /dev/null "$full_url" 2>/dev/null || echo "000")

        if [[ "$response" == "200" ]]; then
            echo -e "  ${GREEN}✅ $name${NC}"
            ((successful_tests++))
        else
            echo -e "  ${RED}❌ $name (HTTP $response)${NC}"
        fi
    done

    echo -e "\n${BLUE}📈 Estatísticas da API:${NC}"
    echo -e "  Total de endpoints: ${CYAN}$total_tests${NC}"
    echo -e "  Endpoints funcionando: ${GREEN}$successful_tests${NC}"
    echo -e "  Endpoints com problema: ${RED}$((total_tests - successful_tests))${NC}"

    if [[ $successful_tests -eq $total_tests ]]; then
        echo -e "\n${GREEN}🎉 Todos os endpoints da API estão funcionando!${NC}"
    elif [[ $successful_tests -gt 0 ]]; then
        echo -e "\n${YELLOW}⚠️ Alguns endpoints da API têm problemas${NC}"
    else
        echo -e "\n${RED}❌ Todos os endpoints da API falharam${NC}"
    fi

    echo -e "\n${BLUE}🔗 URLs importantes da API:${NC}"
    echo -e "  Base da API: ${CYAN}$BASE_URL$API_BASE${NC}"
    echo -e "  Health Check: ${CYAN}$BASE_URL$API_BASE/actuator/health${NC}"
    echo -e "  Teste Público: ${CYAN}$BASE_URL$API_BASE/v1/publico/teste${NC}"
    echo -e "  Resultados: ${CYAN}$BASE_URL$API_BASE/v1/resultados/publico${NC}"
}

# Função principal
main() {
    log_header "TESTE ESPECÍFICO DE ENDPOINTS DA API"

    echo -e "${YELLOW}🎯 Testando endpoints da API em: $BASE_URL$API_BASE${NC}"
    echo -e "${BLUE}ℹ️ Endpoints configurados: ${#API_ENDPOINTS[@]}${NC}"
    echo -e "${CYAN}📋 Foco: Validação de funcionalidade dos endpoints da API${NC}\n"

    # Verificar dependências
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl não encontrado - instale curl para executar os testes"
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq não encontrado - validação JSON será limitada"
    fi

    if ! command -v bc >/dev/null 2>&1; then
        log_warn "bc não encontrado - cálculos de performance serão limitados"
    fi

    # Executar testes
    test_api_connectivity
    test_api_structure
    test_api_performance

    # Testar cada endpoint da API
    for name in "${!API_ENDPOINTS[@]}"; do
        test_api_endpoint "$name" "${API_ENDPOINTS[$name]}"
    done

    show_api_summary

    echo -e "\n${GREEN}🧪 Testes da API concluídos!${NC}\n"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
