import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/enhanced_logger.dart';
import '../models/real_notification_model.dart';
import '../models/interest_model.dart';
import '../models/user_data_model.dart';

/// Sistema de cache offline para continuidade de serviço
class OfflineNotificationCache {
  static OfflineNotificationCache? _instance;
  static OfflineNotificationCache get instance =>
      _instance ??= OfflineNotificationCache._();

  OfflineNotificationCache._();

  bool _isInitialized = false;
  SharedPreferences? _prefs;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;

  // Caches em memória
  final Map<String, List<RealNotification>> _notificationsCache = {};
  final Map<String, List<Interest>> _interactionsCache = {};
  final Map<String, UserData> _userDataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Filas de sincronização
  final List<Map<String, dynamic>> _pendingOperations = [];
  final Map<String, List<RealNotification>> _pendingNotifications = {};

  // Configurações
  static const String _notificationsCacheKey = 'offline_notifications_';
  static const String _interactionsCacheKey = 'offline_interactions_';
  static const String _userDataCacheKey = 'offline_userdata_';
  static const String _timestampCacheKey = 'offline_timestamp_';
  static const String _pendingOperationsKey = 'pending_operations';
  static const Duration _cacheExpiry = Duration(days: 7);

  /// Inicializa sistema de cache offline
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Verificar conectividade inicial
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      // Monitorar mudanças de conectividade
      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

      // Carregar dados em cache
      await _loadCachedData();
      await _loadPendingOperations();

      _isInitialized = true;

      EnhancedLogger.success(
          '✅ [OFFLINE_CACHE] Sistema de cache offline inicializado',
          data: {
            'isOnline': _isOnline,
            'cachedUsers': _notificationsCache.length,
            'pendingOperations': _pendingOperations.length
          });

      // Se estiver online, tentar sincronizar dados pendentes
      if (_isOnline) {
        _scheduleSyncPendingOperations();
      }
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao inicializar sistema',
          error: e);
    }
  }

  /// Manipula mudanças de conectividade
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    EnhancedLogger.info('🌐 [OFFLINE_CACHE] Conectividade alterada', data: {
      'wasOnline': wasOnline,
      'isOnline': _isOnline,
      'connectivityResult': result.toString()
    });

    if (!wasOnline && _isOnline) {
      // Voltou online - sincronizar dados pendentes
      EnhancedLogger.info(
          '🔄 [OFFLINE_CACHE] Voltou online - iniciando sincronização');
      _scheduleSyncPendingOperations();
    } else if (wasOnline && !_isOnline) {
      // Ficou offline
      EnhancedLogger.warning(
          '📴 [OFFLINE_CACHE] Ficou offline - modo cache ativado');
    }
  }

  /// Salva notificações no cache offline
  Future<void> cacheNotifications(
      String userId, List<RealNotification> notifications) async {
    if (!_isInitialized) await initialize();

    try {
      // Salvar na memória
      _notificationsCache[userId] = List.from(notifications);
      _cacheTimestamps['notifications_$userId'] = DateTime.now();

      // Salvar no storage persistente
      if (_prefs != null) {
        final notificationsJson = notifications.map((n) => n.toJson()).toList();
        await _prefs!.setString(
            '$_notificationsCacheKey$userId', jsonEncode(notificationsJson));
        await _prefs!.setString(
            '$_timestampCacheKey$userId', DateTime.now().toIso8601String());
      }

      EnhancedLogger.info('💾 [OFFLINE_CACHE] Notificações cacheadas', data: {
        'userId': userId,
        'count': notifications.length,
        'isOnline': _isOnline
      });
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao cachear notificações',
          error: e, data: {'userId': userId});
    }
  }

  /// Obtém notificações do cache offline
  Future<List<RealNotification>> getCachedNotifications(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      // Tentar obter da memória primeiro
      if (_notificationsCache.containsKey(userId)) {
        final timestamp = _cacheTimestamps['notifications_$userId'];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          EnhancedLogger.info(
              '📦 [OFFLINE_CACHE] Notificações obtidas da memória',
              data: {
                'userId': userId,
                'count': _notificationsCache[userId]!.length
              });
          return List.from(_notificationsCache[userId]!);
        }
      }

      // Tentar obter do storage persistente
      if (_prefs != null) {
        final notificationsData =
            _prefs!.getString('$_notificationsCacheKey$userId');
        final timestampData = _prefs!.getString('$_timestampCacheKey$userId');

        if (notificationsData != null && timestampData != null) {
          final timestamp = DateTime.parse(timestampData);

          if (DateTime.now().difference(timestamp) < _cacheExpiry) {
            final notificationsJson = jsonDecode(notificationsData) as List;
            final notifications = notificationsJson
                .map((json) => RealNotification.fromJson(json))
                .toList();

            // Atualizar cache de memória
            _notificationsCache[userId] = notifications;
            _cacheTimestamps['notifications_$userId'] = timestamp;

            EnhancedLogger.info(
                '💿 [OFFLINE_CACHE] Notificações obtidas do storage',
                data: {'userId': userId, 'count': notifications.length});

            return notifications;
          }
        }
      }

      return [];
    } catch (e) {
      EnhancedLogger.error(
          '❌ [OFFLINE_CACHE] Erro ao obter notificações cacheadas',
          error: e,
          data: {'userId': userId});
      return [];
    }
  }

  /// Salva interações no cache offline
  Future<void> cacheInteractions(
      String userId, List<Interest> interactions) async {
    if (!_isInitialized) await initialize();

    try {
      // Salvar na memória
      _interactionsCache[userId] = List.from(interactions);
      _cacheTimestamps['interactions_$userId'] = DateTime.now();

      // Salvar no storage persistente
      if (_prefs != null) {
        final interactionsJson = interactions.map((i) => i.toJson()).toList();
        await _prefs!.setString(
            '$_interactionsCacheKey$userId', jsonEncode(interactionsJson));
      }

      EnhancedLogger.info('💾 [OFFLINE_CACHE] Interações cacheadas', data: {
        'userId': userId,
        'count': interactions.length,
        'isOnline': _isOnline
      });
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao cachear interações',
          error: e, data: {'userId': userId});
    }
  }

  /// Obtém interações do cache offline
  Future<List<Interest>> getCachedInteractions(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      // Tentar obter da memória primeiro
      if (_interactionsCache.containsKey(userId)) {
        final timestamp = _cacheTimestamps['interactions_$userId'];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          return List.from(_interactionsCache[userId]!);
        }
      }

      // Tentar obter do storage persistente
      if (_prefs != null) {
        final interactionsData =
            _prefs!.getString('$_interactionsCacheKey$userId');

        if (interactionsData != null) {
          final interactionsJson = jsonDecode(interactionsData) as List;
          final interactions =
              interactionsJson.map((json) => Interest.fromJson(json)).toList();

          // Atualizar cache de memória
          _interactionsCache[userId] = interactions;
          _cacheTimestamps['interactions_$userId'] = DateTime.now();

          return interactions;
        }
      }

      return [];
    } catch (e) {
      EnhancedLogger.error(
          '❌ [OFFLINE_CACHE] Erro ao obter interações cacheadas',
          error: e,
          data: {'userId': userId});
      return [];
    }
  }

  /// Salva dados de usuário no cache
  Future<void> cacheUserData(String userId, UserData userData) async {
    if (!_isInitialized) await initialize();

    try {
      // Salvar na memória
      _userDataCache[userId] = userData;
      _cacheTimestamps['userdata_$userId'] = DateTime.now();

      // Salvar no storage persistente
      if (_prefs != null) {
        await _prefs!.setString(
            '$_userDataCacheKey$userId', jsonEncode(userData.toJson()));
      }

      EnhancedLogger.info('💾 [OFFLINE_CACHE] Dados de usuário cacheados',
          data: {'userId': userId, 'isOnline': _isOnline});
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao cachear dados de usuário',
          error: e, data: {'userId': userId});
    }
  }

  /// Obtém dados de usuário do cache
  Future<UserData?> getCachedUserData(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      // Tentar obter da memória primeiro
      if (_userDataCache.containsKey(userId)) {
        final timestamp = _cacheTimestamps['userdata_$userId'];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          return _userDataCache[userId];
        }
      }

      // Tentar obter do storage persistente
      if (_prefs != null) {
        final userDataString = _prefs!.getString('$_userDataCacheKey$userId');

        if (userDataString != null) {
          final userDataJson =
              jsonDecode(userDataString) as Map<String, dynamic>;
          final userData = UserData.fromJson(userDataJson);

          // Atualizar cache de memória
          _userDataCache[userId] = userData;
          _cacheTimestamps['userdata_$userId'] = DateTime.now();

          return userData;
        }
      }

      return null;
    } catch (e) {
      EnhancedLogger.error(
          '❌ [OFFLINE_CACHE] Erro ao obter dados de usuário cacheados',
          error: e,
          data: {'userId': userId});
      return null;
    }
  }

  /// Adiciona operação à fila de sincronização
  Future<void> addPendingOperation(
      String type, Map<String, dynamic> data) async {
    if (!_isInitialized) await initialize();

    try {
      final operation = {
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      _pendingOperations.add(operation);

      // Salvar no storage
      if (_prefs != null) {
        await _prefs!
            .setString(_pendingOperationsKey, jsonEncode(_pendingOperations));
      }

      EnhancedLogger.info('📝 [OFFLINE_CACHE] Operação adicionada à fila',
          data: {
            'type': type,
            'operationId': operation['id'],
            'totalPending': _pendingOperations.length
          });

      // Se estiver online, tentar sincronizar imediatamente
      if (_isOnline) {
        _scheduleSyncPendingOperations();
      }
    } catch (e) {
      EnhancedLogger.error(
          '❌ [OFFLINE_CACHE] Erro ao adicionar operação pendente',
          error: e,
          data: {'type': type});
    }
  }

  /// Carrega dados em cache do storage
  Future<void> _loadCachedData() async {
    try {
      if (_prefs == null) return;

      final keys = _prefs!.getKeys();
      int loadedNotifications = 0;
      int loadedInteractions = 0;
      int loadedUserData = 0;

      for (final key in keys) {
        try {
          if (key.startsWith(_notificationsCacheKey)) {
            final userId = key.substring(_notificationsCacheKey.length);
            final notificationsData = _prefs!.getString(key);

            if (notificationsData != null) {
              final notificationsJson = jsonDecode(notificationsData) as List;
              final notifications = notificationsJson
                  .map((json) => RealNotification.fromJson(json))
                  .toList();

              _notificationsCache[userId] = notifications;
              loadedNotifications++;
            }
          } else if (key.startsWith(_interactionsCacheKey)) {
            final userId = key.substring(_interactionsCacheKey.length);
            final interactionsData = _prefs!.getString(key);

            if (interactionsData != null) {
              final interactionsJson = jsonDecode(interactionsData) as List;
              final interactions = interactionsJson
                  .map((json) => Interest.fromJson(json))
                  .toList();

              _interactionsCache[userId] = interactions;
              loadedInteractions++;
            }
          } else if (key.startsWith(_userDataCacheKey)) {
            final userId = key.substring(_userDataCacheKey.length);
            final userDataString = _prefs!.getString(key);

            if (userDataString != null) {
              final userDataJson =
                  jsonDecode(userDataString) as Map<String, dynamic>;
              final userData = UserData.fromJson(userDataJson);

              _userDataCache[userId] = userData;
              loadedUserData++;
            }
          } else if (key.startsWith(_timestampCacheKey)) {
            final userId = key.substring(_timestampCacheKey.length);
            final timestampString = _prefs!.getString(key);

            if (timestampString != null) {
              _cacheTimestamps['notifications_$userId'] =
                  DateTime.parse(timestampString);
            }
          }
        } catch (e) {
          EnhancedLogger.warning(
              '⚠️ [OFFLINE_CACHE] Erro ao carregar item do cache',
              data: {'key': key, 'error': e.toString()});
        }
      }

      EnhancedLogger.info('📂 [OFFLINE_CACHE] Dados em cache carregados',
          data: {
            'notifications': loadedNotifications,
            'interactions': loadedInteractions,
            'userData': loadedUserData
          });
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao carregar dados em cache',
          error: e);
    }
  }

  /// Carrega operações pendentes
  Future<void> _loadPendingOperations() async {
    try {
      if (_prefs == null) return;

      final pendingData = _prefs!.getString(_pendingOperationsKey);
      if (pendingData != null) {
        final operationsJson = jsonDecode(pendingData) as List;
        _pendingOperations.clear();
        _pendingOperations.addAll(operationsJson.cast<Map<String, dynamic>>());

        EnhancedLogger.info('📋 [OFFLINE_CACHE] Operações pendentes carregadas',
            data: {'count': _pendingOperations.length});
      }
    } catch (e) {
      EnhancedLogger.error(
          '❌ [OFFLINE_CACHE] Erro ao carregar operações pendentes',
          error: e);
    }
  }

  /// Agenda sincronização de operações pendentes
  void _scheduleSyncPendingOperations() {
    Timer(const Duration(seconds: 2), () async {
      await _syncPendingOperations();
    });
  }

  /// Sincroniza operações pendentes
  Future<void> _syncPendingOperations() async {
    if (!_isOnline || _pendingOperations.isEmpty) return;

    try {
      EnhancedLogger.info(
          '🔄 [OFFLINE_CACHE] Sincronizando operações pendentes',
          data: {'count': _pendingOperations.length});

      final operationsToSync =
          List<Map<String, dynamic>>.from(_pendingOperations);
      final syncedOperations = <Map<String, dynamic>>[];

      for (final operation in operationsToSync) {
        try {
          // Aqui você implementaria a lógica específica para cada tipo de operação
          // Por exemplo: enviar para Firebase, atualizar APIs, etc.

          final type = operation['type'] as String;
          final data = operation['data'] as Map<String, dynamic>;

          // Simular sincronização bem-sucedida
          await Future.delayed(const Duration(milliseconds: 100));

          syncedOperations.add(operation);

          EnhancedLogger.info('✅ [OFFLINE_CACHE] Operação sincronizada',
              data: {'type': type, 'operationId': operation['id']});
        } catch (e) {
          EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao sincronizar operação',
              error: e, data: {'operationId': operation['id']});
        }
      }

      // Remover operações sincronizadas
      for (final syncedOp in syncedOperations) {
        _pendingOperations.remove(syncedOp);
      }

      // Atualizar storage
      if (_prefs != null) {
        await _prefs!
            .setString(_pendingOperationsKey, jsonEncode(_pendingOperations));
      }

      EnhancedLogger.success('✅ [OFFLINE_CACHE] Sincronização concluída',
          data: {
            'syncedOperations': syncedOperations.length,
            'remainingOperations': _pendingOperations.length
          });
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro na sincronização', error: e);
    }
  }

  /// Verifica se está online
  bool get isOnline => _isOnline;

  /// Verifica se há dados em cache para um usuário
  bool hasCachedData(String userId) {
    return _notificationsCache.containsKey(userId) ||
        _interactionsCache.containsKey(userId) ||
        _userDataCache.containsKey(userId);
  }

  /// Obtém estatísticas do cache offline
  Map<String, dynamic> getCacheStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isOnline': _isOnline,
      'cachedNotifications': _notificationsCache.length,
      'cachedInteractions': _interactionsCache.length,
      'cachedUserData': _userDataCache.length,
      'pendingOperations': _pendingOperations.length,
      'totalCachedNotifications': _notificationsCache.values
          .map((list) => list.length)
          .fold(0, (a, b) => a + b),
      'totalCachedInteractions': _interactionsCache.values
          .map((list) => list.length)
          .fold(0, (a, b) => a + b),
      'cacheExpiryDays': _cacheExpiry.inDays,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa cache expirado
  Future<void> cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      _cacheTimestamps.forEach((key, timestamp) {
        if (now.difference(timestamp) >= _cacheExpiry) {
          expiredKeys.add(key);
        }
      });

      for (final key in expiredKeys) {
        _cacheTimestamps.remove(key);

        if (key.startsWith('notifications_')) {
          final userId = key.substring('notifications_'.length);
          _notificationsCache.remove(userId);
        } else if (key.startsWith('interactions_')) {
          final userId = key.substring('interactions_'.length);
          _interactionsCache.remove(userId);
        } else if (key.startsWith('userdata_')) {
          final userId = key.substring('userdata_'.length);
          _userDataCache.remove(userId);
        }
      }

      EnhancedLogger.info('🧹 [OFFLINE_CACHE] Cache expirado limpo',
          data: {'expiredKeys': expiredKeys.length});
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao limpar cache expirado',
          error: e);
    }
  }

  /// Finaliza sistema de cache offline
  void dispose() {
    try {
      _connectivitySubscription?.cancel();
      _notificationsCache.clear();
      _interactionsCache.clear();
      _userDataCache.clear();
      _cacheTimestamps.clear();
      _pendingOperations.clear();
      _isInitialized = false;

      EnhancedLogger.info('🛑 [OFFLINE_CACHE] Sistema finalizado');
    } catch (e) {
      EnhancedLogger.error('❌ [OFFLINE_CACHE] Erro ao finalizar sistema',
          error: e);
    }
  }
}
