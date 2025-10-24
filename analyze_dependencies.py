#!/usr/bin/env python3
"""
Analisador de Dependências - Projeto Flutter
Identifica quais arquivos de debug/test/fix podem ser removidos com segurança
"""

import re
import os
from pathlib import Path
from collections import defaultdict
import json

class DependencyAnalyzer:
    def __init__(self, project_path):
        self.project_path = Path(project_path)
        self.lib_path = self.project_path / "lib"
        
        # Categorias de arquivos a analisar
        self.debug_files = []
        self.test_files = []
        self.fix_files = []
        self.other_temp_files = []
        
        # Mapa de dependências: arquivo -> [arquivos que o importam]
        self.imported_by = defaultdict(list)
        
        # Mapa de imports: arquivo -> [arquivos que ele importa]
        self.imports = defaultdict(list)
        
        # Arquivos críticos (não devem ser deletados)
        self.critical_files = [
            'main.dart',
            'token_usuario.dart',
            'firebase_options.dart',
        ]
        
        # Padrões de arquivos temporários/debug
        self.temp_patterns = [
            r'debug_',
            r'test_',
            r'fix_',
            r'force_',
            r'simulate_',
            r'populate_',
            r'quick_',
            r'emergency_',
            r'execute_',
            r'deep_',
            r'simple_',
            r'dual_',
            r'diagnose_',
            r'navigate_to_fix',
        ]
    
    def scan_all_files(self):
        """Escaneia todos os arquivos .dart do projeto"""
        print("📂 Escaneando estrutura do projeto...")
        
        for dart_file in self.lib_path.rglob("*.dart"):
            relative_path = str(dart_file.relative_to(self.lib_path))
            filename = dart_file.name
            
            # Categorizar arquivo
            if any(re.search(pattern, filename) for pattern in self.temp_patterns):
                if filename.startswith('debug_'):
                    self.debug_files.append(relative_path)
                elif filename.startswith('test_'):
                    self.test_files.append(relative_path)
                elif filename.startswith('fix_') or filename.startswith('force_'):
                    self.fix_files.append(relative_path)
                else:
                    self.other_temp_files.append(relative_path)
            
            # Analisar imports
            self.analyze_imports(dart_file, relative_path)
        
        print(f"✅ Escaneamento concluído!")
        print(f"   - Arquivos debug: {len(self.debug_files)}")
        print(f"   - Arquivos test: {len(self.test_files)}")
        print(f"   - Arquivos fix: {len(self.fix_files)}")
        print(f"   - Outros temporários: {len(self.other_temp_files)}")
    
    def analyze_imports(self, filepath, relative_path):
        """Analisa os imports de um arquivo"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Encontrar todos os imports
            import_pattern = r"import\s+['\"](?:package:whatsapp_chat/)?([^'\"]+)['\"]"
            imports = re.findall(import_pattern, content)
            
            for imported_file in imports:
                # Normalizar path
                imported_file = imported_file.replace('/', os.sep)
                
                # Registrar dependência
                self.imports[relative_path].append(imported_file)
                self.imported_by[imported_file].append(relative_path)
        
        except Exception as e:
            print(f"⚠️  Erro ao analisar {filepath}: {e}")
    
    def classify_risk(self, file_path):
        """Classifica o nível de risco de deletar um arquivo"""
        filename = Path(file_path).name
        
        # Arquivo crítico = NUNCA deletar
        if filename in self.critical_files:
            return "CRITICAL"
        
        # Verificar quantos arquivos importam este
        importers = self.imported_by.get(file_path, [])
        num_importers = len(importers)
        
        # Verificar se algum importador é crítico
        critical_importers = [imp for imp in importers if Path(imp).name in self.critical_files]
        if critical_importers:
            return "HIGH"
        
        # Verificar se é importado por arquivos de produção (não debug/test/fix)
        production_importers = [
            imp for imp in importers 
            if not any(re.search(pattern, Path(imp).name) for pattern in self.temp_patterns)
        ]
        
        if len(production_importers) > 5:
            return "HIGH"
        elif len(production_importers) > 0:
            return "MEDIUM"
        elif num_importers > 0:
            return "LOW"
        else:
            return "SAFE"
    
    def generate_report(self):
        """Gera relatório detalhado de análise"""
        print("\n" + "="*80)
        print("📊 RELATÓRIO DE ANÁLISE DE DEPENDÊNCIAS")
        print("="*80)
        
        all_temp_files = (
            self.debug_files + 
            self.test_files + 
            self.fix_files + 
            self.other_temp_files
        )
        
        # Classificar por risco
        by_risk = {
            'SAFE': [],
            'LOW': [],
            'MEDIUM': [],
            'HIGH': [],
            'CRITICAL': []
        }
        
        for file in all_temp_files:
            risk = self.classify_risk(file)
            by_risk[risk].append(file)
        
        # Imprimir resumo
        print(f"\n🎯 RESUMO POR NÍVEL DE RISCO:")
        print(f"   🟢 SAFE (seguros para deletar):     {len(by_risk['SAFE'])} arquivos")
        print(f"   🟡 LOW (baixo risco):                {len(by_risk['LOW'])} arquivos")
        print(f"   🟠 MEDIUM (risco médio):             {len(by_risk['MEDIUM'])} arquivos")
        print(f"   🔴 HIGH (alto risco):                {len(by_risk['HIGH'])} arquivos")
        print(f"   ⛔ CRITICAL (NÃO deletar):          {len(by_risk['CRITICAL'])} arquivos")
        
        # Detalhes de cada categoria
        for risk_level in ['SAFE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL']:
            files = by_risk[risk_level]
            if not files:
                continue
            
            emoji = {'SAFE': '🟢', 'LOW': '🟡', 'MEDIUM': '🟠', 'HIGH': '🔴', 'CRITICAL': '⛔'}[risk_level]
            print(f"\n{emoji} {risk_level} - {len(files)} arquivo(s):")
            print("-" * 80)
            
            for file in sorted(files):
                importers = self.imported_by.get(file, [])
                print(f"\n   📄 {file}")
                
                if importers:
                    print(f"      Importado por {len(importers)} arquivo(s):")
                    for imp in importers[:5]:  # Mostrar no máximo 5
                        is_critical = Path(imp).name in self.critical_files
                        is_prod = not any(re.search(p, Path(imp).name) for p in self.temp_patterns)
                        
                        marker = ""
                        if is_critical:
                            marker = " ⚠️  CRÍTICO"
                        elif is_prod:
                            marker = " 🏭 PRODUÇÃO"
                        
                        print(f"         - {imp}{marker}")
                    
                    if len(importers) > 5:
                        print(f"         ... e mais {len(importers) - 5}")
                else:
                    print(f"      ✅ Não é importado por nenhum arquivo (ISOLADO)")
        
        return by_risk
    
    def generate_deletion_plan(self, by_risk):
        """Gera plano de deleção por fases"""
        print("\n" + "="*80)
        print("📋 PLANO DE DELEÇÃO RECOMENDADO")
        print("="*80)
        
        phases = [
            {
                'name': 'FASE 1: ARQUIVOS ISOLADOS (ZERO RISCO)',
                'files': by_risk['SAFE'],
                'risk': '🟢 ZERO',
                'test_required': 'Opcional',
            },
            {
                'name': 'FASE 2: BAIXO RISCO',
                'files': by_risk['LOW'],
                'risk': '🟡 BAIXO',
                'test_required': 'flutter run após cada grupo de 10',
            },
            {
                'name': 'FASE 3: RISCO MÉDIO',
                'files': by_risk['MEDIUM'],
                'risk': '🟠 MÉDIO',
                'test_required': 'flutter run após CADA arquivo',
            },
            {
                'name': 'FASE 4: ALTO RISCO',
                'files': by_risk['HIGH'],
                'risk': '🔴 ALTO',
                'test_required': 'Análise manual + flutter run + commit individual',
            },
        ]
        
        for i, phase in enumerate(phases, 1):
            print(f"\n{'='*80}")
            print(f"{phase['name']}")
            print(f"Risco: {phase['risk']} | Teste: {phase['test_required']}")
            print(f"Total: {len(phase['files'])} arquivo(s)")
            print('='*80)
            
            if phase['files']:
                for file in sorted(phase['files'])[:10]:  # Mostrar primeiros 10
                    print(f"   • {file}")
                
                if len(phase['files']) > 10:
                    print(f"   ... e mais {len(phase['files']) - 10} arquivo(s)")
        
        if by_risk['CRITICAL']:
            print(f"\n{'='*80}")
            print("⛔ ARQUIVOS CRÍTICOS - NÃO DELETAR")
            print('='*80)
            for file in by_risk['CRITICAL']:
                print(f"   ⛔ {file}")
    
    def save_detailed_report(self, by_risk):
        """Salva relatório detalhado em arquivo"""
        output_file = self.project_path / "ANALISE_DEPENDENCIAS_DETALHADA.json"
        
        report = {
            'summary': {
                'total_files': len(self.debug_files + self.test_files + self.fix_files + self.other_temp_files),
                'by_category': {
                    'debug': len(self.debug_files),
                    'test': len(self.test_files),
                    'fix': len(self.fix_files),
                    'other': len(self.other_temp_files),
                },
                'by_risk': {
                    'safe': len(by_risk['SAFE']),
                    'low': len(by_risk['LOW']),
                    'medium': len(by_risk['MEDIUM']),
                    'high': len(by_risk['HIGH']),
                    'critical': len(by_risk['CRITICAL']),
                }
            },
            'files_by_risk': {
                risk: [
                    {
                        'path': file,
                        'imported_by': self.imported_by.get(file, []),
                        'imports': self.imports.get(file, []),
                    }
                    for file in files
                ]
                for risk, files in by_risk.items()
            }
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Relatório detalhado salvo em: {output_file.name}")
        
        # Também criar um arquivo markdown mais legível
        md_file = self.project_path / "ANALISE_DEPENDENCIAS_DETALHADA.md"
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write("# 📊 ANÁLISE DETALHADA DE DEPENDÊNCIAS\n\n")
            f.write("## 📈 RESUMO GERAL\n\n")
            f.write(f"- **Total de arquivos temporários:** {report['summary']['total_files']}\n")
            f.write(f"- **Arquivos debug:** {report['summary']['by_category']['debug']}\n")
            f.write(f"- **Arquivos test:** {report['summary']['by_category']['test']}\n")
            f.write(f"- **Arquivos fix:** {report['summary']['by_category']['fix']}\n")
            f.write(f"- **Outros temporários:** {report['summary']['by_category']['other']}\n\n")
            
            f.write("## 🎯 DISTRIBUIÇÃO POR RISCO\n\n")
            f.write(f"- 🟢 **SAFE:** {report['summary']['by_risk']['safe']} arquivos\n")
            f.write(f"- 🟡 **LOW:** {report['summary']['by_risk']['low']} arquivos\n")
            f.write(f"- 🟠 **MEDIUM:** {report['summary']['by_risk']['medium']} arquivos\n")
            f.write(f"- 🔴 **HIGH:** {report['summary']['by_risk']['high']} arquivos\n")
            f.write(f"- ⛔ **CRITICAL:** {report['summary']['by_risk']['critical']} arquivos\n\n")
            
            for risk in ['SAFE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL']:
                emoji = {'SAFE': '🟢', 'LOW': '🟡', 'MEDIUM': '🟠', 'HIGH': '🔴', 'CRITICAL': '⛔'}[risk]
                files_data = report['files_by_risk'][risk]
                
                if files_data:
                    f.write(f"\n## {emoji} {risk}\n\n")
                    for file_data in files_data:
                        f.write(f"### `{file_data['path']}`\n\n")
                        
                        if file_data['imported_by']:
                            f.write(f"**Importado por {len(file_data['imported_by'])} arquivo(s):**\n\n")
                            for imp in file_data['imported_by']:
                                f.write(f"- `{imp}`\n")
                            f.write("\n")
                        else:
                            f.write("✅ **Não é importado por nenhum arquivo (ISOLADO)**\n\n")
        
        print(f"💾 Relatório markdown salvo em: {md_file.name}")

def main():
    print("🔍 ANALISADOR DE DEPENDÊNCIAS - Projeto Flutter")
    print("="*80)
    
    # Caminho do projeto
    project_path = Path("C:/Users/ItaloLior/Downloads/whatsapp_chat-main/whatsapp_chat-main")
    
    if not (project_path / "lib").exists():
        print(f"❌ Erro: Diretório 'lib' não encontrado em {project_path}")
        print("Execute este script da raiz do projeto ou ajuste o caminho.")
        return
    
    # Criar analisador e executar
    analyzer = DependencyAnalyzer(project_path)
    
    print("\n🔎 Iniciando análise...")
    analyzer.scan_all_files()
    
    by_risk = analyzer.generate_report()
    analyzer.generate_deletion_plan(by_risk)
    analyzer.save_detailed_report(by_risk)
    
    print("\n" + "="*80)
    print("✅ ANÁLISE COMPLETA!")
    print("="*80)
    print("\n📋 PRÓXIMOS PASSOS:")
    print("1. Revise os arquivos ANALISE_DEPENDENCIAS_DETALHADA.md e .json")
    print("2. Confirme que concorda com a classificação de risco")
    print("3. Vamos começar pela FASE 1 (arquivos SAFE)")

if __name__ == "__main__":
    main()
