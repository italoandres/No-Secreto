import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';
import 'match_cache_service.dart';

/// Configurações de otimização de performance
class PerformanceConfig {
  final bool enableCache;
  final bool enablePagination;
  final bool enableIndexHints;
  final int queryTimeout;
  final int maxRetries;

  const PerformanceConfig({
    this.enableCache = true,
    this.enablePagination = true,
    this.enableIndexHints = true,
    this.queryTimeout = 10000, // 10 segundos
    this.maxRetries = 3,
  });

  /// Configuração para performance máxima
  static const PerformanceConfig maxPerformance = PerformanceConfig(
    enableCache: true,
    enablePagination: true,
    enableIndexHints: true,
    queryTimeout: 5000,
    maxRetries: 2,
  );

  /// Configuração para dados em tempo real
  static const PerformanceConfig realTime = PerformanceConfig(
    enableCache: false,
    enablePagination: false,
    enableIndexHints: true,
    queryTimeout: 15000,
    maxRetries: 5,
  );
}

/// Métricas de performance de queries
class QueryMetrics {
  final String queryType;
  final Duration executionTime;
  final int documentsRead;
  final bool cacheHit;
  final DateTime timestamp;
  final String? error;

  QueryMetrics({
    required this.queryType,
    required this.executionTime,
    required this.documentsRead,
    required this.cacheHit,
    DateTime? timestamp,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'queryType': queryType,
      'executionTimeMs': executionTime.inMilliseconds,
      'documentsRead': documentsRead,
      'cacheHit': cacheHit,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }
}

/// Serviço de otimização de performance para queries de matches
class MatchPerformanceOptimizer {
  static final List<QueryMetrics> _metrics = [];
  static const int _maxMetrics = 100;

  /// Executar query otimizada para matches aceitos
  static Future<QuerySnapshot> optimizedMatchesQuery(
    String userId, {
    PerformanceConfig config = const PerformanceConfig(),
  }) async {
    final stopwatch = Stopwatch()..start();
    bool cacheHit = false;
    String? error;

    try {
      EnhancedLogger.debug('Executing optimized matches query for user $userId', 
        tag: 'MATCH_PERFORMANCE');

      // Tentar cache primeiro se habilitado
      if (config.enableCache) {
        final cachedMatches = await MatchCacheService.getCachedAcceptedMatches();
        if (cachedMatches != null) {
          cacheHit = true;
          stopwatch.stop();
          
          _recordMetrics(QueryMetrics(
            queryType: 'matches_query',
            executionTime: stopwatch.elapsed,
            documentsRead: 0, // Cache hit
            cacheHit: true,
          ));

          EnhancedLogger.info('Matches query served from cache (${cachedMatches.length} matches)', 
            tag: 'MATCH_PERFORMANCE');
          
          // Retornar snapshot simulado do cache
          // Nota: Em implementação real, seria necessário converter para QuerySnapshot
          throw UnimplementedError('Cache to QuerySnapshot conversion not implemented');
        }
      }

      // Query otimizada no Firebase
      Query query = FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted');

      // Adicionar hints de índice se habilitado
      if (config.enableIndexHints) {
        // Ordenar por timestamp para usar índice composto
        query = query.orderBy('timestamp', descending: true);
      }

      // Limitar resultados para performance
      query = query.limit(50);

      // Executar query com timeout
      final snapshot = await query
          .get()
          .timeout(Duration(milliseconds: config.queryTimeout));

      stopwatch.stop();

      // Registrar métricas
      _recordMetrics(QueryMetrics(
        queryType: 'matches_query',
        executionTime: stopwatch.elapsed,
        documentsRead: snapshot.docs.length,
        cacheHit: false,
      ));

      EnhancedLogger.info('Matches query completed in ${stopwatch.elapsedMilliseconds}ms (${snapshot.docs.length} docs)', 
        tag: 'MATCH_PERFORMANCE');

      return snapshot;
    } catch (e) {
      stopwatch.stop();
      error = e.toString();

      _recordMetrics(QueryMetrics(
        queryType: 'matches_query',
        executionTime: stopwatch.elapsed,
        documentsRead: 0,
        cacheHit: cacheHit,
        error: error,
      ));

      EnhancedLogger.error('Matches query failed after ${stopwatch.elapsedMilliseconds}ms: $e', 
        tag: 'MATCH_PERFORMANCE');
      rethrow;
    }
  }

  /// Executar query otimizada para mensagens de chat
  static Future<QuerySnapshot> optimizedMessagesQuery(
    String chatId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    PerformanceConfig config = const PerformanceConfig(),
  }) async {
    final stopwatch = Stopwatch()..start();
    String? error;

    try {
      EnhancedLogger.debug('Executing optimized messages query for chat $chatId', 
        tag: 'MATCH_PERFORMANCE');

      Query query = FirebaseFirestore.instance
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId);

      // Adicionar ordenação para usar índice
      if (config.enableIndexHints) {
        query = query.orderBy('timestamp', descending: true);
      }

      // Adicionar paginação se especificado
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      // Executar query com timeout
      final snapshot = await query
          .get()
          .timeout(Duration(milliseconds: config.queryTimeout));

      stopwatch.stop();

      // Registrar métricas
      _recordMetrics(QueryMetrics(
        queryType: 'messages_query',
        executionTime: stopwatch.elapsed,
        documentsRead: snapshot.docs.length,
        cacheHit: false,
      ));

      EnhancedLogger.info('Messages query completed in ${stopwatch.elapsedMilliseconds}ms (${snapshot.docs.length} docs)', 
        tag: 'MATCH_PERFORMANCE');

      return snapshot;
    } catch (e) {
      stopwatch.stop();
      error = e.toString();

      _recordMetrics(QueryMetrics(
        queryType: 'messages_query',
        executionTime: stopwatch.elapsed,
        documentsRead: 0,
        cacheHit: false,
        error: error,
      ));

      EnhancedLogger.error('Messages query failed after ${stopwatch.elapsedMilliseconds}ms: $e', 
        tag: 'MATCH_PERFORMANCE');
      rethrow;
    }
  }

  /// Registrar métricas de performance
  static void _recordMetrics(QueryMetrics metrics) {
    _metrics.add(metrics);
    
    // Manter apenas as métricas mais recentes
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  /// Obter métricas de performance
  static List<QueryMetrics> getMetrics({
    String? queryType,
    Duration? since,
  }) {
    var filteredMetrics = _metrics.toList();

    if (queryType != null) {
      filteredMetrics = filteredMetrics
          .where((m) => m.queryType == queryType)
          .toList();
    }

    if (since != null) {
      final cutoff = DateTime.now().subtract(since);
      filteredMetrics = filteredMetrics
          .where((m) => m.timestamp.isAfter(cutoff))
          .toList();
    }

    return filteredMetrics;
  }

  /// Obter estatísticas de performance
  static Map<String, dynamic> getPerformanceStats({Duration? timeWindow}) {
    try {
      final metrics = getMetrics(since: timeWindow ?? const Duration(hours: 1));
      
      if (metrics.isEmpty) {
        return {
          'totalQueries': 0,
          'averageExecutionTime': 0,
          'cacheHitRate': 0,
          'errorRate': 0,
        };
      }

      final totalQueries = metrics.length;
      final totalExecutionTime = metrics.fold<int>(
        0, (sum, m) => sum + m.executionTime.inMilliseconds
      );
      final cacheHits = metrics.where((m) => m.cacheHit).length;
      final errors = metrics.where((m) => m.error != null).length;
      final totalDocsRead = metrics.fold<int>(0, (sum, m) => sum + m.documentsRead);

      // Estatísticas por tipo de query
      final byType = <String, Map<String, dynamic>>{};
      for (final metric in metrics) {
        if (!byType.containsKey(metric.queryType)) {
          byType[metric.queryType] = {
            'count': 0,
            'totalTime': 0,
            'totalDocs': 0,
            'errors': 0,
            'cacheHits': 0,
          };
        }
        
        final stats = byType[metric.queryType]!;
        stats['count'] = stats['count'] + 1;
        stats['totalTime'] = stats['totalTime'] + metric.executionTime.inMilliseconds;
        stats['totalDocs'] = stats['totalDocs'] + metric.documentsRead;
        if (metric.error != null) stats['errors'] = stats['errors'] + 1;
        if (metric.cacheHit) stats['cacheHits'] = stats['cacheHits'] + 1;
      }

      // Calcular médias por tipo
      for (final stats in byType.values) {
        final count = stats['count'] as int;
        stats['averageTime'] = count > 0 ? (stats['totalTime'] as int) / count : 0;
        stats['averageDocs'] = count > 0 ? (stats['totalDocs'] as int) / count : 0;
        stats['errorRate'] = count > 0 ? (stats['errors'] as int) / count * 100 : 0;
        stats['cacheHitRate'] = count > 0 ? (stats['cacheHits'] as int) / count * 100 : 0;
      }

      return {
        'totalQueries': totalQueries,
        'averageExecutionTime': totalExecutionTime / totalQueries,
        'cacheHitRate': (cacheHits / totalQueries * 100).round(),
        'errorRate': (errors / totalQueries * 100).round(),
        'totalDocumentsRead': totalDocsRead,
        'averageDocsPerQuery': totalDocsRead / totalQueries,
        'queryTypeStats': byType,
        'timeWindow': timeWindow?.toString() ?? '1 hour',
      };
    } catch (e) {
      EnhancedLogger.error('Error calculating performance stats: $e', tag: 'MATCH_PERFORMANCE');
      return {
        'error': e.toString(),
        'totalQueries': 0,
      };
    }
  }

  /// Limpar métricas antigas
  static void clearOldMetrics({Duration maxAge = const Duration(hours: 24)}) {
    try {
      final cutoff = DateTime.now().subtract(maxAge);
      final initialCount = _metrics.length;
      
      _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
      
      final removedCount = initialCount - _metrics.length;
      if (removedCount > 0) {
        EnhancedLogger.info('Cleared $removedCount old metrics', tag: 'MATCH_PERFORMANCE');
      }
    } catch (e) {
      EnhancedLogger.error('Error clearing old metrics: $e', tag: 'MATCH_PERFORMANCE');
    }
  }

  /// Obter recomendações de otimização
  static List<String> getOptimizationRecommendations() {
    try {
      final stats = getPerformanceStats();
      final recommendations = <String>[];

      final averageTime = stats['averageExecutionTime'] as double;
      final cacheHitRate = stats['cacheHitRate'] as int;
      final errorRate = stats['errorRate'] as int;
      final averageDocs = stats['averageDocsPerQuery'] as double;

      if (averageTime > 2000) {
        recommendations.add('Queries estão lentas (${averageTime.round()}ms). Considere otimizar índices.');
      }

      if (cacheHitRate < 30) {
        recommendations.add('Taxa de cache baixa ($cacheHitRate%). Considere aumentar tempo de cache.');
      }

      if (errorRate > 10) {
        recommendations.add('Taxa de erro alta ($errorRate%). Verifique conectividade e índices.');
      }

      if (averageDocs > 20) {
        recommendations.add('Muitos documentos por query (${averageDocs.round()}). Considere paginação.');
      }

      if (recommendations.isEmpty) {
        recommendations.add('Performance está boa! Todas as métricas dentro do esperado.');
      }

      return recommendations;
    } catch (e) {
      EnhancedLogger.error('Error generating recommendations: $e', tag: 'MATCH_PERFORMANCE');
      return ['Erro ao gerar recomendações: $e'];
    }
  }

  /// Executar otimização automática
  static Future<void> autoOptimize() async {
    try {
      EnhancedLogger.info('Starting auto optimization', tag: 'MATCH_PERFORMANCE');

      // Otimizar cache
      await MatchCacheService.optimizeCache();

      // Limpar métricas antigas
      clearOldMetrics();

      // Log das recomendações
      final recommendations = getOptimizationRecommendations();
      for (final recommendation in recommendations) {
        EnhancedLogger.info('Recommendation: $recommendation', tag: 'MATCH_PERFORMANCE');
      }

      EnhancedLogger.info('Auto optimization completed', tag: 'MATCH_PERFORMANCE');
    } catch (e) {
      EnhancedLogger.error('Error during auto optimization: $e', tag: 'MATCH_PERFORMANCE');
    }
  }

  /// Verificar se performance está degradada
  static bool isPerformanceDegraded({
    Duration timeWindow = const Duration(minutes: 10),
    double maxAverageTime = 3000, // 3 segundos
    int maxErrorRate = 20, // 20%
  }) {
    try {
      final stats = getPerformanceStats(timeWindow: timeWindow);
      
      final averageTime = stats['averageExecutionTime'] as double;
      final errorRate = stats['errorRate'] as int;

      return averageTime > maxAverageTime || errorRate > maxErrorRate;
    } catch (e) {
      EnhancedLogger.error('Error checking performance degradation: $e', tag: 'MATCH_PERFORMANCE');
      return false;
    }
  }

  /// Obter query otimizada para mensagens com paginação
  static Query getOptimizedMessagesQuery(
    String chatId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool descending = true,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('chat_messages')
        .where('chatId', isEqualTo: chatId);

    // Sempre usar ordenação para aproveitar índices
    query = query.orderBy('timestamp', descending: descending);

    // Adicionar paginação se especificado
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Limitar resultados
    query = query.limit(limit);

    return query;
  }

  /// Obter query otimizada para contadores de mensagens não lidas
  static Query getOptimizedUnreadCountQuery(String chatId, String userId) {
    return FirebaseFirestore.instance
        .collection('chat_messages')
        .where('chatId', isEqualTo: chatId)
        .where('senderId', isNotEqualTo: userId)
        .where('readBy.$userId', isNull: true);
  }

  /// Executar múltiplas queries em paralelo de forma otimizada
  static Future<List<QuerySnapshot>> executeParallelQueries(
    List<Query> queries, {
    PerformanceConfig config = const PerformanceConfig(),
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      EnhancedLogger.debug('Executing ${queries.length} parallel queries', 
        tag: 'MATCH_PERFORMANCE');

      final futures = queries.map((query) => 
        query.get().timeout(Duration(milliseconds: config.queryTimeout))
      ).toList();

      final results = await Future.wait(futures);
      stopwatch.stop();

      final totalDocs = results.fold<int>(0, (sum, snapshot) => sum + snapshot.docs.length);

      _recordMetrics(QueryMetrics(
        queryType: 'parallel_queries',
        executionTime: stopwatch.elapsed,
        documentsRead: totalDocs,
        cacheHit: false,
      ));

      EnhancedLogger.info('Parallel queries completed in ${stopwatch.elapsedMilliseconds}ms ($totalDocs total docs)', 
        tag: 'MATCH_PERFORMANCE');

      return results;
    } catch (e) {
      stopwatch.stop();

      _recordMetrics(QueryMetrics(
        queryType: 'parallel_queries',
        executionTime: stopwatch.elapsed,
        documentsRead: 0,
        cacheHit: false,
        error: e.toString(),
      ));

      EnhancedLogger.error('Parallel queries failed after ${stopwatch.elapsedMilliseconds}ms: $e', 
        tag: 'MATCH_PERFORMANCE');
      rethrow;
    }
  }

  /// Resetar todas as métricas
  static void resetMetrics() {
    _metrics.clear();
    EnhancedLogger.info('All performance metrics reset', tag: 'MATCH_PERFORMANCE');
  }

  /// Exportar métricas para análise
  static Map<String, dynamic> exportMetrics() {
    return {
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'totalMetrics': _metrics.length,
    };
  }
}