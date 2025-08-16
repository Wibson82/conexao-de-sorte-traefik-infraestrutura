#!/usr/bin/env bash
# Script para CI local: verifica presença do Java 24 e executa mvn clean package
# Uso: chmod +x scripts/ci_check_java24_and_build.sh && ./scripts/ci_check_java24_and_build.sh
#
# Melhorias:
# - ENFORCE_JAVA_VERSION=true fará o script falhar se a versão major do Java não for REQUIRED_MAJOR.
# - ALLOW_OTHER_JAVA_VERSIONS=true permite prosseguir sem erro mesmo se major != REQUIRED_MAJOR.
#
# Em CI usar: export CI_STRICT_SECRETS=true; export ENFORCE_JAVA_VERSION=true

set -euo pipefail

REQUIRED_MAJOR=24
CI_STRICT_SECRETS="${CI_STRICT_SECRETS:-false}"
ENFORCE_JAVA_VERSION="${ENFORCE_JAVA_VERSION:-false}"
ALLOW_OTHER_JAVA_VERSIONS="${ALLOW_OTHER_JAVA_VERSIONS:-false}"

echo "=== Verificando java -version ==="
if command -v java >/dev/null 2>&1; then
  java -version 2>&1 || true
else
  echo "ERRO: 'java' não encontrado no PATH."
  echo "Verifique JAVA_HOME e PATH. Saindo."
  exit 2
fi

echo "=== Verificando javac -version ==="
if command -v javac >/dev/null 2>&1; then
  javac -version 2>&1 || true
else
  echo "WARN: 'javac' não encontrado no PATH. Se estiver usando JRE em vez de JDK, é necessário apontar para JDK ${REQUIRED_MAJOR}."
fi

# Tentar detectar a versão major do Java de maneira robusta
JAVA_FEATURE=""
JAVA_PROP=""
if command -v java >/dev/null 2>&1; then
  # Método robusto: usar 'java -XshowSettings:properties -version' se disponível
  JAVA_FULL=$(java -XshowSettings:properties -version 2>&1 | grep "java.version = " || true)
  if [ -n "$JAVA_FULL" ]; then
    JAVA_PROP=$(echo "$JAVA_FULL" | awk -F'= ' '{print $2}')
  else
    JAVA_PROP=$(java -version 2>&1 | head -n 1 | sed -E 's/.*"(.*)".*/\1/')
  fi

  # Extrair feature (major) da versão (suporta 24, 17, 11, etc)
  if [[ "$JAVA_PROP" =~ ^([0-9]+)\. ]]; then
    JAVA_FEATURE="${BASH_REMATCH[1]}"
  else
    # Versões sem ponto (ex: 24)
    JAVA_FEATURE=$(echo "$JAVA_PROP" | sed -E 's/^([0-9]+).*/\1/')
  fi
fi

echo "Detected java.version = ${JAVA_PROP:-unknown} -> major = ${JAVA_FEATURE:-unknown}"

if [ "${JAVA_FEATURE}" != "${REQUIRED_MAJOR}" ]; then
  echo "WARNING: A versão major do Java não é ${REQUIRED_MAJOR}. Recomendado usar JDK ${REQUIRED_MAJOR}."
  if [ "${ENFORCE_JAVA_VERSION}" = "true" ] && [ "${ALLOW_OTHER_JAVA_VERSIONS}" != "true" ]; then
    echo "ENFORCE_JAVA_VERSION está ativado. Abortando build por diferença de versão do Java."
    exit 5
  else
    echo "Continuando apesar da diferença de versão. Para forçar falha, export ENFORCE_JAVA_VERSION=true."
  fi
else
  echo "Versão do Java compatível: ${JAVA_FEATURE}"
fi

echo "=== Executando mvn -U clean package -DskipTests ==="
if command -v mvn >/dev/null 2>&1; then
  mvn -U clean package -DskipTests
else
  echo "ERRO: 'mvn' não encontrado no PATH. Instale Maven para executar o build."
  exit 3
fi

echo "=== Build finalizado. Verifique saída acima para erros/warnings. ==="
