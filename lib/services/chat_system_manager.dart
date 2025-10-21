import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_data.dart';
import '../models/message_data.dart';
import 'notification_orchestrator.dart';
import '../models/notification_data.dart';

/// Gerenciador do sistema de chat - cria e gerencia chats de matches
class ChatSystemManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cria um chat com ID determinístico
  static Future<String> createChat(String userId1, String userId2) async {
    print('💬 [CHAT_SYSTEM_MANAGER] Criando chat: $userId1 ↔ $userId2');
    
    try {
      // Gerar ID determinístico (sempre o mesmo para os mesmos usuários)
      final chatId = _generateDeterministicChatId(userId1, userId2);
      
      // Verificar se o chat já existe
      final existingChat = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (existingChat.exists) {
        print('ℹ️ [CHAT_SYSTEM_MANAGER] Chat já existe: $chatId');
        return chatId;
      }
      
      // Buscar dados dos usuários
      final user1Data = await _getUserData(userId1);
      final user2Data = await _getUserData(userId2);
      
      // Criar dados do chat
      final chatData = ChatData(
        chatId: chatId,
        participants: [userId1, userId2],
        createdAt: DateTime.now(),
        lastMessageAt: null,
        lastMessage: null,
        unreadCount: {userId1: 0, userId2: 0},
        isActive: true,
        expiresAt: null, // Pode ser configurado para expirar em X dias
      );
      
      // Salvar no Firestore
      await _firestore
          .collection('match_chats')
          .doc(chatId)
          .set(chatData.toJson());
      
      print('✅ [CHAT_SYSTEM_MANAGER] Chat criado: $chatId');
      
      // Enviar mensagem de boas-vindas automática
      await _sendWelcomeMessage(chatId, user1Data?['nome'] ?? 'Usuário', user2Data?['nome'] ?? 'Usuário');
      
      return chatId;
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao criar chat: $e');
      throw Exception('Erro ao criar chat: $e');
    }
  }

  /// Garante que o chat existe antes de acessar
  static Future<void> ensureChatExists(String chatId) async {
    print('🔍 [CHAT_SYSTEM_MANAGER] Verificando existência do chat: $chatId');
    
    try {
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        print('⚠️ [CHAT_SYSTEM_MANAGER] Chat não existe, tentando recriar...');
        
        // Extrair IDs dos usuários do chatId
        final userIds = _extractUserIdsFromChatId(chatId);
        if (userIds.length == 2) {
          await createChat(userIds[0], userIds[1]);
        } else {
          throw Exception('Não foi possível extrair IDs dos usuários do chatId: $chatId');
        }
      } else {
        print('✅ [CHAT_SYSTEM_MANAGER] Chat existe: $chatId');
      }
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao verificar chat: $e');
      throw Exception('Erro ao verificar chat: $e');
    }
  }

  /// Envia uma mensagem e atualiza contadores
  static Future<void> sendMessage(String chatId, MessageData message) async {
    print('📤 [CHAT_SYSTEM_MANAGER] Enviando mensagem no chat: $chatId');
    
    try {
      // Garantir que o chat existe
      await ensureChatExists(chatId);
      
      // Gerar ID da mensagem
      final messageId = _firestore.collection('chat_messages').doc().id;
      final messageWithId = message.copyWith(id: messageId);
      
      // Salvar mensagem
      await _firestore
          .collection('chat_messages')
          .doc(messageId)
          .set(messageWithId.toJson());
      
      // Atualizar metadados do chat
      await _updateChatMetadata(chatId, messageWithId);
      
      // Atualizar contadores de não lidas
      await updateUnreadCounters(chatId, message.senderId);
      
      // Enviar notificação para o outro usuário
      await _sendMessageNotification(chatId, messageWithId);
      
      print('✅ [CHAT_SYSTEM_MANAGER] Mensagem enviada: $messageId');
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao enviar mensagem: $e');
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  /// Atualiza contadores de mensagens não lidas
  static Future<void> updateUnreadCounters(String chatId, String senderId) async {
    print('🔢 [CHAT_SYSTEM_MANAGER] Atualizando contadores: $chatId');
    
    try {
      // Buscar dados do chat
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        print('❌ [CHAT_SYSTEM_MANAGER] Chat não encontrado para atualizar contadores');
        return;
      }
      
      final chatData = ChatData.fromJson(chatDoc.data()!);
      final otherUserId = chatData.participants.firstWhere((id) => id != senderId);
      
      // Incrementar contador do outro usuário
      final newUnreadCount = Map<String, int>.from(chatData.unreadCount);
      newUnreadCount[otherUserId] = (newUnreadCount[otherUserId] ?? 0) + 1;
      
      // Atualizar no Firestore
      await _firestore
          .collection('match_chats')
          .doc(chatId)
          .update({'unreadCount': newUnreadCount});
      
      print('✅ [CHAT_SYSTEM_MANAGER] Contadores atualizados');
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao atualizar contadores: $e');
    }
  }

  /// Marca mensagens como lidas
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    print('👁️ [CHAT_SYSTEM_MANAGER] Marcando mensagens como lidas: $chatId');
    
    try {
      // Buscar mensagens não lidas do usuário
      final unreadMessages = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();
      
      // Marcar como lidas em lote
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      // Zerar contador de não lidas
      await _firestore
          .collection('match_chats')
          .doc(chatId)
          .update({'unreadCount.$userId': 0});
      
      print('✅ [CHAT_SYSTEM_MANAGER] ${unreadMessages.docs.length} mensagens marcadas como lidas');
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao marcar como lidas: $e');
    }
  }

  /// Busca mensagens do chat
  static Future<List<MessageData>> getChatMessages(String chatId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      final messages = query.docs
          .map((doc) => MessageData.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      print('📋 [CHAT_SYSTEM_MANAGER] ${messages.length} mensagens carregadas do chat $chatId');
      return messages.reversed.toList(); // Ordem cronológica
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao buscar mensagens: $e');
      return [];
    }
  }

  /// Stream de mensagens em tempo real
  static Stream<List<MessageData>> getChatMessagesStream(String chatId) {
    return _firestore
        .collection('chat_messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageData.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Busca dados do chat
  static Future<ChatData?> getChatData(String chatId) async {
    try {
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        return null;
      }
      
      return ChatData.fromJson(chatDoc.data()!);
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao buscar dados do chat: $e');
      return null;
    }
  }

  /// Gera ID determinístico para o chat
  static String _generateDeterministicChatId(String userId1, String userId2) {
    // Ordenar IDs para garantir consistência
    final sortedIds = [userId1, userId2]..sort();
    return 'match_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Extrai IDs dos usuários do chatId
  static List<String> _extractUserIdsFromChatId(String chatId) {
    if (chatId.startsWith('match_')) {
      final parts = chatId.substring(6).split('_');
      if (parts.length >= 2) {
        return [parts[0], parts[1]];
      }
    }
    return [];
  }

  /// Busca dados do usuário
  static Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // Tentar na coleção usuarios primeiro
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data();
      }
      
      // Fallback para coleção users
      final fallbackDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return fallbackDoc.exists ? fallbackDoc.data() : null;
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao buscar dados do usuário $userId: $e');
      return null;
    }
  }

  /// Envia mensagem de boas-vindas
  static Future<void> _sendWelcomeMessage(String chatId, String user1Name, String user2Name) async {
    try {
      final welcomeMessage = MessageData(
        id: '',
        chatId: chatId,
        senderId: 'system',
        senderName: 'Sistema',
        message: '🎉 Parabéns! Vocês têm um match mútuo! Que tal começarem uma conversa?',
        timestamp: DateTime.now(),
        isRead: false,
        messageType: 'system',
      );
      
      final messageId = _firestore.collection('chat_messages').doc().id;
      await _firestore
          .collection('chat_messages')
          .doc(messageId)
          .set(welcomeMessage.copyWith(id: messageId).toJson());
      
      print('🎉 [CHAT_SYSTEM_MANAGER] Mensagem de boas-vindas enviada');
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao enviar mensagem de boas-vindas: $e');
    }
  }

  /// Atualiza metadados do chat
  static Future<void> _updateChatMetadata(String chatId, MessageData message) async {
    try {
      await _firestore
          .collection('match_chats')
          .doc(chatId)
          .update({
            'lastMessageAt': Timestamp.fromDate(message.timestamp),
            'lastMessage': message.message,
          });
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao atualizar metadados: $e');
    }
  }

  /// Envia notificação de nova mensagem
  static Future<void> _sendMessageNotification(String chatId, MessageData message) async {
    try {
      // Buscar dados do chat para identificar o destinatário
      final chatData = await getChatData(chatId);
      if (chatData == null) return;
      
      final recipientId = chatData.participants.firstWhere((id) => id != message.senderId);
      
      // Criar notificação de mensagem
      final notification = NotificationData(
        id: '',
        toUserId: recipientId,
        fromUserId: message.senderId,
        fromUserName: message.senderName,
        fromUserEmail: '',
        type: 'message',
        message: 'Nova mensagem: ${message.message}',
        status: 'new',
        createdAt: DateTime.now(),
        metadata: {
          'chatId': chatId,
          'messageId': message.id,
        },
      );
      
      await NotificationOrchestrator.createNotification(notification);
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro ao enviar notificação de mensagem: $e');
    }
  }

  /// Testa o sistema de chat
  static Future<void> testChatSystem() async {
    print('🧪 [CHAT_SYSTEM_MANAGER] Testando sistema de chat...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [CHAT_SYSTEM_MANAGER] Usuário não autenticado');
      return;
    }
    
    try {
      const testUserId = 'test_chat_user';
      
      // Teste 1: Criar chat
      final chatId = await createChat(currentUser.uid, testUserId);
      print('✅ Teste 1 - Chat criado: $chatId');
      
      // Teste 2: Verificar existência
      await ensureChatExists(chatId);
      print('✅ Teste 2 - Chat existe');
      
      // Teste 3: Buscar dados do chat
      final chatData = await getChatData(chatId);
      print('✅ Teste 3 - Dados do chat: ${chatData?.participants}');
      
      print('🎉 [CHAT_SYSTEM_MANAGER] Todos os testes passaram!');
      
    } catch (e) {
      print('❌ [CHAT_SYSTEM_MANAGER] Erro nos testes: $e');
    }
  }
}