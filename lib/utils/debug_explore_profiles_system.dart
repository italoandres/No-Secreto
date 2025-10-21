import 'package:cloud_firestore/cloud_firestore.dart';
import 'populate_explore_profiles_test_data.dart';

/// Utilitário para debug e teste do sistema Explorar Perfis
class DebugExploreProfilesSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Executa diagnóstico completo do sistema
  static Future<void> runFullDiagnosis() async {
    print('🔍 DIAGNÓSTICO COMPLETO - Sistema Explorar Perfis');
    print('=' * 60);

    await _checkFirebaseConnection();
    await _checkCollections();
    await _checkIndexes();
    await _populateTestDataIfNeeded();
    await _testQueries();
    
    print('=' * 60);
    print('✅ Diagnóstico completo finalizado!');
  }

  /// Verifica conexão com Firebase
  static Future<void> _checkFirebaseConnection() async {
    print('\n📡 Verificando conexão com Firebase...');
    try {
      await _firestore.collection('test').limit(1).get();
      print('✅ Conexão com Firebase: OK');
    } catch (e) {
      print('❌ Erro na conexão com Firebase: $e');
    }
  }

  /// Verifica se as coleções existem e têm dados
  static Future<void> _checkCollections() async {
    print('\n📊 Verificando coleções...');
    
    // Verificar spiritual_profiles
    try {
      final profilesSnapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(5)
          .get();
      print('✅ spiritual_profiles: ${profilesSnapshot.docs.length} documentos');
      
      if (profilesSnapshot.docs.isNotEmpty) {
        final firstDoc = profilesSnapshot.docs.first.data();
        print('   📝 Campos do primeiro documento:');
        firstDoc.keys.take(5).forEach((key) {
          print('      - $key: ${firstDoc[key]}');
        });
      }
    } catch (e) {
      print('❌ Erro ao verificar spiritual_profiles: $e');
    }

    // Verificar profile_engagement
    try {
      final engagementSnapshot = await _firestore
          .collection('profile_engagement')
          .limit(5)
          .get();
      print('✅ profile_engagement: ${engagementSnapshot.docs.length} documentos');
    } catch (e) {
      print('❌ Erro ao verificar profile_engagement: $e');
    }
  }

  /// Verifica status dos índices testando queries
  static Future<void> _checkIndexes() async {
    print('\n🔍 Testando índices...');

    // Teste 1: Verified profiles (deve funcionar)
    try {
      final verifiedQuery = await _firestore
          .collection('spiritual_profiles')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();
      print('✅ Índice verified profiles: OK (${verifiedQuery.docs.length} resultados)');
    } catch (e) {
      print('❌ Índice verified profiles: ERRO - $e');
    }

    // Teste 2: Popular profiles (viewsCount)
    try {
      final popularQuery = await _firestore
          .collection('spiritual_profiles')
          .where('hasCompletedSinaisCoursе', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('viewsCount', descending: true)
          .limit(5)
          .get();
      print('✅ Índice popular profiles: OK (${popularQuery.docs.length} resultados)');
    } catch (e) {
      print('❌ Índice popular profiles: ERRO - $e');
    }

    // Teste 3: Profile engagement
    try {
      final engagementQuery = await _firestore
          .collection('profile_engagement')
          .where('isEligibleForExploration', isEqualTo: true)
          .orderBy('engagementScore', descending: true)
          .limit(5)
          .get();
      print('✅ Índice profile engagement: OK (${engagementQuery.docs.length} resultados)');
    } catch (e) {
      print('❌ Índice profile engagement: ERRO - $e');
    }

    // Teste 4: Search keywords (mais provável de falhar)
    try {
      final searchQuery = await _firestore
          .collection('spiritual_profiles')
          .where('searchKeywords', arrayContains: 'maria')
          .where('hasCompletedSinaisCoursе', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .limit(5)
          .get();
      print('✅ Índice search keywords: OK (${searchQuery.docs.length} resultados)');
    } catch (e) {
      print('❌ Índice search keywords: ERRO - $e');
      print('   🔗 Criar índice: https://console.firebase.google.com/...');
    }
  }

  /// Popula dados de teste se necessário
  static Future<void> _populateTestDataIfNeeded() async {
    print('\n📝 Verificando dados de teste...');
    
    final exists = await PopulateExploreProfilesTestData.testDataExists();
    if (!exists) {
      print('⚠️ Dados de teste não encontrados. Populando...');
      try {
        await PopulateExploreProfilesTestData.populateTestData();
        print('✅ Dados de teste populados com sucesso!');
      } catch (e) {
        print('❌ Erro ao popular dados de teste: $e');
      }
    } else {
      print('✅ Dados de teste já existem');
    }
  }

  /// Testa queries específicas do sistema
  static Future<void> _testQueries() async {
    print('\n🧪 Testando queries do sistema...');

    // Simular busca por "maria"
    try {
      final searchResults = await _firestore
          .collection('spiritual_profiles')
          .where('searchKeywords', arrayContains: 'maria')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .limit(10)
          .get();
      
      print('✅ Busca por "maria": ${searchResults.docs.length} resultados');
      
      if (searchResults.docs.isNotEmpty) {
        final firstResult = searchResults.docs.first.data();
        print('   📝 Primeiro resultado: ${firstResult['displayName']}');
      }
    } catch (e) {
      print('❌ Busca por "maria": ERRO - $e');
    }

    // Testar query de engajamento
    try {
      final engagementResults = await _firestore
          .collection('profile_engagement')
          .where('isEligibleForExploration', isEqualTo: true)
          .orderBy('engagementScore', descending: true)
          .limit(10)
          .get();
      
      print('✅ Query engajamento: ${engagementResults.docs.length} resultados');
    } catch (e) {
      print('❌ Query engajamento: ERRO - $e');
    }
  }

  /// Força recriação dos dados de teste
  static Future<void> recreateTestData() async {
    print('🔄 Recriando dados de teste...');
    
    try {
      // Limpar dados existentes
      await PopulateExploreProfilesTestData.clearTestData();
      print('🗑️ Dados antigos removidos');
      
      // Aguardar um pouco
      await Future.delayed(const Duration(seconds: 2));
      
      // Criar novos dados
      await PopulateExploreProfilesTestData.populateTestData();
      print('✅ Novos dados criados com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao recriar dados: $e');
    }
  }

  /// Mostra instruções para resolver problemas
  static void showTroubleshootingInstructions() {
    print('\n🔧 INSTRUÇÕES DE RESOLUÇÃO DE PROBLEMAS');
    print('=' * 60);
    
    print('\n1. 📊 Se "count: 0" nas queries:');
    print('   - Execute: DebugExploreProfilesSystem.recreateTestData()');
    print('   - Aguarde 1-2 minutos');
    print('   - Teste novamente');
    
    print('\n2. ❌ Se erro "Index required":');
    print('   - Vá para Firebase Console → Firestore → Indexes');
    print('   - Verifique se todos os índices estão "Enabled"');
    print('   - Se "Building", aguarde conclusão');
    
    print('\n3. 🔍 Para testar busca:');
    print('   - Certifique-se que dados têm searchKeywords');
    print('   - Teste buscar por: "maria", "joão", "ana"');
    
    print('\n4. 🚀 Links dos índices:');
    print('   - Profile Engagement: [link fornecido anteriormente]');
    print('   - Popular Profiles: [link fornecido anteriormente]');
    print('   - Search Keywords: [link fornecido anteriormente]');
    
    print('\n=' * 60);
  }
}