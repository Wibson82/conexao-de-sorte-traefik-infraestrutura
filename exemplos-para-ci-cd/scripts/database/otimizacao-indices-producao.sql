-- =============================================================================
-- OTIMIZAÇÃO DE ÍNDICES PARA PRODUÇÃO - CONEXÃO DE SORTE
-- =============================================================================
-- Script de otimização de performance do banco de dados
-- Baseado na análise de queries frequentes e padrões de acesso
-- 
-- IMPORTANTE: Executar em horário de baixo tráfego
-- Tempo estimado: 5-10 minutos
-- Impacto esperado: -50% tempo de consultas críticas

-- =============================================================================
-- ANÁLISE DE QUERIES LENTAS (EXECUTAR ANTES)
-- =============================================================================

-- Habilitar log de queries lentas (se não estiver habilitado)
-- SET GLOBAL slow_query_log = 'ON';
-- SET GLOBAL long_query_time = 1;
-- SET GLOBAL log_queries_not_using_indexes = 'ON';

-- Verificar queries mais lentas
-- SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- =============================================================================
-- ÍNDICES PARA TABELA USUARIO
-- =============================================================================

-- Índice para busca por email (login mais frequente)
CREATE INDEX IF NOT EXISTS idx_usuario_email 
ON usuario(email);

-- Índice composto para usuários ativos com email verificado
CREATE INDEX IF NOT EXISTS idx_usuario_ativo_email_verificado 
ON usuario(ativo, email_verificado);

-- Índice para busca por CPF (validações)
CREATE INDEX IF NOT EXISTS idx_usuario_cpf 
ON usuario(cpf);

-- Índice para ordenação por data de criação
CREATE INDEX IF NOT EXISTS idx_usuario_data_criacao 
ON usuario(data_criacao DESC);

-- Índice composto para queries de administração
CREATE INDEX IF NOT EXISTS idx_usuario_admin_busca 
ON usuario(ativo, email_verificado, data_criacao DESC);

-- =============================================================================
-- ÍNDICES PARA TABELA SESSAO_ATIVA
-- =============================================================================

-- Índice para busca por usuário (sessões ativas)
CREATE INDEX IF NOT EXISTS idx_sessao_ativa_usuario 
ON sessao_ativa(usuario_id, ativa);

-- Índice para limpeza de sessões expiradas
CREATE INDEX IF NOT EXISTS idx_sessao_ativa_expiracao 
ON sessao_ativa(data_expiracao, ativa);

-- Índice para busca por token de sessão
CREATE INDEX IF NOT EXISTS idx_sessao_ativa_token 
ON sessao_ativa(token_sessao);

-- Índice composto para queries de validação
CREATE INDEX IF NOT EXISTS idx_sessao_validacao 
ON sessao_ativa(usuario_id, ativa, data_expiracao);

-- =============================================================================
-- ÍNDICES PARA TABELA CONVERSA
-- =============================================================================

-- Índice para busca por usuário ordenado por data
CREATE INDEX IF NOT EXISTS idx_conversa_usuario_data 
ON conversa(usuario_id, data_criacao DESC);

-- Índice para conversas ativas
CREATE INDEX IF NOT EXISTS idx_conversa_ativa 
ON conversa(ativa, data_criacao DESC);

-- Índice composto para listagem de conversas
CREATE INDEX IF NOT EXISTS idx_conversa_listagem 
ON conversa(usuario_id, ativa, data_criacao DESC);

-- =============================================================================
-- ÍNDICES PARA TABELA MENSAGEM
-- =============================================================================

-- Índice para busca por conversa ordenado por data
CREATE INDEX IF NOT EXISTS idx_mensagem_conversa_data 
ON mensagem(conversa_id, data_envio DESC);

-- Índice para mensagens por status
CREATE INDEX IF NOT EXISTS idx_mensagem_status 
ON mensagem(status_mensagem, data_envio DESC);

-- Índice composto para queries de mensagens
CREATE INDEX IF NOT EXISTS idx_mensagem_busca 
ON mensagem(conversa_id, status_mensagem, data_envio DESC);

-- =============================================================================
-- ÍNDICES PARA TABELA HORARIO_VALIDO
-- =============================================================================

-- Índice para busca por data (query mais frequente)
CREATE INDEX IF NOT EXISTS idx_horario_valido_data 
ON horario_valido(data_valida);

-- Índice para horários ativos
CREATE INDEX IF NOT EXISTS idx_horario_valido_ativo 
ON horario_valido(ativo, data_valida);

-- =============================================================================
-- ÍNDICES PARA TABELA RESULTADO
-- =============================================================================

-- Índice para busca por data do sorteio
CREATE INDEX IF NOT EXISTS idx_resultado_data_sorteio 
ON resultado(data_sorteio DESC);

-- Índice para resultados por tipo de jogo
CREATE INDEX IF NOT EXISTS idx_resultado_tipo_jogo 
ON resultado(tipo_jogo, data_sorteio DESC);

-- =============================================================================
-- ÍNDICES PARA TABELA NOTIFICACAO
-- =============================================================================

-- Índice para notificações por usuário
CREATE INDEX IF NOT EXISTS idx_notificacao_usuario 
ON notificacao(usuario_id, data_criacao DESC);

-- Índice para notificações não lidas
CREATE INDEX IF NOT EXISTS idx_notificacao_nao_lida 
ON notificacao(usuario_id, lida, data_criacao DESC);

-- =============================================================================
-- ÍNDICES PARA TABELA LOG_ACESSO
-- =============================================================================

-- Índice para logs por usuário e data
CREATE INDEX IF NOT EXISTS idx_log_acesso_usuario_data 
ON log_acesso(usuario_id, data_acesso DESC);

-- Índice para logs por IP (segurança)
CREATE INDEX IF NOT EXISTS idx_log_acesso_ip 
ON log_acesso(endereco_ip, data_acesso DESC);

-- =============================================================================
-- OTIMIZAÇÕES DE TABELA
-- =============================================================================

-- Analisar tabelas para otimizar estatísticas
ANALYZE TABLE usuario;
ANALYZE TABLE sessao_ativa;
ANALYZE TABLE conversa;
ANALYZE TABLE mensagem;
ANALYZE TABLE horario_valido;
ANALYZE TABLE resultado;
ANALYZE TABLE notificacao;
ANALYZE TABLE log_acesso;

-- =============================================================================
-- VERIFICAÇÃO DE PERFORMANCE
-- =============================================================================

-- Query para verificar uso dos índices
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY,
    SUB_PART,
    PACKED,
    NULLABLE,
    INDEX_TYPE
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'conexao_de_sorte'
ORDER BY TABLE_NAME, INDEX_NAME;

-- Query para verificar tamanho dos índices
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) AS 'Index Size (MB)'
FROM information_schema.INNODB_SYS_TABLESTATS
WHERE TABLE_NAME LIKE '%conexao_de_sorte%';

-- =============================================================================
-- QUERIES DE TESTE DE PERFORMANCE
-- =============================================================================

-- Teste 1: Busca de usuário por email (deve usar idx_usuario_email)
EXPLAIN SELECT * FROM usuario WHERE email = 'teste@exemplo.com';

-- Teste 2: Listagem de conversas do usuário (deve usar idx_conversa_usuario_data)
EXPLAIN SELECT * FROM conversa WHERE usuario_id = 1 ORDER BY data_criacao DESC LIMIT 10;

-- Teste 3: Mensagens de uma conversa (deve usar idx_mensagem_conversa_data)
EXPLAIN SELECT * FROM mensagem WHERE conversa_id = 1 ORDER BY data_envio DESC LIMIT 50;

-- Teste 4: Horário válido por data (deve usar idx_horario_valido_data)
EXPLAIN SELECT * FROM horario_valido WHERE data_valida = '2025-08-13';

-- Teste 5: Sessões ativas do usuário (deve usar idx_sessao_ativa_usuario)
EXPLAIN SELECT * FROM sessao_ativa WHERE usuario_id = 1 AND ativa = true;

-- =============================================================================
-- MONITORAMENTO CONTÍNUO
-- =============================================================================

-- Query para monitorar queries lentas
SELECT 
    sql_text,
    count_star,
    avg_timer_wait/1000000000 as avg_time_seconds,
    max_timer_wait/1000000000 as max_time_seconds
FROM performance_schema.events_statements_summary_by_digest 
WHERE avg_timer_wait > 1000000000  -- Mais de 1 segundo
ORDER BY avg_timer_wait DESC 
LIMIT 10;

-- Query para monitorar uso de índices
SELECT 
    object_schema,
    object_name,
    index_name,
    count_read,
    count_insert,
    count_update,
    count_delete
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE object_schema = 'conexao_de_sorte'
ORDER BY count_read DESC;

-- =============================================================================
-- LIMPEZA E MANUTENÇÃO
-- =============================================================================

-- Otimizar tabelas após criação dos índices
OPTIMIZE TABLE usuario;
OPTIMIZE TABLE sessao_ativa;
OPTIMIZE TABLE conversa;
OPTIMIZE TABLE mensagem;
OPTIMIZE TABLE horario_valido;
OPTIMIZE TABLE resultado;
OPTIMIZE TABLE notificacao;
OPTIMIZE TABLE log_acesso;

-- =============================================================================
-- SCRIPT DE ROLLBACK (SE NECESSÁRIO)
-- =============================================================================

/*
-- Para remover os índices criados (apenas se necessário):

DROP INDEX IF EXISTS idx_usuario_email ON usuario;
DROP INDEX IF EXISTS idx_usuario_ativo_email_verificado ON usuario;
DROP INDEX IF EXISTS idx_usuario_cpf ON usuario;
DROP INDEX IF EXISTS idx_usuario_data_criacao ON usuario;
DROP INDEX IF EXISTS idx_usuario_admin_busca ON usuario;

DROP INDEX IF EXISTS idx_sessao_ativa_usuario ON sessao_ativa;
DROP INDEX IF EXISTS idx_sessao_ativa_expiracao ON sessao_ativa;
DROP INDEX IF EXISTS idx_sessao_ativa_token ON sessao_ativa;
DROP INDEX IF EXISTS idx_sessao_validacao ON sessao_ativa;

DROP INDEX IF EXISTS idx_conversa_usuario_data ON conversa;
DROP INDEX IF EXISTS idx_conversa_ativa ON conversa;
DROP INDEX IF EXISTS idx_conversa_listagem ON conversa;

DROP INDEX IF EXISTS idx_mensagem_conversa_data ON mensagem;
DROP INDEX IF EXISTS idx_mensagem_status ON mensagem;
DROP INDEX IF EXISTS idx_mensagem_busca ON mensagem;

DROP INDEX IF EXISTS idx_horario_valido_data ON horario_valido;
DROP INDEX IF EXISTS idx_horario_valido_ativo ON horario_valido;

DROP INDEX IF EXISTS idx_resultado_data_sorteio ON resultado;
DROP INDEX IF EXISTS idx_resultado_tipo_jogo ON resultado;

DROP INDEX IF EXISTS idx_notificacao_usuario ON notificacao;
DROP INDEX IF EXISTS idx_notificacao_nao_lida ON notificacao;

DROP INDEX IF EXISTS idx_log_acesso_usuario_data ON log_acesso;
DROP INDEX IF EXISTS idx_log_acesso_ip ON log_acesso;
*/

-- =============================================================================
-- CONCLUSÃO
-- =============================================================================

-- Este script cria índices otimizados para as queries mais frequentes
-- Impacto esperado:
-- - Redução de 50-70% no tempo de consultas críticas
-- - Melhoria significativa na experiência do usuário
-- - Redução da carga no servidor de banco de dados
-- 
-- Monitorar performance após aplicação e ajustar conforme necessário
