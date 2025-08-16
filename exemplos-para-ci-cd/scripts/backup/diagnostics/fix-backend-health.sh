#!/bin/bash

# Script para corrigir problemas de health check do backend
# Autor: Sistema de Deploy Automatizado
# Data: 29/07/2025

set -e

# Cores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Parâmetros
CONTAINER_NAME="${1:-backend-teste}"
MAX_ATTEMPTS="${2:-30}"
WAIT_SECONDS="${3:-10}"

log_header "CORREÇÃO DE HEALTH CHECK - $CONTAINER_NAME"

# 1. Verificar se container existe
log_info "1. Verificando container $CONTAINER_NAME..."
if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    log_success "Container $CONTAINER_NAME encontrado"
    
    # Verificar status
    STATUS=$(docker ps --format "{{.Names}}\t{{.Status}}" | grep "$CONTAINER_NAME" | cut -f2)
    log_info "Status atual: $STATUS"
else
    log_error "Container $CONTAINER_NAME não encontrado"
    exit 1
fi

# 2. Verificar logs para identificar problemas
log_info "2. Analisando logs do container..."
echo "Últimas 20 linhas dos logs:"
docker logs "$CONTAINER_NAME" --tail 20 2>/dev/null || log_warning "Não foi possível obter logs"

# Verificar erros específicos
log_info "Verificando erros específicos..."
if docker logs "$CONTAINER_NAME" 2>&1 | grep -i "tentativavalidacao.*ativo"; then
    log_error "PROBLEMA IDENTIFICADO: Erro na entidade TentativaValidacao - campo 'ativo' não existe no banco"
    
    log_info "🔧 SOLUÇÃO RECOMENDADA:"
    echo "1. Executar migração Flyway para adicionar coluna 'ativo'"
    echo "2. Reiniciar o container após migração"
    echo "3. Verificar se o banco tem a estrutura correta"
    
    # Verificar se Flyway está habilitado
    if docker exec "$CONTAINER_NAME" env | grep -q "FLYWAY_ENABLED=true"; then
        log_info "Flyway está habilitado - migração deve ser executada automaticamente"
    else
        log_warning "Flyway pode não estar habilitado - verificar configuração"
    fi
fi

if docker logs "$CONTAINER_NAME" 2>&1 | grep -i "azure.*key.*vault"; then
    log_warning "Avisos do Azure Key Vault detectados (normal em ambiente de teste)"
fi

if docker logs "$CONTAINER_NAME" 2>&1 | grep -i "connection.*refused\|timeout"; then
    log_error "PROBLEMA: Erro de conectividade com banco de dados"
    
    # Verificar conectividade com MySQL
    log_info "Verificando conectividade com MySQL..."
    if docker ps --format "{{.Names}}" | grep -q "mysql"; then
        MYSQL_CONTAINER=$(docker ps --format "{{.Names}}" | grep mysql | head -1)
        log_info "Container MySQL encontrado: $MYSQL_CONTAINER"
        
        # Testar conectividade
        if docker exec "$CONTAINER_NAME" nc -z conexao-mysql 3306 2>/dev/null; then
            log_success "Conectividade com MySQL OK"
        else
            log_error "Falha na conectividade com MySQL"
            
            # Verificar rede
            log_info "Verificando rede do container..."
            docker inspect "$CONTAINER_NAME" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{$value.IPAddress}}{{"\n"}}{{end}}'
        fi
    else
        log_error "Container MySQL não encontrado"
    fi
fi

# 3. Tentar corrigir problemas comuns
log_info "3. Tentando correções automáticas..."

# Reiniciar container se estiver unhealthy
if echo "$STATUS" | grep -q "unhealthy"; then
    log_info "Container está unhealthy - reiniciando..."
    docker restart "$CONTAINER_NAME"
    
    log_info "Aguardando reinicialização (30 segundos)..."
    sleep 30
    
    # Verificar novo status
    NEW_STATUS=$(docker ps --format "{{.Names}}\t{{.Status}}" | grep "$CONTAINER_NAME" | cut -f2)
    log_info "Novo status: $NEW_STATUS"
fi

# 4. Aguardar health check
log_info "4. Aguardando health check..."
for i in $(seq 1 $MAX_ATTEMPTS); do
    log_info "Tentativa $i/$MAX_ATTEMPTS - verificando health check..."
    
    # Verificar via actuator/health
    if curl -f -s "http://localhost:8081/actuator/health" >/dev/null 2>&1; then
        log_success "Health check passou na tentativa $i!"
        
        # Mostrar resposta do health check
        HEALTH_RESPONSE=$(curl -s "http://localhost:8081/actuator/health" 2>/dev/null)
        echo "Resposta do health check:"
        echo "$HEALTH_RESPONSE" | head -5
        break
    else
        if [ $i -eq $MAX_ATTEMPTS ]; then
            log_error "Health check falhou após $MAX_ATTEMPTS tentativas"
            
            # Logs finais para diagnóstico
            log_info "Logs finais do container:"
            docker logs "$CONTAINER_NAME" --tail 10
            
            return 1
        else
            log_info "Aguardando $WAIT_SECONDS segundos..."
            sleep $WAIT_SECONDS
        fi
    fi
done

# 5. Verificar endpoints específicos
log_info "5. Verificando endpoints específicos..."

# Testar endpoint de info
if curl -f -s "http://localhost:8081/actuator/info" >/dev/null 2>&1; then
    log_success "Endpoint /actuator/info OK"
else
    log_warning "Endpoint /actuator/info não responde"
fi

# Testar endpoint público
if curl -f -s "http://localhost:8081/v1/publico/status" >/dev/null 2>&1; then
    log_success "Endpoint público OK"
else
    log_warning "Endpoint público não responde (pode ser normal)"
fi

# 6. Verificar variáveis de ambiente críticas
log_info "6. Verificando configuração do container..."
echo "Variáveis críticas:"
docker exec "$CONTAINER_NAME" env | grep -E "(SPRING_PROFILES_ACTIVE|ENVIRONMENT|SPRING_DATASOURCE_URL|SERVER_PORT)" | sort

# 7. Resumo final
log_header "RESUMO DA CORREÇÃO"
echo ""
FINAL_STATUS=$(docker ps --format "{{.Names}}\t{{.Status}}" | grep "$CONTAINER_NAME" | cut -f2)
log_info "Status final do container: $FINAL_STATUS"

if curl -f -s "http://localhost:8081/actuator/health" >/dev/null 2>&1; then
    log_success "✅ Health check funcionando"
    echo "🌐 Container acessível em: http://localhost:8081"
    echo "🔍 Health check: http://localhost:8081/actuator/health"
else
    log_error "❌ Health check ainda falhando"
    echo "🔧 Ações recomendadas:"
    echo "  1. Verificar logs: docker logs $CONTAINER_NAME"
    echo "  2. Verificar banco de dados"
    echo "  3. Executar migração Flyway se necessário"
    echo "  4. Recriar container se problema persistir"
fi

log_success "Correção de health check concluída!"
