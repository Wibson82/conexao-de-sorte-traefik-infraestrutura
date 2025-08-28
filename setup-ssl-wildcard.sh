#!/bin/bash

# ===== SETUP SSL WILDCARD CERTIFICATE =====
# Configure Let's Encrypt wildcard certificate for all subdomains

set -e

echo "🔒 Setting up SSL Wildcard Certificate for Conexão de Sorte..."

# Configuration
DOMAIN="conexaodesorte.com.br"
EMAIL="facilitaservicos.dev@gmail.com"
CERT_DIR="/opt/conexao-microservices/letsencrypt"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# Install certbot if not present
echo "📦 Installing certbot..."
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot python3-certbot-dns-cloudflare
fi

# Create certificates directory
mkdir -p "$CERT_DIR"
chmod 700 "$CERT_DIR"

echo ""
echo "🔧 Choose SSL configuration method:"
echo "1) Cloudflare DNS Challenge (Recommended for wildcard)"
echo "2) HTTP Challenge (Single domain only)"
echo "3) Manual configuration"
echo ""
read -p "Select option [1-3]: " SSL_METHOD

case $SSL_METHOD in
    1)
        echo "🌐 Configuring Cloudflare DNS Challenge..."
        
        # Prompt for Cloudflare credentials
        echo ""
        echo "📝 Enter your Cloudflare credentials:"
        read -p "Email: " CF_EMAIL
        read -sp "API Key: " CF_API_KEY
        echo ""
        
        # Create Cloudflare credentials file
        cat > cloudflare.ini << EOF
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = $CF_EMAIL
dns_cloudflare_api_key = $CF_API_KEY
EOF
        chmod 600 cloudflare.ini
        
        echo "🔒 Generating wildcard certificate..."
        certbot certonly \
            --dns-cloudflare \
            --dns-cloudflare-credentials cloudflare.ini \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            -d "*.$DOMAIN" \
            -d "$DOMAIN" \
            --cert-name "$DOMAIN"
        
        # Clean up credentials file
        rm cloudflare.ini
        ;;
        
    2)
        echo "🌐 Configuring HTTP Challenge..."
        echo "⚠️  Note: HTTP challenge doesn't support wildcard certificates"
        echo "⚠️  Will create individual certificates for each subdomain"
        
        SUBDOMAINS=(
            "www.$DOMAIN"
            "api.$DOMAIN"
            "auth.$DOMAIN"
            "results.$DOMAIN"
            "chat.$DOMAIN"
            "notifications.$DOMAIN"
            "audit.$DOMAIN"
            "monitoring.$DOMAIN"
            "scheduler.$DOMAIN"
            "crypto.$DOMAIN"
            "traefik.$DOMAIN"
        )
        
        for subdomain in "${SUBDOMAINS[@]}"; do
            echo "🔒 Generating certificate for $subdomain..."
            certbot certonly \
                --standalone \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                -d "$subdomain" \
                --cert-name "$subdomain"
        done
        ;;
        
    3)
        echo "📝 Manual configuration selected"
        echo "Please follow these steps:"
        echo ""
        echo "1. Generate CSR:"
        echo "   openssl genrsa -out $DOMAIN.key 4096"
        echo "   openssl req -new -key $DOMAIN.key -out $DOMAIN.csr"
        echo ""
        echo "2. Submit CSR to your Certificate Authority"
        echo "3. Download certificate and place in $CERT_DIR"
        echo "4. Update Traefik configuration manually"
        exit 0
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "🔍 Verifying certificates..."

# Verify certificate exists
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ Certificate generated successfully"
    
    # Show certificate info
    echo "📋 Certificate information:"
    openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -text -noout | \
    grep -A1 "Subject:\|Subject Alternative Name:\|Not After"
    
    # Copy certificates to project directory
    echo "📂 Copying certificates to project directory..."
    cp -L "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_DIR/$DOMAIN.crt"
    cp -L "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$CERT_DIR/$DOMAIN.key"
    
    # Set proper permissions
    chmod 644 "$CERT_DIR/$DOMAIN.crt"
    chmod 600 "$CERT_DIR/$DOMAIN.key"
    
    echo "✅ Certificates copied to $CERT_DIR"
else
    echo "❌ Certificate generation failed"
    exit 1
fi

echo ""
echo "⚙️ Setting up automatic renewal..."

# Create renewal script
cat > /etc/cron.daily/certbot-renew << 'EOF'
#!/bin/bash
# Automatic certificate renewal

# Renew certificates
/usr/bin/certbot renew --quiet

# Restart Traefik if certificates renewed
if [ $? -eq 0 ]; then
    # Check if docker compose is running
    if docker compose -f /opt/conexao-microservices/docker-compose.yml ps | grep -q traefik; then
        echo "🔄 Restarting Traefik to reload certificates..."
        docker compose -f /opt/conexao-microservices/docker-compose.yml restart traefik
    fi
fi
EOF

chmod +x /etc/cron.daily/certbot-renew

echo "✅ Automatic renewal configured"

echo ""
echo "🔧 Updating Traefik configuration for SSL..."

# Create TLS configuration
cat > traefik/dynamic/tls.yml << EOF
# ===== TLS CONFIGURATION =====
# SSL certificates and security settings

tls:
  options:
    default:
      minVersion: "VersionTLS12"
      maxVersion: "VersionTLS13"
      sslStrategies:
        - "tls.SniStrict"
      cipherSuites:
        - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
        - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        - "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
      alpnProtocols:
        - "h2"
        - "http/1.1"

  certificates:
    # Wildcard certificate for all subdomains
    - certFile: "/letsencrypt/$DOMAIN.crt"
      keyFile: "/letsencrypt/$DOMAIN.key"
      stores:
        - default

# ===== HTTPS REDIRECT =====
http:
  middlewares:
    https-redirect:
      redirectScheme:
        scheme: "https"
        permanent: true

    security-headers-enhanced:
      headers:
        customResponseHeaders:
          X-Frame-Options: "DENY"
          X-Content-Type-Options: "nosniff"
          X-XSS-Protection: "1; mode=block"
          Strict-Transport-Security: "max-age=31536000; includeSubDomains; preload"
          Referrer-Policy: "strict-origin-when-cross-origin"
          Content-Security-Policy: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
          X-Robots-Tag: "noindex, nofollow"
          X-Powered-By: ""

    # HSTS Headers
    hsts-headers:
      headers:
        customResponseHeaders:
          Strict-Transport-Security: "max-age=63072000; includeSubDomains; preload"
EOF

echo "✅ Traefik TLS configuration updated"

# Update main Traefik configuration
cat > traefik/traefik.yml << EOF
global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: true
  debug: false

log:
  level: INFO
  format: json

accessLog:
  format: json

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: "websecure"
          scheme: "https"
          permanent: true
  websecure:
    address: ":443"
    http:
      middlewares:
        - security-headers-enhanced@file
        - hsts-headers@file
    http3:
      advertisedPort: 443

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "conexao-network"
  file:
    directory: "/etc/traefik/dynamic"
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: "$EMAIL"
      storage: "/letsencrypt/acme.json"
      keyType: EC256
      # Use DNS challenge for wildcard certificates
      dnsChallenge:
        provider: cloudflare
        delayBeforeCheck: 30
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"

# Metrics for monitoring
metrics:
  prometheus:
    addEntryPointsLabels: true
    addServicesLabels: true
    addRoutersLabels: true

# Tracing
tracing:
  jaeger:
    samplingType: const
    samplingParam: 1.0
    localAgentHostPort: "jaeger:6831"
EOF

echo "✅ Traefik main configuration updated"

echo ""
echo "🧪 Testing SSL configuration..."

# Test SSL certificate
echo "🔍 Testing certificate..."
if openssl x509 -in "$CERT_DIR/$DOMAIN.crt" -text -noout | grep -q "$DOMAIN"; then
    echo "✅ Certificate is valid for $DOMAIN"
else
    echo "❌ Certificate validation failed"
fi

# Check certificate expiry
expiry_date=$(openssl x509 -in "$CERT_DIR/$DOMAIN.crt" -enddate -noout | cut -d= -f2)
echo "📅 Certificate expires: $expiry_date"

# Calculate days until expiry
expiry_epoch=$(date -d "$expiry_date" +%s)
current_epoch=$(date +%s)
days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

if [ $days_until_expiry -gt 30 ]; then
    echo "✅ Certificate is valid for $days_until_expiry days"
elif [ $days_until_expiry -gt 7 ]; then
    echo "⚠️  Certificate expires in $days_until_expiry days"
else
    echo "🚨 Certificate expires in $days_until_expiry days - URGENT renewal needed!"
fi

echo ""
echo "🎉 SSL Wildcard setup completed successfully!"
echo ""
echo "📋 Summary:"
echo "  ✅ SSL certificate generated for *.$DOMAIN"
echo "  ✅ Traefik configuration updated"
echo "  ✅ Automatic renewal configured"
echo "  ✅ Security headers enabled"
echo "  ✅ HTTP to HTTPS redirect enabled"
echo ""
echo "🔧 Next steps:"
echo "  1. Update your Cloudflare API credentials in environment variables"
echo "  2. Restart Traefik: docker compose restart traefik"
echo "  3. Test HTTPS endpoints: https://auth.$DOMAIN/actuator/health"
echo "  4. Monitor certificate renewal: tail -f /var/log/letsencrypt/letsencrypt.log"
echo ""
echo "🌐 Your microservices will be available at:"
echo "  - https://auth.$DOMAIN (Authentication)"
echo "  - https://results.$DOMAIN (Results)"
echo "  - https://chat.$DOMAIN (Chat)"
echo "  - https://notifications.$DOMAIN (Notifications)"
echo "  - https://audit.$DOMAIN (Audit)"
echo "  - https://monitoring.$DOMAIN (Observability)"
echo "  - https://scheduler.$DOMAIN (Scheduler)"
echo "  - https://crypto.$DOMAIN (Cryptography)"