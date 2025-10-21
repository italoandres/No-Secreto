import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/explore_profiles_repository.dart';
import 'debug_search_profiles.dart';

class TestSearchNow {
  /// Testar busca imediatamente
  static Future<void> testSearchImmediately() async {
    print('🧪 TESTANDO BUSCA IMEDIATAMENTE...\n');

    // 1. Debug da estrutura
    await DebugSearchProfiles.runAllDebug();

    // 2. Testar busca real
    print('\n🔍 TESTANDO BUSCA REAL...');
    
    try {
      final results = await ExploreProfilesRepository.searchProfiles(
        query: 'italo',
        limit: 10,
      );
      
      print('✅ Busca por "italo": ${results.length} resultados');
      
      for (var profile in results) {
        print('   - ${profile.displayName} (${profile.username})');
      }
      
    } catch (e) {
      print('❌ Erro na busca: $e');
    }

    // 3. Testar busca sem filtros
    print('\n🔍 TESTANDO BUSCA SEM QUERY...');
    
    try {
      final results = await ExploreProfilesRepository.searchProfiles(
        limit: 10,
      );
      
      print('✅ Busca sem query: ${results.length} resultados');
      
      for (var profile in results) {
        print('   - ${profile.displayName} (${profile.username})');
      }
      
    } catch (e) {
      print('❌ Erro na busca sem query: $e');
    }

    print('\n✅ TESTE COMPLETO FINALIZADO!');
  }

  /// Função para chamar do controller
  static Future<void> callFromController() async {
    print('🚀 CHAMANDO TESTE DE BUSCA...');
    await testSearchImmediately();
  }
}