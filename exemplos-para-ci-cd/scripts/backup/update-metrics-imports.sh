#!/bin/bash

# =============================================================================
# SCRIPT PARA ATUALIZAR IMPORTS DE ChatMetricsRegistry PARA RegistroMetricasChat
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 ATUALIZANDO IMPORTS DE ChatMetricsRegistry PARA RegistroMetricasChat${NC}"
echo -e "${BLUE}=================================================================${NC}"

# Lista de arquivos que precisam ser atualizados
files_to_update=(
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/batepapo/DetectorSpamBatePapoService.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/batepapo/RetencaoMensagemBatePapoService.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/batepapo/crypto/CriptografiaBatePapoService.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/batepapo/evento/EventoBatePapoConsumer.java"
    "src/main/java/br/tec/facilitaservicos/conexaodesorte/servico/batepapo/impl/MensagemBatePapoServiceImpl.java"
)

# Função para atualizar um arquivo
update_file() {
    local file=$1
    echo -e "\n${YELLOW}📝 Atualizando: $file${NC}"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        return 1
    fi
    
    # Backup do arquivo
    cp "$file" "$file.bak"
    
    # 1. Atualizar import
    sed -i '' 's/import br\.tec\.facilitaservicos\.conexaodesorte\.transversal\.metricas\.chat\.ChatMetricsRegistry;/import br.tec.facilitaservicos.conexaodesorte.transversal.metricas.chat.RegistroMetricasChat;/g' "$file"
    
    # 2. Atualizar declarações de variáveis
    sed -i '' 's/private final ChatMetricsRegistry/private final RegistroMetricasChat/g' "$file"
    sed -i '' 's/private ChatMetricsRegistry/private RegistroMetricasChat/g' "$file"
    
    # 3. Atualizar parâmetros de construtores
    sed -i '' 's/ChatMetricsRegistry metricsRegistry/RegistroMetricasChat metricsRegistry/g' "$file"
    sed -i '' 's/ChatMetricsRegistry metrics/RegistroMetricasChat metrics/g' "$file"
    
    # 4. Atualizar mensagens de validação
    sed -i '' 's/"ChatMetricsRegistry não pode ser null"/"RegistroMetricasChat não pode ser null"/g' "$file"
    
    # 5. Atualizar comentários
    sed -i '' 's/ChatMetricsRegistry/RegistroMetricasChat/g' "$file"
    
    echo -e "${GREEN}✅ Atualizado: $file${NC}"
}

# Atualizar cada arquivo
for file in "${files_to_update[@]}"; do
    update_file "$file"
done

echo -e "\n${GREEN}🎉 CONSOLIDAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${BLUE}📋 RESUMO DAS ALTERAÇÕES:${NC}"
echo -e "  ✅ ChatMetricsRegistry → RegistroMetricasChat"
echo -e "  ✅ Imports atualizados"
echo -e "  ✅ Declarações de variáveis atualizadas"
echo -e "  ✅ Parâmetros de construtores atualizados"
echo -e "  ✅ Mensagens de validação atualizadas"
echo -e "  ✅ Comentários atualizados"

echo -e "\n${YELLOW}📝 PRÓXIMOS PASSOS:${NC}"
echo -e "  1. Verificar se a compilação funciona"
echo -e "  2. Executar testes para garantir funcionalidade"
echo -e "  3. Fazer commit das alterações"

echo -e "\n${GREEN}✨ Consolidação seguindo padrões do projeto em português!${NC}"
