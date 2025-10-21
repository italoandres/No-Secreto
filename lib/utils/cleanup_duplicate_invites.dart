import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para limpar convites duplicados
class CleanupDuplicateInvites {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Limpar convites duplicados para um usuário específico
  static Future<void> cleanupDuplicatesForUser(String userId) async {
    try {
      EnhancedLogger.info('Starting cleanup of duplicate invites', 
        tag: 'CLEANUP_INVITES',
        data: {'userId': userId}
      );

      // Buscar todos os convites ativos para o usuário
      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('toUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final invitesByFromUser = <String, List<QueryDocumentSnapshot>>{};
      
      // Agrupar por fromUserId
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final fromUserId = data['fromUserId'] as String?;
        
        if (fromUserId != null) {
          invitesByFromUser.putIfAbsent(fromUserId, () => []).add(doc);
        }
      }

      int duplicatesRemoved = 0;
      final batch = _firestore.batch();

      // Para cada fromUserId, manter apenas o mais recente
      for (final entry in invitesByFromUser.entries) {
        final fromUserId = entry.key;
        final docs = entry.value;
        
        if (docs.length > 1) {
          // Ordenar por createdAt (mais recente primeiro)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aCreated = aData['createdAt'] as Timestamp?;
            final bCreated = bData['createdAt'] as Timestamp?;
            
            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1;
            if (bCreated == null) return -1;
            
            return bCreated.compareTo(aCreated);
          });
          
          // Remover todos exceto o primeiro (mais recente)
          for (int i = 1; i < docs.length; i++) {
            batch.update(docs[i].reference, {
              'isActive': false,
              'cleanedUpAt': Timestamp.fromDate(DateTime.now()),
              'cleanupReason': 'duplicate_invite',
            });
            duplicatesRemoved++;
          }
          
          EnhancedLogger.info('Found duplicates for user', 
            tag: 'CLEANUP_INVITES',
            data: {
              'fromUserId': fromUserId,
              'totalInvites': docs.length,
              'duplicatesMarked': docs.length - 1
            }
          );
        }
      }

      if (duplicatesRemoved > 0) {
        await batch.commit();
        
        EnhancedLogger.success('Duplicate invites cleaned up', 
          tag: 'CLEANUP_INVITES',
          data: {
            'userId': userId,
            'duplicatesRemoved': duplicatesRemoved,
            'uniqueFromUsers': invitesByFromUser.length
          }
        );
      } else {
        EnhancedLogger.info('No duplicate invites found', 
          tag: 'CLEANUP_INVITES',
          data: {'userId': userId}
        );
      }
    } catch (e) {
      EnhancedLogger.error('Failed to cleanup duplicate invites', 
        tag: 'CLEANUP_INVITES',
        error: e,
        data: {'userId': userId}
      );
    }
  }

  /// Limpar todos os convites duplicados no sistema
  static Future<void> cleanupAllDuplicates() async {
    try {
      EnhancedLogger.info('Starting global cleanup of duplicate invites', 
        tag: 'CLEANUP_INVITES'
      );

      // Buscar todos os usuários que receberam convites
      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('isActive', isEqualTo: true)
          .get();

      final userIds = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final toUserId = data['toUserId'] as String?;
        if (toUserId != null) {
          userIds.add(toUserId);
        }
      }

      EnhancedLogger.info('Found users with invites', 
        tag: 'CLEANUP_INVITES',
        data: {'uniqueUsers': userIds.length}
      );

      // Limpar duplicatas para cada usuário
      for (final userId in userIds) {
        await cleanupDuplicatesForUser(userId);
        // Pequena pausa para não sobrecarregar o Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      EnhancedLogger.success('Global cleanup completed', 
        tag: 'CLEANUP_INVITES',
        data: {'processedUsers': userIds.length}
      );
    } catch (e) {
      EnhancedLogger.error('Failed to cleanup all duplicates', 
        tag: 'CLEANUP_INVITES',
        error: e
      );
    }
  }

  /// Verificar estatísticas de convites duplicados
  static Future<void> checkDuplicateStats() async {
    try {
      EnhancedLogger.info('Checking duplicate invite statistics', 
        tag: 'CLEANUP_INVITES'
      );

      final querySnapshot = await _firestore
          .collection('user_interests')
          .where('isActive', isEqualTo: true)
          .get();

      final invitesByUser = <String, Map<String, int>>{};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final toUserId = data['toUserId'] as String?;
        final fromUserId = data['fromUserId'] as String?;
        
        if (toUserId != null && fromUserId != null) {
          invitesByUser.putIfAbsent(toUserId, () => {});
          invitesByUser[toUserId]!.update(
            fromUserId, 
            (count) => count + 1, 
            ifAbsent: () => 1
          );
        }
      }

      int totalUsers = invitesByUser.length;
      int usersWithDuplicates = 0;
      int totalDuplicates = 0;

      for (final entry in invitesByUser.entries) {
        final userId = entry.key;
        final fromUserCounts = entry.value;
        
        int userDuplicates = 0;
        for (final count in fromUserCounts.values) {
          if (count > 1) {
            userDuplicates += count - 1;
          }
        }
        
        if (userDuplicates > 0) {
          usersWithDuplicates++;
          totalDuplicates += userDuplicates;
          
          EnhancedLogger.info('User has duplicates', 
            tag: 'CLEANUP_INVITES',
            data: {
              'userId': userId,
              'duplicateCount': userDuplicates,
              'fromUsers': fromUserCounts.length
            }
          );
        }
      }

      EnhancedLogger.info('Duplicate statistics', 
        tag: 'CLEANUP_INVITES',
        data: {
          'totalUsers': totalUsers,
          'usersWithDuplicates': usersWithDuplicates,
          'totalDuplicates': totalDuplicates
        }
      );
    } catch (e) {
      EnhancedLogger.error('Failed to check duplicate stats', 
        tag: 'CLEANUP_INVITES',
        error: e
      );
    }
  }
}