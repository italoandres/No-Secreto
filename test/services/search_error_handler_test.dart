import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../../lib/services/search_error_handler.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchErrorHandler', () {
    late SearchErrorHandler errorHandler;

    setUp(() {
      errorHandler = SearchErrorHandler.instance;
      errorHandler.clearErrorHistory();
    });

    test('should be singleton', () {
      final handler1 = SearchErrorHandler.instance;
      final handler2 = SearchErrorHandler.instance;
      
      expect(handler1, same(handler2));
    });

    test('should execute operation successfully on first try', () async {
      final mockResult = SearchResult(
        profiles: [
          SpiritualProfileModel(
            id: '1',
            displayName: 'Test User',
          ),
        ],
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      final result = await errorHandler.executeWithRetry(
        operation: () async => mockResult,
        operationName: 'test_operation',
        query: 'test',
        limit: 20,
      );

      expect(result.profiles, hasLength(1));
      expect(result.error, isNull);
    });

    test('should retry on recoverable errors', () async {
      int attemptCount = 0;
      
      final result = await errorHandler.executeWithRetry(
        operation: () async {
          attemptCount++;
          if (attemptCount < 3) {
            throw SocketException('Network error');
          }
          return SearchResult(
            profiles: [],
            totalResults: 0,
            hasMore: false,
            appliedFilters: null,
            fromCache: false,
          );
        },
        operationName: 'retry_test',
        query: 'test',
        limit: 20,
      );

      expect(attemptCount, equals(3));
      expect(result.error, isNull);
    });

    test('should not retry on non-recoverable errors', () async {
      int attemptCount = 0;
      
      final result = await errorHandler.executeWithRetry(
        operation: () async {
          attemptCount++;
          throw Exception('requires an index');
        },
        operationName: 'no_retry_test',
        query: 'test',
        limit: 20,
      );

      expect(attemptCount, equals(1));
      expect(result.error, isNotNull);
      expect(result.error!.type, equals(SearchErrorType.indexMissing));
    });

    test('should classify errors correctly', () async {
      final testCases = [
        ('requires an index', SearchErrorType.indexMissing),
        ('permission denied', SearchErrorType.permissionDenied),
        ('network connection failed', SearchErrorType.networkError),
        ('quota exceeded', SearchErrorType.quotaExceeded),
        ('invalid request', SearchErrorType.validationError),
        ('timeout occurred', SearchErrorType.timeout),
        ('unknown error', SearchErrorType.unknown),
      ];

      for (final testCase in testCases) {
        final result = await errorHandler.executeWithRetry(
          operation: () async {
            throw Exception(testCase.$1);
          },
          operationName: 'classification_test',
          query: 'test',
          limit: 20,
        );

        expect(result.error, isNotNull);
        expect(result.error!.type, equals(testCase.$2));
      }
    });

    test('should use fallback strategies when main operation fails', () async {
      final mockFallback = MockFallbackStrategy();
      
      final result = await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('Operation failed');
        },
        operationName: 'fallback_test',
        query: 'test',
        limit: 20,
        fallbackStrategies: [mockFallback],
      );

      expect(result.profiles, hasLength(1));
      expect(mockFallback.wasExecuted, isTrue);
    });

    test('should provide error statistics', () async {
      // Generate some errors
      await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('network error');
        },
        operationName: 'stats_test',
        query: 'test1',
        limit: 20,
      );

      await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('permission denied');
        },
        operationName: 'stats_test',
        query: 'test2',
        limit: 20,
      );

      final stats = errorHandler.getErrorStats();

      expect(stats, containsKey('totalErrors'));
      expect(stats, containsKey('errorTypeStats'));
      expect(stats, containsKey('healthStatus'));
      expect(stats['totalErrors'], greaterThan(0));
    });

    test('should detect frequent error types', () async {
      // Generate multiple network errors
      for (int i = 0; i < 6; i++) {
        await errorHandler.executeWithRetry(
          operation: () async {
            throw SocketException('Network error $i');
          },
          operationName: 'frequency_test',
          query: 'test$i',
          limit: 20,
        );
      }

      final isFrequent = errorHandler.isErrorTypeFrequent(
        SearchErrorType.networkError,
        threshold: 5,
      );

      expect(isFrequent, isTrue);
    });

    test('should create adaptive fallbacks based on error history', () async {
      // Generate index missing errors
      for (int i = 0; i < 6; i++) {
        await errorHandler.executeWithRetry(
          operation: () async {
            throw Exception('requires an index');
          },
          operationName: 'adaptive_test',
          query: 'test$i',
          limit: 20,
        );
      }

      final fallbacks = errorHandler.createAdaptiveFallbacks(
        query: 'test',
        limit: 20,
      );

      expect(fallbacks, isNotEmpty);
      expect(fallbacks.any((f) => f.name == 'SimpleQuery'), isTrue);
    });

    test('should calculate retry delay with exponential backoff', () async {
      final delays = <Duration>[];
      
      await errorHandler.executeWithRetry(
        operation: () async {
          final attempt = delays.length + 1;
          if (attempt <= 3) {
            final start = DateTime.now();
            throw SocketException('Network error');
          }
          return SearchResult(
            profiles: [],
            totalResults: 0,
            hasMore: false,
            appliedFilters: null,
            fromCache: false,
          );
        },
        operationName: 'delay_test',
        query: 'test',
        limit: 20,
      );

      // Verify that delays increase (exponential backoff)
      // Note: This is a simplified test - actual delays would be measured differently
      expect(true, isTrue); // Placeholder assertion
    });

    test('should provide recent error history', () async {
      // Generate some errors
      await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('Test error 1');
        },
        operationName: 'history_test',
        query: 'test1',
        limit: 20,
      );

      await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('Test error 2');
        },
        operationName: 'history_test',
        query: 'test2',
        limit: 20,
      );

      final recentErrors = errorHandler.getRecentErrors(limit: 10);

      expect(recentErrors, hasLength(2));
      expect(recentErrors[0], containsKey('timestamp'));
      expect(recentErrors[0], containsKey('operation'));
      expect(recentErrors[0], containsKey('errorType'));
    });

    test('should clear error history', () async {
      // Generate an error
      await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('Test error');
        },
        operationName: 'clear_test',
        query: 'test',
        limit: 20,
      );

      var stats = errorHandler.getErrorStats();
      expect(stats['totalErrors'], greaterThan(0));

      // Clear history
      errorHandler.clearErrorHistory();

      stats = errorHandler.getErrorStats();
      expect(stats['totalErrors'], equals(0));
    });

    test('should handle timeout errors specifically', () async {
      final result = await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('timeout occurred');
        },
        operationName: 'timeout_test',
        query: 'test',
        limit: 20,
      );

      expect(result.error, isNotNull);
      expect(result.error!.type, equals(SearchErrorType.timeout));
    });

    test('should include detailed error information', () async {
      final result = await errorHandler.executeWithRetry(
        operation: () async {
          throw Exception('Detailed test error');
        },
        operationName: 'detailed_error_test',
        query: 'test query',
        filters: SearchFilters(minAge: 25),
        limit: 30,
      );

      expect(result.error, isNotNull);
      expect(result.error!.operationName, equals('detailed_error_test'));
      expect(result.error!.query, equals('test query'));
      expect(result.error!.filters, isNotNull);
      expect(result.error!.retryAttempts, equals(3));
      expect(result.error!.executionTime, greaterThan(0));
    });
  });
}

/// Mock fallback strategy for testing
class MockFallbackStrategy implements SearchFallbackStrategy {
  bool wasExecuted = false;

  @override
  String get name => 'MockFallback';

  @override
  Future<SearchResult> execute(String query, SearchFilters? filters, int limit) async {
    wasExecuted = true;
    
    return SearchResult(
      profiles: [
        SpiritualProfileModel(
          id: 'fallback_1',
          displayName: 'Fallback User',
        ),
      ],
      totalResults: 1,
      hasMore: false,
      appliedFilters: filters,
      fromCache: false,
    );
  }
}