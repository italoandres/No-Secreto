import 'dart:async';
import '../models/real_notification_model.dart';
import '../repositories/single_source_notification_repository.dart';
import '../services/unified_notification_cache.dart';
import '../utils/enhanced_logger.dart';

/// Gerenciador inteligente de streams com invalidação automática
class IntelligentStreamManager {
  static final IntelligentStreamManager _instance = IntelligentStreamManager._internal();
  factory IntelligentStreamManager() => _instance;
  IntelligentStreamManager._internal();

  final SingleSourceNotificationRepository _repository = SingleSourceNotificationRepository();
  final UnifiedNotificationCache _cache = UnifiedNotificationCache();
  
  final Map<String, StreamController<List<RealNotificationModel>>> _controllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _invalidationTimers = {};
  final Map<String, DateTime> _lastActivity = {};

  /// Obtém stream inteligente com invalidação automática
  Stream<List<RealNotificationModel>> getIntelligentStream(String userId) {
    EnhancedLogger.log('🧠 [INTELLIGENT] Obtendo stream inteligente para: $userId');
    
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<List<RealNotificationModel>>.broadcast();
      _setupIntelligentStream(userId);
    }
    
    _updateActivity(userId);
    return _controllers[userId]!.stream;
  }

  /// Configura stream inteligente
  void _setupIntelligentStream(String userId) {
    EnhancedLogger.log('⚙️ [INTELLIGENT] Configurando stream inteligente para: $userId');
    
    // Cancela subscription anterior
    _subscriptions[userId]?.cancel();
    
    // Envia dados do cache imediatamente se disponíveis
    _sendCachedDataIfAvailable(userId);
    
    // Configura subscription do repositório
    _subscriptions[userId] = _repository
        .watchNotifications(userId)
        .listen(
          (notifications) => _handleStreamUpdate(userId, notifications),
          onError: (error) => _handleStreamError(userId, error),
        );
    
    // Configura invalidação inteligente
    _setupIntelligentInvalidation(userId);
  }

  /// Envia dados do cache se disponíveis
  void _sendCachedDataIfAvailable(String userId) {
    final cachedData = _cache.getCachedNotifications(userId);
    if (cachedData != null) {
      _controllers[userId]?.add(cachedData);
      EnhancedLogger.log('⚡ [INTELLIGENT] Dados do cache enviados: ${cachedData.length} notificações');
    }
  }

  /// Processa atualização do stream
  void _handleStreamUpdate(String userId, List<RealNotificationModel> notifications) {
    EnhancedLogger.log('📨 [INTELLIGENT] Atualização recebida: ${notifications.length} notificações');
    
    // Verifica se houve mudanças significativas
    final cachedData = _cache.getCachedNotifications(userId) ?? [];
    
    if (_hasSignificantChanges(cachedData, notifications)) {
      EnhancedLogger.log('🔄 [INTELLIGENT] Mudanças significativas detectadas');
      
      // Atualiza cache
      _cache.updateCache(userId, notifications);
      
      // Envia para stream
      _controllers[userId]?.add(notifications);
      
      // Reseta timer de invalidação
      _resetInvalidationTimer(userId);
    } else {
      EnhancedLogger.log('📊 [INTELLIGENT] Nenhuma mudança significativa detectada');
    }
    
    _updateActivity(userId);
  }

  /// Processa erro do stream
  void _handleStreamError(String userId, dynamic error) {
    EnhancedLogger.log('❌ [INTELLIGENT] Erro no stream: $error');
    
    _controllers[userId]?.addError(error);
    
    // Tenta recuperação automática
    _attemptAutoRecovery(userId);
  }

  /// Verifica se há mudanças significativas
  bool _hasSignificantChanges(
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
  ) {
    // Diferentes quantidades
    if (cached.length != fresh.length) return true;
    
    // Verifica mudanças nos IDs ou contagens
    for (int i = 0; i < cached.length; i++) {
      if (cached[i].id != fresh[i].id ||
          cached[i].count != fresh[i].count ||
          cached[i].timestamp != fresh[i].timestamp) {
        return true;
      }
    }
    
    return false;
  }

  /// Configura invalidação inteligente
  void _setupIntelligentInvalidation(String userId) {
    _resetInvalidationTimer(userId);
  }

  /// Reseta timer de invalidação
  void _resetInvalidationTimer(String userId) {
    _invalidationTimers[userId]?.cancel();
    
    _invalidationTimers[userId] = Timer(const Duration(minutes: 10), () {
      _performIntelligentInvalidation(userId);
    });
  }

  /// Executa invalidação inteligente
  Future<void> _performIntelligentInvalidation(String userId) async {
    EnhancedLogger.log('🧠 [INTELLIGENT] Executando invalidação inteligente para: $userId');
    
    try {
      // Verifica se o usuário ainda está ativo
      if (!_isUserActive(userId)) {
        EnhancedLogger.log('😴 [INTELLIGENT] Usuário inativo, pulando invalidação');
        return;
      }
      
      // Força refresh do repositório
      await _repository.forceRefresh(userId);
      
      EnhancedLogger.log('✅ [INTELLIGENT] Invalidação inteligente concluída');
      
    } catch (e) {
      EnhancedLogger.log('❌ [INTELLIGENT] Erro na invalidação inteligente: $e');
    }
  }

  /// Verifica se usuário está ativo
  bool _isUserActive(String userId) {
    final lastActivity = _lastActivity[userId];
    if (lastActivity == null) return false;
    
    return DateTime.now().difference(lastActivity).inMinutes < 30;
  }

  /// Atualiza atividade do usuário
  void _updateActivity(String userId) {
    _lastActivity[userId] = DateTime.now();
  }

  /// Tenta recuperação automática
  Future<void> _attemptAutoRecovery(String userId) async {
    EnhancedLogger.log('🔧 [INTELLIGENT] Tentando recuperação automática para: $userId');
    
    try {
      // Aguarda um pouco antes de tentar
      await Future.delayed(const Duration(seconds: 2));
      
      // Reconfigura stream
      _setupIntelligentStream(userId);
      
      EnhancedLogger.log('✅ [INTELLIGENT] Recuperação automática concluída');
      
    } catch (e) {
      EnhancedLogger.log('❌ [INTELLIGENT] Falha na recuperação automática: $e');
    }
  }

  /// Força invalidação imediata
  Future<void> forceInvalidation(String userId) async {
    EnhancedLogger.log('🚀 [INTELLIGENT] Forçando invalidação para: $userId');
    
    await _repository.forceRefresh(userId);
    _resetInvalidationTimer(userId);
  }

  /// Pausa stream para um usuário
  void pauseStream(String userId) {
    EnhancedLogger.log('⏸️ [INTELLIGENT] Pausando stream para: $userId');
    
    _subscriptions[userId]?.pause();
    _invalidationTimers[userId]?.cancel();
  }

  /// Resume stream para um usuário
  void resumeStream(String userId) {
    EnhancedLogger.log('▶️ [INTELLIGENT] Resumindo stream para: $userId');
    
    _subscriptions[userId]?.resume();
    _resetInvalidationTimer(userId);
    _updateActivity(userId);
  }

  /// Obtém estatísticas do gerenciador
  Map<String, dynamic> getManagerStats() {
    return {
      'activeStreams': _controllers.length,
      'activeSubscriptions': _subscriptions.length,
      'activeTimers': _invalidationTimers.length,
      'activeUsers': _lastActivity.length,
      'repository': _repository.getRepositoryStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa recursos para um usuário
  void disposeUser(String userId) {
    EnhancedLogger.log('🧹 [INTELLIGENT] Limpando recursos para: $userId');
    
    _subscriptions[userId]?.cancel();
    _subscriptions.remove(userId);
    
    _controllers[userId]?.close();
    _controllers.remove(userId);
    
    _invalidationTimers[userId]?.cancel();
    _invalidationTimers.remove(userId);
    
    _lastActivity.remove(userId);
    
    _repository.disposeUser(userId);
  }

  /// Limpa todos os recursos
  void dispose() {
    EnhancedLogger.log('🧹 [INTELLIGENT] Limpando todos os recursos');
    
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    
    for (final timer in _invalidationTimers.values) {
      timer.cancel();
    }
    _invalidationTimers.clear();
    
    _lastActivity.clear();
    
    _repository.dispose();
  }
}