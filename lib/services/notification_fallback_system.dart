import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/enhanced_logger.dart';
import '../models/real_notification_model.dart';
import '../services/javascript_error_handler.dart';
import '../services/error_recovery_system.dart';

/// Sistema de fallback para notificações quando APIs falham
class NotificationFallbackSystem {
  static NotificationFallbackSystem? _instance;
  static NotificationFallbackSystem get instance =>
      _instance ??= NotificationFallbackSystem._();

  NotificationFallbackSystem._();

  bool _isInitialized = false;
  SharedPreferences? _prefs;
  final Map<String, List<RealNotification>> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(hours: 24);

  // Configurações de fallback
  static const String _cacheKeyPrefix = 'notification_fallback_';
  static const String _timestampKeyPrefix = 'notification_timestamp_';
  static const String _systemStateKey = 'fallback_system_state';

  /// Inicializa sistema de fallback
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCachedData();
      await _restoreSystemState();

      _isInitialized = true;

      EnhancedLogger.success(
          '✅ [FALLBACK_SYSTEM] Sistema de fallback inicializado');
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao inicializar sistema',
          error: e);
    }
  }

  /// Salva notificações no cache de fallback
  Future<void> saveNotificationsToFallback(
      String userId, List<RealNotification> notifications) async {
    if (!_isInitialized) await initialize();

    try {
      // Salvar na memória
      _memoryCache[userId] = List.from(notifications);
      _cacheTimestamps[userId] = DateTime.now();

      // Salvar no storage persistente
      if (_prefs != null) {
        final notificationsJson = notifications.map((n) => n.toJson()).toList();
        await _prefs!.setString(
            '$_cacheKeyPrefix$userId', jsonEncode(notificationsJson));
        await _prefs!.setString(
            '$_timestampKeyPrefix$userId', DateTime.now().toIso8601String());
      }

      EnhancedLogger.info(
          '💾 [FALLBACK_SYSTEM] Notificações salvas para fallback',
          data: {
            'userId': userId,
            'notificationsCount': notifications.length,
            'timestamp': DateTime.now().toIso8601String()
          });
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao salvar notificações',
          error: e, data: {'userId': userId});
    }
  }

  /// Obtém notificações do cache de fallback
  Future<List<RealNotification>> getFallbackNotifications(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      // Tentar obter da memória primeiro
      if (_memoryCache.containsKey(userId)) {
        final timestamp = _cacheTimestamps[userId];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          EnhancedLogger.info(
              '📦 [FALLBACK_SYSTEM] Notificações obtidas da memória',
              data: {'userId': userId, 'count': _memoryCache[userId]!.length});
          return List.from(_memoryCache[userId]!);
        }
      }

      // Tentar obter do storage persistente
      if (_prefs != null) {
        final notificationsData = _prefs!.getString('$_cacheKeyPrefix$userId');
        final timestampData = _prefs!.getString('$_timestampKeyPrefix$userId');

        if (notificationsData != null && timestampData != null) {
          final timestamp = DateTime.parse(timestampData);

          if (DateTime.now().difference(timestamp) < _cacheExpiry) {
            final notificationsJson = jsonDecode(notificationsData) as List;
            final notifications = notificationsJson
                .map((json) => RealNotification.fromJson(json))
                .toList();

            // Atualizar cache de memória
            _memoryCache[userId] = notifications;
            _cacheTimestamps[userId] = timestamp;

            EnhancedLogger.info(
                '💿 [FALLBACK_SYSTEM] Notificações obtidas do storage',
                data: {'userId': userId, 'count': notifications.length});

            return notifications;
          }
        }
      }

      EnhancedLogger.warning(
          '⚠️ [FALLBACK_SYSTEM] Nenhuma notificação de fallback encontrada',
          data: {'userId': userId});

      return [];
    } catch (e) {
      EnhancedLogger.error(
          '❌ [FALLBACK_SYSTEM] Erro ao obter notificações de fallback',
          error: e,
          data: {'userId': userId});
      return [];
    }
  }

  /// Verifica se há notificações de fallback disponíveis
  bool hasFallbackNotifications(String userId) {
    try {
      // Verificar memória
      if (_memoryCache.containsKey(userId)) {
        final timestamp = _cacheTimestamps[userId];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          return _memoryCache[userId]!.isNotEmpty;
        }
      }

      // Verificar storage
      if (_prefs != null) {
        final notificationsData = _prefs!.getString('$_cacheKeyPrefix$userId');
        final timestampData = _prefs!.getString('$_timestampKeyPrefix$userId');

        if (notificationsData != null && timestampData != null) {
          final timestamp = DateTime.parse(timestampData);
          return DateTime.now().difference(timestamp) < _cacheExpiry;
        }
      }

      return false;
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao verificar fallback',
          error: e, data: {'userId': userId});
      return false;
    }
  }

  /// Limpa cache expirado
  Future<void> cleanExpiredCache() async {
    if (!_isInitialized) await initialize();

    try {
      final now = DateTime.now();
      final expiredUsers = <String>[];

      // Verificar cache de memória
      _cacheTimestamps.forEach((userId, timestamp) {
        if (now.difference(timestamp) >= _cacheExpiry) {
          expiredUsers.add(userId);
        }
      });

      // Remover da memória
      for (final userId in expiredUsers) {
        _memoryCache.remove(userId);
        _cacheTimestamps.remove(userId);
      }

      // Limpar storage persistente
      if (_prefs != null) {
        final keys = _prefs!.getKeys();
        final keysToRemove = <String>[];

        for (final key in keys) {
          if (key.startsWith(_timestampKeyPrefix)) {
            final timestampData = _prefs!.getString(key);
            if (timestampData != null) {
              final timestamp = DateTime.parse(timestampData);
              if (now.difference(timestamp) >= _cacheExpiry) {
                final userId = key.substring(_timestampKeyPrefix.length);
                keysToRemove.add(key);
                keysToRemove.add('$_cacheKeyPrefix$userId');
              }
            }
          }
        }

        for (final key in keysToRemove) {
          await _prefs!.remove(key);
        }
      }

      EnhancedLogger.info('🧹 [FALLBACK_SYSTEM] Cache expirado limpo', data: {
        'expiredUsers': expiredUsers.length,
        'removedKeys': expiredUsers.length * 2
      });
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao limpar cache',
          error: e);
    }
  }

  /// Salva estado do sistema
  Future<void> saveSystemState(Map<String, dynamic> state) async {
    if (!_isInitialized) await initialize();

    try {
      if (_prefs != null) {
        await _prefs!.setString(_systemStateKey, jsonEncode(state));

        EnhancedLogger.info('💾 [FALLBACK_SYSTEM] Estado do sistema salvo',
            data: {'stateKeys': state.keys.length});
      }
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao salvar estado',
          error: e);
    }
  }

  /// Restaura estado do sistema
  Future<Map<String, dynamic>> restoreSystemState() async {
    if (!_isInitialized) await initialize();

    try {
      if (_prefs != null) {
        final stateData = _prefs!.getString(_systemStateKey);
        if (stateData != null) {
          final state = jsonDecode(stateData) as Map<String, dynamic>;

          EnhancedLogger.info(
              '📥 [FALLBACK_SYSTEM] Estado do sistema restaurado',
              data: {'stateKeys': state.keys.length});

          return state;
        }
      }

      return {};
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao restaurar estado',
          error: e);
      return {};
    }
  }

  /// Carrega dados em cache
  Future<void> _loadCachedData() async {
    try {
      if (_prefs == null) return;

      final keys = _prefs!.getKeys();
      int loadedUsers = 0;

      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          final userId = key.substring(_cacheKeyPrefix.length);
          final timestampKey = '$_timestampKeyPrefix$userId';

          final notificationsData = _prefs!.getString(key);
          final timestampData = _prefs!.getString(timestampKey);

          if (notificationsData != null && timestampData != null) {
            final timestamp = DateTime.parse(timestampData);

            if (DateTime.now().difference(timestamp) < _cacheExpiry) {
              final notificationsJson = jsonDecode(notificationsData) as List;
              final notifications = notificationsJson
                  .map((json) => RealNotification.fromJson(json))
                  .toList();

              _memoryCache[userId] = notifications;
              _cacheTimestamps[userId] = timestamp;
              loadedUsers++;
            }
          }
        }
      }

      EnhancedLogger.info('📂 [FALLBACK_SYSTEM] Dados em cache carregados',
          data: {'loadedUsers': loadedUsers});
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao carregar cache',
          error: e);
    }
  }

  /// Restaura estado do sistema na inicialização
  Future<void> _restoreSystemState() async {
    try {
      final state = await restoreSystemState();

      if (state.isNotEmpty) {
        // Aplicar configurações restauradas se necessário
        EnhancedLogger.info('🔄 [FALLBACK_SYSTEM] Estado do sistema aplicado');
      }
    } catch (e) {
      EnhancedLogger.error(
          '❌ [FALLBACK_SYSTEM] Erro ao restaurar estado inicial',
          error: e);
    }
  }

  /// Obtém estatísticas do sistema de fallback
  Map<String, dynamic> getFallbackStatistics() {
    return {
      'isInitialized': _isInitialized,
      'memoryCacheSize': _memoryCache.length,
      'totalCachedNotifications': _memoryCache.values
          .map((list) => list.length)
          .fold(0, (a, b) => a + b),
      'oldestCacheEntry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toIso8601String()
          : null,
      'newestCacheEntry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .toIso8601String()
          : null,
      'cacheExpiryHours': _cacheExpiry.inHours,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Força sincronização de dados
  Future<void> forceSyncData() async {
    try {
      EnhancedLogger.info(
          '🔄 [FALLBACK_SYSTEM] Forçando sincronização de dados');

      // Limpar cache expirado
      await cleanExpiredCache();

      // Salvar estado atual
      await saveSystemState({
        'lastSync': DateTime.now().toIso8601String(),
        'cacheSize': _memoryCache.length,
      });

      EnhancedLogger.success(
          '✅ [FALLBACK_SYSTEM] Sincronização forçada concluída');
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro na sincronização forçada',
          error: e);
    }
  }

  /// Limpa todo o cache
  Future<void> clearAllCache() async {
    try {
      // Limpar memória
      _memoryCache.clear();
      _cacheTimestamps.clear();

      // Limpar storage
      if (_prefs != null) {
        final keys = _prefs!.getKeys();
        final keysToRemove = keys
            .where((key) =>
                key.startsWith(_cacheKeyPrefix) ||
                key.startsWith(_timestampKeyPrefix))
            .toList();

        for (final key in keysToRemove) {
          await _prefs!.remove(key);
        }
      }

      EnhancedLogger.info('🗑️ [FALLBACK_SYSTEM] Todo o cache foi limpo');
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao limpar cache',
          error: e);
    }
  }

  /// Finaliza sistema de fallback
  void dispose() {
    try {
      _memoryCache.clear();
      _cacheTimestamps.clear();
      _isInitialized = false;

      EnhancedLogger.info('🛑 [FALLBACK_SYSTEM] Sistema finalizado');
    } catch (e) {
      EnhancedLogger.error('❌ [FALLBACK_SYSTEM] Erro ao finalizar sistema',
          error: e);
    }
  }
}
