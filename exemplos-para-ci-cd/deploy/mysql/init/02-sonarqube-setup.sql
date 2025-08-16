-- ===== CONFIGURAÇÃO BANCO SONARQUBE =====
-- Script de inicialização para SonarQube
-- Executado automaticamente na primeira inicialização do MySQL
-- Data: $(date +"%d/%m/%Y")

-- Criar banco de dados para SonarQube
CREATE DATABASE IF NOT EXISTS sonarqube
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Criar usuário específico para SonarQube
CREATE USER IF NOT EXISTS 'sonarqube'@'%' IDENTIFIED BY 'sonarqube123';

-- Conceder privilégios necessários
GRANT ALL PRIVILEGES ON sonarqube.* TO 'sonarqube'@'%';

-- Aplicar mudanças
FLUSH PRIVILEGES;

-- Verificar criação
SELECT 
  SCHEMA_NAME as 'Database',
  DEFAULT_CHARACTER_SET_NAME as 'Charset',
  DEFAULT_COLLATION_NAME as 'Collation'
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'sonarqube';

-- Log de confirmação
SELECT 'SonarQube database setup completed successfully' as Status;

-- ===== CONFIGURAÇÕES ESPECÍFICAS SONARQUBE =====

-- Usar o banco SonarQube
USE sonarqube;

-- Configurações de performance para SonarQube
SET GLOBAL innodb_buffer_pool_size = 268435456; -- 256MB
SET GLOBAL max_connections = 200;
SET GLOBAL innodb_log_file_size = 67108864; -- 64MB

-- Configurações de timeout
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;

-- Configurações de charset para compatibilidade
SET GLOBAL character_set_server = 'utf8mb4';
SET GLOBAL collation_server = 'utf8mb4_unicode_ci';

-- ===== VERIFICAÇÕES DE SAÚDE =====

-- Verificar configurações aplicadas
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';
SHOW VARIABLES LIKE 'max_connections';

-- Verificar usuário criado
SELECT User, Host FROM mysql.user WHERE User = 'sonarqube';

-- Verificar privilégios
SHOW GRANTS FOR 'sonarqube'@'%';

-- Log final
SELECT 
  'SonarQube MySQL setup completed' as Message,
  NOW() as Timestamp,
  'Database: sonarqube' as Database_Created,
  'User: sonarqube@%' as User_Created,
  'Charset: utf8mb4' as Charset,
  'Collation: utf8mb4_unicode_ci' as Collation;

-- ===== NOTAS DE CONFIGURAÇÃO =====
/*
1. Este script é executado automaticamente na primeira inicialização do MySQL
2. Cria o banco 'sonarqube' com charset utf8mb4 para suporte completo Unicode
3. Cria usuário 'sonarqube' com senha 'sonarqube123' (alterar em produção)
4. Configura parâmetros de performance adequados para SonarQube
5. O SonarQube criará suas tabelas automaticamente na primeira execução
6. Para produção, considere alterar a senha do usuário sonarqube
7. Monitore o uso de memória e ajuste innodb_buffer_pool_size conforme necessário
8. Este script é idempotente - pode ser executado múltiplas vezes sem problemas
*/