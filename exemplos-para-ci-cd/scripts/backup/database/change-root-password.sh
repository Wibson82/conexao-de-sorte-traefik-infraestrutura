#!/bin/bash
set -euo pipefail

# ===================================================================
# 🔐 SCRIPT PARA ALTERAR SENHA ROOT DO MYSQL
# ===================================================================
# Este script deve ser executado após a primeira configuração
# para alterar a senha root inicial (12345678AbcD) por uma senha segura
# ===================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Alteração de Senha Root MySQL${NC}"
echo "======================================"

# Verificar se MySQL está rodando
if ! docker ps | grep -q "mysql"; then
    echo -e "${RED}❌ Container MySQL não está rodando${NC}"
    exit 1
fi

# Obter container ID do MySQL
MYSQL_CONTAINER=$(docker ps --filter "name=mysql" --format "{{.ID}}")

if [ -z "$MYSQL_CONTAINER" ]; then
    echo -e "${RED}❌ Container MySQL não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Container MySQL encontrado: $MYSQL_CONTAINER${NC}"

# Solicitar nova senha
echo ""
echo -e "${YELLOW}⚠️  ATENÇÃO: A senha root atual é: 12345678AbcD${NC}"
echo -e "${YELLOW}⚠️  Esta senha deve ser alterada por segurança!${NC}"
echo ""

read -s -p "🔑 Nova senha root: " NEW_PASSWORD
echo ""

if [ -z "$NEW_PASSWORD" ]; then
    echo -e "${RED}❌ Nova senha não pode ser vazia${NC}"
    exit 1
fi

read -s -p "🔑 Confirme a nova senha: " CONFIRM_PASSWORD
echo ""

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo -e "${RED}❌ Senhas não coincidem${NC}"
    exit 1
fi

# Verificar se a senha atende aos requisitos mínimos
if [ ${#NEW_PASSWORD} -lt 8 ]; then
    echo -e "${RED}❌ Senha deve ter pelo menos 8 caracteres${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔄 Alterando senha root...${NC}"

# Executar comando para alterar senha
if docker exec "$MYSQL_CONTAINER" mysql -u root -p12345678AbcD -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_PASSWORD'; ALTER USER 'root'@'%' IDENTIFIED BY '$NEW_PASSWORD'; FLUSH PRIVILEGES;" 2>/dev/null; then
    echo -e "${GREEN}✅ Senha root alterada com sucesso!${NC}"
    echo ""
    echo -e "${GREEN}📝 Informações importantes:${NC}"
    echo -e "   • Nova senha root: [PROTEGIDA]"
    echo -e "   • Guarde esta senha em local seguro"
    echo -e "   • Atualize os arquivos de configuração se necessário"
    echo ""
    echo -e "${YELLOW}⚠️  Lembre-se de atualizar:${NC}"
    echo -e "   • Docker secrets (produção)"
    echo -e "   • Arquivos de configuração"
    echo -e "   • Documentação do projeto"
else
    echo -e "${RED}❌ Erro ao alterar senha root${NC}"
    echo -e "${YELLOW}💡 Verifique se a senha atual está correta${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}" 