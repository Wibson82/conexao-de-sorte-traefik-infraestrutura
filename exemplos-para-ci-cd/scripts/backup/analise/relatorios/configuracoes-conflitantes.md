# ⚙️ RELATÓRIO DE CONFIGURAÇÕES CONFLITANTES

## 🔍 Análise de Arquivos de Configuração

### 📄 Arquivos de Configuração Spring

#### application-ci.yml

```yaml
#============================================================================
# 🚀 CONFIGURAÇÃO DE AMBIENTE CI/CD - APPLICATION-CI.YML
#============================================================================
#
# NOVA ESTRATÉGIA: Replicar configurações de produção que funcionam
# Adaptadas para ambiente CI/CD com otimizações específicas
# Baseado nas configurações de produção que são estáveis
#
#============================================================================

spring:
  config:
    activate:
      on-profile: ci
    import: "classpath:application-common.yml"

  # ===== BANCO DE DADOS MYSQL COM TESTCONTAINERS (CONFIG PRODUÇÃO) =====
  datasource:
    url: jdbc:tc:mysql:8.4:///conexao_de_sorte?TC_INITSCRIPT=file:src/test/resources/init-test-db.sql&TC_TMPFS=/testtmpfs:rw&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo&createDatabaseIfNotExist=true
    username: ${CI_DB_USERNAME:testuser}
```

#### application-production.yml

```yaml
# =============================================================================
# CONFIGURAÇÃO DE PRODUÇÃO - VPS HOSTINGER
# =============================================================================
# Configuração específica para produção em VPS sem Azure Key Vault

spring:
  config:
    activate:
      on-profile: production
    import: "classpath:application-common.yml"

  # Configuração Redis para rate limiting distribuído
  data:
    redis:
      host: ${REDIS_HOST:conexao-redis}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      database: ${REDIS_DATABASE:0}
      timeout: 2000ms
      lettuce:
```

#### application-azure.yml

```yaml
# =============================================================================
# CONFIGURAÇÃO AZURE KEY VAULT - SPRING CLOUD AZURE 5.22.0
# =============================================================================
# ✅ Usa DefaultAzureCredential (recomendado para produção)
# ✅ Configuração moderna Spring Cloud Azure
# ✅ Compatível com Azure Container Apps, VMs e desenvolvimento local
# ✅ Fallback automático quando Azure não está disponível
# =============================================================================

spring:
  config:
    activate:
      on-profile: azure
    import:
      - "classpath:application-production.yml"
      - "classpath:application-common.yml"

  # ===== SPRING CLOUD AZURE MODERNA =====
  cloud:
    azure:
```

#### application-test.yml

```yaml
#============================================================================
# 🧪 CONFIGURAÇÃO DE AMBIENTE DE TESTE - APPLICATION-TEST.YML
#============================================================================
#
# ESTRATÉGIA: Ambiente de teste FIEL À PRODUÇÃO
# - Mesmas configurações de segurança que produção
# - Mesmos comportamentos de autenticação e autorização
# - Mesmas validações e filtros
# - Apenas diferenças mínimas necessárias (porta, logging)
#
#============================================================================

spring:
  config:
    activate:
      on-profile: test
    import: "classpath:application-common.yml"

  # ===== CONFIGURAÇÃO DE BANCO DE DADOS (MESMAS CREDENCIAIS DE PRODUÇÃO) =====
  datasource:
```

#### application-dev.yml

```yaml
#============================================================================
# 🛠️ CONFIGURAÇÃO DE AMBIENTE DE DESENVOLVIMENTO - APPLICATION-DEV.YML
#============================================================================
#
# Configuração otimizada para desenvolvimento local:
# - ✅ Testcontainers MySQL para isolamento
# - ✅ JWT com fallback local (não usar em produção)
# - ✅ Logs detalhados para debug
# - ✅ Hot reload habilitado
# - ✅ Configurações de desenvolvimento
#
#============================================================================

# ===== CONFIGURAÇÃO DE SERVIDOR REATIVO =====
server:
  port: 8080
  shutdown: graceful
  # REMOVIDO: configurações tomcat.* incompatíveis com WebFlux/Netty

# ===== CONFIGURAÇÃO SPRING CONSOLIDADA =====
```

#### application-common.yml

```yaml
# =============================================================================
# CONFIGURAÇÃO COMUM - CONEXÃO DE SORTE
# =============================================================================
# Configurações compartilhadas entre todos os ambientes
# Diferenças específicas por ambiente são definidas nos respectivos profiles

spring:
  # =============================================================================
  # DATASOURCE - CONFIGURAÇÃO BASE
  # =============================================================================
  datasource:
    hikari:
      pool-name: ConexaoDeSortePool
      connection-timeout: ${DB_CONNECTION_TIMEOUT:20000}
      validation-timeout: ${DB_VALIDATION_TIMEOUT:5000}
      maximum-pool-size: ${DB_MAX_POOL_SIZE:10}
      minimum-idle: ${DB_MIN_IDLE:5}
      idle-timeout: ${DB_IDLE_TIMEOUT:600000}
      max-lifetime: ${DB_MAX_LIFETIME:1800000}
      leak-detection-threshold: ${DB_LEAK_DETECTION:60000}
```

#### application.yml

```yaml
# =============================================================================
# CONFIGURAÇÃO PRINCIPAL - CONEXÃO DE SORTE
# =============================================================================
# Configuração consolidada que funciona em desenvolvimento e produção
# Diferenças apenas por sistema operacional

spring:
  config:
    import:
      - "classpath:application-common.yml"
  application:
    name: conexao-de-sorte-backend

  # ✅ Configuração de Cache Nativa do Spring Boot
  # Documentação: https://docs.spring.io/spring-boot/docs/current/reference/html/io.html#io.caching
  cache:
    type: caffeine
    caffeine:
      spec: maximumSize=1000,expireAfterWrite=30m,recordStats
    cache-names:
```

