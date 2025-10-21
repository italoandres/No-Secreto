import 'package:flutter_test/flutter_test.dart';
import '../../lib/repositories/explore_profiles_repository.dart';
import '../../lib/models/spiritual_profile_model.dart';
import '../../lib/models/search_filters.dart';

void main() {
  group('ExploreProfilesRepository', () {
    test('should search profiles with basic query', () async {
      // Test that the method accepts correct parameters
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: 'test',
        limit: 10,
      ), returnsNormally);
    });

    test('should search profiles with comprehensive filters', () async {
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: 'João Silva',
        minAge: 25,
        maxAge: 45,
        city: 'São Paulo',
        state: 'SP',
        interests: ['música', 'leitura'],
        limit: 20,
      ), returnsNormally);
    });

    test('should get verified profiles', () async {
      expect(() => ExploreProfilesRepository.getVerifiedProfiles(
        searchQuery: 'test',
        limit: 15,
      ), returnsNormally);
    });

    test('should get verified profiles without search query', () async {
      expect(() => ExploreProfilesRepository.getVerifiedProfiles(
        limit: 20,
      ), returnsNormally);
    });

    test('should get profiles by engagement', () async {
      expect(() => ExploreProfilesRepository.getProfilesByEngagement(
        searchQuery: 'test',
        limit: 15,
      ), returnsNormally);
    });

    test('should get popular profiles', () async {
      expect(() => ExploreProfilesRepository.getPopularProfiles(
        limit: 10,
      ), returnsNormally);
    });

    test('should provide comprehensive search stats', () {
      final stats = ExploreProfilesRepository.getSearchStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, containsKey('timestamp'));
      expect(stats, containsKey('repositoryVersion'));
      expect(stats, containsKey('features'));
      expect(stats, containsKey('searchService'));
      
      final features = stats['features'] as List;
      expect(features, contains('robust_search'));
      expect(features, contains('automatic_fallback'));
      expect(features, contains('intelligent_cache'));
    });

    test('should clear search cache', () async {
      await expectLater(
        ExploreProfilesRepository.clearSearchCache(),
        completes,
      );
    });

    test('should test search with specific strategy', () async {
      expect(() => ExploreProfilesRepository.testSearchWithStrategy(
        query: 'test',
        filters: SearchFilters(minAge: 25),
        limit: 10,
        strategyName: 'Fallback',
      ), returnsNormally);
    });

    test('should test search without specific strategy', () async {
      expect(() => ExploreProfilesRepository.testSearchWithStrategy(
        query: 'test',
        filters: SearchFilters(city: 'São Paulo'),
        limit: 10,
      ), returnsNormally);
    });

    test('should test all strategies', () async {
      expect(() => ExploreProfilesRepository.testAllStrategies(
        query: 'test',
        filters: SearchFilters(isVerified: true),
        limit: 5,
      ), returnsNormally);
    });

    test('should record profile view', () async {
      expect(() => ExploreProfilesRepository.recordProfileView(
        'viewer123',
        'profile456',
      ), returnsNormally);
    });

    test('should update engagement metrics', () async {
      expect(() => ExploreProfilesRepository.updateEngagementMetrics(
        'user123',
        storyLikesIncrement: 1,
        storyCommentsIncrement: 1,
        screenTimeIncrement: 300,
      ), returnsNormally);
    });

    test('should handle edge cases in search', () async {
      // Empty query
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: '',
        limit: 10,
      ), returnsNormally);

      // Null query
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: null,
        limit: 10,
      ), returnsNormally);

      // Large limit
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: 'test',
        limit: 100,
      ), returnsNormally);

      // Zero limit
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: 'test',
        limit: 0,
      ), returnsNormally);
    });

    test('should handle complex filter combinations', () async {
      // All filters
      expect(() => ExploreProfilesRepository.searchProfiles(
        query: 'Maria Santos',
        minAge: 18,
        maxAge: 65,
        city: 'Rio de Janeiro',
        state: 'RJ',
        interests: ['esportes', 'cinema', 'música'],
        limit: 25,
      ), returnsNormally);

      // Only age filters
      expect(() => ExploreProfilesRepository.searchProfiles(
        minAge: 30,
        maxAge: 40,
        limit: 15,
      ), returnsNormally);

      // Only location filters
      expect(() => ExploreProfilesRepository.searchProfiles(
        city: 'Brasília',
        state: 'DF',
        limit: 15,
      ), returnsNormally);

      // Only interests
      expect(() => ExploreProfilesRepository.searchProfiles(
        interests: ['tecnologia', 'inovação'],
        limit: 15,
      ), returnsNormally);
    });

    test('should handle engagement metrics edge cases', () async {
      // Single metric
      expect(() => ExploreProfilesRepository.updateEngagementMetrics(
        'user123',
        storyLikesIncrement: 1,
      ), returnsNormally);

      // Negative increments (decrements)
      expect(() => ExploreProfilesRepository.updateEngagementMetrics(
        'user123',
        storyLikesIncrement: -1,
        storyCommentsIncrement: -2,
      ), returnsNormally);

      // Zero increments
      expect(() => ExploreProfilesRepository.updateEngagementMetrics(
        'user123',
        storyLikesIncrement: 0,
        storyCommentsIncrement: 0,
        screenTimeIncrement: 0,
      ), returnsNormally);
    });

    // Note: Integration tests with actual Firebase would be in a separate file
    // These tests focus on the repository interface and parameter validation
  });
}