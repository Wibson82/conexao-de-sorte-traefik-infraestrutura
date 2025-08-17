-- Inicialização do banco de dados Conexão de Sorte
-- Este script é executado automaticamente na primeira inicialização do PostgreSQL

-- Criar database de teste se não existir
SELECT 'CREATE DATABASE conexaodesorte_test'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'conexaodesorte_test')\gexec

-- Conectar ao database principal
\c conexaodesorte;

-- Criar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Criar schema básico (exemplo)
CREATE SCHEMA IF NOT EXISTS public;

-- Tabela de usuários (exemplo básico)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de resultados de loteria (exemplo)
CREATE TABLE IF NOT EXISTS lottery_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lottery_type VARCHAR(50) NOT NULL,
    draw_number INTEGER NOT NULL,
    draw_date DATE NOT NULL,
    numbers INTEGER[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(lottery_type, draw_number)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_lottery_results_type_date ON lottery_results(lottery_type, draw_date DESC);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Inserir dados de exemplo para teste
INSERT INTO lottery_results (lottery_type, draw_number, draw_date, numbers) 
VALUES 
    ('federal', 5001, CURRENT_DATE, ARRAY[12345, 67890, 11111, 22222, 33333])
ON CONFLICT (lottery_type, draw_number) DO NOTHING;

COMMIT;