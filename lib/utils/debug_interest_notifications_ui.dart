import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';
import '../utils/fix_firebase_index_interests.dart';

/// Utilitário para debug das notificações de interesse na interface
class DebugInterestNotificationsUI {
  
  /// Debug completo do sistema de notificações na interface
  static Future<void> debugCompleteUI() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'DEBUG_UI');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Starting complete UI debug', 
        tag: 'DEBUG_UI',
        data: {'currentUserId': currentUserId}
      );

      // 1. Verificar se o controller existe
      final controller = Get.find<MatchesController>();
      EnhancedLogger.info('Controller found', 
        tag: 'DEBUG_UI',
        data: {
          'controllerExists': true,
          'currentNotifications': controller.interestNotifications.length,
          'currentCount': controller.interestNotificationsCount.value,
        }
      );

      // 2. Verificar dados no Firebase
      final firebaseNotifications = await FixFirebaseIndexInterests.getInterestNotificationsSimple(currentUserId);
      EnhancedLogger.info('Firebase data checked', 
        tag: 'DEBUG_UI',
        data: {
          'firebaseNotifications': firebaseNotifications.length,
          'notifications': firebaseNotifications.map((n) => {
            'displayName': n['profile']['displayName'],
            'timeAgo': n['timeAgo'],
            'isSimulated': n['isSimulated'],
          }).toList(),
        }
      );

      // 3. Forçar atualização do controller
      await controller.forceLoadInterestNotifications();
      
      // Aguardar um pouco para a atualização
      await Future.delayed(const Duration(milliseconds: 500));
      
      EnhancedLogger.info('Controller updated', 
        tag: 'DEBUG_UI',
        data: {
          'updatedNotifications': controller.interestNotifications.length,
          'updatedCount': controller.interestNotificationsCount.value,
        }
      );

      // 4. Verificar se as notificações estão sendo exibidas
      final shouldShow = controller.interestNotifications.isNotEmpty;
      EnhancedLogger.info('UI display check', 
        tag: 'DEBUG_UI',
        data: {
          'shouldShowNotifications': shouldShow,
          'notificationsData': controller.interestNotifications.map((n) => {
            'displayName': n['profile']['displayName'],
            'timeAgo': n['timeAgo'],
            'isSimulated': n['isSimulated'],
          }).toList(),
        }
      );

      EnhancedLogger.success('Complete UI debug finished', 
        tag: 'DEBUG_UI',
        data: {
          'firebaseCount': firebaseNotifications.length,
          'controllerCount': controller.interestNotifications.length,
          'shouldDisplay': shouldShow,
        }
      );

    } catch (e) {
      EnhancedLogger.error('Failed to debug UI', 
        tag: 'DEBUG_UI',
        error: e
      );
      rethrow;
    }
  }

  /// Força a criação e exibição de notificações de teste
  static Future<void> forceCreateAndShow() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'DEBUG_UI');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Force creating and showing notifications', 
        tag: 'DEBUG_UI',
        data: {'currentUserId': currentUserId}
      );

      // 1. Limpar notificações antigas
      await FixFirebaseIndexInterests.cleanupTestNotifications();
      
      // 2. Criar novas notificações
      await FixFirebaseIndexInterests.createInterestNotificationDirect();
      
      // 3. Forçar carregamento no controller
      final controller = Get.find<MatchesController>();
      await controller.forceLoadInterestNotifications();
      
      // 4. Aguardar atualização
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 5. Verificar resultado
      final finalCount = controller.interestNotifications.length;
      
      EnhancedLogger.success('Force create and show completed', 
        tag: 'DEBUG_UI',
        data: {
          'finalNotificationsCount': finalCount,
          'notifications': controller.interestNotifications.map((n) => {
            'displayName': n['profile']['displayName'],
            'timeAgo': n['timeAgo'],
            'isSimulated': n['isSimulated'],
          }).toList(),
        }
      );

      // Não retornar nada, método é void
    } catch (e) {
      EnhancedLogger.error('Failed to force create and show', 
        tag: 'DEBUG_UI',
        error: e
      );
      rethrow;
    }
  }

  /// Verifica o estado atual da interface
  static Map<String, dynamic> getCurrentUIState() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {'error': 'No user logged in'};

      final controller = Get.find<MatchesController>();
      
      return {
        'userId': currentUser.uid,
        'controllerExists': true,
        'notificationsCount': controller.interestNotifications.length,
        'notificationsCountValue': controller.interestNotificationsCount.value,
        'notifications': controller.interestNotifications.map((n) => {
          'displayName': n['profile']['displayName'],
          'timeAgo': n['timeAgo'],
          'isSimulated': n['isSimulated'],
        }).toList(),
        'shouldShowUI': controller.interestNotifications.isNotEmpty,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}