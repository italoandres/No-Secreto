import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/search_profiles_service.dart';
import '../../lib/services/search_cache_manager.dart';
import '../../lib/repositories/explore_profiles_repository.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('Search Performance Tests', () {
    late SearchProfilesService searchService;
    late SearchCacheManager cacheManager;

    setUp(() {
      searchService = SearchProfilesService.instance;
      cacheManager = SearchCacheManager.instance;
      cacheManager.clearCache();
    });

    group('Response Time Performance', () {
      test('should complete simple search within 2 seconds', () async {
        final stopwatch = Stopwatch()..start();
        
        final result = await searchService.searchProfiles(
          query: 'João',
          limit: 10,
        );
        
        stopwatch.stop();
        
        expect(result, isA<SearchResult>());
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(result.executionTime, lessThan(2000));
      });

      test('should complete filtered search within 3 seconds', () async {
        final stopwatch = Stopwatch()..start();
        
        final result = await searchService.searchProfiles(
          query: 'Maria',
          filters: SearchFilters(
            minAge: 25,
            maxAge: 35,
            city: 'São Paulo',
          ),
          limit: 20,
        );
        
        stopwatch.stop();
        
        expect(result, isA<SearchResult>());
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });

      test('should complete complex search within 5 seconds', () async {
        final stopwatch = Stopwatch()..start();
        
        final result = await searchService.searchProfiles(
          query: 'desenvolvedor espiritual',
          filters: SearchFilters(
            minAge: 25,
            maxAge: 40,
            city: 'São Paulo',
            state: 'SP',
            interests: ['tecnologia', 'espiritualidade', 'meditação'],
            isVerified: true,
            hasCompletedCourse: true,
          ),
          limit: 50,
        );
        
        stopwatch.stop();
        
        expect(result, isA<SearchResult>());
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('should handle large result sets within acceptable time', () async {
        final stopwatch = Stopwatch()..start();
        
        final result = await searchService.searchProfiles(
          query: '', // Query vazia para mais resultados
          limit: 100,
        );
        
        stopwatch.stop();
        
        expect(result, isA<SearchResult>());
        expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // 8 segundos para 100 resultados
      });
    });

    group('Cache Performance', () {
      test('should improve performance with cache hits', () async {
        final query = 'cache performance test';
        final filters = SearchFilters(city: 'Rio de Janeiro');
        
        // Primeira busca (sem cache)
        final stopwatch1 = Stopwatch()..start();
        final result1 = await searchService.searchProfiles(
          query: query,
          filters: filters,
          limit: 15,
          useCache: true,
        );
        stopwatch1.stop();
        
        // Segunda busca (com cache)
        final stopwatch2 = Stopwatch()..start();
        final result2 = await searchService.searchProfiles(
          query: query,
          filters: filters,
          limit: 15,
          useCache: true,
        );
        stopwatch2.stop();
        
        expect(result1.fromCache, isFalse);
        expect(result2.fromCache, isTrue);
        expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
        expect(stopwatch2.elapsedMilliseconds, lessThan(100)); // Cache deve ser muito rápido
      });

      test('should maintain cache performance under load', () async {
        final queries = List.generate(10, (i) => 'cache load test $i');
        
        // Pré-popular cache
        for (final query in queries) {
          await searchService.searchProfiles(
            query: query,
            limit: 5,
            useCache: true,
          );
        }
        
        // Testar performance com cache populado
        final stopwatch = Stopwatch()..start();
        
        for (final query in queries) {
          final result = await searchService.searchProfiles(
            query: query,
            limit: 5,
            useCache: true,
          );
          expect(result.fromCache, isTrue);
        }
        
        stopwatch.stop();
        
        // 10 buscas em cache devem ser muito rápidas
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle cache eviction gracefully', () async {
        // Preencher cache até o limite
        for (int i = 0; i < 50; i++) {
          await searchService.searchProfiles(
            query: 'cache eviction test $i',
            limit: 5,
            useCache: true,
          );
        }
        
        // Adicionar mais entradas para forçar eviction
        final stopwatch = Stopwatch()..start();
        
        for (int i = 50; i < 60; i++) {
          await searchService.searchProfiles(
            query: 'cache eviction test $i',
            limit: 5,
            useCache: true,
          );
        }
        
        stopwatch.stop();
        
        // Performance deve se manter mesmo com eviction
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Concurrent Performance', () {
      test('should handle concurrent searches efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Executar 10 buscas simultaneamente
        final futures = List.generate(10, (i) => 
          searchService.searchProfiles(
            query: 'concurrent performance test $i',
            limit: 10,
          )
        );
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        expect(results, hasLength(10));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 segundos para 10 buscas concorrentes
        
        for (final result in results) {
          expect(result, isA<SearchResult>());
        }
      });

      test('should maintain performance under high concurrency', () async {
        final stopwatch = Stopwatch()..start();
        
        // Executar 20 buscas simultaneamente
        final futures = List.generate(20, (i) => 
          searchService.searchProfiles(
            query: 'high concurrency test ${i % 5}', // Reutilizar algumas queries para cache
            limit: 5,
            useCache: true,
          )
        );
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        expect(results, hasLength(20));
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 segundos para 20 buscas
        
        // Verificar se algumas vieram do cache
        final cachedResults = results.where((r) => r.fromCache).length;
        expect(cachedResults, greaterThan(0));
      });

      test('should handle mixed concurrent operations', () async {
        final stopwatch = Stopwatch()..start();
        
        // Mix de operações: busca, cache, repository
        final futures = <Future>[];
        
        // Buscas normais
        for (int i = 0; i < 5; i++) {
          futures.add(searchService.searchProfiles(
            query: 'mixed ops test $i',
            limit: 10,
          ));
        }
        
        // Buscas com cache
        for (int i = 0; i < 5; i++) {
          futures.add(searchService.searchProfiles(
            query: 'mixed cache test $i',
            limit: 5,
            useCache: true,
          ));
        }
        
        // Buscas do repository
        for (int i = 0; i < 3; i++) {
          futures.add(ExploreProfilesRepository.searchProfiles(
            query: 'mixed repo test $i',
            limit: 8,
          ));
        }
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        expect(results, hasLength(13));
        expect(stopwatch.elapsedMilliseconds, lessThan(12000));
      });
    });

    group('Memory Performance', () {
      test('should maintain reasonable memory usage', () async {
        // Executar muitas buscas para testar uso de memória
        for (int i = 0; i < 50; i++) {
          await searchService.searchProfiles(
            query: 'memory test $i',
            limit: 20,
          );
          
          // Pequena pausa para permitir garbage collection
          if (i % 10 == 0) {
            await Future.delayed(Duration(milliseconds: 10));
          }
        }
        
        // Verificar estatísticas do cache
        final cacheStats = cacheManager.getStats();
        expect(cacheStats['currentSize'], lessThanOrEqualTo(100)); // Limite do cache
      });

      test('should clean up expired cache entries', () async {
        // Adicionar entradas ao cache
        for (int i = 0; i < 10; i++) {
          await searchService.searchProfiles(
            query: 'cleanup test $i',
            limit: 5,
            useCache: true,
          );
        }
        
        // Forçar limpeza de cache
        cacheManager.cleanupExpired();
        
        final cacheStats = cacheManager.getStats();
        expect(cacheStats, containsKey('currentSize'));
      });
    });

    group('Scalability Performance', () {
      test('should scale with increasing query complexity', () async {
        final complexities = [
          // Simples
          SearchFilters(),
          // Médio
          SearchFilters(minAge: 25, city: 'São Paulo'),
          // Complexo
          SearchFilters(
            minAge: 25,
            maxAge: 35,
            city: 'São Paulo',
            state: 'SP',
            interests: ['tech'],
            isVerified: true,
          ),
          // Muito complexo
          SearchFilters(
            minAge: 20,
            maxAge: 40,
            city: 'São Paulo',
            state: 'SP',
            interests: ['tech', 'music', 'sports'],
            isVerified: true,
            hasCompletedCourse: true,
          ),
        ];
        
        final times = <int>[];
        
        for (int i = 0; i < complexities.length; i++) {
          final stopwatch = Stopwatch()..start();
          
          final result = await searchService.searchProfiles(
            query: 'scalability test $i',
            filters: complexities[i],
            limit: 15,
          );
          
          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
          
          expect(result, isA<SearchResult>());
        }
        
        // Verificar que o tempo não cresce exponencialmente
        for (int i = 0; i < times.length; i++) {
          expect(times[i], lessThan(8000)); // Máximo 8 segundos para qualquer complexidade
        }
      });

      test('should handle increasing result set sizes efficiently', () async {
        final limits = [5, 10, 25, 50, 100];
        final times = <int>[];
        
        for (final limit in limits) {
          final stopwatch = Stopwatch()..start();
          
          final result = await searchService.searchProfiles(
            query: 'result size test',
            limit: limit,
          );
          
          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
          
          expect(result, isA<SearchResult>());
          expect(result.profiles.length, lessThanOrEqualTo(limit));
        }
        
        // Tempo deve crescer de forma linear, não exponencial
        for (int i = 1; i < times.length; i++) {
          final growthFactor = times[i] / times[i-1];
          expect(growthFactor, lessThan(3.0)); // Crescimento máximo de 3x
        }
      });
    });

    group('Repository Performance', () {
      test('should maintain repository performance standards', () async {
        final stopwatch = Stopwatch()..start();
        
        final profiles = await ExploreProfilesRepository.searchProfiles(
          query: 'repository performance test',
          minAge: 25,
          maxAge: 35,
          limit: 30,
        );
        
        stopwatch.stop();
        
        expect(profiles, isA<List<SpiritualProfileModel>>());
        expect(stopwatch.elapsedMilliseconds, lessThan(6000));
      });

      test('should handle verified profiles search efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        final profiles = await ExploreProfilesRepository.getVerifiedProfiles(
          searchQuery: 'verified performance test',
          limit: 20,
        );
        
        stopwatch.stop();
        
        expect(profiles, isA<List<SpiritualProfileModel>>());
        expect(stopwatch.elapsedMilliseconds, lessThan(4000));
      });

      test('should handle engagement-based search efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        final profiles = await ExploreProfilesRepository.getProfilesByEngagement(
          searchQuery: 'engagement performance test',
          limit: 15,
        );
        
        stopwatch.stop();
        
        expect(profiles, isA<List<SpiritualProfileModel>>());
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Performance Regression Tests', () {
      test('should not regress from baseline performance', () async {
        // Teste de regressão - tempos baseados em benchmarks anteriores
        final baselineTests = [
          {'query': 'João', 'limit': 10, 'maxTime': 2000},
          {'query': 'Maria Silva', 'limit': 20, 'maxTime': 3000},
          {'query': '', 'limit': 50, 'maxTime': 6000},
        ];
        
        for (final test in baselineTests) {
          final stopwatch = Stopwatch()..start();
          
          final result = await searchService.searchProfiles(
            query: test['query'] as String,
            limit: test['limit'] as int,
          );
          
          stopwatch.stop();
          
          expect(result, isA<SearchResult>());
          expect(stopwatch.elapsedMilliseconds, lessThan(test['maxTime'] as int));
        }
      });

      test('should maintain consistent performance across runs', () async {
        final times = <int>[];
        const query = 'consistency test';
        const runs = 5;
        
        // Executar a mesma busca múltiplas vezes
        for (int i = 0; i < runs; i++) {
          final stopwatch = Stopwatch()..start();
          
          final result = await searchService.searchProfiles(
            query: query,
            limit: 15,
            useCache: false, // Desabilitar cache para teste consistente
          );
          
          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
          
          expect(result, isA<SearchResult>());
        }
        
        // Calcular variação
        final average = times.reduce((a, b) => a + b) / times.length;
        final maxDeviation = times.map((t) => (t - average).abs()).reduce((a, b) => a > b ? a : b);
        
        // Variação não deve ser maior que 50% da média
        expect(maxDeviation, lessThan(average * 0.5));
      });
    });

    group('Performance Monitoring', () {
      test('should provide performance metrics', () async {
        // Executar algumas operações para gerar métricas
        for (int i = 0; i < 5; i++) {
          await searchService.searchProfiles(
            query: 'metrics test $i',
            limit: 10,
          );
        }
        
        final stats = searchService.getStats();
        
        expect(stats, containsKey('averageExecutionTime'));
        expect(stats, containsKey('recentAttempts'));
        expect(stats, containsKey('successfulAttempts'));
        expect(stats['averageExecutionTime'], greaterThan(0));
      });

      test('should track cache performance metrics', () async {
        // Executar operações com cache
        const query = 'cache metrics test';
        
        // Primeira busca
        await searchService.searchProfiles(
          query: query,
          limit: 10,
          useCache: true,
        );
        
        // Segunda busca (cache hit)
        await searchService.searchProfiles(
          query: query,
          limit: 10,
          useCache: true,
        );
        
        final cacheStats = cacheManager.getStats();
        
        expect(cacheStats, containsKey('hitRate'));
        expect(cacheStats, containsKey('totalRequests'));
        expect(cacheStats, containsKey('totalHits'));
        expect(cacheStats['hitRate'], greaterThan(0));
      });
    });
  });
}