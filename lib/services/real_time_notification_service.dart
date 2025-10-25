import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_data.dart';
import '../models/message_data.dart';

/// Serviço de notificações em tempo real
class RealTimeNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Streams controllers para gerenciar notificações em tempo real
  static final StreamController<NotificationData> _inAppNotificationController =
      StreamController<NotificationData>.broadcast();
  static final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  static final StreamController<MessageData> _newMessageController =
      StreamController<MessageData>.broadcast();

  // Subscriptions para gerenciar listeners
  static StreamSubscription? _notificationSubscription;
  static StreamSubscription? _messageSubscription;
  static String? _currentUserId;

  /// Inicializa o serviço de notificações em tempo real
  static Future<void> initialize() async {
    print('🚀 [REAL_TIME_NOTIFICATION] Inicializando serviço...');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [REAL_TIME_NOTIFICATION] Usuário não autenticado');
      return;
    }

    _currentUserId = currentUser.uid;

    // Iniciar listeners
    await _startNotificationListener();
    await _startMessageListener();

    print(
        '✅ [REAL_TIME_NOTIFICATION] Serviço inicializado para ${currentUser.uid}');
  }

  /// Para o serviço e limpa recursos
  static Future<void> dispose() async {
    print('🛑 [REAL_TIME_NOTIFICATION] Parando serviço...');

    await _notificationSubscription?.cancel();
    await _messageSubscription?.cancel();

    _notificationSubscription = null;
    _messageSubscription = null;
    _currentUserId = null;

    print('✅ [REAL_TIME_NOTIFICATION] Serviço parado');
  }

  /// Envia notificação in-app
  static Future<void> sendInAppNotification(
      String userId, NotificationData notification) async {
    print(
        '📱 [REAL_TIME_NOTIFICATION] Enviando notificação in-app para $userId');

    try {
      // Se é para o usuário atual, emitir no stream
      if (userId == _currentUserId) {
        _inAppNotificationController.add(notification);
        print('✅ [REAL_TIME_NOTIFICATION] Notificação in-app enviada');
      }

      // Aqui você pode integrar com FCM para push notifications
      await _sendPushNotification(userId, notification);
    } catch (e) {
      print('❌ [REAL_TIME_NOTIFICATION] Erro ao enviar notificação in-app: $e');
    }
  }

  /// Stream de contador de não lidas
  static Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'new')
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs.length;
      _unreadCountController.add(count);
      return count;
    });
  }

  /// Stream de novas mensagens para um chat específico
  static Stream<MessageData> getNewMessageStream(String chatId, String userId) {
    return _firestore
        .collection('chat_messages')
        .where('chatId', isEqualTo: chatId)
        .where('senderId', isNotEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final messageData = MessageData.fromJson({
          ...snapshot.docs.first.data(),
          'id': snapshot.docs.first.id,
        });
        _newMessageController.add(messageData);
        return messageData;
      }
      throw Exception('Nenhuma mensagem nova');
    });
  }

  /// Stream de notificações in-app
  static Stream<NotificationData> get inAppNotificationStream =>
      _inAppNotificationController.stream;

  /// Stream de contador de não lidas (broadcast)
  static Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Stream de novas mensagens (broadcast)
  static Stream<MessageData> get newMessageStream =>
      _newMessageController.stream;

  /// Marca todas as notificações como visualizadas
  static Future<void> markAllNotificationsAsViewed(String userId) async {
    try {
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'new')
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'status': 'viewed'});
      }

      await batch.commit();

      print(
          '👁️ [REAL_TIME_NOTIFICATION] ${unreadNotifications.docs.length} notificações marcadas como visualizadas');
    } catch (e) {
      print(
          '❌ [REAL_TIME_NOTIFICATION] Erro ao marcar notificações como visualizadas: $e');
    }
  }

  /// Obtém estatísticas de notificações
  static Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final allNotifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total': allNotifications.docs.length,
        'new': 0,
        'viewed': 0,
        'accepted': 0,
        'rejected': 0,
        'interest': 0,
        'mutual_match': 0,
        'message': 0,
      };

      for (final doc in allNotifications.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'new';
        final type = data['type'] ?? 'interest';

        stats[status] = (stats[status] ?? 0) + 1;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ [REAL_TIME_NOTIFICATION] Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Inicia listener de notificações
  static Future<void> _startNotificationListener() async {
    if (_currentUserId == null) return;

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notification = NotificationData.fromJson({
            ...change.doc.data()!,
            'id': change.doc.id,
          });

          // Emitir notificação in-app apenas para novas notificações
          if (notification.status == 'new') {
            _inAppNotificationController.add(notification);
            print(
                '🔔 [REAL_TIME_NOTIFICATION] Nova notificação recebida: ${notification.type}');
          }
        }
      }
    });
  }

  /// Inicia listener de mensagens
  static Future<void> _startMessageListener() async {
    if (_currentUserId == null) return;

    // Listener para todas as mensagens onde o usuário não é o remetente
    _messageSubscription = _firestore
        .collection('chat_messages')
        .where('senderId', isNotEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final message = MessageData.fromJson({
            ...change.doc.data()!,
            'id': change.doc.id,
          });

          // Verificar se a mensagem é para um chat do usuário atual
          _checkIfMessageIsForCurrentUser(message);
        }
      }
    });
  }

  /// Verifica se a mensagem é para o usuário atual
  static Future<void> _checkIfMessageIsForCurrentUser(
      MessageData message) async {
    try {
      final chatDoc =
          await _firestore.collection('match_chats').doc(message.chatId).get();

      if (chatDoc.exists) {
        final participants =
            List<String>.from(chatDoc.data()?['participants'] ?? []);

        if (participants.contains(_currentUserId)) {
          _newMessageController.add(message);
          print(
              '💬 [REAL_TIME_NOTIFICATION] Nova mensagem recebida no chat ${message.chatId}');
        }
      }
    } catch (e) {
      print('❌ [REAL_TIME_NOTIFICATION] Erro ao verificar mensagem: $e');
    }
  }

  /// Envia push notification (placeholder para FCM)
  static Future<void> _sendPushNotification(
      String userId, NotificationData notification) async {
    try {
      // Aqui você implementaria a integração com FCM
      print(
          '🔔 [REAL_TIME_NOTIFICATION] Push notification enviada para $userId: ${notification.message}');

      // Exemplo de como seria com FCM:
      // await FirebaseMessaging.instance.sendMessage(
      //   to: userToken,
      //   data: notification.toJson(),
      // );
    } catch (e) {
      print('❌ [REAL_TIME_NOTIFICATION] Erro ao enviar push notification: $e');
    }
  }

  /// Testa o serviço de notificações em tempo real
  static Future<void> testRealTimeNotificationService() async {
    print('🧪 [REAL_TIME_NOTIFICATION] Testando serviço...');

    try {
      // Teste 1: Inicializar serviço
      await initialize();
      print('✅ Teste 1 - Serviço inicializado');

      // Teste 2: Obter estatísticas
      if (_currentUserId != null) {
        final stats = await getNotificationStats(_currentUserId!);
        print('✅ Teste 2 - Estatísticas: $stats');
      }

      // Teste 3: Testar streams
      final unreadCountSubscription =
          getUnreadCountStream(_currentUserId!).take(1).listen((count) {
        print('✅ Teste 3 - Contador não lidas: $count');
      });

      // Aguardar um pouco para o stream processar
      await Future.delayed(const Duration(seconds: 2));
      await unreadCountSubscription.cancel();

      print('🎉 [REAL_TIME_NOTIFICATION] Todos os testes passaram!');
    } catch (e) {
      print('❌ [REAL_TIME_NOTIFICATION] Erro nos testes: $e');
    }
  }
}
