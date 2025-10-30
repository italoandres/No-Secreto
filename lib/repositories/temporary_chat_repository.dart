import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/temporary_chat_model.dart';
import '../models/spiritual_profile_model.dart';
import '../models/usuario_model.dart';
import '../repositories/usuario_repository.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class TemporaryChatRepository {
  static const String _chatsCollection = 'temporary_chats';
  static const String _messagesCollection = 'temporary_chat_messages';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a temporary chat from mutual interest
  static Future<TemporaryChatModel> createTemporaryChat(
    MutualInterestModel mutualInterest,
  ) async {
    try {
      safePrint(
          '💬 Criando chat temporário para interesse mútuo: ${mutualInterest.id}');

      // Get user information
      final user1 = await UsuarioRepository.getUserById(mutualInterest.user1Id);
      final user2 = await UsuarioRepository.getUserById(mutualInterest.user2Id);

      if (user1 == null || user2 == null) {
        throw Exception('Usuários não encontrados');
      }

      // Generate unique chat room ID
      final chatRoomId =
          'temp_${mutualInterest.user1Id}_${mutualInterest.user2Id}_${DateTime.now().millisecondsSinceEpoch}';

      // Create temporary chat
      final temporaryChat = TemporaryChatModel(
        mutualInterestId: mutualInterest.id!,
        user1Id: mutualInterest.user1Id,
        user2Id: mutualInterest.user2Id,
        chatRoomId: chatRoomId,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        user1Name: user1.nome,
        user1Username: user1.username,
        user1PhotoUrl: user1.imgUrl,
        user2Name: user2.nome,
        user2Username: user2.username,
        user2PhotoUrl: user2.imgUrl,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_chatsCollection)
          .add(temporaryChat.toJson());
      temporaryChat.id = docRef.id;

      // Send welcome message
      await _sendWelcomeMessage(temporaryChat);

      safePrint('✅ Chat temporário criado: ${temporaryChat.id}');
      return temporaryChat;
    } catch (e) {
      safePrint('❌ Erro ao criar chat temporário: $e');
      rethrow;
    }
  }

  /// Send welcome message to temporary chat
  static Future<void> _sendWelcomeMessage(TemporaryChatModel chat) async {
    try {
      final welcomeMessage = TemporaryChatMessageModel(
        chatRoomId: chat.chatRoomId,
        senderId: 'system',
        senderName: 'Sistema',
        message: '💕 Vocês demonstraram interesse mútuo!\n\n'
            'Este é um chat temporário de 7 dias para vocês se conhecerem melhor. '
            'Conversem com respeito e propósito espiritual.\n\n'
            'Ao final dos 7 dias, vocês podem decidir se querem continuar no "Nosso Propósito".\n\n'
            '⚠️ Lembrem-se: este é um terreno sagrado. Conexões aqui devem honrar Deus.',
        timestamp: DateTime.now(),
        messageType: 'welcome',
      );

      await _firestore
          .collection(_messagesCollection)
          .add(welcomeMessage.toJson());

      safePrint('✅ Mensagem de boas-vindas enviada');
    } catch (e) {
      safePrint('❌ Erro ao enviar mensagem de boas-vindas: $e');
    }
  }

  /// Get temporary chat by mutual interest ID
  static Future<TemporaryChatModel?> getChatByMutualInterestId(
      String mutualInterestId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_chatsCollection)
          .where('mutualInterestId', isEqualTo: mutualInterestId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final chat = TemporaryChatModel.fromJson(doc.data());
      chat.id = doc.id;

      return chat;
    } catch (e) {
      safePrint('❌ Erro ao buscar chat por interesse mútuo: $e');
      return null;
    }
  }

  /// Get temporary chat by chat room ID
  static Future<TemporaryChatModel?> getChatByRoomId(String chatRoomId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_chatsCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final chat = TemporaryChatModel.fromJson(doc.data());
      chat.id = doc.id;

      return chat;
    } catch (e) {
      safePrint('❌ Erro ao buscar chat por room ID: $e');
      return null;
    }
  }

  /// Get all active temporary chats for current user
  static Future<List<TemporaryChatModel>> getUserTemporaryChats() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      safePrint(
          '🔍 Buscando chats temporários para usuário: ${currentUser.uid}');

      // Query for chats where user is participant
      final querySnapshot1 = await _firestore
          .collection(_chatsCollection)
          .where('user1Id', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .get();

      final querySnapshot2 = await _firestore
          .collection(_chatsCollection)
          .where('user2Id', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .get();

      final chats = <TemporaryChatModel>[];

      // Process first query results
      for (final doc in querySnapshot1.docs) {
        final chat = TemporaryChatModel.fromJson(doc.data());
        chat.id = doc.id;
        chats.add(chat);
      }

      // Process second query results
      for (final doc in querySnapshot2.docs) {
        final chat = TemporaryChatModel.fromJson(doc.data());
        chat.id = doc.id;
        chats.add(chat);
      }

      // Sort by last message time (most recent first)
      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      safePrint('✅ Encontrados ${chats.length} chats temporários');
      return chats;
    } catch (e) {
      safePrint('❌ Erro ao buscar chats do usuário: $e');
      return [];
    }
  }

  /// Send message to temporary chat
  static Future<void> sendMessage(
    String chatRoomId,
    String message,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Get user info
      final user = await UsuarioRepository.getUserById(currentUser.uid);
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      // Get chat to verify user is participant
      final chat = await getChatByRoomId(chatRoomId);
      if (chat == null) {
        throw Exception('Chat não encontrado');
      }

      if (!chat.isParticipant(currentUser.uid)) {
        throw Exception('Usuário não é participante deste chat');
      }

      if (chat.isExpired) {
        throw Exception('Este chat expirou');
      }

      safePrint('💬 Enviando mensagem para chat: $chatRoomId');

      // Create message
      final chatMessage = TemporaryChatMessageModel(
        chatRoomId: chatRoomId,
        senderId: currentUser.uid,
        senderName: user.nome ?? 'Usuário',
        senderUsername: user.username,
        senderPhotoUrl: user.imgUrl,
        message: message.trim(),
        timestamp: DateTime.now(),
      );

      // Save message
      await _firestore
          .collection(_messagesCollection)
          .add(chatMessage.toJson());

      // Update chat with last message info
      await _firestore.collection(_chatsCollection).doc(chat.id).update({
        'lastMessage': message.trim(),
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': currentUser.uid,
        'messageCount': FieldValue.increment(1),
      });

      safePrint('✅ Mensagem enviada com sucesso');
    } catch (e) {
      safePrint('❌ Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Get messages stream for a chat room
  static Stream<List<TemporaryChatMessageModel>> getMessagesStream(
      String chatRoomId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final message = TemporaryChatMessageModel.fromJson(doc.data());
        message.id = doc.id;
        return message;
      }).toList();
    });
  }

  /// Move temporary chat to "Nosso Propósito"
  static Future<void> moveToNossoProposito(String chatId) async {
    try {
      safePrint('🔄 Movendo chat para Nosso Propósito: $chatId');

      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'movedToNossoProposito': true,
        'movedAt': Timestamp.fromDate(DateTime.now()),
        'isActive': false, // Deactivate temporary chat
      });

      // TODO: Create "Nosso Propósito" chat
      // This would integrate with the existing purpose chat system

      safePrint('✅ Chat movido para Nosso Propósito');
    } catch (e) {
      safePrint('❌ Erro ao mover chat: $e');
      rethrow;
    }
  }

  /// Expire chat (called when 7 days pass)
  static Future<void> expireChat(String chatId) async {
    try {
      safePrint('⏰ Expirando chat: $chatId');

      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'isActive': false,
      });

      // Send expiration message
      final chat =
          await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (chat.exists) {
        final chatData = TemporaryChatModel.fromJson(chat.data()!);

        final expirationMessage = TemporaryChatMessageModel(
          chatRoomId: chatData.chatRoomId,
          senderId: 'system',
          senderName: 'Sistema',
          message: '⏰ Este chat temporário expirou.\n\n'
              'Esperamos que tenham tido uma boa conversa! '
              'Se desejarem continuar se conhecendo, podem se conectar através do "Nosso Propósito".',
          timestamp: DateTime.now(),
          messageType: 'system',
        );

        await _firestore
            .collection(_messagesCollection)
            .add(expirationMessage.toJson());
      }

      safePrint('✅ Chat expirado');
    } catch (e) {
      safePrint('❌ Erro ao expirar chat: $e');
    }
  }

  /// Clean up expired chats (should be called periodically)
  static Future<void> cleanupExpiredChats() async {
    try {
      safePrint('🧹 Limpando chats expirados...');

      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_chatsCollection)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      int expiredCount = 0;

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
        expiredCount++;
      }

      if (expiredCount > 0) {
        await batch.commit();
        safePrint('✅ $expiredCount chats expirados foram desativados');
      } else {
        safePrint('✅ Nenhum chat expirado encontrado');
      }
    } catch (e) {
      safePrint('❌ Erro na limpeza de chats expirados: $e');
    }
  }

  /// Get chat statistics
  static Future<Map<String, int>> getChatStatistics() async {
    try {
      final activeChats = await _firestore
          .collection(_chatsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final expiredChats = await _firestore
          .collection(_chatsCollection)
          .where('isActive', isEqualTo: false)
          .get();

      final movedChats = await _firestore
          .collection(_chatsCollection)
          .where('movedToNossoProposito', isEqualTo: true)
          .get();

      return {
        'active': activeChats.docs.length,
        'expired': expiredChats.docs.length,
        'moved': movedChats.docs.length,
        'total': activeChats.docs.length + expiredChats.docs.length,
      };
    } catch (e) {
      safePrint('❌ Erro ao obter estatísticas: $e');
      return {'active': 0, 'expired': 0, 'moved': 0, 'total': 0};
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(
      String chatRoomId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      safePrint('✅ Mensagens marcadas como lidas');
    } catch (e) {
      safePrint('❌ Erro ao marcar mensagens como lidas: $e');
    }
  }
}
