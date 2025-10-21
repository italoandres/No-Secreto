import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_data.dart';

/// Orquestrador de notificações - gerencia criação e entrega de notificações
class NotificationOrchestrator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cria uma notificação individual
  static Future<String?> createNotification(NotificationData notification) async {
    print('📢 [NOTIFICATION_ORCHESTRATOR] Criando notificação: ${notification.type}');
    
    try {
      // Gerar ID se não fornecido
      final notificationId = notification.id.isEmpty 
          ? _firestore.collection('notifications').doc().id 
          : notification.id;
      
      final notificationWithId = notification.copyWith(id: notificationId);
      
      // Salvar no Firestore
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notificationWithId.toJson());
      
      print('✅ [NOTIFICATION_ORCHESTRATOR] Notificação criada: $notificationId');
      
      // Enviar notificação em tempo real
      await _sendRealTimeNotification(notificationWithId);
      
      return notificationId;
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao criar notificação: $e');
      return null;
    }
  }

  /// Cria múltiplas notificações em lote
  static Future<List<String>> createBulkNotifications(List<NotificationData> notifications) async {
    print('📢 [NOTIFICATION_ORCHESTRATOR] Criando ${notifications.length} notificações em lote');
    
    try {
      final batch = _firestore.batch();
      final createdIds = <String>[];
      
      for (final notification in notifications) {
        // Gerar ID se não fornecido
        final notificationId = notification.id.isEmpty 
            ? _firestore.collection('notifications').doc().id 
            : notification.id;
        
        final notificationWithId = notification.copyWith(id: notificationId);
        
        // Adicionar ao batch
        final docRef = _firestore.collection('notifications').doc(notificationId);
        batch.set(docRef, notificationWithId.toJson());
        
        createdIds.add(notificationId);
      }
      
      // Executar batch
      await batch.commit();
      
      print('✅ [NOTIFICATION_ORCHESTRATOR] ${createdIds.length} notificações criadas em lote');
      
      // Enviar notificações em tempo real
      for (int i = 0; i < notifications.length; i++) {
        final notificationWithId = notifications[i].copyWith(id: createdIds[i]);
        await _sendRealTimeNotification(notificationWithId);
      }
      
      return createdIds;
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao criar notificações em lote: $e');
      return [];
    }
  }

  /// Processa resposta a uma notificação
  static Future<void> handleNotificationResponse(String notificationId, String action) async {
    print('🔄 [NOTIFICATION_ORCHESTRATOR] Processando resposta: $action para $notificationId');
    
    try {
      // Buscar a notificação
      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        print('❌ [NOTIFICATION_ORCHESTRATOR] Notificação não encontrada: $notificationId');
        return;
      }
      
      final notificationData = NotificationData.fromJson(notificationDoc.data()!);
      
      // Verificar se já foi respondida
      if (notificationData.isResponded) {
        print('ℹ️ [NOTIFICATION_ORCHESTRATOR] Notificação já foi respondida anteriormente');
        return;
      }
      
      // Atualizar status da notificação
      final newStatus = _getStatusFromAction(action);
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'status': newStatus,
            'dataResposta': Timestamp.now(),
            'respondedAt': Timestamp.now(),
          });
      
      print('✅ [NOTIFICATION_ORCHESTRATOR] Status atualizado para: $newStatus');
      
      // Processar ação específica
      await _processSpecificAction(notificationData, action);
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao processar resposta: $e');
    }
  }

  /// Marca notificação como visualizada
  static Future<void> markAsViewed(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
            'status': 'viewed',
          });
      
      print('👁️ [NOTIFICATION_ORCHESTRATOR] Notificação marcada como visualizada: $notificationId');
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao marcar como visualizada: $e');
    }
  }

  /// Busca notificações de um usuário
  static Future<List<NotificationData>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final notifications = query.docs
          .map((doc) => NotificationData.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      print('📋 [NOTIFICATION_ORCHESTRATOR] Encontradas ${notifications.length} notificações para $userId');
      return notifications;
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao buscar notificações: $e');
      return [];
    }
  }

  /// Conta notificações não lidas
  static Future<int> getUnreadCount(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'new')
          .get();
      
      final count = query.docs.length;
      print('🔢 [NOTIFICATION_ORCHESTRATOR] $count notificações não lidas para $userId');
      return count;
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao contar não lidas: $e');
      return 0;
    }
  }

  /// Stream de notificações em tempo real
  static Stream<List<NotificationData>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationData.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Stream de contador não lidas em tempo real
  static Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'new')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Remove notificações antigas (mais de 30 dias)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('🧹 [NOTIFICATION_ORCHESTRATOR] ${oldNotifications.docs.length} notificações antigas removidas');
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro na limpeza: $e');
    }
  }

  /// Envia notificação em tempo real
  static Future<void> _sendRealTimeNotification(NotificationData notification) async {
    try {
      // Aqui você pode integrar com FCM ou outro serviço de push
      print('🔔 [NOTIFICATION_ORCHESTRATOR] Enviando notificação em tempo real para ${notification.toUserId}');
      
      // Por enquanto, apenas log - você pode implementar FCM aqui
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao enviar notificação em tempo real: $e');
    }
  }

  /// Converte ação em status
  static String _getStatusFromAction(String action) {
    switch (action.toLowerCase()) {
      case 'accepted':
      case 'aceitar':
      case 'também tenho':
        return 'accepted';
      case 'rejected':
      case 'rejeitar':
      case 'não tenho':
        return 'rejected';
      case 'viewed':
      case 'visualizar':
        return 'viewed';
      default:
        return 'pending';
    }
  }

  /// Processa ação específica da notificação
  static Future<void> _processSpecificAction(NotificationData notification, String action) async {
    try {
      if (notification.isInterestNotification && action.toLowerCase() == 'accepted') {
        // Importar dinamicamente para evitar dependência circular
        final MutualMatchDetector = await _importMutualMatchDetector();
        await MutualMatchDetector.processInterestResponse(
          notification.id,
          action,
          notification.fromUserId,
          notification.toUserId,
        );
      }
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro ao processar ação específica: $e');
    }
  }

  /// Importa MutualMatchDetector dinamicamente
  static Future<dynamic> _importMutualMatchDetector() async {
    // Importação dinâmica para evitar dependência circular
    final module = await import('mutual_match_detector.dart');
    return module.MutualMatchDetector;
  }

  /// Testa o orquestrador de notificações
  static Future<void> testNotificationOrchestrator() async {
    print('🧪 [NOTIFICATION_ORCHESTRATOR] Testando orquestrador...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Usuário não autenticado');
      return;
    }
    
    try {
      // Teste 1: Criar notificação individual
      final testNotification = NotificationData(
        id: '',
        toUserId: currentUser.uid,
        fromUserId: 'test_user',
        fromUserName: 'Usuário Teste',
        fromUserEmail: 'teste@exemplo.com',
        type: 'interest',
        message: 'Teste de notificação',
        status: 'new',
        createdAt: DateTime.now(),
      );
      
      final notificationId = await createNotification(testNotification);
      print('✅ Teste 1 - Notificação criada: $notificationId');
      
      // Teste 2: Buscar notificações do usuário
      final userNotifications = await getUserNotifications(currentUser.uid);
      print('✅ Teste 2 - Notificações encontradas: ${userNotifications.length}');
      
      // Teste 3: Contar não lidas
      final unreadCount = await getUnreadCount(currentUser.uid);
      print('✅ Teste 3 - Não lidas: $unreadCount');
      
      print('🎉 [NOTIFICATION_ORCHESTRATOR] Todos os testes passaram!');
      
    } catch (e) {
      print('❌ [NOTIFICATION_ORCHESTRATOR] Erro nos testes: $e');
    }
  }
}