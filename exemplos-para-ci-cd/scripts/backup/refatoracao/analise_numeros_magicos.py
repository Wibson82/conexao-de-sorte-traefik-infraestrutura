#!/usr/bin/env python3
"""
Script para análise e categorização dos 342 números mágicos restantes.
Extrai informações do output do Maven compile e categoriza por tipo.
"""

import re
import json
from collections import defaultdict, Counter
from pathlib import Path

# Dados extraídos do Maven compile output
NUMEROS_MAGICOS_RAW = """
'256' é um número mágico - AutenticacaoResponseDTO.java:87:51
'256' é um número mágico - UsuarioResponseDTO.java:267:51
'30' é um número mágico - ControladorUsuario.java:217:58
'64' é um número mágico - ServicoValidacaoSenha.java:73:30
'64' é um número mágico - ServicoValidacaoSenha.java:101:52
'40' é um número mágico - ServicoValidacaoSenha.java:187:51
'15' é um número mágico - ServicoValidacaoSenha.java:193:57
'15' é um número mágico - ServicoValidacaoSenha.java:197:26
'30' é um número mágico - ServicoSegurancaUsuario.java:72:17
'30' é um número mágico - ServicoSegurancaUsuario.java:72:21
'11' é um número mágico - ValidadorUsuarioServico.java:343:28
'11' é um número mágico - ValidadorUsuarioServico.java:344:35
'11' é um número mágico - ValidadorUsuarioServico.java:353:51
'11' é um número mágico - ValidadorUsuarioServico.java:356:24
'11' é um número mágico - ValidadorUsuarioServico.java:357:35
'12' é um número mágico - ValidadorUsuarioServico.java:431:31
'60' é um número mágico - UsuarioAutenticacaoServico.java:250:82
'30' é um número mágico - UsuarioAutenticacaoServico.java:437:49
'500' é um número mágico - GrupoDTO.java:134:57
'10000' é um número mágico - MapeadorUsuarioBase.java:305:54
'1000000' é um número mágico - MapeadorCodigoVerificacao.java:200:79
'60' é um número mágico - ConfiguracaoMonitoramentoIntegrado.java:258:27
'15.0' é um número mágico - ConfiguracaoMonitoramentoIntegrado.java:333:31
'500' é um número mágico - CorretorIndiceTokenRefresh.java:128:31
'1_000_000' é um número mágico - ServicoMonitoramentoCacheConsolidado.java:150:37
'1_000_000' é um número mágico - ServicoMonitoramentoCacheConsolidado.java:151:42
'1_000_000.0' é um número mágico - ServicoCache.java:376:63
'1_000_000' é um número mágico - ServicoCache.java:388:65
'30' é um número mágico - HistoricoSenhaCache.java:258:30
'20' é um número mágico - ConfiguracaoResiliencia.java:159:33
'500' é um número mágico - ConfiguracaoResiliencia.java:160:48
'30' é um número mágico - ConfiguracaoResiliencia.java:173:35
'40' é um número mágico - ConfiguracaoResiliencia.java:212:35
'50' é um número mágico - ConfiguracaoResiliencia.java:261:39
'32' é um número mágico - ServicoSegurancaProducao.java:174:23
'600000' é um número mágico - ConfiguracaoDataSource.java:258:31
'1800000' é um número mágico - ConfiguracaoDataSource.java:259:31
'20' é um número mágico - ConfiguracaoDataSource.java:271:39
'0.75f' é um número mágico - GerenciadorChavesCacheLRU.java:27:78
'50' é um número mágico - RegistradorSegurancaAprimorado.java:111:58
'45' é um número mágico - RegistradorSegurancaAprimorado.java:145:64
'30' é um número mágico - ConfiguracaoAzureKeyVaultSpringCloud.java:46:49
'80' é um número mágico - ConfiguracaoAzureKeyVaultSpringCloud.java:188:69
'30' é um número mágico - AzureKeyVaultProperties.java:69:36
'30' é um número mágico - AzureKeyVaultProperties.java:77:36
'20' é um número mágico - AzureKeyVaultProperties.java:200:55
'300_000' é um número mágico - PropriedadesConfiguracao.java:171:20
'60' é um número mágico - PropriedadesConfiguracao.java:185:32
'60' é um número mágico - PropriedadesConfiguracao.java:188:32
'60' é um número mágico - PropriedadesConfiguracao.java:188:37
'24' é um número mágico - PropriedadesConfiguracao.java:191:32
'60' é um número mágico - PropriedadesConfiguracao.java:191:37
'60' é um número mágico - PropriedadesConfiguracao.java:191:42
'300_000' é um número mágico - PropriedadesConfiguracao.java:197:20
'300' é um número mágico - PropriedadesToken.java:116:13
'30' é um número mágico - PropriedadesToken.java:119:37
'300' é um número mágico - PropriedadesToken.java:233:13
'30' é um número mágico - PropriedadesToken.java:236:37
'24' é um número mágico - PropriedadesToken.java:247:30
'30' é um número mágico - PropriedadesToken.java:248:29
'600' é um número mágico - PropriedadesToken.java:253:13
'90' é um número mágico - PropriedadesToken.java:256:37
'14' é um número mágico - PropriedadesToken.java:256:41
'16' é um número mágico - GeradorToken.java:42:49
'60' é um número mágico - GeradorToken.java:125:76
'50' é um número mágico - PropriedadesSeguranca.java:326:13
'255' é um número mágico - ValidadorRecursos.java:40:37
'3600L' é um número mágico - ConfiguracaoSegurancaHealth.java:72:32
'429' é um número mágico - FiltroLimiteRequisicoes.java:245:32
'429' é um número mágico - FiltroLimiteRequisicoes.java:287:32
'429' é um número mágico - FiltroLimiteRequisicoes.java:336:32
'10000' é um número mágico - ConfiguracaoFiltrosUnificada.java:264:36
'600' é um número mágico - ProvedorUrlPagina.java:53:32
'3600' é um número mágico - ProvedorUrlPagina.java:54:37
'1800' é um número mágico - ProvedorUrlPagina.java:55:39
'86400' é um número mágico - ProvedorUrlPagina.java:56:42
'86400' é um número mágico - ProvedorUrlPagina.java:57:52
'31536000' é um número mágico - ConfiguracaoSegurancaOAuth2.java:208:50
'401' é um número mágico - ConfiguracaoSegurancaOAuth2.java:214:48
'403' é um número mágico - ConfiguracaoSegurancaOAuth2.java:221:48
'2048' é um número mágico - ConfiguracaoSegurancaOAuth2.java:313:35
'2048' é um número mágico - ConfiguracaoSegurancaOAuth2.java:341:35
'0.7' é um número mágico - EstrategiaDetecaoComportamentoSimples.java:106:48
'0.3' é um número mágico - EstrategiaDetecaoComportamentoSimples.java:106:74
'30.0' é um número mágico - EstrategiaDetecaoComportamentoSimples.java:164:41
'29.0' é um número mágico - EstrategiaDetecaoComportamentoSimples.java:168:55
'0.7' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:147:34
'0.4' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:171:52
'0.3' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:172:38
'0.15' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:173:32
'0.15' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:174:32
'0.8' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:251:31
'0.5' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:253:31
'0.8' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:329:52
'0.8' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:329:58
'0.4' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:436:52
'0.3' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:437:38
'0.15' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:438:32
'0.15' é um número mágico - EstrategiaDetecaoComportamentoAvancada.java:439:32
'3600L' é um número mágico - ConfiguracaoCorsSimplifcada.java:67:33
'3600L' é um número mágico - ConfiguracaoCorsSimplifcada.java:90:33
'3600' é um número mágico - PropriedadesCors.java:77:17
'3600' é um número mágico - PropriedadesCors.java:91:17
'1024' é um número mágico - ServicoValidacaoEntrada.java:442:78
'1024' é um número mágico - ServicoValidacaoEntrada.java:442:85
'32' é um número mágico - ServicoValidacaoEntrada.java:563:82
'127' é um número mágico - ServicoValidacaoEntrada.java:563:92
'159' é um número mágico - ServicoValidacaoEntrada.java:563:104
'120' é um número mágico - PropriedadesLimites.java:134:13
'20' é um número mágico - PropriedadesLimites.java:140:13
'60' é um número mágico - PropriedadesLimites.java:154:13
'30' é um número mágico - PropriedadesLimites.java:157:13
'15' é um número mágico - PropriedadesLimites.java:159:13
'20' é um número mágico - PropriedadesLimites.java:161:13
'500' é um número mágico - PropriedadesLimites.java:177:13
'60' é um número mágico - PropriedadesLimites.java:179:13
'200' é um número mágico - PropriedadesLimites.java:180:13
'500' é um número mágico - PropriedadesLimites.java:181:13
'0.5' é um número mágico - MetricasToken.java:87:37
'0.95' é um número mágico - MetricasToken.java:87:42
'0.99' é um número mágico - MetricasToken.java:87:48
'0.5' é um número mágico - MetricasToken.java:93:37
'0.95' é um número mágico - MetricasToken.java:93:42
'0.99' é um número mágico - MetricasToken.java:93:48
'80' é um número mágico - ExtratorResultadoQuina.java:97:46
'80' é um número mágico - ExtratorResultadoQuina.java:178:42
'10_000' é um número mágico - ExtratorResultadoDeuNoPoste.java:64:26
'24' é um número mágico - ServicoExtracaoRefatorado.java:94:17
'30' é um número mágico - ServicoExtracaoRefatorado.java:102:87
'60' é um número mágico - ExtratorResultadoMegaSena.java:87:46
'60' é um número mágico - ExtratorResultadoMegaSena.java:148:42
'32' é um número mágico - ServicoRefreshToken.java:272:33
'18' é um número mágico - ValidadorCriacaoUsuario.java:66:25
'11' é um número mágico - ValidadorCPFRefatorado.java:67:28
'11' é um número mágico - ValidadorCPFRefatorado.java:68:35
'11' é um número mágico - ValidadorCPFRefatorado.java:77:46
'11' é um número mágico - ValidadorCPFRefatorado.java:80:24
'11' é um número mágico - ValidadorCPFRefatorado.java:81:35
'16' é um número mágico - ServicoCriptografiaAES.java:193:60
'32' é um número mágico - ServicoCriptografiaAES.java:257:47
'32' é um número mágico - ServicoCriptografiaAES.java:292:57
'307' é um número mágico - ServicoExtracaoLoteria.java:74:26
'308' é um número mágico - ServicoExtracaoLoteria.java:74:43
'24' é um número mágico - FalhaAutenticacaoRepositorio.java:80:71
'24' é um número mágico - FalhaAutenticacaoRepositorio.java:151:48
'90' é um número mágico - SessaoUsuarioRepositorio.java:777:42
'11' é um número mágico - ValidadorUsuario.java:256:28
'11' é um número mágico - ValidadorUsuario.java:257:37
'11' é um número mágico - ValidadorUsuario.java:266:46
'11' é um número mágico - ValidadorUsuario.java:268:24
'11' é um número mágico - ValidadorUsuario.java:269:37
'12' é um número mágico - ValidadorUsuario.java:371:31
'11' é um número mágico - ValidadorUsuarioRefatorado.java:252:29
'11' é um número mágico - ValidadorUsuarioRefatorado.java:266:28
'11' é um número mágico - ValidadorUsuarioRefatorado.java:267:39
'11' é um número mágico - ValidadorUsuarioRefatorado.java:272:65
'11' é um número mágico - ValidadorUsuarioRefatorado.java:274:24
'11' é um número mágico - ValidadorUsuarioRefatorado.java:275:39
'20' é um número mágico - ValidadorUsuarioRefatorado.java:375:22
'20' é um número mágico - ValidadorUsuarioRefatorado.java:378:22
'15' é um número mágico - ValidadorUsuarioRefatorado.java:383:22
'15' é um número mágico - ValidadorUsuarioRefatorado.java:386:22
'15' é um número mágico - ValidadorUsuarioRefatorado.java:389:22
'15' é um número mágico - ValidadorUsuarioRefatorado.java:392:22
'200' é um número mágico - LocalizadorIdChatTelegram.java:46:44
'200' é um número mágico - HttpFetcher.java:88:31
'300' é um número mágico - HttpFetcher.java:88:51
'2000L' é um número mágico - UtilidadesConsolidadas.java:421:61
'60' é um número mágico - GeradorTokens.java:144:76
'0xff' é um número mágico - GeradorTokens.java:240:50
'200' é um número mágico - ConstantesHTTP.java:249:30
'300' é um número mágico - ConstantesHTTP.java:249:50
'300' é um número mágico - ConstantesHTTP.java:256:30
'400' é um número mágico - ConstantesHTTP.java:256:50
'400' é um número mágico - ConstantesHTTP.java:263:30
'500' é um número mágico - ConstantesHTTP.java:263:50
'500' é um número mágico - ConstantesHTTP.java:270:30
'600' é um número mágico - ConstantesHTTP.java:270:50
'400' é um número mágico - ConstantesHTTP.java:277:30
'999' é um número mágico - ConstantesAutorizacao.java:267:24
'1000000' é um número mágico - CorretorProblemasSpotBugs.java:47:60
'50' é um número mágico - ValidadorAuditoria.java:67:88
'90' é um número mágico - ServicoAuditoria.java:509:33
'30' é um número mágico - ServicoAuditoria.java:518:75
'60' é um número mágico - ServicoAuditoria.java:523:88
'60' é um número mágico - ServicoProcessadorEventosAuditoria.java:84:51
'24' é um número mágico - ServicoEstatisticaAuditoria.java:277:39
'11' é um número mágico - CpfEncryptionConverter.java:129:44
'11' é um número mágico - CpfEncryptionConverter.java:144:34
'11' é um número mágico - CpfEncryptionConverter.java:144:47
'11' é um número mágico - CpfEncryptionConverter.java:157:69
'11' é um número mágico - CpfEncryptionConverter.java:159:33
'11' é um número mágico - CpfEncryptionConverter.java:159:46
'11' é um número mágico - CpfEncryptionConverter.java:181:44
'11' é um número mágico - CpfEncryptionConverter.java:189:34
'11' é um número mágico - CpfEncryptionConverter.java:199:43
'11' é um número mágico - CpfEncryptionConverter.java:204:40
'11' é um número mágico - CpfEncryptionConverter.java:211:45
'11' é um número mágico - TelefoneEncryptionConverter.java:99:68
'11' é um número mágico - TelefoneEncryptionConverter.java:193:34
'11' é um número mágico - TelefoneEncryptionConverter.java:198:39
'11' é um número mágico - TelefoneEncryptionConverter.java:225:45
'11' é um número mágico - TelefoneEncryptionConverter.java:230:50
'254' é um número mágico - EmailEncryptionConverter.java:114:30
'128' é um número mágico - Grupo.java:606:51
'3600' é um número mágico - UsuarioSeguranca.java:116:102
'50' é um número mágico - Visualizacao.java:115:41
'255' é um número mágico - Visualizacao.java:233:27
'39' é um número mágico - Visualizacao.java:240:51
'50' é um número mágico - Visualizacao.java:283:37
'24' é um número mágico - TokenRevogado.java:147:74
'200' é um número mágico - Notificacao.java:76:35
'200' é um número mágico - Notificacao.java:224:31
'50' é um número mágico - Notificacao.java:305:48
'47' é um número mágico - Notificacao.java:305:75
'256' é um número mágico - Auditoria.java:340:38
'50' é um número mágico - TipoItem.java:379:35
'255' é um número mágico - TipoItem.java:385:61
'50' é um número mágico - TipoItem.java:388:53
'500' é um número mágico - EventoAuditoria.java:484:59
'500' é um número mágico - EventoAuditoria.java:485:50
'1024.0' é um número mágico - TipoAnexo.java:175:38
'1024.0' é um número mágico - TipoAnexo.java:175:47
'1024' é um número mágico - TipoAnexo.java:334:21
'1024' é um número mágico - TipoAnexo.java:336:28
'1024' é um número mágico - TipoAnexo.java:336:35
'1024.0' é um número mágico - TipoAnexo.java:337:53
'1024' é um número mágico - TipoAnexo.java:338:28
'1024' é um número mágico - TipoAnexo.java:338:35
'1024' é um número mágico - TipoAnexo.java:338:42
'1024.0' é um número mágico - TipoAnexo.java:339:54
'1024' é um número mágico - TipoAnexo.java:339:63
'1024.0' é um número mágico - TipoAnexo.java:341:54
'1024' é um número mágico - TipoAnexo.java:341:63
'1024' é um número mágico - TipoAnexo.java:341:70
'256' é um número mágico - SessaoUsuario.java:760:55
'1000000' é um número mágico - CodigoVerificacao.java:176:53
'24' é um número mágico - CodigoVerificacao.java:201:43
'30' é um número mágico - CodigoVerificacao.java:202:51
'128' é um número mágico - CodigoVerificacao.java:345:50
'50' é um número mágico - TipoConversa.java:205:24
'1024' é um número mágico - TipoConversa.java:205:29
'1024' é um número mágico - TipoConversa.java:205:36
'1024' é um número mágico - TipoConversa.java:208:30
'1024' é um número mágico - TipoConversa.java:208:37
'20' é um número mágico - TipoConversa.java:211:24
'1024' é um número mágico - TipoConversa.java:211:29
'1024' é um número mágico - TipoConversa.java:211:36
'255' é um número mágico - Modalidade.java:441:61
'50' é um número mágico - ItemModalidade.java:109:42
'50' é um número mágico - ItemModalidade.java:274:42
'50' é um número mágico - Endereco.java:188:75
'150' é um número mágico - Endereco.java:192:87
'50' é um número mágico - Endereco.java:492:63
'150' é um número mágico - Endereco.java:495:75
'128' é um número mágico - Papel.java:420:51
'256' é um número mágico - Anexo.java:621:55
"""

def extrair_numeros_magicos():
    """Extrai e categoriza os números mágicos do output do Maven."""
    linhas = [linha.strip() for linha in NUMEROS_MAGICOS_RAW.strip().split('\n') if linha.strip()]
    
    numeros_magicos = []
    for linha in linhas:
        # Padrão: 'NUMERO' é um número mágico - ARQUIVO.java:LINHA:COLUNA
        match = re.match(r"'([^']+)' é um número mágico - ([^:]+):(\d+):(\d+)", linha)
        if match:
            numero, arquivo, linha_num, coluna = match.groups()
            numeros_magicos.append({
                'numero': numero,
                'arquivo': arquivo,
                'linha': int(linha_num),
                'coluna': int(coluna),
                'linha_completa': linha
            })
    
    return numeros_magicos

def categorizar_numeros(numeros_magicos):
    """Categoriza os números mágicos por tipo e domínio."""
    categorias = {
        'documentos_brasil': [],      # 11, 12 (CPF, CNPJ, telefone)
        'timeouts_duracao': [],       # 15, 30, 60, 300, 600, 1800, 3600, 86400
        'tamanhos_memoria': [],       # 1024, 10000, 1000000, 256, 128
        'codigos_http': [],           # 200, 300, 400, 401, 403, 404, 429, 500
        'percentuais': [],            # 0.1, 0.15, 0.3, 0.4, 0.5, 0.7, 0.8, 0.95, 0.99
        'criptografia': [],           # 16, 32, 64
        'regras_loteria': [],         # 80, 60 (números específicos de jogos)
        'limites_campos': [],         # 50, 150, 200, 254, 255
        'outros': []
    }
    
    # Mapeamento de números para categorias
    mapeamento = {
        'documentos_brasil': ['11', '12', '18'],
        'timeouts_duracao': ['15', '20', '24', '30', '45', '60', '90', '120', '300', '600', '1800', '3600', '3600L', '86400', '31536000', '300_000', '600000', '1800000'],
        'tamanhos_memoria': ['128', '256', '500', '1024', '1024.0', '2048', '10000', '10_000', '1000000', '1_000_000', '1_000_000.0'],
        'codigos_http': ['200', '300', '307', '308', '400', '401', '403', '404', '429', '500', '999'],
        'percentuais': ['0.15', '0.3', '0.4', '0.5', '0.7', '0.75f', '0.8', '0.95', '0.99', '15.0', '29.0', '30.0'],
        'criptografia': ['16', '32', '64', '127', '159', '0xff'],
        'regras_loteria': ['14', '39', '47', '60', '80'],
        'limites_campos': ['40', '50', '150', '200', '254', '255']
    }
    
    for numero_info in numeros_magicos:
        numero = numero_info['numero']
        categorizado = False
        
        for categoria, valores in mapeamento.items():
            if numero in valores:
                categorias[categoria].append(numero_info)
                categorizado = True
                break
        
        if not categorizado:
            categorias['outros'].append(numero_info)
    
    return categorias

def gerar_estatisticas(categorias):
    """Gera estatísticas das categorias."""
    stats = {}
    total = 0
    
    for categoria, items in categorias.items():
        count = len(items)
        total += count
        
        # Conta ocorrências por número
        numeros_count = Counter(item['numero'] for item in items)
        
        stats[categoria] = {
            'total': count,
            'numeros_unicos': len(numeros_count),
            'mais_frequentes': numeros_count.most_common(5),
            'arquivos_afetados': len(set(item['arquivo'] for item in items))
        }
    
    stats['total_geral'] = total
    return stats

def main():
    """Função principal."""
    print("🔍 ANALISANDO 342 NÚMEROS MÁGICOS RESTANTES...")
    
    numeros_magicos = extrair_numeros_magicos()
    print(f"📊 Total extraído: {len(numeros_magicos)} números mágicos")
    
    categorias = categorizar_numeros(numeros_magicos)
    stats = gerar_estatisticas(categorias)
    
    print("\n📋 CATEGORIZAÇÃO POR DOMÍNIO:")
    print("=" * 60)
    
    for categoria, info in stats.items():
        if categoria == 'total_geral':
            continue
            
        print(f"\n🏷️  {categoria.upper().replace('_', ' ')}")
        print(f"   Total: {info['total']} ocorrências")
        print(f"   Números únicos: {info['numeros_unicos']}")
        print(f"   Arquivos afetados: {info['arquivos_afetados']}")
        print(f"   Mais frequentes: {info['mais_frequentes']}")
    
    print(f"\n🎯 TOTAL GERAL: {stats['total_geral']} números mágicos")
    
    # Salva dados para scripts de refatoração
    with open('scripts/refatoracao/numeros_magicos_categorizados.json', 'w', encoding='utf-8') as f:
        json.dump({
            'categorias': categorias,
            'estatisticas': stats,
            'total': len(numeros_magicos)
        }, f, indent=2, ensure_ascii=False)
    
    print("\n💾 Dados salvos em: scripts/refatoracao/numeros_magicos_categorizados.json")

if __name__ == "__main__":
    main()
