# Dockerfile para Traefik com multi-stage build e labels OCI
# Stage 1: Preparação de configurações
FROM alpine:3.19 as config

WORKDIR /config

# Copiar arquivos de configuração
COPY traefik/traefik.yml /config/traefik.yml
COPY traefik/dynamic/ /config/dynamic/

# Validar configurações
RUN apk add --no-cache curl && \
    echo "Validando configurações..." && \
    if [ -f "/config/traefik.yml" ]; then echo "✅ traefik.yml encontrado"; else echo "❌ traefik.yml não encontrado" && exit 1; fi && \
    if [ -f "/config/dynamic/middlewares.yml" ]; then echo "✅ middlewares.yml encontrado"; else echo "❌ middlewares.yml não encontrado" && exit 1; fi

# Stage 2: Imagem final
FROM traefik:v3.1

# Argumentos de build para labels OCI
ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF
ARG VCS_URL

# Labels OCI (Open Container Initiative)
LABEL org.opencontainers.image.created=${BUILD_DATE} \
      org.opencontainers.image.title="Traefik Gateway" \
      org.opencontainers.image.description="Traefik Gateway para Conexão de Sorte" \
      org.opencontainers.image.version=${BUILD_VERSION} \
      org.opencontainers.image.revision=${VCS_REF} \
      org.opencontainers.image.source=${VCS_URL} \
      org.opencontainers.image.vendor="Conexão de Sorte" \
      org.opencontainers.image.authors="Equipe DevOps Conexão de Sorte" \
      org.opencontainers.image.licenses="Proprietary"

# Copiar configurações validadas
COPY --from=config /config/traefik.yml /traefik.yml
COPY --from=config /config/dynamic/ /etc/traefik/dynamic/

# Criar diretórios necessários
RUN mkdir -p /letsencrypt /secrets

# Definir usuário não-root
USER 1000:1000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD traefik healthcheck --ping || exit 1

# Comando padrão
CMD ["traefik"]