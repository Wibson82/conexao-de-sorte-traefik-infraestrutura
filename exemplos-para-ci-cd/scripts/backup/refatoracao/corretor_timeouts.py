#!/usr/bin/env python3
"""
Script para corrigir referências de ConstantesHTTP.Timeouts para ConstantesHTTP.Rede.
"""

import os
from pathlib import Path

def corrigir_referencias_timeouts():
    """Corrige referências de Timeouts para Rede."""
    src_path = Path("src/main/java")
    
    # Substituições necessárias
    substituicoes = [
        ("ConstantesHTTP.Timeouts.CONNECTION_TIMEOUT_MS", "ConstantesHTTP.Rede.CONNECTION_TIMEOUT_MS"),
        ("ConstantesHTTP.Timeouts.CONNECTION_POOL_TIMEOUT_MS", "ConstantesHTTP.Rede.CONNECTION_POOL_TIMEOUT_MS"),
        ("ConstantesHTTP.Timeouts.CONNECTION_VALIDATE_TIMEOUT_MS", "ConstantesHTTP.Rede.CONNECTION_VALIDATE_TIMEOUT_MS"),
        ("ConstantesHTTP.Timeouts.SOCKET_TIMEOUT_MS", "ConstantesHTTP.Rede.SOCKET_TIMEOUT_MS"),
        ("ConstantesHTTP.Timeouts.API_PUBLICA_TIMEOUT_MS", "ConstantesHTTP.Rede.API_PUBLICA_TIMEOUT_MS"),
        ("ConstantesHTTP.Timeouts.READ_TIMEOUT_MS", "ConstantesHTTP.Rede.READ_TIMEOUT_MS"),
    ]
    
    arquivos_corrigidos = 0
    
    # Procura todos os arquivos Java
    for java_file in src_path.rglob("*.java"):
        try:
            with open(java_file, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            conteudo_original = conteudo
            
            # Aplica todas as substituições
            for antigo, novo in substituicoes:
                conteudo = conteudo.replace(antigo, novo)
            
            # Se houve mudanças, salva o arquivo
            if conteudo != conteudo_original:
                with open(java_file, 'w', encoding='utf-8') as f:
                    f.write(conteudo)
                
                print(f"✅ {java_file.relative_to(src_path)}")
                arquivos_corrigidos += 1
                
        except Exception as e:
            print(f"❌ Erro em {java_file}: {e}")
    
    print(f"\n📊 Total de arquivos corrigidos: {arquivos_corrigidos}")

def main():
    """Função principal."""
    print("🔧 CORRIGINDO REFERÊNCIAS DE TIMEOUTS")
    print("=" * 50)
    
    corrigir_referencias_timeouts()
    
    print("\n🎉 CORREÇÃO DE TIMEOUTS CONCLUÍDA!")

if __name__ == "__main__":
    main()
