#!/bin/bash

# 🎯 TESTE ESPECÍFICO DO ENDPOINT CRÍTICO
# ✅ Testa especificamente: https://www.conexaodesorte.com.br/rest/v1/resultados/publico/ultimo/rio

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
ENDPOINT_URL="https://www.conexaodesorte.com.br/rest/v1/resultados/publico/ultimo/rio"
TIMEOUT=15

# Funções de log
log_header() { echo -e "\n${PURPLE}=== $1 ===${NC}"; }
log_step() { echo -e "${BLUE}🔧 $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Função principal de teste
test_endpoint() {
    log_header "TESTE ESPECÍFICO DO ENDPOINT CRÍTICO"
    
    echo -e "${YELLOW}🎯 Testando endpoint que deve funcionar:${NC}"
    echo -e "${BLUE}URL: $ENDPOINT_URL${NC}\n"
    
    # Teste detalhado
    log_step "Executando requisição..."
    
    # Capturar resposta completa
    local temp_file="/tmp/endpoint_response_$(date +%s).txt"
    local response=$(curl -s -w "%{http_code}|%{content_type}|%{time_total}|%{size_download}" \
                          -H "Accept: application/json" \
                          -H "User-Agent: ConexaoDeSorte-Test/1.0" \
                          -o "$temp_file" \
                          "$ENDPOINT_URL" \
                          --connect-timeout "$TIMEOUT" \
                          --max-time "$TIMEOUT" \
                          -k \
                          2>/dev/null || echo "000|||0")
    
    IFS='|' read -r http_code content_type time_total size_download <<< "$response"
    local content=$(cat "$temp_file" 2>/dev/null || echo "")
    
    # Análise da resposta
    log_info "HTTP Code: $http_code"
    log_info "Content-Type: $content_type"
    log_info "Tempo: ${time_total}s"
    log_info "Tamanho: ${size_download} bytes"
    
    echo ""
    
    case "$http_code" in
        "200")
            log_success "HTTP 200 - Endpoint funcionando!"
            
            # Verificar se é JSON
            if echo "$content" | jq . >/dev/null 2>&1; then
                log_success "Resposta é JSON válido"
                
                # Extrair dados específicos
                local horario=$(echo "$content" | jq -r '.horario // "N/A"' 2>/dev/null)
                local data=$(echo "$content" | jq -r '.data // "N/A"' 2>/dev/null)
                local numeros=$(echo "$content" | jq -r '.numeros // [] | length' 2>/dev/null)
                
                log_info "Dados retornados:"
                log_info "  Horário: $horario"
                log_info "  Data: $data"
                log_info "  Números: $numeros"
                
                if [[ "$numeros" != "0" && "$numeros" != "null" ]]; then
                    log_success "Endpoint retorna dados válidos!"
                    echo -e "\n${GREEN}🎉 SUCESSO: Endpoint funcionando perfeitamente!${NC}"
                    return 0
                else
                    log_warn "Endpoint funciona mas não há dados disponíveis"
                    echo -e "\n${YELLOW}⚠️ PARCIAL: Endpoint funciona mas sem dados${NC}"
                    return 1
                fi
            else
                log_error "Resposta não é JSON válido"
                log_info "Conteúdo (primeiros 200 chars): $(echo "$content" | head -c 200)..."
                
                if echo "$content" | grep -q -i "html\|<!DOCTYPE"; then
                    log_error "Resposta é HTML - possível página de erro"
                fi
                
                echo -e "\n${RED}❌ FALHA: Endpoint retorna conteúdo inválido${NC}"
                return 1
            fi
            ;;
            
        "404")
            log_error "HTTP 404 - Endpoint não encontrado"
            log_info "Possíveis causas:"
            log_info "  • Controller não mapeado corretamente"
            log_info "  • Context-path incorreto"
            log_info "  • Roteamento do Traefik com problema"
            
            if echo "$content" | grep -q "No static resource"; then
                log_error "Erro específico: Spring Boot tratando como recurso estático"
                log_info "Solução: Verificar context-path e mapeamento do controller"
            fi
            
            echo -e "\n${RED}❌ FALHA: Endpoint não encontrado${NC}"
            return 1
            ;;
            
        "401"|"403")
            log_error "HTTP $http_code - Problema de autenticação/autorização"
            log_info "Possíveis causas:"
            log_info "  • Spring Security bloqueando endpoint público"
            log_info "  • Configuração de segurança incorreta"
            log_info "  • Endpoint não está em .permitAll()"
            
            echo -e "\n${RED}❌ FALHA: Endpoint sendo bloqueado pela segurança${NC}"
            return 1
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
            
            echo -e "\n${RED}❌ FALHA: Erro interno do servidor${NC}"
            return 1
            ;;
            
        "000")
            log_error "Falha na conexão - Timeout ou DNS"
            log_info "Possíveis causas:"
            log_info "  • Servidor não está respondendo"
            log_info "  • Problema de DNS"
            log_info "  • Timeout de conexão"
            log_info "  • Certificado SSL inválido"
            
            echo -e "\n${RED}❌ FALHA: Não foi possível conectar${NC}"
            return 1
            ;;
            
        *)
            log_warn "HTTP $http_code - Status inesperado"
            log_info "Conteúdo: $(echo "$content" | head -c 200)..."
            
            echo -e "\n${YELLOW}⚠️ INESPERADO: Status HTTP não reconhecido${NC}"
            return 1
            ;;
    esac
    
    # Cleanup
    rm -f "$temp_file"
}

# Função para mostrar diagnóstico adicional
show_diagnostic() {
    log_header "DIAGNÓSTICO ADICIONAL"
    
    # Testar conectividade básica
    log_step "Testando conectividade básica..."
    if ping -c 1 www.conexaodesorte.com.br >/dev/null 2>&1; then
        log_success "DNS resolvendo corretamente"
    else
        log_error "Problema de DNS ou conectividade"
    fi
    
    # Testar HTTPS básico
    log_step "Testando HTTPS básico..."
    if curl -s -k --connect-timeout 5 https://www.conexaodesorte.com.br >/dev/null 2>&1; then
        log_success "HTTPS funcionando"
    else
        log_error "Problema com HTTPS"
    fi
    
    # Testar health check
    log_step "Testando health check..."
    local health_response=$(curl -s -w "%{http_code}" -o /dev/null https://www.conexaodesorte.com.br/rest/actuator/health --connect-timeout 5 -k 2>/dev/null || echo "000")
    if [[ "$health_response" == "200" ]]; then
        log_success "Health check OK"
    else
        log_warn "Health check retornou HTTP $health_response"
    fi
}

# Executar teste
main() {
    if test_endpoint; then
        echo -e "\n${GREEN}🎯 RESULTADO: ENDPOINT FUNCIONANDO!${NC}"
        exit 0
    else
        show_diagnostic
        echo -e "\n${RED}🎯 RESULTADO: ENDPOINT COM PROBLEMAS${NC}"
        echo -e "${BLUE}💡 Verificar logs do servidor e configuração de segurança${NC}"
        exit 1
    fi
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
