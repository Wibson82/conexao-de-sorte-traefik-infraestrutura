-- =============================================================================
-- SCRIPT DE MIGRAÇÃO DE TABELAS PARA TDE
-- Projeto: Conexão de Sorte - Transparent Data Encryption
-- =============================================================================

-- Verificar status atual do TDE
SELECT 'Verificando status TDE...' as status;
SHOW VARIABLES LIKE 'innodb_encrypt%';

-- Verificar keyring disponível
SELECT 'Verificando keyring...' as status;
SELECT * FROM performance_schema.keyring_keys;

-- =============================================================================
-- BACKUP DE SEGURANÇA ANTES DA MIGRAÇÃO
-- =============================================================================

-- Criar tabela de log de migração
CREATE TABLE IF NOT EXISTS migration_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL,
    action VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    error_message TEXT NULL,
    INDEX idx_table_name (table_name),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- =============================================================================
-- FUNÇÃO PARA REGISTRAR LOG DE MIGRAÇÃO
-- =============================================================================

DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS log_migration_step(
    IN p_table_name VARCHAR(255),
    IN p_action VARCHAR(50),
    IN p_status VARCHAR(50),
    IN p_error_message TEXT
)
BEGIN
    INSERT INTO migration_log (table_name, action, status, end_time, error_message)
    VALUES (p_table_name, p_action, p_status, CURRENT_TIMESTAMP, p_error_message);
END$$

DELIMITER ;

-- =============================================================================
-- VERIFICAR TABELAS EXISTENTES
-- =============================================================================

SELECT 'Verificando tabelas existentes...' as status;

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    ENGINE,
    CREATE_OPTIONS,
    CASE 
        WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN 'CRIPTOGRAFADA'
        ELSE 'NÃO CRIPTOGRAFADA'
    END as ENCRYPTION_STATUS
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- =============================================================================
-- MIGRAÇÃO DAS TABELAS PRINCIPAIS
-- =============================================================================

-- Registrar início da migração
CALL log_migration_step('MIGRATION_START', 'BEGIN', 'STARTED', NULL);

-- 1. TABELA USUARIOS (Dados pessoais sensíveis)
SELECT 'Migrando tabela usuarios...' as status;
CALL log_migration_step('usuarios', 'ENCRYPT', 'STARTED', NULL);

ALTER TABLE usuarios ENCRYPTION='Y';

-- Verificar se a migração foi bem-sucedida
SELECT 
    CASE 
        WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN 'SUCCESS'
        ELSE 'FAILED'
    END as migration_status
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte' 
  AND TABLE_NAME = 'usuarios';

CALL log_migration_step('usuarios', 'ENCRYPT', 'COMPLETED', NULL);

-- 2. TABELA SORTEIOS (Dados de negócio críticos)
SELECT 'Migrando tabela sorteios...' as status;
CALL log_migration_step('sorteios', 'ENCRYPT', 'STARTED', NULL);

ALTER TABLE sorteios ENCRYPTION='Y';

CALL log_migration_step('sorteios', 'ENCRYPT', 'COMPLETED', NULL);

-- 3. TABELA PARTICIPANTES (Dados pessoais)
SELECT 'Migrando tabela participantes...' as status;
CALL log_migration_step('participantes', 'ENCRYPT', 'STARTED', NULL);

ALTER TABLE participantes ENCRYPTION='Y';

CALL log_migration_step('participantes', 'ENCRYPT', 'COMPLETED', NULL);

-- 4. TABELA TRANSACOES (Dados financeiros)
SELECT 'Migrando tabela transacoes...' as status;
CALL log_migration_step('transacoes', 'ENCRYPT', 'STARTED', NULL);

ALTER TABLE transacoes ENCRYPTION='Y';

CALL log_migration_step('transacoes', 'ENCRYPT', 'COMPLETED', NULL);

-- 5. TABELA AUDIT_LOGS (Logs de auditoria)
SELECT 'Migrando tabela audit_logs...' as status;
CALL log_migration_step('audit_logs', 'ENCRYPT', 'STARTED', NULL);

-- Criar tabela de auditoria se não existir
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NULL,
    record_id BIGINT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_table_name (table_name),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB ENCRYPTION='Y';

CALL log_migration_step('audit_logs', 'ENCRYPT', 'COMPLETED', NULL);

-- 6. TABELAS DE CONFIGURAÇÃO (Se existirem)
SELECT 'Migrando tabelas de configuração...' as status;

-- Verificar se existem outras tabelas para migrar
SELECT 
    CONCAT('ALTER TABLE ', TABLE_NAME, ' ENCRYPTION=''Y'';') as migration_command
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
  AND TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME NOT IN ('usuarios', 'sorteios', 'participantes', 'transacoes', 'audit_logs', 'migration_log')
  AND CREATE_OPTIONS NOT LIKE '%ENCRYPTION%';

-- =============================================================================
-- VERIFICAÇÃO FINAL
-- =============================================================================

SELECT 'Verificação final da migração...' as status;

-- Verificar todas as tabelas criptografadas
SELECT 
    TABLE_NAME,
    ENGINE,
    CREATE_OPTIONS,
    CASE 
        WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN '✅ CRIPTOGRAFADA'
        ELSE '❌ NÃO CRIPTOGRAFADA'
    END as ENCRYPTION_STATUS,
    TABLE_ROWS,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as SIZE_MB
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Verificar keyring após migração
SELECT 'Verificando keyring após migração...' as status;
SELECT 
    KEY_ID,
    KEY_OWNER,
    BACKEND_KEY_ID
FROM performance_schema.keyring_keys;

-- Estatísticas de migração
SELECT 'Estatísticas de migração...' as status;

SELECT 
    COUNT(*) as total_tables,
    SUM(CASE WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN 1 ELSE 0 END) as encrypted_tables,
    SUM(CASE WHEN CREATE_OPTIONS NOT LIKE '%ENCRYPTION%' THEN 1 ELSE 0 END) as unencrypted_tables,
    ROUND(
        (SUM(CASE WHEN CREATE_OPTIONS LIKE '%ENCRYPTION%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        2
    ) as encryption_percentage
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
  AND TABLE_TYPE = 'BASE TABLE';

-- Log de migração completo
SELECT 'Log de migração...' as status;
SELECT 
    table_name,
    action,
    status,
    start_time,
    end_time,
    TIMESTAMPDIFF(SECOND, start_time, end_time) as duration_seconds,
    error_message
FROM migration_log 
ORDER BY start_time;

-- Registrar fim da migração
CALL log_migration_step('MIGRATION_END', 'COMPLETE', 'SUCCESS', NULL);

-- =============================================================================
-- COMANDOS DE VALIDAÇÃO MANUAL
-- =============================================================================

/*
-- Comandos para executar manualmente após a migração:

-- 1. Verificar se TDE está funcionando
SHOW VARIABLES LIKE 'innodb_encrypt%';

-- 2. Verificar keyring
SELECT * FROM performance_schema.keyring_keys;

-- 3. Verificar tabelas criptografadas
SELECT TABLE_NAME, CREATE_OPTIONS 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'conexao_de_sorte' 
  AND CREATE_OPTIONS LIKE '%ENCRYPTION%';

-- 4. Testar inserção em tabela criptografada
INSERT INTO usuarios (nome, email, cpf, created_at) 
VALUES ('Teste TDE', 'teste@tde.com', '12345678901', NOW());

-- 5. Verificar se dados foram inseridos
SELECT * FROM usuarios WHERE email = 'teste@tde.com';

-- 6. Limpar dados de teste
DELETE FROM usuarios WHERE email = 'teste@tde.com';

-- 7. Verificar performance
SHOW GLOBAL STATUS LIKE 'Innodb_encryption%';

-- 8. Verificar logs de erro
-- Verificar arquivo: /var/log/mysql/error.log
*/

-- =============================================================================
-- NOTAS IMPORTANTES
-- =============================================================================

/*
NOTAS CRÍTICAS SOBRE TDE:

1. BACKUP DO KEYRING:
   - O keyring é CRÍTICO para recuperação dos dados
   - Sem keyring, dados criptografados são IRRECUPERÁVEIS
   - Fazer backup do diretório /var/lib/mysql-keyring/

2. PERFORMANCE:
   - TDE adiciona overhead de ~5-15%
   - Monitorar performance após migração
   - Considerar ajustes de buffer pool se necessário

3. BACKUP E RESTORE:
   - Backups incluem dados criptografados
   - Keyring deve estar disponível para restore
   - Testar procedimentos de backup/restore

4. REPLICAÇÃO:
   - Master e slaves devem ter keyring sincronizado
   - Configurar replicação de keyring se aplicável

5. MONITORAMENTO:
   - Monitorar variáveis Innodb_encryption_*
   - Alertas para falhas de criptografia
   - Logs de erro para problemas de keyring

6. SEGURANÇA:
   - Keyring deve ter permissões 700
   - Owner deve ser mysql:mysql
   - Considerar keyring remoto para produção
*/

SELECT 'Migração TDE concluída! Verifique os logs acima.' as final_status;
