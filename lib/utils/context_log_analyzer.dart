import '../models/storie_file_model.dart';
import 'context_validator.dart';
import 'context_debug.dart';

/// Analisador de logs de contexto para debugging avançado
///
/// Esta classe fornece métodos para analisar e gerar relatórios
/// sobre o estado do isolamento de contextos no sistema.
class ContextLogAnalyzer {
  /// Analisa uma lista de stories e gera relatório detalhado
  static Map<String, dynamic> analyzeStories(
      List<StorieFileModel> stories, String expectedContext) {
    final report = <String, dynamic>{};
    final now = DateTime.now();

    // Estatísticas básicas
    report['totalStories'] = stories.length;
    report['expectedContext'] = expectedContext;
    report['analysisTimestamp'] = now.toIso8601String();

    // Análise por contexto
    final contextDistribution = <String, int>{};
    final invalidStories = <Map<String, dynamic>>[];
    final validStories = <StorieFileModel>[];

    for (final story in stories) {
      final storyContext = ContextValidator.normalizeContext(story.contexto);
      contextDistribution[storyContext] =
          (contextDistribution[storyContext] ?? 0) + 1;

      if (storyContext == expectedContext) {
        validStories.add(story);
      } else {
        invalidStories.add({
          'storyId': story.id,
          'title': story.titulo ?? 'Sem título',
          'actualContext': story.contexto,
          'normalizedContext': storyContext,
          'expectedContext': expectedContext,
          'createdAt': story.dataCadastro?.toDate().toIso8601String(),
        });
      }
    }

    report['contextDistribution'] = contextDistribution;
    report['validStories'] = validStories.length;
    report['invalidStories'] = invalidStories.length;
    report['invalidStoriesDetails'] = invalidStories;

    // Análise de vazamentos
    final leakPercentage = stories.isNotEmpty
        ? (invalidStories.length / stories.length * 100).toStringAsFixed(2)
        : '0.00';

    report['leakPercentage'] = leakPercentage;
    report['hasLeaks'] = invalidStories.isNotEmpty;

    // Análise temporal
    final storyAges = stories
        .where((s) => s.dataCadastro != null)
        .map((s) => now.difference(s.dataCadastro!.toDate()).inHours)
        .toList();

    if (storyAges.isNotEmpty) {
      storyAges.sort();
      report['oldestStoryHours'] = storyAges.last;
      report['newestStoryHours'] = storyAges.first;
      report['averageAgeHours'] =
          (storyAges.reduce((a, b) => a + b) / storyAges.length)
              .toStringAsFixed(2);
    }

    // Recomendações
    final recommendations = <String>[];

    if (invalidStories.isNotEmpty) {
      recommendations.add(
          '🚨 CRÍTICO: Encontrados ${invalidStories.length} stories com contexto incorreto');
      recommendations
          .add('🔧 AÇÃO: Investigar origem dos stories com contexto incorreto');
      recommendations.add(
          '🛠️ SOLUÇÃO: Executar limpeza de dados ou corrigir código de inserção');
    }

    if (double.parse(leakPercentage) > 10) {
      recommendations
          .add('⚠️ ALERTA: Taxa de vazamento alta (${leakPercentage}%)');
      recommendations
          .add('🔍 INVESTIGAR: Verificar filtros de contexto nos repositórios');
    }

    if (stories.isEmpty) {
      recommendations.add(
          'ℹ️ INFO: Nenhum story encontrado para o contexto $expectedContext');
      recommendations.add(
          '✅ OK: Isso pode ser normal se não há conteúdo para este contexto');
    }

    report['recommendations'] = recommendations;

    return report;
  }

  /// Gera relatório de saúde do sistema de contextos
  static Map<String, dynamic> generateHealthReport() {
    final report = <String, dynamic>{};
    final now = DateTime.now();

    report['reportType'] = 'CONTEXT_HEALTH_REPORT';
    report['timestamp'] = now.toIso8601String();

    // Verificar configurações de debug
    final debugConfig = {
      'ENABLE_CONTEXT_LOGS': ContextDebug.ENABLE_CONTEXT_LOGS,
      'VALIDATE_CONTEXT_STRICT': ContextDebug.VALIDATE_CONTEXT_STRICT,
      'FILTER_INVALID_CONTEXTS': ContextDebug.FILTER_INVALID_CONTEXTS,
      'DETECT_CONTEXT_LEAKS': ContextDebug.DETECT_CONTEXT_LEAKS,
      'LOG_QUERY_PERFORMANCE': ContextDebug.LOG_QUERY_PERFORMANCE,
    };

    report['debugConfiguration'] = debugConfig;

    // Verificar contextos válidos
    final validContexts = ContextValidator.getValidContexts();
    report['validContexts'] = validContexts;
    report['totalValidContexts'] = validContexts.length;

    // Verificar configuração de coleções
    final collectionMapping = <String, String>{};
    for (final context in validContexts) {
      collectionMapping[context] =
          ContextValidator.getCollectionForContext(context);
    }
    report['collectionMapping'] = collectionMapping;

    // Recomendações de configuração
    final configRecommendations = <String>[];

    if (!ContextDebug.ENABLE_CONTEXT_LOGS) {
      configRecommendations
          .add('⚠️ Logs de contexto desabilitados - habilite para debugging');
    }

    if (!ContextDebug.DETECT_CONTEXT_LEAKS) {
      configRecommendations.add(
          '🚨 Detecção de vazamentos desabilitada - recomendado habilitar');
    }

    if (!ContextDebug.VALIDATE_CONTEXT_STRICT) {
      configRecommendations.add(
          '🔧 Validação rigorosa desabilitada - pode permitir contextos inválidos');
    }

    report['configurationRecommendations'] = configRecommendations;

    return report;
  }

  /// Simula cenários de teste para validar o sistema
  static Map<String, dynamic> runSystemTests() {
    final report = <String, dynamic>{};
    final now = DateTime.now();

    report['testType'] = 'CONTEXT_SYSTEM_TESTS';
    report['timestamp'] = now.toIso8601String();

    final testResults = <String, dynamic>{};

    // Teste 1: Validação de contextos
    try {
      final validContexts = ['principal', 'sinais_rebeca', 'sinais_isaque'];
      final invalidContexts = ['invalid', '', null, 'wrong_context'];

      final validationResults = <String, bool>{};

      for (final context in validContexts) {
        validationResults['valid_$context'] =
            ContextValidator.isValidContext(context);
      }

      for (final context in invalidContexts) {
        validationResults['invalid_${context ?? 'null'}'] =
            !ContextValidator.isValidContext(context);
      }

      testResults['contextValidation'] = {
        'passed': validationResults.values.every((result) => result),
        'details': validationResults,
      };
    } catch (e) {
      testResults['contextValidation'] = {
        'passed': false,
        'error': e.toString(),
      };
    }

    // Teste 2: Normalização de contextos
    try {
      final normalizationTests = <String, String>{};
      normalizationTests['principal'] =
          ContextValidator.normalizeContext('principal');
      normalizationTests['invalid'] =
          ContextValidator.normalizeContext('invalid');
      normalizationTests['null'] = ContextValidator.normalizeContext(null);
      normalizationTests['empty'] = ContextValidator.normalizeContext('');

      final normalizationPassed =
          normalizationTests['principal'] == 'principal' &&
              normalizationTests['invalid'] == 'principal' &&
              normalizationTests['null'] == 'principal' &&
              normalizationTests['empty'] == 'principal';

      testResults['contextNormalization'] = {
        'passed': normalizationPassed,
        'details': normalizationTests,
      };
    } catch (e) {
      testResults['contextNormalization'] = {
        'passed': false,
        'error': e.toString(),
      };
    }

    // Teste 3: Mapeamento de coleções
    try {
      final collectionTests = <String, String>{};
      collectionTests['principal'] =
          ContextValidator.getCollectionForContext('principal');
      collectionTests['sinais_rebeca'] =
          ContextValidator.getCollectionForContext('sinais_rebeca');
      collectionTests['sinais_isaque'] =
          ContextValidator.getCollectionForContext('sinais_isaque');

      final collectionPassed =
          collectionTests['principal'] == 'stories_files' &&
              collectionTests['sinais_rebeca'] == 'stories_sinais_rebeca' &&
              collectionTests['sinais_isaque'] == 'stories_sinais_isaque';

      testResults['collectionMapping'] = {
        'passed': collectionPassed,
        'details': collectionTests,
      };
    } catch (e) {
      testResults['collectionMapping'] = {
        'passed': false,
        'error': e.toString(),
      };
    }

    // Resumo dos testes
    final allTestsPassed = testResults.values
        .every((test) => test is Map && test['passed'] == true);

    report['testResults'] = testResults;
    report['allTestsPassed'] = allTestsPassed;
    report['summary'] = allTestsPassed
        ? '✅ Todos os testes passaram - Sistema funcionando corretamente'
        : '❌ Alguns testes falharam - Verificar detalhes dos testes';

    return report;
  }

  /// Imprime relatório formatado no console
  static void printReport(Map<String, dynamic> report) {
    print('\n' + '=' * 60);
    print('📊 RELATÓRIO DE ANÁLISE DE CONTEXTO');
    print('=' * 60);

    if (report.containsKey('reportType')) {
      print('📋 Tipo: ${report['reportType']}');
    }

    if (report.containsKey('timestamp')) {
      print('🕒 Timestamp: ${report['timestamp']}');
    }

    if (report.containsKey('expectedContext')) {
      print('🎯 Contexto Esperado: ${report['expectedContext']}');
      print('📊 Total de Stories: ${report['totalStories']}');
      print('✅ Stories Válidos: ${report['validStories']}');
      print('❌ Stories Inválidos: ${report['invalidStories']}');
      print('📈 Taxa de Vazamento: ${report['leakPercentage']}%');
    }

    if (report.containsKey('contextDistribution')) {
      print('\n📊 DISTRIBUIÇÃO POR CONTEXTO:');
      final distribution =
          report['contextDistribution'] as Map<String, dynamic>;
      distribution.forEach((context, count) {
        print('   - $context: $count stories');
      });
    }

    if (report.containsKey('recommendations')) {
      print('\n💡 RECOMENDAÇÕES:');
      final recommendations = report['recommendations'] as List<dynamic>;
      for (final rec in recommendations) {
        print('   $rec');
      }
    }

    if (report.containsKey('testResults')) {
      print('\n🧪 RESULTADOS DOS TESTES:');
      final testResults = report['testResults'] as Map<String, dynamic>;
      testResults.forEach((testName, result) {
        final passed = result['passed'] as bool;
        final status = passed ? '✅' : '❌';
        print('   $status $testName: ${passed ? 'PASSOU' : 'FALHOU'}');
      });
    }

    print('=' * 60 + '\n');
  }
}
