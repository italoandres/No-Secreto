import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/match_chat_model.dart';
import '../models/chat_message_model.dart';
import '../services/chat_expiration_service.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

/// Serviço responsável por gerenciar operações de chat entre matches
///
/// Funcionalidades:
/// - Criar ou obter ID único do chat
/// - Verificar expiração de chats
/// - Gerenciar contadores de mensagens não lidas
/// - Atualizar última mensagem do chat
class MatchChatService {
  final FirebaseFirestore _firestore;
  final Map<String, MatchChatModel> _chatCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 2);

  MatchChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Cria ou obtém o ID único do chat entre dois usuários
  ///
  /// [userId1] ID do primeiro usuário
  /// [userId2] ID do segundo usuário
  /// Retorna ID único do chat
  String createOrGetChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'match_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Cria um novo chat no Firebase se não existir
  ///
  /// [chatId] ID único do chat
  /// [userId1] ID do primeiro usuário
  /// [userId2] ID do segundo usuário
  /// [matchNotificationId] ID da notificação de match
  /// Retorna o modelo do chat criado ou existente
  Future<MatchChatModel> createOrGetChat({
    required String chatId,
    required String userId1,
    required String userId2,
    required String matchNotificationId,
  }) async {
    try {
      // Verificar cache primeiro
      if (_isChatCacheValid(chatId)) {
        safePrint('MatchChatService: Usando cache para chat $chatId');
        return _chatCache[chatId]!;
      }

      // Verificar se chat já existe no Firebase
      final chatDoc =
          await _firestore.collection('match_chats').doc(chatId).get();

      MatchChatModel chat;

      if (chatDoc.exists) {
        // Chat já existe, carregar dados
        chat = MatchChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
        safePrint('MatchChatService: Chat $chatId já existe');
      } else {
        // Criar novo chat
        chat = MatchChatModel.create(
          user1Id: userId1,
          user2Id: userId2,
        );

        // Salvar no Firebase
        await _firestore
            .collection('match_chats')
            .doc(chatId)
            .set(chat.toMap());

        safePrint('MatchChatService: Novo chat $chatId criado');
      }

      // Atualizar cache
      _updateChatCache(chatId, chat);

      return chat;
    } catch (e) {
      safePrint('MatchChatService: Erro ao criar/obter chat $chatId: $e');
      rethrow;
    }
  }

  /// Verifica se o chat está expirado
  ///
  /// [chatId] ID do chat a ser verificado
  /// Retorna true se o chat expirou
  Future<bool> isChatExpired(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return true;

      return ChatExpirationService.isChatExpired(chat.createdAt);
    } catch (e) {
      safePrint(
          'MatchChatService: Erro ao verificar expiração do chat $chatId: $e');
      return true; // Assumir expirado em caso de erro
    }
  }

  /// Obtém informações de um chat específico
  ///
  /// [chatId] ID do chat
  /// Retorna modelo do chat ou null se não encontrado
  Future<MatchChatModel?> getChatById(String chatId) async {
    try {
      // Verificar cache primeiro
      if (_isChatCacheValid(chatId)) {
        return _chatCache[chatId];
      }

      final chatDoc =
          await _firestore.collection('match_chats').doc(chatId).get();

      if (!chatDoc.exists) {
        return null;
      }

      final chat =
          MatchChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
      _updateChatCache(chatId, chat);

      return chat;
    } catch (e) {
      safePrint('MatchChatService: Erro ao buscar chat $chatId: $e');
      return null;
    }
  }

  /// Atualiza a última mensagem do chat
  ///
  /// [chatId] ID do chat
  /// [message] Modelo da mensagem enviada
  /// [senderId] ID do usuário que enviou a mensagem
  Future<bool> updateLastMessage({
    required String chatId,
    required ChatMessageModel message,
    required String senderId,
  }) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) {
        safePrint(
            'MatchChatService: Chat $chatId não encontrado para atualizar última mensagem');
        return false;
      }

      // Verificar se chat não expirou
      if (ChatExpirationService.isChatExpired(chat.createdAt)) {
        safePrint(
            'MatchChatService: Tentativa de atualizar chat expirado $chatId');
        return false;
      }

      // Calcular novos contadores de mensagens não lidas
      final newUnreadCounts = Map<String, int>.from(chat.unreadCount);

      // Incrementar contador para o outro usuário (não o remetente)
      final otherUserId = chat.getOtherUserId(senderId);
      newUnreadCounts[otherUserId] = (newUnreadCounts[otherUserId] ?? 0) + 1;

      // Atualizar no Firebase
      await _firestore.collection('match_chats').doc(chatId).update({
        'lastMessage': message.message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': newUnreadCounts,
      });

      // Invalidar cache para forçar atualização
      _clearChatCache(chatId);

      safePrint(
          'MatchChatService: Última mensagem atualizada para chat $chatId');
      return true;
    } catch (e) {
      safePrint(
          'MatchChatService: Erro ao atualizar última mensagem do chat $chatId: $e');
      return false;
    }
  }

  /// Marca mensagens como lidas para um usuário
  ///
  /// [chatId] ID do chat
  /// [userId] ID do usuário que leu as mensagens
  Future<bool> markMessagesAsRead(String chatId, String userId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) {
        safePrint(
            'MatchChatService: Chat $chatId não encontrado para marcar como lido');
        return false;
      }

      // Verificar se há mensagens não lidas
      final currentUnreadCount = chat.unreadCount[userId] ?? 0;
      if (currentUnreadCount == 0) {
        safePrint(
            'MatchChatService: Nenhuma mensagem não lida para usuário $userId no chat $chatId');
        return true; // Já está atualizado
      }

      // Zerar contador de mensagens não lidas
      final newUnreadCounts = Map<String, int>.from(chat.unreadCount);
      newUnreadCounts[userId] = 0;

      // Atualizar no Firebase
      await _firestore.collection('match_chats').doc(chatId).update({
        'unreadCount': newUnreadCounts,
      });

      // Invalidar cache
      _clearChatCache(chatId);

      safePrint(
          'MatchChatService: Mensagens marcadas como lidas para usuário $userId no chat $chatId');
      return true;
    } catch (e) {
      safePrint(
          'MatchChatService: Erro ao marcar mensagens como lidas no chat $chatId: $e');
      return false;
    }
  }

  /// Obtém o número de mensagens não lidas para um usuário
  ///
  /// [chatId] ID do chat
  /// [userId] ID do usuário
  /// Retorna número de mensagens não lidas
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return 0;

      return chat.unreadCount[userId] ?? 0;
    } catch (e) {
      safePrint(
          'MatchChatService: Erro ao obter contagem não lida do chat $chatId: $e');
      return 0;
    }
  }

  /// Desativa um chat (marca como inativo)
  ///
  /// [chatId] ID do chat a ser desativado
  /// [reason] Motivo da desativação (opcional)
  Future<bool> deactivateChat(String chatId, {String? reason}) async {
    try {
      await _firestore.collection('match_chats').doc(chatId).update({
        'isExpired': true,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivationReason': reason,
      });

      // Invalidar cache
      _clearChatCache(chatId);

      safePrint('MatchChatService: Chat $chatId desativado. Motivo: $reason');
      return true;
    } catch (e) {
      safePrint('MatchChatService: Erro ao desativar chat $chatId: $e');
      return false;
    }
  }

  /// Reativa um chat (marca como ativo novamente)
  ///
  /// [chatId] ID do chat a ser reativado
  Future<bool> reactivateChat(String chatId) async {
    try {
      await _firestore.collection('match_chats').doc(chatId).update({
        'isExpired': false,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'deactivationReason': FieldValue.delete(),
      });

      // Invalidar cache
      _clearChatCache(chatId);

      safePrint('MatchChatService: Chat $chatId reativado');
      return true;
    } catch (e) {
      safePrint('MatchChatService: Erro ao reativar chat $chatId: $e');
      return false;
    }
  }

  /// Obtém estatísticas do chat
  ///
  /// [chatId] ID do chat
  /// Retorna mapa com estatísticas
  Future<Map<String, dynamic>> getChatStats(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) {
        return {'error': 'Chat não encontrado'};
      }

      // Contar mensagens totais
      final messagesQuery = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .count()
          .get();

      final totalMessages = messagesQuery.count ?? 0;

      // Calcular dias restantes
      final daysRemaining =
          ChatExpirationService.getDaysRemaining(chat.createdAt);
      final isExpired = ChatExpirationService.isChatExpired(chat.createdAt);

      return {
        'chatId': chatId,
        'totalMessages': totalMessages,
        'daysRemaining': daysRemaining,
        'isExpired': isExpired,
        'createdAt': chat.createdAt.toIso8601String(),
        'participants': [chat.user1Id, chat.user2Id],
        'unreadCounts': chat.unreadCount,
        'lastMessageAt': chat.lastMessageAt?.toIso8601String(),
      };
    } catch (e) {
      safePrint(
          'MatchChatService: Erro ao obter estatísticas do chat $chatId: $e');
      return {'error': 'Erro ao obter estatísticas'};
    }
  }

  /// Verifica se o cache do chat é válido
  bool _isChatCacheValid(String chatId) {
    if (!_chatCache.containsKey(chatId) ||
        !_cacheTimestamps.containsKey(chatId)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[chatId]!;
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheExpiration;
  }

  /// Atualiza o cache do chat
  void _updateChatCache(String chatId, MatchChatModel chat) {
    _chatCache[chatId] = chat;
    _cacheTimestamps[chatId] = DateTime.now();
  }

  /// Limpa o cache de um chat específico
  void _clearChatCache(String chatId) {
    _chatCache.remove(chatId);
    _cacheTimestamps.remove(chatId);
  }

  /// Limpa todo o cache de chats
  void clearAllCache() {
    _chatCache.clear();
    _cacheTimestamps.clear();
  }

  /// Força atualização de um chat específico
  Future<MatchChatModel?> refreshChat(String chatId) async {
    _clearChatCache(chatId);
    return await getChatById(chatId);
  }
}
