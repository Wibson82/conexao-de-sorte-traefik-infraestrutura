#!/bin/bash
# =============================================================================
# 🌐 SERVIDOR DE DIAGNÓSTICO - ENDPOINT SIMPLES
# =============================================================================
# Gera e serve o diagnóstico completo via HTTP
# Atualiza a cada 30 segundos automaticamente
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="/tmp/diagnostic"
OUTPUT_FILE="$OUTPUT_DIR/diagnostic.json"
HTML_FILE="$OUTPUT_DIR/diagnostic.html"

# Criar diretório se não existir
mkdir -p "$OUTPUT_DIR"

# Função para gerar diagnóstico
generate_diagnostic() {
    echo "🔍 $(date): Gerando diagnóstico completo..."

    # Executar diagnóstico completo
    DIAGNOSTIC_OUTPUT=$("$SCRIPT_DIR/diagnostic-complete.sh" 2>&1 || echo "Erro ao executar diagnóstico")

    # Gerar JSON estruturado
    cat > "$OUTPUT_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "domain": "conexaodesorte.com.br",
  "endpoint": "/rest/v1/log-servidor",
  "auth_required": false,
  "diagnostic_data": {
    "raw_output": $(echo "$DIAGNOSTIC_OUTPUT" | jq -Rs .),
    "format": "markdown",
    "generated_at": "$(date '+%Y-%m-%d %H:%M:%S')",
    "server_info": {
      "containers_running": $(docker ps -q | wc -l),
      "containers_total": $(docker ps -aq | wc -l),
      "docker_version": "$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'unknown')",
      "swarm_active": $(docker info 2>/dev/null | grep -q "Swarm: active" && echo true || echo false)
    }
  },
  "access_info": {
    "curl_command": "curl https://conexaodesorte.com.br/rest/v1/log-servidor",
    "postman_url": "https://conexaodesorte.com.br/rest/v1/log-servidor",
    "content_type": "application/json",
    "methods": ["GET"]
  }
}
EOF

    # Gerar versão HTML para visualização no navegador
    cat > "$HTML_FILE" <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Diagnóstico do Servidor - Conexão de Sorte</title>
    <style>
        body { font-family: monospace; margin: 20px; background: #1e1e1e; color: #d4d4d4; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #0e639c; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
        .content { background: #2d2d30; padding: 20px; border-radius: 5px; white-space: pre-wrap; }
        .timestamp { color: #569cd6; }
        .success { color: #4ec9b0; }
        .warning { color: #dcdcaa; }
        .error { color: #f44747; }
        .code { background: #1e1e1e; padding: 10px; border-radius: 3px; border-left: 3px solid #0e639c; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Diagnóstico Completo do Servidor</h1>
            <p class="timestamp">Gerado em: $(date)</p>
            <p>Endpoint: <strong>/rest/v1/log-servidor</strong> | Público (sem autenticação)</p>
        </div>
        <div class="content">$DIAGNOSTIC_OUTPUT</div>
    </div>
</body>
</html>
EOF

    echo "✅ Diagnóstico gerado: $OUTPUT_FILE"
    echo "📄 HTML gerado: $HTML_FILE"
}

# Função principal do servidor
if [[ "$1" == "generate" ]]; then
    # Gerar diagnóstico uma vez
    generate_diagnostic
elif [[ "$1" == "serve" ]]; then
    # Loop de atualização contínua
    echo "🌐 Iniciando servidor de diagnóstico..."
    echo "📊 Atualizando a cada 30 segundos..."

    while true; do
        generate_diagnostic
        sleep 30
    done
else
    echo "Uso: $0 {generate|serve}"
    echo "  generate - Gerar diagnóstico uma vez"
    echo "  serve    - Executar em loop (a cada 30s)"
    exit 1
fi