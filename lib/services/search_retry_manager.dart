import 'dart:async';
import 'dart:math' as math;
import '../models/search_filters.dart';
import '../models/search_result.dart';
import '../utils/enhanced_logger.dart';
import 'search_error_handler.dart';
import 'search_logger.dart';

/// Gerenciador avançado de retry para operações de busca
/// com estratégias adaptativas e circuit breaker
class SearchRetryManager {
  static SearchRetryManager? _instance;
  static SearchRetryManager get instance => _instance ??= SearchRetryManager._();
  
  SearchRetryManager._();

  /// Circuit breakers por operação
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  
  /// Configurações de retry por tipo de erro
  final Map<SearchErrorType, RetryConfig> _retryConfigs = {
    SearchErrorType.networkError: RetryConfig(
      maxAttempts: 5,
      baseDelay: Duration(milliseconds: 500),
      maxDelay: Duration(seconds: 30),
      backoffMultiplier: 2.0,
      jitterFactor: 0.25,
    ),
    SearchErrorType.timeout: RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 15),
      backoffMultiplier: 1.5,
      jitterFactor: 0.1,
    ),
    SearchErrorType.quotaExceeded: RetryConfig(
      maxAttempts: 2,
      baseDelay: Duration(seconds: 5),
      maxDelay: Duration(minutes: 2),
      backoffMultiplier: 3.0,
      jitterFactor: 0.5,
    ),
    SearchErrorType.indexMissing: RetryConfig(
      maxAttempts: 1, // Não retry para índices faltando
      baseDelay: Duration.zero,
      maxDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFactor: 0.0,
    ),
    SearchErrorType.permissionDenied: RetryConfig(
      maxAttempts: 1, // Não retry para permissão negada
      baseDelay: Duration.zero,
      maxDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFactor: 0.0,
    ),
    SearchErrorType.validationError: RetryConfig(
      maxAttempts: 1, // Não retry para erros de validação
      baseDelay: Duration.zero,
      maxDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFactor: 0.0,
    ),
  };

  /// Executa operação com retry inteligente e circuit breaker
  Future<SearchResult> executeWithRetry({
    required String operationName,
    required Future<SearchResult> Function() operation,
    required String query,
    SearchFilters? filters,
    int limit = 20,
    RetryConfig? customConfig,
    bool useCircuitBreaker = true,
  }) async {
    final logger = SearchLogger.instance;
    final operationId = logger.startSearchOperation(
      operationName: operationName,
      query: query,
      filters: filters,
      limit: limit,
      additionalContext: {
        'useCircuitBreaker': useCircuitBreaker,
        'hasCustomConfig': customConfig != null,
      },
    );

    // Verificar circuit breaker
    if (useCircuitBreaker) {
      final circuitBreaker = _getCircuitBreaker(operationName);
      if (circuitBreaker.state == CircuitBreakerState.open) {
        final error = Exception('Circuit breaker is open for operation: $operationName');
        logger.completeSearchOperation(
          operationId: operationId,
          error: error,
          additionalData: {'circuitBreakerState': 'open'},
        );
        
        return SearchResult(
          profiles: [],
          totalResults: 0,
          hasMore: false,
          appliedFilters: filters,
          fromCache: false,
          error: SearchError(
            type: SearchErrorType.unknown,
            message: 'Service temporarily unavailable',
            originalException: error,
            operationName: operationName,
            query: query,
            filters: filters,
            retryAttempts: 0,
            executionTime: 0,
          ),
        );
      }
    }

    SearchResult? lastResult;
    Exception? lastException;
    int totalAttempts = 0;
    final startTime = DateTime.now();

    // Tentar operação com retry baseado no tipo de erro
    while (totalAttempts < 10) { // Limite absoluto de segurança
      totalAttempts++;
      
      try {
        logger.logSearchEvent(
          operationId: operationId,
          eventType: 'attempt_start',
          message: 'Starting attempt $totalAttempts',
          data: {'attempt': totalAttempts},
        );

        final result = await operation();
        
        // Sucesso - registrar no circuit breaker e retornar
        if (useCircuitBreaker) {
          _getCircuitBreaker(operationName).recordSuccess();
        }
        
        logger.completeSearchOperation(
          operationId: operationId,
          result: result,
          retryAttempts: totalAttempts - 1,
          additionalData: {
            'finalAttempt': totalAttempts,
            'circuitBreakerState': useCircuitBreaker ? 
                _getCircuitBreaker(operationName).state.toString() : 'disabled',
          },
        );
        
        return result;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorType = SearchErrorHandler.instance._classifyError(lastException);
        
        logger.logSearchEvent(
          operationId: operationId,
          eventType: 'attempt_failed',
          message: 'Attempt $totalAttempts failed: ${lastException.toString()}',
          data: {
            'attempt': totalAttempts,
            'errorType': errorType.toString(),
            'error': lastException.toString(),
          },
        );

        // Registrar falha no circuit breaker
        if (useCircuitBreaker) {
          _getCircuitBreaker(operationName).recordFailure();
        }

        // Obter configuração de retry para este tipo de erro
        final config = customConfig ?? _retryConfigs[errorType] ?? _retryConfigs[SearchErrorType.unknown]!;
        
        // Verificar se deve tentar novamente
        if (totalAttempts >= config.maxAttempts) {
          logger.logSearchEvent(
            operationId: operationId,
            eventType: 'retry_exhausted',
            message: 'Maximum retry attempts reached for error type: $errorType',
            data: {
              'totalAttempts': totalAttempts,
              'maxAttempts': config.maxAttempts,
              'errorType': errorType.toString(),
            },
          );
          break;
        }

        // Calcular delay para próxima tentativa
        final delay = _calculateDelay(totalAttempts, config, errorType);
        
        logger.logSearchEvent(
          operationId: operationId,
          eventType: 'retry_scheduled',
          message: 'Scheduling retry attempt ${totalAttempts + 1} after ${delay.inMilliseconds}ms',
          data: {
            'nextAttempt': totalAttempts + 1,
            'delayMs': delay.inMilliseconds,
            'errorType': errorType.toString(),
          },
        );

        await Future.delayed(delay);
      }
    }

    // Todas as tentativas falharam
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;
    
    logger.completeSearchOperation(
      operationId: operationId,
      error: lastException,
      retryAttempts: totalAttempts,
      additionalData: {
        'totalAttempts': totalAttempts,
        'finalError': lastException?.toString(),
        'circuitBreakerState': useCircuitBreaker ? 
            _getCircuitBreaker(operationName).state.toString() : 'disabled',
      },
    );

    return SearchResult(
      profiles: [],
      totalResults: 0,
      hasMore: false,
      appliedFilters: filters,
      fromCache: false,
      error: SearchError(
        type: SearchErrorHandler.instance._classifyError(lastException!),
        message: lastException.toString(),
        originalException: lastException,
        operationName: operationName,
        query: query,
        filters: filters,
        retryAttempts: totalAttempts,
        executionTime: executionTime,
      ),
    );
  }

  /// Calcula delay para retry com backoff exponencial e jitter
  Duration _calculateDelay(int attempt, RetryConfig config, SearchErrorType errorType) {
    if (config.baseDelay == Duration.zero) {
      return Duration.zero;
    }

    // Backoff exponencial
    final exponentialDelay = config.baseDelay.inMilliseconds * 
        math.pow(config.backoffMultiplier, attempt - 1);
    
    // Aplicar jitter para evitar thundering herd
    final jitterRange = exponentialDelay * config.jitterFactor;
    final jitter = (math.Random().nextDouble() - 0.5) * 2 * jitterRange;
    
    final totalDelayMs = (exponentialDelay + jitter).clamp(
      config.baseDelay.inMilliseconds.toDouble(),
      config.maxDelay.inMilliseconds.toDouble(),
    );

    return Duration(milliseconds: totalDelayMs.round());
  }

  /// Obtém ou cria circuit breaker para uma operação
  CircuitBreaker _getCircuitBreaker(String operationName) {
    return _circuitBreakers.putIfAbsent(
      operationName,
      () => CircuitBreaker(
        operationName: operationName,
        failureThreshold: 5,
        recoveryTimeout: Duration(minutes: 2),
        halfOpenMaxCalls: 3,
      ),
    );
  }

  /// Obtém estatísticas de retry
  Map<String, dynamic> getRetryStats() {
    final circuitBreakerStats = <String, Map<String, dynamic>>{};
    
    _circuitBreakers.forEach((operation, breaker) {
      circuitBreakerStats[operation] = breaker.getStats();
    });

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'circuitBreakers': circuitBreakerStats,
      'retryConfigs': _retryConfigs.map((errorType, config) => 
          MapEntry(errorType.toString(), config.toJson())),
      'totalCircuitBreakers': _circuitBreakers.length,
    };
  }

  /// Redefine circuit breaker específico
  void resetCircuitBreaker(String operationName) {
    final breaker = _circuitBreakers[operationName];
    if (breaker != null) {
      breaker.reset();
      
      EnhancedLogger.info('Circuit breaker reset', 
        tag: 'SEARCH_RETRY_MANAGER',
        data: {'operationName': operationName}
      );
    }
  }

  /// Redefine todos os circuit breakers
  void resetAllCircuitBreakers() {
    _circuitBreakers.values.forEach((breaker) => breaker.reset());
    
    EnhancedLogger.info('All circuit breakers reset', 
      tag: 'SEARCH_RETRY_MANAGER',
      data: {'count': _circuitBreakers.length}
    );
  }

  /// Atualiza configuração de retry para um tipo de erro
  void updateRetryConfig(SearchErrorType errorType, RetryConfig config) {
    _retryConfigs[errorType] = config;
    
    EnhancedLogger.info('Retry configuration updated', 
      tag: 'SEARCH_RETRY_MANAGER',
      data: {
        'errorType': errorType.toString(),
        'config': config.toJson(),
      }
    );
  }
}

/// Configuração de retry para um tipo específico de erro
class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final double jitterFactor;

  const RetryConfig({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
    required this.jitterFactor,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxAttempts': maxAttempts,
      'baseDelayMs': baseDelay.inMilliseconds,
      'maxDelayMs': maxDelay.inMilliseconds,
      'backoffMultiplier': backoffMultiplier,
      'jitterFactor': jitterFactor,
    };
  }
}

/// Circuit breaker para prevenir cascata de falhas
class CircuitBreaker {
  final String operationName;
  final int failureThreshold;
  final Duration recoveryTimeout;
  final int halfOpenMaxCalls;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  int _halfOpenCalls = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastStateChange;

  CircuitBreaker({
    required this.operationName,
    required this.failureThreshold,
    required this.recoveryTimeout,
    required this.halfOpenMaxCalls,
  }) {
    _lastStateChange = DateTime.now();
  }

  CircuitBreakerState get state {
    _updateState();
    return _state;
  }

  void recordSuccess() {
    _successCount++;
    
    if (_state == CircuitBreakerState.halfOpen) {
      _halfOpenCalls++;
      
      if (_halfOpenCalls >= halfOpenMaxCalls) {
        _setState(CircuitBreakerState.closed);
        _failureCount = 0;
        _halfOpenCalls = 0;
      }
    } else if (_state == CircuitBreakerState.closed) {
      _failureCount = 0; // Reset failure count on success
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_state == CircuitBreakerState.closed && _failureCount >= failureThreshold) {
      _setState(CircuitBreakerState.open);
    } else if (_state == CircuitBreakerState.halfOpen) {
      _setState(CircuitBreakerState.open);
      _halfOpenCalls = 0;
    }
  }

  void reset() {
    _setState(CircuitBreakerState.closed);
    _failureCount = 0;
    _successCount = 0;
    _halfOpenCalls = 0;
    _lastFailureTime = null;
  }

  void _updateState() {
    if (_state == CircuitBreakerState.open && _lastFailureTime != null) {
      final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
      
      if (timeSinceLastFailure >= recoveryTimeout) {
        _setState(CircuitBreakerState.halfOpen);
        _halfOpenCalls = 0;
      }
    }
  }

  void _setState(CircuitBreakerState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _lastStateChange = DateTime.now();
      
      EnhancedLogger.info('Circuit breaker state changed', 
        tag: 'CIRCUIT_BREAKER',
        data: {
          'operationName': operationName,
          'oldState': oldState.toString(),
          'newState': newState.toString(),
          'failureCount': _failureCount,
          'successCount': _successCount,
        }
      );
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'operationName': operationName,
      'state': _state.toString(),
      'failureCount': _failureCount,
      'successCount': _successCount,
      'halfOpenCalls': _halfOpenCalls,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'lastStateChange': _lastStateChange?.toIso8601String(),
      'configuration': {
        'failureThreshold': failureThreshold,
        'recoveryTimeoutMs': recoveryTimeout.inMilliseconds,
        'halfOpenMaxCalls': halfOpenMaxCalls,
      },
    };
  }
}

/// Estados do circuit breaker
enum CircuitBreakerState {
  closed,   // Funcionando normalmente
  open,     // Bloqueando chamadas devido a falhas
  halfOpen, // Testando se o serviço se recuperou
}