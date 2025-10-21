import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/interests_repository.dart';
import '../utils/enhanced_logger.dart';
import '../utils/fix_firebase_index_interests.dart';

/// Utilitário para testar o sistema de notificações de interesse
class TestInterestNotifications {
  
  /// Testa o sistema completo de notificações de interesse
  static Future<void> testCompleteSystem() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'TEST_INTEREST');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Testing complete interest notifications system', 
        tag: 'TEST_INTEREST',
        data: {'currentUserId': currentUserId}
      );

      // Usar método que funciona sem índice do Firebase
      await FixFirebaseIndexInterests.testCompleteSystemWithoutIndex();
      
      EnhancedLogger.success('Complete interest notifications system test completed', 
        tag: 'TEST_INTEREST'
      );

    } catch (e) {
      EnhancedLogger.error('Failed to test complete system', 
        tag: 'TEST_INTEREST',
        error: e
      );
      rethrow;
    }
  }



  /// Remove todas as notificações de teste
  static Future<void> cleanupTestNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Cleaning up test notifications', 
        tag: 'TEST_INTEREST',
        data: {'userId': currentUserId}
      );

      // Remover interesse da @itala
      await InterestsRepository.removeInterest('itala_user_id_simulation_$currentUserId');
      
      // Remover interesse do João
      await InterestsRepository.removeInterest('test_user_joao_123_$currentUserId');

      EnhancedLogger.success('Test notifications cleaned up', 
        tag: 'TEST_INTEREST'
      );
    } catch (e) {
      EnhancedLogger.error('Failed to cleanup test notifications', 
        tag: 'TEST_INTEREST',
        error: e
      );
    }
  }

  /// Obtém estatísticas das notificações
  static Future<Map<String, dynamic>> getNotificationsStats() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {};

      final currentUserId = currentUser.uid;
      final notifications = await FixFirebaseIndexInterests.getInterestNotificationsSimple(currentUserId);

      return {
        'totalNotifications': notifications.length,
        'unreadCount': notifications.length, // Por enquanto, todas são não lidas
        'simulatedCount': notifications.where((n) => n['isSimulated'] == true).length,
        'realCount': notifications.where((n) => n['isSimulated'] != true).length,
      };
    } catch (e) {
      EnhancedLogger.error('Failed to get notifications stats', 
        tag: 'TEST_INTEREST',
        error: e
      );
      return {};
    }
  }
}