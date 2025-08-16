#!/bin/bash
# Analisador de falhas para workflows com exit code 127
# Uso: analisar-falha-127.sh [CAMINHO_DO_LOG]
# Procura em um arquivo de log a causa real da falha e exporta para o workflow

set -euo pipefail

LOG_FILE="${1:-logs/workflow.log}"

if [[ ! -f "$LOG_FILE" ]]; then
  MSG="Arquivo de log não encontrado: $LOG_FILE"
  echo "$MSG" >&2
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "cause=$MSG" >> "$GITHUB_OUTPUT"
  fi
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "### Causa da Falha" >> "$GITHUB_STEP_SUMMARY"
    echo "$MSG" >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 0
fi

# Busca mensagens comuns associadas ao exit code 127
CAUSE=$(grep -E "command not found|No such file or directory|error|Exception" "$LOG_FILE" | tail -n 1 || true)

if [[ -z "$CAUSE" ]]; then
  CAUSE="Causa da falha não identificada. Verifique o log completo."
fi

echo "$CAUSE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "cause=$CAUSE" >> "$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  echo "### Causa da Falha" >> "$GITHUB_STEP_SUMMARY"
  echo "$CAUSE" >> "$GITHUB_STEP_SUMMARY"
fi
