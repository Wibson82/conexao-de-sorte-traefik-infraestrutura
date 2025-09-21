#!/bin/bash
# =============================================================================
# 🏥 Health Monitor HTTP Server
# =============================================================================
# Converte requisições HTTP simples em chamadas ao agregador de health checks.
# Aceita as rotas documentadas em traefik/dynamic/health-monitor.yml.
# =============================================================================

set -euo pipefail

PORT="${PORT:-8080}"

serve_once() {
  local request_line path status_line response_body exit_code

  # Ler primeira linha da requisição (método + path + versão)
  if ! IFS=$'\r' read -r request_line; then
    return 1
  fi

  # Conexões keep-alive podem enviar linhas em branco inicialmente
  if [[ -z "$request_line" ]]; then
    return 0
  fi

  # Extrair path; se ausente, usar overall
  path=$(printf '%s\n' "$request_line" | awk '{print $2}')
  if [[ -z "$path" || "$path" == "*" ]]; then
    path="/health/overall"
  fi

  # Consumir cabeçalhos até linha em branco
  while IFS=$'\r' read -r header_line; do
    header_line=${header_line%$'\r'}
    [[ -z "$header_line" ]] && break
  done

  # Executar agregador com REQUEST_URI definido
  if response_body=$(REQUEST_URI="$path" SUPPRESS_HEADERS=1 /app/health-aggregator.sh 2>&1); then
    status_line="HTTP/1.1 200 OK"
    exit_code=0
  else
    status_line="HTTP/1.1 503 Service Unavailable"
    exit_code=$?
    if [[ -z "$response_body" ]]; then
      response_body='{"status":"error","message":"empty response"}'
    fi
  fi

  # Garantir JSON válido; se saída não começar com {, encapsular mensagem
  if [[ ! "$response_body" =~ ^\{ ]]; then
    escaped=$(printf '%s' "$response_body" | jq -Rs '.')
    response_body=$(printf '{"status":"error","message":%s}' "$escaped")
    status_line="HTTP/1.1 503 Service Unavailable"
  fi

  printf '%s\r\n' "$status_line"
  printf 'Content-Type: application/json\r\n'
  printf 'Cache-Control: no-cache, no-store, must-revalidate\r\n'
  printf 'X-Health-Monitor: traefik-central\r\n'
  printf '\r\n'
  printf '%s\r\n' "$response_body"

  return "$exit_code"
}

while true; do
  # Usar subshell para isolar a comunicação com o netcat
  {
    if ! serve_once; then
      exit 0
    fi
  } | nc -l -p "$PORT" -q 1
  # Pequena pausa para evitar loop apertado caso conexões rápidas falhem
  sleep 0.1
done
