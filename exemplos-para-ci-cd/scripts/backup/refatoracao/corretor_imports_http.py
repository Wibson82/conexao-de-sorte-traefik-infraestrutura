#!/usr/bin/env python3
"""
Script para corrigir imports de ConstantesHTTP após mudança de pacote.
"""

import os
from pathlib import Path

def corrigir_imports_constantes_http():
    """Corrige todos os imports de ConstantesHTTP do pacote util para core."""
    src_path = Path("src/main/java")
    
    # Import antigo e novo
    import_antigo = "import br.tec.facilitaservicos.conexaodesorte.infraestrutura.util.ConstantesHTTP;"
    import_novo = "import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.core.ConstantesHTTP;"
    
    arquivos_corrigidos = 0
    
    # Procura todos os arquivos Java
    for java_file in src_path.rglob("*.java"):
        try:
            with open(java_file, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            # Se contém o import antigo, substitui
            if import_antigo in conteudo:
                conteudo = conteudo.replace(import_antigo, import_novo)
                
                with open(java_file, 'w', encoding='utf-8') as f:
                    f.write(conteudo)
                
                print(f"✅ {java_file.relative_to(src_path)}")
                arquivos_corrigidos += 1
                
        except Exception as e:
            print(f"❌ Erro em {java_file}: {e}")
    
    print(f"\n📊 Total de arquivos corrigidos: {arquivos_corrigidos}")

def main():
    """Função principal."""
    print("🔧 CORRIGINDO IMPORTS DE CONSTANTESHTTP")
    print("=" * 50)
    
    corrigir_imports_constantes_http()
    
    print("\n🎉 CORREÇÃO DE IMPORTS CONCLUÍDA!")

if __name__ == "__main__":
    main()
