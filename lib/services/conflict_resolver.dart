import 'dart:async';
import '../models/real_notification_model.dart';
import '../services/unified_notification_cache.dart';
import '../repositories/single_source_notification_repository.dart';
import '../utils/enhanced_logger.dart';

/// Estratégias de resolução de conflitos
enum ResolutionStrategy {
  useLatest,      // Usa dados mais recentes
  merge,          // Mescla dados diferentes
  forceRefresh,   // Força nova busca
  userChoice      // Deixa usuário escolher
}

/// Dados de resolução de conflito
class ConflictResolution {
  final List<RealNotificationModel> resolvedNotifications;
  final List<String> conflictSources;
  final ResolutionStrategy strategy;
  final DateTime resolvedAt;
  final String? errorMessage;

  ConflictResolution({
    required this.resolvedNotifications,
    required this.conflictSources,
    required this.strategy,
    required this.resolvedAt,
    this.errorMessage,
  });
}

/// Resolvedor de conflitos entre sistemas de notificação
class ConflictResolver {
  static final ConflictResolver _instance = ConflictResolver._internal();
  factory ConflictResolver() => _instance;
  ConflictResolver._internal();

  final UnifiedNotificationCache _cache = UnifiedNotificationCache();
  final SingleSourceNotificationRepository _repository = SingleSourceNotificationRepository();
  
  final Map<String, Timer> _conflictDetectionTimers = {};
  final Map<String, List<ConflictResolution>> _resolutionHistory = {};

  /// Detecta conflitos automaticamente
  Future<bool> detectConflict(String userId, List<RealNotificationModel> notifications) async {
    EnhancedLogger.log('🔍 [CONFLICT] Detectando conflitos para: $userId');
    
    try {
      // Obtém dados do cache
      final cachedData = _cache.getCachedNotifications(userId) ?? [];
      
      // Obtém dados frescos do repositório
      final freshData = await _repository.getNotifications(userId);
      
      // Compara as fontes
      final hasConflict = _compareDataSources(cachedData, freshData, notifications);
      
      if (hasConflict) {
        EnhancedLogger.log('⚠️ [CONFLICT] Conflito detectado para: $userId');
        await _handleDetectedConflict(userId, cachedData, freshData, notifications);
      } else {
        EnhancedLogger.log('✅ [CONFLICT] Nenhum conflito detectado para: $userId');
      }
      
      return hasConflict;
      
    } catch (e) {
      EnhancedLogger.log('❌ [CONFLICT] Erro na detecção de conflitos: $e');
      return false;
    }
  }

  /// Compara diferentes fontes de dados
  bool _compareDataSources(
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
  ) {
    // Verifica inconsistências entre as fontes
    final sources = [cached, fresh, current];
    
    // Se alguma fonte tem quantidade muito diferente
    final counts = sources.map((s) => s.length).toList();
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final minCount = counts.reduce((a, b) => a < b ? a : b);
    
    if (maxCount - minCount > 2) {
      EnhancedLogger.log('⚠️ [CONFLICT] Diferença significativa nas quantidades: $counts');
      return true;
    }
    
    // Verifica se os IDs principais são diferentes
    final allIds = <String>{};
    for (final source in sources) {
      allIds.addAll(source.map((n) => n.id));
    }
    
    // Se há muitos IDs únicos, pode haver conflito
    final totalNotifications = sources.fold<int>(0, (sum, s) => sum + s.length);
    if (allIds.length > totalNotifications * 0.7) {
      EnhancedLogger.log('⚠️ [CONFLICT] Muitos IDs únicos detectados');
      return true;
    }
    
    return false;
  }

  /// Processa conflito detectado
  Future<void> _handleDetectedConflict(
    String userId,
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
  ) async {
    EnhancedLogger.log('⚡ [CONFLICT] Processando conflito para: $userId');
    
    // Determina estratégia de resolução
    final strategy = _determineResolutionStrategy(cached, fresh, current);
    
    // Resolve conflito
    final resolution = await _resolveConflict(userId, cached, fresh, current, strategy);
    
    // Armazena histórico
    _storeResolutionHistory(userId, resolution);
    
    // Aplica resolução
    await _applyResolution(userId, resolution);
  }

  /// Determina estratégia de resolução
  ResolutionStrategy _determineResolutionStrategy(
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
  ) {
    // Se dados frescos são mais recentes e completos
    if (fresh.isNotEmpty && fresh.length >= cached.length && fresh.length >= current.length) {
      return ResolutionStrategy.useLatest;
    }
    
    // Se há dados em todas as fontes mas diferentes
    if (cached.isNotEmpty && fresh.isNotEmpty && current.isNotEmpty) {
      return ResolutionStrategy.merge;
    }
    
    // Se há inconsistências graves
    return ResolutionStrategy.forceRefresh;
  }

  /// Resolve conflito usando estratégia específica
  Future<ConflictResolution> _resolveConflict(
    String userId,
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
    ResolutionStrategy strategy,
  ) async {
    EnhancedLogger.log('🔧 [CONFLICT] Resolvendo com estratégia: $strategy');
    
    try {
      List<RealNotificationModel> resolved;
      
      switch (strategy) {
        case ResolutionStrategy.useLatest:
          resolved = _resolveUsingLatest(cached, fresh, current);
          break;
        case ResolutionStrategy.merge:
          resolved = _resolveByMerging(cached, fresh, current);
          break;
        case ResolutionStrategy.forceRefresh:
          resolved = await _resolveByForceRefresh(userId);
          break;
        case ResolutionStrategy.userChoice:
          resolved = _resolveByUserChoice(cached, fresh, current);
          break;
      }
      
      return ConflictResolution(
        resolvedNotifications: resolved,
        conflictSources: ['cached', 'fresh', 'current'],
        strategy: strategy,
        resolvedAt: DateTime.now(),
      );
      
    } catch (e) {
      EnhancedLogger.log('❌ [CONFLICT] Erro na resolução: $e');
      
      return ConflictResolution(
        resolvedNotifications: [],
        conflictSources: ['cached', 'fresh', 'current'],
        strategy: strategy,
        resolvedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Resolve usando dados mais recentes
  List<RealNotificationModel> _resolveUsingLatest(
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
  ) {
    EnhancedLogger.log('📅 [CONFLICT] Usando dados mais recentes');
    
    // Prioriza fresh > current > cached
    if (fresh.isNotEmpty) return fresh;
    if (current.isNotEmpty) return current;
    return cached;
  }

  /// Resolve mesclando dados
  List<RealNotificationModel> _resolveByMerging(
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
  ) {
    EnhancedLogger.log('🔀 [CONFLICT] Mesclando dados');
    
    final merged = <String, RealNotificationModel>{};
    
    // Adiciona todas as notificações, priorizando as mais recentes
    for (final source in [cached, current, fresh]) {
      for (final notification in source) {
        final existing = merged[notification.fromUserId];
        if (existing == null || notification.timestamp.isAfter(existing.timestamp)) {
          merged[notification.fromUserId] = notification;
        }
      }
    }
    
    final result = merged.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    EnhancedLogger.log('🔀 [CONFLICT] Mesclagem concluída: ${result.length} notificações');
    return result;
  }

  /// Resolve forçando nova busca
  Future<List<RealNotificationModel>> _resolveByForceRefresh(String userId) async {
    EnhancedLogger.log('🚀 [CONFLICT] Forçando nova busca');
    
       
 await _repository.forceRefresh(userId);
    return await _repository.getNotifications(userId);
  }

  /// Resolve por escolha do usuário (implementação futura)
  List<RealNotificationModel> _resolveByUserChoice(
    List<RealNotificationModel> cached,
    List<RealNotificationModel> fresh,
    List<RealNotificationModel> current,
  ) {
    EnhancedLogger.log('👤 [CONFLICT] Resolução por escolha do usuário (usando merge temporariamente)');
    
    // Por enquanto usa merge, pode ser expandido para UI de escolha
    return _resolveByMerging(cached, fresh, current);
  }

  /// Aplica resolução
  Future<void> _applyResolution(String userId, ConflictResolution resolution) async {
    EnhancedLogger.log('✅ [CONFLICT] Aplicando resolução para: $userId');
    
    try {
      // Atualiza cache com dados resolvidos
      _cache.updateCache(userId, resolution.resolvedNotifications);
      
      EnhancedLogger.log('✅ [CONFLICT] Resolução aplicada: ${resolution.resolvedNotifications.length} notificações');
      
    } catch (e) {
      EnhancedLogger.log('❌ [CONFLICT] Erro ao aplicar resolução: $e');
    }
  }

  /// Armazena histórico de resoluções
  void _storeResolutionHistory(String userId, ConflictResolution resolution) {
    _resolutionHistory.putIfAbsent(userId, () => []).add(resolution);
    
    // Mantém apenas os últimos 10 registros
    final history = _resolutionHistory[userId]!;
    if (history.length > 10) {
      history.removeRange(0, history.length - 10);
    }
    
    EnhancedLogger.log('📚 [CONFLICT] Histórico atualizado: ${history.length} resoluções');
  }

  /// Resolve inconsistências entre múltiplas fontes
  Future<List<RealNotificationModel>> resolveInconsistencies(
    List<RealNotificationModel> source1,
    List<RealNotificationModel> source2,
  ) async {
    EnhancedLogger.log('🔧 [CONFLICT] Resolvendo inconsistências entre 2 fontes');
    
    if (source1.isEmpty && source2.isEmpty) return [];
    if (source1.isEmpty) return source2;
    if (source2.isEmpty) return source1;
    
    // Mescla as duas fontes
    return _resolveByMerging(source1, source2, []);
  }

  /// Força consistência para um usuário
  Future<void> forceConsistency(String userId) async {
    EnhancedLogger.log('⚡ [CONFLICT] Forçando consistência para: $userId');
    
    try {
      // Invalida cache
      _cache.invalidateCache(userId);
      
      // Força nova busca
      await _repository.forceRefresh(userId);
      
      // Valida resultado
      final notifications = await _repository.getNotifications(userId);
      
      // Cria resolução de força
      final resolution = ConflictResolution(
        resolvedNotifications: notifications,
        conflictSources: ['force_refresh'],
        strategy: ResolutionStrategy.forceRefresh,
        resolvedAt: DateTime.now(),
      );
      
      _storeResolutionHistory(userId, resolution);
      
      EnhancedLogger.log('✅ [CONFLICT] Consistência forçada: ${notifications.length} notificações');
      
    } catch (e) {
      EnhancedLogger.log('❌ [CONFLICT] Erro ao forçar consistência: $e');
      rethrow;
    }
  }

  /// Configura detecção automática de conflitos
  void setupAutomaticConflictDetection(String userId) {
    EnhancedLogger.log('🤖 [CONFLICT] Configurando detecção automática para: $userId');
    
    _conflictDetectionTimers[userId]?.cancel();
    
    _conflictDetectionTimers[userId] = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _performAutomaticDetection(userId),
    );
  }

  /// Executa detecção automática
  Future<void> _performAutomaticDetection(String userId) async {
    try {
      final cachedData = _cache.getCachedNotifications(userId) ?? [];
      await detectConflict(userId, cachedData);
    } catch (e) {
      EnhancedLogger.log('❌ [CONFLICT] Erro na detecção automática: $e');
    }
  }

  /// Obtém histórico de resoluções
  List<ConflictResolution> getResolutionHistory(String userId) {
    return _resolutionHistory[userId] ?? [];
  }

  /// Obtém estatísticas de conflitos
  Map<String, dynamic> getConflictStats() {
    final totalResolutions = _resolutionHistory.values
        .fold<int>(0, (sum, list) => sum + list.length);
    
    final strategyCounts = <ResolutionStrategy, int>{};
    for (final history in _resolutionHistory.values) {
      for (final resolution in history) {
        strategyCounts[resolution.strategy] = 
            (strategyCounts[resolution.strategy] ?? 0) + 1;
      }
    }
    
    return {
      'totalUsers': _resolutionHistory.length,
      'totalResolutions': totalResolutions,
      'activeDetectors': _conflictDetectionTimers.length,
      'strategyCounts': strategyCounts.map((k, v) => MapEntry(k.toString(), v)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Valida consistência contínua
  Future<bool> validateConsistency(String userId) async {
    EnhancedLogger.log('🔍 [CONFLICT] Validando consistência para: $userId');
    
    try {
      // Obtém dados de múltiplas fontes
      final cachedData = _cache.getCachedNotifications(userId) ?? [];
      final freshData = await _repository.getNotifications(userId);
      
      // Verifica se são consistentes
      final isConsistent = !_compareDataSources(cachedData, freshData, []);
      
      if (!isConsistent) {
        EnhancedLogger.log('⚠️ [CONFLICT] Inconsistência detectada, resolvendo...');
        await forceConsistency(userId);
        return false;
      }
      
      EnhancedLogger.log('✅ [CONFLICT] Sistema consistente para: $userId');
      return true;
      
    } catch (e) {
      EnhancedLogger.log('❌ [CONFLICT] Erro na validação: $e');
      return false;
    }
  }

  /// Limpa recursos para um usuário
  void disposeUser(String userId) {
    EnhancedLogger.log('🧹 [CONFLICT] Limpando recursos para: $userId');
    
    _conflictDetectionTimers[userId]?.cancel();
    _conflictDetectionTimers.remove(userId);
    
    _resolutionHistory.remove(userId);
  }

  /// Limpa todos os recursos
  void dispose() {
    EnhancedLogger.log('🧹 [CONFLICT] Limpando todos os recursos');
    
    for (final timer in _conflictDetectionTimers.values) {
      timer.cancel();
    }
    _conflictDetectionTimers.clear();
    
    _resolutionHistory.clear();
  }
}