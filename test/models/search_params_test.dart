import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/search_params.dart';
import '../../lib/models/search_filters.dart';

void main() {
  group('SearchParams', () {
    test('should create with default values', () {
      const params = SearchParams();
      
      expect(params.query, isNull);
      expect(params.filters, isNull);
      expect(params.limit, equals(30));
      expect(params.preferredStrategy, isNull);
      expect(params.useCache, isTrue);
      expect(params.timeout, isNull);
      expect(params.isEmpty, isTrue);
    });

    test('should create with custom values', () {
      const filters = SearchFilters(minAge: 18);
      const params = SearchParams(
        query: 'João',
        filters: filters,
        limit: 50,
        preferredStrategy: SearchStrategy.displayName,
        useCache: false,
        timeout: Duration(seconds: 10),
      );
      
      expect(params.query, equals('João'));
      expect(params.filters, equals(filters));
      expect(params.limit, equals(50));
      expect(params.preferredStrategy, equals(SearchStrategy.displayName));
      expect(params.useCache, isFalse);
      expect(params.timeout, equals(const Duration(seconds: 10)));
      expect(params.isEmpty, isFalse);
    });

    test('should detect text query correctly', () {
      const withQuery = SearchParams(query: 'João');
      expect(withQuery.hasTextQuery, isTrue);
      
      const withEmptyQuery = SearchParams(query: '');
      expect(withEmptyQuery.hasTextQuery, isFalse);
      
      const withSpacesQuery = SearchParams(query: '   ');
      expect(withSpacesQuery.hasTextQuery, isFalse);
      
      const noQuery = SearchParams();
      expect(noQuery.hasTextQuery, isFalse);
    });

    test('should detect filters correctly', () {
      const filters = SearchFilters(minAge: 18);
      const withFilters = SearchParams(filters: filters);
      expect(withFilters.hasFilters, isTrue);
      
      const emptyFilters = SearchFilters();
      const withEmptyFilters = SearchParams(filters: emptyFilters);
      expect(withEmptyFilters.hasFilters, isFalse);
      
      const noFilters = SearchParams();
      expect(noFilters.hasFilters, isFalse);
    });

    test('should validate parameters correctly', () {
      const validParams = SearchParams(query: 'João', limit: 30);
      expect(validParams.isValid, isTrue);
      
      const invalidLimit = SearchParams(limit: 0);
      expect(invalidLimit.isValid, isFalse);
      
      const negativeLimit = SearchParams(limit: -5);
      expect(negativeLimit.isValid, isFalse);
      
      const invalidFilters = SearchParams(
        filters: SearchFilters(minAge: 65, maxAge: 18),
      );
      expect(invalidFilters.isValid, isFalse);
    });

    test('should generate cache key correctly', () {
      const params1 = SearchParams(query: 'João', limit: 30);
      const params2 = SearchParams(query: 'joão', limit: 30); // Mesmo query em lowercase
      const params3 = SearchParams(query: 'Maria', limit: 30);
      
      expect(params1.cacheKey, equals(params2.cacheKey));
      expect(params1.cacheKey, isNot(equals(params3.cacheKey)));
      
      const withFilters = SearchParams(
        query: 'João',
        filters: const SearchFilters(minAge: 18, city: 'São Paulo'),
        limit: 30,
      );
      
      final cacheKey = withFilters.cacheKey;
      expect(cacheKey, contains('q:joão'));
      expect(cacheKey, contains('minAge:18'));
      expect(cacheKey, contains('city:São Paulo'));
      expect(cacheKey, contains('limit:30'));
    });

    test('should copy with new values', () {
      const original = SearchParams(query: 'João', limit: 30);
      final copy = original.copyWith(limit: 50, useCache: false);
      
      expect(copy.query, equals('João')); // Mantém valor original
      expect(copy.limit, equals(50)); // Novo valor
      expect(copy.useCache, isFalse); // Novo valor
    });

    test('should convert to/from JSON correctly', () {
      const filters = SearchFilters(minAge: 18);
      const original = SearchParams(
        query: 'João',
        filters: filters,
        limit: 50,
        preferredStrategy: SearchStrategy.displayName,
        useCache: false,
        timeout: Duration(seconds: 10),
      );
      
      final json = original.toJson();
      final restored = SearchParams.fromJson(json);
      
      expect(restored.query, equals(original.query));
      expect(restored.filters, equals(original.filters));
      expect(restored.limit, equals(original.limit));
      expect(restored.preferredStrategy, equals(original.preferredStrategy));
      expect(restored.useCache, equals(original.useCache));
      expect(restored.timeout, equals(original.timeout));
    });

    test('should handle equality correctly', () {
      const params1 = SearchParams(query: 'João', limit: 30);
      const params2 = SearchParams(query: 'João', limit: 30);
      const params3 = SearchParams(query: 'Maria', limit: 30);
      
      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('should detect empty search correctly', () {
      const emptyParams = SearchParams();
      expect(emptyParams.isEmpty, isTrue);
      
      const withQuery = SearchParams(query: 'João');
      expect(withQuery.isEmpty, isFalse);
      
      const withFilters = SearchParams(filters: SearchFilters(minAge: 18));
      expect(withFilters.isEmpty, isFalse);
      
      const withEmptyQuery = SearchParams(query: '');
      expect(withEmptyQuery.isEmpty, isTrue);
      
      const withSpacesQuery = SearchParams(query: '   ');
      expect(withSpacesQuery.isEmpty, isTrue);
    });
  });

  group('SearchStrategy', () {
    test('should have all expected values', () {
      expect(SearchStrategy.values, contains(SearchStrategy.firebaseSimple));
      expect(SearchStrategy.values, contains(SearchStrategy.displayName));
      expect(SearchStrategy.values, contains(SearchStrategy.fallback));
      expect(SearchStrategy.values, contains(SearchStrategy.auto));
    });
  });
}