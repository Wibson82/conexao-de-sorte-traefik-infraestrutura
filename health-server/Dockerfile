# =============================================================================
# 📊 LOG SERVER - DOCKERFILE OPTIMIZADO
# =============================================================================
# Servidor Python para endpoint /rest/v1/log-servidor
# Base: Alpine Linux + Python + Docker CLI
# =============================================================================

FROM python:3.11-alpine

# Metadados
LABEL maintainer="conexao-de-sorte@sistema.com"
LABEL version="1.0.0"
LABEL description="Log Server para monitoramento completo dos containers"

# Dependências do sistema + Docker CLI
RUN apk add --no-cache \
    docker-cli \
    bash \
    bc \
    curl \
    jq \
    dcron \
    && rm -rf /var/cache/apk/*

# Criar usuário não-privilegiado
RUN addgroup -g 1000 logserver && \
    adduser -u 1000 -G logserver -s /bin/bash -D logserver

# Diretórios de trabalho
RUN mkdir -p /app/logs /app/scripts /app/health-server && \
    chown -R logserver:logserver /app

# Copiar scripts e servidor (contexto é a raiz do projeto)
COPY --chown=logserver:logserver scripts/server-monitor.sh /app/scripts/
COPY --chown=logserver:logserver scripts/cronjob-monitor.sh /app/scripts/
COPY --chown=logserver:logserver health-server/log-server.py /app/health-server/
COPY --chown=logserver:logserver health-server/entrypoint.sh /app/

# Dar permissões de execução
RUN chmod +x /app/scripts/server-monitor.sh /app/scripts/cronjob-monitor.sh /app/health-server/log-server.py /app/entrypoint.sh

# Mudar para usuário não-privilegiado
USER logserver

# Configurações
ENV PYTHONUNBUFFERED=1
ENV TZ=America/Sao_Paulo
ENV LOG_LEVEL=INFO

# Porta do servidor
EXPOSE 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD curl -f http://localhost:9090/health || exit 1

# Ponto de entrada
CMD ["/app/entrypoint.sh"]
