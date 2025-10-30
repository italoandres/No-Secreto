import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/accepted_match_model.dart';
import '../models/interest_notification_model.dart';

/// Repositório responsável por gerenciar matches aceitos
///
/// Funcionalidades:
/// - Buscar matches aceitos do usuário
/// - Integrar com sistema de notificações existente
/// - Filtrar notificações com status 'accepted'
/// - Cache local para performance
class AcceptedMatchesRepository {
  final FirebaseFirestore _firestore;
  final Map<String, List<AcceptedMatchModel>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  AcceptedMatchesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Busca todos os matches aceitos do usuário
  ///
  /// [userId] ID do usuário atual
  /// [useCache] Se deve usar cache local (padrão: true)
  /// Retorna lista de matches aceitos ordenados por data
  Future<List<AcceptedMatchModel>> getAcceptedMatches(
    String userId, {
    bool useCache = true,
  }) async {
    try {
      // Verificar cache primeiro
      if (useCache && _isCacheValid(userId)) {
        safePrint(
            'AcceptedMatchesRepository: Usando cache para usuário $userId');
        return _cache[userId] ?? [];
      }

      safePrint(
          'AcceptedMatchesRepository: Buscando matches aceitos para usuário $userId');

      // Buscar notificações de interesse aceitas
      final acceptedNotifications =
          await _getAcceptedInterestNotifications(userId);

      // Converter para AcceptedMatchModel
      final matches = <AcceptedMatchModel>[];

      for (final notification in acceptedNotifications) {
        try {
          final match = await _convertNotificationToMatch(notification, userId);
          if (match != null) {
            matches.add(match);
          }
        } catch (e) {
          safePrint(
              'AcceptedMatchesRepository: Erro ao converter notificação ${notification.id}: $e');
          // Continue processando outras notificações
        }
      }

      // Ordenar por data de aceitação (mais recentes primeiro)
      matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));

      // Atualizar cache
      _updateCache(userId, matches);

      safePrint(
          'AcceptedMatchesRepository: Encontrados ${matches.length} matches aceitos');
      return matches;
    } catch (e) {
      safePrint(
          'AcceptedMatchesRepository: Erro ao buscar matches aceitos: $e');

      // Retornar cache se disponível, mesmo expirado
      if (_cache.containsKey(userId)) {
        safePrint(
            'AcceptedMatchesRepository: Retornando cache expirado devido ao erro');
        return _cache[userId] ?? [];
      }

      return [];
    }
  }

  /// Busca matches aceitos em tempo real (stream)
  ///
  /// [userId] ID do usuário atual
  /// Retorna stream de lista de matches aceitos
  Stream<List<AcceptedMatchModel>> getAcceptedMatchesStream(String userId) {
    return _getAcceptedInterestNotificationsStream(userId)
        .asyncMap((notifications) async {
      final matches = <AcceptedMatchModel>[];

      for (final notification in notifications) {
        try {
          final match = await _convertNotificationToMatch(notification, userId);
          if (match != null) {
            matches.add(match);
          }
        } catch (e) {
          safePrint(
              'AcceptedMatchesRepository: Erro no stream para notificação ${notification.id}: $e');
        }
      }

      // Ordenar por data de aceitação
      matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));

      // Atualizar cache
      _updateCache(userId, matches);

      return matches;
    });
  }

  /// Busca um match específico por ID
  ///
  /// [userId] ID do usuário atual
  /// [matchId] ID do match a ser buscado
  /// Retorna o match encontrado ou null
  Future<AcceptedMatchModel?> getMatchById(
      String userId, String matchId) async {
    try {
      // Verificar cache primeiro
      final cachedMatches = _cache[userId];
      if (cachedMatches != null) {
        final cachedMatch =
            cachedMatches.where((m) => m.notificationId == matchId).firstOrNull;
        if (cachedMatch != null) {
          return cachedMatch;
        }
      }

      // Buscar no Firebase
      final notificationDoc = await _firestore
          .collection('interest_notifications')
          .doc(matchId)
          .get();

      if (!notificationDoc.exists) {
        return null;
      }

      final notification = InterestNotificationModel.fromMap(
          {...notificationDoc.data()!, 'id': notificationDoc.id});

      if (notification.status != 'accepted') {
        return null;
      }

      return await _convertNotificationToMatch(notification, userId);
    } catch (e) {
      safePrint(
          'AcceptedMatchesRepository: Erro ao buscar match $matchId: $e');
      return null;
    }
  }

  /// Atualiza o status de leitura de um match
  ///
  /// [matchId] ID do match
  /// [isRead] Novo status de leitura
  Future<bool> updateReadStatus(String matchId, bool isRead) async {
    try {
      await _firestore
          .collection('interest_notifications')
          .doc(matchId)
          .update({
        'isRead': isRead,
        'readAt': isRead ? FieldValue.serverTimestamp() : null,
      });

      // Invalidar cache para forçar atualização
      _clearCache();

      return true;
    } catch (e) {
      safePrint(
          'AcceptedMatchesRepository: Erro ao atualizar status de leitura: $e');
      return false;
    }
  }

  /// Conta o número de matches não lidos
  ///
  /// [userId] ID do usuário atual
  /// Retorna número de matches não lidos
  Future<int> getUnreadMatchesCount(String userId) async {
    try {
      final query = await _firestore
          .collection('interest_notifications')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      safePrint(
          'AcceptedMatchesRepository: Erro ao contar matches não lidos: $e');
      return 0;
    }
  }

  /// Busca notificações de interesse aceitas do Firebase
  Future<List<InterestNotificationModel>> _getAcceptedInterestNotifications(
      String userId) async {
    final query = await _firestore
        .collection('interest_notifications')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('dataResposta', descending: true)
        .limit(50) // Limitar para performance
        .get();

    return query.docs
        .map((doc) =>
            InterestNotificationModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Stream de notificações de interesse aceitas
  Stream<List<InterestNotificationModel>>
      _getAcceptedInterestNotificationsStream(String userId) {
    return _firestore
        .collection('interest_notifications')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('dataResposta', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InterestNotificationModel.fromMap(
                {...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Converte uma notificação de interesse em AcceptedMatchModel
  Future<AcceptedMatchModel?> _convertNotificationToMatch(
    InterestNotificationModel notification,
    String currentUserId,
  ) async {
    try {
      // Determinar o ID do outro usuário
      final otherUserId = notification.fromUserId == currentUserId
          ? notification.toUserId
          : notification.fromUserId;

      // Buscar dados do outro usuário
      final otherUserDoc =
          await _firestore.collection('usuarios').doc(otherUserId).get();

      if (!otherUserDoc.exists) {
        safePrint(
            'AcceptedMatchesRepository: Usuário $otherUserId não encontrado');
        return null;
      }

      final otherUserData = otherUserDoc.data() as Map<String, dynamic>;

      // Gerar ID único do chat
      final chatId = _generateChatId(currentUserId, otherUserId!);

      // Calcular dias restantes e status de expiração
      final matchDate = notification.dataResposta?.toDate() ??
          notification.dataCriacao?.toDate() ??
          DateTime.now();
      final daysRemaining = 30 - DateTime.now().difference(matchDate).inDays;
      final chatExpired = daysRemaining <= 0;

      return AcceptedMatchModel.fromNotification(
        notificationId: notification.id!,
        otherUserId: otherUserId,
        otherUserName: otherUserData['nome'] ?? 'Usuário',
        otherUserPhoto: otherUserData['photoURL'],
        matchDate: matchDate,
        chatId: chatId,
        unreadMessages: 0, // Será preenchido pelo MatchChatService
        chatExpired: chatExpired,
        daysRemaining: daysRemaining.clamp(0, 30),
      );
    } catch (e) {
      safePrint(
          'AcceptedMatchesRepository: Erro ao converter notificação: $e');
      return null;
    }
  }

  /// Gera ID único para o chat baseado nos IDs dos usuários
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'match_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Verifica se o cache é válido
  bool _isCacheValid(String userId) {
    if (!_cache.containsKey(userId) || !_cacheTimestamps.containsKey(userId)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[userId]!;
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheExpiration;
  }

  /// Atualiza o cache com novos dados
  void _updateCache(String userId, List<AcceptedMatchModel> matches) {
    _cache[userId] = matches;
    _cacheTimestamps[userId] = DateTime.now();
  }

  /// Limpa todo o cache
  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Limpa cache de um usuário específico
  void clearUserCache(String userId) {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Força atualização do cache para um usuário
  Future<List<AcceptedMatchModel>> refreshMatches(String userId) async {
    clearUserCache(userId);
    return await getAcceptedMatches(userId, useCache: false);
  }
}

/// Extensão para adicionar firstOrNull se não estiver disponível
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
