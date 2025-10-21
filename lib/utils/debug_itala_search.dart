import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';
import '../utils/unified_profile_search.dart';

/// Debug específico para encontrar o perfil "Itala"
class DebugItalaSearch {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug completo da busca por "Itala"
  static Future<void> debugItalaSearch() async {
    print('\n🔍 DEBUG: Procurando perfil "Itala"');
    print('=' * 60);

    try {
      // 1. Verificar se existe na coleção usuarios
      await _debugUsuariosCollection();
      
      // 2. Verificar se existe na coleção spiritual_profiles
      await _debugSpiritualProfilesCollection();
      
      // 3. Testar busca unificada com logs detalhados
      await _debugUnifiedSearch();
      
      // 4. Testar filtro de texto isoladamente
      await _debugTextFilter();

    } catch (e) {
      print('❌ ERRO NO DEBUG: $e');
    }
  }

  /// Debug da coleção usuarios
  static Future<void> _debugUsuariosCollection() async {
    print('\n📊 1. DEBUG: Coleção "usuarios"');
    print('-' * 40);

    try {
      // Buscar todos os usuários
      final snapshot = await _firestore
          .collection('usuarios')
          .limit(20)
          .get();

      print('✅ Total de usuários encontrados: ${snapshot.docs.length}');
      
      // Procurar por "Itala" especificamente
      bool italaFound = false;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nome = data['nome'] as String? ?? '';
        
        print('   - ${doc.id}: ${nome}');
        
        if (nome.toLowerCase().contains('itala')) {
          italaFound = true;
          print('   🎯 ENCONTROU ITALA!');
          print('   📋 Dados completos:');
          print('      • ID: ${doc.id}');
          print('      • Nome: ${nome}');
          print('      • Username: ${data['username'] ?? 'N/A'}');
          print('      • Email: ${data['email'] ?? 'N/A'}');
          print('      • Cidade: ${data['cidade'] ?? 'N/A'}');
          print('      • Estado: ${data['estado'] ?? 'N/A'}');
          print('      • IsActive: ${data['isActive'] ?? 'N/A'}');
          print('      • Foto: ${data['foto'] ?? 'N/A'}');
        }
      }
      
      if (!italaFound) {
        print('❌ Perfil "Itala" NÃO encontrado na coleção usuarios');
      }

    } catch (e) {
      print('❌ Erro ao buscar na coleção usuarios: $e');
    }
  }

  /// Debug da coleção spiritual_profiles
  static Future<void> _debugSpiritualProfilesCollection() async {
    print('\n📊 2. DEBUG: Coleção "spiritual_profiles"');
    print('-' * 40);

    try {
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(20)
          .get();

      print('✅ Total de perfis espirituais: ${snapshot.docs.length}');
      
      bool italaFound = false;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final displayName = data['displayName'] as String? ?? '';
        
        print('   - ${doc.id}: ${displayName}');
        
        if (displayName.toLowerCase().contains('itala')) {
          italaFound = true;
          print('   🎯 ENCONTROU ITALA em spiritual_profiles!');
          print('   📋 Dados: ${data}');
        }
      }
      
      if (!italaFound) {
        print('❌ Perfil "Itala" NÃO encontrado na coleção spiritual_profiles');
      }

    } catch (e) {
      print('❌ Erro ao buscar na coleção spiritual_profiles: $e');
    }
  }

  /// Debug da busca unificada
  static Future<void> _debugUnifiedSearch() async {
    print('\n📊 3. DEBUG: Busca Unificada');
    print('-' * 40);

    try {
      print('🔍 Testando busca unificada por "itala"...');
      
      final results = await UnifiedProfileSearch.searchAllProfiles(
        query: 'itala',
        limit: 50,
      );
      
      print('✅ Resultados da busca unificada: ${results.length}');
      
      if (results.isEmpty) {
        print('❌ NENHUM resultado para "itala"');
        
        // Testar sem query para ver todos os perfis
        print('\n🔍 Testando busca SEM filtro de texto...');
        final allResults = await UnifiedProfileSearch.searchAllProfiles(
          query: null,
          limit: 50,
        );
        
        print('✅ Total de perfis sem filtro: ${allResults.length}');
        
        // Procurar "Itala" manualmente nos resultados
        for (final profile in allResults) {
          final name = profile.displayName ?? '';
          if (name.toLowerCase().contains('itala')) {
            print('🎯 ENCONTROU ITALA nos resultados sem filtro!');
            print('   📋 Nome: ${name}');
            print('   📋 Tipo: ${profile.profileType ?? 'spiritual'}');
            print('   📋 Keywords: ${profile.searchKeywords ?? []}');
            print('   📋 Bio: ${profile.bio ?? 'N/A'}');
            print('   📋 Cidade: ${profile.city ?? 'N/A'}');
          }
        }
      } else {
        for (final profile in results) {
          print('   ✅ ${profile.displayName} (${profile.profileType ?? 'spiritual'})');
        }
      }

    } catch (e) {
      print('❌ Erro na busca unificada: $e');
    }
  }

  /// Debug do filtro de texto
  static Future<void> _debugTextFilter() async {
    print('\n📊 4. DEBUG: Filtro de Texto');
    print('-' * 40);

    try {
      // Simular o filtro de texto com dados de teste
      print('🔍 Testando filtro de texto com dados simulados...');
      
      // Criar perfil de teste que simula "Itala"
      final testProfile = {
        'displayName': 'Itala',
        'bio': 'Perfil de vitrine de propósito',
        'city': 'São Paulo',
        'state': 'SP',
        'searchKeywords': ['itala', 'são', 'paulo', 'sp'],
      };
      
      final searchableText = [
        testProfile['displayName'] ?? '',
        testProfile['bio'] ?? '',
        testProfile['city'] ?? '',
        testProfile['state'] ?? '',
        ...(testProfile['searchKeywords'] as List<String>? ?? []),
      ].join(' ').toLowerCase();
      
      print('📋 Texto pesquisável: "$searchableText"');
      
      // Testar diferentes queries
      final queries = ['itala', 'ital', 'ita', 'it'];
      
      for (final query in queries) {
        final queryLower = query.toLowerCase();
        final matches = searchableText.contains(queryLower);
        
        print('   🔍 Query "$query" → ${matches ? '✅ MATCH' : '❌ NO MATCH'}');
      }

    } catch (e) {
      print('❌ Erro no debug do filtro: $e');
    }
  }

  /// Executa debug completo e retorna informações
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final info = <String, dynamic>{};
    
    try {
      // Contar usuários
      final usuariosSnapshot = await _firestore
          .collection('usuarios')
          .limit(50)
          .get();
      
      info['totalUsuarios'] = usuariosSnapshot.docs.length;
      info['usuariosComItala'] = usuariosSnapshot.docs
          .where((doc) => (doc.data()['nome'] as String? ?? '')
              .toLowerCase()
              .contains('itala'))
          .length;
      
      // Contar perfis espirituais
      final spiritualSnapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(50)
          .get();
      
      info['totalSpiritual'] = spiritualSnapshot.docs.length;
      info['spiritualComItala'] = spiritualSnapshot.docs
          .where((doc) => (doc.data()['displayName'] as String? ?? '')
              .toLowerCase()
              .contains('itala'))
          .length;
      
      // Testar busca unificada
      final unifiedResults = await UnifiedProfileSearch.searchAllProfiles(
        query: 'itala',
        limit: 50,
      );
      
      info['buscaUnificadaResultados'] = unifiedResults.length;
      info['buscaUnificadaComItala'] = unifiedResults
          .where((profile) => (profile.displayName ?? '')
              .toLowerCase()
              .contains('itala'))
          .length;

    } catch (e) {
      info['erro'] = e.toString();
    }
    
    return info;
  }
}