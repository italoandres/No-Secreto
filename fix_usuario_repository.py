#!/usr/bin/env python3
"""
Script para corrigir todas as chamadas ao UsuarioRepository
Converte de métodos estáticos para singleton pattern
"""

import os
import re

# Lista de arquivos para corrigir (baseado nos erros do log)
FILES_TO_FIX = [
    'lib/views/completar_perfil_view.dart',
    'lib/views/edit_profile_menu_view.dart',
    'lib/repositories/temporary_chat_repository.dart',
    'lib/views/nosso_proposito_view.dart',
    'lib/views/sinais_isaque_view.dart',
    'lib/views/sinais_rebeca_view.dart',
    'lib/views/username_settings_view.dart',
    'lib/views/profile_completion_view.dart',
    'lib/components/editar_capa_component.dart',
    'lib/controllers/story_interactions_controller.dart',
    'lib/repositories/story_interactions_repository.dart',
    'lib/controllers/profile_completion_controller.dart',
    'lib/services/profile_data_synchronizer.dart',
]

def fix_file(filepath):
    """Corrige um arquivo substituindo UsuarioRepository. por UsuarioRepository."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Substituir todas as ocorrências de UsuarioRepository. (que não seja .instance)
        # Usa negative lookahead para não substituir se já tiver .instance
        pattern = r'UsuarioRepository\.(?!instance)'
        replacement = r'UsuarioRepository.'
        
        content = re.sub(pattern, replacement, content)
        
        # Se houve mudança, salvar o arquivo
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Corrigido: {filepath}")
            return True
        else:
            print(f"⏭️  Sem mudanças: {filepath}")
            return False
            
    except FileNotFoundError:
        print(f"❌ Arquivo não encontrado: {filepath}")
        return False
    except Exception as e:
        print(f"❌ Erro ao processar {filepath}: {e}")
        return False

def main():
    print("🔧 INICIANDO CORREÇÃO AUTOMÁTICA DO USUARIOREPOSITORY\n")
    print(f"📁 Diretório base: {os.getcwd()}\n")
    
    fixed_count = 0
    not_found_count = 0
    no_change_count = 0
    
    for filepath in FILES_TO_FIX:
        if os.path.exists(filepath):
            if fix_file(filepath):
                fixed_count += 1
            else:
                no_change_count += 1
        else:
            print(f"⚠️  Arquivo não existe: {filepath}")
            not_found_count += 1
    
    print("\n" + "="*60)
    print("📊 RESUMO:")
    print(f"✅ Arquivos corrigidos: {fixed_count}")
    print(f"⏭️  Arquivos sem mudanças: {no_change_count}")
    print(f"⚠️  Arquivos não encontrados: {not_found_count}")
    print("="*60)
    
    if fixed_count > 0:
        print("\n✨ CORREÇÃO CONCLUÍDA!")
        print("\n🚀 Agora execute:")
        print("   flutter run")
    else:
        print("\n⚠️  Nenhum arquivo foi corrigido.")
        print("   Verifique se você está na pasta raiz do projeto Flutter.")

if __name__ == '__main__':
    main()
