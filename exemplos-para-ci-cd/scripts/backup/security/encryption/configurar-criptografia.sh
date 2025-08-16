#!/bin/bash

# ============================================================================
# SCRIPT DE CONFIGURAÇÃO DE CRIPTOGRAFIA
# ============================================================================
# Configura criptografia de dados em repouso e em trânsito
# Implementa práticas de segurança para compliance LGPD
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configurações
CRYPTO_DIR="${CRYPTO_DIR:-/app/crypto}"
KEYS_DIR="$CRYPTO_DIR/keys"
CERTS_DIR="$CRYPTO_DIR/certs"
SECRETS_DIR="${SECRETS_DIR:-/run/secrets}"
BACKUP_DIR="${BACKUP_DIR:-/backup/crypto}"
KEY_SIZE="${KEY_SIZE:-2048}"
CERT_VALIDITY_DAYS="${CERT_VALIDITY_DAYS:-365}"
ORGANIZATION="${ORGANIZATION:-Conexao de Sorte}"
COUNTRY="${COUNTRY:-BR}"

# Função de ajuda
show_help() {
    echo "
╔══════════════════════════════════════════════════════════════════╗
║                  CONFIGURAÇÃO DE CRIPTOGRAFIA                   ║
╚══════════════════════════════════════════════════════════════════╝

Uso: $0 [COMANDO] [OPÇÕES]

COMANDOS DISPONÍVEIS:
  setup-crypto        - Configuração inicial de criptografia
  generate-keys       - Gerar chaves de criptografia
  generate-certs      - Gerar certificados SSL/TLS
  setup-database      - Configurar criptografia do banco
  setup-application   - Configurar criptografia da aplicação
  rotate-keys         - Rotacionar chaves de criptografia
  validate-crypto     - Validar configuração de criptografia
  backup-keys         - Backup de chaves e certificados
  test-encryption     - Testar criptografia
  help                - Mostrar esta ajuda

EXEMPLOS:
  $0 setup-crypto                # Configuração completa
  $0 generate-keys               # Gerar apenas chaves
  $0 validate-crypto             # Validar configuração
  $0 test-encryption             # Testar criptografia
"
}

# Criar estrutura de diretórios
setup_directories() {
    log_info "📁 Criando estrutura de diretórios..."
    
    mkdir -p "$CRYPTO_DIR" "$KEYS_DIR" "$CERTS_DIR" "$BACKUP_DIR"
    
    # Definir permissões restritivas
    chmod 700 "$CRYPTO_DIR" "$KEYS_DIR" "$CERTS_DIR" "$BACKUP_DIR"
    
    log_success "📁 Estrutura de diretórios criada"
}

# Gerar chaves de criptografia
generate_keys() {
    log_info "🔐 Gerando chaves de criptografia..."
    
    setup_directories
    
    # Chave mestra para criptografia de dados
    local master_key_file="$KEYS_DIR/master.key"
    if [[ ! -f "$master_key_file" ]]; then
        openssl rand -hex 32 > "$master_key_file"
        chmod 600 "$master_key_file"
        log_success "Chave mestra gerada: $master_key_file"
    else
        log_info "Chave mestra já existe: $master_key_file"
    fi
    
    # Chave para criptografia de dados pessoais (LGPD)
    local personal_data_key_file="$KEYS_DIR/personal_data.key"
    if [[ ! -f "$personal_data_key_file" ]]; then
        openssl rand -hex 32 > "$personal_data_key_file"
        chmod 600 "$personal_data_key_file"
        log_success "Chave de dados pessoais gerada: $personal_data_key_file"
    else
        log_info "Chave de dados pessoais já existe: $personal_data_key_file"
    fi
    
    # Chave para tokens JWT
    local jwt_key_file="$KEYS_DIR/jwt.key"
    if [[ ! -f "$jwt_key_file" ]]; then
        openssl rand -base64 64 > "$jwt_key_file"
        chmod 600 "$jwt_key_file"
        log_success "Chave JWT gerada: $jwt_key_file"
    else
        log_info "Chave JWT já existe: $jwt_key_file"
    fi
    
    # Par de chaves RSA para assinatura digital
    local rsa_private_key="$KEYS_DIR/rsa_private.pem"
    local rsa_public_key="$KEYS_DIR/rsa_public.pem"
    
    if [[ ! -f "$rsa_private_key" ]]; then
        openssl genrsa -out "$rsa_private_key" "$KEY_SIZE"
        openssl rsa -in "$rsa_private_key" -pubout -out "$rsa_public_key"
        chmod 600 "$rsa_private_key"
        chmod 644 "$rsa_public_key"
        log_success "Par de chaves RSA gerado: $rsa_private_key, $rsa_public_key"
    else
        log_info "Par de chaves RSA já existe"
    fi
    
    # Chave para criptografia de backup
    local backup_key_file="$KEYS_DIR/backup.key"
    if [[ ! -f "$backup_key_file" ]]; then
        openssl rand -hex 32 > "$backup_key_file"
        chmod 600 "$backup_key_file"
        log_success "Chave de backup gerada: $backup_key_file"
    else
        log_info "Chave de backup já existe: $backup_key_file"
    fi
    
    log_success "🔐 Geração de chaves concluída"
}

# Gerar certificados SSL/TLS
generate_certificates() {
    log_info "📜 Gerando certificados SSL/TLS..."
    
    setup_directories
    
    # Certificado auto-assinado para desenvolvimento
    local cert_file="$CERTS_DIR/server.crt"
    local key_file="$CERTS_DIR/server.key"
    local csr_file="$CERTS_DIR/server.csr"
    
    if [[ ! -f "$cert_file" ]]; then
        # Gerar chave privada
        openssl genrsa -out "$key_file" "$KEY_SIZE"
        chmod 600 "$key_file"
        
        # Criar arquivo de configuração para o certificado
        local config_file="$CERTS_DIR/server.conf"
        cat > "$config_file" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY
ST = State
L = City
O = $ORGANIZATION
OU = IT Department
CN = localhost

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF
        
        # Gerar CSR
        openssl req -new -key "$key_file" -out "$csr_file" -config "$config_file"
        
        # Gerar certificado auto-assinado
        openssl x509 -req -in "$csr_file" -signkey "$key_file" -out "$cert_file" \
            -days "$CERT_VALIDITY_DAYS" -extensions v3_req -extfile "$config_file"
        
        chmod 644 "$cert_file"
        
        log_success "Certificado SSL gerado: $cert_file"
        log_success "Chave privada SSL gerada: $key_file"
    else
        log_info "Certificado SSL já existe: $cert_file"
    fi
    
    # Certificado para assinatura de dados (LGPD)
    local data_cert_file="$CERTS_DIR/data_signing.crt"
    local data_key_file="$CERTS_DIR/data_signing.key"
    
    if [[ ! -f "$data_cert_file" ]]; then
        # Gerar chave privada para assinatura de dados
        openssl genrsa -out "$data_key_file" "$KEY_SIZE"
        chmod 600 "$data_key_file"
        
        # Gerar certificado para assinatura de dados
        openssl req -new -x509 -key "$data_key_file" -out "$data_cert_file" \
            -days "$CERT_VALIDITY_DAYS" -subj "/C=$COUNTRY/O=$ORGANIZATION/CN=Data Signing"
        
        chmod 644 "$data_cert_file"
        
        log_success "Certificado de assinatura de dados gerado: $data_cert_file"
    else
        log_info "Certificado de assinatura de dados já existe: $data_cert_file"
    fi
    
    log_success "📜 Geração de certificados concluída"
}

# Configurar criptografia do banco de dados
setup_database_encryption() {
    log_info "🗄️ Configurando criptografia do banco de dados..."
    
    # Verificar se as chaves existem
    local master_key_file="$KEYS_DIR/master.key"
    if [[ ! -f "$master_key_file" ]]; then
        log_error "Chave mestra não encontrada. Execute 'generate-keys' primeiro."
        return 1
    fi
    
    # Criar configuração de criptografia para MySQL
    local mysql_crypto_config="$CRYPTO_DIR/mysql-crypto.cnf"
    cat > "$mysql_crypto_config" << EOF
# Configuração de criptografia MySQL
[mysqld]
# Criptografia em repouso
innodb_encrypt_tables = ON
innodb_encrypt_log = ON
innodb_encrypt_temporary_tables = ON

# Configurações de SSL
ssl-ca = $CERTS_DIR/server.crt
ssl-cert = $CERTS_DIR/server.crt
ssl-key = $CERTS_DIR/server.key

# Configurações de segurança
local_infile = OFF
secure_file_priv = /var/lib/mysql-files/
EOF
    
    chmod 644 "$mysql_crypto_config"
    
    # Criar script de inicialização de criptografia
    local init_script="$CRYPTO_DIR/init-db-encryption.sql"
    cat > "$init_script" << EOF
-- Script de inicialização de criptografia do banco

-- Criar função para criptografia de dados pessoais
DELIMITER //
CREATE FUNCTION IF NOT EXISTS encrypt_personal_data(data TEXT)
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN AES_ENCRYPT(data, UNHEX(SHA2('$(cat "$master_key_file")', 256)));
END//

-- Criar função para descriptografia de dados pessoais
CREATE FUNCTION IF NOT EXISTS decrypt_personal_data(encrypted_data TEXT)
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN AES_DECRYPT(encrypted_data, UNHEX(SHA2('$(cat "$master_key_file")', 256)));
END//
DELIMITER ;

-- Criar tabela de auditoria de criptografia
CREATE TABLE IF NOT EXISTS crypto_audit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL,
    operation VARCHAR(50) NOT NULL,
    encrypted_fields JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT,
    ip_address VARCHAR(45)
) ENGINE=InnoDB;

-- Criar índices para performance
CREATE INDEX idx_crypto_audit_timestamp ON crypto_audit(timestamp);
CREATE INDEX idx_crypto_audit_table ON crypto_audit(table_name);
EOF
    
    chmod 600 "$init_script"
    
    log_success "🗄️ Configuração de criptografia do banco criada"
    log_info "Arquivo de configuração: $mysql_crypto_config"
    log_info "Script de inicialização: $init_script"
}

# Configurar criptografia da aplicação
setup_application_encryption() {
    log_info "⚙️ Configurando criptografia da aplicação..."
    
    # Verificar se as chaves existem
    local personal_data_key="$KEYS_DIR/personal_data.key"
    local jwt_key="$KEYS_DIR/jwt.key"
    
    if [[ ! -f "$personal_data_key" ]] || [[ ! -f "$jwt_key" ]]; then
        log_error "Chaves não encontradas. Execute 'generate-keys' primeiro."
        return 1
    fi
    
    # Criar arquivo de configuração de criptografia para a aplicação
    local app_crypto_config="$CRYPTO_DIR/application-crypto.yml"
    cat > "$app_crypto_config" << EOF
# Configuração de criptografia da aplicação
crypto:
  # Configurações de criptografia de dados pessoais
  personal-data:
    algorithm: AES-256-GCM
    key-file: $personal_data_key
    key-rotation-days: 90
    
  # Configurações JWT
  jwt:
    algorithm: HS256
    key-file: $jwt_key
    expiration: 3600 # 1 hora
    refresh-expiration: 86400 # 24 horas
    
  # Configurações de hash de senhas
  password:
    algorithm: bcrypt
    rounds: 12
    
  # Configurações de assinatura digital
  digital-signature:
    algorithm: RSA-SHA256
    private-key-file: $KEYS_DIR/rsa_private.pem
    public-key-file: $KEYS_DIR/rsa_public.pem
    
  # Configurações de backup
  backup:
    encryption: true
    algorithm: AES-256-CBC
    key-file: $KEYS_DIR/backup.key
    
  # Configurações de auditoria
  audit:
    encrypt-logs: true
    sign-logs: true
    retention-days: 2555 # 7 anos (LGPD)
EOF
    
    chmod 600 "$app_crypto_config"
    
    # Criar classe Java de configuração de criptografia
    local java_crypto_config="$CRYPTO_DIR/CryptographyConfig.java"
    cat > "$java_crypto_config" << EOF
package br.tec.facilitaservicos.conexaodesorte.configuracao;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Configuração de criptografia para compliance LGPD
 */
@Configuration
public class CryptographyConfig {
    
    @Value("\${crypto.personal-data.key-file}")
    private String personalDataKeyFile;
    
    @Value("\${crypto.jwt.key-file}")
    private String jwtKeyFile;
    
    @Value("\${crypto.password.rounds:12}")
    private int bcryptRounds;
    
    /**
     * Encoder de senhas com BCrypt
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(bcryptRounds);
    }
    
    /**
     * Chave para criptografia de dados pessoais
     */
    @Bean
    public SecretKey personalDataKey() throws Exception {
        byte[] keyBytes = Files.readAllBytes(Paths.get(personalDataKeyFile));
        String keyHex = new String(keyBytes).trim();
        byte[] decodedKey = hexStringToByteArray(keyHex);
        return new SecretKeySpec(decodedKey, "AES");
    }
    
    /**
     * Chave JWT
     */
    @Bean
    public String jwtSecret() throws Exception {
        return new String(Files.readAllBytes(Paths.get(jwtKeyFile))).trim();
    }
    
    /**
     * Gerador de números aleatórios seguro
     */
    @Bean
    public SecureRandom secureRandom() {
        return new SecureRandom();
    }
    
    /**
     * Utilitário para conversão de hex para bytes
     */
    private byte[] hexStringToByteArray(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                                 + Character.digit(s.charAt(i+1), 16));
        }
        return data;
    }
}
EOF
    
    chmod 644 "$java_crypto_config"
    
    log_success "⚙️ Configuração de criptografia da aplicação criada"
    log_info "Arquivo de configuração: $app_crypto_config"
    log_info "Classe Java: $java_crypto_config"
}

# Rotacionar chaves de criptografia
rotate_keys() {
    log_info "🔄 Iniciando rotação de chaves..."
    
    # Backup das chaves atuais
    backup_keys
    
    # Rotacionar chave mestra
    local master_key_file="$KEYS_DIR/master.key"
    if [[ -f "$master_key_file" ]]; then
        mv "$master_key_file" "$master_key_file.old"
        openssl rand -hex 32 > "$master_key_file"
        chmod 600 "$master_key_file"
        log_success "Chave mestra rotacionada"
    fi
    
    # Rotacionar chave de dados pessoais
    local personal_data_key_file="$KEYS_DIR/personal_data.key"
    if [[ -f "$personal_data_key_file" ]]; then
        mv "$personal_data_key_file" "$personal_data_key_file.old"
        openssl rand -hex 32 > "$personal_data_key_file"
        chmod 600 "$personal_data_key_file"
        log_success "Chave de dados pessoais rotacionada"
    fi
    
    # Rotacionar chave JWT
    local jwt_key_file="$KEYS_DIR/jwt.key"
    if [[ -f "$jwt_key_file" ]]; then
        mv "$jwt_key_file" "$jwt_key_file.old"
        openssl rand -base64 64 > "$jwt_key_file"
        chmod 600 "$jwt_key_file"
        log_success "Chave JWT rotacionada"
    fi
    
    log_success "🔄 Rotação de chaves concluída"
    log_warning "⚠️ ATENÇÃO: Reinicie a aplicação para aplicar as novas chaves"
    log_warning "⚠️ ATENÇÃO: Re-criptografe os dados com as novas chaves"
}

# Validar configuração de criptografia
validate_crypto() {
    log_info "🔍 Validando configuração de criptografia..."
    
    local errors=0
    
    # Verificar estrutura de diretórios
    for dir in "$CRYPTO_DIR" "$KEYS_DIR" "$CERTS_DIR"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Diretório não encontrado: $dir"
            ((errors++))
        else
            local permissions=$(stat -c "%a" "$dir" 2>/dev/null || stat -f "%A" "$dir" 2>/dev/null)
            if [[ "$permissions" != "700" ]]; then
                log_warning "Permissões inseguras em $dir: $permissions"
            fi
        fi
    done
    
    # Verificar chaves obrigatórias
    local required_keys=(
        "$KEYS_DIR/master.key"
        "$KEYS_DIR/personal_data.key"
        "$KEYS_DIR/jwt.key"
        "$KEYS_DIR/rsa_private.pem"
        "$KEYS_DIR/rsa_public.pem"
    )
    
    for key_file in "${required_keys[@]}"; do
        if [[ ! -f "$key_file" ]]; then
            log_error "Chave não encontrada: $key_file"
            ((errors++))
        else
            local permissions=$(stat -c "%a" "$key_file" 2>/dev/null || stat -f "%A" "$key_file" 2>/dev/null)
            if [[ "$permissions" != "600" ]] && [[ "$permissions" != "644" ]]; then
                log_warning "Permissões inseguras em $key_file: $permissions"
            fi
            
            # Verificar tamanho da chave
            local size=$(wc -c < "$key_file")
            if [[ $size -lt 32 ]]; then
                log_warning "Chave muito pequena: $key_file ($size bytes)"
            fi
        fi
    done
    
    # Verificar certificados
    local cert_file="$CERTS_DIR/server.crt"
    if [[ -f "$cert_file" ]]; then
        # Verificar validade do certificado
        local expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
        if [[ -n "$expiry" ]]; then
            local expiry_timestamp=$(date -d "$expiry" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
            
            if [[ $days_until_expiry -lt 30 ]]; then
                log_warning "Certificado expira em $days_until_expiry dias"
            fi
        fi
    else
        log_error "Certificado SSL não encontrado: $cert_file"
        ((errors++))
    fi
    
    # Testar criptografia
    if test_encryption_internal; then
        log_success "Teste de criptografia passou"
    else
        log_error "Teste de criptografia falhou"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "🔍 Configuração de criptografia válida"
    else
        log_error "🔍 Encontrados $errors problemas na configuração"
        return 1
    fi
}

# Backup de chaves e certificados
backup_keys() {
    log_info "💾 Fazendo backup de chaves e certificados..."
    
    local backup_file="$BACKUP_DIR/crypto-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if tar -czf "$backup_file" -C "$CRYPTO_DIR" keys/ certs/ 2>/dev/null; then
        chmod 600 "$backup_file"
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "💾 Backup criado: $backup_file ($size)"
    else
        log_error "Falha ao criar backup de criptografia"
        return 1
    fi
}

# Teste interno de criptografia
test_encryption_internal() {
    local test_data="Dados de teste para LGPD - $(date)"
    local master_key_file="$KEYS_DIR/master.key"
    
    if [[ ! -f "$master_key_file" ]]; then
        return 1
    fi
    
    local key=$(cat "$master_key_file")
    
    # Teste de criptografia simples
    local encrypted=$(echo "$test_data" | openssl enc -aes-256-cbc -a -salt -k "$key" 2>/dev/null)
    local decrypted=$(echo "$encrypted" | openssl enc -aes-256-cbc -d -a -k "$key" 2>/dev/null)
    
    if [[ "$test_data" == "$decrypted" ]]; then
        return 0
    else
        return 1
    fi
}

# Testar criptografia
test_encryption() {
    log_info "🧪 Testando criptografia..."
    
    local test_data="Dados pessoais de teste - CPF: 123.456.789-00 - $(date)"
    
    # Testar com chave mestra
    local master_key_file="$KEYS_DIR/master.key"
    if [[ -f "$master_key_file" ]]; then
        local key=$(cat "$master_key_file")
        
        log_info "Testando criptografia AES-256-CBC..."
        local encrypted=$(echo "$test_data" | openssl enc -aes-256-cbc -a -salt -k "$key")
        local decrypted=$(echo "$encrypted" | openssl enc -aes-256-cbc -d -a -k "$key")
        
        if [[ "$test_data" == "$decrypted" ]]; then
            log_success "✅ Teste AES-256-CBC: PASSOU"
        else
            log_error "❌ Teste AES-256-CBC: FALHOU"
        fi
        
        echo "Dados originais: $test_data"
        echo "Dados criptografados: $encrypted"
        echo "Dados descriptografados: $decrypted"
    else
        log_error "Chave mestra não encontrada para teste"
    fi
    
    # Testar assinatura digital
    local private_key="$KEYS_DIR/rsa_private.pem"
    local public_key="$KEYS_DIR/rsa_public.pem"
    
    if [[ -f "$private_key" ]] && [[ -f "$public_key" ]]; then
        log_info "Testando assinatura digital RSA..."
        
        local signature_file="/tmp/test_signature.sig"
        local data_file="/tmp/test_data.txt"
        
        echo "$test_data" > "$data_file"
        
        # Assinar
        if openssl dgst -sha256 -sign "$private_key" -out "$signature_file" "$data_file" 2>/dev/null; then
            # Verificar assinatura
            if openssl dgst -sha256 -verify "$public_key" -signature "$signature_file" "$data_file" >/dev/null 2>&1; then
                log_success "✅ Teste assinatura digital: PASSOU"
            else
                log_error "❌ Teste verificação de assinatura: FALHOU"
            fi
        else
            log_error "❌ Teste criação de assinatura: FALHOU"
        fi
        
        # Limpar arquivos temporários
        rm -f "$signature_file" "$data_file"
    else
        log_error "Chaves RSA não encontradas para teste"
    fi
    
    log_success "🧪 Testes de criptografia concluídos"
}

# Configuração completa
setup_crypto() {
    log_info "🚀 Iniciando configuração completa de criptografia..."
    
    setup_directories
    generate_keys
    generate_certificates
    setup_database_encryption
    setup_application_encryption
    
    log_success "🚀 Configuração de criptografia concluída"
    log_info "📁 Diretório principal: $CRYPTO_DIR"
    log_info "🔐 Chaves: $KEYS_DIR"
    log_info "📜 Certificados: $CERTS_DIR"
    log_warning "⚠️ IMPORTANTE: Faça backup das chaves em local seguro"
    log_warning "⚠️ IMPORTANTE: Configure rotação automática de chaves"
}

# Processar comando
case "${1:-help}" in
    setup-crypto)
        setup_crypto
        ;;
    generate-keys)
        generate_keys
        ;;
    generate-certs)
        generate_certificates
        ;;
    setup-database)
        setup_database_encryption
        ;;
    setup-application)
        setup_application_encryption
        ;;
    rotate-keys)
        rotate_keys
        ;;
    validate-crypto)
        validate_crypto
        ;;
    backup-keys)
        backup_keys
        ;;
    test-encryption)
        test_encryption
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Comando inválido: $1"
        show_help
        exit 1
        ;;
esac