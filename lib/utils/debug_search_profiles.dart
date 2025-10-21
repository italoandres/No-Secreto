import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

class DebugSearchProfiles {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug: Verificar estrutura dos perfis
  static Future<void> debugProfileStructure() async {
    try {
      print('🔍 DEBUG: Verificando estrutura dos perfis...');
      
      // Buscar alguns perfis para análise
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(3)
          .get();

      print('📊 Total de perfis encontrados: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('\n📋 PERFIL: ${doc.id}');
        print('   - displayName: ${data['displayName']}');
        print('   - username: ${data['username']}');
        print('   - isActive: ${data['isActive']}');
        print('   - isVerified: ${data['isVerified']}');
        print('   - hasCompletedSinaisCourse: ${data['hasCompletedSinaisCourse']}');
        print('   - searchKeywords: ${data['searchKeywords']}');
        print('   - age: ${data['age']}');
        print('   - city: ${data['city']}');
      }
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }

  /// Debug: Testar busca simples
  static Future<void> debugSimpleSearch(String query) async {
    try {
      print('\n🔍 DEBUG: Testando busca simples por "$query"...');
      
      // Teste 1: Busca sem filtros
      print('\n1️⃣ Teste sem filtros:');
      final snapshot1 = await _firestore
          .collection('spiritual_profiles')
          .limit(10)
          .get();
      print('   Resultados: ${snapshot1.docs.length}');

      // Teste 2: Busca só com isActive
      print('\n2️⃣ Teste só com isActive:');
      final snapshot2 = await _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();
      print('   Resultados: ${snapshot2.docs.length}');

      // Teste 3: Busca com searchKeywords
      print('\n3️⃣ Teste com searchKeywords:');
      try {
        final snapshot3 = await _firestore
            .collection('spiritual_profiles')
            .where('searchKeywords', arrayContains: query.toLowerCase())
            .limit(10)
            .get();
        print('   Resultados: ${snapshot3.docs.length}');
      } catch (e) {
        print('   ❌ Erro: $e');
      }

      // Teste 4: Busca por displayName
      print('\n4️⃣ Teste por displayName:');
      final snapshot4 = await _firestore
          .collection('spiritual_profiles')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + 'z')
          .limit(10)
          .get();
      print('   Resultados: ${snapshot4.docs.length}');

    } catch (e) {
      print('❌ Erro no debug de busca: $e');
    }
  }

  /// Debug: Verificar campos específicos
  static Future<void> debugSpecificFields() async {
    try {
      print('\n🔍 DEBUG: Verificando campos específicos...');
      
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(5)
          .get();

      int activeCount = 0;
      int verifiedCount = 0;
      int courseCount = 0;
      int keywordsCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        if (data['isActive'] == true) activeCount++;
        if (data['isVerified'] == true) verifiedCount++;
        if (data['hasCompletedSinaisCourse'] == true) courseCount++;
        if (data['searchKeywords'] != null) keywordsCount++;
      }

      print('📊 ESTATÍSTICAS (de ${snapshot.docs.length} perfis):');
      print('   - isActive: $activeCount');
      print('   - isVerified: $verifiedCount');
      print('   - hasCompletedSinaisCourse: $courseCount');
      print('   - tem searchKeywords: $keywordsCount');

    } catch (e) {
      print('❌ Erro no debug de campos: $e');
    }
  }

  /// Executar todos os debugs
  static Future<void> runAllDebug() async {
    print('🚀 INICIANDO DEBUG COMPLETO DA BUSCA...\n');
    
    await debugProfileStructure();
    await debugSpecificFields();
    await debugSimpleSearch('italo');
    
    print('\n✅ DEBUG COMPLETO FINALIZADO!');
  }
}