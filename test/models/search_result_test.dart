import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/search_params.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('SearchResult', () {
    late List<SpiritualProfileModel> mockProfiles;

    setUp(() {
      mockProfiles = [
        SpiritualProfileModel(
          id: '1',
          userId: 'user1',
          displayName: 'João Silva',
          isActive: true,
          isVerified: true,
          hasCompletedSinaisCourse: true,
        ),
        SpiritualProfileModel(
          id: '2',
          userId: 'user2',
          displayName: 'Maria Santos',
          isActive: true,
          isVerified: true,
          hasCompletedSinaisCourse: true,
        ),
      ];
    });

    test('should create success result', () {
      final result = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
        fromCache: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.hasResults, isTrue);
      expect(result.profiles.length, equals(2));
      expect(result.totalFound, equals(2));
      expect(result.strategyUsed, equals(SearchStrategy.displayName));
      expect(result.searchTime, equals(const Duration(milliseconds: 500)));
      expect(result.fromCache, isFalse);
      expect(result.error, isNull);
      expect(result.isFast, isTrue);
    });

    test('should create error result', () {
      final result = SearchResult.error(
        error: 'Firebase index required',
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 100),
      );

      expect(result.isSuccess, isFalse);
      expect(result.hasResults, isFalse);
      expect(result.profiles, isEmpty);
      expect(result.totalFound, equals(0));
      expect(result.error, equals('Firebase index required'));
    });

    test('should create empty result', () {
      final result = SearchResult.empty(
        strategyUsed: SearchStrategy.fallback,
        searchTime: const Duration(milliseconds: 200),
        fromCache: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.hasResults, isFalse);
      expect(result.profiles, isEmpty);
      expect(result.totalFound, equals(0));
      expect(result.fromCache, isTrue);
    });

    test('should detect fast searches correctly', () {
      final fastResult = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );
      expect(fastResult.isFast, isTrue);

      final slowResult = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 1500),
      );
      expect(slowResult.isFast, isFalse);
    });

    test('should copy with new values', () {
      final original = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      final copy = original.copyWith(
        fromCache: true,
        metadata: {'test': 'value'},
      );

      expect(copy.profiles, equals(original.profiles));
      expect(copy.fromCache, isTrue);
      expect(copy.metadata, equals({'test': 'value'}));
    });

    test('should merge results correctly', () {
      final result1 = SearchResult.success(
        profiles: [mockProfiles[0]],
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 300),
      );

      final result2 = SearchResult.success(
        profiles: [mockProfiles[1]],
        strategyUsed: SearchStrategy.fallback,
        searchTime: const Duration(milliseconds: 200),
      );

      final merged = result1.merge(result2);

      expect(merged.profiles.length, equals(2));
      expect(merged.totalFound, equals(2));
      expect(merged.strategyUsed, equals(SearchStrategy.displayName)); // Mantém original
      expect(merged.searchTime, equals(const Duration(milliseconds: 500)));
      expect(merged.metadata?['merged'], isTrue);
    });

    test('should merge without duplicates', () {
      final result1 = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 300),
      );

      final result2 = SearchResult.success(
        profiles: [mockProfiles[0]], // Perfil duplicado
        strategyUsed: SearchStrategy.fallback,
        searchTime: const Duration(milliseconds: 200),
      );

      final merged = result1.merge(result2);

      expect(merged.profiles.length, equals(2)); // Não deve duplicar
      expect(merged.totalFound, equals(2));
    });

    test('should filter results correctly', () {
      final result = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      final filtered = result.filter((profile) => profile.displayName?.contains('João') ?? false);

      expect(filtered.profiles.length, equals(1));
      expect(filtered.profiles[0].displayName, equals('João Silva'));
      expect(filtered.totalFound, equals(1));
      expect(filtered.metadata?['filtered'], isTrue);
      expect(filtered.metadata?['originalCount'], equals(2));
      expect(filtered.metadata?['filteredCount'], equals(1));
    });

    test('should limit results correctly', () {
      final result = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      final limited = result.limit(1);

      expect(limited.profiles.length, equals(1));
      expect(limited.totalFound, equals(1));
      expect(limited.metadata?['limited'], isTrue);
      expect(limited.metadata?['originalCount'], equals(2));
      expect(limited.metadata?['limitedTo'], equals(1));
    });

    test('should not limit if already within limit', () {
      final result = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      final notLimited = result.limit(5);

      expect(notLimited.profiles.length, equals(2));
      expect(notLimited.metadata?['limited'], isNull);
    });

    test('should convert to/from JSON correctly', () {
      final original = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
        fromCache: true,
        metadata: {'test': 'value'},
      );

      final json = original.toJson();
      final restored = SearchResult.fromJson(json);

      expect(restored.profiles.length, equals(original.profiles.length));
      expect(restored.totalFound, equals(original.totalFound));
      expect(restored.strategyUsed, equals(original.strategyUsed));
      expect(restored.searchTime, equals(original.searchTime));
      expect(restored.fromCache, equals(original.fromCache));
      expect(restored.metadata, equals(original.metadata));
    });

    test('should handle equality correctly', () {
      final result1 = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      final result2 = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      final result3 = SearchResult.success(
        profiles: [mockProfiles[0]],
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('should handle toString correctly', () {
      final result = SearchResult.success(
        profiles: mockProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: const Duration(milliseconds: 500),
        fromCache: true,
      );

      final string = result.toString();

      expect(string, contains('SearchResult'));
      expect(string, contains('profiles: 2'));
      expect(string, contains('strategy: SearchStrategy.displayName'));
      expect(string, contains('time: 500ms'));
      expect(string, contains('fromCache: true'));
    });
  });
}