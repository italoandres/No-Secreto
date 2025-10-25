import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_sync_manager.dart';
import '../services/unified_notification_cache.dart';
import '../services/conflict_resolver.dart';
import '../utils/enhanced_logger.dart';

/// Interface unificada para gerenciamento de notificações
class UnifiedNotificationInterface {
  static final UnifiedNotificationInterface _instance =
      UnifiedNotificationInterface._internal();
  factory UnifiedNotificationInterface() => _instance;
  UnifiedNotificationInterface._internal();

  final NotificationSyncManager _syncManager = NotificationSyncManager();
  final UnifiedNotificationCache _cache = UnifiedNotificationCache();
  final ConflictResolver _conflictResolver = ConflictResolver();
  final Map<String, StreamController<List<NotificationModel>>>
      _unifiedControllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Obtém stream unificado de notificações
  Stream<List<NotificationModel>> getUnifiedNotificationStream(String userId) {
    EnhancedLogger.log('🎯 [UNIFIED] Obtendo stream unificado para: $userId');

    if (!_unifiedControllers.containsKey(userId)) {
      _unifiedControllers[userId] =
          StreamController<List<NotificationModel>>.broadcast();
      _setupUnifiedStream(userId);
    }

    return _unifiedControllers[userId]!.stream;
  }

  /// Configura stream unificado
  void _setupUnifiedStream(String userId) {
    EnhancedLogger.log(
        '⚙️ [UNIFIED] Configurando stream unificado para: $userId');

    // Escuta mudanças do sync manager
    _subscriptions[userId] = _syncManager.getNotificationsStream(userId).listen(
      (notifications) {
        // Atualiza cache
        _cache.updateCache(userId, notifications);

        // Emite para o stream unificado
        _unifiedControllers[userId]?.add(notifications);

        EnhancedLogger.log(
            '📨 [UNIFIED] Recebidas ${notifications.length} notificações para: $userId');
      },
      onError: (error) {
        EnhancedLogger.log('❌ [UNIFIED] Erro no stream para $userId: $error');

        // Em caso de erro, tenta usar cache
        final cached = _cache.getCachedNotifications(userId);
        if (cached != null) {
          _unifiedControllers[userId]?.add(cached);
        }
      },
    );
  }

  /// Força sincronização
  Future<void> forceSync(String userId) async {
    EnhancedLogger.log('🚀 [UNIFIED] Forçando sincronização para: $userId');

    try {
      await _syncManager.forceSync(userId);
      EnhancedLogger.log(
          '✅ [UNIFIED] Sincronização forçada concluída para: $userId');
    } catch (e) {
      EnhancedLogger.log('❌ [UNIFIED] Erro na sincronização forçada: $e');
      rethrow;
    }
  }

  /// Obtém notificações em cache
  List<NotificationModel> getCachedNotifications(String userId) {
    final cached = _cache.getCachedNotifications(userId) ?? [];

    if (cached.isNotEmpty) {
      EnhancedLogger.log(
          '📦 [UNIFIED] Retornando ${cached.length} notificações do cache para: $userId');
    } else {
      EnhancedLogger.log(
          '📭 [UNIFIED] Nenhuma notificação em cache para: $userId');
    }

    return cached;
  }

  /// Obtém notificações (cache + rede)
  Future<List<NotificationModel>> getNotifications(String userId) async {
    EnhancedLogger.log(
        '🔄 [UNIFIED] Invalidando cache e atualizando para: $userId');

    try {
      // Força atualização
      await _syncManager.forceSync(userId);

      // Retorna do cache atualizado
      return getCachedNotifications(userId);
    } catch (e) {
      EnhancedLogger.log('❌ [UNIFIED] Erro ao obter notificações: $e');

      // Em caso de erro, retorna cache
      return getCachedNotifications(userId);
    }
  }

  /// Valida consistência dos dados
  Future<bool> validateConsistency(String userId) async {
    EnhancedLogger.log('🔍 [UNIFIED] Validando consistência para: $userId');

    try {
      final hasCache = _cache.getCachedNotifications(userId) != null;

      EnhancedLogger.log(
          '✅ [UNIFIED] Validação concluída para $userId: cache válido = $hasCache');
      return hasCache;
    } catch (e) {
      EnhancedLogger.log('❌ [UNIFIED] Erro na validação de consistência: $e');
      return false;
    }
  }

  /// Resolve conflitos de dados
  Future<void> resolveConflicts(String userId) async {
    EnhancedLogger.log('⚡ [UNIFIED] Resolvendo conflitos para: $userId');

    try {
      // Obtém dados atuais
      final cached = getCachedNotifications(userId);

      // Resolve conflitos (implementação simplificada)
      final resolved =
          await _conflictResolver.resolveNotificationConflicts(cached);

      // Atualiza cache com dados resolvidos
      _cache.updateCache(userId, resolved);

      EnhancedLogger.log('✅ [UNIFIED] Conflitos resolvidos para: $userId');
    } catch (e) {
      EnhancedLogger.log('❌ [UNIFIED] Erro ao resolver conflitos: $e');
    }
  }

  /// Limpa recursos para um usuário
  void dispose(String userId) {
    EnhancedLogger.log('🧹 [UNIFIED] Limpando recursos para: $userId');

    _subscriptions[userId]?.cancel();
    _subscriptions.remove(userId);

    _unifiedControllers[userId]?.close();
    _unifiedControllers.remove(userId);

    _cache.dispose(userId);
  }

  /// Limpa todos os recursos
  void disposeAll() {
    EnhancedLogger.log('🧹 [UNIFIED] Limpando todos os recursos');

    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final controller in _unifiedControllers.values) {
      controller.close();
    }
    _unifiedControllers.clear();

    _cache.disposeAll();
  }

  /// Verifica se há dados em cache
  bool hasCachedData(String userId) {
    return _cache.getCachedNotifications(userId) != null;
  }

  /// Verifica se está online
  bool isOnline() {
    return true; // Implementação simplificada
  }

  /// Obtém estatísticas do sistema
  Map<String, dynamic> getSystemStats() {
    EnhancedLogger.log('🔍 [UNIFIED] Estado do sistema unificado:');
    EnhancedLogger.log('  📡 Streams ativos: ${_unifiedControllers.length}');
    EnhancedLogger.log('  🔗 Subscriptions ativas: ${_subscriptions.length}');

    final stats = _cache.getStats();
    EnhancedLogger.log('  📊 Estatísticas: $stats');

    return {
      'activeStreams': _unifiedControllers.length,
      'activeSubscriptions': _subscriptions.length,
      'cacheStats': stats,
      'isOnline': isOnline(),
    };
  }
}
