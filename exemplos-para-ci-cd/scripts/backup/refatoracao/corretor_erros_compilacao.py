#!/usr/bin/env python3
"""
Script para corrigir erros de compilação após refatoração em massa.
"""

import os
from pathlib import Path

def corrigir_constantes_memoria():
    """Adiciona a classe Processamento que está faltando."""
    arquivo = Path("src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/constantes/infraestrutura/ConstantesMemoria.java")
    
    with open(arquivo, 'r', encoding='utf-8') as f:
        conteudo = f.read()
    
    # Adiciona a classe Processamento antes da classe Arquivo
    processamento_class = '''
    /**
     * Constantes relacionadas a limites de processamento.
     */
    public static final class Processamento {
        
        /** Limite padrão de registros para processamento em lote - 10.000 */
        public static final int LIMITE_REGISTROS_LOTE = 10_000;
        
        /** Limite de registros para operações grandes - 1.000.000 */
        public static final int LIMITE_REGISTROS_GRANDE = 1_000_000;
        
        /** Limite de registros para operações pequenas - 1.000 */
        public static final int LIMITE_REGISTROS_PEQUENO = 1_000;
        
        private Processamento() {}
    }
'''
    
    # Encontra onde inserir
    if 'public static final class Processamento' not in conteudo:
        # Insere antes da classe Arquivo
        conteudo = conteudo.replace(
            '    /**\n     * Tamanhos relacionados a arquivos.',
            processamento_class + '\n    /**\n     * Tamanhos relacionados a arquivos.'
        )
        
        with open(arquivo, 'w', encoding='utf-8') as f:
            f.write(conteudo)
        
        print("✅ Classe Processamento adicionada a ConstantesMemoria.java")

def corrigir_switch_cases():
    """Corrige switch cases que precisam de constantes literais."""
    arquivos_switch = [
        "src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/RespostaErroUtil.java"
    ]
    
    for arquivo_path in arquivos_switch:
        arquivo = Path(arquivo_path)
        if not arquivo.exists():
            continue
            
        with open(arquivo, 'r', encoding='utf-8') as f:
            conteudo = f.read()
        
        # Reverte switch cases para números literais (Java requer constantes compile-time)
        substituicoes = [
            ('ConstantesHTTP.Status.BAD_REQUEST', '400'),
            ('ConstantesHTTP.Status.UNAUTHORIZED', '401'),
            ('ConstantesHTTP.Status.FORBIDDEN', '403'),
            ('ConstantesHTTP.Status.NOT_FOUND', '404'),
            ('ConstantesHTTP.Status.UNPROCESSABLE_ENTITY', '422'),
            ('ConstantesHTTP.Status.INTERNAL_SERVER_ERROR', '500'),
        ]
        
        for constante, literal in substituicoes:
            conteudo = conteudo.replace(f'case {constante} ->', f'case {literal} ->')
        
        with open(arquivo, 'w', encoding='utf-8') as f:
            f.write(conteudo)
        
        print(f"✅ Switch cases corrigidos em {arquivo.name}")

def corrigir_cors_configuration():
    """Corrige problemas de tipo em CorsConfiguration."""
    arquivos_cors = [
        "src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/ConfiguracaoSegurancaHealth.java",
        "src/main/java/br/tec/facilitaservicos/conexaodesorte/configuracao/seguranca/cors/ConfiguracaoCorsSimplifcada.java"
    ]
    
    for arquivo_path in arquivos_cors:
        arquivo = Path(arquivo_path)
        if not arquivo.exists():
            continue
            
        with open(arquivo, 'r', encoding='utf-8') as f:
            conteudo = f.read()
        
        # Converte int para Long para setMaxAge
        conteudo = conteudo.replace(
            '.setMaxAge(ConstantesTempo.Seguranca.TOKEN_DURACAO_PADRAO_SEGUNDOS)',
            '.setMaxAge((long) ConstantesTempo.Seguranca.TOKEN_DURACAO_PADRAO_SEGUNDOS)'
        )
        
        with open(arquivo, 'w', encoding='utf-8') as f:
            f.write(conteudo)
        
        print(f"✅ CorsConfiguration corrigida em {arquivo.name}")

def remover_constantes_http_duplicada():
    """Remove classe ConstantesHTTP duplicada em util."""
    arquivo = Path("src/main/java/br/tec/facilitaservicos/conexaodesorte/infraestrutura/util/ConstantesHTTP.java")
    
    if arquivo.exists():
        with open(arquivo, 'r', encoding='utf-8') as f:
            conteudo = f.read()
        
        # Se contém import da classe correta, remove a definição duplicada
        if 'import br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.core.ConstantesHTTP' in conteudo:
            # Remove tudo após o import
            linhas = conteudo.split('\n')
            novas_linhas = []
            
            for linha in linhas:
                if linha.strip().startswith('public final class ConstantesHTTP'):
                    break
                novas_linhas.append(linha)
            
            # Adiciona apenas um comentário
            novas_linhas.append('')
            novas_linhas.append('// Esta classe foi movida para br.tec.facilitaservicos.conexaodesorte.infraestrutura.constantes.core.ConstantesHTTP')
            novas_linhas.append('// Use a nova localização')
            
            with open(arquivo, 'w', encoding='utf-8') as f:
                f.write('\n'.join(novas_linhas))
            
            print("✅ ConstantesHTTP duplicada removida de util/")

def main():
    """Função principal."""
    print("🔧 CORRIGINDO ERROS DE COMPILAÇÃO")
    print("=" * 50)
    
    corrigir_constantes_memoria()
    corrigir_switch_cases()
    corrigir_cors_configuration()
    remover_constantes_http_duplicada()
    
    print("\n🎉 CORREÇÕES CONCLUÍDAS!")
    print("Execute './mvnw compile' para verificar se os erros foram corrigidos.")

if __name__ == "__main__":
    main()
