import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/search_cache_manager.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchCacheManager', () {
    late SearchCacheManager cacheManager;

    setUp(() {
      cacheManager = SearchCacheManager.instance;
    });

    tearDown(() async {
      await cacheManager.clearCache();
    });

    test('should be singleton', () {
      final manager1 = SearchCacheManager.instance;
      final manager2 = SearchCacheManager.instance;
      
      expect(manager1, same(manager2));
    });

    test('should cache and retrieve results', () async {
      final mockProfiles = [
        SpiritualProfileModel(
          id: '1',
          displayName: 'João Silva',
          isActive: true,
        ),
        SpiritualProfileModel(
          id: '2',
          displayName: 'Maria Santos',
          isActive: true,
        ),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'test',
        totalResults: 2,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 100,
        fromCache: false,
      );

      // Cache the result
      await cacheManager.cacheResult(
        query: 'test',
        filters: null,
        limit: 20,
        result: result,
      );

      // Retrieve from cache
      final cachedResult = await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
      );

      expect(cachedResult, isNotNull);
      expect(cachedResult!.profiles, hasLength(2));
      expect(cachedResult.fromCache, isTrue);
      expect(cachedResult.query, equals('test'));
    });

    test('should handle cache with filters', () async {
      final filters = SearchFilters(
        minAge: 25,
        maxAge: 45,
        city: 'São Paulo',
      );

      final mockProfiles = [
        SpiritualProfileModel(
          id: '1',
          displayName: 'João Silva',
          age: 30,
          city: 'São Paulo',
          isActive: true,
        ),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'João',
        totalResults: 1,
        hasMore: false,
        appliedFilters: filters,
        strategy: 'Test Strategy',
        executionTime: 150,
        fromCache: false,
      );

      // Cache with filters
      await cacheManager.cacheResult(
        query: 'João',
        filters: filters,
        limit: 20,
        result: result,
      );

      // Retrieve with same filters
      final cachedResult = await cacheManager.getCachedResult(
        query: 'João',
        filters: filters,
        limit: 20,
      );

      expect(cachedResult, isNotNull);
      expect(cachedResult!.profiles, hasLength(1));
      expect(cachedResult.fromCache, isTrue);

      // Try to retrieve with different filters (should miss)
      final differentFilters = SearchFilters(minAge: 30, maxAge: 50);
      final missResult = await cacheManager.getCachedResult(
        query: 'João',
        filters: differentFilters,
        limit: 20,
      );

      expect(missResult, isNull);
    });

    test('should expire old entries', () async {
      final mockProfiles = [
        SpiritualProfileModel(
          id: '1',
          displayName: 'Test',
          isActive: true,
        ),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'test',
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 100,
        fromCache: false,
      );

      // Cache the result
      await cacheManager.cacheResult(
        query: 'test',
        filters: null,
        limit: 20,
        result: result,
      );

      // Try to retrieve with very short max age (should expire)
      final expiredResult = await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
        maxAge: Duration(milliseconds: 1),
      );

      // Wait a bit to ensure expiration
      await Future.delayed(Duration(milliseconds: 10));

      final expiredResult2 = await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
        maxAge: Duration(milliseconds: 1),
      );

      expect(expiredResult2, isNull);
    });

    test('should not cache empty results', () async {
      final emptyResult = SearchResult(
        profiles: [],
        query: 'empty',
        totalResults: 0,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 50,
        fromCache: false,
      );

      // Try to cache empty result
      await cacheManager.cacheResult(
        query: 'empty',
        filters: null,
        limit: 20,
        result: emptyResult,
      );

      // Should not be cached
      final cachedResult = await cacheManager.getCachedResult(
        query: 'empty',
        filters: null,
        limit: 20,
      );

      expect(cachedResult, isNull);
    });

    test('should provide comprehensive stats', () async {
      // Add some cache entries
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'test',
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 100,
        fromCache: false,
      );

      await cacheManager.cacheResult(
        query: 'test',
        filters: null,
        limit: 20,
        result: result,
      );

      // Get some hits and misses
      await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
      );

      await cacheManager.getCachedResult(
        query: 'nonexistent',
        filters: null,
        limit: 20,
      );

      final stats = cacheManager.getStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, containsKey('timestamp'));
      expect(stats, containsKey('size'));
      expect(stats, containsKey('maxSize'));
      expect(stats, containsKey('hitRate'));
      expect(stats, containsKey('totalRequests'));
      expect(stats, containsKey('totalHits'));
      expect(stats, containsKey('totalMisses'));
      expect(stats, containsKey('filterTypeStats'));
      expect(stats, containsKey('configuration'));

      expect(stats['size'], greaterThan(0));
      expect(stats['totalRequests'], greaterThan(0));
    });

    test('should handle cache entry removal', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'test',
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 100,
        fromCache: false,
      );

      // Cache the result
      await cacheManager.cacheResult(
        query: 'test',
        filters: null,
        limit: 20,
        result: result,
      );

      // Verify it's cached
      final cachedResult = await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
      );
      expect(cachedResult, isNotNull);

      // Remove the entry
      cacheManager.removeEntry(
        query: 'test',
        filters: null,
        limit: 20,
      );

      // Verify it's removed
      final removedResult = await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
      );
      expect(removedResult, isNull);
    });

    test('should get entry info', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'test',
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 100,
        fromCache: false,
      );

      // Cache the result
      await cacheManager.cacheResult(
        query: 'test',
        filters: null,
        limit: 20,
        result: result,
      );

      // Get entry info
      final entryInfo = cacheManager.getEntryInfo(
        query: 'test',
        filters: null,
        limit: 20,
      );

      expect(entryInfo, isNotNull);
      expect(entryInfo!.query, equals('test'));
      expect(entryInfo.resultCount, equals(1));
      expect(entryInfo.strategy, equals('Test Strategy'));
      expect(entryInfo.filters, isNull);
    });

    test('should list all entries', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];

      final result1 = SearchResult(
        profiles: mockProfiles,
        query: 'test1',
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Strategy1',
        executionTime: 100,
        fromCache: false,
      );

      final result2 = SearchResult(
        profiles: mockProfiles,
        query: 'test2',
        totalResults: 1,
        hasMore: false,
        appliedFilters: SearchFilters(minAge: 25),
        strategy: 'Strategy2',
        executionTime: 150,
        fromCache: false,
      );

      // Cache multiple results
      await cacheManager.cacheResult(
        query: 'test1',
        filters: null,
        limit: 20,
        result: result1,
      );

      await cacheManager.cacheResult(
        query: 'test2',
        filters: SearchFilters(minAge: 25),
        limit: 20,
        result: result2,
      );

      // Get all entries
      final allEntries = cacheManager.getAllEntries();

      expect(allEntries, hasLength(2));
      expect(allEntries.any((e) => e.query == 'test1'), isTrue);
      expect(allEntries.any((e) => e.query == 'test2'), isTrue);
    });

    test('should handle filter type invalidation', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];

      final ageFilters = SearchFilters(minAge: 25, maxAge: 45);
      final cityFilters = SearchFilters(city: 'São Paulo');

      final result1 = SearchResult(
        profiles: mockProfiles,
        query: 'test1',
        totalResults: 1,
        hasMore: false,
        appliedFilters: ageFilters,
        strategy: 'Strategy1',
        executionTime: 100,
        fromCache: false,
      );

      final result2 = SearchResult(
        profiles: mockProfiles,
        query: 'test2',
        totalResults: 1,
        hasMore: false,
        appliedFilters: cityFilters,
        strategy: 'Strategy2',
        executionTime: 150,
        fromCache: false,
      );

      // Cache results with different filter types
      await cacheManager.cacheResult(
        query: 'test1',
        filters: ageFilters,
        limit: 20,
        result: result1,
      );

      await cacheManager.cacheResult(
        query: 'test2',
        filters: cityFilters,
        limit: 20,
        result: result2,
      );

      // Invalidate age filter type
      cacheManager.invalidateByFilterType('age');

      // Age filter result should be gone
      final ageResult = await cacheManager.getCachedResult(
        query: 'test1',
        filters: ageFilters,
        limit: 20,
      );
      expect(ageResult, isNull);

      // City filter result should still be there
      final cityResult = await cacheManager.getCachedResult(
        query: 'test2',
        filters: cityFilters,
        limit: 20,
      );
      expect(cityResult, isNotNull);
    });

    test('should handle cleanup expired entries', () async {
      final mockProfiles = [
        SpiritualProfileModel(id: '1', displayName: 'Test', isActive: true),
      ];

      final result = SearchResult(
        profiles: mockProfiles,
        query: 'test',
        totalResults: 1,
        hasMore: false,
        appliedFilters: null,
        strategy: 'Test Strategy',
        executionTime: 100,
        fromCache: false,
      );

      // Cache the result
      await cacheManager.cacheResult(
        query: 'test',
        filters: null,
        limit: 20,
        result: result,
      );

      // Cleanup with very short max age
      cacheManager.cleanupExpired(maxAge: Duration(milliseconds: 1));

      // Wait a bit
      await Future.delayed(Duration(milliseconds: 10));

      // Run cleanup again
      cacheManager.cleanupExpired(maxAge: Duration(milliseconds: 1));

      // Entry should be removed
      final cachedResult = await cacheManager.getCachedResult(
        query: 'test',
        filters: null,
        limit: 20,
      );

      expect(cachedResult, isNull);
    });
  });
}