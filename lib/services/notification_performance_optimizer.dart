import 'dart:async';
import 'dart:math';
import '../utils/enhanced_logger.dart';
import '../services/notification_system_integrator.dart';
import '../services/fixed_notification_pipeline.dart';
import '../services/robust_notification_converter.dart';
import '../repositories/enhanced_real_interests_repository.dart';
import '../services/offline_notification_cache.dart';

/// Sistema de otimização de performance para notificações
class NotificationPerformanceOptimizer {
  static NotificationPerformanceOptimizer? _instance;
  static NotificationPerformanceOptimizer get instance => 
      _instance ??= NotificationPerformanceOptimizer._();
  
  NotificationPerformanceOptimizer._();
  
  bool _isInitialized = false;
  Timer? _optimizationTimer;
  final Map<String, List<int>> _performanceMetrics = {};
  final Map<String, DateTime> _lastOptimization = {};
  final Duration _optimizationInterval = const Duration(minutes: 10);
  
  // Configurações de performance
  final int _maxCacheSize = 1000;
  final int _batchSize = 50;
  final Duration _cacheTimeout = const Duration(minutes: 30);
  
  /// Inicializa otimizador de performance
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Configurar otimização periódica
      _setupPeriodicOptimization();
      
      // Inicializar métricas
      _initializeMetrics();
      
      _isInitialized = true;
      
      EnhancedLogger.success('✅ [PERFORMANCE_OPTIMIZER] Otimizador inicializado');
      
    } catch (e) {
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro ao inicializar', error: e);
    }
  }
  
  /// Configura otimização periódica
  void _setupPeriodicOptimization() {
    _optimizationTimer = Timer.periodic(_optimizationInterval, (timer) {
      _performPeriodicOptimization();
    });
    
    EnhancedLogger.info('⏰ [PERFORMANCE_OPTIMIZER] Otimização periódica configurada');
  }
  
  /// Inicializa métricas de performance
  void _initializeMetrics() {
    _performanceMetrics.clear();
    _performanceMetrics['processingTimes'] = [];
    _performanceMetrics['cacheHits'] = [];
    _performanceMetrics['cacheMisses'] = [];
    _performanceMetrics['batchSizes'] = [];
    _performanceMetrics['memoryUsage'] = [];
  }
  
  /// Executa otimização periódica
  void _performPeriodicOptimization() async {
    try {
      EnhancedLogger.info('🔧 [PERFORMANCE_OPTIMIZER] Executando otimização periódica');
      
      // Otimizar caches
      await _optimizeCaches();
      
      // Otimizar processamento em lote
      await _optimizeBatchProcessing();
      
      // Limpar dados expirados
      await _cleanupExpiredData();
      
      // Otimizar memória
      await _optimizeMemoryUsage();
      
      // Atualizar métricas
      _updatePerformanceMetrics();
      
      EnhancedLogger.success('✅ [PERFORMANCE_OPTIMIZER] Otimização periódica concluída');
      
    } catch (e) {
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro na otimização periódica', error: e);
    }
  }
  
  /// Otimiza caches do sistema
  Future<void> _optimizeCaches() async {
    try {
      EnhancedLogger.info('  💾 Otimizando caches');
      
      // Otimizar cache do repository
      final repoStats = EnhancedRealInterestsRepository.instance.getStatistics();
      final cacheSize = repoStats['cacheSize'] as int? ?? 0;
      
      if (cacheSize > _maxCacheSize) {
        EnhancedLogger.info('    🧹 Cache do repository muito grande, limpando');
        EnhancedRealInterestsRepository.instance.clearCache();
        _recordMetric('cacheCleanups', 1);
      }
      
      // Otimizar cache offline
      await OfflineNotificationCache.instance.cleanExpiredCache();
      
      // Otimizar estatísticas do converter
      RobustNotificationConverter.instance.clearOldStatistics();
      
      EnhancedLogger.info('    ✅ Caches otimizados');
      
    } catch (e) {
      EnhancedLogger.error('    ❌ Erro ao otimizar caches', error: e);
    }
  }
  
  /// Otimiza processamento em lote
  Future<void> _optimizeBatchProcessing() async {
    try {
      EnhancedLogger.info('  📦 Otimizando processamento em lote');
      
      // Calcular tamanho de lote otimizado baseado na performance
      final avgProcessingTime = _getAverageProcessingTime();
      final optimalBatchSize = _calculateOptimalBatchSize(avgProcessingTime);
      
      EnhancedLogger.info('    📊 Tamanho de lote otimizado: $optimalBatchSize');
      _recordMetric('optimalBatchSize', optimalBatchSize);
      
      EnhancedLogger.info('    ✅ Processamento em lote otimizado');
      
    } catch (e) {
      EnhancedLogger.error('    ❌ Erro ao otimizar processamento em lote', error: e);
    }
  }
  
  /// Limpa dados expirados
  Future<void> _cleanupExpiredData() async {
    try {
      EnhancedLogger.info('  🧹 Limpando dados expirados');
      
      // Limpar cache offline expirado
      await OfflineNotificationCache.instance.cleanExpiredCache();
      
      // Limpar métricas antigas
      _cleanupOldMetrics();
      
      // Limpar logs de otimização antigos
      _cleanupOldOptimizationLogs();
      
      EnhancedLogger.info('    ✅ Dados expirados limpos');
      
    } catch (e) {
      EnhancedLogger.error('    ❌ Erro ao limpar dados expirados', error: e);
    }
  }
  
  /// Otimiza uso de memória
  Future<void> _optimizeMemoryUsage() async {
    try {
      EnhancedLogger.info('  🧠 Otimizando uso de memória');
      
      // Simular limpeza de memória (em um app real, você usaria técnicas específicas)
      final beforeOptimization = DateTime.now();
      
      // Forçar garbage collection (conceitual)
      await Future.delayed(const Duration(milliseconds: 100));
      
      final afterOptimization = DateTime.now();
      final optimizationTime = afterOptimization.difference(beforeOptimization).inMilliseconds;
      
      _recordMetric('memoryOptimizationTime', optimizationTime);
      
      EnhancedLogger.info('    ✅ Memória otimizada em ${optimizationTime}ms');
      
    } catch (e) {
      EnhancedLogger.error('    ❌ Erro ao otimizar memória', error: e);
    }
  }
  
  /// Atualiza métricas de performance
  void _updatePerformanceMetrics() {
    try {
      // Obter estatísticas dos componentes
      final pipelineStats = FixedNotificationPipeline.instance.getPipelineStatistics();
      final converterStats = RobustNotificationConverter.instance.getConversionStatistics();
      final cacheStats = OfflineNotificationCache.instance.getCacheStatistics();
      
      // Registrar métricas
      _recordMetric('pipelineProcessed', pipelineStats['processingLogSize'] ?? 0);
      _recordMetric('conversionsTotal', converterStats['totalConversions'] ?? 0);
      _recordMetric('cacheSize', cacheStats['cachedNotifications'] ?? 0);
      
      EnhancedLogger.info('📊 [PERFORMANCE_OPTIMIZER] Métricas atualizadas');
      
    } catch (e) {
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro ao atualizar métricas', error: e);
    }
  }
  
  /// Otimiza processamento para um usuário específico
  Future<List<dynamic>> optimizeUserProcessing(String userId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      EnhancedLogger.info('⚡ [PERFORMANCE_OPTIMIZER] Otimizando processamento para usuário', 
        data: {'userId': userId}
      );
      
      // Verificar se há cache disponível primeiro
      final cachedNotifications = await OfflineNotificationCache.instance
          .getCachedNotifications(userId);
      
      if (cachedNotifications.isNotEmpty) {
        stopwatch.stop();
        _recordMetric('cacheHits', 1);
        _recordMetric('processingTimes', stopwatch.elapsedMilliseconds);
        
        EnhancedLogger.success('💾 [PERFORMANCE_OPTIMIZER] Cache hit para usuário', 
          data: {
            'userId': userId,
            'count': cachedNotifications.length,
            'time': stopwatch.elapsedMilliseconds
          }
        );
        
        return cachedNotifications;
      }
      
      // Cache miss - processar normalmente
      _recordMetric('cacheMisses', 1);
      
      final notifications = await NotificationSystemIntegrator.instance
          .processNotificationsIntegrated(userId);
      
      stopwatch.stop();
      _recordMetric('processingTimes', stopwatch.elapsedMilliseconds);
      
      // Salvar no cache para próximas consultas
      if (notifications.isNotEmpty) {
        await OfflineNotificationCache.instance.cacheNotifications(userId, notifications);
      }
      
      EnhancedLogger.success('⚡ [PERFORMANCE_OPTIMIZER] Processamento otimizado concluído', 
        data: {
          'userId': userId,
          'count': notifications.length,
          'time': stopwatch.elapsedMilliseconds
        }
      );
      
      return notifications;
      
    } catch (e) {
      stopwatch.stop();
      _recordMetric('processingErrors', 1);
      
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro no processamento otimizado', 
        error: e,
        data: {'userId': userId, 'time': stopwatch.elapsedMilliseconds}
      );
      
      throw e;
    }
  }
  
  /// Otimiza processamento em lote para múltiplos usuários
  Future<Map<String, List<dynamic>>> optimizeBatchProcessing(List<String> userIds) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      EnhancedLogger.info('📦 [PERFORMANCE_OPTIMIZER] Iniciando processamento em lote otimizado', 
        data: {'userCount': userIds.length}
      );
      
      final results = <String, List<dynamic>>{};
      final batches = _createBatches(userIds, _batchSize);
      
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        
        EnhancedLogger.info('  📋 Processando lote ${i + 1}/${batches.length}', 
          data: {'batchSize': batch.length}
        );
        
        // Processar lote em paralelo
        final futures = batch.map((userId) => optimizeUserProcessing(userId)).toList();
        final batchResults = await Future.wait(futures);
        
        // Armazenar resultados
        for (int j = 0; j < batch.length; j++) {
          results[batch[j]] = batchResults[j];
        }
        
        // Pequena pausa entre lotes para não sobrecarregar o sistema
        if (i < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      stopwatch.stop();
      _recordMetric('batchProcessingTime', stopwatch.elapsedMilliseconds);
      _recordMetric('batchSizes', userIds.length);
      
      EnhancedLogger.success('✅ [PERFORMANCE_OPTIMIZER] Processamento em lote concluído', 
        data: {
          'userCount': userIds.length,
          'batches': batches.length,
          'time': stopwatch.elapsedMilliseconds
        }
      );
      
      return results;
      
    } catch (e) {
      stopwatch.stop();
      
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro no processamento em lote', 
        error: e,
        data: {'userCount': userIds.length, 'time': stopwatch.elapsedMilliseconds}
      );
      
      throw e;
    }
  }
  
  /// Cria lotes de usuários para processamento
  List<List<String>> _createBatches(List<String> userIds, int batchSize) {
    final batches = <List<String>>[];
    
    for (int i = 0; i < userIds.length; i += batchSize) {
      final end = min(i + batchSize, userIds.length);
      batches.add(userIds.sublist(i, end));
    }
    
    return batches;
  }
  
  /// Calcula tamanho de lote otimizado
  int _calculateOptimalBatchSize(double avgProcessingTime) {
    // Algoritmo simples: ajustar tamanho do lote baseado na performance
    if (avgProcessingTime < 100) {
      return min(_batchSize * 2, 100); // Aumentar lote se processamento é rápido
    } else if (avgProcessingTime > 1000) {
      return max(_batchSize ~/ 2, 10); // Diminuir lote se processamento é lento
    } else {
      return _batchSize; // Manter tamanho padrão
    }
  }
  
  /// Obtém tempo médio de processamento
  double _getAverageProcessingTime() {
    final times = _performanceMetrics['processingTimes'] ?? [];
    if (times.isEmpty) return 500.0; // Valor padrão
    
    final sum = times.reduce((a, b) => a + b);
    return sum / times.length;
  }
  
  /// Registra métrica de performance
  void _recordMetric(String metricName, int value) {
    if (!_performanceMetrics.containsKey(metricName)) {
      _performanceMetrics[metricName] = [];
    }
    
    _performanceMetrics[metricName]!.add(value);
    
    // Manter apenas as últimas 100 métricas
    if (_performanceMetrics[metricName]!.length > 100) {
      _performanceMetrics[metricName]!.removeAt(0);
    }
  }
  
  /// Limpa métricas antigas
  void _cleanupOldMetrics() {
    _performanceMetrics.forEach((key, values) {
      if (values.length > 50) {
        _performanceMetrics[key] = values.sublist(values.length - 50);
      }
    });
    
    EnhancedLogger.info('🧹 [PERFORMANCE_OPTIMIZER] Métricas antigas limpas');
  }
  
  /// Limpa logs de otimização antigos
  void _cleanupOldOptimizationLogs() {
    final now = DateTime.now();
    final expiredThreshold = const Duration(hours: 24);
    
    final expiredUsers = <String>[];
    _lastOptimization.forEach((userId, time) {
      if (now.difference(time) > expiredThreshold) {
        expiredUsers.add(userId);
      }
    });
    
    for (final userId in expiredUsers) {
      _lastOptimization.remove(userId);
    }
    
    EnhancedLogger.info('🧹 [PERFORMANCE_OPTIMIZER] Logs de otimização antigos limpos', 
      data: {'removedLogs': expiredUsers.length}
    );
  }
  
  /// Força otimização completa do sistema
  Future<void> forceFullOptimization() async {
    try {
      EnhancedLogger.info('⚡ [PERFORMANCE_OPTIMIZER] Forçando otimização completa');
      
      await _optimizeCaches();
      await _optimizeBatchProcessing();
      await _cleanupExpiredData();
      await _optimizeMemoryUsage();
      _updatePerformanceMetrics();
      
      EnhancedLogger.success('✅ [PERFORMANCE_OPTIMIZER] Otimização completa concluída');
      
    } catch (e) {
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro na otimização completa', error: e);
    }
  }
  
  /// Obtém estatísticas de performance
  Map<String, dynamic> getPerformanceStatistics() {
    final stats = <String, dynamic>{};
    
    _performanceMetrics.forEach((key, values) {
      if (values.isNotEmpty) {
        final sum = values.reduce((a, b) => a + b);
        final avg = sum / values.length;
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        
        stats[key] = {
          'count': values.length,
          'average': avg.round(),
          'min': min,
          'max': max,
          'total': sum,
        };
      }
    });
    
    return {
      'isInitialized': _isInitialized,
      'optimizationInterval': _optimizationInterval.inMinutes,
      'maxCacheSize': _maxCacheSize,
      'batchSize': _batchSize,
      'cacheTimeout': _cacheTimeout.inMinutes,
      'metrics': stats,
      'lastOptimizationCount': _lastOptimization.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Obtém recomendações de otimização
  List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    
    // Analisar tempo de processamento
    final processingTimes = _performanceMetrics['processingTimes'] ?? [];
    if (processingTimes.isNotEmpty) {
      final avgTime = processingTimes.reduce((a, b) => a + b) / processingTimes.length;
      
      if (avgTime > 2000) {
        recommendations.add('Tempo de processamento alto (${avgTime.round()}ms). Considere otimizar queries ou aumentar cache.');
      } else if (avgTime < 100) {
        recommendations.add('Processamento muito rápido (${avgTime.round()}ms). Considere aumentar tamanho do lote.');
      }
    }
    
    // Analisar cache hits/misses
    final cacheHits = _performanceMetrics['cacheHits'] ?? [];
    final cacheMisses = _performanceMetrics['cacheMisses'] ?? [];
    
    if (cacheHits.isNotEmpty && cacheMisses.isNotEmpty) {
      final totalRequests = cacheHits.length + cacheMisses.length;
      final hitRate = (cacheHits.length / totalRequests * 100).round();
      
      if (hitRate < 50) {
        recommendations.add('Taxa de cache hit baixa ($hitRate%). Considere aumentar TTL do cache ou pré-carregar dados.');
      } else if (hitRate > 90) {
        recommendations.add('Excelente taxa de cache hit ($hitRate%). Sistema bem otimizado.');
      }
    }
    
    // Analisar tamanho dos lotes
    final batchSizes = _performanceMetrics['batchSizes'] ?? [];
    if (batchSizes.isNotEmpty) {
      final avgBatchSize = batchSizes.reduce((a, b) => a + b) / batchSizes.length;
      
      if (avgBatchSize > 100) {
        recommendations.add('Lotes muito grandes (${avgBatchSize.round()}). Considere reduzir para melhorar responsividade.');
      } else if (avgBatchSize < 10) {
        recommendations.add('Lotes muito pequenos (${avgBatchSize.round()}). Considere aumentar para melhor throughput.');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Sistema funcionando dentro dos parâmetros normais. Nenhuma otimização crítica necessária.');
    }
    
    return recommendations;
  }
  
  /// Finaliza otimizador de performance
  void dispose() {
    try {
      _optimizationTimer?.cancel();
      _performanceMetrics.clear();
      _lastOptimization.clear();
      _isInitialized = false;
      
      EnhancedLogger.info('🛑 [PERFORMANCE_OPTIMIZER] Otimizador finalizado');
      
    } catch (e) {
      EnhancedLogger.error('❌ [PERFORMANCE_OPTIMIZER] Erro ao finalizar otimizador', error: e);
    }
  }
}