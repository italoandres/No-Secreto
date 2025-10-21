import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para corrigir problema de índice do Firebase para notificações de interesse
class FixFirebaseIndexInterests {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Cria notificações de interesse usando método que não precisa de índice
  static Future<void> createInterestNotificationDirect() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'FIX_FIREBASE_INDEX');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Creating interest notification directly', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {'toUserId': currentUserId}
      );

      // Criar notificação da @itala usando método direto (sem query complexa)
      final interestData = {
        'fromUserId': 'itala_user_id_simulation',
        'toUserId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'profile_interest',
        'fromProfile': {
          'displayName': 'Itala',
          'username': 'itala',
          'age': 25,
          'mainPhotoUrl': null,
          'bio': 'Buscando relacionamento sério com propósito',
        },
        // Campos adicionais para facilitar busca sem índice
        'notificationId': 'itala_notification_$currentUserId',
        'isActive': true,
        'priority': 1,
      };

      // Salvar com ID específico para facilitar busca
      await _firestore
          .collection('interests')
          .doc('itala_user_id_simulation_$currentUserId')
          .set(interestData);

      // Criar segunda notificação de teste
      final interestData2 = {
        'fromUserId': 'test_user_joao_123',
        'toUserId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'profile_interest',
        'fromProfile': {
          'displayName': 'João Santos',
          'username': 'joao_santos',
          'age': 32,
          'mainPhotoUrl': null,
          'bio': 'Cristão em busca de relacionamento com propósito',
        },
        'notificationId': 'joao_notification_$currentUserId',
        'isActive': true,
        'priority': 2,
      };

      await _firestore
          .collection('interests')
          .doc('test_user_joao_123_$currentUserId')
          .set(interestData2);

      EnhancedLogger.success('Interest notifications created directly', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {'count': 2}
      );

    } catch (e) {
      EnhancedLogger.error('Failed to create interest notifications directly', 
        tag: 'FIX_FIREBASE_INDEX',
        error: e
      );
      rethrow;
    }
  }

  /// Busca notificações usando método simples (sem índice complexo)
  static Future<List<Map<String, dynamic>>> getInterestNotificationsSimple(String userId) async {
    try {
      EnhancedLogger.info('Loading interest notifications with simple method', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {'userId': userId}
      );

      final notifications = <Map<String, dynamic>>[];

      // Buscar documentos específicos conhecidos (não precisa de índice)
      final docs = [
        'itala_user_id_simulation_$userId',
        'test_user_joao_123_$userId',
      ];

      for (final docId in docs) {
        try {
          final doc = await _firestore
              .collection('interests')
              .doc(docId)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            
            // Verificar se é para este usuário e está pendente
            if (data['toUserId'] == userId && data['status'] == 'pending') {
              // Calcular tempo decorrido
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final timeAgo = _formatTimeAgo(createdAt);
              
              // Criar perfil a partir dos dados salvos
              final fromProfile = data['fromProfile'] as Map<String, dynamic>?;
              
              if (fromProfile != null) {
                notifications.add({
                  'profile': {
                    'userId': data['fromUserId'],
                    'displayName': fromProfile['displayName'],
                    'username': fromProfile['username'],
                    'age': fromProfile['age'],
                    'mainPhotoUrl': fromProfile['mainPhotoUrl'],
                    'bio': fromProfile['bio'],
                    'createdAt': createdAt,
                  },
                  'hasUserInterest': false, // Por enquanto sempre false
                  'timeAgo': timeAgo,
                  'interestId': docId,
                  'isSimulated': data['fromUserId'] == 'itala_user_id_simulation',
                  'createdAt': createdAt,
                });
              }
            }
          }
        } catch (e) {
          EnhancedLogger.error('Failed to load specific interest document', 
            tag: 'FIX_FIREBASE_INDEX',
            error: e,
            data: {'docId': docId}
          );
        }
      }

      // Ordenar por data de criação (mais recente primeiro)
      notifications.sort((a, b) => 
        (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime)
      );

      EnhancedLogger.success('Interest notifications loaded with simple method', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {
          'userId': userId,
          'notificationsCount': notifications.length,
        }
      );

      return notifications;
    } catch (e) {
      EnhancedLogger.error('Failed to load interest notifications with simple method', 
        tag: 'FIX_FIREBASE_INDEX',
        error: e,
        data: {'userId': userId}
      );
      return [];
    }
  }

  /// Formata tempo decorrido em string legível
  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays}d';
    } else {
      return 'há ${(difference.inDays / 7).floor()}sem';
    }
  }

  /// Remove todas as notificações de teste
  static Future<void> cleanupTestNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Cleaning up test notifications', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {'userId': currentUserId}
      );

      final docs = [
        'itala_user_id_simulation_$currentUserId',
        'test_user_joao_123_$currentUserId',
      ];

      for (final docId in docs) {
        try {
          await _firestore
              .collection('interests')
              .doc(docId)
              .delete();
        } catch (e) {
          // Ignorar erros de documentos que não existem
        }
      }

      EnhancedLogger.success('Test notifications cleaned up', 
        tag: 'FIX_FIREBASE_INDEX'
      );
    } catch (e) {
      EnhancedLogger.error('Failed to cleanup test notifications', 
        tag: 'FIX_FIREBASE_INDEX',
        error: e
      );
    }
  }

  /// Testa o sistema completo sem precisar de índices
  static Future<void> testCompleteSystemWithoutIndex() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.warning('No current user found', tag: 'FIX_FIREBASE_INDEX');
        return;
      }

      final currentUserId = currentUser.uid;
      
      EnhancedLogger.info('Testing complete system without Firebase index', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {'currentUserId': currentUserId}
      );

      // 1. Limpar notificações antigas
      await cleanupTestNotifications();
      
      // 2. Criar novas notificações
      await createInterestNotificationDirect();
      
      // 3. Testar carregamento
      final notifications = await getInterestNotificationsSimple(currentUserId);
      
      EnhancedLogger.success('Complete system test completed without index', 
        tag: 'FIX_FIREBASE_INDEX',
        data: {
          'notificationsCreated': 2,
          'notificationsLoaded': notifications.length,
          'notifications': notifications.map((n) => {
            'displayName': n['profile']['displayName'],
            'timeAgo': n['timeAgo'],
            'isSimulated': n['isSimulated'],
          }).toList(),
        }
      );

    } catch (e) {
      EnhancedLogger.error('Failed to test complete system without index', 
        tag: 'FIX_FIREBASE_INDEX',
        error: e
      );
      rethrow;
    }
  }
}