#!/usr/bin/env python3
"""
Script simplificado para refatoração em massa de números mágicos.
Usa substituições diretas e seguras.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Set

class RefatoradorSimples:
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.src_path = self.base_path / "src" / "main" / "java"
        
        # Configurações por categoria
        self.configuracoes = {
            'documentos_brasil': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.negocio.ConstantesDocumentosBrasil;',
                'mapeamento': {
                    '11': 'ConstantesDocumentosBrasil.CPF.TAMANHO_DIGITOS',
                    '12': 'ConstantesDocumentosBrasil.CNPJ.TAMANHO_DIGITOS',
                    '18': 'ConstantesDocumentosBrasil.Demografico.IDADE_MINIMA_CADASTRO'
                }
            },
            'tamanhos_memoria': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.infraestrutura.ConstantesMemoria;',
                'mapeamento': {
                    '1024': 'ConstantesMemoria.Buffer.SIZE_XLARGE_BYTES',
                    '1024.0': 'ConstantesMemoria.Buffer.SIZE_XLARGE_BYTES',
                    '256': 'ConstantesMemoria.Buffer.SIZE_LARGE_BYTES',
                    '128': 'ConstantesMemoria.Buffer.SIZE_MEDIUM_BYTES',
                    '500': 'ConstantesMemoria.Processamento.LIMITE_REGISTROS_PEQUENO * 2',
                    '1000000': 'ConstantesMemoria.Processamento.LIMITE_REGISTROS_GRANDE',
                    '1_000_000': 'ConstantesMemoria.Processamento.LIMITE_REGISTROS_GRANDE',
                    '1_000_000.0': 'ConstantesMemoria.Processamento.LIMITE_REGISTROS_GRANDE',
                    '10000': 'ConstantesMemoria.Processamento.LIMITE_REGISTROS_LOTE',
                    '10_000': 'ConstantesMemoria.Processamento.LIMITE_REGISTROS_LOTE',
                    '2048': 'ConstantesMemoria.Buffer.SIZE_XLARGE_BYTES * 2'
                }
            },
            'timeouts_duracao': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.temporal.ConstantesTempo;',
                'mapeamento': {
                    '15': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_PADRAO_MINUTOS',
                    '20': 'ConstantesTempo.Seguranca.LIMITE_LOGIN_DESENVOLVIMENTO_POR_MINUTO',
                    '24': 'ConstantesTempo.Duracao.HORAS_POR_DIA',
                    '30': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_PRODUCAO_MINUTOS',
                    '45': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_SEGURO_MINUTOS',
                    '60': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_MAXIMO_MINUTOS',
                    '90': 'ConstantesTempo.Seguranca.ROTACAO_CHAVES_MAXIMA_DIAS',
                    '120': 'ConstantesTempo.Duracao.MINUTOS_POR_DUAS_HORAS',
                    '300': 'ConstantesTempo.Seguranca.TOKEN_DURACAO_MINIMA_SEGUNDOS',
                    '600': 'ConstantesTempo.Seguranca.LIMITE_REQUISICOES_GLOBAL_PADRAO',
                    '1800': 'ConstantesTempo.Seguranca.TOKEN_DURACAO_SEGURA_SEGUNDOS',
                    '3600': 'ConstantesTempo.Seguranca.TOKEN_DURACAO_PADRAO_SEGUNDOS',
                    '3600L': 'ConstantesTempo.Seguranca.TOKEN_DURACAO_PADRAO_SEGUNDOS',
                    '86400': 'ConstantesTempo.Duracao.SEGUNDOS_POR_DIA',
                    '31536000': 'ConstantesTempo.Duracao.SEGUNDOS_POR_ANO',
                    '300_000': 'ConstantesTempo.Duracao.MILISSEGUNDOS_POR_5_MINUTOS',
                    '600000': 'ConstantesTempo.Duracao.MILISSEGUNDOS_POR_10_MINUTOS',
                    '1800000': 'ConstantesTempo.Duracao.MILISSEGUNDOS_POR_30_MINUTOS'
                }
            },
            'codigos_http': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.core.ConstantesHTTP;',
                'mapeamento': {
                    '200': 'ConstantesHTTP.Status.OK',
                    '300': 'ConstantesHTTP.Status.MULTIPLE_CHOICES',
                    '307': 'ConstantesHTTP.Status.TEMPORARY_REDIRECT',
                    '308': 'ConstantesHTTP.Status.PERMANENT_REDIRECT',
                    '400': 'ConstantesHTTP.Status.BAD_REQUEST',
                    '401': 'ConstantesHTTP.Status.UNAUTHORIZED',
                    '403': 'ConstantesHTTP.Status.FORBIDDEN',
                    '404': 'ConstantesHTTP.Status.NOT_FOUND',
                    '429': 'ConstantesHTTP.Status.TOO_MANY_REQUESTS',
                    '500': 'ConstantesHTTP.Status.INTERNAL_SERVER_ERROR',
                    '999': 'ConstantesHTTP.Status.CUSTOM_ERROR'
                }
            }
        }
        
        self.arquivos_processados = []
        self.substituicoes_realizadas = 0

    def carregar_numeros_magicos(self) -> Dict:
        """Carrega os números mágicos categorizados."""
        try:
            with open('scripts/refatoracao/numeros_magicos_categorizados.json', 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            print("❌ Arquivo de números mágicos não encontrado.")
            return {}

    def adicionar_import(self, conteudo: str, import_linha: str) -> str:
        """Adiciona import se não existir."""
        if import_linha in conteudo:
            return conteudo
        
        linhas = conteudo.split('\n')
        
        # Encontra posição para inserir import
        for i, linha in enumerate(linhas):
            if linha.strip().startswith('import br.tec.facilitaservicos.conexaodesorte'):
                # Insere após os imports do projeto
                linhas.insert(i + 1, import_linha)
                return '\n'.join(linhas)
        
        # Se não encontrou imports do projeto, insere após package
        for i, linha in enumerate(linhas):
            if linha.strip().startswith('package '):
                linhas.insert(i + 2, import_linha)
                return '\n'.join(linhas)
        
        return conteudo

    def substituir_numero_magico(self, conteudo: str, numero: str, constante: str) -> tuple[str, int]:
        """Substitui número mágico por constante de forma segura."""
        substituicoes = 0
        
        # Padrões seguros de substituição
        padroes_substituicao = [
            # Literal isolado com espaços
            f' {numero} ',
            f' {numero};',
            f' {numero},',
            f'({numero})',
            f'({numero},',
            f', {numero})',
            f'= {numero};',
            f'== {numero}',
            f'!= {numero}',
            f'< {numero}',
            f'> {numero}',
            f'<= {numero}',
            f'>= {numero}',
            f'[{numero}]',
            f'{{{numero}}}',
        ]
        
        for padrao in padroes_substituicao:
            if padrao in conteudo:
                novo_padrao = padrao.replace(numero, constante)
                conteudo = conteudo.replace(padrao, novo_padrao)
                substituicoes += 1
        
        return conteudo, substituicoes

    def processar_arquivo(self, arquivo_path: Path, categoria: str, numeros: Set[str]) -> bool:
        """Processa um arquivo específico."""
        try:
            with open(arquivo_path, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            conteudo_original = conteudo
            config = self.configuracoes[categoria]
            
            # Adiciona import
            conteudo = self.adicionar_import(conteudo, config['import'])
            
            # Substitui números mágicos
            substituicoes_arquivo = 0
            for numero in numeros:
                if numero in config['mapeamento']:
                    constante = config['mapeamento'][numero]
                    conteudo, subs = self.substituir_numero_magico(conteudo, numero, constante)
                    substituicoes_arquivo += subs
            
            # Salva se houve mudanças
            if conteudo != conteudo_original:
                with open(arquivo_path, 'w', encoding='utf-8') as f:
                    f.write(conteudo)
                
                self.substituicoes_realizadas += substituicoes_arquivo
                print(f"   ✅ {arquivo_path.name}: {substituicoes_arquivo} substituições")
                return True
            else:
                print(f"   ⚠️  {arquivo_path.name}: Nenhuma substituição")
                return False
                
        except Exception as e:
            print(f"   ❌ Erro em {arquivo_path.name}: {e}")
            return False

    def processar_categoria(self, categoria: str) -> None:
        """Processa uma categoria específica."""
        dados = self.carregar_numeros_magicos()
        if not dados or categoria not in dados['categorias']:
            print(f"❌ Categoria '{categoria}' não encontrada")
            return
        
        items = dados['categorias'][categoria]
        if not items:
            print(f"⚠️  Categoria '{categoria}' está vazia")
            return
        
        print(f"🔧 REFATORANDO {categoria.upper().replace('_', ' ')} ({len(items)} ocorrências)")
        print("=" * 70)
        
        # Agrupa por arquivo
        arquivos_por_nome = {}
        for item in items:
            arquivo = item['arquivo']
            numero = item['numero']
            
            if arquivo not in arquivos_por_nome:
                arquivos_por_nome[arquivo] = set()
            arquivos_por_nome[arquivo].add(numero)
        
        sucessos = 0
        for arquivo_nome, numeros in arquivos_por_nome.items():
            print(f"\n📄 Processando: {arquivo_nome}")
            print(f"   Números: {sorted(numeros)}")
            
            # Encontra o arquivo
            arquivo_path = None
            for java_file in self.src_path.rglob(f"*{arquivo_nome}"):
                arquivo_path = java_file
                break
            
            if not arquivo_path:
                print(f"   ❌ Arquivo não encontrado: {arquivo_nome}")
                continue
            
            if self.processar_arquivo(arquivo_path, categoria, numeros):
                sucessos += 1
                self.arquivos_processados.append(arquivo_nome)
        
        print(f"\n📊 RESUMO {categoria.upper()}:")
        print(f"   ✅ Arquivos processados: {sucessos}/{len(arquivos_por_nome)}")

def main():
    """Função principal."""
    import sys
    
    if len(sys.argv) < 2:
        print("Uso: python3 refatorador_simples.py <categoria>")
        print("Categorias disponíveis:")
        print("  - documentos_brasil")
        print("  - tamanhos_memoria") 
        print("  - timeouts_duracao")
        print("  - codigos_http")
        return
    
    categoria = sys.argv[1]
    
    print("🚀 INICIANDO REFATORAÇÃO SIMPLES")
    print("=" * 50)
    
    refatorador = RefatoradorSimples()
    refatorador.processar_categoria(categoria)
    
    print(f"\n🎉 REFATORAÇÃO CONCLUÍDA!")
    print(f"📁 Arquivos processados: {len(refatorador.arquivos_processados)}")
    print(f"🔄 Total de substituições: {refatorador.substituicoes_realizadas}")

if __name__ == "__main__":
    main()
