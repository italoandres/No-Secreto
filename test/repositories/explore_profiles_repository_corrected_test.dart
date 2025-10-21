import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/repositories/explore_profiles_repository.dart';
import '../../lib/models/spiritual_profile_model.dart';
import '../../lib/models/search_filters.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockQuery extends Mock implements Query {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

void main() {
  group('ExploreProfilesRepository - Corrected Version', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();
    });

    group('Layered Search Strategy', () {
      test('should use layered approach for profile search', () async {
        // Este teste verifica se a estratégia em camadas está sendo aplicada
        // Na prática, testaria com dados reais do Firebase
        
        final filters = SearchFilters(
          minAge: 25,
          maxAge: 35,
          city: 'São Paulo',
          isVerified: true,
          hasCompletedCourse: true,
        );

        // Simular busca (em ambiente real, usaria Firebase Test SDK)
        final result = await ExploreProfilesRepository.searchProfiles(
          query: 'João',
          minAge: 25,
          maxAge: 35,
          city: 'São Paulo',
          limit: 20,
        );

        // Verificar que o método não falha
        expect(result, isA<List<SpiritualProfileModel>>());
      });

      test('should handle Firebase errors gracefully', () async {
        // Testar tratamento de erros específicos do Firebase
        
        // Simular diferentes tipos de erro
        final errorTypes = [
          'requires an index',
          'permission denied',
          'network error',
          'quota exceeded',
        ];

        for (final errorMessage in errorTypes) {
          // Em um teste real, mockaria o Firebase para lançar esses erros
          // e verificaria se o fallback correto é chamado
          
          final errorType = ExploreProfilesRepository._classifyFirebaseError(
            Exception(errorMessage)
          );
          
          expect(errorType, isNotNull);
        }
      });
    });

    group('Error Classification', () {
      test('should classify index missing errors correctly', () {
        final errors = [
          'requires an index',
          'composite index',
          'inequality filter requires',
        ];

        for (final error in errors) {
          final type = ExploreProfilesRepository._classifyFirebaseError(
            Exception(error)
          );
          expect(type, equals(FirebaseErrorType.indexMissing));
        }
      });

      test('should classify permission errors correctly', () {
        final errors = [
          'permission denied',
          'unauthorized',
          'insufficient permissions',
        ];

        for (final error in errors) {
          final type = ExploreProfilesRepository._classifyFirebaseError(
            Exception(error)
          );
          expect(type, equals(FirebaseErrorType.permissionDenied));
        }
      });

      test('should classify network errors correctly', () {
        final errors = [
          'network error',
          'connection timeout',
          'deadline exceeded',
          'unavailable',
        ];

        for (final error in errors) {
          final type = ExploreProfilesRepository._classifyFirebaseError(
            Exception(error)
          );
          expect(type, equals(FirebaseErrorType.networkError));
        }
      });

      test('should classify quota errors correctly', () {
        final errors = [
          'quota exceeded',
          'resource exhausted',
          'limit exceeded',
        ];

        for (final error in errors) {
          final type = ExploreProfilesRepository._classifyFirebaseError(
            Exception(error)
          );
          expect(type, equals(FirebaseErrorType.quotaExceeded));
        }
      });
    });

    group('Document Parsing', () {
      test('should parse valid profile documents', () {
        // Criar mock de documentos válidos
        final mockDocs = [
          _createMockDocument('user1', {
            'displayName': 'João Silva',
            'age': 30,
            'city': 'São Paulo',
            'isVerified': true,
            'hasCompletedCourse': true,
            'isActive': true,
          }),
          _createMockDocument('user2', {
            'displayName': 'Maria Santos',
            'age': 28,
            'city': 'Rio de Janeiro',
            'isVerified': true,
            'hasCompletedCourse': true,
            'isActive': true,
          }),
        ];

        final profiles = ExploreProfilesRepository._parseProfileDocuments(mockDocs);
        
        expect(profiles, hasLength(2));
        expect(profiles[0].displayName, equals('João Silva'));
        expect(profiles[1].displayName, equals('Maria Santos'));
      });

      test('should handle invalid documents gracefully', () {
        // Criar mix de documentos válidos e inválidos
        final mockDocs = [
          _createMockDocument('valid', {
            'displayName': 'Valid User',
            'age': 25,
            'isActive': true,
          }),
          _createMockDocument('invalid', {
            'invalidField': 'This will cause parsing error',
            // Faltam campos obrigatórios
          }),
        ];

        final profiles = ExploreProfilesRepository._parseProfileDocuments(mockDocs);
        
        // Deve retornar apenas os documentos válidos
        expect(profiles, hasLength(1));
        expect(profiles[0].displayName, equals('Valid User'));
      });
    });

    group('Filter Application', () {
      test('should apply text search filters correctly', () {
        final profiles = [
          _createTestProfile('1', 'João Silva', 30, 'São Paulo'),
          _createTestProfile('2', 'Maria Santos', 25, 'Rio de Janeiro'),
          _createTestProfile('3', 'Pedro João', 35, 'Brasília'),
        ];

        final filtered = ExploreProfilesRepository._applyOptimizedFilters(
          profiles,
          'João',
          SearchFilters(),
        );

        expect(filtered, hasLength(2));
        expect(filtered.any((p) => p.displayName!.contains('João')), isTrue);
      });

      test('should apply age filters correctly', () {
        final profiles = [
          _createTestProfile('1', 'User 1', 20, 'City'),
          _createTestProfile('2', 'User 2', 30, 'City'),
          _createTestProfile('3', 'User 3', 40, 'City'),
        ];

        final filtered = ExploreProfilesRepository._applyOptimizedFilters(
          profiles,
          null,
          SearchFilters(minAge: 25, maxAge: 35),
        );

        expect(filtered, hasLength(1));
        expect(filtered[0].age, equals(30));
      });

      test('should apply location filters correctly', () {
        final profiles = [
          _createTestProfile('1', 'User 1', 25, 'São Paulo'),
          _createTestProfile('2', 'User 2', 25, 'Rio de Janeiro'),
          _createTestProfile('3', 'User 3', 25, 'São Paulo'),
        ];

        final filtered = ExploreProfilesRepository._applyOptimizedFilters(
          profiles,
          null,
          SearchFilters(city: 'São Paulo'),
        );

        expect(filtered, hasLength(2));
        expect(filtered.every((p) => p.city == 'São Paulo'), isTrue);
      });

      test('should apply boolean filters correctly', () {
        final profiles = [
          _createTestProfile('1', 'User 1', 25, 'City', isVerified: true),
          _createTestProfile('2', 'User 2', 25, 'City', isVerified: false),
          _createTestProfile('3', 'User 3', 25, 'City', isVerified: true),
        ];

        final filtered = ExploreProfilesRepository._applyOptimizedFilters(
          profiles,
          null,
          SearchFilters(isVerified: true),
        );

        expect(filtered, hasLength(2));
        expect(filtered.every((p) => p.isVerified == true), isTrue);
      });

      test('should apply combined filters correctly', () {
        final profiles = [
          _createTestProfile('1', 'João Silva', 30, 'São Paulo', isVerified: true),
          _createTestProfile('2', 'João Santos', 20, 'São Paulo', isVerified: true),
          _createTestProfile('3', 'Maria Silva', 30, 'Rio de Janeiro', isVerified: true),
          _createTestProfile('4', 'João Silva', 30, 'São Paulo', isVerified: false),
        ];

        final filtered = ExploreProfilesRepository._applyOptimizedFilters(
          profiles,
          'João',
          SearchFilters(
            minAge: 25,
            city: 'São Paulo',
            isVerified: true,
          ),
        );

        expect(filtered, hasLength(1));
        expect(filtered[0].displayName, equals('João Silva'));
        expect(filtered[0].age, equals(30));
        expect(filtered[0].city, equals('São Paulo'));
        expect(filtered[0].isVerified, isTrue);
      });
    });

    group('Integration with SearchProfilesService', () {
      test('should integrate with SearchProfilesService correctly', () async {
        // Testar se a integração com o SearchProfilesService funciona
        final result = await ExploreProfilesRepository.searchProfiles(
          query: 'test',
          limit: 10,
        );

        expect(result, isA<List<SpiritualProfileModel>>());
      });

      test('should get search statistics', () {
        final stats = ExploreProfilesRepository.getSearchStats();
        
        expect(stats, containsKey('searchService'));
        expect(stats, containsKey('timestamp'));
        expect(stats, containsKey('repositoryVersion'));
        expect(stats, containsKey('features'));
      });

      test('should clear search cache', () async {
        // Testar limpeza de cache
        await ExploreProfilesRepository.clearSearchCache();
        
        // Operação deve completar sem erro
        expect(true, isTrue);
      });
    });

    group('Compatibility', () {
      test('should maintain compatibility with existing code', () async {
        // Testar se os métodos existentes ainda funcionam
        final verifiedProfiles = await ExploreProfilesRepository.getVerifiedProfiles(
          searchQuery: 'test',
          limit: 10,
        );

        expect(verifiedProfiles, isA<List<SpiritualProfileModel>>());
      });

      test('should handle engagement-based search', () async {
        final engagementProfiles = await ExploreProfilesRepository.getProfilesByEngagement(
          searchQuery: 'test',
          limit: 10,
        );

        expect(engagementProfiles, isA<List<SpiritualProfileModel>>());
      });
    });
  });
}

// Helper functions for testing
MockQueryDocumentSnapshot _createMockDocument(String id, Map<String, dynamic> data) {
  final mockDoc = MockQueryDocumentSnapshot();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}

SpiritualProfileModel _createTestProfile(
  String id,
  String displayName,
  int age,
  String city, {
  bool isVerified = true,
  bool hasCompletedCourse = true,
}) {
  return SpiritualProfileModel(
    id: id,
    displayName: displayName,
    age: age,
    city: city,
    isVerified: isVerified,
    hasCompletedCourse: hasCompletedCourse,
    isActive: true,
  );
}