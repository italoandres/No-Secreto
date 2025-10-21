import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/enhanced_logger.dart';

/// Repository para gerenciar interesses entre usuários
class InterestsRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _interestsCollection = 'interests';

  /// Obtém todas as notificações de interesse para um usuário
  static Future<List<Map<String, dynamic>>> getInterestNotifications(String userId) async {
    try {
      EnhancedLogger.info('Loading interest notifications', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'userId': userId}
      );

      // Buscar interesses onde o usuário é o destinatário
      final query = await _firestore
          .collection(_interestsCollection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final notifications = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        try {
          final data = doc.data();
          
          // Calcular tempo decorrido
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final timeAgo = _formatTimeAgo(createdAt);
          
          // Verificar se o usuário atual também demonstrou interesse (interesse mútuo)
          final hasUserInterest = await _checkMutualInterest(userId, data['fromUserId']);
          
          // Criar perfil a partir dos dados salvos
          final fromProfile = data['fromProfile'] as Map<String, dynamic>?;
          SpiritualProfileModel? profile;
          
          if (fromProfile != null) {
            profile = SpiritualProfileModel(
              userId: data['fromUserId'],
              displayName: fromProfile['displayName'],
              username: fromProfile['username'],
              age: fromProfile['age'],
              mainPhotoUrl: fromProfile['mainPhotoUrl'],
              bio: fromProfile['bio'],
              createdAt: createdAt,
            );
          }

          if (profile != null) {
            notifications.add({
              'profile': profile,
              'hasUserInterest': hasUserInterest,
              'timeAgo': timeAgo,
              'interestId': doc.id,
              'isSimulated': data['fromUserId'] == 'itala_user_id_simulation',
              'createdAt': createdAt,
            });
          }
        } catch (e) {
          EnhancedLogger.error('Failed to parse interest notification', 
            tag: 'INTERESTS_REPOSITORY',
            error: e,
            data: {'docId': doc.id}
          );
        }
      }

      EnhancedLogger.success('Interest notifications loaded', 
        tag: 'INTERESTS_REPOSITORY',
        data: {
          'userId': userId,
          'notificationsCount': notifications.length,
        }
      );

      return notifications;
    } catch (e) {
      EnhancedLogger.error('Failed to load interest notifications', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {'userId': userId}
      );
      return [];
    }
  }

  /// Stream de notificações de interesse em tempo real
  static Stream<List<Map<String, dynamic>>> getInterestNotificationsStream(String userId) {
    try {
      EnhancedLogger.info('Starting interest notifications stream', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'userId': userId}
      );

      return _firestore
          .collection(_interestsCollection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final notifications = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            
            // Calcular tempo decorrido
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final timeAgo = _formatTimeAgo(createdAt);
            
            // Verificar interesse mútuo
            final hasUserInterest = await _checkMutualInterest(userId, data['fromUserId']);
            
            // Criar perfil
            final fromProfile = data['fromProfile'] as Map<String, dynamic>?;
            SpiritualProfileModel? profile;
            
            if (fromProfile != null) {
              profile = SpiritualProfileModel(
                userId: data['fromUserId'],
                displayName: fromProfile['displayName'],
                username: fromProfile['username'],
                age: fromProfile['age'],
                mainPhotoUrl: fromProfile['mainPhotoUrl'],
                bio: fromProfile['bio'],
                createdAt: createdAt,
              );
            }

            if (profile != null) {
              notifications.add({
                'profile': profile,
                'hasUserInterest': hasUserInterest,
                'timeAgo': timeAgo,
                'interestId': doc.id,
                'isSimulated': data['fromUserId'] == 'itala_user_id_simulation',
                'createdAt': createdAt,
              });
            }
          } catch (e) {
            EnhancedLogger.error('Failed to parse interest notification in stream', 
              tag: 'INTERESTS_REPOSITORY',
              error: e,
              data: {'docId': doc.id}
            );
          }
        }

        return notifications;
      });
    } catch (e) {
      EnhancedLogger.error('Failed to create interest notifications stream', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {'userId': userId}
      );
      return Stream.value([]);
    }
  }

  /// Verifica se há interesse mútuo entre dois usuários
  static Future<bool> _checkMutualInterest(String userId, String otherUserId) async {
    try {
      final doc = await _firestore
          .collection(_interestsCollection)
          .doc('${userId}_$otherUserId')
          .get();

      return doc.exists && doc.data()?['status'] == 'pending';
    } catch (e) {
      return false;
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

  /// Expressa interesse em um usuário
  static Future<void> expressInterest({
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> fromProfile,
  }) async {
    try {
      EnhancedLogger.info('Expressing interest', 
        tag: 'INTERESTS_REPOSITORY',
        data: {
          'fromUserId': fromUserId,
          'toUserId': toUserId,
        }
      );

      final interestData = {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'profile_interest',
        'fromProfile': fromProfile,
      };

      await _firestore
          .collection(_interestsCollection)
          .doc('${fromUserId}_$toUserId')
          .set(interestData);

      EnhancedLogger.success('Interest expressed successfully', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': '${fromUserId}_$toUserId'}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to express interest', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {
          'fromUserId': fromUserId,
          'toUserId': toUserId,
        }
      );
      rethrow;
    }
  }

  /// Rejeita um interesse
  static Future<void> rejectInterest(String interestId) async {
    try {
      EnhancedLogger.info('Rejecting interest', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': interestId}
      );

      await _firestore
          .collection(_interestsCollection)
          .doc(interestId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      EnhancedLogger.success('Interest rejected successfully', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': interestId}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to reject interest', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {'interestId': interestId}
      );
      rethrow;
    }
  }

  /// Aceita um interesse (marca como aceito)
  static Future<void> acceptInterest(String interestId) async {
    try {
      EnhancedLogger.info('Accepting interest', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': interestId}
      );

      await _firestore
          .collection(_interestsCollection)
          .doc(interestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      EnhancedLogger.success('Interest accepted successfully', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': interestId}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to accept interest', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {'interestId': interestId}
      );
      rethrow;
    }
  }

  /// Remove um interesse (delete)
  static Future<void> removeInterest(String interestId) async {
    try {
      EnhancedLogger.info('Removing interest', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': interestId}
      );

      await _firestore
          .collection(_interestsCollection)
          .doc(interestId)
          .delete();

      EnhancedLogger.success('Interest removed successfully', 
        tag: 'INTERESTS_REPOSITORY',
        data: {'interestId': interestId}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to remove interest', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {'interestId': interestId}
      );
      rethrow;
    }
  }

  /// Obtém contador de notificações não lidas
  static Future<int> getUnreadInterestCount(String userId) async {
    try {
      final query = await _firestore
          .collection(_interestsCollection)
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return query.docs.length;
    } catch (e) {
      EnhancedLogger.error('Failed to get unread interest count', 
        tag: 'INTERESTS_REPOSITORY',
        error: e,
        data: {'userId': userId}
      );
      return 0;
    }
  }
}