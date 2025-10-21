import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar o sistema de convites da vitrine
class TestVitrineInvites {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Criar um convite de teste
  static Future<void> createTestInvite({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      EnhancedLogger.info('Creating test invite', 
        tag: 'TEST_VITRINE',
        data: {'from': fromUserId, 'to': toUserId}
      );

      final interest = InterestModel(
        fromUserId: fromUserId,
        toUserId: toUserId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('user_interests').add(interest.toJson());

      EnhancedLogger.success('Test invite created', 
        tag: 'TEST_VITRINE',
        data: {'from': fromUserId, 'to': toUserId}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to create test invite', 
        tag: 'TEST_VITRINE',
        error: e,
        data: {'from': fromUserId, 'to': toUserId}
      );
    }
  }

  /// Listar todos os convites pendentes para um usuário
  static Future<void> listPendingInvites(String userId) async {
    try {
      EnhancedLogger.info('Listing pending invites', 
        tag: 'TEST_VITRINE',
        data: {'userId': userId}
      );

      final invites = await SpiritualProfileRepository.getPendingInterestsForUser(userId);

      EnhancedLogger.info('Pending invites found', 
        tag: 'TEST_VITRINE',
        data: {
          'userId': userId,
          'count': invites.length,
          'invites': invites.map((i) => {
            'id': i.id,
            'from': i.fromUserId,
            'to': i.toUserId,
            'createdAt': i.createdAt?.toIso8601String(),
          }).toList()
        }
      );
    } catch (e) {
      EnhancedLogger.error('Failed to list pending invites', 
        tag: 'TEST_VITRINE',
        error: e,
        data: {'userId': userId}
      );
    }
  }

  /// Limpar todos os convites de teste
  static Future<void> clearTestInvites() async {
    try {
      EnhancedLogger.info('Clearing test invites', tag: 'TEST_VITRINE');

      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      EnhancedLogger.success('Test invites cleared', 
        tag: 'TEST_VITRINE',
        data: {'count': querySnapshot.docs.length}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to clear test invites', 
        tag: 'TEST_VITRINE',
        error: e
      );
    }
  }

  /// Testar o fluxo completo de convites
  static Future<void> testCompleteFlow() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.error('No authenticated user', tag: 'TEST_VITRINE');
        return;
      }

      EnhancedLogger.info('Starting complete flow test', 
        tag: 'TEST_VITRINE',
        data: {'currentUser': currentUser.uid}
      );

      // 1. Listar convites pendentes
      await listPendingInvites(currentUser.uid);

      // 2. Criar um convite de teste (simulando outro usuário)
      const testFromUserId = 'test_user_123';
      await createTestInvite(
        fromUserId: testFromUserId,
        toUserId: currentUser.uid,
      );

      // 3. Listar novamente para ver o novo convite
      await Future.delayed(const Duration(seconds: 2));
      await listPendingInvites(currentUser.uid);

      EnhancedLogger.success('Complete flow test finished', tag: 'TEST_VITRINE');
    } catch (e) {
      EnhancedLogger.error('Complete flow test failed', 
        tag: 'TEST_VITRINE',
        error: e
      );
    }
  }

  /// Verificar se o índice do Firebase está funcionando
  static Future<void> checkFirebaseIndex() async {
    try {
      EnhancedLogger.info('Checking Firebase index', tag: 'TEST_VITRINE');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.error('No authenticated user', tag: 'TEST_VITRINE');
        return;
      }

      // Tentar fazer a query que requer o índice
      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      EnhancedLogger.success('Firebase index is working', 
        tag: 'TEST_VITRINE',
        data: {'documentsFound': querySnapshot.docs.length}
      );
    } catch (e) {
      if (e.toString().contains('requires an index')) {
        EnhancedLogger.error('Firebase index missing', 
          tag: 'TEST_VITRINE',
          error: e,
          data: {
            'solution': 'Create the index using the Firebase Console',
            'indexUrl': 'https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes'
          }
        );
      } else {
        EnhancedLogger.error('Firebase index check failed', 
          tag: 'TEST_VITRINE',
          error: e
        );
      }
    }
  }

  /// Simular cenário completo de teste
  static Future<void> simulateTestScenario() async {
    try {
      EnhancedLogger.info('Starting test scenario simulation', tag: 'TEST_VITRINE');

      // 1. Verificar índice
      await checkFirebaseIndex();

      // 2. Testar fluxo completo
      await testCompleteFlow();

      EnhancedLogger.success('Test scenario completed', tag: 'TEST_VITRINE');
    } catch (e) {
      EnhancedLogger.error('Test scenario failed', 
        tag: 'TEST_VITRINE',
        error: e
      );
    }
  }
}