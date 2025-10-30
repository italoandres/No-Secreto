import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/services/match_retry_service.dart';

void main() {
  group('RetryConfig', () {
    testWidgets('deve ter configuração padrão válida', (tester) async {
      // Arrange & Act
      const config = RetryConfig();

      // Assert
      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(const Duration(seconds: 1)));
      expect(config.maxDelay, equals(const Duration(seconds: 30)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.exponentialBackoff, isTrue);
      expect(config.retryableExceptions, isEmpty);
    });

    testWidgets('deve ter configuração de rede válida', (tester) async {
      // Act
      const config = RetryConfig.network;

      // Assert
      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(const Duration(seconds: 2)));
      expect(config.maxDelay, equals(const Duration(seconds: 10)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.exponentialBackoff, isTrue);
    });

    testWidgets('deve ter configuração crítica válida', (tester) async {
      // Act
      const config = RetryConfig.critical;

      // Assert
      expect(config.maxAttempts, equals(5));
      expect(config.initialDelay, equals(const Duration(milliseconds: 500)));
      expect(config.maxDelay, equals(const Duration(seconds: 15)));
      expect(config.backoffMultiplier, equals(1.5));
      expect(config.exponentialBackoff, isTrue);
    });

    testWidgets('deve ter configuração rápida válida', (tester) async {
      // Act
      const config = RetryConfig.fast;

      // Assert
      expect(config.maxAttempts, equals(2));
      expect(config.initialDelay, equals(const Duration(milliseconds: 200)));
      expect(config.maxDelay, equals(const Duration(seconds: 2)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.exponentialBackoff, isFalse);
    });
  });

  group('RetryResult', () {
    testWidgets('deve criar resultado de sucesso', (tester) async {
      // Arrange & Act
      final result = RetryResult<String>(
        result: 'sucesso',
        success: true,
        attempts: 2,
        totalDuration: const Duration(seconds: 1),
      );

      // Assert
      expect(result.result, equals('sucesso'));
      expect(result.success, isTrue);
      expect(result.attempts, equals(2));
      expect(result.totalDuration, equals(const Duration(seconds: 1)));
      expect(result.lastError, isNull);
    });

    testWidgets('deve criar resultado de falha', (tester) async {
      // Arrange
      final error = Exception('Erro de teste');

      // Act
      final result = RetryResult<String>(
        success: false,
        attempts: 3,
        totalDuration: const Duration(seconds: 5),
        lastError: error,
      );

      // Assert
      expect(result.result, isNull);
      expect(result.success, isFalse);
      expect(result.attempts, equals(3));
      expect(result.totalDuration, equals(const Duration(seconds: 5)));
      expect(result.lastError, equals(error));
    });

    testWidgets('deve ter toString informativo', (tester) async {
      // Arrange
      final result = RetryResult<String>(
        success: true,
        attempts: 2,
        totalDuration: const Duration(milliseconds: 1500),
      );

      // Act
      final string = result.toString();

      // Assert
      expect(string, contains('RetryResult'));
      expect(string, contains('success: true'));
      expect(string, contains('attempts: 2'));
      expect(string, contains('1500ms'));
    });
  });

  group('MatchRetryService', () {
    setUp(() {
      MatchRetryService.resetAllStats();
    });

    testWidgets('deve executar operação com sucesso na primeira tentativa', (tester) async {
      // Arrange
      int attempts = 0;
      Future<String> operation() async {
        attempts++;
        return 'sucesso';
      }

      // Act
      final result = await MatchRetryService.executeWithRetry(
        operation,
        config: RetryConfig.fast,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.result, equals('sucesso'));
      expect(result.attempts, equals(1));
      expect(attempts, equals(1));
      expect(result.lastError, isNull);
    });

    testWidgets('deve tentar novamente após falha', (tester) async {
      // Arrange
      int attempts = 0;
      Future<String> operation() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Network error');
        }
        return 'sucesso';
      }

      // Act
      final result = await MatchRetryService.executeWithRetry(
        operation,
        config: RetryConfig.fast,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.result, equals('sucesso'));
      expect(result.attempts, equals(2));
      expect(attempts, equals(2));
    });

    testWidgets('deve falhar após esgotar tentativas', (tester) async {
      // Arrange
      int attempts = 0;
      Future<String> operation() async {
        attempts++;
        throw Exception('Persistent error');
      }

      // Act
      final result = await MatchRetryService.executeWithRetry(
        operation,
        config: RetryConfig.fast,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.result, isNull);
      expect(result.attempts, equals(2)); // maxAttempts do RetryConfig.fast
      expect(attempts, equals(2));
      expect(result.lastError, isNotNull);
    });

    testWidgets('deve não tentar novamente para erros não retentáveis', (tester) async {
      // Arrange
      int attempts = 0;
      Future<String> operation() async {
        attempts++;
        throw Exception('Permission denied');
      }

      // Act
      final result = await MatchRetryService.executeWithRetry(
        operation,
        config: RetryConfig.fast,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.attempts, equals(1)); // Não deve tentar novamente
      expect(attempts, equals(1));
    });

    testWidgets('deve usar função shouldRetry personalizada', (tester) async {
      // Arrange
      int attempts = 0;
      Future<String> operation() async {
        attempts++;
        throw Exception('Custom error');
      }

      bool shouldRetry(Exception error) {
        return error.toString().contains('Custom');
      }

      // Act
      final result = await MatchRetryService.executeWithRetry(
        operation,
        config: RetryConfig.fast,
        shouldRetry: shouldRetry,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.attempts, equals(2)); // Deve tentar novamente
      expect(attempts, equals(2));
    });

    testWidgets('deve executar com retry e tratamento de erro', (tester) async {
      // Arrange
      Future<String> operation() async {
        throw Exception('Network error');
      }

      // Act
      final result = await MatchRetryService.executeWithRetryAndErrorHandling(
        operation,
        config: RetryConfig.fast,
        showErrorSnackbar: false,
      );

      // Assert
      expect(result, isNull); // Deve retornar null em caso de falha
    });

    testWidgets('deve detectar falhas frequentes', (tester) async {
      // Arrange
      const operationName = 'test_operation';
      
      // Simular múltiplas falhas
      for (int i = 0; i < 4; i++) {
        await MatchRetryService.executeWithRetry(
          () => throw Exception('Error $i'),
          config: RetryConfig.fast,
          operationName: operationName,
        );
      }

      // Act
      final hasFrequent = MatchRetryService.hasFrequentFailures(operationName);

      // Assert
      expect(hasFrequent, isTrue);
    });

    testWidgets('deve retornar estatísticas válidas', (tester) async {
      // Arrange
      await MatchRetryService.executeWithRetry(
        () => throw Exception('Network error'),
        config: RetryConfig.fast,
        operationName: 'test_op_1',
      );

      await MatchRetryService.executeWithRetry(
        () => throw Exception('Timeout'),
        config: RetryConfig.fast,
        operationName: 'test_op_2',
      );

      // Act
      final stats = MatchRetryService.getRetryStats();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['totalOperations'], equals(2));
      expect(stats['recentFailures'], equals(2));
      expect(stats['operationsWithFailures'], isA<Map<String, int>>());
      expect(stats['averageFailures'], greaterThan(0));
    });

    testWidgets('deve resetar falhas para operação específica', (tester) async {
      // Arrange
      const operationName = 'test_operation';
      await MatchRetryService.executeWithRetry(
        () => throw Exception('Error'),
        config: RetryConfig.fast,
        operationName: operationName,
      );

      // Act
      MatchRetryService.resetFailures(operationName);

      // Assert
      final hasFrequent = MatchRetryService.hasFrequentFailures(operationName);
      expect(hasFrequent, isFalse);
    });

    testWidgets('deve limpar estatísticas antigas', (tester) async {
      // Arrange
      await MatchRetryService.executeWithRetry(
        () => throw Exception('Error'),
        config: RetryConfig.fast,
        operationName: 'old_operation',
      );

      // Act
      MatchRetryService.cleanupOldStats();

      // Assert - Não deve falhar
      expect(() => MatchRetryService.cleanupOldStats(), returnsNormally);
    });

    testWidgets('deve resetar todas as estatísticas', (tester) async {
      // Arrange
      await MatchRetryService.executeWithRetry(
        () => throw Exception('Error'),
        config: RetryConfig.fast,
        operationName: 'test_operation',
      );

      // Act
      MatchRetryService.resetAllStats();

      // Assert
      final stats = MatchRetryService.getRetryStats();
      expect(stats['totalOperations'], equals(0));
      expect(stats['recentFailures'], equals(0));
    });
  });
}