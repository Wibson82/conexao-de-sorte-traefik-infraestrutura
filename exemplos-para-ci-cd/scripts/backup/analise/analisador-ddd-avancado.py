#!/usr/bin/env python3
"""
Analisador Avançado DDD/SOLID - Conexão de Sorte
Análise detalhada de violações, redundâncias e oportunidades de melhoria
"""

import os
import re
import json
import ast
from pathlib import Path
from collections import defaultdict, Counter
from dataclasses import dataclass, field
from typing import List, Dict, Set, Tuple, Optional
import argparse
from datetime import datetime

@dataclass
class ClasseAnalise:
    """Representa uma classe Java analisada"""
    nome: str
    caminho: str
    pacote: str
    tipo: str  # Entity, Service, Controller, DTO, etc.
    linhas: int
    metodos: List[str] = field(default_factory=list)
    dependencias: Set[str] = field(default_factory=set)
    anotacoes: Set[str] = field(default_factory=set)
    violacoes: List[str] = field(default_factory=list)
    complexidade: int = 0

@dataclass
class ViolacaoDDD:
    """Representa uma violação de DDD identificada"""
    tipo: str
    severidade: str  # ALTA, MEDIA, BAIXA
    classe: str
    descricao: str
    sugestao: str
    linha: Optional[int] = None

@dataclass
class RelatorioAnalise:
    """Relatório completo da análise"""
    timestamp: str
    total_classes: int
    bounded_contexts: Dict[str, List[str]]
    violacoes: List[ViolacaoDDD]
    redundancias: List[Dict]
    oportunidades_solid: List[Dict]
    metricas: Dict[str, int]

class AnalisadorDDD:
    """Analisador principal para DDD e SOLID"""
    
    def __init__(self, projeto_root: str):
        self.projeto_root = Path(projeto_root)
        self.src_path = self.projeto_root / "src" / "main" / "java"
        self.classes: List[ClasseAnalise] = []
        self.violacoes: List[ViolacaoDDD] = []
        self.bounded_contexts: Dict[str, List[str]] = defaultdict(list)
        
    def analisar_projeto(self) -> RelatorioAnalise:
        """Executa análise completa do projeto"""
        print("🔍 Iniciando análise avançada DDD/SOLID...")
        
        # 1. Descobrir e analisar todas as classes
        self._descobrir_classes()
        
        # 2. Identificar Bounded Contexts
        self._identificar_bounded_contexts()
        
        # 3. Detectar violações DDD
        self._detectar_violacoes_ddd()
        
        # 4. Identificar redundâncias
        redundancias = self._identificar_redundancias()
        
        # 5. Analisar oportunidades SOLID
        oportunidades_solid = self._analisar_solid()
        
        # 6. Calcular métricas
        metricas = self._calcular_metricas()
        
        return RelatorioAnalise(
            timestamp=datetime.now().isoformat(),
            total_classes=len(self.classes),
            bounded_contexts=dict(self.bounded_contexts),
            violacoes=self.violacoes,
            redundancias=redundancias,
            oportunidades_solid=oportunidades_solid,
            metricas=metricas
        )
    
    def _descobrir_classes(self):
        """Descobre e analisa todas as classes Java"""
        print("📁 Descobrindo classes Java...")
        
        for java_file in self.src_path.rglob("*.java"):
            try:
                classe = self._analisar_classe(java_file)
                if classe:
                    self.classes.append(classe)
            except Exception as e:
                print(f"⚠️ Erro ao analisar {java_file}: {e}")
    
    def _analisar_classe(self, arquivo: Path) -> Optional[ClasseAnalise]:
        """Analisa uma classe Java específica"""
        try:
            with open(arquivo, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            # Extrair informações básicas
            nome_classe = arquivo.stem
            pacote = self._extrair_pacote(conteudo)
            tipo = self._identificar_tipo_classe(nome_classe, conteudo)
            linhas = len(conteudo.splitlines())
            
            # Extrair métodos
            metodos = self._extrair_metodos(conteudo)
            
            # Extrair dependências
            dependencias = self._extrair_dependencias(conteudo)
            
            # Extrair anotações
            anotacoes = self._extrair_anotacoes(conteudo)
            
            # Calcular complexidade ciclomática básica
            complexidade = self._calcular_complexidade(conteudo)
            
            return ClasseAnalise(
                nome=nome_classe,
                caminho=str(arquivo.relative_to(self.projeto_root)),
                pacote=pacote,
                tipo=tipo,
                linhas=linhas,
                metodos=metodos,
                dependencias=dependencias,
                anotacoes=anotacoes,
                complexidade=complexidade
            )
            
        except Exception as e:
            print(f"Erro ao analisar {arquivo}: {e}")
            return None
    
    def _extrair_pacote(self, conteudo: str) -> str:
        """Extrai o pacote da classe"""
        match = re.search(r'package\s+([\w.]+);', conteudo)
        return match.group(1) if match else ""
    
    def _identificar_tipo_classe(self, nome: str, conteudo: str) -> str:
        """Identifica o tipo da classe baseado no nome e conteúdo"""
        if "Controller" in nome or "@RestController" in conteudo or "@Controller" in conteudo:
            return "Controller"
        elif "Service" in nome or "Servico" in nome or "@Service" in conteudo:
            return "Service"
        elif "Repository" in nome or "Repositorio" in nome or "@Repository" in conteudo:
            return "Repository"
        elif "DTO" in nome or "/dto/" in conteudo:
            return "DTO"
        elif "@Entity" in conteudo or "/entidade/" in conteudo:
            return "Entity"
        elif "Exception" in nome or "Excecao" in nome:
            return "Exception"
        elif "Config" in nome or "@Configuration" in conteudo:
            return "Configuration"
        elif nome.startswith("Constantes") or "Constants" in nome:
            return "Constants"
        else:
            return "Other"
    
    def _extrair_metodos(self, conteudo: str) -> List[str]:
        """Extrai nomes dos métodos públicos"""
        pattern = r'public\s+(?:static\s+)?(?:\w+\s+)*(\w+)\s*\('
        return re.findall(pattern, conteudo)
    
    def _extrair_dependencias(self, conteudo: str) -> Set[str]:
        """Extrai dependências (imports)"""
        pattern = r'import\s+([\w.]+);'
        imports = re.findall(pattern, conteudo)
        return set(imp.split('.')[-1] for imp in imports if not imp.startswith('java.'))
    
    def _extrair_anotacoes(self, conteudo: str) -> Set[str]:
        """Extrai anotações da classe"""
        pattern = r'@(\w+)'
        return set(re.findall(pattern, conteudo))
    
    def _calcular_complexidade(self, conteudo: str) -> int:
        """Calcula complexidade ciclomática básica"""
        # Conta estruturas de controle
        patterns = [r'\bif\b', r'\bfor\b', r'\bwhile\b', r'\bswitch\b', 
                   r'\bcatch\b', r'\bcase\b', r'\?\s*:', r'&&', r'\|\|']
        
        complexidade = 1  # Base
        for pattern in patterns:
            complexidade += len(re.findall(pattern, conteudo))
        
        return complexidade
    
    def _identificar_bounded_contexts(self):
        """Identifica Bounded Contexts baseado na estrutura de pacotes"""
        print("🎯 Identificando Bounded Contexts...")
        
        contextos_mapeados = {
            'autenticacao': 'Contexto de Autenticação',
            'batepapo': 'Contexto de Bate-Papo', 
            'loteria': 'Contexto de Loteria',
            'transacao': 'Contexto de Transação',
            'monitoramento': 'Contexto de Monitoramento',
            'seguranca': 'Contexto de Segurança',
            'privacidade': 'Contexto de Privacidade',
            'usuario': 'Contexto de Usuário'
        }
        
        for classe in self.classes:
            for contexto_key, contexto_nome in contextos_mapeados.items():
                if contexto_key in classe.pacote.lower():
                    self.bounded_contexts[contexto_nome].append(classe.nome)
                    break
            else:
                # Classes que não se encaixam em contextos específicos
                if classe.tipo in ['Configuration', 'Constants', 'Exception']:
                    self.bounded_contexts['Infraestrutura'].append(classe.nome)
                else:
                    self.bounded_contexts['Não Classificado'].append(classe.nome)
    
    def _detectar_violacoes_ddd(self):
        """Detecta violações de DDD"""
        print("⚠️ Detectando violações DDD...")
        
        for classe in self.classes:
            # Violação 1: Entidades anêmicas
            if classe.tipo == "Entity":
                if self._eh_entidade_anemica(classe):
                    self.violacoes.append(ViolacaoDDD(
                        tipo="ENTIDADE_ANEMICA",
                        severidade="ALTA",
                        classe=classe.nome,
                        descricao=f"Entidade {classe.nome} possui apenas getters/setters",
                        sugestao="Adicionar lógica de domínio e invariantes na entidade"
                    ))
            
            # Violação 2: Services com muitas responsabilidades
            if classe.tipo == "Service" and classe.complexidade > 20:
                self.violacoes.append(ViolacaoDDD(
                    tipo="SERVICE_COMPLEXO",
                    severidade="MEDIA",
                    classe=classe.nome,
                    descricao=f"Service {classe.nome} tem complexidade alta ({classe.complexidade})",
                    sugestao="Dividir em services menores seguindo Single Responsibility"
                ))
            
            # Violação 3: DTOs com anotações JPA
            if classe.tipo == "DTO" and any(ann in classe.anotacoes for ann in ['Entity', 'Table', 'Id']):
                self.violacoes.append(ViolacaoDDD(
                    tipo="DTO_COM_JPA",
                    severidade="ALTA",
                    classe=classe.nome,
                    descricao=f"DTO {classe.nome} possui anotações JPA",
                    sugestao="Separar DTO de entidade JPA, usar mapeamento"
                ))
    
    def _eh_entidade_anemica(self, classe: ClasseAnalise) -> bool:
        """Verifica se uma entidade é anêmica"""
        metodos_negocio = [m for m in classe.metodos 
                          if not m.startswith('get') and not m.startswith('set') 
                          and not m.startswith('is') and m not in ['equals', 'hashCode', 'toString']]
        
        return len(metodos_negocio) < 2  # Menos de 2 métodos de negócio
    
    def _identificar_redundancias(self) -> List[Dict]:
        """Identifica redundâncias no código"""
        print("🔄 Identificando redundâncias...")
        
        redundancias = []
        
        # Agrupar por nome similar
        nomes_similares = defaultdict(list)
        for classe in self.classes:
            nome_base = re.sub(r'(Controller|Service|Repository|DTO|Impl)$', '', classe.nome)
            nomes_similares[nome_base].append(classe)
        
        # Identificar possíveis duplicações
        for nome_base, classes_grupo in nomes_similares.items():
            if len(classes_grupo) > 3:  # Muitas classes com nome similar
                redundancias.append({
                    'tipo': 'NOMES_SIMILARES',
                    'nome_base': nome_base,
                    'classes': [c.nome for c in classes_grupo],
                    'sugestao': f'Revisar se todas as {len(classes_grupo)} classes são necessárias'
                })
        
        return redundancias
    
    def _analisar_solid(self) -> List[Dict]:
        """Analisa oportunidades de aplicação dos princípios SOLID"""
        print("🔧 Analisando oportunidades SOLID...")
        
        oportunidades = []
        
        for classe in self.classes:
            # Single Responsibility: Classes muito grandes
            if classe.linhas > 500:
                oportunidades.append({
                    'principio': 'Single Responsibility',
                    'classe': classe.nome,
                    'problema': f'Classe muito grande ({classe.linhas} linhas)',
                    'sugestao': 'Dividir em classes menores com responsabilidades específicas'
                })
            
            # Open/Closed: Services que podem ser extensíveis
            if classe.tipo == "Service" and len(classe.metodos) > 10:
                oportunidades.append({
                    'principio': 'Open/Closed',
                    'classe': classe.nome,
                    'problema': f'Service com muitos métodos ({len(classe.metodos)})',
                    'sugestao': 'Considerar padrão Strategy ou Command para extensibilidade'
                })
        
        return oportunidades
    
    def _calcular_metricas(self) -> Dict[str, int]:
        """Calcula métricas do projeto"""
        metricas = {
            'total_classes': len(self.classes),
            'total_linhas': sum(c.linhas for c in self.classes),
            'complexidade_media': sum(c.complexidade for c in self.classes) // len(self.classes) if self.classes else 0,
            'violacoes_alta': len([v for v in self.violacoes if v.severidade == 'ALTA']),
            'violacoes_media': len([v for v in self.violacoes if v.severidade == 'MEDIA']),
            'violacoes_baixa': len([v for v in self.violacoes if v.severidade == 'BAIXA'])
        }
        
        # Métricas por tipo
        tipos = Counter(c.tipo for c in self.classes)
        metricas.update({f'total_{tipo.lower()}': count for tipo, count in tipos.items()})
        
        return metricas

def main():
    parser = argparse.ArgumentParser(description='Analisador Avançado DDD/SOLID')
    parser.add_argument('--projeto', default='.', help='Caminho do projeto')
    parser.add_argument('--output', default='docs/analise', help='Diretório de saída')
    
    args = parser.parse_args()
    
    # Executar análise
    analisador = AnalisadorDDD(args.projeto)
    relatorio = analisador.analisar_projeto()
    
    # Salvar relatório
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    arquivo_json = output_dir / f"analise-ddd-{timestamp}.json"
    
    with open(arquivo_json, 'w', encoding='utf-8') as f:
        json.dump(relatorio.__dict__, f, indent=2, ensure_ascii=False, default=str)
    
    print(f"\n✅ Análise concluída!")
    print(f"📄 Relatório salvo em: {arquivo_json}")
    print(f"📊 Total de classes analisadas: {relatorio.total_classes}")
    print(f"⚠️ Violações encontradas: {len(relatorio.violacoes)}")

if __name__ == "__main__":
    main()
