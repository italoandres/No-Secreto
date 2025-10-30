import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interest_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Serviço de cache local para notificações de interesse
class InterestCacheService {
  static final InterestCacheService _instance =
      InterestCacheService._internal();
  factory InterestCacheService() => _instance;
  InterestCacheService._internal();

  static const String _notificationsKey = 'interest_notifications';
  static const String _sentInterestsKey = 'sent_interests';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _userStatsKey = 'user_stats';

  /// Salvar notificações no cache
  Future<void> cacheNotifications(
      List<InterestNotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(notificationsJson));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      EnhancedLogger.info('Notificações salvas no cache',
          tag: 'INTEREST_CACHE', data: {'count': notifications.length});
    } catch (e) {
      EnhancedLogger.error('Erro ao salvar notificações no cache: $e',
          tag: 'INTEREST_CACHE');
    }
  }

  /// Obter notificações do cache
  Future<List<InterestNotificationModel>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsString = prefs.getString(_notificationsKey);

      if (notificationsString == null) {
        return [];
      }

      final notificationsJson = jsonDecode(notificationsString) as List;
      final notifications = notificationsJson
          .map((json) =>
              InterestNotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      EnhancedLogger.info('Notificações carregadas do cache',
          tag: 'INTEREST_CACHE', data: {'count': notifications.length});

      return notifications;
    } catch (e) {
      EnhancedLogger.error('Erro ao carregar notificações do cache: $e',
          tag: 'INTEREST_CACHE');
      return [];
    }
  }

  /// Salvar interesse enviado no cache
  Future<void> cacheSentInterest(InterestNotificationModel interest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSentString = prefs.getString(_sentInterestsKey);

      List<Map<String, dynamic>> sentInterests = [];
      if (existingSentString != null) {
        final existingSent = jsonDecode(existingSentString) as List;
        sentInterests = existingSent.cast<Map<String, dynamic>>();
      }

      // Adicionar novo interesse
      sentInterests.add(interest.toJson());

      // Manter apenas os últimos 100 interesses enviados
      if (sentInterests.length > 100) {
        sentInterests = sentInterests.sublist(sentInterests.length - 100);
      }

      await prefs.setString(_sentInterestsKey, jsonEncode(sentInterests));

      EnhancedLogger.info('Interesse enviado salvo no cache',
          tag: 'INTEREST_CACHE', data: {'targetUserId': interest.toUserId});
    } catch (e) {
      EnhancedLogger.error('Erro ao salvar interesse enviado no cache: $e',
          tag: 'INTEREST_CACHE');
    }
  }

  /// Verificar se já existe interesse enviado (cache local)
  Future<bool> hasSentInterestCached(String targetUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sentInterestsString = prefs.getString(_sentInterestsKey);

      if (sentInterestsString == null) {
        return false;
      }

      final sentInterests = jsonDecode(sentInterestsString) as List;
      return sentInterests
          .any((interest) => interest['toUserId'] == targetUserId);
    } catch (e) {
      EnhancedLogger.error('Erro ao verificar interesse enviado no cache: $e',
          tag: 'INTEREST_CACHE');
      return false;
    }
  }

  /// Salvar estatísticas do usuário
  Future<void> cacheUserStats(String userId, Map<String, int> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsKey = '${_userStatsKey}_$userId';
      await prefs.setString(statsKey, jsonEncode(stats));

      EnhancedLogger.info('Estatísticas do usuário salvas no cache',
          tag: 'INTEREST_CACHE', data: {'userId': userId, 'stats': stats});
    } catch (e) {
      EnhancedLogger.error('Erro ao salvar estatísticas no cache: $e',
          tag: 'INTEREST_CACHE');
    }
  }

  /// Obter estatísticas do usuário do cache
  Future<Map<String, int>?> getCachedUserStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsKey = '${_userStatsKey}_$userId';
      final statsString = prefs.getString(statsKey);

      if (statsString == null) {
        return null;
      }

      final stats = jsonDecode(statsString) as Map<String, dynamic>;
      return stats.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      EnhancedLogger.error('Erro ao carregar estatísticas do cache: $e',
          tag: 'INTEREST_CACHE');
      return null;
    }
  }

  /// Verificar se o cache está desatualizado
  Future<bool> isCacheStale(
      {Duration maxAge = const Duration(minutes: 5)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);

      if (lastSync == null) {
        return true; // Nunca sincronizou
      }

      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      final now = DateTime.now();

      return now.difference(lastSyncTime) > maxAge;
    } catch (e) {
      EnhancedLogger.error('Erro ao verificar idade do cache: $e',
          tag: 'INTEREST_CACHE');
      return true; // Em caso de erro, considerar desatualizado
    }
  }

  /// Limpar cache de notificações
  Future<void> clearNotificationsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      await prefs.remove(_lastSyncKey);

      EnhancedLogger.info('Cache de notificações limpo', tag: 'INTEREST_CACHE');
    } catch (e) {
      EnhancedLogger.error('Erro ao limpar cache de notificações: $e',
          tag: 'INTEREST_CACHE');
    }
  }

  /// Limpar cache de interesses enviados
  Future<void> clearSentInterestsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sentInterestsKey);

      EnhancedLogger.info('Cache de interesses enviados limpo',
          tag: 'INTEREST_CACHE');
    } catch (e) {
      EnhancedLogger.error('Erro ao limpar cache de interesses enviados: $e',
          tag: 'INTEREST_CACHE');
    }
  }

  /// Limpar todo o cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) =>
              key.startsWith(_notificationsKey) ||
              key.startsWith(_sentInterestsKey) ||
              key.startsWith(_lastSyncKey) ||
              key.startsWith(_userStatsKey))
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      EnhancedLogger.info('Todo o cache limpo',
          tag: 'INTEREST_CACHE', data: {'keysRemoved': keys.length});
    } catch (e) {
      EnhancedLogger.error('Erro ao limpar todo o cache: $e',
          tag: 'INTEREST_CACHE');
    }
  }

  /// Obter informações do cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);
      final notificationsString = prefs.getString(_notificationsKey);
      final sentInterestsString = prefs.getString(_sentInterestsKey);

      int notificationsCount = 0;
      int sentInterestsCount = 0;

      if (notificationsString != null) {
        final notifications = jsonDecode(notificationsString) as List;
        notificationsCount = notifications.length;
      }

      if (sentInterestsString != null) {
        final sentInterests = jsonDecode(sentInterestsString) as List;
        sentInterestsCount = sentInterests.length;
      }

      return {
        'lastSync': lastSync != null
            ? DateTime.fromMillisecondsSinceEpoch(lastSync).toIso8601String()
            : null,
        'notificationsCount': notificationsCount,
        'sentInterestsCount': sentInterestsCount,
        'isStale': await isCacheStale(),
      };
    } catch (e) {
      EnhancedLogger.error('Erro ao obter informações do cache: $e',
          tag: 'INTEREST_CACHE');
      return {};
    }
  }
}
