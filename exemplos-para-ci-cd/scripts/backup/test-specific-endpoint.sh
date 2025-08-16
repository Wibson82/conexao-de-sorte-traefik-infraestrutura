#!/bin/bash

# 🎯 TESTE ESPECÍFICO DE ENDPOINTS DE RESULTADOS DE LOTERIA
# ✅ Testa especificamente endpoints de resultados que devem funcionar
# 🎯 Foco: Validação de endpoints de resultados de loteria específicos

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações específicas para resultados de loteria
DOMAIN_BASE="conexaodesorte.com.br"
DOMAIN_WWW="www.conexaodesorte.com.br"
ENDPOINT_PATH="/rest/v1/resultados/publico/ultimo"
HORARIOS_LOTERIA=("rio" "boa sorte" "boa%20sorte")

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Função para testar endpoint específico de resultado de loteria
test_lottery_endpoint() {
    local domain="$1"
    local protocol="$2"
    local horario="$3"
    local full_url="$protocol://$domain$ENDPOINT_PATH/$horario"

    log_step "Testando resultado de loteria: $domain ($protocol) - Horário: $horario"
    log_info "URL: $full_url"

    # Teste detalhado com headers específicos para loteria
    local response=$(curl -s -w "%{http_code}|%{content_type}|%{time_total}|%{size_download}" \
                          -H "Accept: application/json" \
                          -H "User-Agent: ConexaoDeSorte-Lottery-Test/1.0" \
                          -o /tmp/lottery_response_${domain}_${horario}.txt \
                          "$full_url" \
                          --connect-timeout 15 \
                          --max-time 30 \
                          2>/dev/null || echo "000|||0")

    IFS='|' read -r http_code content_type time_total size_download <<< "$response"
    local content=$(cat /tmp/lottery_response_${domain}_${horario}.txt 2>/dev/null || echo "")

    # Análise detalhada da resposta de loteria
    case "$http_code" in
        "200")
            log_success "HTTP 200 - Resultado de loteria OK (${time_total}s, ${size_download} bytes)"

            # Verificar Content-Type
            if [[ "$content_type" == *"application/json"* ]]; then
                log_success "Content-Type: JSON"
            else
                log_warn "Content-Type: $content_type (esperado JSON)"
            fi

            # Verificar se é JSON válido e extrair dados de loteria
            if echo "$content" | jq . >/dev/null 2>&1; then
                log_success "Resposta JSON válida"

                # Extrair informações específicas do resultado de loteria
                local horario_resp=$(echo "$content" | jq -r '.horario // "N/A"' 2>/dev/null)
                local data_resp=$(echo "$content" | jq -r '.data // "N/A"' 2>/dev/null)
                local numeros=$(echo "$content" | jq -r '.numeros // [] | length' 2>/dev/null)
                local status=$(echo "$content" | jq -r '.status // "N/A"' 2>/dev/null)
                local modalidade=$(echo "$content" | jq -r '.modalidade // "N/A"' 2>/dev/null)

                log_info "Dados do resultado:"
                log_info "  Horário: $horario_resp"
                log_info "  Data: $data_resp"
                log_info "  Modalidade: $modalidade"
                log_info "  Números: $numeros"
                log_info "  Status: $status"

                # Verificar se tem dados válidos de loteria
                if [[ "$numeros" != "0" && "$numeros" != "null" && "$numeros" != "" ]]; then
                    log_success "Resultado contém números válidos de loteria"

                    # Mostrar alguns números (se houver muitos, mostrar apenas os primeiros)
                    local numeros_array=$(echo "$content" | jq -r '.numeros // [] | .[0:5] | join(", ")' 2>/dev/null)
                    if [[ -n "$numeros_array" && "$numeros_array" != "null" ]]; then
                        log_info "Primeiros números: $numeros_array"
                    fi
                else
                    log_warn "Resultado sem números ou dados inválidos"
                fi

            else
                log_error "Resposta não é JSON válido"
                log_info "Conteúdo (primeiros 200 chars): $(echo "$content" | head -c 200)..."

                # Verificar se é HTML de erro
                if echo "$content" | grep -q "<html\|<body\|<!DOCTYPE"; then
                    log_error "Resposta é HTML - possível página de erro"

                    # Extrair título se for HTML
                    local title=$(echo "$content" | grep -o '<title[^>]*>[^<]*</title>' | sed 's/<[^>]*>//g' 2>/dev/null || echo "")
                    if [[ -n "$title" ]]; then
                        log_info "Título da página: $title"
                    fi
                fi
            fi
            ;;

        "404")
            log_error "HTTP 404 - Endpoint de resultado não encontrado"
            log_info "Possíveis causas:"
            log_info "  • Horário '$horario' não existe"
            log_info "  • Controller não mapeado para este horário"
            log_info "  • Path incorreto"
            log_info "Conteúdo: $(echo "$content" | head -c 300)"

            # Verificar se é erro do Spring Boot
            if echo "$content" | jq -r '.title // ""' 2>/dev/null | grep -q "Not Found"; then
                log_error "Erro Spring Boot: Endpoint não mapeado"
                local detail=$(echo "$content" | jq -r '.detail // ""' 2>/dev/null)
                log_info "Detalhe: $detail"
            fi
            ;;

        "403")
            log_error "HTTP 403 - Acesso negado (problema de segurança)"
            log_info "Possíveis causas:"
            log_info "  • Spring Security bloqueando endpoint público"
            log_info("  • Endpoint não está em .permitAll()"
            log_info "Conteúdo: $(echo "$content" | head -c 300)"
            ;;

        "500")
            log_error "HTTP 500 - Erro interno do servidor"
            log_info "Possíveis causas:"
            log_info "  • Erro na aplicação"
            log_info "  • Problema com banco de dados"
            log_info "  • Exceção não tratada"

            if echo "$content" | grep -q -i "database\|mysql\|connection"; then
                log_error "Possível problema de conexão com banco de dados"
            fi
            ;;

        "000")
            log_error "Falha na conexão - Timeout ou DNS"
            log_info "Possíveis causas:"
            log_info "  • Servidor não está respondendo"
            log_info "  • Problema de DNS"
            log_info "  • Timeout de conexão"
            ;;

        *)
            log_warn "HTTP $http_code - Status inesperado"
            log_info "Conteúdo: $(echo "$content" | head -c 300)"
            ;;
    esac

    echo ""
    return $([ "$http_code" = "200" ] && echo 0 || echo 1)
}

# Função para testar conectividade básica da API de loteria
test_lottery_connectivity() {
    log_step "Testando conectividade básica da API de loteria..."

    # Testar health check
    local health_url="https://$DOMAIN_BASE/rest/actuator/health"
    log_info "Testando health check: $health_url"

    local health_response=$(curl -s -w "%{http_code}" -o /tmp/health.txt "$health_url" --connect-timeout 10 2>/dev/null || echo "000")
    local health_content=$(cat /tmp/health.txt 2>/dev/null || echo "")

    if [[ "$health_response" == "200" ]]; then
        log_success "Health check OK"

        if echo "$health_content" | jq -r '.status // ""' 2>/dev/null | grep -q "UP\|DOWN"; then
            local status=$(echo "$health_content" | jq -r '.status' 2>/dev/null)
            log_info "Status da aplicação: $status"
        fi
    else
        log_error "Health check falhou: HTTP $health_response"
        log_info "Conteúdo: $(echo "$health_content" | head -c 200)"
    fi

    echo ""
}

# Função para testar endpoint de teste público
test_public_test_endpoint() {
    log_step "Testando endpoint de teste público..."

    local test_url="https://$DOMAIN_BASE/rest/v1/publico/teste"
    log_info "URL: $test_url"

    local test_response=$(curl -s -w "%{http_code}" -o /tmp/test.txt "$test_url" --connect-timeout 10 2>/dev/null || echo "000")
    local test_content=$(cat /tmp/test.txt 2>/dev/null || echo "")

    if [[ "$test_response" == "200" ]]; then
        log_success "Endpoint de teste público OK"
        log_info "Resposta: $test_content"
    else
        log_error "Endpoint de teste público falhou: HTTP $test_response"
        log_info "Conteúdo: $(echo "$test_content" | head -c 200)"
    fi

    echo ""
}

# Função para mostrar resumo específico de loteria
show_lottery_summary() {
    log_header "RESUMO DOS TESTES DE RESULTADOS DE LOTERIA"

    echo -e "${BLUE}🎯 Endpoint testado:${NC}"
    echo -e "  $ENDPOINT_PATH/{horario}"

    echo -e "\n${BLUE}📊 Resultados por combinação:${NC}"

    local total_tests=0
    local successful_tests=0

    # Testar todas as combinações para o resumo
    for domain in "$DOMAIN_BASE" "$DOMAIN_WWW"; do
        for protocol in "http" "https"; do
            for horario in "${HORARIOS_LOTERIA[@]}"; do
                ((total_tests++))
                local test_url="$protocol://$domain$ENDPOINT_PATH/$horario"
                local response=$(curl -s -w "%{http_code}" -o /dev/null "$test_url" --connect-timeout 5 2>/dev/null || echo "000")

                if [[ "$response" == "200" ]]; then
                    echo -e "  ${GREEN}✅ $protocol://$domain - $horario${NC}"
                    ((successful_tests++))
                else
                    echo -e "  ${RED}❌ $protocol://$domain - $horario (HTTP $response)${NC}"
                fi
            done
        done
    done

    echo -e "\n${BLUE}📈 Estatísticas de loteria:${NC}"
    echo -e "  Total de testes: ${CYAN}$total_tests${NC}"
    echo -e "  Sucessos: ${GREEN}$successful_tests${NC}"
    echo -e "  Falhas: ${RED}$((total_tests - successful_tests))${NC}"

    if [[ $successful_tests -eq $total_tests ]]; then
        echo -e "\n${GREEN}🎉 Todos os endpoints de loteria estão funcionando!${NC}"
    elif [[ $successful_tests -gt 0 ]]; then
        echo -e "\n${YELLOW}⚠️ Alguns endpoints de loteria têm problemas${NC}"
        echo -e "${BLUE}💡 Verificar: Configuração de segurança, MySQL, Traefik${NC}"
    else
        echo -e "\n${RED}❌ Todos os endpoints de loteria falharam${NC}"
        echo -e "${BLUE}💡 Problemas possíveis:${NC}"
        echo -e "  • Spring Security bloqueando endpoints públicos"
        echo -e "  • MySQL não conectado ou sem dados de loteria"
        echo -e "  • Traefik não roteando corretamente"
        echo -e "  • Context-path configurado incorretamente"
        echo -e "  • Horários de loteria não configurados"
    fi

    echo -e "\n${BLUE}🔗 URLs de loteria para testar manualmente:${NC}"
    for horario in "${HORARIOS_LOTERIA[@]}"; do
        echo -e "  ${CYAN}https://$DOMAIN_BASE$ENDPOINT_PATH/$horario${NC}"
    done
}

# Função principal
main() {
    log_header "TESTE ESPECÍFICO DE ENDPOINTS DE RESULTADOS DE LOTERIA"

    echo -e "${YELLOW}🎯 Testando endpoints de resultados de loteria${NC}"
    echo -e "${BLUE}ℹ️ Endpoint: $ENDPOINT_PATH/{horario}${NC}"
    echo -e "${BLUE}ℹ️ Horários: ${HORARIOS_LOTERIA[*]}${NC}"
    echo -e "${CYAN}📋 Foco: Validação de endpoints de resultados de loteria${NC}\n"

    # Verificar dependências
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl não encontrado - instale curl para executar os testes"
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq não encontrado - validação JSON será limitada"
    fi

    # Executar testes
    test_lottery_connectivity
    test_public_test_endpoint

    # Testar endpoint específico de loteria para cada combinação
    for domain in "$DOMAIN_BASE" "$DOMAIN_WWW"; do
        for protocol in "http" "https"; do
            for horario in "${HORARIOS_LOTERIA[@]}"; do
                test_lottery_endpoint "$domain" "$protocol" "$horario"
            done
        done
    done

    show_lottery_summary

    echo -e "\n${GREEN}🎯 Teste de loteria concluído!${NC}\n"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
