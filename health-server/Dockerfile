# =============================================================================
# 🏥 HEALTH SERVER - Lightweight Health Check Aggregator
# =============================================================================
FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    docker-cli \
    netcat-openbsd

# Create app directory
WORKDIR /app

# Copy health aggregator script
COPY scripts/health-aggregator.sh /app/health-aggregator.sh
RUN chmod +x /app/health-aggregator.sh

# Copy HTTP server script responsible for encaminhar as requisições
COPY health-server/server.sh /app/server.sh
RUN chmod +x /app/server.sh

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start server
CMD ["/app/server.sh"]
