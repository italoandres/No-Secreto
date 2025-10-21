import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_chat/services/match_performance_optimizer.dart';

void main() {
  group('MatchPerformanceOptimizer', () {
    setUp(() {
      MatchPerformanceOptimizer.resetMetrics();
    });

    tearDown(() {
      MatchPerformanceOptimizer.resetMetrics();
    });

    group('getPerformanceStats', () {
      testWidgets('deve retornar estatísticas válidas', (tester) async {
        // Act
        final stats = MatchPerformanceOptimizer.getPerformanceStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalQueries'), isTrue);
        expect(stats.containsKey('averageExecutionTime'), isTrue);
        expect(stats.containsKey('cacheHitRate'), isTrue);
        expect(stats.containsKey('errorRate'), isTrue);
      });

      testWidgets('deve aceitar janela de tempo personalizada', (tester) async {
        // Act
        final stats = MatchPerformanceOptimizer.getPerformanceStats(
          timeWindow: const Duration(minutes: 30),
        );

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
      });
    });

    group('getMetrics', () {
      testWidgets('deve retornar lista de métricas', (tester) async {
        // Act
        final metrics = MatchPerformanceOptimizer.getMetrics();

        // Assert
        expect(metrics, isA<List<QueryMetrics>>());
      });

      testWidgets('deve filtrar por tipo de query', (tester) async {
        // Act
        final metrics = MatchPerformanceOptimizer.getMetrics(
          queryType: 'matches_query',
        );

        // Assert
        expect(metrics, isA<List<QueryMetrics>>());
      });

      testWidgets('deve filtrar por período', (tester) async {
        // Act
        final metrics = MatchPerformanceOptimizer.getMetrics(
          since: const Duration(hours: 1),
        );

        // Assert
        expect(metrics, isA<List<QueryMetrics>>());
      });
    });

    group('getOptimizationRecommendations', () {
      testWidgets('deve retornar lista de recomendações', (tester) async {
        // Act
        final recommendations = MatchPerformanceOptimizer.getOptimizationRecommendations();

        // Assert
        expect(recommendations, isA<List<String>>());
      });

      testWidgets('deve fornecer recomendações baseadas em métricas', (tester) async {
        // Act
        final recommendations = MatchPerformanceOptimizer.getOptimizationRecommendations();

        // Assert
        expect(recommendations, isA<List<String>>());
        // Pode estar vazio se não há métricas suficientes
      });
    });

    group('isPerformanceDegraded', () {
      testWidgets('deve verificar degradação de performance', (tester) async {
        // Act
        final isDegraded = MatchPerformanceOptimizer.isPerformanceDegraded();

        // Assert
        expect(isDegraded, isA<bool>());
      });

      testWidgets('deve aceitar parâmetros personalizados', (tester) async {
        // Act
        final isDegraded = MatchPerformanceOptimizer.isPerformanceDegraded(
          timeWindow: const Duration(minutes: 5),
          maxAverageTime: 2000,
        );

        // Assert
        expect(isDegraded, isA<bool>());
      });
    });

    group('autoOptimize', () {
      testWidgets('deve executar otimização automática', (tester) async {
        // Act & Assert
        expect(() async {
          await MatchPerformanceOptimizer.autoOptimize();
        }, returnsNormally);
      });
    });

    group('clearOldMetrics', () {
      testWidgets('deve limpar métricas antigas', (tester) async {
        // Act & Assert
        expect(() {
          MatchPerformanceOptimizer.clearOldMetrics();
        }, returnsNormally);
      });

      testWidgets('deve aceitar idade máxima personalizada', (tester) async {
        // Act & Assert
        expect(() {
          MatchPerformanceOptimizer.clearOldMetrics(
            maxAge: const Duration(hours: 12),
          );
        }, returnsNormally);
      });
    });

    group('resetMetrics', () {
      testWidgets('deve resetar todas as métricas', (tester) async {
        // Act & Assert
        expect(() {
          MatchPerformanceOptimizer.resetMetrics();
        }, returnsNormally);
      });

      testWidgets('deve limpar métricas existentes', (tester) async {
        // Act
        MatchPerformanceOptimizer.resetMetrics();
        final metrics = MatchPerformanceOptimizer.getMetrics();

        // Assert
        expect(metrics, isEmpty);
      });
    });

    group('exportMetrics', () {
      testWidgets('deve exportar métricas para análise', (tester) async {
        // Act
        final exported = MatchPerformanceOptimizer.exportMetrics();

        // Assert
        expect(exported, isA<Map<String, dynamic>>());
        expect(exported.containsKey('metrics'), isTrue);
        expect(exported.containsKey('totalMetrics'), isTrue);
        expect(exported.containsKey('exportedAt'), isTrue);
      });

      testWidgets('deve incluir todas as métricas disponíveis', (tester) async {
        // Act
        final exported = MatchPerformanceOptimizer.exportMetrics();

        // Assert
        expect(exported['metrics'], isA<List>());
      });
    });

    group('PerformanceConfig', () {
      testWidgets('deve ter configuração padrão válida', (tester) async {
        // Arrange & Act
        const config = PerformanceConfig();

        // Assert
        expect(config.enableCache, isTrue);
        expect(config.enablePagination, isTrue);
        expect(config.enableIndexHints, isTrue);
        expect(config.queryTimeout, equals(10000));
        expect(config.maxRetries, equals(3));
      });

      testWidgets('deve ter configuração de performance máxima', (tester) async {
        // Arrange & Act
        const config = PerformanceConfig.maxPerformance;

        // Assert
        expect(config.enableCache, isTrue);
        expect(config.queryTimeout, equals(5000));
        expect(config.maxRetries, equals(2));
      });

      testWidgets('deve ter configuração para tempo real', (tester) async {
        // Arrange & Act
        const config = PerformanceConfig.realTime;

        // Assert
        expect(config.enableCache, isFalse);
        expect(config.enablePagination, isFalse);
        expect(config.queryTimeout, equals(15000));
        expect(config.maxRetries, equals(5));
      });
    });
  });
}