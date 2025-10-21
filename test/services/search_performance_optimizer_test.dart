import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/search_performance_optimizer.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchPerformanceOptimizer', () {
    late SearchPerformanceOptimizer optimizer;

    setUp(() {
      optimizer = SearchPerformanceOptimizer.instance;
      optimizer.clearHistory();
    });

    test('should be singleton', () {
      final optimizer1 = SearchPerformanceOptimizer.instance;
      final optimizer2 = SearchPerformanceOptimizer.instance;
      
      expect(optimizer1, same(optimizer2));
    });

    test('should optimize search operation successfully', () async {
      final mockResult = SearchResult(
        profiles: [
          SpiritualProfileModel(
            id: '1',
            displayName: 'Test User',
          ),
        ],
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      final result = await optimizer.optimizeSearch(
        operationName: 'test_search',
        searchOperation: () async => mockResult,
        query: 'test query',
        limit: 20,
      );

      expect(result.profiles, hasLength(1));
      expect(result.profiles.first.displayName, equals('Test User'));
    });

    test('should truncate long queries', () async {
      final longQuery = 'a' * 200; // Query muito longa
      
      final mockResult = SearchResult(
        profiles: [],
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      await optimizer.optimizeSearch(
        operationName: 'long_query_test',
        searchOperation: () async => mockResult,
        query: longQuery,
        limit: 20,
      );

      // Verificar se a otimização foi aplicada através das estatísticas
      final stats = optimizer.getPerformanceStats();
      expect(stats['recentOptimizations'], isNotEmpty);
    });

    test('should reduce limit for slow operations', () async {
      // Simular operação lenta
      final mockResult = SearchResult(
        profiles: [],
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      // Primeira execução para estabelecer histórico
      await optimizer.optimizeSearch(
        operationName: 'slow_operation',
        searchOperation: () async {
          await Future.delayed(Duration(milliseconds: 3000)); // Simular lentidão
          return mockResult;
        },
        query: 'test',
        limit: 50,
      );

      // Segunda execução deve aplicar otimização
      await optimizer.optimizeSearch(
        operationName: 'slow_operation',
        searchOperation: () async => mockResult,
        query: 'test',
        limit: 50,
      );

      final stats = optimizer.getPerformanceStats();
      expect(stats['recentOptimizations'], isNotEmpty);
    });

    test('should simplify complex filters', () async {
      final complexFilters = SearchFilters(
        minAge: 25,
        maxAge: 35,
        city: 'São Paulo',
        state: 'SP',
        interests: ['tech', 'music', 'sports', 'travel', 'books'],
        isVerified: true,
        hasCompletedCourse: true,
      );

      final mockResult = SearchResult(
        profiles: [],
        hasMore: false,
        appliedFilters: complexFilters,
        fromCache: false,
      );

      await optimizer.optimizeSearch(
        operationName: 'complex_filter_test',
        searchOperation: () async => mockResult,
        query: 'test',
        filters: complexFilters,
        limit: 20,
      );

      final stats = optimizer.getPerformanceStats();
      expect(stats['recentOptimizations'], isNotEmpty);
    });

    test('should record performance metrics', () async {
      final mockResult = SearchResult(
        profiles: [
          SpiritualProfileModel(id: '1', displayName: 'User 1'),
          SpiritualProfileModel(id: '2', displayName: 'User 2'),
        ],
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      // Executar várias operações
      for (int i = 0; i < 5; i++) {
        await optimizer.optimizeSearch(
          operationName: 'metrics_test',
          searchOperation: () async => mockResult,
          query: 'test $i',
          limit: 20,
        );
      }

      final stats = optimizer.getPerformanceStats();
      
      expect(stats, containsKey('operationStats'));
      expect(stats['operationStats'], containsKey('metrics_test'));
      
      final operationStats = stats['operationStats']['metrics_test'];
      expect(operationStats['totalOperations'], equals(5));
      expect(operationStats['successfulOperations'], equals(5));
    });

    test('should handle operation failures', () async {
      var attemptCount = 0;
      
      try {
        await optimizer.optimizeSearch(
          operationName: 'failure_test',
          searchOperation: () async {
            attemptCount++;
            throw Exception('Test failure');
          },
          query: 'test',
          limit: 20,
        );
      } catch (e) {
        expect(e.toString(), contains('Test failure'));
      }

      expect(attemptCount, equals(1));
      
      final stats = optimizer.getPerformanceStats();
      expect(stats['operationStats'], containsKey('failure_test'));
      
      final operationStats = stats['operationStats']['failure_test'];
      expect(operationStats['failedOperations'], equals(1));
    });

    test('should provide global performance metrics', () async {
      final mockResult = SearchResult(
        profiles: [],
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      // Executar operações em diferentes operações
      await optimizer.optimizeSearch(
        operationName: 'operation_1',
        searchOperation: () async => mockResult,
        query: 'test1',
        limit: 20,
      );

      await optimizer.optimizeSearch(
        operationName: 'operation_2',
        searchOperation: () async => mockResult,
        query: 'test2',
        limit: 20,
      );

      final stats = optimizer.getPerformanceStats();
      
      expect(stats, containsKey('globalMetrics'));
      expect(stats['globalMetrics'], containsKey('averageExecutionTime'));
      expect(stats['globalMetrics'], containsKey('globalCacheHitRate'));
      expect(stats['globalMetrics'], containsKey('globalSuccessRate'));
    });

    test('should clear history correctly', () async {
      final mockResult = SearchResult(
        profiles: [],
        hasMore: false,
        appliedFilters: null,
        fromCache: false,
      );

      await optimizer.optimizeSearch(
        operationName: 'clear_test',
        searchOperation: () async => mockResult,
        query: 'test',
        limit: 20,
      );

      var stats = optimizer.getPerformanceStats();
      expect(stats['totalOperations'], greaterThan(0));

      optimizer.clearHistory();

      stats = optimizer.getPerformanceStats();
      expect(stats['totalOperations'], equals(0));
    });
  });

  group('PerformanceMetrics', () {
    test('should calculate metrics correctly', () {
      final metrics = PerformanceMetrics(operationName: 'test');
      
      // Registrar sucessos
      metrics.recordSuccess(
        executionTime: 1000,
        resultCount: 5,
        fromCache: false,
      );
      
      metrics.recordSuccess(
        executionTime: 2000,
        resultCount: 0,
        fromCache: true,
      );
      
      expect(metrics.totalOperations, equals(2));
      expect(metrics.successfulOperations, equals(2));
      expect(metrics.averageExecutionTime, equals(1500));
      expect(metrics.cacheHitRate, equals(0.5));
      expect(metrics.emptyResultRate, equals(0.5));
      expect(metrics.successRate, equals(1.0));
    });

    test('should handle failures correctly', () {
      final metrics = PerformanceMetrics(operationName: 'test');
      
      metrics.recordSuccess(
        executionTime: 1000,
        resultCount: 5,
        fromCache: false,
      );
      
      metrics.recordFailure(
        executionTime: 500,
        error: Exception('Test error'),
      );
      
      expect(metrics.totalOperations, equals(2));
      expect(metrics.successfulOperations, equals(1));
      expect(metrics.failedOperations, equals(1));
      expect(metrics.successRate, equals(0.5));
    });
  });
}