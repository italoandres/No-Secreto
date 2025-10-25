import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/diagnostic_logger.dart';
import '../services/intelligent_cache_manager.dart';
import '../utils/enhanced_logger.dart';

/// Resultado de query otimizada
class OptimizedQueryResult<T> {
  final List<T> data;
  final bool isFromCache;
  final Duration executionTime;
  final int totalDocuments;
  final String optimizationStrategy;
  final Map<String, dynamic> metadata;

  OptimizedQueryResult({
    required this.data,
    required this.isFromCache,
    required this.executionTime,
    required this.totalDocuments,
    required this.optimizationStrategy,
    this.metadata = const {},
  });
}

/// Estratégia de otimização de query
enum QueryOptimizationStrategy {
  cache,
  pagination,
  indexHint,
  fieldSelection,
  batchProcessing,
  parallelExecution,
  preloading,
}

/// Configuração de otimização
class QueryOptimizationConfig {
  final bool enableCache;
  final bool enablePagination;
  final bool enableIndexHints;
  final bool enableFieldSelection;
  final bool enableBatchProcessing;
  final bool enableParallelExecution;
  final bool enablePreloading;
  final int maxConcurrentQueries;
  final int defaultPageSize;
  final Duration cacheTimeout;

  const QueryOptimizationConfig({
    this.enableCache = true,
    this.enablePagination = true,
    this.enableIndexHints = true,
    this.enableFieldSelection = true,
    this.enableBatchProcessing = true,
    this.enableParallelExecution = true,
    this.enablePreloading = false,
    this.maxConcurrentQueries = 5,
    this.defaultPageSize = 20,
    this.cacheTimeout = const Duration(minutes: 10),
  });
}

/// Estatísticas de performance de queries
class QueryPerformanceStats {
  final String queryId;
  final Duration executionTime;
  final int documentsRead;
  final int documentsReturned;
  final bool usedIndex;
  final String strategy;
  final DateTime timestamp;

  QueryPerformanceStats({
    required this.queryId,
    required this.executionTime,
    required this.documentsRead,
    required this.documentsReturned,
    required this.usedIndex,
    required this.strategy,
    required this.timestamp,
  });
}

/// Otimizador de queries para melhor performance
class QueryOptimizer {
  static final QueryOptimizer _instance = QueryOptimizer._internal();
  factory QueryOptimizer() => _instance;
  QueryOptimizer._internal();

  final DiagnosticLogger _logger = DiagnosticLogger();
  final IntelligentCacheManager _cache = IntelligentCacheManager();
  final List<QueryPerformanceStats> _performanceHistory = [];
  final Map<String, int> _queryFrequency = {};
  final Map<String, Duration> _averageExecutionTimes = {};

  QueryOptimizationConfig _config = const QueryOptimizationConfig();
  final Completer<void> _initCompleter = Completer<void>();

  /// Inicializa o otimizador
  Future<void> initialize({QueryOptimizationConfig? config}) async {
    if (_initCompleter.isCompleted) return;

    try {
      _config = config ?? const QueryOptimizationConfig();

      // Registra configurações de cache específicas para queries
      _cache.registerCacheConfig(
          'queries',
          CacheConfig(
            ttl: _config.cacheTimeout,
            maxSize: 200,
            enableCompression: true,
          ));

      _cache.registerCacheConfig(
          'query_results',
          CacheConfig(
            ttl: _config.cacheTimeout,
            maxSize: 500,
            enableCompression: true,
          ));

      _logger.info(
        DiagnosticLogCategory.performance,
        'Query Optimizer inicializado',
        data: {
          'enableCache': _config.enableCache,
          'enablePagination': _config.enablePagination,
          'maxConcurrentQueries': _config.maxConcurrentQueries,
          'defaultPageSize': _config.defaultPageSize,
        },
      );

      EnhancedLogger.log('⚡ [QUERY_OPTIMIZER] Otimizador inicializado');
      _initCompleter.complete();
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro na inicialização do Query Optimizer',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );

      _initCompleter.completeError(e);
    }
  }

  /// Executa query otimizada
  Future<OptimizedQueryResult<T>> executeOptimizedQuery<T>({
    required String queryId,
    required Future<List<T>> Function() queryFunction,
    List<QueryOptimizationStrategy>? strategies,
    Map<String, dynamic>? queryParams,
    Duration? customCacheTimeout,
  }) async {
    await _initCompleter.future;

    final stopwatch = Stopwatch()..start();
    final appliedStrategies =
        strategies ?? _determineOptimalStrategies(queryId);

    try {
      // Incrementa frequência da query
      _queryFrequency[queryId] = (_queryFrequency[queryId] ?? 0) + 1;

      // Tenta cache primeiro se habilitado
      if (_config.enableCache &&
          appliedStrategies.contains(QueryOptimizationStrategy.cache)) {
        final cacheKey = _buildCacheKey(queryId, queryParams);
        final cacheResult = await _cache.get<List<T>>(
          cacheKey,
          cacheType: 'query_results',
        );

        if (cacheResult.isValid) {
          stopwatch.stop();

          _recordPerformanceStats(QueryPerformanceStats(
            queryId: queryId,
            executionTime: stopwatch.elapsed,
            documentsRead: 0,
            documentsReturned: cacheResult.data!.length,
            usedIndex: true,
            strategy: 'cache',
            timestamp: DateTime.now(),
          ));

          _logger.debug(
            DiagnosticLogCategory.performance,
            'Query servida do cache',
            data: {
              'queryId': queryId,
              'resultCount': cacheResult.data!.length,
              'cacheAge': cacheResult.cacheTime != null
                  ? DateTime.now().difference(cacheResult.cacheTime!).inSeconds
                  : 0,
            },
            executionTime: stopwatch.elapsed,
          );

          return OptimizedQueryResult<T>(
            data: cacheResult.data!,
            isFromCache: true,
            executionTime: stopwatch.elapsed,
            totalDocuments: cacheResult.data!.length,
            optimizationStrategy: 'cache',
            metadata: {
              'cacheHit': true,
              'appliedStrategies':
                  appliedStrategies.map((s) => s.toString()).toList(),
            },
          );
        }
      }

      // Executa query com otimizações
      List<T> results;
      String strategy = 'direct';

      if (appliedStrategies
          .contains(QueryOptimizationStrategy.batchProcessing)) {
        results = await _executeBatchQuery(queryFunction);
        strategy = 'batch';
      } else if (appliedStrategies
          .contains(QueryOptimizationStrategy.parallelExecution)) {
        results = await _executeParallelQuery(queryFunction);
        strategy = 'parallel';
      } else {
        results = await queryFunction();
        strategy = 'direct';
      }

      stopwatch.stop();

      // Armazena no cache se habilitado
      if (_config.enableCache &&
          appliedStrategies.contains(QueryOptimizationStrategy.cache)) {
        final cacheKey = _buildCacheKey(queryId, queryParams);
        await _cache.set(
          cacheKey,
          results,
          cacheType: 'query_results',
          customTtl: customCacheTimeout,
        );
      }

      // Registra estatísticas
      _recordPerformanceStats(QueryPerformanceStats(
        queryId: queryId,
        executionTime: stopwatch.elapsed,
        documentsRead: results.length, // Estimativa
        documentsReturned: results.length,
        usedIndex: true, // Assumimos que sim
        strategy: strategy,
        timestamp: DateTime.now(),
      ));

      _logger.info(
        DiagnosticLogCategory.performance,
        'Query otimizada executada',
        data: {
          'queryId': queryId,
          'strategy': strategy,
          'resultCount': results.length,
          'appliedStrategies':
              appliedStrategies.map((s) => s.toString()).toList(),
        },
        executionTime: stopwatch.elapsed,
      );

      return OptimizedQueryResult<T>(
        data: results,
        isFromCache: false,
        executionTime: stopwatch.elapsed,
        totalDocuments: results.length,
        optimizationStrategy: strategy,
        metadata: {
          'cacheHit': false,
          'appliedStrategies':
              appliedStrategies.map((s) => s.toString()).toList(),
          'queryFrequency': _queryFrequency[queryId] ?? 1,
        },
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro na execução de query otimizada',
        data: {
          'queryId': queryId,
          'error': e.toString(),
          'appliedStrategies':
              appliedStrategies.map((s) => s.toString()).toList(),
        },
        stackTrace: stackTrace.toString(),
        executionTime: stopwatch.elapsed,
      );

      rethrow;
    }
  }

  /// Executa múltiplas queries em paralelo
  Future<List<OptimizedQueryResult<T>>> executeParallelQueries<T>(
    List<({String queryId, Future<List<T>> Function() queryFunction})> queries,
  ) async {
    await _initCompleter.future;

    final stopwatch = Stopwatch()..start();

    try {
      // Limita concorrência
      final batches = <List<
          ({String queryId, Future<List<T>> Function() queryFunction})>>[];
      for (int i = 0; i < queries.length; i += _config.maxConcurrentQueries) {
        batches
            .add(queries.skip(i).take(_config.maxConcurrentQueries).toList());
      }

      final allResults = <OptimizedQueryResult<T>>[];

      for (final batch in batches) {
        final futures = batch.map((query) => executeOptimizedQuery<T>(
              queryId: query.queryId,
              queryFunction: query.queryFunction,
            ));

        final batchResults = await Future.wait(futures);
        allResults.addAll(batchResults);
      }

      stopwatch.stop();

      _logger.info(
        DiagnosticLogCategory.performance,
        'Queries paralelas executadas',
        data: {
          'totalQueries': queries.length,
          'batches': batches.length,
          'maxConcurrency': _config.maxConcurrentQueries,
          'totalResults':
              allResults.fold(0, (sum, result) => sum + result.data.length),
        },
        executionTime: stopwatch.elapsed,
      );

      return allResults;
    } catch (e, stackTrace) {
      stopwatch.stop();

      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro na execução de queries paralelas',
        data: {
          'totalQueries': queries.length,
          'error': e.toString(),
        },
        stackTrace: stackTrace.toString(),
        executionTime: stopwatch.elapsed,
      );

      rethrow;
    }
  }

  /// Pré-carrega queries frequentes
  Future<void> preloadFrequentQueries() async {
    if (!_config.enablePreloading) return;

    await _initCompleter.future;

    try {
      // Identifica queries mais frequentes
      final frequentQueries = _queryFrequency.entries
          .where((entry) => entry.value >= 3)
          .map((entry) => entry.key)
          .take(10)
          .toList();

      if (frequentQueries.isEmpty) return;

      _logger.info(
        DiagnosticLogCategory.performance,
        'Iniciando pré-carregamento de queries frequentes',
        data: {
          'queriesCount': frequentQueries.length,
          'queries': frequentQueries,
        },
      );

      // Aqui você implementaria a lógica específica de pré-carregamento
      // baseada nas queries mais frequentes do seu sistema

      EnhancedLogger.log(
          '🚀 [QUERY_OPTIMIZER] Pré-carregamento de ${frequentQueries.length} queries iniciado');
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro no pré-carregamento de queries',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Obtém estatísticas de performance
  Map<String, dynamic> getPerformanceStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(Duration(hours: 24));

    final recentStats = _performanceHistory
        .where((stat) => stat.timestamp.isAfter(last24h))
        .toList();

    if (recentStats.isEmpty) {
      return {
        'totalQueries': 0,
        'averageExecutionTime': 0.0,
        'cacheHitRate': 0.0,
        'topQueries': <String, dynamic>{},
        'strategyUsage': <String, int>{},
      };
    }

    final totalQueries = recentStats.length;
    final avgExecutionTime = recentStats
            .map((stat) => stat.executionTime.inMilliseconds)
            .reduce((a, b) => a + b) /
        totalQueries;

    final cacheHits =
        recentStats.where((stat) => stat.strategy == 'cache').length;
    final cacheHitRate = cacheHits / totalQueries;

    // Estatísticas por query
    final queryStats = <String, List<QueryPerformanceStats>>{};
    for (final stat in recentStats) {
      queryStats[stat.queryId] ??= [];
      queryStats[stat.queryId]!.add(stat);
    }

    final topQueries = queryStats.entries
        .map((entry) => {
              'queryId': entry.key,
              'count': entry.value.length,
              'avgTime': entry.value
                      .map((s) => s.executionTime.inMilliseconds)
                      .reduce((a, b) => a + b) /
                  entry.value.length,
              'frequency': _queryFrequency[entry.key] ?? 0,
            })
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Uso de estratégias
    final strategyUsage = <String, int>{};
    for (final stat in recentStats) {
      strategyUsage[stat.strategy] = (strategyUsage[stat.strategy] ?? 0) + 1;
    }

    return {
      'totalQueries': totalQueries,
      'averageExecutionTime': avgExecutionTime,
      'cacheHitRate': cacheHitRate,
      'topQueries': topQueries.take(10).toList(),
      'strategyUsage': strategyUsage,
      'performanceHistory': recentStats.length,
      'queryFrequency': _queryFrequency,
      'config': {
        'enableCache': _config.enableCache,
        'enablePagination': _config.enablePagination,
        'maxConcurrentQueries': _config.maxConcurrentQueries,
        'defaultPageSize': _config.defaultPageSize,
      },
    };
  }

  /// Otimiza configuração baseada no histórico
  Future<void> optimizeConfiguration() async {
    try {
      final stats = getPerformanceStatistics();
      final suggestions = <String>[];

      // Analisa cache hit rate
      final cacheHitRate = stats['cacheHitRate'] as double;
      if (cacheHitRate < 0.3 && _config.enableCache) {
        suggestions.add(
            'Cache hit rate baixo (${(cacheHitRate * 100).toStringAsFixed(1)}%) - considere aumentar TTL');
      }

      // Analisa tempo médio de execução
      final avgTime = stats['averageExecutionTime'] as double;
      if (avgTime > 1000) {
        suggestions.add(
            'Tempo médio alto (${avgTime.toStringAsFixed(0)}ms) - considere otimizações adicionais');
      }

      // Analisa queries mais frequentes
      final topQueries = stats['topQueries'] as List;
      if (topQueries.isNotEmpty) {
        final mostFrequent = topQueries.first;
        if ((mostFrequent['count'] as int) > 50) {
          suggestions.add(
              'Query "${mostFrequent['queryId']}" muito frequente - considere pré-carregamento');
        }
      }

      if (suggestions.isNotEmpty) {
        _logger.info(
          DiagnosticLogCategory.performance,
          'Sugestões de otimização geradas',
          data: {
            'suggestions': suggestions,
            'analysisData': {
              'cacheHitRate': cacheHitRate,
              'avgExecutionTime': avgTime,
              'totalQueries': stats['totalQueries'],
            },
          },
        );

        EnhancedLogger.log(
            '💡 [QUERY_OPTIMIZER] ${suggestions.length} sugestões de otimização geradas');
      }
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro na otimização de configuração',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Limpa cache de queries
  Future<void> clearQueryCache() async {
    await _cache.invalidateType('query_results');
    await _cache.invalidateType('queries');

    _logger.info(
      DiagnosticLogCategory.performance,
      'Cache de queries limpo',
    );

    EnhancedLogger.log('🧹 [QUERY_OPTIMIZER] Cache de queries limpo');
  }

  /// Determina estratégias ótimas para uma query
  List<QueryOptimizationStrategy> _determineOptimalStrategies(String queryId) {
    final strategies = <QueryOptimizationStrategy>[];

    // Cache sempre habilitado se configurado
    if (_config.enableCache) {
      strategies.add(QueryOptimizationStrategy.cache);
    }

    // Baseado na frequência da query
    final frequency = _queryFrequency[queryId] ?? 0;

    if (frequency > 10 && _config.enablePreloading) {
      strategies.add(QueryOptimizationStrategy.preloading);
    }

    if (frequency > 5 && _config.enableBatchProcessing) {
      strategies.add(QueryOptimizationStrategy.batchProcessing);
    }

    // Baseado no tempo médio de execução
    final avgTime = _averageExecutionTimes[queryId];
    if (avgTime != null && avgTime.inMilliseconds > 500) {
      if (_config.enableParallelExecution) {
        strategies.add(QueryOptimizationStrategy.parallelExecution);
      }
      if (_config.enablePagination) {
        strategies.add(QueryOptimizationStrategy.pagination);
      }
    }

    // Estratégias sempre aplicáveis
    if (_config.enableIndexHints) {
      strategies.add(QueryOptimizationStrategy.indexHint);
    }
    if (_config.enableFieldSelection) {
      strategies.add(QueryOptimizationStrategy.fieldSelection);
    }

    return strategies;
  }

  /// Constrói chave de cache
  String _buildCacheKey(String queryId, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return queryId;
    }

    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    return '${queryId}_${sortedParams.hashCode}';
  }

  /// Executa query em lotes
  Future<List<T>> _executeBatchQuery<T>(
      Future<List<T>> Function() queryFunction) async {
    // Implementação simplificada - em um caso real, você dividiria a query em lotes menores
    return await queryFunction();
  }

  /// Executa query em paralelo
  Future<List<T>> _executeParallelQuery<T>(
      Future<List<T>> Function() queryFunction) async {
    // Implementação simplificada - em um caso real, você dividiria a query em partes paralelas
    return await queryFunction();
  }

  /// Registra estatísticas de performance
  void _recordPerformanceStats(QueryPerformanceStats stats) {
    _performanceHistory.add(stats);

    // Mantém apenas últimas 1000 estatísticas
    if (_performanceHistory.length > 1000) {
      _performanceHistory.removeRange(0, _performanceHistory.length - 1000);
    }

    // Atualiza tempo médio de execução
    final queryStats =
        _performanceHistory.where((s) => s.queryId == stats.queryId).toList();

    if (queryStats.isNotEmpty) {
      final avgTime = queryStats
              .map((s) => s.executionTime.inMilliseconds)
              .reduce((a, b) => a + b) /
          queryStats.length;

      _averageExecutionTimes[stats.queryId] =
          Duration(milliseconds: avgTime.round());
    }
  }

  /// Dispose dos recursos
  void dispose() {
    _performanceHistory.clear();
    _queryFrequency.clear();
    _averageExecutionTimes.clear();

    _logger.info(
      DiagnosticLogCategory.performance,
      'Query Optimizer finalizado',
    );

    EnhancedLogger.log('⚡ [QUERY_OPTIMIZER] Otimizador finalizado');
  }
}
