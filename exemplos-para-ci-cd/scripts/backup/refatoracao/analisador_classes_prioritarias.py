#!/usr/bin/env python3
"""
Script para analisar e priorizar classes com mais números mágicos.
"""

import re
from collections import defaultdict, Counter

# Dados dos números mágicos restantes
NUMEROS_MAGICOS_RESTANTES = """
ServicoValidacaoSenha.java:74:30: '64' é um número mágico. [MagicNumber]
ServicoValidacaoSenha.java:102:52: '64' é um número mágico. [MagicNumber]
ServicoValidacaoSenha.java:188:51: '40' é um número mágico. [MagicNumber]
ValidadorUsuarioServico.java:354:51: '11' é um número mágico. [MagicNumber]
GrupoDTO.java:134:57: '500' é um número mágico. [MagicNumber]
ConfiguracaoMonitoramentoIntegrado.java:334:31: '15.0' é um número mágico. [MagicNumber]
ServicoCache.java:389:65: '1_000_000' é um número mágico. [MagicNumber]
ConfiguracaoResiliencia.java:214:35: '40' é um número mágico. [MagicNumber]
ConfiguracaoResiliencia.java:263:39: '50' é um número mágico. [MagicNumber]
ServicoSegurancaProducao.java:174:23: '32' é um número mágico. [MagicNumber]
GerenciadorChavesCacheLRU.java:27:78: '0.75f' é um número mágico. [MagicNumber]
RegistradorSegurancaAprimorado.java:112:58: '50' é um número mágico. [MagicNumber]
ConfiguracaoAzureKeyVaultSpringCloud.java:189:69: '80' é um número mágico. [MagicNumber]
PropriedadesToken.java:257:91: '14' é um número mágico. [MagicNumber]
GeradorToken.java:43:49: '16' é um número mágico. [MagicNumber]
PropriedadesSeguranca.java:326:13: '50' é um número mágico. [MagicNumber]
ValidadorRecursos.java:40:37: '255' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoSimples.java:106:48: '0.7' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoSimples.java:106:74: '0.3' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoSimples.java:164:41: '30.0' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoSimples.java:168:55: '29.0' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:147:34: '0.7' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:171:52: '0.4' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:172:38: '0.3' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:173:32: '0.15' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:174:32: '0.15' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:251:31: '0.8' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:253:31: '0.5' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:329:52: '0.8' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:329:58: '0.8' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:436:52: '0.4' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:437:38: '0.3' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:438:32: '0.15' é um número mágico. [MagicNumber]
EstrategiaDetecaoComportamentoAvancada.java:439:32: '0.15' é um número mágico. [MagicNumber]
ServicoValidacaoEntrada.java:443:123: '1024' é um número mágico. [MagicNumber]
ServicoValidacaoEntrada.java:564:82: '32' é um número mágico. [MagicNumber]
ServicoValidacaoEntrada.java:564:92: '127' é um número mágico. [MagicNumber]
ServicoValidacaoEntrada.java:564:104: '159' é um número mágico. [MagicNumber]
MetricasToken.java:87:37: '0.5' é um número mágico. [MagicNumber]
MetricasToken.java:87:42: '0.95' é um número mágico. [MagicNumber]
MetricasToken.java:87:48: '0.99' é um número mágico. [MagicNumber]
MetricasToken.java:93:37: '0.5' é um número mágico. [MagicNumber]
MetricasToken.java:93:42: '0.95' é um número mágico. [MagicNumber]
MetricasToken.java:93:48: '0.99' é um número mágico. [MagicNumber]
ConfiguracaoAuditoriaPerformance.java:210:81: '50' é um número mágico. [MagicNumber]
ConfiguracaoAuditoriaPerformance.java:290:41: '0.1' é um número mágico. [MagicNumber]
ConfiguracaoGDPRCompliance.java:704:42: '15' é um número mágico. [MagicNumber]
ConfiguracaoGDPRCompliance.java:734:42: '25' é um número mágico. [MagicNumber]
AuditoriaAspecto.java:84:65: '500' é um número mágico. [MagicNumber]
AuditoriaAspecto.java:85:69: '500' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:52:46: '13' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:53:47: '15' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:54:45: '17' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:55:45: '18' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:55:49: '44' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:56:44: '20' é um número mágico. [MagicNumber]
ConfiguracaoHorarioValido.java:62:63: '13' é um número mágico. [MagicNumber]
AgendadorTarefas.java:80:44: '30' é um número mágico. [MagicNumber]
ServicoExportacao.java:79:79: '12' é um número mágico. [MagicNumber]
ServicoNotificacao.java:371:31: '255' é um número mágico. [MagicNumber]
ServicoNotificacaoAdmin.java:47:114: '60' é um número mágico. [MagicNumber]
ServicoNotificacaoAdmin.java:155:37: '3000' é um número mágico. [MagicNumber]
ServicoNotificacaoAdmin.java:260:44: '200' é um número mágico. [MagicNumber]
ExtratorResultadoPortalBrasil.java:64:26: '10_000' é um número mágico. [MagicNumber]
ExtratorResultadoLotomania.java:85:51: '20' é um número mágico. [MagicNumber]
ExtratorResultadoLotomania.java:88:46: '99' é um número mágico. [MagicNumber]
ExtratorResultadoLotomania.java:97:31: '20' é um número mágico. [MagicNumber]
ExtratorResultadoLoteca.java:109:59: '14' é um número mágico. [MagicNumber]
ExtratorResultadoLoteca.java:139:39: '14' é um número mágico. [MagicNumber]
ExtratorResultadoLoteca.java:197:34: '14' é um número mágico. [MagicNumber]
ServicoExtracaoLoteriaRefatorado.java:240:24: '30' é um número mágico. [MagicNumber]
ServicoExtracaoLoteriaRefatorado.java:294:42: '200' é um número mágico. [MagicNumber]
ExtratorResultadoDiaDeSorte.java:100:46: '31' é um número mágico. [MagicNumber]
ExtratorResultadoDiaDeSorte.java:203:42: '31' é um número mágico. [MagicNumber]
ServicoExtracaoLoteria.java:334:24: '30' é um número mágico. [MagicNumber]
ServicoExtracaoLoteria.java:388:42: '200' é um número mágico. [MagicNumber]
ServicoExtracaoLoteria.java:503:45: '60' é um número mágico. [MagicNumber]
GerenciadorHtmlProblematico.java:84:41: '1024' é um número mágico. [MagicNumber]
GerenciadorHtmlProblematico.java:85:51: '1024' é um número mágico. [MagicNumber]
GerenciadorHtmlProblematico.java:91:41: '1024' é um número mágico. [MagicNumber]
ExtratorResultadoDeuNoPosteRefatorado.java:67:26: '10_000' é um número mágico. [MagicNumber]
ExtratorResultadoOclick.java:47:26: '10_000' é um número mágico. [MagicNumber]
ExtratorResiliente.java:56:69: '30' é um número mágico. [MagicNumber]
ExtratorResultadoTimemania.java:98:46: '80' é um número mágico. [MagicNumber]
ExtratorResultadoTimemania.java:203:42: '80' é um número mágico. [MagicNumber]
ExtratorResultadoLotofacil.java:171:31: '15' é um número mágico. [MagicNumber]
ExtratorResultadoLotofacil.java:180:42: '25' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:167:52: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:167:56: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:171:56: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:171:60: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:175:52: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:175:56: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:178:52: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:178:56: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:182:56: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:182:60: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:186:56: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:186:60: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:189:52: '19' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:189:56: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:192:52: '11' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:192:56: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:196:56: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:196:60: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:200:56: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:200:60: '30' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:203:52: '20' é um número mágico. [MagicNumber]
OrquestradorExtracoes.java:203:56: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:379:64: '15' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:392:50: '200' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:983:56: '15' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:996:42: '200' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:1068:54: '200' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:1206:29: '31' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:1207:28: '11' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:1208:24: '41' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:1222:45: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultado.java:1224:49: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:677:26: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:678:25: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:679:30: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:680:31: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:681:29: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:682:29: '15' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:683:28: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:684:31: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:685:24: '30' é um número mágico. [MagicNumber]
ServicoExtracaoResultadoRefatorado.java:742:49: '30' é um número mágico. [MagicNumber]
ExtratorResultadoQuina.java:97:46: '80' é um número mágico. [MagicNumber]
ExtratorResultadoQuina.java:178:42: '80' é um número mágico. [MagicNumber]
ServicoRefreshToken.java:272:33: '32' é um número mágico. [MagicNumber]
ValidadorCPFRefatorado.java:78:46: '11' é um número mágico. [MagicNumber]
ServicoCriptografiaAES.java:193:60: '16' é um número mágico. [MagicNumber]
ServicoCriptografiaAES.java:257:47: '32' é um número mágico. [MagicNumber]
ServicoCriptografiaAES.java:292:57: '32' é um número mágico. [MagicNumber]
ServicoExtracaoLoteria.java:74:26: '307' é um número mágico. [MagicNumber]
ServicoExtracaoLoteria.java:74:43: '308' é um número mágico. [MagicNumber]
ValidadorUsuario.java:267:46: '11' é um número mágico. [MagicNumber]
ValidadorUsuarioRefatorado.java:274:65: '11' é um número mágico. [MagicNumber]
LocalizadorIdChatTelegram.java:47:44: '200' é um número mágico. [MagicNumber]
UtilidadesConsolidadas.java:421:61: '2000L' é um número mágico. [MagicNumber]
GeradorTokens.java:241:50: '0xff' é um número mágico. [MagicNumber]
RespostaErroUtil.java:170:18: '400' é um número mágico. [MagicNumber]
RespostaErroUtil.java:171:18: '401' é um número mágico. [MagicNumber]
RespostaErroUtil.java:172:18: '403' é um número mágico. [MagicNumber]
RespostaErroUtil.java:173:18: '404' é um número mágico. [MagicNumber]
RespostaErroUtil.java:174:18: '422' é um número mágico. [MagicNumber]
RespostaErroUtil.java:175:18: '500' é um número mágico. [MagicNumber]
ValidadorAuditoria.java:67:88: '50' é um número mágico. [MagicNumber]
CpfEncryptionConverter.java:145:91: '11' é um número mágico. [MagicNumber]
CpfEncryptionConverter.java:158:69: '11' é um número mágico. [MagicNumber]
CpfEncryptionConverter.java:160:90: '11' é um número mágico. [MagicNumber]
EmailEncryptionConverter.java:114:30: '254' é um número mágico. [MagicNumber]
Grupo.java:606:51: '128' é um número mágico. [MagicNumber]
UsuarioSeguranca.java:116:102: '3600' é um número mágico. [MagicNumber]
Visualizacao.java:115:41: '50' é um número mágico. [MagicNumber]
Visualizacao.java:233:27: '255' é um número mágico. [MagicNumber]
Visualizacao.java:240:51: '39' é um número mágico. [MagicNumber]
Visualizacao.java:283:37: '50' é um número mágico. [MagicNumber]
TokenRevogado.java:147:74: '24' é um número mágico. [MagicNumber]
Notificacao.java:76:35: '200' é um número mágico. [MagicNumber]
Notificacao.java:224:31: '200' é um número mágico. [MagicNumber]
Notificacao.java:305:48: '50' é um número mágico. [MagicNumber]
Notificacao.java:305:75: '47' é um número mágico. [MagicNumber]
Auditoria.java:340:38: '256' é um número mágico. [MagicNumber]
TipoItem.java:379:35: '50' é um número mágico. [MagicNumber]
TipoItem.java:385:61: '255' é um número mágico. [MagicNumber]
TipoItem.java:388:53: '50' é um número mágico. [MagicNumber]
EventoAuditoria.java:484:59: '500' é um número mágico. [MagicNumber]
EventoAuditoria.java:485:50: '500' é um número mágico. [MagicNumber]
TipoAnexo.java:175:38: '1024.0' é um número mágico. [MagicNumber]
TipoAnexo.java:175:47: '1024.0' é um número mágico. [MagicNumber]
TipoAnexo.java:336:73: '1024' é um número mágico. [MagicNumber]
TipoAnexo.java:337:53: '1024.0' é um número mágico. [MagicNumber]
TipoAnexo.java:338:118: '1024' é um número mágico. [MagicNumber]
TipoAnexo.java:339:54: '1024.0' é um número mágico. [MagicNumber]
TipoAnexo.java:339:63: '1024' é um número mágico. [MagicNumber]
TipoAnexo.java:341:54: '1024.0' é um número mágico. [MagicNumber]
TipoAnexo.java:341:108: '1024' é um número mágico. [MagicNumber]
SessaoUsuario.java:760:55: '256' é um número mágico. [MagicNumber]
CodigoVerificacao.java:176:53: '1000000' é um número mágico. [MagicNumber]
CodigoVerificacao.java:201:43: '24' é um número mágico. [MagicNumber]
CodigoVerificacao.java:202:51: '30' é um número mágico. [MagicNumber]
CodigoVerificacao.java:345:50: '128' é um número mágico. [MagicNumber]
TipoConversa.java:207:24: '50' é um número mágico. [MagicNumber]
Modalidade.java:441:61: '255' é um número mágico. [MagicNumber]
ItemModalidade.java:109:42: '50' é um número mágico. [MagicNumber]
ItemModalidade.java:274:42: '50' é um número mágico. [MagicNumber]
Endereco.java:188:75: '50' é um número mágico. [MagicNumber]
Endereco.java:192:87: '150' é um número mágico. [MagicNumber]
Endereco.java:492:63: '50' é um número mágico. [MagicNumber]
Endereco.java:495:75: '150' é um número mágico. [MagicNumber]
Papel.java:420:51: '128' é um número mágico. [MagicNumber]
Anexo.java:621:55: '256' é um número mágico. [MagicNumber]
"""

def analisar_classes_prioritarias():
    """Analisa e prioriza classes por número de ocorrências."""
    linhas = [linha.strip() for linha in NUMEROS_MAGICOS_RESTANTES.strip().split('\n') if linha.strip()]
    
    # Conta ocorrências por classe
    classes_count = defaultdict(list)
    
    for linha in linhas:
        # Extrai nome da classe
        match = re.match(r"([^:]+\.java):", linha)
        if match:
            classe = match.group(1)
            # Extrai o número mágico
            numero_match = re.search(r"'([^']+)' é um número mágico", linha)
            if numero_match:
                numero = numero_match.group(1)
                classes_count[classe].append(numero)
    
    # Ordena por número de ocorrências (decrescente)
    classes_ordenadas = sorted(classes_count.items(), key=lambda x: len(x[1]), reverse=True)
    
    print("🎯 PRIORIZAÇÃO DE CLASSES POR NÚMERO DE OCORRÊNCIAS")
    print("=" * 70)
    
    total_numeros = sum(len(numeros) for numeros in classes_count.values())
    print(f"📊 Total de números mágicos restantes: {total_numeros}")
    print(f"📁 Total de classes afetadas: {len(classes_count)}")
    
    print("\n🏆 TOP 20 CLASSES COM MAIS NÚMEROS MÁGICOS:")
    print("-" * 70)
    
    for i, (classe, numeros) in enumerate(classes_ordenadas[:20], 1):
        numeros_unicos = len(set(numeros))
        numeros_str = ", ".join(sorted(set(numeros)))
        print(f"{i:2d}. {classe:<40} | {len(numeros):2d} ocorrências ({numeros_unicos} únicos)")
        print(f"    Números: {numeros_str}")
        print()
    
    return classes_ordenadas

def gerar_plano_refatoracao(classes_ordenadas):
    """Gera plano de refatoração estruturado."""
    print("\n📋 PLANO DE REFATORAÇÃO ESTRUTURADO")
    print("=" * 70)
    
    # Agrupa classes por domínio/categoria
    dominios = {
        'loteria': ['Extrator', 'ServicoExtracao', 'Orquestrador'],
        'seguranca': ['Validador', 'Servico', 'Configuracao', 'Token', 'Criptografia'],
        'entidades': ['.java'],  # Entidades JPA
        'configuracao': ['Configuracao'],
        'auditoria': ['Auditoria'],
        'outros': []
    }
    
    classes_por_dominio = defaultdict(list)
    
    for classe, numeros in classes_ordenadas:
        categorizado = False
        for dominio, palavras_chave in dominios.items():
            if dominio == 'outros':
                continue
            for palavra in palavras_chave:
                if palavra in classe:
                    classes_por_dominio[dominio].append((classe, numeros))
                    categorizado = True
                    break
            if categorizado:
                break
        
        if not categorizado:
            classes_por_dominio['outros'].append((classe, numeros))
    
    # Plano por fases
    print("\n🚀 FASES DE REFATORAÇÃO:")
    
    fase = 1
    for dominio, classes in classes_por_dominio.items():
        if not classes:
            continue
            
        print(f"\n📌 FASE {fase}: {dominio.upper()}")
        print(f"   Classes: {len(classes)}")
        print(f"   Números mágicos: {sum(len(nums) for _, nums in classes)}")
        
        for i, (classe, numeros) in enumerate(classes[:5], 1):  # Top 5 por domínio
            print(f"   {i}. {classe} ({len(numeros)} números)")
        
        if len(classes) > 5:
            print(f"   ... e mais {len(classes) - 5} classes")
        
        fase += 1

def main():
    """Função principal."""
    classes_ordenadas = analisar_classes_prioritarias()
    gerar_plano_refatoracao(classes_ordenadas)
    
    print(f"\n🎯 PRÓXIMOS PASSOS:")
    print("1. Começar com as classes que têm mais números mágicos")
    print("2. Criar constantes específicas para cada domínio")
    print("3. Refatorar uma classe por vez para manter controle")
    print("4. Testar compilação após cada refatoração")

if __name__ == "__main__":
    main()
