import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para simular interesse da @itala no usuário atual
class SimulateItalaInterest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Simula que a @itala demonstrou interesse no usuário atual
  static Future<void> simulateInterestFromItala() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'SIMULATE_INTEREST');
        return;
      }

      final currentUserId = currentUser.uid;
      
      // ID simulado da @itala (você pode ajustar conforme necessário)
      const italaUserId = 'itala_user_id_simulation';
      
      EnhancedLogger.info('Simulating interest from @itala', 
        tag: 'SIMULATE_INTEREST',
        data: {
          'fromUserId': italaUserId,
          'toUserId': currentUserId,
        }
      );

      // Criar documento de interesse no Firebase
      final interestData = {
        'fromUserId': italaUserId,
        'toUserId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, accepted, rejected
        'type': 'profile_interest',
        'fromProfile': {
          'displayName': 'Itala',
          'username': 'itala',
          'age': 25,
          'mainPhotoUrl': null,
          'bio': 'Buscando relacionamento sério com propósito',
        },
      };

      // Salvar no Firestore
      await _firestore
          .collection('interests')
          .doc('${italaUserId}_${currentUserId}')
          .set(interestData);

      EnhancedLogger.success('Interest from @itala simulated successfully', 
        tag: 'SIMULATE_INTEREST',
        data: {'interestId': '${italaUserId}_${currentUserId}'}
      );

    } catch (e) {
      EnhancedLogger.error('Failed to simulate interest from @itala', 
        tag: 'SIMULATE_INTEREST',
        error: e
      );
      rethrow;
    }
  }

  /// Remove a simulação de interesse da @itala
  static Future<void> removeSimulatedInterest() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      const italaUserId = 'itala_user_id_simulation';
      final currentUserId = currentUser.uid;

      await _firestore
          .collection('interests')
          .doc('${italaUserId}_${currentUserId}')
          .delete();

      EnhancedLogger.success('Simulated interest removed', 
        tag: 'SIMULATE_INTEREST'
      );

    } catch (e) {
      EnhancedLogger.error('Failed to remove simulated interest', 
        tag: 'SIMULATE_INTEREST',
        error: e
      );
    }
  }

  /// Verifica se existe interesse simulado da @itala
  static Future<bool> hasSimulatedInterest() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      const italaUserId = 'itala_user_id_simulation';
      final currentUserId = currentUser.uid;

      final doc = await _firestore
          .collection('interests')
          .doc('${italaUserId}_${currentUserId}')
          .get();

      return doc.exists;
    } catch (e) {
      EnhancedLogger.error('Failed to check simulated interest', 
        tag: 'SIMULATE_INTEREST',
        error: e
      );
      return false;
    }
  }
}