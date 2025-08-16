#!/bin/bash

# =============================================================================
# SCRIPT DE TESTES DE CARGA PARA PRODUÇÃO
# =============================================================================
# Executa testes de carga abrangentes no sistema de chat

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
BASE_URL="https://conexaodesorte.com.br"
API_BASE="$BASE_URL/api/v1"
WS_URL="wss://conexaodesorte.com.br/ws"

# Verificar dependências
check_dependencies() {
    echo -e "${BLUE}🔍 Verificando dependências...${NC}"
    
    command -v curl >/dev/null 2>&1 || { echo -e "${RED}❌ curl não encontrado${NC}"; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo -e "${RED}❌ jq não encontrado${NC}"; exit 1; }
    command -v ab >/dev/null 2>&1 || { echo -e "${RED}❌ Apache Bench (ab) não encontrado. Instale com: brew install httpie${NC}"; exit 1; }
    
    echo -e "${GREEN}✅ Dependências verificadas${NC}"
}

# Função para obter token JWT
get_jwt_token() {
    echo -e "${YELLOW}🔑 Obtendo token JWT...${NC}"
    
    local response=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "teste@conexaodesorte.com.br",
            "senha": "TesteLoad123!"
        }')
    
    local token=$(echo $response | jq -r '.dados.token // empty')
    
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo -e "${RED}❌ Erro ao obter token JWT${NC}"
        echo "Response: $response"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Token JWT obtido${NC}"
    echo $token
}

# Teste de carga básico - API REST
test_api_load() {
    local token=$1
    echo -e "${BLUE}🚀 Executando teste de carga - API REST${NC}"
    
    # Teste 1: Health Check (sem autenticação)
    echo -e "${YELLOW}📊 Teste 1: Health Check (1000 requests, 10 concurrent)${NC}"
    ab -n 1000 -c 10 -H "Accept: application/json" "$BASE_URL/actuator/health" > /tmp/health_test.txt
    
    local health_rps=$(grep "Requests per second" /tmp/health_test.txt | awk '{print $4}')
    echo -e "${GREEN}✅ Health Check: $health_rps requests/sec${NC}"
    
    # Teste 2: API Autenticada
    echo -e "${YELLOW}📊 Teste 2: API Autenticada (500 requests, 5 concurrent)${NC}"
    ab -n 500 -c 5 \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        "$API_BASE/usuarios/perfil" > /tmp/auth_test.txt
    
    local auth_rps=$(grep "Requests per second" /tmp/auth_test.txt | awk '{print $4}')
    echo -e "${GREEN}✅ API Autenticada: $auth_rps requests/sec${NC}"
    
    # Teste 3: Chat API (POST)
    echo -e "${YELLOW}📊 Teste 3: Chat API - Envio de Mensagens (200 requests, 3 concurrent)${NC}"
    
    # Criar arquivo temporário com dados da mensagem
    cat > /tmp/message_data.json << EOF
{
    "conteudo": "Mensagem de teste de carga",
    "remetenteId": 1,
    "nomeRemetente": "Teste Load",
    "conversaId": 123
}
EOF
    
    ab -n 200 -c 3 -p /tmp/message_data.json -T "application/json" \
        -H "Authorization: Bearer $token" \
        "$API_BASE/chat/mensagens" > /tmp/chat_test.txt
    
    local chat_rps=$(grep "Requests per second" /tmp/chat_test.txt | awk '{print $4}')
    echo -e "${GREEN}✅ Chat API: $chat_rps requests/sec${NC}"
    
    # Limpar arquivo temporário
    rm -f /tmp/message_data.json
}

# Teste de carga WebSocket
test_websocket_load() {
    local token=$1
    echo -e "${BLUE}🔌 Executando teste de carga - WebSocket${NC}"
    
    # Criar script Node.js para teste WebSocket
    cat > /tmp/websocket_test.js << 'EOF'
const WebSocket = require('ws');

const WS_URL = process.argv[2];
const TOKEN = process.argv[3];
const CONNECTIONS = parseInt(process.argv[4]) || 10;
const MESSAGES_PER_CONNECTION = parseInt(process.argv[5]) || 5;

let connectedCount = 0;
let messagesSent = 0;
let messagesReceived = 0;
let errors = 0;

console.log(`🔌 Iniciando teste WebSocket: ${CONNECTIONS} conexões, ${MESSAGES_PER_CONNECTION} mensagens cada`);

for (let i = 0; i < CONNECTIONS; i++) {
    setTimeout(() => {
        const ws = new WebSocket(WS_URL, {
            headers: {
                'Authorization': `Bearer ${TOKEN}`
            }
        });

        ws.on('open', () => {
            connectedCount++;
            console.log(`✅ Conexão ${i + 1} estabelecida (${connectedCount}/${CONNECTIONS})`);
            
            // Enviar mensagens de teste
            for (let j = 0; j < MESSAGES_PER_CONNECTION; j++) {
                setTimeout(() => {
                    const message = {
                        type: 'chat.message',
                        data: {
                            conversaId: '123',
                            conteudo: `Mensagem de teste ${j + 1} da conexão ${i + 1}`,
                            timestamp: new Date().toISOString()
                        }
                    };
                    
                    ws.send(JSON.stringify(message));
                    messagesSent++;
                }, j * 100);
            }
        });

        ws.on('message', (data) => {
            messagesReceived++;
        });

        ws.on('error', (error) => {
            errors++;
            console.error(`❌ Erro na conexão ${i + 1}:`, error.message);
        });

        ws.on('close', () => {
            console.log(`🔌 Conexão ${i + 1} fechada`);
        });

        // Fechar conexão após 10 segundos
        setTimeout(() => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.close();
            }
        }, 10000);

    }, i * 100); // Escalonar conexões
}

// Relatório final após 15 segundos
setTimeout(() => {
    console.log('\n📊 RELATÓRIO FINAL WebSocket:');
    console.log(`✅ Conexões estabelecidas: ${connectedCount}/${CONNECTIONS}`);
    console.log(`📤 Mensagens enviadas: ${messagesSent}`);
    console.log(`📥 Mensagens recebidas: ${messagesReceived}`);
    console.log(`❌ Erros: ${errors}`);
    console.log(`📈 Taxa de sucesso: ${((connectedCount / CONNECTIONS) * 100).toFixed(2)}%`);
    
    process.exit(0);
}, 15000);
EOF

    # Executar teste WebSocket se Node.js estiver disponível
    if command -v node >/dev/null 2>&1; then
        echo -e "${YELLOW}📊 Executando teste WebSocket (10 conexões, 5 mensagens cada)${NC}"
        node /tmp/websocket_test.js "$WS_URL" "$token" 10 5
    else
        echo -e "${YELLOW}⚠️ Node.js não encontrado, pulando teste WebSocket${NC}"
    fi
    
    # Limpar arquivo temporário
    rm -f /tmp/websocket_test.js
}

# Teste de stress - Rate Limiting
test_rate_limiting() {
    local token=$1
    echo -e "${BLUE}🛡️ Testando Rate Limiting${NC}"
    
    echo -e "${YELLOW}📊 Enviando 100 requests em 10 segundos para testar rate limiting...${NC}"
    
    local success_count=0
    local rate_limited_count=0
    
    for i in {1..100}; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Authorization: Bearer $token" \
            -H "Accept: application/json" \
            "$API_BASE/usuarios/perfil")
        
        if [ "$response" = "200" ]; then
            ((success_count++))
        elif [ "$response" = "429" ]; then
            ((rate_limited_count++))
        fi
        
        # Pequeno delay para não sobrecarregar
        sleep 0.1
    done
    
    echo -e "${GREEN}✅ Requests bem-sucedidos: $success_count${NC}"
    echo -e "${YELLOW}⚠️ Requests limitados (429): $rate_limited_count${NC}"
    
    if [ $rate_limited_count -gt 0 ]; then
        echo -e "${GREEN}✅ Rate limiting funcionando corretamente${NC}"
    else
        echo -e "${YELLOW}⚠️ Rate limiting pode não estar ativo${NC}"
    fi
}

# Teste de performance do banco de dados
test_database_performance() {
    local token=$1
    echo -e "${BLUE}🗄️ Testando Performance do Banco de Dados${NC}"
    
    echo -e "${YELLOW}📊 Teste de consultas simultâneas...${NC}"
    
    # Teste de consultas de leitura
    ab -n 200 -c 5 \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        "$API_BASE/chat/conversas/123/mensagens?limite=20" > /tmp/db_read_test.txt
    
    local db_read_rps=$(grep "Requests per second" /tmp/db_read_test.txt | awk '{print $4}')
    local db_read_time=$(grep "Time per request" /tmp/db_read_test.txt | head -1 | awk '{print $4}')
    
    echo -e "${GREEN}✅ Consultas de leitura: $db_read_rps requests/sec (${db_read_time}ms por request)${NC}"
}

# Relatório final
generate_report() {
    echo -e "\n${BLUE}📋 RELATÓRIO FINAL DE TESTES DE CARGA${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    echo -e "\n${GREEN}✅ TESTES CONCLUÍDOS:${NC}"
    echo "• Health Check API"
    echo "• API Autenticada"
    echo "• Chat API (POST)"
    echo "• WebSocket (se disponível)"
    echo "• Rate Limiting"
    echo "• Performance do Banco"
    
    echo -e "\n${YELLOW}📊 ARQUIVOS DE RESULTADO:${NC}"
    echo "• /tmp/health_test.txt - Teste Health Check"
    echo "• /tmp/auth_test.txt - Teste API Autenticada"
    echo "• /tmp/chat_test.txt - Teste Chat API"
    echo "• /tmp/db_read_test.txt - Teste Banco de Dados"
    
    echo -e "\n${GREEN}🎯 PRÓXIMOS PASSOS:${NC}"
    echo "1. Analisar os arquivos de resultado detalhados"
    echo "2. Verificar logs da aplicação durante os testes"
    echo "3. Monitorar métricas no Prometheus/Grafana"
    echo "4. Ajustar configurações se necessário"
    
    echo -e "\n${GREEN}✅ Testes de carga concluídos com sucesso!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}🚀 INICIANDO TESTES DE CARGA - CONEXÃO DE SORTE${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    check_dependencies
    
    local token=$(get_jwt_token)
    
    test_api_load "$token"
    test_websocket_load "$token"
    test_rate_limiting "$token"
    test_database_performance "$token"
    
    generate_report
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
