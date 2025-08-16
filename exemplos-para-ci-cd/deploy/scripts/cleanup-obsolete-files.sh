#!/bin/bash
# 🧹 Limpeza de Arquivos Obsoletos - Production-Ready GitOps
# ✅ Remove arquivos que não são mais necessários após implementação GitOps

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Diretório raiz do projeto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "🧹 Iniciando limpeza de arquivos obsoletos..."
log_warning "Esta operação removerá arquivos permanentemente!"

# Confirmar com usuário
read -p "Deseja continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Operação cancelada pelo usuário"
    exit 0
fi

# Criar backup antes da limpeza
BACKUP_DIR="backups/cleanup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
log_info "📦 Criando backup em: $BACKUP_DIR"

# ===== SCRIPTS OBSOLETOS =====
log_info "🗂️ Removendo scripts obsoletos..."

# Scripts de deploy (substituídos pelo GitOps)
if [[ -d "scripts/deploy" ]]; then
    cp -r scripts/deploy "$BACKUP_DIR/"
    rm -rf scripts/deploy
    log_success "Removido: scripts/deploy/"
fi

# Scripts de refatoração (concluída)
if [[ -d "scripts/refatoracao" ]]; then
    cp -r scripts/refatoracao "$BACKUP_DIR/"
    rm -rf scripts/refatoracao
    log_success "Removido: scripts/refatoracao/"
fi

# Scripts de monitoramento (substituídos pelo Prometheus)
if [[ -d "scripts/monitoring" ]]; then
    cp -r scripts/monitoring "$BACKUP_DIR/"
    rm -rf scripts/monitoring
    log_success "Removido: scripts/monitoring/"
fi

# Scripts VPS (substituídos pelo deploy automático)
if [[ -d "scripts/vps" ]]; then
    cp -r scripts/vps "$BACKUP_DIR/"
    rm -rf scripts/vps
    log_success "Removido: scripts/vps/"
fi

# Scripts individuais obsoletos
obsolete_scripts=(
    "scripts/cleanup-duplicates.sh"
    "scripts/one-click-mysql-deploy.sh"
    "scripts/pos-deploy-config.sh"
    "scripts/post-deploy-cleanup.sh"
    "scripts/pre-deploy-check.sh"
    "scripts/reset-and-deploy.sh"
    "scripts/run.sh"
    "scripts/setup-all-scripts.sh"
    "scripts/test-docker-secrets.sh"
    "scripts/test-mysql.sh"
    "scripts/test-secrets.sh"
    "scripts/validar-correcoes.sh"
    "scripts/validate-deployment.sh"
)

for script in "${obsolete_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        cp "$script" "$BACKUP_DIR/"
        rm "$script"
        log_success "Removido: $script"
    fi
done

# ===== DOCKER COMPOSE OBSOLETOS =====
log_info "🐳 Removendo Docker Compose obsoletos..."

obsolete_compose=(
    "docker-compose.prod.yml"
    "docker-compose.simple.yml"
    "docker-compose.test-local.yml"
    "docker-compose.test.yml"
    "docker-compose.yml"
    "docker-stack-production.yml"
)

for compose in "${obsolete_compose[@]}"; do
    if [[ -f "$compose" ]]; then
        cp "$compose" "$BACKUP_DIR/"
        rm "$compose"
        log_success "Removido: $compose"
    fi
done

# ===== SCRIPTS RAIZ OBSOLETOS =====
log_info "📄 Removendo scripts da raiz..."

obsolete_root_scripts=(
    "cleanup-dev.sh"
    "debug-dev.sh"
    "deploy-dev.sh"
    "deploy-manual-swarm.sh"
    "entrypoint.sh"
    "monitor-dev.sh"
    "setup-secrets.sh"
    "test-health-endpoint.sh"
    "test-keyvault-endpoint.sh"
    "validate-dev.sh"
)

for script in "${obsolete_root_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        cp "$script" "$BACKUP_DIR/"
        rm "$script"
        log_success "Removido: $script"
    fi
done

# ===== DOCUMENTAÇÃO OBSOLETA =====
log_info "📚 Removendo documentação obsoleta..."

# Documentos de deploy obsoletos
obsolete_docs=(
    "docs/DEPLOY-PRODUCAO-COMPLETO.md"
    "docs/DEPLOY-WORKFLOW.md"
    "docs/OPERACOES-E-DEPLOY.md"
    "docs/README-LIMPEZA-CONFIGURACOES.md"
    "docs/README-LIMPEZA-DOCKER.md"
    "docs/README-LIMPEZA-DOCUMENTACAO.md"
    "docs/TROUBLESHOOTING-MYSQL.md"
    "docs/VALIDACAO-POS-REFATORACAO.md"
    "docs/ANALISE-AZURE-KEYVAULT-CICD.md"
)

for doc in "${obsolete_docs[@]}"; do
    if [[ -f "$doc" ]]; then
        cp "$doc" "$BACKUP_DIR/"
        rm "$doc"
        log_success "Removido: $doc"
    fi
done

# Diretório de refatoração completo
if [[ -d "docs/refatoracao" ]]; then
    cp -r docs/refatoracao "$BACKUP_DIR/"
    rm -rf docs/refatoracao
    log_success "Removido: docs/refatoracao/"
fi

# Documentos da raiz obsoletos
obsolete_root_docs=(
    "README-DEPLOY-HIBRIDO.md"
    "CONFIGURACAO-AMBIENTES.md"
    "CONFLITOS_CORRIGIDOS.md"
    "CORREÇÃO-JARlauncher.md"
)

for doc in "${obsolete_root_docs[@]}"; do
    if [[ -f "$doc" ]]; then
        cp "$doc" "$BACKUP_DIR/"
        rm "$doc"
        log_success "Removido: $doc"
    fi
done

# ===== DOCKERFILES OBSOLETOS =====
log_info "🐳 Removendo Dockerfiles obsoletos..."

# Diretórios completos
obsolete_docker_dirs=(
    "dockerfiles/mysql"
    "dockerfiles/nginx" 
    "dockerfiles/traefik"
    "nginx"
    "mysql-config"
    "monitoring"
)

for dir in "${obsolete_docker_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        cp -r "$dir" "$BACKUP_DIR/"
        rm -rf "$dir"
        log_success "Removido: $dir/"
    fi
done

# Remover diretório dockerfiles se vazio
if [[ -d "dockerfiles" ]] && [[ -z "$(ls -A dockerfiles)" ]]; then
    rmdir dockerfiles
    log_success "Removido: dockerfiles/ (vazio)"
fi

# ===== ARQUIVOS DIVERSOS OBSOLETOS =====
log_info "🗃️ Removendo arquivos diversos..."

obsolete_files=(
    "Dockerfile.multistage"
    "init-mysql-secure.sql"
    "scripts/init-mysql-secure.sql"
)

for file in "${obsolete_files[@]}"; do
    if [[ -f "$file" ]]; then
        cp "$file" "$BACKUP_DIR/"
        rm "$file"
        log_success "Removido: $file"
    fi
done

# ===== RESUMO =====
log_success "🎉 Limpeza concluída!"
log_info "📦 Backup salvo em: $BACKUP_DIR"
log_info "📊 Arquivos mantidos (essenciais):"
echo "  ✅ deploy/ - Nova estrutura Production-Ready"
echo "  ✅ .github/workflows/ - Pipeline GitOps"
echo "  ✅ src/ - Código fonte"
echo "  ✅ scripts/azure/ - Troubleshooting Azure"
echo "  ✅ scripts/database/backup-restore.sh - Backup manual"
echo "  ✅ docs/DIRETRIZES_*.md - Diretrizes de desenvolvimento"
echo "  ✅ docker-compose.dev.yml - Desenvolvimento local"

log_warning "⚠️  Se precisar de algum arquivo removido, restaure do backup!"
log_info "🚀 Projeto agora está limpo e otimizado para Production-Ready GitOps"
