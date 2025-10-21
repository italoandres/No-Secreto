import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/search_filters.dart';

void main() {
  group('SearchFilters', () {
    test('should create empty filters', () {
      const filters = SearchFilters();
      
      expect(filters.minAge, isNull);
      expect(filters.maxAge, isNull);
      expect(filters.city, isNull);
      expect(filters.state, isNull);
      expect(filters.interests, isNull);
      expect(filters.isVerified, isNull);
      expect(filters.hasCompletedCourse, isNull);
      expect(filters.hasActiveFilters, isFalse);
    });

    test('should create filters with values', () {
      const filters = SearchFilters(
        minAge: 18,
        maxAge: 65,
        city: 'São Paulo',
        state: 'SP',
        interests: ['música', 'leitura'],
        isVerified: true,
        hasCompletedCourse: true,
      );
      
      expect(filters.minAge, equals(18));
      expect(filters.maxAge, equals(65));
      expect(filters.city, equals('São Paulo'));
      expect(filters.state, equals('SP'));
      expect(filters.interests, equals(['música', 'leitura']));
      expect(filters.isVerified, isTrue);
      expect(filters.hasCompletedCourse, isTrue);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('should validate age ranges correctly', () {
      const validFilters = SearchFilters(minAge: 18, maxAge: 65);
      expect(validFilters.isValid, isTrue);
      
      const invalidFilters = SearchFilters(minAge: 65, maxAge: 18);
      expect(invalidFilters.isValid, isFalse);
      
      const negativeAge = SearchFilters(minAge: -5);
      expect(negativeAge.isValid, isFalse);
    });

    test('should copy with new values', () {
      const original = SearchFilters(minAge: 18, city: 'São Paulo');
      final copy = original.copyWith(maxAge: 65, state: 'SP');
      
      expect(copy.minAge, equals(18)); // Mantém valor original
      expect(copy.maxAge, equals(65)); // Novo valor
      expect(copy.city, equals('São Paulo')); // Mantém valor original
      expect(copy.state, equals('SP')); // Novo valor
    });

    test('should convert to/from JSON correctly', () {
      const original = SearchFilters(
        minAge: 18,
        maxAge: 65,
        city: 'São Paulo',
        interests: ['música'],
        isVerified: true,
      );
      
      final json = original.toJson();
      final restored = SearchFilters.fromJson(json);
      
      expect(restored, equals(original));
    });

    test('should detect active filters correctly', () {
      const noFilters = SearchFilters();
      expect(noFilters.hasActiveFilters, isFalse);
      
      const withAge = SearchFilters(minAge: 18);
      expect(withAge.hasActiveFilters, isTrue);
      
      const withCity = SearchFilters(city: 'São Paulo');
      expect(withCity.hasActiveFilters, isTrue);
      
      const withEmptyCity = SearchFilters(city: '');
      expect(withEmptyCity.hasActiveFilters, isFalse);
      
      const withEmptyInterests = SearchFilters(interests: []);
      expect(withEmptyInterests.hasActiveFilters, isFalse);
    });

    test('should handle equality correctly', () {
      const filters1 = SearchFilters(minAge: 18, city: 'São Paulo');
      const filters2 = SearchFilters(minAge: 18, city: 'São Paulo');
      const filters3 = SearchFilters(minAge: 20, city: 'São Paulo');
      
      expect(filters1, equals(filters2));
      expect(filters1, isNot(equals(filters3)));
    });

    test('should handle toString correctly', () {
      const filters = SearchFilters(minAge: 18, city: 'São Paulo');
      final string = filters.toString();
      
      expect(string, contains('SearchFilters'));
      expect(string, contains('minAge: 18'));
      expect(string, contains('city: São Paulo'));
    });
  });
}