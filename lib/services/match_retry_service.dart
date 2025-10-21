import 'dart:async';
import 'dart:math';
import '../utils/enhanced_logger.dart';
import 'match_error_handler.dart';
import 'match_loading_manager.dart';

/// Configuração para retry de operações
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool exponentialBackoff;
  final List<Type> retryableExceptions;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.exponentialBackoff = true,
    this.retryableExceptions = const [],
  });

  /// Configuração padrão para operações de rede
  static const RetryConfig network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
    exponentialBackoff: true,
  );

  /// Configuração para operações críticas
  static const RetryConfig critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 15),
    backoffMultiplier: 1.5,
    exponentialBackoff: true,
  );

  /// Configuração para operações rápidas
  static const RetryConfig fast = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    exponentialBackoff: false,
  );
}

/// Resultado de uma operação com retry
class RetryResult<T> {
  final T? result;
  final bool success;
  final int attempts;
  final Duration totalDuration;
  final Exception? lastError;

  RetryResult({
    this.result,
    required this.success,
    required this.attempts,
    required this.totalDuration,
    this.lastError,
  });

  @override
  String toString() {
    return 'RetryResult(success: $success, attempts: $attempts, duration: ${totalDuration.inMilliseconds}ms)';
  }
}

/// Serviço para retry automático de operações
class MatchRetryService {
  static final Map<String, DateTime> _lastRetryTimes = {};
  static final Map<String, int> _consecutiveFailures = {};

  /// Executar operação com retry automático
  static Future<RetryResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
    LoadingType? loadingType,
    bool Function(Exception)? shouldRetry,
  }) async {
    final startTime = DateTime.now();
    final operationId = operationName ?? 'operation_${DateTime.now().millisecondsSinceEpoch}';
    
    Exception? lastError;
    int attempts = 0;

    // Iniciar loading se especificado
    if (loadingType != null) {
      MatchLoadingManager.instance.startLoading(
        loadingType,
        message: 'Tentativa ${attempts + 1}/${config.maxAttempts}...',
      );
    }

    for (attempts = 1; attempts <= config.maxAttempts; attempts++) {
      try {
        EnhancedLogger.debug(
          'Executing $operationId - Attempt $attempts/${config.maxAttempts}',
          tag: 'MATCH_RETRY',
        );

        // Atualizar mensagem de loading
        if (loadingType != null && attempts > 1) {
          MatchLoadingManager.instance.updateLoadingMessage(
            loadingType,
            'Tentativa $attempts/${config.maxAttempts}...',
          );
        }

        final result = await operation();
        
        // Sucesso - limpar falhas consecutivas
        _consecutiveFailures.remove(operationId);
        
        // Parar loading
        if (loadingType != null) {
          MatchLoadingManager.instance.stopLoading(loadingType);
        }

        final duration = DateTime.now().difference(startTime);
        
        EnhancedLogger.info(
          'Operation $operationId succeeded on attempt $attempts (${duration.inMilliseconds}ms)',
          tag: 'MATCH_RETRY',
        );

        return RetryResult<T>(
          result: result,
          success: true,
          attempts: attempts,
          totalDuration: duration,
        );

      } catch (error) {
        lastError = error is Exception ? error : Exception(error.toString());
        
        EnhancedLogger.warning(
          'Operation $operationId failed on attempt $attempts: $error',
          tag: 'MATCH_RETRY',
        );

        // Verificar se deve tentar novamente
        final shouldRetryOperation = shouldRetry?.call(lastError) ?? 
                                   _shouldRetryByDefault(lastError);

        if (attempts >= config.maxAttempts || !shouldRetryOperation) {
          break;
        }

        // Calcular delay para próxima tentativa
        final delay = _calculateDelay(attempts, config);
        
        EnhancedLogger.debug(
          'Retrying $operationId in ${delay.inMilliseconds}ms',
          tag: 'MATCH_RETRY',
        );

        await Future.delayed(delay);
      }
    }

    // Falha após todas as tentativas
    _consecutiveFailures[operationId] = (_consecutiveFailures[operationId] ?? 0) + 1;
    _lastRetryTimes[operationId] = DateTime.now();

    // Parar loading
    if (loadingType != null) {
      MatchLoadingManager.instance.stopLoading(loadingType);
    }

    final duration = DateTime.now().difference(startTime);
    
    EnhancedLogger.error(
      'Operation $operationId failed after $attempts attempts (${duration.inMilliseconds}ms) - ${lastError.toString()}',
      tag: 'MATCH_RETRY',
    );

    return RetryResult<T>(
      success: false,
      attempts: attempts,
      totalDuration: duration,
      lastError: lastError,
    );
  }

  /// Calcular delay para próxima tentativa
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    if (!config.exponentialBackoff) {
      return config.initialDelay;
    }

    final delay = config.initialDelay.inMilliseconds * 
                  pow(config.backoffMultiplier, attempt - 1);
    
    final clampedDelay = delay.clamp(
      config.initialDelay.inMilliseconds.toDouble(),
      config.maxDelay.inMilliseconds.toDouble(),
    );

    // Adicionar jitter para evitar thundering herd
    final jitter = Random().nextDouble() * 0.1 * clampedDelay;
    
    return Duration(milliseconds: (clampedDelay + jitter).round());
  }

  /// Verificar se deve tentar novamente baseado no tipo de erro
  static bool _shouldRetryByDefault(Exception error) {
    final errorMessage = error.toString().toLowerCase();
    
    // Não tentar novamente para estes erros
    final nonRetryableErrors = [
      'permission',
      'denied',
      'unauthorized',
      'forbidden',
      'not found',
      'expired',
      'validation',
      'invalid',
    ];

    for (final nonRetryable in nonRetryableErrors) {
      if (errorMessage.contains(nonRetryable)) {
        return false;
      }
    }

    // Tentar novamente para erros de rede/temporários
    final retryableErrors = [
      'network',
      'connection',
      'timeout',
      'unavailable',
      'server',
      'internal',
    ];

    for (final retryable in retryableErrors) {
      if (errorMessage.contains(retryable)) {
        return true;
      }
    }

    // Por padrão, tentar novamente
    return true;
  }

  /// Executar operação com retry e tratamento de erro automático
  static Future<T?> executeWithRetryAndErrorHandling<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
    LoadingType? loadingType,
    String? context,
    bool showErrorSnackbar = true,
    bool Function(Exception)? shouldRetry,
  }) async {
    final result = await executeWithRetry<T>(
      operation,
      config: config,
      operationName: operationName,
      loadingType: loadingType,
      shouldRetry: shouldRetry,
    );

    if (result.success) {
      return result.result;
    }

    // Tratar erro automaticamente
    if (result.lastError != null) {
      MatchErrorHandler.handleError(
        result.lastError!,
        context: context ?? operationName,
        showSnackbar: showErrorSnackbar,
        onRetry: () => executeWithRetryAndErrorHandling<T>(
          operation,
          config: config,
          operationName: operationName,
          loadingType: loadingType,
          context: context,
          showErrorSnackbar: showErrorSnackbar,
          shouldRetry: shouldRetry,
        ),
      );
    }

    return null;
  }

  /// Verificar se operação teve muitas falhas recentes
  static bool hasFrequentFailures(String operationName, {
    Duration timeWindow = const Duration(minutes: 5),
    int threshold = 3,
  }) {
    final lastFailure = _lastRetryTimes[operationName];
    if (lastFailure == null) return false;

    final cutoff = DateTime.now().subtract(timeWindow);
    if (lastFailure.isBefore(cutoff)) return false;

    final failures = _consecutiveFailures[operationName] ?? 0;
    return failures >= threshold;
  }

  /// Obter estatísticas de retry
  static Map<String, dynamic> getRetryStats() {
    final now = DateTime.now();
    final recentFailures = <String, int>{};
    final oldFailures = <String>[];

    for (final entry in _lastRetryTimes.entries) {
      final age = now.difference(entry.value);
      if (age.inHours < 1) {
        recentFailures[entry.key] = _consecutiveFailures[entry.key] ?? 0;
      } else if (age.inDays > 7) {
        oldFailures.add(entry.key);
      }
    }

    // Limpar falhas antigas
    for (final old in oldFailures) {
      _lastRetryTimes.remove(old);
      _consecutiveFailures.remove(old);
    }

    return {
      'totalOperations': _lastRetryTimes.length,
      'recentFailures': recentFailures.length,
      'operationsWithFailures': recentFailures,
      'averageFailures': recentFailures.isNotEmpty 
          ? recentFailures.values.reduce((a, b) => a + b) / recentFailures.length
          : 0,
    };
  }

  /// Limpar estatísticas antigas
  static void cleanupOldStats() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toRemove = <String>[];

    for (final entry in _lastRetryTimes.entries) {
      if (entry.value.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      _lastRetryTimes.remove(key);
      _consecutiveFailures.remove(key);
    }

    if (toRemove.isNotEmpty) {
      EnhancedLogger.debug(
        'Cleaned up ${toRemove.length} old retry stats',
        tag: 'MATCH_RETRY',
      );
    }
  }

  /// Resetar falhas consecutivas para uma operação
  static void resetFailures(String operationName) {
    _consecutiveFailures.remove(operationName);
    _lastRetryTimes.remove(operationName);
  }

  /// Resetar todas as estatísticas
  static void resetAllStats() {
    _consecutiveFailures.clear();
    _lastRetryTimes.clear();
    EnhancedLogger.debug('All retry stats reset', tag: 'MATCH_RETRY');
  }
}