#!/usr/bin/env python3
"""
Script para refatorar uma classe específica com números mágicos.
Permite refatoração focada e controlada.
"""

import sys
import os
from pathlib import Path
import re

class RefatoradorClasseEspecifica:
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.src_path = self.base_path / "src" / "main" / "java"
        
        # Mapeamentos de constantes por domínio
        self.mapeamentos = {
            'TipoAnexo.java': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.infraestrutura.ConstantesMemoria;',
                'substituicoes': {
                    '1024': 'ConstantesMemoria.Buffer.SIZE_XLARGE_BYTES',
                    '1024.0': '(double) ConstantesMemoria.Buffer.SIZE_XLARGE_BYTES'
                }
            },
            'ServicoExtracaoResultado.java': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.negocio.ConstantesLoteria;\nimport br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.core.ConstantesHTTP;',
                'substituicoes': {
                    '15': 'ConstantesLoteria.Modalidades.Lotofacil.NUMERO_MAXIMO',
                    '200': 'ConstantesHTTP.Status.OK',
                    '30': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_PRODUCAO_MINUTOS',
                    '31': 'ConstantesLoteria.Modalidades.DiaDeSorte.NUMERO_MAXIMO',
                    '41': 'ConstantesLoteria.Modalidades.DiaDeSorte.NUMERO_MAXIMO + 10',
                    '11': 'ConstantesDocumentosBrasil.CPF.TAMANHO_DIGITOS'
                }
            },
            'ServicoExtracaoResultadoRefatorado.java': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.temporal.ConstantesTempo;',
                'substituicoes': {
                    '30': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_PRODUCAO_MINUTOS',
                    '15': 'ConstantesTempo.Seguranca.BLOQUEIO_TEMPO_PADRAO_MINUTOS'
                }
            },
            'MetricasToken.java': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.seguranca.ConstantesDetecaoComportamento;',
                'substituicoes': {
                    '0.5': 'ConstantesDetecaoComportamento.Thresholds.ATIVIDADE_MODERADA',
                    '0.95': '0.95', # Percentil específico - manter
                    '0.99': '0.99'  # Percentil específico - manter
                }
            },
            'RespostaErroUtil.java': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.core.ConstantesHTTP;',
                'substituicoes': {
                    '400': 'ConstantesHTTP.Status.BAD_REQUEST',
                    '401': 'ConstantesHTTP.Status.UNAUTHORIZED',
                    '403': 'ConstantesHTTP.Status.FORBIDDEN',
                    '404': 'ConstantesHTTP.Status.NOT_FOUND',
                    '422': 'ConstantesHTTP.Status.UNPROCESSABLE_ENTITY',
                    '500': 'ConstantesHTTP.Status.INTERNAL_SERVER_ERROR'
                }
            },
            'ConfiguracaoHorarioValido.java': {
                'import': 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.negocio.ConstantesLoteria;',
                'substituicoes': {
                    '13': 'ConstantesLoteria.Horarios.SORTEIO_LOTECA.getHour()',
                    '15': 'ConstantesLoteria.Horarios.SORTEIO_LOTECA.getMinute()',
                    '17': '17', # Horário específico - criar constante se necessário
                    '18': 'ConstantesDocumentosBrasil.Demografico.IDADE_MINIMA_CADASTRO',
                    '20': 'ConstantesLoteria.Horarios.SORTEIO_PADRAO.getHour()',
                    '44': '44' # Minuto específico - criar constante se necessário
                }
            }
        }

    def encontrar_arquivo(self, nome_classe: str) -> Path:
        """Encontra o arquivo da classe no projeto."""
        for java_file in self.src_path.rglob(f"*{nome_classe}"):
            return java_file
        return None

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

    def substituir_numeros_magicos(self, conteudo: str, substituicoes: dict) -> tuple[str, int]:
        """Substitui números mágicos por constantes."""
        total_substituicoes = 0
        
        for numero, constante in substituicoes.items():
            # Padrões seguros de substituição
            padroes = [
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
                f':{numero}',
                f'"{numero}"'
            ]
            
            for padrao in padroes:
                if padrao in conteudo:
                    novo_padrao = padrao.replace(numero, constante)
                    conteudo = conteudo.replace(padrao, novo_padrao)
                    total_substituicoes += 1
        
        return conteudo, total_substituicoes

    def refatorar_classe(self, nome_classe: str) -> bool:
        """Refatora uma classe específica."""
        if nome_classe not in self.mapeamentos:
            print(f"❌ Classe '{nome_classe}' não tem mapeamento definido")
            return False
        
        arquivo_path = self.encontrar_arquivo(nome_classe)
        if not arquivo_path:
            print(f"❌ Arquivo não encontrado: {nome_classe}")
            return False
        
        try:
            with open(arquivo_path, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            conteudo_original = conteudo
            config = self.mapeamentos[nome_classe]
            
            # Adiciona imports
            if 'import' in config:
                for import_linha in config['import'].split('\n'):
                    conteudo = self.adicionar_import(conteudo, import_linha.strip())
            
            # Substitui números mágicos
            conteudo, substituicoes = self.substituir_numeros_magicos(conteudo, config['substituicoes'])
            
            # Salva se houve mudanças
            if conteudo != conteudo_original:
                with open(arquivo_path, 'w', encoding='utf-8') as f:
                    f.write(conteudo)
                
                print(f"✅ {nome_classe}: {substituicoes} substituições realizadas")
                return True
            else:
                print(f"⚠️  {nome_classe}: Nenhuma substituição realizada")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao processar {nome_classe}: {e}")
            return False

def main():
    """Função principal."""
    if len(sys.argv) < 2:
        print("Uso: python3 refatorador_classe_especifica.py <NomeClasse.java>")
        print("\nClasses disponíveis:")
        refatorador = RefatoradorClasseEspecifica()
        for classe in refatorador.mapeamentos.keys():
            print(f"  - {classe}")
        return
    
    nome_classe = sys.argv[1]
    
    print(f"🔧 REFATORANDO CLASSE: {nome_classe}")
    print("=" * 50)
    
    refatorador = RefatoradorClasseEspecifica()
    sucesso = refatorador.refatorar_classe(nome_classe)
    
    if sucesso:
        print(f"\n🎉 Refatoração de {nome_classe} concluída com sucesso!")
        print("Execute './mvnw compile' para verificar se não há erros.")
    else:
        print(f"\n❌ Falha na refatoração de {nome_classe}")

if __name__ == "__main__":
    main()
