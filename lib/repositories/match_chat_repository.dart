import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_chat_model.dart';
import '../models/chat_message_model.dart';

/// Repositório para operações CRUD de chats e mensagens no Firebase
class MatchChatRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatsCollection = 'match_chats';
  static const String _messagesCollection = 'chat_messages';

  // ==================== OPERAÇÕES DE CHAT ====================

  /// Cria um novo chat no Firebase
  static Future<void> createChat(MatchChatModel chat) async {
    try {
      print('💾 Criando chat no Firebase: ${chat.id}');
      
      await _firestore
          .collection(_chatsCollection)
          .doc(chat.id)
          .set(chat.toMap());
      
      print('✅ Chat criado com sucesso: ${chat.id}');
      
    } catch (e) {
      print('❌ Erro ao criar chat: $e');
      rethrow;
    }
  }

  /// Busca um chat pelo ID
  static Future<MatchChatModel?> getChatById(String chatId) async {
    try {
      print('🔍 Buscando chat: $chatId');
      
      final doc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .get();
      
      if (!doc.exists) {
        print('❌ Chat não encontrado: $chatId');
        return null;
      }
      
      final chat = MatchChatModel.fromMap(doc.data()!);
      print('✅ Chat encontrado: $chatId');
      
      return chat;
      
    } catch (e) {
      print('❌ Erro ao buscar chat $chatId: $e');
      return null;
    }
  }

  /// Atualiza um chat existente
  static Future<void> updateChat(MatchChatModel chat) async {
    try {
      print('📝 Atualizando chat: ${chat.id}');
      
      await _firestore
          .collection(_chatsCollection)
          .doc(chat.id)
          .update(chat.toMap());
      
      print('✅ Chat atualizado: ${chat.id}');
      
    } catch (e) {
      print('❌ Erro ao atualizar chat: $e');
      rethrow;
    }
  }

  /// Atualiza campos específicos do chat
  static Future<void> updateChatFields(String chatId, Map<String, dynamic> fields) async {
    try {
      print('📝 Atualizando campos do chat $chatId: ${fields.keys.join(', ')}');
      
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .update(fields);
      
      print('✅ Campos atualizados com sucesso');
      
    } catch (e) {
      print('❌ Erro ao atualizar campos do chat: $e');
      rethrow;
    }
  }

  /// Busca todos os chats de um usuário
  static Future<List<MatchChatModel>> getUserChats(String userId) async {
    try {
      print('🔍 Buscando chats do usuário: $userId');
      
      // Buscar chats onde o usuário é user1
      final chats1Query = await _firestore
          .collection(_chatsCollection)
          .where('user1Id', isEqualTo: userId)
          .get();
      
      // Buscar chats onde o usuário é user2
      final chats2Query = await _firestore
          .collection(_chatsCollection)
          .where('user2Id', isEqualTo: userId)
          .get();
      
      final chats = <MatchChatModel>[];
      
      // Processar chats como user1
      for (final doc in chats1Query.docs) {
        try {
          final chat = MatchChatModel.fromMap(doc.data());
          chats.add(chat);
        } catch (e) {
          print('❌ Erro ao processar chat ${doc.id}: $e');
        }
      }
      
      // Processar chats como user2
      for (final doc in chats2Query.docs) {
        try {
          final chat = MatchChatModel.fromMap(doc.data());
          chats.add(chat);
        } catch (e) {
          print('❌ Erro ao processar chat ${doc.id}: $e');
        }
      }
      
      // Ordenar por data de criação (mais recente primeiro)
      chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ Encontrados ${chats.length} chats para o usuário');
      return chats;
      
    } catch (e) {
      print('❌ Erro ao buscar chats do usuário: $e');
      return [];
    }
  }

  // ==================== OPERAÇÕES DE MENSAGENS ====================

  /// Envia uma nova mensagem
  static Future<void> sendMessage(ChatMessageModel message) async {
    try {
      print('📤 Enviando mensagem: ${message.id}');
      
      // Validar mensagem
      if (!message.isValid) {
        throw Exception('Mensagem inválida');
      }
      
      // Salvar mensagem
      await _firestore
          .collection(_messagesCollection)
          .doc(message.id)
          .set(message.toMap());
      
      // Atualizar última mensagem do chat
      await updateChatFields(message.chatId, {
        'lastMessage': message.message,
        'lastMessageAt': Timestamp.fromDate(message.timestamp),
      });
      
      // Incrementar contador de não lidas para o destinatário
      await _incrementUnreadCount(message.chatId, message.senderId);
      
      print('✅ Mensagem enviada com sucesso: ${message.id}');
      
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Busca mensagens de um chat com paginação
  static Future<List<ChatMessageModel>> getChatMessages(
    String chatId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      print('🔍 Buscando mensagens do chat: $chatId (limit: $limit)');
      
      Query query = _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      final messages = <ChatMessageModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final message = ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>);
          messages.add(message);
        } catch (e) {
          print('❌ Erro ao processar mensagem ${doc.id}: $e');
        }
      }
      
      print('✅ Encontradas ${messages.length} mensagens');
      return messages;
      
    } catch (e) {
      print('❌ Erro ao buscar mensagens: $e');
      return [];
    }
  }

  /// Stream de mensagens em tempo real
  static Stream<List<ChatMessageModel>> getMessagesStream(String chatId, {int limit = 50}) {
    print('🔄 Iniciando stream de mensagens para chat: $chatId');
    
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final messages = <ChatMessageModel>[];
          
          for (final doc in snapshot.docs) {
            try {
              final message = ChatMessageModel.fromMap(doc.data());
              messages.add(message);
            } catch (e) {
              print('❌ Erro ao processar mensagem do stream ${doc.id}: $e');
            }
          }
          
          return messages;
        });
  }

  /// Marca mensagens como lidas
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      print('👁️ Marcando mensagens como lidas: $chatId, usuário: $userId');
      
      // Buscar mensagens não lidas do chat que não foram enviadas pelo usuário
      final unreadMessages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();
      
      if (unreadMessages.docs.isEmpty) {
        print('📋 Nenhuma mensagem não lida encontrada');
        return;
      }
      
      // Marcar como lidas em lote
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      
      // Zerar contador de não lidas
      await updateChatFields(chatId, {
        'unreadCount.$userId': 0,
      });
      
      print('✅ ${unreadMessages.docs.length} mensagens marcadas como lidas');
      
    } catch (e) {
      print('❌ Erro ao marcar mensagens como lidas: $e');
    }
  }

  /// Incrementa contador de mensagens não lidas
  static Future<void> _incrementUnreadCount(String chatId, String senderId) async {
    try {
      // Buscar chat atual para obter contadores
      final chat = await getChatById(chatId);
      if (chat == null) return;
      
      // Determinar quem é o destinatário
      final recipientId = chat.getOtherUserId(senderId);
      final currentCount = chat.getUnreadCount(recipientId);
      
      // Incrementar contador
      await updateChatFields(chatId, {
        'unreadCount.$recipientId': currentCount + 1,
      });
      
      print('📊 Contador não lidas incrementado: $recipientId = ${currentCount + 1}');
      
    } catch (e) {
      print('❌ Erro ao incrementar contador não lidas: $e');
    }
  }

  /// Obtém contagem de mensagens não lidas de um chat
  static Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return 0;
      
      return chat.getUnreadCount(userId);
      
    } catch (e) {
      print('❌ Erro ao obter contagem não lidas: $e');
      return 0;
    }
  }

  // ==================== OPERAÇÕES DE LIMPEZA ====================

  /// Remove mensagens antigas (mais de 60 dias)
  static Future<void> cleanupOldMessages() async {
    try {
      print('🧹 Limpando mensagens antigas...');
      
      final cutoffDate = DateTime.now().subtract(const Duration(days: 60));
      
      final oldMessages = await _firestore
          .collection(_messagesCollection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(100) // Processar em lotes
          .get();
      
      if (oldMessages.docs.isEmpty) {
        print('📋 Nenhuma mensagem antiga encontrada');
        return;
      }
      
      // Deletar em lote
      final batch = _firestore.batch();
      for (final doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ ${oldMessages.docs.length} mensagens antigas removidas');
      
    } catch (e) {
      print('❌ Erro ao limpar mensagens antigas: $e');
    }
  }

  /// Remove chats expirados há mais de 30 dias
  static Future<void> cleanupExpiredChats() async {
    try {
      print('🧹 Limpando chats expirados...');
      
      final cutoffDate = DateTime.now().subtract(const Duration(days: 60));
      
      final expiredChats = await _firestore
          .collection(_chatsCollection)
          .where('isExpired', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(50) // Processar em lotes
          .get();
      
      if (expiredChats.docs.isEmpty) {
        print('📋 Nenhum chat expirado antigo encontrado');
        return;
      }
      
      // Deletar chats e suas mensagens
      for (final chatDoc in expiredChats.docs) {
        final chatId = chatDoc.id;
        
        // Deletar mensagens do chat
        final messages = await _firestore
            .collection(_messagesCollection)
            .where('chatId', isEqualTo: chatId)
            .get();
        
        final batch = _firestore.batch();
        
        // Adicionar mensagens ao lote de deleção
        for (final messageDoc in messages.docs) {
          batch.delete(messageDoc.reference);
        }
        
        // Adicionar chat ao lote de deleção
        batch.delete(chatDoc.reference);
        
        await batch.commit();
        
        print('🗑️ Chat $chatId e ${messages.docs.length} mensagens removidos');
      }
      
      print('✅ ${expiredChats.docs.length} chats expirados removidos');
      
    } catch (e) {
      print('❌ Erro ao limpar chats expirados: $e');
    }
  }

  // ==================== ESTATÍSTICAS ====================

  /// Obtém estatísticas de um chat
  static Future<Map<String, dynamic>> getChatStats(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) {
        return {
          'exists': false,
          'totalMessages': 0,
          'unreadMessages': 0,
          'lastActivity': null,
        };
      }
      
      // Contar mensagens totais
      final messagesCount = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .count()
          .get();
      
      final totalUnread = chat.unreadCount.values.fold<int>(0, (sum, count) => sum + count);
      
      return {
        'exists': true,
        'totalMessages': messagesCount.count,
        'unreadMessages': totalUnread,
        'lastActivity': chat.lastMessageAt,
        'daysRemaining': chat.daysRemaining,
        'isExpired': chat.hasExpired,
      };
      
    } catch (e) {
      print('❌ Erro ao obter estatísticas do chat: $e');
      return {
        'exists': false,
        'totalMessages': 0,
        'unreadMessages': 0,
        'lastActivity': null,
      };
    }
  }

  /// Obtém estatísticas gerais do usuário
  static Future<Map<String, int>> getUserChatStats(String userId) async {
    try {
      final userChats = await getUserChats(userId);
      
      int activeChats = 0;
      int expiredChats = 0;
      int totalUnread = 0;
      
      for (final chat in userChats) {
        if (chat.hasExpired) {
          expiredChats++;
        } else {
          activeChats++;
        }
        
        totalUnread += chat.getUnreadCount(userId);
      }
      
      return {
        'totalChats': userChats.length,
        'activeChats': activeChats,
        'expiredChats': expiredChats,
        'totalUnreadMessages': totalUnread,
      };
      
    } catch (e) {
      print('❌ Erro ao obter estatísticas do usuário: $e');
      return {
        'totalChats': 0,
        'activeChats': 0,
        'expiredChats': 0,
        'totalUnreadMessages': 0,
      };
    }
  }
}