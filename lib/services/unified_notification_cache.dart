import 'dart:async';
import '../models/notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Cache unificado para notificações
class UnifiedNotificationCache {
  static final UnifiedNotificationCache _instance = UnifiedNotificationCache._internal();
  factory UnifiedNotificationCache() => _instance;
  UnifiedNotificationCache._internal();

  final Map<String, List<NotificationModel>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, StreamController<List<NotificationModel>>> _controllers = {};
  
  static const Duration _cacheTimeout = Duration(minutes: 15);

  /// Obtém notificações do cache
  List<NotificationModel>? getCachedNotifications(String userId) {
    if (!_cache.containsKey(userId)) {
      EnhancedLogger.log('📭 [CACHE] Nenhuma notificação em cache para: $userId');
      return null;
    }

    // Verifica se o cache expirou
    final timestamp = _cacheTimestamps[userId];
    if (timestamp != null && DateTime.now().difference(timestamp) > _cacheTimeout) {
      EnhancedLogger.log('⏰ [CACHE] Cache expirado para: $userId');
      _cache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }

    final notifications = _cache[userId]!;
    EnhancedLogger.log('✅ [CACHE] Retornando ${notifications.length} notificações do cache para: $userId');
    return notifications;
  }

  /// Atualiza cache
  void updateCache(String userId, List<NotificationModel> notifications) {
    final previousCount = _cache[userId]?.length ?? 0;
    
    _cache[userId] = notifications;
    _cacheTimestamps[userId] = DateTime.now();
    
    EnhancedLogger.log('🔄 [CACHE] Cache atualizado para $userId: $previousCount → ${notifications.length} notificações');
    
    // Notifica listeners
    _notifyListeners(userId, notifications);
  }

  /// Obtém stream de notificações
  Stream<List<NotificationModel>> getNotificationStream(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<List<NotificationModel>>.broadcast();
      
      // Emite dados do cache se disponível
      final cached = getCachedNotifications(userId);
      if (cached != null) {
        _controllers[userId]!.add(cached);
      }
    }
    
    return _controllers[userId]!.stream;
  }

  /// Notifica listeners sobre mudanças
  void _notifyListeners(String userId, List<NotificationModel> notifications) {
    if (_controllers.containsKey(userId)) {
      EnhancedLogger.log('📡 [CACHE] Notificando listeners para $userId: ${notifications.length} notificações');
      _controllers[userId]!.add(notifications);
    }
  }

  /// Invalida cache para um usuário
  void invalidateCache(String userId) {
    EnhancedLogger.log('🗑️ [CACHE] Invalidando cache para: $userId');
    
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalida todo o cache
  void invalidateAll() {
    EnhancedLogger.log('🗑️ [CACHE] Invalidando todo o cache');
    
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Verifica se há cache válido
  bool hasValidCache(String userId) {
    if (!_cache.containsKey(userId)) return false;
    
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) <= _cacheTimeout;
  }

  /// Força atualização do cache
  void forceUpdate(String userId, List<NotificationModel> notifications) {
    EnhancedLogger.log('🚀 [CACHE] Forçando atualização do cache para: $userId');
    
    _cache[userId] = notifications;
    _cacheTimestamps[userId] = DateTime.now();
    _notifyListeners(userId, notifications);
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getStats() {
    final totalNotifications = _cache.values
        .map((list) => list.length)
        .fold(0, (sum, count) => sum + count);
    
    return {
      'totalUsers': _cache.length,
      'totalNotifications': totalNotifications,
      'cacheHits': _cache.length,
      'activeStreams': _controllers.length,
      'lastUpdate': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  /// Limpa recursos para um usuário
  void dispose(String userId) {
    EnhancedLogger.log('🧹 [CACHE] Limpando recursos para: $userId');
    
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
    
    _controllers[userId]?.close();
    _controllers.remove(userId);
  }

  /// Limpa todos os recursos
  void disposeAll() {
    EnhancedLogger.log('🧹 [CACHE] Limpando todos os recursos do cache');
    
    _cache.clear();
    _cacheTimestamps.clear();
    
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// Debug: mostra estado atual do cache
  void debugPrintCacheState() {
    EnhancedLogger.log('🔍 [CACHE] Estado atual do cache:');
    
    for (final entry in _cache.entries) {
      final userId = entry.key;
      final notifications = entry.value;
      final timestamp = _cacheTimestamps[userId];
      
      EnhancedLogger.log('  👤 $userId: ${notifications.length} notificações, '
          'timestamp: ${timestamp?.toIso8601String() ?? 'null'}');
    }
  }
}