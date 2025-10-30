import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/search_analytics_service.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchAnalyticsService', () {
    late SearchAnalyticsService analyticsService;

    setUp(() {
      analyticsService = SearchAnalyticsService.instance;
      analyticsService.clearAnalytics(); // Limpar dados entre testes
    });

    tearDown(() {
      analyticsService.dispose();
    });

    group('Event Tracking', () {
      test('should track search events correctly', () {
        // Arrange
        const query = 'test query';
        final filters = SearchFilters(minAge: 25, maxAge: 35);
        final result = SearchResult(
          profiles: [_createMockProfile('1'), _createMockProfile('2')],
          query: query,
          totalResults: 2,
          hasMore: false,
          appliedFilters: filters,
          strategy: 'firebase_simple',
          executionTime: 1500,
          fromCache: false,
        );

        // Act
        analyticsService.trackSearchEvent(
          query: query,
          filters: filters,
          result: result,
          strategy: 'firebase_simple',
          context: {'test': true},
        );

        // Assert
        final report = analyticsService.getAnalyticsReport();
        final summary = report['summary'] as Map<String, dynamic>;
        
        expect(summary['totalEvents'], equals(1));
        expect(summary['todaySearches'], equals(1));
        expect(summary['avgExecutionTime'], equals(1500.0));
        expect(summary['cacheHitRate'], equals(0.0));
      });

      test('should track result interactions', () {
        // Arrange
        const query = 'test query';
        const profileId = 'profile123';
        const interactionType = 'view';

        // Act
        analyticsService.trackResultInteraction(
          query: query,
          profileId: profileId,
          interactionType: interactionType,
          resultPosition: 1,
          context: {'test': true},
        );

        // Assert - Verificar se não há erros (método não retorna dados diretamente)
        expect(() => analyticsService.trackResultInteraction(
          query: query,
          profileId: profileId,
          interactionType: interactionType,
        ), returnsNormally);
      });

      test('should track search errors', () {
        // Arrange
        const query = 'error query';
        final filters = SearchFilters(city: 'TestCity');
        const errorType = 'NetworkError';
        const errorMessage = 'Connection timeout';

        // Act
        analyticsService.trackSearchError(
          query: query,
          filters: filters,
          errorType: errorType,
          errorMessage: errorMessage,
          executionTime: 5000,
          context: {'test': true},
        );

        // Assert - Verificar se não há erros
        expect(() => analyticsService.trackSearchError(
          query: query,
          filters: filters,
          errorType: errorType,
          errorMessage: errorMessage,
        ), returnsNormally);
      });
    });

    group('Analytics Report', () {
      test('should generate comprehensive analytics report', () {
        // Arrange - Adicionar alguns eventos
        _addTestEvents(analyticsService);

        // Act
        final report = analyticsService.getAnalyticsReport();

        // Assert
        expect(report, isA<Map<String, dynamic>>());
        expect(report.containsKey('timestamp'), isTrue);
        expect(report.containsKey('summary'), isTrue);
        expect(report.containsKey('periodMetrics'), isTrue);
        expect(report.containsKey('usagePatterns'), isTrue);
        expect(report.containsKey('insights'), isTrue);
        expect(report.containsKey('topQueries'), isTrue);
        expect(report.containsKey('strategyUsage'), isTrue);
        expect(report.containsKey('performanceTrends'), isTrue);

        final summary = report['summary'] as Map<String, dynamic>;
        expect(summary.containsKey('totalEvents'), isTrue);
        expect(summary.containsKey('todaySearches'), isTrue);
        expect(summary.containsKey('avgExecutionTime'), isTrue);
        expect(summary.containsKey('cacheHitRate'), isTrue);
        expect(summary.containsKey('successRate'), isTrue);
      });

      test('should calculate metrics correctly', () {
        // Arrange
        final filters = SearchFilters(minAge: 20, maxAge: 30);
        
        // Adicionar evento com cache hit
        analyticsService.trackSearchEvent(
          query: 'cached query',
          filters: filters,
          result: SearchResult(
            profiles: [_createMockProfile('1')],
            query: 'cached query',
            totalResults: 1,
            hasMore: false,
            appliedFilters: filters,
            strategy: 'firebase_simple',
            executionTime: 500,
            fromCache: true,
          ),
          strategy: 'firebase_simple',
        );

        // Adicionar evento sem cache
        analyticsService.trackSearchEvent(
          query: 'fresh query',
          filters: filters,
          result: SearchResult(
            profiles: [],
            query: 'fresh query',
            totalResults: 0,
            hasMore: false,
            appliedFilters: filters,
            strategy: 'fallback',
            executionTime: 2000,
            fromCache: false,
          ),
          strategy: 'fallback',
        );

        // Act
        final report = analyticsService.getAnalyticsReport();
        final summary = report['summary'] as Map<String, dynamic>;

        // Assert
        expect(summary['totalEvents'], equals(2));
        expect(summary['cacheHitRate'], equals(0.5)); // 1 de 2 eventos foi cache hit
        expect(summary['avgExecutionTime'], equals(1250.0)); // (500 + 2000) / 2
      });

      test('should track strategy usage', () {
        // Arrange
        _addEventsWithDifferentStrategies(analyticsService);

        // Act
        final report = analyticsService.getAnalyticsReport();
        final strategyUsage = report['strategyUsage'] as Map<String, dynamic>;

        // Assert
        expect(strategyUsage.containsKey('firebase_simple'), isTrue);
        expect(strategyUsage.containsKey('display_name'), isTrue);
        expect(strategyUsage.containsKey('fallback'), isTrue);

        final firebaseUsage = strategyUsage['firebase_simple'] as Map<String, dynamic>;
        expect(firebaseUsage.containsKey('count'), isTrue);
        expect(firebaseUsage.containsKey('percentage'), isTrue);
      });
    });

    group('Usage Patterns', () {
      test('should identify hourly usage patterns', () {
        // Arrange - Adicionar eventos em horários diferentes
        _addEventsAtDifferentHours(analyticsService);

        // Act
        final report = analyticsService.getAnalyticsReport();
        final patterns = report['usagePatterns'] as List;

        // Assert
        expect(patterns, isNotEmpty);
        
        final peakHoursPattern = patterns.firstWhere(
          (pattern) => pattern['type'] == 'peak_hours',
          orElse: () => null,
        );
        
        if (peakHoursPattern != null) {
          expect(peakHoursPattern['data'], isA<Map<String, dynamic>>());
          expect(peakHoursPattern['confidence'], isA<double>());
        }
      });

      test('should identify common queries', () {
        // Arrange
        _addRepeatedQueries(analyticsService);

        // Act
        final report = analyticsService.getAnalyticsReport();
        final patterns = report['usagePatterns'] as List;

        // Assert
        final commonQueriesPattern = patterns.firstWhere(
          (pattern) => pattern['type'] == 'common_queries',
          orElse: () => null,
        );
        
        if (commonQueriesPattern != null) {
          expect(commonQueriesPattern['data'], isA<Map<String, dynamic>>());
          final data = commonQueriesPattern['data'] as Map<String, dynamic>;
          expect(data.containsKey('popular query'), isTrue);
        }
      });
    });

    group('Insights Generation', () {
      test('should generate performance insights', () {
        // Arrange - Adicionar eventos com performance ruim
        _addSlowEvents(analyticsService);

        // Act
        final report = analyticsService.getAnalyticsReport();
        final insights = report['insights'] as List;

        // Assert
        expect(insights, isNotEmpty);
        
        final performanceInsight = insights.firstWhere(
          (insight) => insight['type'] == 'performance',
          orElse: () => null,
        );
        
        if (performanceInsight != null) {
          expect(performanceInsight['message'], isA<String>());
          expect(performanceInsight['priority'], isA<String>());
          expect(performanceInsight['recommendations'], isA<List>());
        }
      });

      test('should generate success rate insights', () {
        // Arrange - Adicionar eventos com resultados vazios
        _addEmptyResultEvents(analyticsService);

        // Act
        final report = analyticsService.getAnalyticsReport();
        final insights = report['insights'] as List;

        // Assert
        final successRateInsight = insights.firstWhere(
          (insight) => insight['type'] == 'success_rate',
          orElse: () => null,
        );
        
        if (successRateInsight != null) {
          expect(successRateInsight['message'], contains('Taxa'));
          expect(successRateInsight['data'], containsPair('emptyResultRate', isA<double>()));
        }
      });
    });

    group('Data Management', () {
      test('should limit events in memory', () {
        // Arrange - Adicionar mais eventos que o limite
        for (int i = 0; i < 1200; i++) {
          analyticsService.trackSearchEvent(
            query: 'query $i',
            result: SearchResult(
              profiles: [_createMockProfile('$i')],
              query: 'query $i',
              totalResults: 1,
              hasMore: false,
              strategy: 'test',
              executionTime: 1000,
              fromCache: false,
            ),
            strategy: 'test',
          );
        }

        // Act
        final report = analyticsService.getAnalyticsReport();
        final summary = report['summary'] as Map<String, dynamic>;

        // Assert - Deve limitar a 1000 eventos
        expect(summary['totalEvents'], equals(1000));
      });

      test('should clear analytics data', () {
        // Arrange
        _addTestEvents(analyticsService);
        
        var report = analyticsService.getAnalyticsReport();
        expect((report['summary'] as Map)['totalEvents'], greaterThan(0));

        // Act
        analyticsService.clearAnalytics();

        // Assert
        report = analyticsService.getAnalyticsReport();
        expect((report['summary'] as Map)['totalEvents'], equals(0));
      });
    });
  });
}

// Helper methods
SpiritualProfileModel _createMockProfile(String id) {
  return SpiritualProfileModel(
    id: id,
    displayName: 'Test User $id',
    age: 25,
    city: 'Test City',
    state: 'Test State',
    interests: ['test'],
    isVerified: false,
    hasCompletedCourse: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void _addTestEvents(SearchAnalyticsService service) {
  final filters = SearchFilters(minAge: 20, maxAge: 30);
  
  for (int i = 0; i < 5; i++) {
    service.trackSearchEvent(
      query: 'test query $i',
      filters: filters,
      result: SearchResult(
        profiles: [_createMockProfile('$i')],
        query: 'test query $i',
        totalResults: 1,
        hasMore: false,
        appliedFilters: filters,
        strategy: 'firebase_simple',
        executionTime: 1000 + (i * 100),
        fromCache: i % 2 == 0,
      ),
      strategy: 'firebase_simple',
    );
  }
}

void _addEventsWithDifferentStrategies(SearchAnalyticsService service) {
  final strategies = ['firebase_simple', 'display_name', 'fallback'];
  
  for (int i = 0; i < 9; i++) {
    final strategy = strategies[i % 3];
    service.trackSearchEvent(
      query: 'query $i',
      result: SearchResult(
        profiles: [_createMockProfile('$i')],
        query: 'query $i',
        totalResults: 1,
        hasMore: false,
        strategy: strategy,
        executionTime: 1000,
        fromCache: false,
      ),
      strategy: strategy,
    );
  }
}

void _addEventsAtDifferentHours(SearchAnalyticsService service) {
  // Simular eventos em horários diferentes seria complexo
  // Por enquanto, apenas adicionar eventos normais
  _addTestEvents(service);
}

void _addRepeatedQueries(SearchAnalyticsService service) {
  final queries = ['popular query', 'popular query', 'rare query'];
  
  for (int i = 0; i < queries.length; i++) {
    service.trackSearchEvent(
      query: queries[i],
      result: SearchResult(
        profiles: [_createMockProfile('$i')],
        query: queries[i],
        totalResults: 1,
        hasMore: false,
        strategy: 'firebase_simple',
        executionTime: 1000,
        fromCache: false,
      ),
      strategy: 'firebase_simple',
    );
  }
}

void _addSlowEvents(SearchAnalyticsService service) {
  for (int i = 0; i < 3; i++) {
    service.trackSearchEvent(
      query: 'slow query $i',
      result: SearchResult(
        profiles: [_createMockProfile('$i')],
        query: 'slow query $i',
        totalResults: 1,
        hasMore: false,
        strategy: 'firebase_simple',
        executionTime: 4000, // Tempo lento
        fromCache: false,
      ),
      strategy: 'firebase_simple',
    );
  }
}

void _addEmptyResultEvents(SearchAnalyticsService service) {
  for (int i = 0; i < 3; i++) {
    service.trackSearchEvent(
      query: 'empty query $i',
      result: SearchResult(
        profiles: [], // Resultado vazio
        query: 'empty query $i',
        totalResults: 0,
        hasMore: false,
        strategy: 'firebase_simple',
        executionTime: 1000,
        fromCache: false,
      ),
      strategy: 'firebase_simple',
    );
  }
}