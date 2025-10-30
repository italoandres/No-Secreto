import 'dart:convert';
import 'dart:io';
import '../models/search_filters.dart';
import '../models/search_result.dart';
import '../utils/enhanced_logger.dart';

/// Logger estruturado específico para operações de busca
/// com análise de padrões e métricas detalhadas
class SearchLogger {
  static SearchLogger? _instance;
  static SearchLogger get instance => _instance ??= SearchLogger._();

  SearchLogger._();

  /// Histórico de operações de busca
  final List<SearchLogEntry> _searchHistory = [];
  static const int maxHistorySize = 500;

  /// Métricas agregadas
  final Map<String, SearchMetrics> _operationMetrics = {};

  /// Padrões de busca identificados
  final List<SearchPattern> _identifiedPatterns = [];

  /// Registra início de uma operação de busca
  String startSearchOperation({
    required String operationName,
    required String query,
    SearchFilters? filters,
    required int limit,
    Map<String, dynamic>? additionalContext,
  }) {
    final operationId = _generateOperationId();
    final startTime = DateTime.now();

    final entry = SearchLogEntry(
      operationId: operationId,
      operationName: operationName,
      query: query,
      filters: filters,
      limit: limit,
      startTime: startTime,
      additionalContext: additionalContext ?? {},
    );

    _searchHistory.add(entry);

    // Limitar tamanho do histórico
    if (_searchHistory.length > maxHistorySize) {
      _searchHistory.removeAt(0);
    }

    EnhancedLogger.info('Search operation started',
        tag: 'SEARCH_LOGGER',
        data: {
          'operationId': operationId,
          'operationName': operationName,
          'query': query,
          'hasFilters': filters != null,
          'limit': limit,
          'timestamp': startTime.toIso8601String(),
          ...?additionalContext,
        });

    return operationId;
  }

  /// Registra conclusão de uma operação de busca
  void completeSearchOperation({
    required String operationId,
    SearchResult? result,
    Exception? error,
    String? strategy,
    bool fromCache = false,
    int? retryAttempts,
    Map<String, dynamic>? additionalData,
  }) {
    final entry = _findEntryById(operationId);
    if (entry == null) {
      EnhancedLogger.warning('Search operation not found for completion',
          tag: 'SEARCH_LOGGER', data: {'operationId': operationId});
      return;
    }

    final endTime = DateTime.now();
    final executionTime = endTime.difference(entry.startTime).inMilliseconds;

    entry.endTime = endTime;
    entry.executionTime = executionTime;
    entry.result = result;
    entry.error = error;
    entry.strategy = strategy;
    entry.fromCache = fromCache;
    entry.retryAttempts = retryAttempts ?? 0;
    entry.additionalData = additionalData ?? {};

    // Atualizar métricas
    _updateMetrics(entry);

    // Analisar padrões
    _analyzePatterns(entry);

    final logLevel = error != null ? 'error' : 'success';
    final logData = {
      'operationId': operationId,
      'operationName': entry.operationName,
      'query': entry.query,
      'executionTime': executionTime,
      'resultCount': result?.profiles.length ?? 0,
      'totalResults': result?.totalResults ?? 0,
      'hasMore': result?.hasMore ?? false,
      'fromCache': fromCache,
      'strategy': strategy,
      'retryAttempts': retryAttempts ?? 0,
      'hasError': error != null,
      'errorType': error?.runtimeType.toString(),
      'timestamp': endTime.toIso8601String(),
      ...?additionalData,
    };

    if (error != null) {
      EnhancedLogger.error('Search operation failed',
          tag: 'SEARCH_LOGGER',
          data: {
            ...logData,
            'error': error.toString(),
          });
    } else {
      EnhancedLogger.success('Search operation completed',
          tag: 'SEARCH_LOGGER', data: logData);
    }
  }

  /// Registra evento durante uma operação de busca
  void logSearchEvent({
    required String operationId,
    required String eventType,
    required String message,
    Map<String, dynamic>? data,
  }) {
    final entry = _findEntryById(operationId);
    if (entry == null) return;

    final event = SearchEvent(
      timestamp: DateTime.now(),
      eventType: eventType,
      message: message,
      data: data ?? {},
    );

    entry.events.add(event);

    EnhancedLogger.debug('Search event', tag: 'SEARCH_LOGGER', data: {
      'operationId': operationId,
      'eventType': eventType,
      'message': message,
      'timestamp': event.timestamp.toIso8601String(),
      ...?data,
    });
  }

  /// Obtém métricas detalhadas de busca
  Map<String, dynamic> getSearchMetrics({Duration? timeWindow}) {
    final now = DateTime.now();
    final windowStart = timeWindow != null ? now.subtract(timeWindow) : null;

    // Filtrar entradas por janela de tempo se especificada
    final relevantEntries = _searchHistory.where((entry) {
      return windowStart == null || entry.startTime.isAfter(windowStart);
    }).toList();

    if (relevantEntries.isEmpty) {
      return {
        'totalOperations': 0,
        'timeWindow': timeWindow?.inMinutes,
        'timestamp': now.toIso8601String(),
      };
    }

    // Calcular métricas básicas
    final totalOperations = relevantEntries.length;
    final successfulOperations =
        relevantEntries.where((e) => e.error == null).length;
    final failedOperations = totalOperations - successfulOperations;
    final successRate =
        totalOperations > 0 ? successfulOperations / totalOperations : 0.0;

    // Métricas de tempo
    final executionTimes = relevantEntries
        .where((e) => e.executionTime != null)
        .map((e) => e.executionTime!)
        .toList();

    final avgExecutionTime = executionTimes.isNotEmpty
        ? executionTimes.reduce((a, b) => a + b) / executionTimes.length
        : 0.0;

    executionTimes.sort();
    final medianExecutionTime = executionTimes.isNotEmpty
        ? executionTimes[executionTimes.length ~/ 2]
        : 0;

    // Métricas de cache
    final cacheHits = relevantEntries.where((e) => e.fromCache == true).length;
    final cacheHitRate =
        totalOperations > 0 ? cacheHits / totalOperations : 0.0;

    // Métricas por operação
    final operationStats = <String, Map<String, dynamic>>{};
    final operationGroups = <String, List<SearchLogEntry>>{};

    for (final entry in relevantEntries) {
      operationGroups.putIfAbsent(entry.operationName, () => []).add(entry);
    }

    operationGroups.forEach((operation, entries) {
      final opSuccessful = entries.where((e) => e.error == null).length;
      final opTotal = entries.length;
      final opTimes = entries
          .where((e) => e.executionTime != null)
          .map((e) => e.executionTime!)
          .toList();

      operationStats[operation] = {
        'totalCalls': opTotal,
        'successfulCalls': opSuccessful,
        'failedCalls': opTotal - opSuccessful,
        'successRate': opTotal > 0 ? opSuccessful / opTotal : 0.0,
        'avgExecutionTime': opTimes.isNotEmpty
            ? opTimes.reduce((a, b) => a + b) / opTimes.length
            : 0.0,
      };
    });

    // Queries mais comuns
    final queryFrequency = <String, int>{};
    for (final entry in relevantEntries) {
      final normalizedQuery = entry.query.toLowerCase().trim();
      queryFrequency[normalizedQuery] =
          (queryFrequency[normalizedQuery] ?? 0) + 1;
    }

    final topQueries = queryFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Estratégias mais usadas
    final strategyFrequency = <String, int>{};
    for (final entry in relevantEntries) {
      if (entry.strategy != null) {
        strategyFrequency[entry.strategy!] =
            (strategyFrequency[entry.strategy!] ?? 0) + 1;
      }
    }

    return {
      'timestamp': now.toIso8601String(),
      'timeWindow': timeWindow?.inMinutes,
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'successRate': successRate,
      'successRatePercentage': '${(successRate * 100).toStringAsFixed(1)}%',
      'performance': {
        'avgExecutionTime': avgExecutionTime.round(),
        'medianExecutionTime': medianExecutionTime,
        'minExecutionTime':
            executionTimes.isNotEmpty ? executionTimes.first : 0,
        'maxExecutionTime': executionTimes.isNotEmpty ? executionTimes.last : 0,
      },
      'cache': {
        'hits': cacheHits,
        'hitRate': cacheHitRate,
        'hitRatePercentage': '${(cacheHitRate * 100).toStringAsFixed(1)}%',
      },
      'operationStats': operationStats,
      'topQueries': topQueries
          .take(10)
          .map((e) => {
                'query': e.key,
                'count': e.value,
              })
          .toList(),
      'strategyUsage': strategyFrequency,
      'identifiedPatterns': _identifiedPatterns.map((p) => p.toJson()).toList(),
    };
  }

  /// Obtém histórico de operações recentes
  List<Map<String, dynamic>> getRecentOperations({int limit = 50}) {
    return _searchHistory.reversed
        .take(limit)
        .map((entry) => {
              'operationId': entry.operationId,
              'operationName': entry.operationName,
              'query': entry.query,
              'startTime': entry.startTime.toIso8601String(),
              'endTime': entry.endTime?.toIso8601String(),
              'executionTime': entry.executionTime,
              'resultCount': entry.result?.profiles.length ?? 0,
              'fromCache': entry.fromCache,
              'strategy': entry.strategy,
              'hasError': entry.error != null,
              'retryAttempts': entry.retryAttempts,
              'events': entry.events.map((e) => e.toJson()).toList(),
            })
        .toList();
  }

  /// Analisa padrões de busca
  void _analyzePatterns(SearchLogEntry entry) {
    // Detectar queries repetitivas
    _detectRepetitiveQueries(entry);

    // Detectar filtros comuns
    _detectCommonFilters(entry);

    // Detectar padrões de performance
    _detectPerformancePatterns(entry);
  }

  /// Detecta queries repetitivas
  void _detectRepetitiveQueries(SearchLogEntry entry) {
    final recentEntries = _searchHistory
        .where((e) => DateTime.now().difference(e.startTime).inMinutes < 60)
        .toList();

    final sameQueryCount = recentEntries
        .where((e) => e.query.toLowerCase() == entry.query.toLowerCase())
        .length;

    if (sameQueryCount >= 5) {
      final pattern = SearchPattern(
        type: 'repetitive_query',
        description:
            'Query "${entry.query}" executada ${sameQueryCount}x na última hora',
        frequency: sameQueryCount,
        detectedAt: DateTime.now(),
        data: {'query': entry.query},
      );

      _addPattern(pattern);
    }
  }

  /// Detecta filtros comuns
  void _detectCommonFilters(SearchLogEntry entry) {
    if (entry.filters == null) return;

    final recentEntries = _searchHistory
        .where((e) =>
            e.filters != null &&
            DateTime.now().difference(e.startTime).inMinutes < 120)
        .toList();

    // Analisar filtros de idade
    if (entry.filters!.minAge != null || entry.filters!.maxAge != null) {
      final ageFilterCount = recentEntries
          .where((e) => e.filters!.minAge != null || e.filters!.maxAge != null)
          .length;

      if (ageFilterCount >= 10) {
        final pattern = SearchPattern(
          type: 'common_age_filter',
          description:
              'Filtros de idade usados em ${ageFilterCount} buscas recentes',
          frequency: ageFilterCount,
          detectedAt: DateTime.now(),
          data: {
            'minAge': entry.filters!.minAge,
            'maxAge': entry.filters!.maxAge,
          },
        );

        _addPattern(pattern);
      }
    }
  }

  /// Detecta padrões de performance
  void _detectPerformancePatterns(SearchLogEntry entry) {
    if (entry.executionTime == null) return;

    final recentEntries = _searchHistory
        .where((e) =>
            e.executionTime != null &&
            DateTime.now().difference(e.startTime).inMinutes < 30)
        .toList();

    if (recentEntries.length < 5) return;

    final avgTime =
        recentEntries.map((e) => e.executionTime!).reduce((a, b) => a + b) /
            recentEntries.length;

    // Detectar operações lentas
    if (entry.executionTime! > avgTime * 2 && entry.executionTime! > 1000) {
      final pattern = SearchPattern(
        type: 'slow_operation',
        description:
            'Operação ${entry.operationName} executou em ${entry.executionTime}ms (média: ${avgTime.round()}ms)',
        frequency: 1,
        detectedAt: DateTime.now(),
        data: {
          'operationName': entry.operationName,
          'executionTime': entry.executionTime,
          'averageTime': avgTime.round(),
        },
      );

      _addPattern(pattern);
    }
  }

  /// Adiciona um padrão identificado
  void _addPattern(SearchPattern pattern) {
    // Evitar duplicatas recentes
    final recentPatterns = _identifiedPatterns
        .where((p) =>
            p.type == pattern.type &&
            DateTime.now().difference(p.detectedAt).inMinutes < 30)
        .toList();

    if (recentPatterns.isEmpty) {
      _identifiedPatterns.add(pattern);

      // Limitar tamanho da lista
      if (_identifiedPatterns.length > 100) {
        _identifiedPatterns.removeAt(0);
      }

      EnhancedLogger.info('Search pattern detected',
          tag: 'SEARCH_LOGGER', data: pattern.toJson());
    }
  }

  /// Atualiza métricas agregadas
  void _updateMetrics(SearchLogEntry entry) {
    final metrics = _operationMetrics.putIfAbsent(entry.operationName,
        () => SearchMetrics(operationName: entry.operationName));

    metrics.totalCalls++;

    if (entry.error == null) {
      metrics.successfulCalls++;
    } else {
      metrics.failedCalls++;
    }

    if (entry.executionTime != null) {
      metrics.totalExecutionTime += entry.executionTime!;
      metrics.executionTimes.add(entry.executionTime!);

      // Manter apenas os últimos 100 tempos para cálculos
      if (metrics.executionTimes.length > 100) {
        metrics.totalExecutionTime -= metrics.executionTimes.removeAt(0);
      }
    }

    if (entry.fromCache == true) {
      metrics.cacheHits++;
    }

    metrics.lastExecuted = entry.endTime ?? DateTime.now();
  }

  /// Encontra entrada por ID
  SearchLogEntry? _findEntryById(String operationId) {
    try {
      return _searchHistory
          .firstWhere((entry) => entry.operationId == operationId);
    } catch (e) {
      return null;
    }
  }

  /// Gera ID único para operação
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'search_${timestamp}_$random';
  }

  /// Limpa histórico de logs
  void clearHistory() {
    _searchHistory.clear();
    _operationMetrics.clear();
    _identifiedPatterns.clear();

    EnhancedLogger.info('Search history cleared', tag: 'SEARCH_LOGGER');
  }

  /// Exporta logs para análise externa
  Map<String, dynamic> exportLogs({Duration? timeWindow}) {
    final now = DateTime.now();
    final windowStart = timeWindow != null ? now.subtract(timeWindow) : null;

    final relevantEntries = _searchHistory.where((entry) {
      return windowStart == null || entry.startTime.isAfter(windowStart);
    }).toList();

    return {
      'exportTimestamp': now.toIso8601String(),
      'timeWindow': timeWindow?.inMinutes,
      'totalEntries': relevantEntries.length,
      'entries': relevantEntries.map((entry) => entry.toJson()).toList(),
      'metrics': getSearchMetrics(timeWindow: timeWindow),
      'patterns': _identifiedPatterns.map((p) => p.toJson()).toList(),
    };
  }
}

/// Entrada de log de busca
class SearchLogEntry {
  final String operationId;
  final String operationName;
  final String query;
  final SearchFilters? filters;
  final int limit;
  final DateTime startTime;
  final Map<String, dynamic> additionalContext;
  final List<SearchEvent> events = [];

  DateTime? endTime;
  int? executionTime;
  SearchResult? result;
  Exception? error;
  String? strategy;
  bool fromCache = false;
  int retryAttempts = 0;
  Map<String, dynamic> additionalData = {};

  SearchLogEntry({
    required this.operationId,
    required this.operationName,
    required this.query,
    required this.filters,
    required this.limit,
    required this.startTime,
    required this.additionalContext,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'operationName': operationName,
      'query': query,
      'hasFilters': filters != null,
      'limit': limit,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'executionTime': executionTime,
      'resultCount': result?.profiles.length ?? 0,
      'totalResults': result?.totalResults ?? 0,
      'hasMore': result?.hasMore ?? false,
      'fromCache': fromCache,
      'strategy': strategy,
      'hasError': error != null,
      'errorType': error?.runtimeType.toString(),
      'retryAttempts': retryAttempts,
      'events': events.map((e) => e.toJson()).toList(),
      'additionalContext': additionalContext,
      'additionalData': additionalData,
    };
  }
}

/// Evento durante uma operação de busca
class SearchEvent {
  final DateTime timestamp;
  final String eventType;
  final String message;
  final Map<String, dynamic> data;

  const SearchEvent({
    required this.timestamp,
    required this.eventType,
    required this.message,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'message': message,
      'data': data,
    };
  }
}

/// Métricas agregadas por operação
class SearchMetrics {
  final String operationName;
  int totalCalls = 0;
  int successfulCalls = 0;
  int failedCalls = 0;
  int totalExecutionTime = 0;
  int cacheHits = 0;
  DateTime? lastExecuted;
  final List<int> executionTimes = [];

  SearchMetrics({required this.operationName});

  double get successRate => totalCalls > 0 ? successfulCalls / totalCalls : 0.0;
  double get averageExecutionTime => executionTimes.isNotEmpty
      ? executionTimes.reduce((a, b) => a + b) / executionTimes.length
      : 0.0;
  double get cacheHitRate => totalCalls > 0 ? cacheHits / totalCalls : 0.0;
}

/// Padrão de busca identificado
class SearchPattern {
  final String type;
  final String description;
  final int frequency;
  final DateTime detectedAt;
  final Map<String, dynamic> data;

  const SearchPattern({
    required this.type,
    required this.description,
    required this.frequency,
    required this.detectedAt,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'frequency': frequency,
      'detectedAt': detectedAt.toIso8601String(),
      'data': data,
    };
  }
}
