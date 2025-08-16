#!/usr/bin/env python3
"""
Script para refatoração em massa dos números mágicos relacionados a documentos brasileiros.
Foca em CPF (11), CNPJ (12) e idade mínima (18).
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Tuple

class RefatoradorDocumentosBrasil:
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.src_path = self.base_path / "src" / "main" / "java"
        
        # Mapeamento de números para constantes
        self.mapeamento_constantes = {
            '11': 'ConstantesDocumentosBrasil.CPF.TAMANHO_DIGITOS',
            '12': 'ConstantesDocumentosBrasil.CNPJ.TAMANHO_DIGITOS', 
            '18': 'ConstantesDocumentosBrasil.Demografico.IDADE_MINIMA_CADASTRO'
        }
        
        # Import necessário
        self.import_necessario = "import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.negocio.ConstantesDocumentosBrasil;"
        
        self.arquivos_processados = []
        self.substituicoes_realizadas = 0

    def carregar_numeros_magicos(self) -> Dict:
        """Carrega os números mágicos categorizados."""
        try:
            with open('scripts/refatoracao/numeros_magicos_categorizados.json', 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            print("❌ Arquivo de números mágicos não encontrado. Execute primeiro analise_numeros_magicos.py")
            return {}

    def adicionar_import(self, conteudo: str, arquivo: str) -> str:
        """Adiciona o import necessário se não existir."""
        if self.import_necessario in conteudo:
            return conteudo
        
        # Encontra a posição para inserir o import
        linhas = conteudo.split('\n')
        posicao_insert = -1
        
        for i, linha in enumerate(linhas):
            if linha.strip().startswith('import br.tec.facilitaservicos.conexaodesorte'):
                posicao_insert = i + 1
            elif linha.strip().startswith('import') and not linha.strip().startswith('import br.tec.facilitaservicos'):
                if posicao_insert == -1:
                    posicao_insert = i
                break
        
        if posicao_insert > -1:
            linhas.insert(posicao_insert, self.import_necessario)
            print(f"   ✅ Import adicionado em {arquivo}")
            return '\n'.join(linhas)
        
        return conteudo

    def refatorar_arquivo(self, arquivo_info: Dict) -> bool:
        """Refatora um arquivo específico."""
        arquivo_nome = arquivo_info['arquivo']
        numero = arquivo_info['numero']
        linha_num = arquivo_info['linha']
        
        # Encontra o arquivo
        arquivo_path = None
        for java_file in self.src_path.rglob(f"*{arquivo_nome}"):
            arquivo_path = java_file
            break
        
        if not arquivo_path or not arquivo_path.exists():
            print(f"   ❌ Arquivo não encontrado: {arquivo_nome}")
            return False
        
        try:
            # Lê o conteudo
            with open(arquivo_path, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            conteudo_original = conteudo
            
            # Adiciona import se necessário
            conteudo = self.adicionar_import(conteudo, arquivo_nome)
            
            # Substitui o número mágico
            constante = self.mapeamento_constantes.get(numero)
            if not constante:
                print(f"   ⚠️  Constante não mapeada para número: {numero}")
                return False
            
            # Padrões de substituição mais específicos
            padroes = [
                # Comparações e operações
                (rf'\b{re.escape(numero)}\b(?=\s*[<>=!])', constante),
                # Parâmetros de método
                (rf'(?<=[\(,\s]){re.escape(numero)}(?=[\),\s])', constante),
                # Atribuições
                (rf'(?<==\s*){re.escape(numero)}\b', constante),
                # Condições
                (rf'(?<=\s){re.escape(numero)}(?=\s*[<>=!])', constante),
                # Literais isolados
                (rf'\b{re.escape(numero)}\b', constante)
            ]
            
            substituicoes_arquivo = 0
            for padrao, substituicao in padroes:
                novo_conteudo = re.sub(padrao, substituicao, conteudo)
                if novo_conteudo != conteudo:
                    conteudo = novo_conteudo
                    substituicoes_arquivo += 1
            
            # Salva apenas se houve mudanças
            if conteudo != conteudo_original:
                with open(arquivo_path, 'w', encoding='utf-8') as f:
                    f.write(conteudo)
                
                self.substituicoes_realizadas += substituicoes_arquivo
                print(f"   ✅ {arquivo_nome}: {substituicoes_arquivo} substituições")
                return True
            else:
                print(f"   ⚠️  {arquivo_nome}: Nenhuma substituição realizada")
                return False
                
        except Exception as e:
            print(f"   ❌ Erro ao processar {arquivo_nome}: {e}")
            return False

    def processar_categoria(self) -> None:
        """Processa todos os arquivos da categoria documentos_brasil."""
        dados = self.carregar_numeros_magicos()
        if not dados:
            return
        
        documentos_brasil = dados['categorias']['documentos_brasil']
        
        print(f"🇧🇷 REFATORANDO DOCUMENTOS BRASILEIROS ({len(documentos_brasil)} ocorrências)")
        print("=" * 70)
        
        # Agrupa por arquivo para processar de uma vez
        arquivos_por_nome = {}
        for item in documentos_brasil:
            arquivo = item['arquivo']
            if arquivo not in arquivos_por_nome:
                arquivos_por_nome[arquivo] = []
            arquivos_por_nome[arquivo].append(item)
        
        sucessos = 0
        for arquivo_nome, items in arquivos_por_nome.items():
            print(f"\n📄 Processando: {arquivo_nome}")
            print(f"   Números a refatorar: {[item['numero'] for item in items]}")
            
            # Processa o primeiro item (o método refatorar_arquivo já trata todos os números)
            if self.refatorar_arquivo(items[0]):
                sucessos += 1
                self.arquivos_processados.append(arquivo_nome)
        
        print(f"\n📊 RESUMO DOCUMENTOS BRASILEIROS:")
        print(f"   ✅ Arquivos processados: {sucessos}/{len(arquivos_por_nome)}")
        print(f"   🔄 Substituições realizadas: {self.substituicoes_realizadas}")

    def verificar_constantes_existem(self) -> bool:
        """Verifica se as constantes necessárias existem."""
        constantes_path = self.src_path / "br" / "tec" / "facilitaservicos" / "conexaodesorte" / "infraestrutura" / "constantes" / "negocio" / "ConstantesDocumentosBrasil.java"
        
        if not constantes_path.exists():
            print("❌ Arquivo ConstantesDocumentosBrasil.java não encontrado!")
            print(f"   Esperado em: {constantes_path}")
            return False
        
        try:
            with open(constantes_path, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            # Verifica se as constantes necessárias existem
            constantes_necessarias = [
                'TAMANHO_DIGITOS = 11',
                'TAMANHO_DIGITOS = 14', 
                'IDADE_MINIMA_CADASTRO = 18'
            ]
            
            for constante in constantes_necessarias:
                if constante not in conteudo:
                    print(f"⚠️  Constante não encontrada: {constante}")
                    return False
            
            print("✅ Todas as constantes necessárias existem")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao verificar constantes: {e}")
            return False

def main():
    """Função principal."""
    print("🚀 INICIANDO REFATORAÇÃO DE DOCUMENTOS BRASILEIROS")
    print("=" * 60)
    
    refatorador = RefatoradorDocumentosBrasil()
    
    # Verifica se as constantes existem
    if not refatorador.verificar_constantes_existem():
        print("\n❌ Abortando: Constantes necessárias não encontradas")
        return
    
    # Processa a categoria
    refatorador.processar_categoria()
    
    print(f"\n🎉 REFATORAÇÃO CONCLUÍDA!")
    print(f"📁 Arquivos processados: {len(refatorador.arquivos_processados)}")
    print(f"🔄 Total de substituições: {refatorador.substituicoes_realizadas}")
    
    if refatorador.arquivos_processados:
        print(f"\n📋 Arquivos modificados:")
        for arquivo in refatorador.arquivos_processados:
            print(f"   - {arquivo}")

if __name__ == "__main__":
    main()
