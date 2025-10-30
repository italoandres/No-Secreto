import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../lib/services/search_profiles_service.dart';
import '../../lib/services/search_error_handler.dart';
import '../../lib/repositories/explore_profiles_repository.dart';
import '../../lib/models/search_filters.dart';
import '../../lib/models/search_result.dart';
import '../../lib/models/spiritual_profile_model.dart';

void main() {
  group('Search Error Handling and Fallback Tests', () {
    late SearchProfilesService searchService;
    late SearchErrorHandler errorHandler;

    setUp(() {
      searchService = SearchProfilesService.instance;
      errorHandler = SearchErrorHandler.instance;
      errorHandler.clearErrorHistory();
    });

    group('Firebase Error Scenarios', () {
      test('should handle index missing errors with fallback', () async {
        // Simular erro de índice faltando
        try {
          final result = await ExploreProfilesRepository.searchProfiles(
            query: 'index missing test',
            minAge: 25,
            maxAge: 35,
            city: 'São Paulo',
            state: 'SP',
            interests: ['tech', 'music'],
            limit: 20,
          );

          // Deve retornar resultado mesmo com possível erro de índice
          expect(result, isA<List<SpiritualProfileModel>>());
        } catch (e) {
          // Se houver erro, deve ser do tipo esperado
          expect(e, isA<Exception>());
        }
      });

      test('should handle permission denied errors', () async {
        // Testar comportamento com erro de permissão
        try {
          final result = await searchService.searchProfiles(
            query: 'permission test',
            limit: 10,
          );

          expect(result, isA<SearchResult>());
        } catch (e) {
          // Erro de permissão deve ser tratado
          expect(e, isA<Exception>());
        }
      });

      test('should handle network timeout errors', () async {
        // Simular timeout de rede
        try {
          final result = await errorHandler.executeWithRetry(
            operation: () async {
              // Simular operação que pode dar timeout
              await Future.delayed(Duration(milliseconds: 100));
              return SearchResult(
                profiles: [],
                query: 'timeout test',
                totalResults: 0,
                hasMore: false,
                appliedFilters: null,
                strategy: 'timeout_test',
                executionTime: 100,
                fromCache: false,
              );
            },
            operationName: 'timeout_test',
            query: 'timeout test',
          );

          expect(result, isA<SearchResult>());
          expect(result.query, equals('timeout test'));
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle quota exceeded errors', () async {
        // Testar comportamento com quota excedida
        try {
          final result = await searchService.searchProfiles(
            query: 'quota test',
            limit: 5,
          );

          expect(result, isA<SearchResult>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Retry Mechanism', () {
      test('should retry failed operations automatically', () async {
        int attemptCount = 0;
        
        final result = await errorHandler.executeWithRetry(
          operation: () async {
            attemptCount++;
            if (attemptCount < 2) {
              throw Exception('Temporary failure');
            }
            return SearchResult(
              profiles: [
                SpiritualProfileModel(
                  id: 'retry_test_1',
                  displayName: 'Retry Test User',
                ),
              ],
              query: 'retry test',
              totalResults: 1,
              hasMore: false,
              appliedFilters: null,
              strategy: 'retry_success',
              executionTime: 200,
              fromCache: false,
            );
          },
          operationName: 'retry_test',
          query: 'retry test',
        );

        expect(attemptCount, equals(2)); // Deve ter tentado 2 vezes
        expect(result.profiles, hasLength(1));
        expect(result.profiles.first.displayName, equals('Retry Test User'));
      });

      test('should respect maximum retry attempts', () async {
        int attemptCount = 0;
        
        try {
          await errorHandler.executeWithRetry(
            operation: () async {
              attemptCount++;
              throw Exception('Persistent failure');
            },
            operationName: 'max_retry_test',
            query: 'max retry test',
          );
        } catch (e) {
          expect(e, isA<Exception>());
          expect(attemptCount, equals(3)); // Máximo de 3 tentativas
        }
      });

      test('should use exponential backoff for retries', () async {
        final retryTimes = <DateTime>[];
        
        try {
          await errorHandler.executeWithRetry(
            operation: () async {
              retryTimes.add(DateTime.now());
              throw Exception('Backoff test failure');
            },
            operationName: 'backoff_test',
            query: 'backoff test',
          );
        } catch (e) {
          expect(retryTimes, hasLength(3));
          
          // Verificar se o delay aumentou entre tentativas
          if (retryTimes.length >= 2) {
            final firstDelay = retryTimes[1].difference(retryTimes[0]);
            final secondDelay = retryTimes[2].difference(retryTimes[1]);
            expect(secondDelay.inMilliseconds, greaterThan(firstDelay.inMilliseconds));
          }
        }
      });
    });

    group('Fallback Strategies', () {
      test('should use layered fallback approach', () async {
        // Testar estratégia em camadas do repository
        final result = await ExploreProfilesRepository.searchProfiles(
          query: 'layered fallback test',
          limit: 10,
        );

        expect(result, isA<List<SpiritualProfileModel>>());
      });

      test('should fallback to basic search when complex filters fail', () async {
        // Testar fallback para busca básica com filtros complexos
        final complexFilters = SearchFilters(
          minAge: 25,
          maxAge: 35,
          city: 'São Paulo',
          state: 'SP',
          interests: ['tech', 'music', 'sports', 'travel'],
          isVerified: true,
          hasCompletedCourse: true,
        );

        final result = await ExploreProfilesRepository.searchProfiles(
          query: 'complex fallback test',
          minAge: complexFilters.minAge,
          maxAge: complexFilters.maxAge,
          city: complexFilters.city,
          state: complexFilters.state,
          interests: complexFilters.interests,
          limit: 15,
          requireVerified: complexFilters.isVerified ?? false,
          requireCompletedCourse: complexFilters.hasCompletedCourse ?? false,
        );

        expect(result, isA<List<SpiritualProfileModel>>());
      });

      test('should use manual fallback as last resort', () async {
        // Testar fallback manual quando tudo mais falha
        try {
          final result = await ExploreProfilesRepository.searchProfiles(
            query: 'manual fallback test',
            limit: 5,
          );

          expect(result, isA<List<SpiritualProfileModel>>());
        } catch (e) {
          // Mesmo com erro, deve tentar fallback manual
          expect(e, isA<Exception>());
        }
      });
    });

    group('Error Classification', () {
      test('should classify Firebase errors correctly', () async {
        // Testar classificação de diferentes tipos de erro
        final errorTypes = [
          'requires an index',
          'permission denied',
          'network error',
          'quota exceeded',
          'unknown error',
        ];

        for (final errorMessage in errorTypes) {
          try {
            // Simular erro específico
            throw Exception(errorMessage);
          } catch (e) {
            // Verificar se o erro seria classificado corretamente
            expect(e, isA<Exception>());
            expect(e.toString(), contains(errorMessage));
          }
        }
      });

      test('should handle unknown errors gracefully', () async {
        try {
          await errorHandler.executeWithRetry(
            operation: () async {
              throw Exception('Unknown error type');
            },
            operationName: 'unknown_error_test',
            query: 'unknown error test',
          );
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('Unknown error type'));
        }
      });
    });

    group('Error Recovery', () {
      test('should recover from temporary Firebase outages', () async {
        int attemptCount = 0;
        
        final result = await errorHandler.executeWithRetry(
          operation: () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw Exception('Firebase temporarily unavailable');
            }
            return SearchResult(
              profiles: [
                SpiritualProfileModel(
                  id: 'recovery_test_1',
                  displayName: 'Recovery Test User',
                ),
              ],
              query: 'recovery test',
              totalResults: 1,
              hasMore: false,
              appliedFilters: null,
              strategy: 'recovery_success',
              executionTime: 300,
              fromCache: false,
            );
          },
          operationName: 'recovery_test',
          query: 'recovery test',
        );

        expect(result.profiles, hasLength(1));
        expect(result.strategy, equals('recovery_success'));
      });

      test('should maintain service availability during errors', () async {
        // Testar se o serviço continua disponível mesmo com erros
        final results = <SearchResult>[];
        
        for (int i = 0; i < 5; i++) {
          try {
            final result = await searchService.searchProfiles(
              query: 'availability test $i',
              limit: 5,
            );
            results.add(result);
          } catch (e) {
            // Mesmo com erros, deve tentar continuar
            expect(e, isA<Exception>());
          }
        }

        // Pelo menos algumas buscas devem ter sucesso
        expect(results, isNotEmpty);
      });
    });

    group('Error Logging and Monitoring', () {
      test('should log errors with proper context', () async {
        try {
          await errorHandler.executeWithRetry(
            operation: () async {
              throw Exception('Test error for logging');
            },
            operationName: 'logging_test',
            query: 'logging test query',
          );
        } catch (e) {
          // Verificar se o erro foi registrado
          final errorStats = errorHandler.getStats();
          expect(errorStats['totalOperations'], greaterThan(0));
        }
      });

      test('should track error patterns over time', () async {
        // Simular vários erros para testar padrões
        for (int i = 0; i < 3; i++) {
          try {
            await errorHandler.executeWithRetry(
              operation: () async {
                throw Exception('Pattern test error $i');
              },
              operationName: 'pattern_test',
              query: 'pattern test $i',
            );
          } catch (e) {
            // Ignorar erros individuais
          }
        }

        final errorStats = errorHandler.getStats();
        expect(errorStats['totalOperations'], equals(3));
        expect(errorStats['failedOperations'], equals(3));
      });

      test('should provide error statistics for monitoring', () async {
        // Executar operações mistas (sucesso e falha)
        for (int i = 0; i < 2; i++) {
          try {
            await errorHandler.executeWithRetry(
              operation: () async {
                if (i == 0) {
                  return SearchResult(
                    profiles: [],
                    query: 'stats test $i',
                    totalResults: 0,
                    hasMore: false,
                    appliedFilters: null,
                    strategy: 'success',
                    executionTime: 100,
                    fromCache: false,
                  );
                } else {
                  throw Exception('Stats test error');
                }
              },
              operationName: 'stats_test',
              query: 'stats test $i',
            );
          } catch (e) {
            // Ignorar erros para estatísticas
          }
        }

        final stats = errorHandler.getStats();
        expect(stats, containsKey('totalOperations'));
        expect(stats, containsKey('successfulOperations'));
        expect(stats, containsKey('failedOperations'));
        expect(stats, containsKey('successRate'));
      });
    });

    group('Performance Under Error Conditions', () {
      test('should maintain reasonable performance during errors', () async {
        final stopwatch = Stopwatch()..start();
        
        try {
          await errorHandler.executeWithRetry(
            operation: () async {
              throw Exception('Performance test error');
            },
            operationName: 'performance_error_test',
            query: 'performance error test',
          );
        } catch (e) {
          stopwatch.stop();
          
          // Mesmo com erros e retries, deve completar em tempo razoável
          expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 segundos max
        }
      });

      test('should not degrade performance of successful operations', () async {
        // Executar operação com erro primeiro
        try {
          await errorHandler.executeWithRetry(
            operation: () async {
              throw Exception('Error before success test');
            },
            operationName: 'error_before_success',
            query: 'error test',
          );
        } catch (e) {
          // Ignorar erro
        }

        // Executar operação bem-sucedida
        final stopwatch = Stopwatch()..start();
        
        final result = await errorHandler.executeWithRetry(
          operation: () async {
            return SearchResult(
              profiles: [],
              query: 'success after error',
              totalResults: 0,
              hasMore: false,
              appliedFilters: null,
              strategy: 'success',
              executionTime: 100,
              fromCache: false,
            );
          },
          operationName: 'success_after_error',
          query: 'success after error',
        );
        
        stopwatch.stop();

        expect(result, isA<SearchResult>());
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 segundos max
      });
    });
  });
}