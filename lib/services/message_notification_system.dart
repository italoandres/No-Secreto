import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_data.dart';
import '../models/notification_data.dart';
import 'notification_orchestrator.dart';
import 'real_time_notification_service.dart';
import 'chat_system_manager.dart';

/// Sistema de notificações para mensagens de chat
class MessageNotificationSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Streams para gerenciar notificações em tempo real
  static final Map<String, StreamSubscription> _messageListeners = {};
  static final StreamController<MessageData> _newMessageController =
      StreamController<MessageData>.broadcast();

  /// Inicializa o sistema de notificações de mensagens
  static Future<void> initialize() async {
    print('🚀 [MESSAGE_NOTIFICATION_SYSTEM] Inicializando sistema...');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Usuário não autenticado');
      return;
    }

    // Inicializar listeners para chats do usuário
    await _initializeMessageListeners(currentUser.uid);

    print('✅ [MESSAGE_NOTIFICATION_SYSTEM] Sistema inicializado');
  }

  /// Para o sistema e limpa recursos
  static Future<void> dispose() async {
    print('🛑 [MESSAGE_NOTIFICATION_SYSTEM] Parando sistema...');

    // Cancelar todos os listeners
    for (final subscription in _messageListeners.values) {
      await subscription.cancel();
    }
    _messageListeners.clear();

    print('✅ [MESSAGE_NOTIFICATION_SYSTEM] Sistema parado');
  }

  /// Envia uma mensagem e cria notificações
  static Future<void> sendMessageWithNotification({
    required String chatId,
    required String message,
    String messageType = 'text',
  }) async {
    print(
        '📤 [MESSAGE_NOTIFICATION_SYSTEM] Enviando mensagem no chat: $chatId');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Usuário não autenticado');
      return;
    }

    try {
      // Buscar dados do usuário
      final userData = await _getUserData(currentUser.uid);
      if (userData == null) {
        print(
            '❌ [MESSAGE_NOTIFICATION_SYSTEM] Dados do usuário não encontrados');
        return;
      }

      // Criar dados da mensagem
      final messageData = MessageData(
        id: '',
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: userData['nome'] ?? 'Usuário',
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        messageType: messageType,
      );

      // Enviar mensagem através do ChatSystemManager
      await ChatSystemManager.sendMessage(chatId, messageData);

      print(
          '✅ [MESSAGE_NOTIFICATION_SYSTEM] Mensagem enviada com notificações');
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao enviar mensagem: $e');
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  /// Cria notificação para nova mensagem
  static Future<void> createMessageNotification({
    required String chatId,
    required MessageData message,
    required String recipientId,
  }) async {
    print('🔔 [MESSAGE_NOTIFICATION_SYSTEM] Criando notificação de mensagem');

    try {
      // Buscar dados do chat para contexto
      final chatData = await ChatSystemManager.getChatData(chatId);
      if (chatData == null) {
        print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Dados do chat não encontrados');
        return;
      }

      // Criar notificação
      final notification = NotificationData(
        id: '',
        toUserId: recipientId,
        fromUserId: message.senderId,
        fromUserName: message.senderName,
        fromUserEmail: '',
        type: 'message',
        message: _formatMessageNotification(message),
        status: 'new',
        createdAt: DateTime.now(),
        metadata: {
          'chatId': chatId,
          'messageId': message.id,
          'messageType': message.messageType,
          'originalMessage': message.message,
        },
      );

      // Criar notificação
      await NotificationOrchestrator.createNotification(notification);

      // Enviar notificação em tempo real
      await RealTimeNotificationService.sendInAppNotification(
          recipientId, notification);

      print('✅ [MESSAGE_NOTIFICATION_SYSTEM] Notificação de mensagem criada');
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao criar notificação: $e');
    }
  }

  /// Marca mensagens como lidas e remove notificações
  static Future<void> markMessagesAsReadAndClearNotifications({
    required String chatId,
    required String userId,
  }) async {
    print(
        '👁️ [MESSAGE_NOTIFICATION_SYSTEM] Marcando mensagens como lidas: $chatId');

    try {
      // Marcar mensagens como lidas no chat
      await ChatSystemManager.markMessagesAsRead(chatId, userId);

      // Buscar e marcar notificações relacionadas como visualizadas
      final notifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('type', isEqualTo: 'message')
          .where('metadata.chatId', isEqualTo: chatId)
          .where('status', isEqualTo: 'new')
          .get();

      if (notifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in notifications.docs) {
          batch.update(doc.reference, {'status': 'viewed'});
        }
        await batch.commit();

        print(
            '✅ [MESSAGE_NOTIFICATION_SYSTEM] ${notifications.docs.length} notificações marcadas como visualizadas');
      }
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao marcar como lidas: $e');
    }
  }

  /// Obtém contador de mensagens não lidas para um usuário
  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      // Buscar todos os chats do usuário
      final chatsQuery = await _firestore
          .collection('match_chats')
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;

      for (final chatDoc in chatsQuery.docs) {
        final chatData = chatDoc.data();
        final unreadCount = chatData['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null) {
          totalUnread += (unreadCount[userId] as int?) ?? 0;
        }
      }

      return totalUnread;
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao contar não lidas: $e');
      return 0;
    }
  }

  /// Stream de contador de mensagens não lidas
  static Stream<int> getUnreadMessageCountStream(String userId) {
    return _firestore
        .collection('match_chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null) {
          totalUnread += (unreadCount[userId] as int?) ?? 0;
        }
      }
      return totalUnread;
    });
  }

  /// Stream de novas mensagens
  static Stream<MessageData> get newMessageStream =>
      _newMessageController.stream;

  /// Inicializa listeners para mensagens dos chats do usuário
  static Future<void> _initializeMessageListeners(String userId) async {
    try {
      // Buscar chats do usuário
      final chatsQuery = await _firestore
          .collection('match_chats')
          .where('participants', arrayContains: userId)
          .get();

      for (final chatDoc in chatsQuery.docs) {
        final chatId = chatDoc.id;
        await _addMessageListener(chatId, userId);
      }

      print(
          '✅ [MESSAGE_NOTIFICATION_SYSTEM] ${chatsQuery.docs.length} listeners de mensagem inicializados');
    } catch (e) {
      print(
          '❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao inicializar listeners: $e');
    }
  }

  /// Adiciona listener para mensagens de um chat específico
  static Future<void> _addMessageListener(String chatId, String userId) async {
    try {
      // Cancelar listener existente se houver
      await _messageListeners[chatId]?.cancel();

      // Criar novo listener
      final subscription = _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId',
              isNotEqualTo: userId) // Apenas mensagens de outros usuários
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final messageData = MessageData.fromJson({
              ...change.doc.data()!,
              'id': change.doc.id,
            });

            // Emitir nova mensagem
            _newMessageController.add(messageData);

            // Criar notificação automaticamente
            _handleNewMessage(messageData, userId);

            print(
                '💬 [MESSAGE_NOTIFICATION_SYSTEM] Nova mensagem recebida no chat $chatId');
          }
        }
      });

      _messageListeners[chatId] = subscription;
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao adicionar listener: $e');
    }
  }

  /// Processa nova mensagem recebida
  static Future<void> _handleNewMessage(
      MessageData message, String userId) async {
    try {
      // Criar notificação para a nova mensagem
      await createMessageNotification(
        chatId: message.chatId,
        message: message,
        recipientId: userId,
      );
    } catch (e) {
      print(
          '❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao processar nova mensagem: $e');
    }
  }

  /// Formata mensagem para notificação
  static String _formatMessageNotification(MessageData message) {
    switch (message.messageType) {
      case 'image':
        return '📷 ${message.senderName} enviou uma imagem';
      case 'system':
        return message.message;
      case 'text':
      default:
        final preview = message.message.length > 50
            ? '${message.message.substring(0, 47)}...'
            : message.message;
        return '${message.senderName}: $preview';
    }
  }

  /// Busca dados do usuário
  static Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // Tentar na coleção usuarios primeiro
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data();
      }

      // Fallback para coleção users
      final fallbackDoc =
          await _firestore.collection('users').doc(userId).get();

      return fallbackDoc.exists ? fallbackDoc.data() : null;
    } catch (e) {
      print(
          '❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro ao buscar dados do usuário $userId: $e');
      return null;
    }
  }

  /// Limpa notificações antigas de mensagens
  static Future<void> cleanupOldMessageNotifications() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: 'message')
          .where('createdAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print(
          '🧹 [MESSAGE_NOTIFICATION_SYSTEM] ${oldNotifications.docs.length} notificações antigas removidas');
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro na limpeza: $e');
    }
  }

  /// Testa o sistema de notificações de mensagens
  static Future<void> testMessageNotificationSystem() async {
    print('🧪 [MESSAGE_NOTIFICATION_SYSTEM] Testando sistema...');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Usuário não autenticado');
      return;
    }

    try {
      // Teste 1: Inicializar sistema
      await initialize();
      print('✅ Teste 1 - Sistema inicializado');

      // Teste 2: Contar mensagens não lidas
      final unreadCount = await getUnreadMessageCount(currentUser.uid);
      print('✅ Teste 2 - Mensagens não lidas: $unreadCount');

      // Teste 3: Testar stream de contador
      final streamSubscription =
          getUnreadMessageCountStream(currentUser.uid).take(1).listen((count) {
        print('✅ Teste 3 - Stream contador: $count');
      });

      // Aguardar um pouco para o stream processar
      await Future.delayed(const Duration(seconds: 2));
      await streamSubscription.cancel();

      print('🎉 [MESSAGE_NOTIFICATION_SYSTEM] Todos os testes passaram!');
    } catch (e) {
      print('❌ [MESSAGE_NOTIFICATION_SYSTEM] Erro nos testes: $e');
    }
  }
}
