#!/bin/bash

# Script para corrigir permissões no runner self-hosted
# Autor: Equipe Conexão de Sorte
# Data: $(date +"%d/%m/%Y")

# Definir cores para output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}=== Verificador e Corretor de Permissões para Runner Self-Hosted ===${NC}"
echo -e "${YELLOW}Iniciando verificação de permissões...${NC}"

# Verificar se está sendo executado como root ou com sudo
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${YELLOW}⚠️  Este script não está sendo executado como root.${NC}"
  echo -e "${YELLOW}⚠️  Algumas operações podem falhar por falta de permissões.${NC}"
  echo -e "${YELLOW}⚠️  Recomendamos executar com sudo.${NC}"
  echo
  read -p "Deseja continuar mesmo assim? (s/n): " choice
  if [ "$choice" != "s" ] && [ "$choice" != "S" ]; then
    echo -e "${RED}Operação cancelada pelo usuário.${NC}"
    exit 1
  fi
fi

# Definir diretório de trabalho
if [ -z "$GITHUB_WORKSPACE" ]; then
  WORKSPACE_DIR="$(pwd)"
  echo -e "${YELLOW}Variável GITHUB_WORKSPACE não definida. Usando diretório atual: $WORKSPACE_DIR${NC}"
else
  WORKSPACE_DIR="$GITHUB_WORKSPACE"
  echo -e "${GREEN}Usando GITHUB_WORKSPACE: $WORKSPACE_DIR${NC}"
fi

# Verificar se o diretório existe
if [ ! -d "$WORKSPACE_DIR" ]; then
  echo -e "${RED}❌ Diretório de trabalho não existe: $WORKSPACE_DIR${NC}"
  exit 1
fi

# Obter usuário e grupo do runner
RUNNER_USER=$(whoami)
RUNNER_GROUP=$(id -gn)

echo -e "${BLUE}Informações do ambiente:${NC}"
echo -e "- Usuário do runner: ${GREEN}$RUNNER_USER${NC}"
echo -e "- Grupo do runner: ${GREEN}$RUNNER_GROUP${NC}"
echo -e "- Diretório de trabalho: ${GREEN}$WORKSPACE_DIR${NC}"

# Função para corrigir permissões
fix_permissions() {
  local dir=$1
  local description=$2
  
  if [ -d "$dir" ]; then
    echo -e "${YELLOW}🔧 Corrigindo permissões para $description: $dir${NC}"
    chown -R $RUNNER_USER:$RUNNER_GROUP "$dir" 2>/dev/null
    chmod -R u+rwX "$dir" 2>/dev/null
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✅ Permissões corrigidas com sucesso para $description${NC}"
    else
      echo -e "${RED}❌ Falha ao corrigir permissões para $description${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️ Diretório não encontrado: $dir${NC}"
  fi
}

# Função para verificar e remover arquivos problemáticos
check_and_clean_files() {
  local dir=$1
  local description=$2
  
  if [ -d "$dir" ]; then
    echo -e "${YELLOW}🔍 Verificando arquivos problemáticos em $description: $dir${NC}"
    
    # Lista de arquivos problemáticos conhecidos
    local problem_files=("security-headers.yml" "middlewares.yml" "tls.yml")
    
    for file in "${problem_files[@]}"; do
      if [ -f "$dir/$file" ]; then
        echo -e "${YELLOW}🗑️ Removendo arquivo problemático: $dir/$file${NC}"
        rm -f "$dir/$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}✅ Arquivo removido com sucesso: $file${NC}"
        else
          echo -e "${RED}❌ Falha ao remover arquivo: $file${NC}"
          echo -e "${YELLOW}⚠️ Tentando com sudo...${NC}"
          sudo rm -f "$dir/$file" 2>/dev/null
          
          if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Arquivo removido com sucesso usando sudo: $file${NC}"
          else
            echo -e "${RED}❌ Falha ao remover arquivo mesmo com sudo: $file${NC}"
          fi
        fi
      fi
    done
  else
    echo -e "${YELLOW}⚠️ Diretório não encontrado: $dir${NC}"
  fi
}

# Função para verificar processos bloqueando arquivos
check_blocking_processes() {
  local dir=$1
  
  echo -e "${YELLOW}🔍 Verificando processos que podem estar bloqueando arquivos em: $dir${NC}"
  
  if command -v lsof &> /dev/null; then
    lsof +D "$dir" 2>/dev/null
    
    if [ $? -eq 0 ]; then
      echo -e "${RED}⚠️ Processos encontrados bloqueando arquivos!${NC}"
    else
      echo -e "${GREEN}✅ Nenhum processo bloqueando arquivos${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️ Comando 'lsof' não disponível. Não foi possível verificar processos bloqueando arquivos.${NC}"
  fi
}

# Corrigir permissões do diretório de trabalho
fix_permissions "$WORKSPACE_DIR" "diretório de trabalho"

# Verificar diretórios específicos
DYNAMIC_DIR="$WORKSPACE_DIR/traefik/dynamic"
fix_permissions "$DYNAMIC_DIR" "diretório traefik/dynamic"

# Verificar e limpar arquivos problemáticos
check_and_clean_files "$DYNAMIC_DIR" "diretório traefik/dynamic"

# Verificar processos bloqueando arquivos
check_blocking_processes "$WORKSPACE_DIR"

echo -e "\n${GREEN}✅ Verificação e correção de permissões concluída!${NC}"
echo -e "${YELLOW}Execute este script no runner self-hosted antes de iniciar o workflow para evitar problemas de permissão.${NC}"