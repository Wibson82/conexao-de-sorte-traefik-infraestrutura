#!/bin/bash

# Script de Diagnóstico de Emergência
# Verifica o status completo da aplicação em produção

echo "🚨 DIAGNÓSTICO DE EMERGÊNCIA - $(date)"
echo "================================================"

# Função para verificar conectividade
check_connectivity() {
    local url=$1
    local name=$2
    echo "🔍 Testando $name: $url"
    
    if curl -f -s -o /dev/null --max-time 10 "$url"; then
        echo "✅ $name está respondendo"
    else
        echo "❌ $name NÃO está respondendo"
        # Tentar com mais detalhes
        echo "📋 Detalhes do erro:"
        curl -v --max-time 10 "$url" 2>&1 | head -20
    fi
    echo ""
}

# Verificar containers Docker
echo "🐳 STATUS DOS CONTAINERS:"
echo "========================"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo ""

# Verificar redes Docker
echo "🌐 REDES DOCKER:"
echo "==============="
docker network ls
echo ""

# Verificar se a rede traefik-network existe
if docker network inspect traefik-network >/dev/null 2>&1; then
    echo "✅ Rede traefik-network existe"
    docker network inspect traefik-network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
else
    echo "❌ Rede traefik-network NÃO existe"
fi
echo ""

# Verificar portas em uso
echo "🔌 PORTAS EM USO:"
echo "================"
netstat -tuln | grep -E ':(80|443|8080|3306)\s'
echo ""

# Verificar logs dos containers principais
echo "📋 LOGS DOS CONTAINERS:"
echo "======================"

for container in traefik backend-prod frontend-prod mysql-prod; do
    if docker ps -q -f name=$container | grep -q .; then
        echo "📄 Logs do $container (últimas 10 linhas):"
        docker logs $container --tail 10 2>&1
    else
        echo "⚠️ Container $container não está rodando"
    fi
    echo "---"
done

# Testes de conectividade
echo "🌍 TESTES DE CONECTIVIDADE:"
echo "==========================="

# Teste local
check_connectivity "http://localhost" "Localhost (porta 80)"
check_connectivity "http://localhost:8080" "Traefik Dashboard"
check_connectivity "http://localhost:8080/ping" "Traefik Health Check"

# Testes externos
check_connectivity "https://conexaodesorte.com.br" "Site Principal (HTTPS)"
check_connectivity "http://conexaodesorte.com.br" "Site Principal (HTTP)"
check_connectivity "https://www.conexaodesorte.com.br" "Site com WWW (HTTPS)"
check_connectivity "https://conexaodesorte.com.br/rest/v1/resultados/publico/ultimo/rio" "API REST"

# Verificar DNS
echo "🔍 VERIFICAÇÃO DNS:"
echo "=================="
nslookup conexaodesorte.com.br
echo ""

# Verificar certificados SSL
echo "🔒 VERIFICAÇÃO SSL:"
echo "=================="
echo | openssl s_client -connect conexaodesorte.com.br:443 -servername conexaodesorte.com.br 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "❌ Erro ao verificar certificado SSL"
echo ""

# Verificar espaço em disco
echo "💾 ESPAÇO EM DISCO:"
echo "=================="
df -h
echo ""

# Verificar uso de memória
echo "🧠 USO DE MEMÓRIA:"
echo "=================="
free -h
echo ""

# Sugestões de correção
echo "🔧 SUGESTÕES DE CORREÇÃO:"
echo "========================="
echo "1. Se Traefik não estiver rodando:"
echo "   docker start traefik"
echo ""
echo "2. Se containers estiverem com erro:"
echo "   docker restart backend-prod frontend-prod"
echo ""
echo "3. Se rede não existir:"
echo "   docker network create traefik-network"
echo ""
echo "4. Para recriar Traefik:"
echo "   docker stop traefik && docker rm traefik"
echo "   docker run -d --name traefik -p 80:80 -p 443:443 -p 8080:8080 --network traefik-network -v /var/run/docker.sock:/var/run/docker.sock -v /home/ubuntu/traefik:/etc/traefik --restart unless-stopped traefik:v3.0"
echo ""
echo "5. Para verificar logs em tempo real:"
echo "   docker logs -f traefik"
echo "   docker logs -f backend-prod"
echo ""
echo "🚨 DIAGNÓSTICO CONCLUÍDO - $(date)"