import '../utils/vitrine_profile_filter.dart';
import '../utils/deep_vitrine_debug.dart';

/// Utilitário para testar busca de perfis de vitrine completos
class TestVitrineCompleteSearch {
  
  /// Registra função global para teste no console
  static void registerGlobalTestFunction() {
    print('✅ Funções de teste de vitrine registradas!');
    print('💡 Use as funções diretamente no código para testar');
    
    // Registrar debug profundo
    DeepVitrineDebug.registerGlobalDebugFunction();
  }
  
  /// Executa teste automático na inicialização
  static Future<void> autoTestOnStart() async {
    // Aguardar um pouco para o app carregar
    await Future.delayed(const Duration(seconds: 3));
    
    print('\n🔍 AUTO-TEST: Investigação profunda do perfil @itala3...');
    
    // INVESTIGAÇÃO PROFUNDA - descobrir a verdadeira causa
    await DeepVitrineDebug.investigateItala3Profile();
    
    // Depois fazer o teste normal
    print('\n🎯 Testando busca específica por "itala3"...');
    final itala3Profiles = await VitrineProfileFilter.searchCompleteVitrineProfiles(
      query: 'itala3',
      limit: 5,
    );
    
    print('\n📊 RESULTADO FINAL:');
    print('   • Perfis "itala3" encontrados: ${itala3Profiles.length}');
    
    if (itala3Profiles.isNotEmpty) {
      print('   ✅ SUCESSO! Perfis de vitrine completos encontrados:');
      for (final profile in itala3Profiles) {
        print('      - ${profile.displayName} (@${profile.username})');
        print('        📍 ${profile.city}, ${profile.state}');
        print('        📝 ${profile.bio?.length ?? 0} caracteres de bio');
      }
    } else {
      print('   ❌ PROBLEMA: Nenhum perfil "itala3" de vitrine completo encontrado!');
      print('   🔍 A investigação profunda acima deve revelar a causa exata.');
    }
  }
}