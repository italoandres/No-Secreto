import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';
import '../utils/fix_firebase_index_interests.dart';

/// Utilitário para forçar atualização da interface de notificações
class ForceUIRefreshNotifications {
  
  /// Força a atualização completa da interface
  static Future<void> forceCompleteUIRefresh() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'FORCE_UI');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Starting force UI refresh', 
        tag: 'FORCE_UI',
        data: {'currentUserId': currentUserId}
      );

      // 1. Obter controller
      final controller = Get.find<MatchesController>();
      
      // 2. Limpar dados antigos
      controller.interestNotifications.clear();
      controller.interestNotificationsCount.value = 0;
      
      // 3. Aguardar um frame
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 4. Carregar dados do Firebase
      final notifications = await FixFirebaseIndexInterests.getInterestNotificationsSimple(currentUserId);
      
      // 5. Atualizar controller diretamente
      controller.interestNotifications.value = notifications;
      controller.interestNotificationsCount.value = notifications.length;
      
      // 6. Forçar rebuild da interface
      controller.interestNotifications.refresh();
      
      // 7. Aguardar atualização
      await Future.delayed(const Duration(milliseconds: 500));
      
      EnhancedLogger.success('Force UI refresh completed', 
        tag: 'FORCE_UI',
        data: {
          'notificationsLoaded': notifications.length,
          'controllerUpdated': controller.interestNotifications.length,
          'shouldShow': controller.interestNotifications.isNotEmpty,
          'notifications': notifications.map((n) => {
            'displayName': n['profile']['displayName'],
            'timeAgo': n['timeAgo'],
            'isSimulated': n['isSimulated'],
          }).toList(),
        }
      );

    } catch (e) {
      EnhancedLogger.error('Failed to force UI refresh', 
        tag: 'FORCE_UI',
        error: e
      );
      rethrow;
    }
  }

  /// Cria notificações de interesse do @italo2 para @itala
  static Future<void> createItalo2InterestForItala() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'FORCE_UI');
        return;
      }

      final currentUserId = currentUser.uid; // Este é o ID da @itala
      
      EnhancedLogger.info('Creating @italo2 interest for @itala', 
        tag: 'FORCE_UI',
        data: {
          'fromUserId': 'DSMhyNtfPAe9jZtjkon34Zi7eit2', // ID do @italo2
          'toUserId': currentUserId, // ID da @itala
        }
      );

      // Criar interesse do @italo2 para @itala
      const italo2UserId = 'DSMhyNtfPAe9jZtjkon34Zi7eit2';
      
      final interestData = {
        'fromUserId': italo2UserId,
        'toUserId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'profile_interest',
        'fromProfile': {
          'displayName': 'Italo',
          'username': 'italo2',
          'age': 28,
          'mainPhotoUrl': null,
          'bio': 'Cristão em busca de relacionamento sério',
        },
        'notificationId': 'italo2_notification_$currentUserId',
        'isActive': true,
        'priority': 1,
      };

      // Salvar no Firebase
      await FirebaseFirestore.instance
          .collection('interests')
          .doc('${italo2UserId}_$currentUserId')
          .set(interestData);

      EnhancedLogger.success('@italo2 interest created for @itala', 
        tag: 'FORCE_UI',
        data: {'interestId': '${italo2UserId}_$currentUserId'}
      );

    } catch (e) {
      EnhancedLogger.error('Failed to create @italo2 interest', 
        tag: 'FORCE_UI',
        error: e
      );
      rethrow;
    }
  }

  /// Sistema completo: cria interesse real e força exibição
  static Future<void> createRealInterestAndShow() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'FORCE_UI');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Creating real interest and forcing UI show', 
        tag: 'FORCE_UI',
        data: {'currentUserId': currentUserId}
      );

      // 1. Criar interesse real do @italo2
      await createItalo2InterestForItala();
      
      // 2. Aguardar salvamento
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 3. Forçar atualização da interface
      await forceCompleteUIRefresh();
      
      EnhancedLogger.success('Real interest created and UI forced to show', 
        tag: 'FORCE_UI'
      );

    } catch (e) {
      EnhancedLogger.error('Failed to create real interest and show', 
        tag: 'FORCE_UI',
        error: e
      );
      rethrow;
    }
  }

  /// Verifica se as notificações estão visíveis na interface
  static bool areNotificationsVisible() {
    try {
      final controller = Get.find<MatchesController>();
      final hasNotifications = controller.interestNotifications.isNotEmpty;
      final count = controller.interestNotifications.length;
      
      EnhancedLogger.info('Checking notifications visibility', 
        tag: 'FORCE_UI',
        data: {
          'hasNotifications': hasNotifications,
          'count': count,
          'shouldBeVisible': hasNotifications,
        }
      );
      
      return hasNotifications;
    } catch (e) {
      EnhancedLogger.error('Failed to check notifications visibility', 
        tag: 'FORCE_UI',
        error: e
      );
      return false;
    }
  }
}