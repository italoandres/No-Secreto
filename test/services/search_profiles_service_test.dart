import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/search_profiles_service.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchProfilesService', () {
    late SearchProfilesService service;

    setUp(() {
      service = SearchProfilesService.instance;
    });

    test('should be singleton', () {
      final service1 = SearchProfilesService.instance;
      final service2 = SearchProfilesService.instance;
      
      expect(service1, same(service2));
    });

    test('should handle basic search parameters', () async {
      // Test that the method accepts correct parameters
      expect(() => service.searchProfiles(
        query: 'test',
        limit: 10,
      ), returnsNormally);
    });

    test('should handle search with filters', () async {
      final filters = SearchFilters(
        minAge: 25,
        maxAge: 45,
        city: 'São Paulo',
      );

      expect(() => service.searchProfiles(
        query: 'João',
        filters: filters,
        limit: 20,
      ), returnsNormally);
    });

    test('should provide comprehensive stats', () {
      final stats = service.getStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, containsKey('timestamp'));
      expect(stats, containsKey('cacheStats'));
      expect(stats, containsKey('historySize'));
      expect(stats, containsKey('recentAttempts'));
      expect(stats, containsKey('successfulAttempts'));
      expect(stats, containsKey('failedAttempts'));
      expect(stats, containsKey('successRate'));
      expect(stats, containsKey('averageExecutionTime'));
      expect(stats, containsKey('strategyStats'));
      
      // Verify strategy stats structure
      final strategyStats = stats['strategyStats'] as Map<String, dynamic>;
      expect(strategyStats, isNotEmpty);
      
      for (final strategyName in strategyStats.keys) {
        final strategyData = strategyStats[strategyName] as Map<String, dynamic>;
        expect(strategyData, containsKey('attempts'));
        expect(strategyData, containsKey('successes'));
        expect(strategyData, containsKey('failures'));
        expect(strategyData, containsKey('successRate'));
        expect(strategyData, containsKey('averageTime'));
        expect(strategyData, containsKey('priority'));
        expect(strategyData, containsKey('isAvailable'));
      }
    });

    test('should clear cache without errors', () async {
      await expectLater(service.clearCache(), completes);
    });

    test('should handle strategy forcing', () async {
      // Test forcing fallback strategy (should always be available)
      expect(() => service.searchWithStrategy(
        strategyName: 'Fallback',
        query: 'test',
        limit: 10,
      ), returnsNormally);
    });

    test('should reject invalid strategy names', () async {
      expect(() => service.searchWithStrategy(
        strategyName: 'NonExistentStrategy',
        query: 'test',
      ), throwsArgumentError);
    });

    test('should handle test all strategies', () async {
      expect(() => service.testAllStrategies(
        query: 'test',
        limit: 5,
      ), returnsNormally);
    });

    test('should handle empty query gracefully', () async {
      expect(() => service.searchProfiles(
        query: '',
        limit: 10,
      ), returnsNormally);
    });

    test('should handle various filter combinations', () async {
      // Test with age filters only
      final ageFilters = SearchFilters(minAge: 18, maxAge: 65);
      expect(() => service.searchProfiles(
        query: 'test',
        filters: ageFilters,
      ), returnsNormally);

      // Test with location filters only
      final locationFilters = SearchFilters(
        city: 'São Paulo',
        state: 'SP',
      );
      expect(() => service.searchProfiles(
        query: 'test',
        filters: locationFilters,
      ), returnsNormally);

      // Test with interest filters only
      final interestFilters = SearchFilters(
        interests: ['música', 'leitura'],
      );
      expect(() => service.searchProfiles(
        query: 'test',
        filters: interestFilters,
      ), returnsNormally);

      // Test with all filters
      final allFilters = SearchFilters(
        minAge: 25,
        maxAge: 45,
        city: 'Rio de Janeiro',
        state: 'RJ',
        interests: ['esportes', 'cinema'],
        isVerified: true,
        hasCompletedCourse: true,
      );
      expect(() => service.searchProfiles(
        query: 'Maria',
        filters: allFilters,
      ), returnsNormally);
    });

    test('should handle cache control', () async {
      // Test with cache enabled
      expect(() => service.searchProfiles(
        query: 'test',
        useCache: true,
      ), returnsNormally);

      // Test with cache disabled
      expect(() => service.searchProfiles(
        query: 'test',
        useCache: false,
      ), returnsNormally);
    });

    test('should handle different limit values', () async {
      // Test with small limit
      expect(() => service.searchProfiles(
        query: 'test',
        limit: 5,
      ), returnsNormally);

      // Test with large limit
      expect(() => service.searchProfiles(
        query: 'test',
        limit: 100,
      ), returnsNormally);

      // Test with default limit
      expect(() => service.searchProfiles(
        query: 'test',
      ), returnsNormally);
    });

    group('SearchAttemptResult', () {
      test('should create successful attempt', () {
        final attempt = SearchAttemptResult(
          strategyName: 'Test Strategy',
          success: true,
          executionTime: Duration(milliseconds: 100),
          resultCount: 5,
        );

        expect(attempt.strategyName, equals('Test Strategy'));
        expect(attempt.success, isTrue);
        expect(attempt.executionTime.inMilliseconds, equals(100));
        expect(attempt.resultCount, equals(5));
        expect(attempt.error, isNull);
        expect(attempt.timestamp, isA<DateTime>());
      });

      test('should create failed attempt', () {
        final attempt = SearchAttemptResult(
          strategyName: 'Test Strategy',
          success: false,
          executionTime: Duration(milliseconds: 50),
          resultCount: 0,
          error: 'Test error',
        );

        expect(attempt.success, isFalse);
        expect(attempt.error, equals('Test error'));
        expect(attempt.resultCount, equals(0));
      });

      test('should serialize to JSON', () {
        final attempt = SearchAttemptResult(
          strategyName: 'Test Strategy',
          success: true,
          executionTime: Duration(milliseconds: 100),
          resultCount: 5,
        );

        final json = attempt.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['strategyName'], equals('Test Strategy'));
        expect(json['success'], isTrue);
        expect(json['executionTime'], equals(100));
        expect(json['resultCount'], equals(5));
        expect(json['error'], isNull);
        expect(json['timestamp'], isA<String>());
      });
    });

    group('SearchException', () {
      test('should create exception with message', () {
        const exception = SearchException('Test error');

        expect(exception.message, equals('Test error'));
        expect(exception.attempts, isEmpty);
        expect(exception.toString(), equals('SearchException: Test error'));
      });

      test('should create exception with attempts', () {
        final attempts = [
          SearchAttemptResult(
            strategyName: 'Strategy 1',
            success: false,
            executionTime: Duration(milliseconds: 100),
            resultCount: 0,
            error: 'Error 1',
          ),
        ];

        final exception = SearchException('Test error', attempts: attempts);

        expect(exception.attempts, hasLength(1));
        expect(exception.attempts.first.strategyName, equals('Strategy 1'));
      });
    });

    // Note: Integration tests with actual Firebase would be in a separate file
    // These tests focus on the service structure and error handling
  });
}