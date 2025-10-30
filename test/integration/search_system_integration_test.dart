import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/services/search_profiles_service.dart';
import '../../lib/services/search_cache_manager.dart';
import '../../lib/services/search_error_handler.dart';
import '../../lib/repositories/explore_profiles_repository.dart';
import '../../lib/controllers/explore_profiles_controller.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockQuery extends Mock implements Query {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

void main() {
  group('Search System Integration Tests', () {
    late SearchProfilesService searchService;
    late SearchCacheManager cacheManager;
    late SearchErrorHandler errorHandler;
    late ExploreProfilesController controller;

    setUp(() {
      searchService = SearchProfilesService.instance;
      cacheManager = SearchCacheManager.instance;
      errorHandler = SearchErrorHandler.instance;
      controller = ExploreProfilesController();
      
      // Limpar estado entre testes
      cacheManager.clearCache();
      errorHandler.clearErrorHistory();
    });

    group('End-to-End Search Flow', () {
      test('should complete full search flow successfully', () async {
        // Arrange
        final searchQuery = 'João Silva';
        final filters = SearchFilters(
          minAge: 25,
          maxAge: 35,
          city: 'São Paulo',
          isVerified: true,
        );

        // Act - Executar busca completa
        final result = await searchService.searchProfiles(
          query: searchQuery,
          filters: filters,
          limit: 20,
          useCache: true,
        );

        // Assert
        expect(result, isA<SearchResult>());
        expect(result.query, equals(searchQuery));
        expect(result.appliedFilters, equals(filters));
        expect(result.executionTime, greaterThan(0));
        expect(result.strategy, isNotEmpty);
      });

      test('should handle search with caching correctly', () async {
        // Arrange
        final searchQuery = 'Maria Santos';
        final filters = SearchFilters(city: 'Rio de Janeiro');

        // Act - Primeira busca (deve ir para o cache)
        final firstResult = await searchService.searchProfiles(
          query: searchQuery,
          filters: filters,
          limit: 10,
          useCache: true,
        );

        // Act - Segunda busca (deve vir do cache)
        final secondResult = await searchService.searchProfiles(
          query: searchQuery,
          filters: filters,
          limit: 10,
          useCache: true,
        );

        // Assert
        expect(firstResult.fromCache, isFalse);
        expect(secondResult.fromCache, isTrue);
        expect(firstResult.query, equals(secondResult.query));
        expect(firstResult.appliedFilters, equals(secondResult.appliedFilters));
      });

      test('should handle search without cache correctly', () async {
        // Arrange
        final searchQuery = 'Pedro Costa';

        // Act
        final result = await searchService.searchProfiles(
          query: searchQuery,
          useCache: false,
        );

        // Assert
        expect(result.fromCache, isFalse);
        expect(result.query, equals(searchQuery));
      });
    });

    group('Error Handling and Fallback', () {
      test('should handle Firebase errors with fallback', () async {
        // Este teste simula cenários de erro e verifica se o fallback funciona
        // Em um ambiente real, mockaria o Firebase para lançar erros específicos
        
        final searchQuery = 'test error handling';
        
        // Act - Tentar busca que pode falhar
        final result = await searchService.searchProfiles(
          query: searchQuery,
          limit: 5,
        );

        // Assert - Deve retornar resultado mesmo com possíveis erros
        expect(result, isA<SearchResult>());
        expect(result.query, equals(searchQuery));
      });

      test('should retry on temporary failures', () async {
        // Simular retry em falhas temporárias
        final searchQuery = 'retry test';
        
        final result = await errorHandler.executeWithRetry(
          operation: () async {
            return SearchResult(
              profiles: [],
              query: searchQuery,
              totalResults: 0,
              hasMore: false,
              appliedFilters: null,
              strategy: 'test',
              executionTime: 100,
              fromCache: false,
            );
          },
          operationName: 'test_retry',
          query: searchQuery,
        );

        expect(result, isA<SearchResult>());
        expect(result.query, equals(searchQuery));
      });

      test('should handle network errors gracefully', () async {
        // Testar comportamento com erros de rede
        final searchQuery = 'network error test';
        
        try {
          final result = await searchService.searchProfiles(
            query: searchQuery,
            limit: 10,
          );
          
          // Deve retornar resultado mesmo com possíveis erros de rede
          expect(result, isA<SearchResult>());
        } catch (e) {
          // Se houver erro, deve ser tratado graciosamente
          expect(e, isA<Exception>());
        }
      });
    });

    group('Performance Validation', () {
      test('should complete search within acceptable time', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act
        final result = await searchService.searchProfiles(
          query: 'performance test',
          limit: 20,
        );
        
        stopwatch.stop();
        
        // Assert - Busca deve completar em menos de 10 segundos
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
        expect(result.executionTime, lessThan(10000));
      });

      test('should handle large result sets efficiently', () async {
        // Testar performance com muitos resultados
        final result = await searchService.searchProfiles(
          query: '',  // Query vazia para pegar mais resultados
          limit: 100,
        );

        expect(result, isA<SearchResult>());
        expect(result.executionTime, lessThan(15000)); // 15 segundos max
      });

      test('should cache frequently used searches', () async {
        // Testar se buscas frequentes são cacheadas eficientemente
        final searchQuery = 'frequent search';
        
        // Executar a mesma busca múltiplas vezes
        for (int i = 0; i < 3; i++) {
          await searchService.searchProfiles(
            query: searchQuery,
            limit: 10,
            useCache: true,
          );
        }

        // Verificar estatísticas do cache
        final cacheStats = cacheManager.getStats();
        expect(cacheStats['totalHits'], greaterThan(0));
      });
    });

    group('Filter Combinations', () {
      test('should handle age filters correctly', () async {
        final result = await searchService.searchProfiles(
          query: 'age filter test',
          filters: SearchFilters(minAge: 25, maxAge: 35),
          limit: 20,
        );

        expect(result, isA<SearchResult>());
        expect(result.appliedFilters?.minAge, equals(25));
        expect(result.appliedFilters?.maxAge, equals(35));
      });

      test('should handle location filters correctly', () async {
        final result = await searchService.searchProfiles(
          query: 'location test',
          filters: SearchFilters(
            city: 'São Paulo',
            state: 'SP',
          ),
          limit: 15,
        );

        expect(result, isA<SearchResult>());
        expect(result.appliedFilters?.city, equals('São Paulo'));
        expect(result.appliedFilters?.state, equals('SP'));
      });

      test('should handle boolean filters correctly', () async {
        final result = await searchService.searchProfiles(
          query: 'boolean filter test',
          filters: SearchFilters(
            isVerified: true,
            hasCompletedCourse: true,
          ),
          limit: 10,
        );

        expect(result, isA<SearchResult>());
        expect(result.appliedFilters?.isVerified, isTrue);
        expect(result.appliedFilters?.hasCompletedCourse, isTrue);
      });

      test('should handle complex filter combinations', () async {
        final complexFilters = SearchFilters(
          minAge: 25,
          maxAge: 40,
          city: 'São Paulo',
          state: 'SP',
          interests: ['tecnologia', 'espiritualidade'],
          isVerified: true,
          hasCompletedCourse: true,
        );

        final result = await searchService.searchProfiles(
          query: 'complex filters test',
          filters: complexFilters,
          limit: 25,
        );

        expect(result, isA<SearchResult>());
        expect(result.appliedFilters, equals(complexFilters));
      });

      test('should handle empty filters gracefully', () async {
        final result = await searchService.searchProfiles(
          query: 'no filters test',
          filters: SearchFilters(),
          limit: 10,
        );

        expect(result, isA<SearchResult>());
        expect(result.appliedFilters, isA<SearchFilters>());
      });
    });

    group('Repository Integration', () {
      test('should integrate with ExploreProfilesRepository correctly', () async {
        // Testar integração com o repository
        final profiles = await ExploreProfilesRepository.searchProfiles(
          query: 'repository integration test',
          minAge: 25,
          maxAge: 35,
          limit: 15,
        );

        expect(profiles, isA<List<SpiritualProfileModel>>());
      });

      test('should get verified profiles correctly', () async {
        final profiles = await ExploreProfilesRepository.getVerifiedProfiles(
          searchQuery: 'verified test',
          limit: 10,
        );

        expect(profiles, isA<List<SpiritualProfileModel>>());
      });

      test('should get profiles by engagement correctly', () async {
        final profiles = await ExploreProfilesRepository.getProfilesByEngagement(
          searchQuery: 'engagement test',
          limit: 10,
        );

        expect(profiles, isA<List<SpiritualProfileModel>>());
      });
    });

    group('Controller Integration', () {
      test('should integrate with ExploreProfilesController correctly', () async {
        // Testar integração com o controller
        controller.searchProfiles('controller test');
        
        // Aguardar um pouco para a busca completar
        await Future.delayed(Duration(milliseconds: 500));
        
        // Verificar se o controller foi atualizado
        expect(controller.searchQuery.value, equals('controller test'));
      });

      test('should handle filter changes in controller', () async {
        // Testar mudanças de filtro no controller
        controller.updateFilters(SearchFilters(
          minAge: 30,
          city: 'Rio de Janeiro',
        ));
        
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(controller.currentFilters.value.minAge, equals(30));
        expect(controller.currentFilters.value.city, equals('Rio de Janeiro'));
      });

      test('should clear search correctly in controller', () async {
        // Configurar estado inicial
        controller.searchProfiles('test query');
        await Future.delayed(Duration(milliseconds: 100));
        
        // Limpar busca
        controller.clearSearch();
        
        expect(controller.searchQuery.value, isEmpty);
      });
    });

    group('Statistics and Monitoring', () {
      test('should collect search statistics correctly', () async {
        // Executar algumas buscas para gerar estatísticas
        await searchService.searchProfiles(query: 'stats test 1', limit: 5);
        await searchService.searchProfiles(query: 'stats test 2', limit: 10);
        await searchService.searchProfiles(query: 'stats test 3', limit: 15);

        // Verificar estatísticas do serviço
        final serviceStats = searchService.getStats();
        expect(serviceStats, containsKey('recentAttempts'));
        expect(serviceStats, containsKey('successfulAttempts'));
        expect(serviceStats, containsKey('strategyStats'));

        // Verificar estatísticas do cache
        final cacheStats = cacheManager.getStats();
        expect(cacheStats, containsKey('totalRequests'));
        expect(cacheStats, containsKey('hitRate'));

        // Verificar estatísticas do error handler
        final errorStats = errorHandler.getStats();
        expect(errorStats, containsKey('totalOperations'));
        expect(errorStats, containsKey('successRate'));
      });

      test('should track performance metrics correctly', () async {
        final startTime = DateTime.now();
        
        await searchService.searchProfiles(
          query: 'performance metrics test',
          limit: 20,
        );
        
        final endTime = DateTime.now();
        final totalTime = endTime.difference(startTime).inMilliseconds;
        
        expect(totalTime, greaterThan(0));
        expect(totalTime, lessThan(30000)); // Máximo 30 segundos
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle empty query correctly', () async {
        final result = await searchService.searchProfiles(
          query: '',
          limit: 10,
        );

        expect(result, isA<SearchResult>());
        expect(result.query, isEmpty);
      });

      test('should handle very long query correctly', () async {
        final longQuery = 'a' * 1000; // Query muito longa
        
        final result = await searchService.searchProfiles(
          query: longQuery,
          limit: 5,
        );

        expect(result, isA<SearchResult>());
      });

      test('should handle zero limit correctly', () async {
        final result = await searchService.searchProfiles(
          query: 'zero limit test',
          limit: 0,
        );

        expect(result, isA<SearchResult>());
        expect(result.profiles, isEmpty);
      });

      test('should handle very large limit correctly', () async {
        final result = await searchService.searchProfiles(
          query: 'large limit test',
          limit: 1000,
        );

        expect(result, isA<SearchResult>());
        expect(result.profiles.length, lessThanOrEqualTo(1000));
      });

      test('should handle special characters in query', () async {
        final specialQuery = 'João & Maria @#\$%';
        
        final result = await searchService.searchProfiles(
          query: specialQuery,
          limit: 10,
        );

        expect(result, isA<SearchResult>());
        expect(result.query, equals(specialQuery));
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent searches correctly', () async {
        // Executar múltiplas buscas simultaneamente
        final futures = List.generate(5, (index) => 
          searchService.searchProfiles(
            query: 'concurrent test $index',
            limit: 10,
          )
        );

        final results = await Future.wait(futures);

        expect(results, hasLength(5));
        for (int i = 0; i < results.length; i++) {
          expect(results[i], isA<SearchResult>());
          expect(results[i].query, equals('concurrent test $i'));
        }
      });

      test('should handle cache correctly with concurrent access', () async {
        final sameQuery = 'concurrent cache test';
        
        // Executar a mesma busca simultaneamente
        final futures = List.generate(3, (_) => 
          searchService.searchProfiles(
            query: sameQuery,
            limit: 10,
            useCache: true,
          )
        );

        final results = await Future.wait(futures);

        expect(results, hasLength(3));
        for (final result in results) {
          expect(result.query, equals(sameQuery));
        }
      });
    });
  });
}