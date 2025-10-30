import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/search_filters.dart';
import '../models/search_result.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/enhanced_logger.dart';

/// Handler especializado para erros de busca com retry automático
/// e fallback inteligente baseado no tipo de erro
class SearchErrorHandler {
  static SearchErrorHandler? _instance;
  static SearchErrorHandler get instance =>
      _instance ??= SearchErrorHandler._();

  SearchErrorHandler._();

  /// Configurações de retry
  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);
  static const Duration maxRetryDelay = Duration(seconds: 10);

  /// Histórico de erros para análise
  final List<SearchErrorEvent> _errorHistory = [];
  static const int maxErrorHistorySize = 100;

  /// Contadores de erro por tipo
  final Map<SearchErrorType, int> _errorCounts = {};

  /// Última vez que cada tipo de erro ocorreu
  final Map<SearchErrorType, DateTime> _lastErrorTime = {};

  /// Executa uma operação de busca com retry automático e fallback
  Future<SearchResult> executeWithRetry<T>({
    required Future<SearchResult> Function() operation,
    required String operationName,
    required String query,
    SearchFilters? filters,
    int limit = 20,
    List<SearchFallbackStrategy>? fallbackStrategies,
  }) async {
    final startTime = DateTime.now();
    SearchResult? lastResult;
    Exception? lastException;

    EnhancedLogger.info('Starting search operation with error handling',
        tag: 'SEARCH_ERROR_HANDLER',
        data: {
          'operation': operationName,
          'query': query,
          'hasFilters': filters != null,
          'limit': limit,
          'maxRetries': maxRetryAttempts,
        });

    // Tentar operação principal com retry
    for (int attempt = 1; attempt <= maxRetryAttempts; attempt++) {
      try {
        final result = await operation();

        // Sucesso - registrar e retornar
        _recordSuccess(operationName, attempt, startTime);
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorType = _classifyError(lastException);

        EnhancedLogger.warning('Search operation failed',
            tag: 'SEARCH_ERROR_HANDLER',
            data: {
              'operation': operationName,
              'attempt': attempt,
              'maxAttempts': maxRetryAttempts,
              'errorType': errorType.toString(),
              'error': e.toString(),
            });

        // Registrar erro
        _recordError(operationName, errorType, lastException, attempt);

        // Se não é o último attempt e o erro é recuperável, tentar novamente
        if (attempt < maxRetryAttempts && _isRecoverableError(errorType)) {
          final delay = _calculateRetryDelay(attempt, errorType);

          EnhancedLogger.info('Retrying search operation',
              tag: 'SEARCH_ERROR_HANDLER',
              data: {
                'operation': operationName,
                'attempt': attempt + 1,
                'delayMs': delay.inMilliseconds,
                'errorType': errorType.toString(),
              });

          await Future.delayed(delay);
          continue;
        }

        // Último attempt falhou - tentar fallbacks
        break;
      }
    }

    // Operação principal falhou - tentar fallbacks
    if (fallbackStrategies != null && fallbackStrategies.isNotEmpty) {
      for (final strategy in fallbackStrategies) {
        try {
          EnhancedLogger.info('Attempting fallback strategy',
              tag: 'SEARCH_ERROR_HANDLER',
              data: {
                'operation': operationName,
                'strategy': strategy.name,
                'query': query,
              });

          final result = await strategy.execute(query, filters, limit);

          EnhancedLogger.success('Fallback strategy succeeded',
              tag: 'SEARCH_ERROR_HANDLER',
              data: {
                'operation': operationName,
                'strategy': strategy.name,
                'results': result.profiles.length,
                'executionTime':
                    DateTime.now().difference(startTime).inMilliseconds,
              });

          return result;
        } catch (fallbackError) {
          EnhancedLogger.warning('Fallback strategy failed',
              tag: 'SEARCH_ERROR_HANDLER',
              data: {
                'operation': operationName,
                'strategy': strategy.name,
                'error': fallbackError.toString(),
              });
          continue;
        }
      }
    }

    // Todos os fallbacks falharam - retornar resultado vazio com erro
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;

    EnhancedLogger.error('All search strategies failed',
        tag: 'SEARCH_ERROR_HANDLER',
        data: {
          'operation': operationName,
          'query': query,
          'totalExecutionTime': executionTime,
          'finalError': lastException?.toString(),
        });

    return SearchResult(
      profiles: [],
      totalResults: 0,
      hasMore: false,
      appliedFilters: filters,
      fromCache: false,
      error: SearchError(
        type: _classifyError(lastException!),
        message: lastException.toString(),
        originalException: lastException,
        operationName: operationName,
        query: query,
        filters: filters,
        retryAttempts: maxRetryAttempts,
        executionTime: executionTime,
      ),
    );
  }

  /// Classifica o tipo de erro para escolher estratégia apropriada
  SearchErrorType _classifyError(Exception error) {
    final errorString = error.toString().toLowerCase();

    // Erros de índice do Firebase
    if (errorString.contains('index') ||
        errorString.contains('composite') ||
        errorString.contains('requires an index')) {
      return SearchErrorType.indexMissing;
    }

    // Erros de permissão
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('unauthorized')) {
      return SearchErrorType.permissionDenied;
    }

    // Erros de rede
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        error is SocketException ||
        error is TimeoutException) {
      return SearchErrorType.networkError;
    }

    // Erros de quota
    if (errorString.contains('quota') ||
        errorString.contains('limit') ||
        errorString.contains('exceeded') ||
        errorString.contains('resource exhausted')) {
      return SearchErrorType.quotaExceeded;
    }

    // Erros de validação
    if (errorString.contains('invalid') ||
        errorString.contains('malformed') ||
        errorString.contains('bad request')) {
      return SearchErrorType.validationError;
    }

    // Erros de timeout
    if (errorString.contains('timeout') ||
        errorString.contains('deadline exceeded')) {
      return SearchErrorType.timeout;
    }

    return SearchErrorType.unknown;
  }

  /// Verifica se um erro é recuperável com retry
  bool _isRecoverableError(SearchErrorType errorType) {
    switch (errorType) {
      case SearchErrorType.networkError:
      case SearchErrorType.timeout:
      case SearchErrorType.quotaExceeded:
        return true;
      case SearchErrorType.indexMissing:
      case SearchErrorType.permissionDenied:
      case SearchErrorType.validationError:
      case SearchErrorType.unknown:
        return false;
    }
  }

  /// Calcula delay para retry baseado no attempt e tipo de erro
  Duration _calculateRetryDelay(int attempt, SearchErrorType errorType) {
    // Exponential backoff com jitter
    var delay = Duration(
        milliseconds:
            (baseRetryDelay.inMilliseconds * (1 << (attempt - 1))).toInt());

    // Ajustar baseado no tipo de erro
    switch (errorType) {
      case SearchErrorType.networkError:
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).toInt());
        break;
      case SearchErrorType.quotaExceeded:
        delay = Duration(milliseconds: (delay.inMilliseconds * 2.0).toInt());
        break;
      case SearchErrorType.timeout:
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.2).toInt());
        break;
      default:
        break;
    }

    // Aplicar jitter (±25%)
    final jitter = (delay.inMilliseconds *
            0.25 *
            (DateTime.now().millisecond / 1000.0 - 0.5))
        .toInt();
    delay = Duration(milliseconds: delay.inMilliseconds + jitter);

    // Limitar ao máximo
    if (delay > maxRetryDelay) {
      delay = maxRetryDelay;
    }

    return delay;
  }

  /// Registra um erro no histórico
  void _recordError(String operation, SearchErrorType errorType,
      Exception error, int attempt) {
    final event = SearchErrorEvent(
      timestamp: DateTime.now(),
      operation: operation,
      errorType: errorType,
      error: error,
      attempt: attempt,
    );

    _errorHistory.add(event);

    // Limitar tamanho do histórico
    if (_errorHistory.length > maxErrorHistorySize) {
      _errorHistory.removeAt(0);
    }

    // Atualizar contadores
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _lastErrorTime[errorType] = DateTime.now();
  }

  /// Registra um sucesso
  void _recordSuccess(String operation, int attempts, DateTime startTime) {
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;

    EnhancedLogger.success('Search operation completed successfully',
        tag: 'SEARCH_ERROR_HANDLER',
        data: {
          'operation': operation,
          'attempts': attempts,
          'executionTime': executionTime,
          'wasRetried': attempts > 1,
        });
  }

  /// Obtém estatísticas de erro
  Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();

    // Calcular estatísticas por tipo de erro
    final errorTypeStats = <String, Map<String, dynamic>>{};
    for (final errorType in SearchErrorType.values) {
      final count = _errorCounts[errorType] ?? 0;
      final lastTime = _lastErrorTime[errorType];

      errorTypeStats[errorType.toString()] = {
        'count': count,
        'lastOccurrence': lastTime?.toIso8601String(),
        'minutesSinceLastOccurrence':
            lastTime != null ? now.difference(lastTime).inMinutes : null,
      };
    }

    // Estatísticas dos últimos erros
    final recentErrors = _errorHistory
        .where((e) => now.difference(e.timestamp).inMinutes < 60)
        .toList();

    final totalErrors =
        _errorCounts.values.fold(0, (sum, count) => sum + count);

    return {
      'timestamp': now.toIso8601String(),
      'totalErrors': totalErrors,
      'recentErrors': recentErrors.length,
      'errorTypeStats': errorTypeStats,
      'recentErrorsByType': _groupRecentErrorsByType(recentErrors),
      'configuration': {
        'maxRetryAttempts': maxRetryAttempts,
        'baseRetryDelay': baseRetryDelay.inMilliseconds,
        'maxRetryDelay': maxRetryDelay.inMilliseconds,
        'maxHistorySize': maxErrorHistorySize,
      },
      'healthStatus': _calculateHealthStatus(),
    };
  }

  /// Agrupa erros recentes por tipo
  Map<String, int> _groupRecentErrorsByType(
      List<SearchErrorEvent> recentErrors) {
    final grouped = <String, int>{};

    for (final error in recentErrors) {
      final key = error.errorType.toString();
      grouped[key] = (grouped[key] ?? 0) + 1;
    }

    return grouped;
  }

  /// Calcula status de saúde do sistema
  String _calculateHealthStatus() {
    final now = DateTime.now();
    final recentErrors = _errorHistory
        .where((e) => now.difference(e.timestamp).inMinutes < 30)
        .length;

    if (recentErrors == 0) return 'healthy';
    if (recentErrors < 5) return 'warning';
    return 'critical';
  }

  /// Obtém histórico de erros recentes
  List<Map<String, dynamic>> getRecentErrors({int limit = 20}) {
    return _errorHistory.reversed
        .take(limit)
        .map((event) => {
              'timestamp': event.timestamp.toIso8601String(),
              'operation': event.operation,
              'errorType': event.errorType.toString(),
              'error': event.error.toString(),
              'attempt': event.attempt,
              'minutesAgo':
                  DateTime.now().difference(event.timestamp).inMinutes,
            })
        .toList();
  }

  /// Limpa histórico de erros
  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTime.clear();

    EnhancedLogger.info('Error history cleared', tag: 'SEARCH_ERROR_HANDLER');
  }

  /// Verifica se um tipo de erro está ocorrendo frequentemente
  bool isErrorTypeFrequent(
    SearchErrorType errorType, {
    Duration timeWindow = const Duration(minutes: 30),
    int threshold = 5,
  }) {
    final now = DateTime.now();
    final recentErrors = _errorHistory
        .where((e) =>
            e.errorType == errorType &&
            now.difference(e.timestamp) <= timeWindow)
        .length;

    return recentErrors >= threshold;
  }

  /// Cria estratégias de fallback baseadas no histórico de erros
  List<SearchFallbackStrategy> createAdaptiveFallbacks({
    required String query,
    SearchFilters? filters,
    required int limit,
  }) {
    final strategies = <SearchFallbackStrategy>[];

    // Analisar erros frequentes para escolher melhores fallbacks
    if (isErrorTypeFrequent(SearchErrorType.indexMissing)) {
      strategies.add(SimpleQueryFallbackStrategy());
    }

    if (isErrorTypeFrequent(SearchErrorType.networkError)) {
      strategies.add(CachedResultsFallbackStrategy());
    }

    if (isErrorTypeFrequent(SearchErrorType.quotaExceeded)) {
      strategies.add(CachedResultsFallbackStrategy());
      strategies.add(LimitedQueryFallbackStrategy());
    }

    // Sempre adicionar fallback básico como último recurso
    strategies.add(EmptyResultFallbackStrategy());

    return strategies;
  }
}

/// Tipos de erro de busca
enum SearchErrorType {
  indexMissing,
  permissionDenied,
  networkError,
  quotaExceeded,
  validationError,
  timeout,
  unknown,
}

/// Evento de erro registrado
class SearchErrorEvent {
  final DateTime timestamp;
  final String operation;
  final SearchErrorType errorType;
  final Exception error;
  final int attempt;

  const SearchErrorEvent({
    required this.timestamp,
    required this.operation,
    required this.errorType,
    required this.error,
    required this.attempt,
  });
}

/// Erro de busca com contexto detalhado
class SearchError {
  final SearchErrorType type;
  final String message;
  final Exception originalException;
  final String operationName;
  final String query;
  final SearchFilters? filters;
  final int retryAttempts;
  final int executionTime;

  const SearchError({
    required this.type,
    required this.message,
    required this.originalException,
    required this.operationName,
    required this.query,
    required this.filters,
    required this.retryAttempts,
    required this.executionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'message': message,
      'operationName': operationName,
      'query': query,
      'hasFilters': filters != null,
      'retryAttempts': retryAttempts,
      'executionTime': executionTime,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Interface para estratégias de fallback
abstract class SearchFallbackStrategy {
  String get name;
  Future<SearchResult> execute(String query, SearchFilters? filters, int limit);
}

/// Fallback para query simples (sem filtros complexos)
class SimpleQueryFallbackStrategy implements SearchFallbackStrategy {
  @override
  String get name => 'SimpleQuery';

  @override
  Future<SearchResult> execute(
      String query, SearchFilters? filters, int limit) async {
    // Implementar busca simples sem índices complexos
    return SearchResult(
      profiles: [],
      totalResults: 0,
      hasMore: false,
      appliedFilters: null,
      fromCache: false,
    );
  }
}

/// Fallback para resultados em cache
class CachedResultsFallbackStrategy implements SearchFallbackStrategy {
  @override
  String get name => 'CachedResults';

  @override
  Future<SearchResult> execute(
      String query, SearchFilters? filters, int limit) async {
    // Tentar buscar resultados similares no cache
    return SearchResult(
      profiles: [],
      totalResults: 0,
      hasMore: false,
      appliedFilters: filters,
      fromCache: true,
    );
  }
}

/// Fallback com query limitada
class LimitedQueryFallbackStrategy implements SearchFallbackStrategy {
  @override
  String get name => 'LimitedQuery';

  @override
  Future<SearchResult> execute(
      String query, SearchFilters? filters, int limit) async {
    // Implementar busca com limite reduzido
    final reducedLimit = (limit * 0.5).toInt().clamp(1, 10);

    return SearchResult(
      profiles: [],
      totalResults: 0,
      hasMore: false,
      appliedFilters: filters,
      fromCache: false,
    );
  }
}

/// Fallback que retorna resultado vazio
class EmptyResultFallbackStrategy implements SearchFallbackStrategy {
  @override
  String get name => 'EmptyResult';

  @override
  Future<SearchResult> execute(
      String query, SearchFilters? filters, int limit) async {
    return SearchResult(
      profiles: [],
      totalResults: 0,
      hasMore: false,
      appliedFilters: filters,
      fromCache: false,
    );
  }
}
