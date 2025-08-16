#!/usr/bin/env python3
"""
Script para filtrar classes já refatoradas do terminal.txt e identificar pendências.
"""

import re
from collections import defaultdict

# Classes já refatoradas (confirmadas)
CLASSES_REFATORADAS = {
    'OrquestradorExtracoes.java',
    'EstrategiaDetecaoComportamentoAvancada.java', 
    'EstrategiaDetecaoComportamentoSimples.java',
    'TipoAnexo.java',
    'ServicoExtracaoResultadoRefatorado.java',
    'ServicoValidacaoEntrada.java',
    'ConfiguracaoHorarioValido.java',
    'ServicoExtracaoResultado.java'
}

def processar_terminal_txt():
    """Processa o arquivo terminal.txt e filtra classes pendentes."""
    
    # Lê o conteúdo do terminal.txt
    with open('terminal.txt', 'r', encoding='utf-8') as f:
        linhas = f.readlines()
    
    # Agrupa por classe
    classes_pendentes = defaultdict(list)
    classes_refatoradas_encontradas = defaultdict(list)
    
    for linha in linhas:
        linha = linha.strip()
        if not linha:
            continue
            
        # Extrai nome da classe
        match = re.match(r"([^:]+\.java):", linha)
        if match:
            classe = match.group(1)
            
            if classe in CLASSES_REFATORADAS:
                classes_refatoradas_encontradas[classe].append(linha)
            else:
                classes_pendentes[classe].append(linha)
    
    return classes_pendentes, classes_refatoradas_encontradas

def gerar_relatorio(classes_pendentes, classes_refatoradas_encontradas):
    """Gera relatório das classes pendentes e refatoradas."""
    
    print("🔍 ANÁLISE DO ARQUIVO TERMINAL.TXT")
    print("=" * 60)
    
    print(f"\n✅ CLASSES JÁ REFATORADAS ENCONTRADAS: {len(classes_refatoradas_encontradas)}")
    for classe, linhas in classes_refatoradas_encontradas.items():
        print(f"   - {classe}: {len(linhas)} números mágicos (JÁ REFATORADO)")
    
    print(f"\n⏳ CLASSES PENDENTES: {len(classes_pendentes)}")
    
    # Ordena por número de ocorrências (decrescente)
    classes_ordenadas = sorted(classes_pendentes.items(), 
                              key=lambda x: len(x[1]), reverse=True)
    
    total_pendentes = sum(len(linhas) for linhas in classes_pendentes.values())
    print(f"📊 Total de números mágicos pendentes: {total_pendentes}")
    
    print(f"\n🎯 TOP 15 CLASSES PRIORITÁRIAS:")
    print("-" * 60)
    
    for i, (classe, linhas) in enumerate(classes_ordenadas[:15], 1):
        numeros = []
        for linha in linhas:
            match = re.search(r"'([^']+)' é um número mágico", linha)
            if match:
                numeros.append(match.group(1))
        
        numeros_unicos = list(set(numeros))
        print(f"{i:2d}. {classe:<40} | {len(linhas):2d} ocorrências")
        print(f"    Números: {', '.join(numeros_unicos[:8])}")
        if len(numeros_unicos) > 8:
            print(f"    ... e mais {len(numeros_unicos) - 8} números")
        print()
    
    return classes_ordenadas

def salvar_classes_pendentes(classes_pendentes):
    """Salva arquivo atualizado apenas com classes pendentes."""
    
    with open('terminal_pendentes.txt', 'w', encoding='utf-8') as f:
        for classe, linhas in classes_pendentes.items():
            for linha in linhas:
                f.write(linha + '\n')
    
    print(f"💾 Arquivo salvo: terminal_pendentes.txt")
    print(f"   Contém apenas as classes que ainda precisam ser refatoradas")

def main():
    """Função principal."""
    classes_pendentes, classes_refatoradas = processar_terminal_txt()
    classes_ordenadas = gerar_relatorio(classes_pendentes, classes_refatoradas)
    salvar_classes_pendentes(classes_pendentes)
    
    print(f"\n🚀 PRÓXIMOS PASSOS:")
    print("1. Focar nas classes com mais números mágicos")
    print("2. Criar constantes específicas por domínio")
    print("3. Refatorar uma classe por vez")
    print("4. Validar compilação após cada refatoração")

if __name__ == "__main__":
    main()
