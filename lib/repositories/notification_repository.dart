import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/models/notification_model.dart';

class NotificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  // Criar nova notificação
  static Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      print('Erro ao criar notificação: $e');
      rethrow;
    }
  }

  // Buscar notificações do usuário (ordenadas por data, mais recentes primeiro)
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limitar a 50 notificações mais recentes
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromDocument(doc))
          .toList();
    });
  }

  // Buscar notificações paginadas
  static Future<List<NotificationModel>> getUserNotificationsPaginated(
    String userId, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Erro ao buscar notificações paginadas: $e');
      return [];
    }
  }

  // Marcar notificação como lida
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
      rethrow;
    }
  }

  // Marcar todas as notificações do usuário como lidas
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao marcar todas as notificações como lidas: $e');
      rethrow;
    }
  }

  // Contar notificações não lidas do usuário
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Deletar notificação
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Erro ao deletar notificação: $e');
      rethrow;
    }
  }

  // Deletar todas as notificações do usuário
  static Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao deletar todas as notificações: $e');
      rethrow;
    }
  }

  // Limpar notificações antigas (mais de 30 dias)
  static Future<void> cleanOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
          'Limpeza de notificações antigas concluída: ${snapshot.docs.length} removidas');
    } catch (e) {
      print('Erro ao limpar notificações antigas: $e');
    }
  }

  // Verificar se uma notificação específica existe
  static Future<bool> notificationExists(String notificationId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(notificationId).get();
      return doc.exists;
    } catch (e) {
      print('Erro ao verificar existência da notificação: $e');
      return false;
    }
  }

  // Buscar notificação por ID
  static Future<NotificationModel?> getNotificationById(
      String notificationId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(notificationId).get();

      if (doc.exists) {
        return NotificationModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar notificação por ID: $e');
      return null;
    }
  }

  // Buscar notificações do usuário para um contexto específico
  static Stream<List<NotificationModel>> getContextNotifications(
      String userId, String contexto) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('contexto', isEqualTo: contexto)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromDocument(doc))
          .toList();
    });
  }

  // Contar notificações não lidas para um contexto específico
  static Stream<int> getContextUnreadCount(String userId, String contexto) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('contexto', isEqualTo: contexto)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Marcar todas as notificações de um contexto como lidas
  static Future<void> markContextAsRead(String userId, String contexto) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('contexto', isEqualTo: contexto)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao marcar notificações do contexto como lidas: $e');
      rethrow;
    }
  }

  // Deletar todas as notificações de um contexto específico
  static Future<void> deleteContextNotifications(
      String userId, String contexto) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('contexto', isEqualTo: contexto)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao deletar notificações do contexto: $e');
      rethrow;
    }
  }
}
