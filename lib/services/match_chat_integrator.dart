import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interest_notification_model.dart';
import '../models/accepted_match_model.dart';
import '../models/match_chat_model.dart';
import '../models/chat_message_model.dart';
import '../services/match_chat_service.dart';
import '../repositories/match_chat_repository.dart';
import '../utils/enhanced_logger.dart';

/// Serviço integrador entre sistema de notificações e sistema de chat
class MatchChatIntegrator {
  static final MatchChatIntegrator _instance = MatchChatIntegrator._internal();
  factory MatchChatIntegrator() => _instance;
  MatchChatIntegrator._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final MatchChatService _chatService = MatchChatService();
  static final MatchChatRepository _chatRepository = MatchChatRepository();

  /// Criar chat automaticamente quando um interesse é aceito
  /// 
  /// Este método é chamado quando:
  /// 1. Um usuário aceita um interesse
  /// 2. Há interesse mútuo entre dois usuários
  /// 
  /// [notification] - Notificação de interesse aceita
  /// [isMutualMatch] - Se é um match mútuo (ambos demonstraram interesse)
  static Future<String?> createChatFromAcceptedInterest({
    required InterestNotificationModel notification,
    bool isMutualMatch = false,
  }) async {
    try {
      EnhancedLogger.info('🚀 Criando chat a partir de interesse aceito', 
        tag: 'MATCH_CHAT_INTEGRATOR',
        data: {
          'fromUserId': notification.fromUserId,
          'toUserId': notification.toUserId,
          'isMutualMatch': isMutualMatch,
        }
      );

      // Verificar se os usuários existem
      final fromUserDoc = await _firestore
          .collection('usuarios')
          .doc(notification.fromUserId)
          .get();
      
      final toUserDoc = await _firestore
          .collection('usuarios')
          .doc(notification.toUserId)
          .get();

      if (!fromUserDoc.exists || !toUserDoc.exists) {
        EnhancedLogger.error('Usuários não encontrados para criar chat', 
          tag: 'MATCH_CHAT_INTEGRATOR');
        return null;
      }

      final fromUserData = fromUserDoc.data()!;
      final toUserData = toUserDoc.data()!;

      // Gerar ID único do chat primeiro
      final chatId = _chatService.createOrGetChatId(
        notification.fromUserId!,
        notification.toUserId!,
      );

      // Criar AcceptedMatchModel a partir da notificação
      final matchDate = notification.dataCriacao is DateTime 
          ? notification.dataCriacao as DateTime
          : DateTime.now();
          
      final acceptedMatch = AcceptedMatchModel.fromNotification(
        notificationId: notification.id ?? '',
        otherUserId: notification.toUserId!,
        otherUserName: toUserData['nome'] ?? 'Usuário',
        otherUserPhoto: toUserData['photoUrl'],
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 0,
        chatExpired: false,
        daysRemaining: 30,
      );

      // Verificar se o chat já existe
      final existingChat = await MatchChatRepository.getChatById(chatId);
      if (existingChat != null) {
        EnhancedLogger.info('Chat já existe, não criando duplicado', 
          tag: 'MATCH_CHAT_INTEGRATOR',
          data: {'chatId': chatId}
        );
        return chatId;
      }

      // Criar modelo de chat
      final chatModel = MatchChatModel.create(
        user1Id: notification.fromUserId!,
        user2Id: notification.toUserId!,
      );

      // Criar o chat no Firebase
      await MatchChatRepository.createChat(chatModel);

      // Enviar mensagem de boas-vindas automática
      await _sendWelcomeMessage(
        chatId: chatId,
        otherUserName: toUserData['nome'] ?? 'Usuário',
        isMutualMatch: isMutualMatch,
      );

      EnhancedLogger.info('✅ Chat criado com sucesso', 
        tag: 'MATCH_CHAT_INTEGRATOR',
        data: {'chatId': chatId}
      );

      return chatId;

    } catch (e) {
      EnhancedLogger.error('Erro ao criar chat a partir de interesse aceito: $e', 
        tag: 'MATCH_CHAT_INTEGRATOR');
      return null;
    }
  }

  /// Enviar mensagem de boas-vindas automática
  static Future<void> _sendWelcomeMessage({
    required String chatId,
    required String otherUserName,
    required bool isMutualMatch,
  }) async {
    try {
      String welcomeMessage;
      
      if (isMutualMatch) {
        welcomeMessage = '🎉 Vocês têm um match! Ambos demonstraram interesse um no outro. '
                        'Este chat expira em 30 dias. Aproveitem para se conhecer melhor! 💕';
      } else {
        welcomeMessage = '💕 $otherUserName aceitou seu interesse! '
                        'Este chat expira em 30 dias. Que tal começar uma conversa? 😊';
      }

      final welcomeMessageModel = ChatMessageModel.create(
        chatId: chatId,
        senderId: 'system',
        senderName: 'Sistema',
        message: welcomeMessage,
        type: MessageType.system,
      );

      await MatchChatRepository.sendMessage(welcomeMessageModel);

      EnhancedLogger.info('Mensagem de boas-vindas enviada', 
        tag: 'MATCH_CHAT_INTEGRATOR',
        data: {'chatId': chatId}
      );

    } catch (e) {
      EnhancedLogger.error('Erro ao enviar mensagem de boas-vindas: $e', 
        tag: 'MATCH_CHAT_INTEGRATOR');
      // Não lançar exceção para não impedir a criação do chat
    }
  }

  /// Sincronizar contadores de mensagens não lidas
  /// 
  /// Este método atualiza os contadores quando:
  /// - Uma nova mensagem é enviada
  /// - Uma mensagem é marcada como lida
  /// - Um chat é aberto
  static Future<void> syncUnreadMessageCounters({
    required String chatId,
    required String userId,
    int? newUnreadCount,
  }) async {
    try {
      // Marcar mensagens como lidas se newUnreadCount for 0
      if (newUnreadCount == 0) {
        await MatchChatRepository.markMessagesAsRead(chatId, userId);
      }

      // Atualizar contador global do usuário
      await _updateGlobalUnreadCount(userId);

      EnhancedLogger.info('Contadores sincronizados', 
        tag: 'MATCH_CHAT_INTEGRATOR',
        data: {
          'chatId': chatId,
          'userId': userId,
          'newUnreadCount': newUnreadCount,
        }
      );

    } catch (e) {
      EnhancedLogger.error('Erro ao sincronizar contadores: $e', 
        tag: 'MATCH_CHAT_INTEGRATOR');
    }
  }

  /// Atualizar contador global de mensagens não lidas do usuário
  static Future<void> _updateGlobalUnreadCount(String userId) async {
    try {
      // Buscar todos os chats do usuário
      final userChats = await MatchChatRepository.getUserChats(userId);
      
      // Calcular total de mensagens não lidas
      int totalUnread = 0;
      for (final chat in userChats) {
        final unreadCount = await MatchChatRepository.getUnreadCount(chat.id, userId);
        totalUnread += unreadCount;
      }

      // Atualizar no documento do usuário
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .update({
        'unreadMatchMessages': totalUnread,
        'lastUnreadUpdate': Timestamp.now(),
      });

      EnhancedLogger.info('Contador global atualizado', 
        tag: 'MATCH_CHAT_INTEGRATOR',
        data: {
          'userId': userId,
          'totalUnread': totalUnread,
        }
      );

    } catch (e) {
      EnhancedLogger.error('Erro ao atualizar contador global: $e', 
        tag: 'MATCH_CHAT_INTEGRATOR');
    }
  }

  /// Verificar se um chat deve ser criado para uma notificação
  static Future<bool> shouldCreateChatForNotification(
    InterestNotificationModel notification,
  ) async {
    try {
      // Só criar chat se a notificação foi aceita
      if (notification.status != 'accepted') {
        return false;
      }

      // Verificar se o chat já existe
      final chatId = _chatService.createOrGetChatId(
        notification.fromUserId!,
        notification.toUserId!,
      );

      final existingChat = await MatchChatRepository.getChatById(chatId);
      return existingChat == null;

    } catch (e) {
      EnhancedLogger.error('Erro ao verificar se deve criar chat: $e', 
        tag: 'MATCH_CHAT_INTEGRATOR');
      return false;
    }
  }

  /// Obter estatísticas de integração
  static Future<Map<String, dynamic>> getIntegrationStats(String userId) async {
    try {
      final userChats = await MatchChatRepository.getUserChats(userId);
      
      int totalChats = userChats.length;
      int activeChats = 0;
      int totalUnread = 0;
      
      for (final chat in userChats) {
        final isExpired = await _chatService.isChatExpired(chat.id);
        if (!isExpired) {
          activeChats++;
        }
        
        final unreadCount = await MatchChatRepository.getUnreadCount(chat.id, userId);
        totalUnread += unreadCount;
      }
      
      int expiredChats = totalChats - activeChats;

      return {
        'totalChats': totalChats,
        'activeChats': activeChats,
        'expiredChats': expiredChats,
        'totalUnreadMessages': totalUnread,
        'lastSync': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      EnhancedLogger.error('Erro ao obter estatísticas de integração: $e', 
        tag: 'MATCH_CHAT_INTEGRATOR');
      return {
        'totalChats': 0,
        'activeChats': 0,
        'expiredChats': 0,
        'totalUnreadMessages': 0,
        'lastSync': DateTime.now().toIso8601String(),
      };
    }
  }
}