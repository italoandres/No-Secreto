import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accepted_match_model.dart';
import '../models/chat_message_model.dart';
import '../utils/enhanced_logger.dart';

/// Serviço de cache local para matches e mensagens
class MatchCacheService {
  static const String _matchesKey = 'cached_matches';
  static const String _messagesKeyPrefix = 'cached_messages_';
  static const String _lastUpdateKey = 'cache_last_update';
  static const Duration _cacheExpiration = Duration(hours: 1);
  static const int _maxMessagesPerChat = 50;
  static const int _maxCachedChats = 20;

  static SharedPreferences? _prefs;

  /// Inicializar o serviço de cache
  static Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      EnhancedLogger.info('Cache service initialized', tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error('Failed to initialize cache service: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Verificar se o cache está válido
  static bool _isCacheValid(String key) {
    try {
      final lastUpdate = _prefs?.getString('${key}_timestamp');
      if (lastUpdate == null) return false;

      final updateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();

      return now.difference(updateTime) < _cacheExpiration;
    } catch (e) {
      EnhancedLogger.warning('Error checking cache validity: $e',
          tag: 'MATCH_CACHE');
      return false;
    }
  }

  /// Salvar timestamp do cache
  static Future<void> _saveCacheTimestamp(String key) async {
    try {
      await _prefs?.setString(
          '${key}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      EnhancedLogger.warning('Error saving cache timestamp: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Cache de matches aceitos
  static Future<void> cacheAcceptedMatches(
      List<AcceptedMatchModel> matches) async {
    try {
      await initialize();

      final matchesJson = matches.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(matchesJson);

      await _prefs?.setString(_matchesKey, jsonString);
      await _saveCacheTimestamp(_matchesKey);

      EnhancedLogger.info('Cached ${matches.length} matches',
          tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error('Error caching matches: $e', tag: 'MATCH_CACHE');
    }
  }

  /// Obter matches aceitos do cache
  static Future<List<AcceptedMatchModel>?> getCachedAcceptedMatches() async {
    try {
      await initialize();

      if (!_isCacheValid(_matchesKey)) {
        EnhancedLogger.debug('Matches cache expired', tag: 'MATCH_CACHE');
        return null;
      }

      final jsonString = _prefs?.getString(_matchesKey);
      if (jsonString == null) return null;

      final List<dynamic> matchesJson = jsonDecode(jsonString);
      final matches =
          matchesJson.map((json) => AcceptedMatchModel.fromJson(json)).toList();

      EnhancedLogger.info('Retrieved ${matches.length} matches from cache',
          tag: 'MATCH_CACHE');
      return matches;
    } catch (e) {
      EnhancedLogger.error('Error retrieving cached matches: $e',
          tag: 'MATCH_CACHE');
      return null;
    }
  }

  /// Cache de mensagens de um chat específico
  static Future<void> cacheChatMessages(
      String chatId, List<ChatMessageModel> messages) async {
    try {
      await initialize();

      // Limitar número de mensagens em cache
      final messagesToCache = messages.take(_maxMessagesPerChat).toList();

      final messagesJson = messagesToCache.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(messagesJson);

      final key = '$_messagesKeyPrefix$chatId';
      await _prefs?.setString(key, jsonString);
      await _saveCacheTimestamp(key);

      // Gerenciar limite de chats em cache
      await _manageCacheSize();

      EnhancedLogger.info(
          'Cached ${messagesToCache.length} messages for chat $chatId',
          tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error('Error caching messages for chat $chatId: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Obter mensagens de um chat do cache
  static Future<List<ChatMessageModel>?> getCachedChatMessages(
      String chatId) async {
    try {
      await initialize();

      final key = '$_messagesKeyPrefix$chatId';
      if (!_isCacheValid(key)) {
        EnhancedLogger.debug('Messages cache expired for chat $chatId',
            tag: 'MATCH_CACHE');
        return null;
      }

      final jsonString = _prefs?.getString(key);
      if (jsonString == null) return null;

      final List<dynamic> messagesJson = jsonDecode(jsonString);
      final messages =
          messagesJson.map((json) => ChatMessageModel.fromJson(json)).toList();

      EnhancedLogger.info(
          'Retrieved ${messages.length} messages from cache for chat $chatId',
          tag: 'MATCH_CACHE');
      return messages;
    } catch (e) {
      EnhancedLogger.error(
          'Error retrieving cached messages for chat $chatId: $e',
          tag: 'MATCH_CACHE');
      return null;
    }
  }

  /// Gerenciar tamanho do cache removendo chats mais antigos
  static Future<void> _manageCacheSize() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final messageKeys =
          keys.where((key) => key.startsWith(_messagesKeyPrefix)).toList();

      if (messageKeys.length <= _maxCachedChats) return;

      // Ordenar por timestamp (mais antigos primeiro)
      messageKeys.sort((a, b) {
        final timestampA = _prefs?.getString('${a}_timestamp') ?? '';
        final timestampB = _prefs?.getString('${b}_timestamp') ?? '';
        return timestampA.compareTo(timestampB);
      });

      // Remover chats mais antigos
      final keysToRemove =
          messageKeys.take(messageKeys.length - _maxCachedChats);
      for (final key in keysToRemove) {
        await _prefs?.remove(key);
        await _prefs?.remove('${key}_timestamp');
      }

      EnhancedLogger.info('Removed ${keysToRemove.length} old cached chats',
          tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.warning('Error managing cache size: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Invalidar cache de matches
  static Future<void> invalidateMatchesCache() async {
    try {
      await initialize();
      await _prefs?.remove(_matchesKey);
      await _prefs?.remove('${_matchesKey}_timestamp');

      EnhancedLogger.info('Matches cache invalidated', tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error('Error invalidating matches cache: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Invalidar cache de mensagens de um chat
  static Future<void> invalidateChatMessagesCache(String chatId) async {
    try {
      await initialize();
      final key = '$_messagesKeyPrefix$chatId';
      await _prefs?.remove(key);
      await _prefs?.remove('${key}_timestamp');

      EnhancedLogger.info('Messages cache invalidated for chat $chatId',
          tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error(
          'Error invalidating messages cache for chat $chatId: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Limpar todo o cache
  static Future<void> clearAllCache() async {
    try {
      await initialize();
      final keys = _prefs?.getKeys() ?? <String>{};

      final cacheKeys = keys
          .where((key) =>
              key.startsWith(_matchesKey) ||
              key.startsWith(_messagesKeyPrefix) ||
              key.contains('_timestamp'))
          .toList();

      for (final key in cacheKeys) {
        await _prefs?.remove(key);
      }

      EnhancedLogger.info('All cache cleared (${cacheKeys.length} keys)',
          tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error('Error clearing cache: $e', tag: 'MATCH_CACHE');
    }
  }

  /// Obter estatísticas do cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      await initialize();
      final keys = _prefs?.getKeys() ?? <String>{};

      final matchCacheExists = keys.contains(_matchesKey);
      final messageKeys =
          keys.where((key) => key.startsWith(_messagesKeyPrefix)).toList();
      final timestampKeys =
          keys.where((key) => key.contains('_timestamp')).toList();

      // Calcular tamanho aproximado do cache
      int totalSize = 0;
      for (final key in keys) {
        if (key.startsWith(_matchesKey) || key.startsWith(_messagesKeyPrefix)) {
          final value = _prefs?.getString(key) ?? '';
          totalSize += value.length;
        }
      }

      // Verificar validade dos caches
      int validCaches = 0;
      int expiredCaches = 0;

      for (final key in [...messageKeys, if (matchCacheExists) _matchesKey]) {
        if (_isCacheValid(key)) {
          validCaches++;
        } else {
          expiredCaches++;
        }
      }

      return {
        'matchesCached': matchCacheExists,
        'cachedChatsCount': messageKeys.length,
        'totalCacheKeys': keys.length,
        'approximateSizeBytes': totalSize,
        'validCaches': validCaches,
        'expiredCaches': expiredCaches,
        'maxCachedChats': _maxCachedChats,
        'maxMessagesPerChat': _maxMessagesPerChat,
        'cacheExpirationHours': _cacheExpiration.inHours,
      };
    } catch (e) {
      EnhancedLogger.error('Error getting cache stats: $e', tag: 'MATCH_CACHE');
      return {
        'error': e.toString(),
        'matchesCached': false,
        'cachedChatsCount': 0,
        'totalCacheKeys': 0,
        'approximateSizeBytes': 0,
      };
    }
  }

  /// Verificar se um chat específico está em cache
  static Future<bool> isChatCached(String chatId) async {
    try {
      await initialize();
      final key = '$_messagesKeyPrefix$chatId';
      return _prefs?.containsKey(key) ?? false;
    } catch (e) {
      EnhancedLogger.warning('Error checking if chat is cached: $e',
          tag: 'MATCH_CACHE');
      return false;
    }
  }

  /// Pré-carregar cache para chats mais usados
  static Future<void> preloadFrequentChats(List<String> chatIds) async {
    try {
      EnhancedLogger.info(
          'Preloading cache for ${chatIds.length} frequent chats',
          tag: 'MATCH_CACHE');

      // Esta função seria chamada com dados dos chats mais acessados
      // A implementação real dependeria de ter acesso aos repositórios
      for (final chatId in chatIds.take(5)) {
        // Limitar a 5 chats mais frequentes
        final isCached = await isChatCached(chatId);
        if (!isCached) {
          EnhancedLogger.debug('Chat $chatId not in cache, would preload',
              tag: 'MATCH_CACHE');
          // TODO: Implementar preload real quando integrado com repositórios
        }
      }
    } catch (e) {
      EnhancedLogger.error('Error preloading frequent chats: $e',
          tag: 'MATCH_CACHE');
    }
  }

  /// Otimizar cache removendo dados desnecessários
  static Future<void> optimizeCache() async {
    try {
      EnhancedLogger.info('Starting cache optimization', tag: 'MATCH_CACHE');

      // Remover caches expirados
      final keys = _prefs?.getKeys() ?? <String>{};
      final cacheKeys = keys
          .where((key) =>
              key.startsWith(_matchesKey) || key.startsWith(_messagesKeyPrefix))
          .toList();

      int removedCount = 0;
      for (final key in cacheKeys) {
        if (!_isCacheValid(key)) {
          await _prefs?.remove(key);
          await _prefs?.remove('${key}_timestamp');
          removedCount++;
        }
      }

      // Gerenciar tamanho do cache
      await _manageCacheSize();

      EnhancedLogger.info(
          'Cache optimization completed, removed $removedCount expired entries',
          tag: 'MATCH_CACHE');
    } catch (e) {
      EnhancedLogger.error('Error optimizing cache: $e', tag: 'MATCH_CACHE');
    }
  }
}
