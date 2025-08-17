# ⚠️ BACKUP OBSOLETO - Arquivos de Roteamento Conflitantes

> **AVISO IMPORTANTE**: Esta pasta contém configurações OBSOLETAS e NÃO DEVE SER USADA na infraestrutura atual.
> 
> ❌ **NÃO USE** estes arquivos para configuração atual  
> ✅ **USE** as configurações em `/config/` e `/dynamic/` na raiz do projeto

Esta pasta contém arquivos que foram identificados como conflitantes com o roteamento centralizado do Traefik e foram movidos dos projetos individuais para evitar problemas de configuração.

## Arquivos Movidos

### Backend (conexao-de-sorte-backend-backup)
- `backend-docker-compose.prod.yml` - Continha labels do Traefik para roteamento
- `backend-docker-compose.dev.yml` - Continha labels do Traefik para desenvolvimento
- `backend-traefik-dockerfiles/` - Diretório com Dockerfile e configurações do Traefik

### Frontend (conexao-de-sorte-frontend)
- `frontend-deploy-vps.sh` - Script com labels do Traefik hardcoded
- `frontend-docker-compose.yml` - Arquivo docker-compose com possíveis configurações conflitantes

## Motivo da Movimentação

Estes arquivos continham configurações de roteamento que poderiam:
1. Conflitar com o roteamento centralizado
2. Causar problemas durante deploys individuais dos projetos
3. Sobrescrever configurações do proxy centralizado

## ✅ Roteamento Atual (Centralizado)

O roteamento agora é gerenciado centralmente através dos arquivos:
- `config/traefik.yml` - Configuração principal do Traefik
- `dynamic/services.yml` - Definições de rotas e serviços  
- `dynamic/middlewares.yml` - Middlewares de segurança e processamento
- `docker-compose.yml` - Configuração do proxy Traefik

### Rotas Configuradas
- `conexaodesorte.com.br` e `www.conexaodesorte.com.br` → Frontend
- `conexaodesorte.com.br/rest` e `www.conexaodesorte.com.br/rest` → Backend API
- `conexaodesorte.com.br/teste/rest` e `www.conexaodesorte.com.br/teste/rest` → Backend de Teste
- `conexaodesorte.com.br/teste/frete` e `www.conexaodesorte.com.br/teste/frete` → Fretes Website

## Próximos Passos

Os projetos individuais devem ser atualizados para:
1. Remover labels do Traefik dos docker-compose
2. Usar apenas a rede `conexao-network` como externa
3. Expor apenas as portas necessárias para comunicação interna

## 🔄 Status da Infraestrutura Atual

- ✅ **Traefik**: Funcionando corretamente
- ✅ **Conectividade**: Backend e Frontend conectados
- ✅ **Rede Docker**: `conexao-network` ativa
- ⚠️ **SSL**: Certificados em processo de renovação
- ✅ **API Traefik**: Acessível na porta 8090
- ✅ **Diagnósticos**: Automatizados via GitHub Actions

---
*Backup criado em: Dezembro 2024*  
*Última atualização: Janeiro 2025*