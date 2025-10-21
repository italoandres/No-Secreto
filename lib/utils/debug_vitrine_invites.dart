import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para debugar convites da vitrine
class DebugVitrineInvites {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debugar todos os convites de um usuário
  static Future<void> debugUserInvites(String userId) async {
    try {
      EnhancedLogger.info('Starting debug for user invites', 
        tag: 'DEBUG_VITRINE',
        data: {'userId': userId}
      );

      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('toUserId', isEqualTo: userId)
          .get();

      EnhancedLogger.info('Found total documents', 
        tag: 'DEBUG_VITRINE',
        data: {'userId': userId, 'totalDocs': querySnapshot.docs.length}
      );

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        EnhancedLogger.info('Document details', 
          tag: 'DEBUG_VITRINE',
          data: {
            'docId': doc.id,
            'fromUserId': data['fromUserId'],
            'toUserId': data['toUserId'],
            'isActive': data['isActive'],
            'createdAt': data['createdAt']?.toString(),
            'allFields': data.keys.toList(),
          }
        );

        // Verificar se fromUserId está vazio ou nulo
        final fromUserId = data['fromUserId'];
        if (fromUserId == null || fromUserId.toString().isEmpty) {
          EnhancedLogger.error('Found invite with invalid fromUserId', 
            tag: 'DEBUG_VITRINE',
            data: {
              'docId': doc.id,
              'fromUserId': fromUserId,
              'fromUserIdType': fromUserId.runtimeType.toString(),
              'rawData': data,
            }
          );
        }
      }

      // Debugar apenas os ativos
      final activeQuery = await _firestore
          .collection('user_interests')
          .where('toUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      EnhancedLogger.info('Active invites summary', 
        tag: 'DEBUG_VITRINE',
        data: {
          'userId': userId,
          'totalInvites': querySnapshot.docs.length,
          'activeInvites': activeQuery.docs.length,
        }
      );

    } catch (e) {
      EnhancedLogger.error('Failed to debug user invites', 
        tag: 'DEBUG_VITRINE',
        error: e,
        data: {'userId': userId}
      );
    }
  }

  /// Debugar convite específico por ID
  static Future<void> debugSpecificInvite(String inviteId) async {
    try {
      EnhancedLogger.info('Debugging specific invite', 
        tag: 'DEBUG_VITRINE',
        data: {'inviteId': inviteId}
      );

      final doc = await _firestore
          .collection('user_interests')
          .doc(inviteId)
          .get();

      if (!doc.exists) {
        EnhancedLogger.error('Invite document not found', 
          tag: 'DEBUG_VITRINE',
          data: {'inviteId': inviteId}
        );
        return;
      }

      final data = doc.data()!;
      
      EnhancedLogger.info('Invite document data', 
        tag: 'DEBUG_VITRINE',
        data: {
          'inviteId': inviteId,
          'exists': doc.exists,
          'data': data,
          'fromUserId': data['fromUserId'],
          'fromUserIdLength': data['fromUserId']?.toString().length ?? 0,
          'toUserId': data['toUserId'],
          'isActive': data['isActive'],
          'createdAt': data['createdAt']?.toString(),
        }
      );

    } catch (e) {
      EnhancedLogger.error('Failed to debug specific invite', 
        tag: 'DEBUG_VITRINE',
        error: e,
        data: {'inviteId': inviteId}
      );
    }
  }

  /// Debugar convites do usuário atual
  static Future<void> debugCurrentUserInvites() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.error('No authenticated user', tag: 'DEBUG_VITRINE');
        return;
      }

      await debugUserInvites(currentUser.uid);
    } catch (e) {
      EnhancedLogger.error('Failed to debug current user invites', 
        tag: 'DEBUG_VITRINE',
        error: e
      );
    }
  }

  /// Corrigir convites com fromUserId vazio
  static Future<void> fixInvitesWithEmptyFromUserId() async {
    try {
      EnhancedLogger.info('Starting fix for invites with empty fromUserId', 
        tag: 'DEBUG_VITRINE'
      );

      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('isActive', isEqualTo: true)
          .get();

      int fixedCount = 0;
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final fromUserId = data['fromUserId'];
        
        if (fromUserId == null || fromUserId.toString().isEmpty) {
          // Marcar como inativo se fromUserId estiver vazio
          batch.update(doc.reference, {
            'isActive': false,
            'fixedAt': Timestamp.fromDate(DateTime.now()),
            'fixReason': 'empty_fromUserId',
          });
          fixedCount++;
          
          EnhancedLogger.info('Marking invalid invite as inactive', 
            tag: 'DEBUG_VITRINE',
            data: {
              'docId': doc.id,
              'fromUserId': fromUserId,
              'toUserId': data['toUserId'],
            }
          );
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        
        EnhancedLogger.success('Fixed invites with empty fromUserId', 
          tag: 'DEBUG_VITRINE',
          data: {'fixedCount': fixedCount}
        );
      } else {
        EnhancedLogger.info('No invites with empty fromUserId found', 
          tag: 'DEBUG_VITRINE'
        );
      }

    } catch (e) {
      EnhancedLogger.error('Failed to fix invites with empty fromUserId', 
        tag: 'DEBUG_VITRINE',
        error: e
      );
    }
  }

  /// Verificar integridade dos dados de convites
  static Future<void> checkDataIntegrity() async {
    try {
      EnhancedLogger.info('Checking invite data integrity', 
        tag: 'DEBUG_VITRINE'
      );

      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('isActive', isEqualTo: true)
          .get();

      int totalInvites = querySnapshot.docs.length;
      int validInvites = 0;
      int invalidFromUserId = 0;
      int invalidToUserId = 0;
      int invalidCreatedAt = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        bool isValid = true;
        
        // Verificar fromUserId
        final fromUserId = data['fromUserId'];
        if (fromUserId == null || fromUserId.toString().isEmpty) {
          invalidFromUserId++;
          isValid = false;
        }
        
        // Verificar toUserId
        final toUserId = data['toUserId'];
        if (toUserId == null || toUserId.toString().isEmpty) {
          invalidToUserId++;
          isValid = false;
        }
        
        // Verificar createdAt
        final createdAt = data['createdAt'];
        if (createdAt == null) {
          invalidCreatedAt++;
          isValid = false;
        }
        
        if (isValid) {
          validInvites++;
        }
      }

      EnhancedLogger.info('Data integrity report', 
        tag: 'DEBUG_VITRINE',
        data: {
          'totalInvites': totalInvites,
          'validInvites': validInvites,
          'invalidFromUserId': invalidFromUserId,
          'invalidToUserId': invalidToUserId,
          'invalidCreatedAt': invalidCreatedAt,
          'integrityPercentage': totalInvites > 0 ? (validInvites / totalInvites * 100).toStringAsFixed(2) : '0',
        }
      );

    } catch (e) {
      EnhancedLogger.error('Failed to check data integrity', 
        tag: 'DEBUG_VITRINE',
        error: e
      );
    }
  }
}