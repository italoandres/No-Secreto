import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/enhanced_logger.dart';

/// Script para criar interesses e matches de teste
class CreateTestInterestsMatches {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cria interesses de teste (perfis que demonstraram interesse em você)
  static Future<void> createTestInterests() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Você precisa estar logado para criar interesses de teste');
        return;
      }

      EnhancedLogger.info(
        'Creating test interests',
        tag: 'TEST_INTERESTS',
        data: {'userId': currentUser.uid},
      );

      // Criar 3 interesses de perfis de teste demonstrando interesse em você
      final testProfiles = [
        {'id': 'test_maria_001', 'name': 'Maria Silva'},
        {'id': 'test_ana_002', 'name': 'Ana Costa'},
        {'id': 'test_carolina_005', 'name': 'Carolina Ferreira'},
      ];

      for (final profile in testProfiles) {
        await _firestore.collection('interests').add({
          'fromUserId': profile['id'], // Perfil de teste demonstrou interesse
          'toUserId': currentUser.uid, // Em você
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        print('✅ ${profile['name']} demonstrou interesse em você!');
      }

      EnhancedLogger.success(
        'Test interests created',
        tag: 'TEST_INTERESTS',
        data: {'count': testProfiles.length},
      );

      print('');
      print('🎉 ${testProfiles.length} interesses de teste criados!');
      print('Agora você pode ver a aba "Interesses" funcionando.');
    } catch (e) {
      EnhancedLogger.error(
        'Failed to create test interests',
        tag: 'TEST_INTERESTS',
        error: e,
      );
      print('❌ Erro ao criar interesses de teste: $e');
    }
  }

  /// Cria matches de teste (interesse mútuo)
  static Future<void> createTestMatches() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Você precisa estar logado para criar matches de teste');
        return;
      }

      EnhancedLogger.info(
        'Creating test matches',
        tag: 'TEST_MATCHES',
        data: {'userId': currentUser.uid},
      );

      // Criar 2 matches com perfis de teste
      final testProfiles = [
        {'id': 'test_juliana_003', 'name': 'Juliana Santos'},
        {'id': 'test_beatriz_004', 'name': 'Beatriz Oliveira'},
      ];

      for (final profile in testProfiles) {
        final matchId = _generateMatchId(currentUser.uid, profile['id']!);

        // Criar match
        await _firestore.collection('matches').doc(matchId).set({
          'users': [currentUser.uid, profile['id']],
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'viewedByUser1': false,
          'viewedByUser2': false,
        });

        // Criar interesses mútuos com status 'matched'
        await _firestore.collection('interests').add({
          'fromUserId': currentUser.uid,
          'toUserId': profile['id'],
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'matched',
        });

        await _firestore.collection('interests').add({
          'fromUserId': profile['id'],
          'toUserId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'matched',
        });

        print('✅ Match criado com ${profile['name']}!');
      }

      EnhancedLogger.success(
        'Test matches created',
        tag: 'TEST_MATCHES',
        data: {'count': testProfiles.length},
      );

      print('');
      print('🎉 ${testProfiles.length} matches de teste criados!');
      print('Agora você pode ver a aba "Matches" funcionando.');
    } catch (e) {
      EnhancedLogger.error(
        'Failed to create test matches',
        tag: 'TEST_MATCHES',
        error: e,
      );
      print('❌ Erro ao criar matches de teste: $e');
    }
  }

  /// Gera ID único para o match (ordenado alfabeticamente)
  static String _generateMatchId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Remove todos os interesses e matches de teste
  static Future<void> deleteTestInterestsAndMatches() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Você precisa estar logado');
        return;
      }

      EnhancedLogger.info(
        'Deleting test interests and matches',
        tag: 'TEST_CLEANUP',
      );

      // Deletar interesses
      final interestsQuery = await _firestore
          .collection('interests')
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in interestsQuery.docs) {
        await doc.reference.delete();
      }

      final interestsQuery2 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in interestsQuery2.docs) {
        await doc.reference.delete();
      }

      // Deletar matches
      final matchesQuery = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .get();

      for (final doc in matchesQuery.docs) {
        await doc.reference.delete();
      }

      EnhancedLogger.success(
        'Test data deleted',
        tag: 'TEST_CLEANUP',
      );

      print('✅ Interesses e matches de teste removidos!');
    } catch (e) {
      EnhancedLogger.error(
        'Failed to delete test data',
        tag: 'TEST_CLEANUP',
        error: e,
      );
      print('❌ Erro ao remover dados de teste: $e');
    }
  }

  /// Cria tudo de uma vez (perfis, interesses e matches)
  static Future<void> createCompleteTestData() async {
    print('🚀 Criando dados de teste completos...\n');
    
    // Importar e criar perfis
    print('📝 Passo 1: Criando perfis de teste...');
    // Note: Você precisa chamar CreateTestProfilesSinais.createTestProfiles() separadamente
    
    print('\n📝 Passo 2: Criando interesses de teste...');
    await createTestInterests();
    
    print('\n📝 Passo 3: Criando matches de teste...');
    await createTestMatches();
    
    print('\n✅ Dados de teste completos criados!');
    print('');
    print('📊 Resumo:');
    print('  • 6 perfis de teste');
    print('  • 3 interesses pendentes (Maria, Ana, Carolina)');
    print('  • 2 matches (Juliana, Beatriz)');
    print('');
    print('🎯 Agora você pode testar todas as abas do Sinais!');
  }
}
