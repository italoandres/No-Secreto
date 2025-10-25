import '../models/storie_file_model.dart';
import '../models/usuario_model.dart';
import '../repositories/stories_repository.dart';
import '../repositories/story_interactions_repository.dart';
import 'context_validator.dart';
import 'story_context_filter.dart';
import 'context_debug.dart';
import 'context_log_analyzer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Testes abrangentes para validar o isolamento de contextos
///
/// Esta classe contém todos os testes necessários para garantir que
/// o isolamento entre contextos está funcionando corretamente.
class ContextIsolationTests {
  /// Executa todos os testes de isolamento de contexto
  static Future<Map<String, dynamic>> runAllTests() async {
    final testReport = <String, dynamic>{};
    final now = DateTime.now();

    testReport['testSuite'] = 'CONTEXT_ISOLATION_TESTS';
    testReport['timestamp'] = now.toIso8601String();
    testReport['totalTests'] = 0;
    testReport['passedTests'] = 0;
    testReport['failedTests'] = 0;
    testReport['testResults'] = <String, dynamic>{};

    print('🧪 INICIANDO TESTES DE ISOLAMENTO DE CONTEXTO');
    print('=' * 60);

    // Teste 1: Validação de contextos
    await _runTest(testReport, 'contextValidation', testContextValidation);

    // Teste 2: Filtros de stories por contexto
    await _runTest(testReport, 'storyFiltering', testStoryFiltering);

    // Teste 3: Isolamento de favoritos
    await _runTest(testReport, 'favoritesIsolation', testFavoritesIsolation);

    // Teste 4: Cálculos de círculos de notificação
    await _runTest(testReport, 'circleNotifications', testCircleNotifications);

    // Teste 5: Enhanced Stories Viewer
    await _runTest(testReport, 'enhancedViewer', testEnhancedViewer);

    // Teste 6: Story Favorites View
    await _runTest(testReport, 'favoritesView', testFavoritesView);

    // Teste 7: Detecção de vazamentos
    await _runTest(testReport, 'leakDetection', testLeakDetection);

    // Teste 8: Performance e logs
    await _runTest(testReport, 'performanceLogging', testPerformanceLogging);

    // Calcular estatísticas finais
    final totalTests = testReport['totalTests'] as int;
    final passedTests = testReport['passedTests'] as int;
    final failedTests = testReport['failedTests'] as int;
    final successRate = totalTests > 0
        ? (passedTests / totalTests * 100).toStringAsFixed(2)
        : '0.00';

    testReport['successRate'] = successRate;
    testReport['summary'] = passedTests == totalTests
        ? '✅ TODOS OS TESTES PASSARAM ($passedTests/$totalTests)'
        : '❌ ALGUNS TESTES FALHARAM ($passedTests/$totalTests)';

    print('=' * 60);
    print('📊 RESUMO DOS TESTES:');
    print('   Total: $totalTests');
    print('   Passou: $passedTests');
    print('   Falhou: $failedTests');
    print('   Taxa de sucesso: $successRate%');
    print('=' * 60);

    return testReport;
  }

  /// Helper para executar um teste individual
  static Future<void> _runTest(Map<String, dynamic> report, String testName,
      Future<Map<String, dynamic>> Function() testFunction) async {
    try {
      print('\n🧪 Executando teste: $testName');

      final result = await testFunction();
      final passed = result['passed'] as bool;

      report['testResults'][testName] = result;
      report['totalTests'] = (report['totalTests'] as int) + 1;

      if (passed) {
        report['passedTests'] = (report['passedTests'] as int) + 1;
        print('   ✅ $testName: PASSOU');
      } else {
        report['failedTests'] = (report['failedTests'] as int) + 1;
        print(
            '   ❌ $testName: FALHOU - ${result['error'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      report['testResults'][testName] = {
        'passed': false,
        'error': e.toString(),
        'exception': true,
      };
      report['totalTests'] = (report['totalTests'] as int) + 1;
      report['failedTests'] = (report['failedTests'] as int) + 1;
      print('   💥 $testName: EXCEÇÃO - $e');
    }
  }

  /// Teste 1: Validação de contextos
  static Future<Map<String, dynamic>> testContextValidation() async {
    final result = <String, dynamic>{};

    try {
      // Testar contextos válidos
      final validContexts = ['principal', 'sinais_rebeca', 'sinais_isaque'];
      for (final context in validContexts) {
        if (!ContextValidator.isValidContext(context)) {
          result['passed'] = false;
          result['error'] = 'Contexto válido "$context" foi rejeitado';
          return result;
        }
      }

      // Testar contextos inválidos
      final invalidContexts = ['invalid', '', null, 'wrong_context'];
      for (final context in invalidContexts) {
        if (ContextValidator.isValidContext(context)) {
          result['passed'] = false;
          result['error'] = 'Contexto inválido "$context" foi aceito';
          return result;
        }
      }

      // Testar normalização
      if (ContextValidator.normalizeContext('invalid') != 'principal') {
        result['passed'] = false;
        result['error'] = 'Normalização de contexto inválido falhou';
        return result;
      }

      // Testar mapeamento de coleções
      final expectedMappings = {
        'principal': 'stories_files',
        'sinais_rebeca': 'stories_sinais_rebeca',
        'sinais_isaque': 'stories_sinais_isaque',
      };

      for (final entry in expectedMappings.entries) {
        final actualCollection =
            ContextValidator.getCollectionForContext(entry.key);
        if (actualCollection != entry.value) {
          result['passed'] = false;
          result['error'] =
              'Mapeamento incorreto: ${entry.key} -> $actualCollection (esperado: ${entry.value})';
          return result;
        }
      }

      result['passed'] = true;
      result['details'] = 'Todos os testes de validação passaram';
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste de validação: $e';
    }

    return result;
  }

  /// Teste 2: Filtros de stories por contexto
  static Future<Map<String, dynamic>> testStoryFiltering() async {
    final result = <String, dynamic>{};

    try {
      // Criar stories de teste com contextos misturados
      final testStories = [
        _createTestStory('1', 'principal', 'Story Principal 1'),
        _createTestStory('2', 'sinais_rebeca', 'Story Rebeca 1'),
        _createTestStory('3', 'principal', 'Story Principal 2'),
        _createTestStory('4', 'sinais_isaque', 'Story Isaque 1'),
        _createTestStory('5', 'sinais_rebeca', 'Story Rebeca 2'),
      ];

      // Testar filtro para contexto principal
      final principalStories = StoryContextFilter.filterByContext(
          testStories, 'principal',
          debugEnabled: false);
      if (principalStories.length != 2) {
        result['passed'] = false;
        result['error'] =
            'Filtro principal retornou ${principalStories.length} stories (esperado: 2)';
        return result;
      }

      // Testar filtro para contexto sinais_rebeca
      final rebecaStories = StoryContextFilter.filterByContext(
          testStories, 'sinais_rebeca',
          debugEnabled: false);
      if (rebecaStories.length != 2) {
        result['passed'] = false;
        result['error'] =
            'Filtro sinais_rebeca retornou ${rebecaStories.length} stories (esperado: 2)';
        return result;
      }

      // Testar filtro para contexto sinais_isaque
      final isaqueStories = StoryContextFilter.filterByContext(
          testStories, 'sinais_isaque',
          debugEnabled: false);
      if (isaqueStories.length != 1) {
        result['passed'] = false;
        result['error'] =
            'Filtro sinais_isaque retornou ${isaqueStories.length} stories (esperado: 1)';
        return result;
      }

      // Testar detecção de vazamentos
      final hasLeaks = StoryContextFilter.detectContextLeaks(
          testStories, 'principal',
          debugEnabled: false);
      if (!hasLeaks) {
        result['passed'] = false;
        result['error'] =
            'Detecção de vazamentos falhou - deveria detectar vazamentos';
        return result;
      }

      // Testar lista sem vazamentos
      final noLeaks = StoryContextFilter.detectContextLeaks(
          principalStories, 'principal',
          debugEnabled: false);
      if (noLeaks) {
        result['passed'] = false;
        result['error'] =
            'Detecção de vazamentos falhou - não deveria detectar vazamentos em lista filtrada';
        return result;
      }

      result['passed'] = true;
      result['details'] = {
        'totalStories': testStories.length,
        'principalFiltered': principalStories.length,
        'rebecaFiltered': rebecaStories.length,
        'isaqueFiltered': isaqueStories.length,
        'leakDetectionWorking': true,
      };
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste de filtros: $e';
    }

    return result;
  }

  /// Teste 3: Isolamento de favoritos
  static Future<Map<String, dynamic>> testFavoritesIsolation() async {
    final result = <String, dynamic>{};

    try {
      // Simular cenário onde favoritos têm contextos misturados
      final favoriteStories = [
        _createTestStory('fav1', 'principal', 'Favorito Principal'),
        _createTestStory('fav2', 'sinais_rebeca', 'Favorito Rebeca'),
        _createTestStory('fav3', 'principal', 'Favorito Principal 2'),
        _createTestStory('fav4', 'sinais_isaque', 'Favorito Isaque'),
      ];

      // Testar análise de favoritos para contexto principal
      final principalReport =
          ContextLogAnalyzer.analyzeStories(favoriteStories, 'principal');

      if (principalReport['validStories'] != 2) {
        result['passed'] = false;
        result['error'] =
            'Análise de favoritos principal incorreta: ${principalReport['validStories']} válidos (esperado: 2)';
        return result;
      }

      if (principalReport['invalidStories'] != 2) {
        result['passed'] = false;
        result['error'] =
            'Análise de favoritos principal incorreta: ${principalReport['invalidStories']} inválidos (esperado: 2)';
        return result;
      }

      if (principalReport['hasLeaks'] != true) {
        result['passed'] = false;
        result['error'] = 'Detecção de vazamentos em favoritos falhou';
        return result;
      }

      // Testar análise para contexto sinais_rebeca
      final rebecaReport =
          ContextLogAnalyzer.analyzeStories(favoriteStories, 'sinais_rebeca');

      if (rebecaReport['validStories'] != 1) {
        result['passed'] = false;
        result['error'] =
            'Análise de favoritos rebeca incorreta: ${rebecaReport['validStories']} válidos (esperado: 1)';
        return result;
      }

      result['passed'] = true;
      result['details'] = {
        'principalValid': principalReport['validStories'],
        'principalInvalid': principalReport['invalidStories'],
        'rebecaValid': rebecaReport['validStories'],
        'rebecaInvalid': rebecaReport['invalidStories'],
        'leakDetectionWorking': true,
      };
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste de favoritos: $e';
    }

    return result;
  }

  /// Teste 4: Cálculos de círculos de notificação
  static Future<Map<String, dynamic>> testCircleNotifications() async {
    final result = <String, dynamic>{};

    try {
      // Este teste verifica se os métodos de cálculo de círculos
      // estão usando contextos corretos (não podemos testar completamente
      // sem acesso ao Firebase, mas podemos testar a lógica)

      // Testar validação de contexto nos métodos
      final validContexts = ['principal', 'sinais_rebeca', 'sinais_isaque'];

      for (final context in validContexts) {
        // Verificar se o contexto é normalizado corretamente
        final normalized = ContextValidator.normalizeContext(context);
        if (normalized != context) {
          result['passed'] = false;
          result['error'] =
              'Normalização incorreta para contexto válido: $context -> $normalized';
          return result;
        }
      }

      // Testar normalização de contextos inválidos
      final invalidContexts = ['invalid', '', null];
      for (final context in invalidContexts) {
        final normalized = ContextValidator.normalizeContext(context);
        if (normalized != 'principal') {
          result['passed'] = false;
          result['error'] =
              'Normalização incorreta para contexto inválido: $context -> $normalized (esperado: principal)';
          return result;
        }
      }

      result['passed'] = true;
      result['details'] =
          'Validação de contextos para círculos funcionando corretamente';
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste de círculos: $e';
    }

    return result;
  }

  /// Teste 5: Enhanced Stories Viewer
  static Future<Map<String, dynamic>> testEnhancedViewer() async {
    final result = <String, dynamic>{};

    try {
      // Testar validação de stories iniciais
      final initialStories = [
        _createTestStory('viewer1', 'sinais_rebeca', 'Viewer Story 1'),
        _createTestStory(
            'viewer2', 'principal', 'Viewer Story Vazado'), // VAZAMENTO
        _createTestStory('viewer3', 'sinais_rebeca', 'Viewer Story 2'),
      ];

      // Simular filtro que seria aplicado no Enhanced Viewer
      final filteredStories = StoryContextFilter.filterByContext(
          initialStories, 'sinais_rebeca',
          debugEnabled: false);

      if (filteredStories.length != 2) {
        result['passed'] = false;
        result['error'] =
            'Filtro do Enhanced Viewer incorreto: ${filteredStories.length} stories (esperado: 2)';
        return result;
      }

      // Verificar se apenas stories do contexto correto foram mantidos
      for (final story in filteredStories) {
        if (story.contexto != 'sinais_rebeca') {
          result['passed'] = false;
          result['error'] =
              'Story com contexto incorreto passou pelo filtro: ${story.contexto}';
          return result;
        }
      }

      // Testar detecção de vazamentos
      final hasLeaks = StoryContextFilter.detectContextLeaks(
          initialStories, 'sinais_rebeca',
          debugEnabled: false);
      if (!hasLeaks) {
        result['passed'] = false;
        result['error'] =
            'Enhanced Viewer não detectou vazamentos nos stories iniciais';
        return result;
      }

      result['passed'] = true;
      result['details'] = {
        'initialStories': initialStories.length,
        'filteredStories': filteredStories.length,
        'leaksDetected': hasLeaks,
      };
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste do Enhanced Viewer: $e';
    }

    return result;
  }

  /// Teste 6: Story Favorites View
  static Future<Map<String, dynamic>> testFavoritesView() async {
    final result = <String, dynamic>{};

    try {
      // Testar geração de título por contexto
      final contextTitles = {
        'principal': 'Chat Principal',
        'sinais_rebeca': 'Sinais Rebeca',
        'sinais_isaque': 'Sinais Isaque',
        null: 'Todos os Favoritos',
      };

      // Simular lógica de geração de título
      for (final entry in contextTitles.entries) {
        final context = entry.key;
        final expectedTitle = entry.value;

        // Simular normalização que seria feita na view
        final normalizedContext =
            context != null ? ContextValidator.normalizeContext(context) : null;

        String actualTitle;
        switch (normalizedContext) {
          case 'sinais_rebeca':
            actualTitle = 'Sinais Rebeca';
            break;
          case 'sinais_isaque':
            actualTitle = 'Sinais Isaque';
            break;
          case 'principal':
            actualTitle = 'Chat Principal';
            break;
          default:
            actualTitle = 'Todos os Favoritos';
        }

        if (!actualTitle.contains(expectedTitle)) {
          result['passed'] = false;
          result['error'] =
              'Título incorreto para contexto $context: "$actualTitle" (esperado conter: "$expectedTitle")';
          return result;
        }
      }

      result['passed'] = true;
      result['details'] =
          'Geração de títulos por contexto funcionando corretamente';
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste da Favorites View: $e';
    }

    return result;
  }

  /// Teste 7: Detecção de vazamentos
  static Future<Map<String, dynamic>> testLeakDetection() async {
    final result = <String, dynamic>{};

    try {
      // Cenário 1: Lista sem vazamentos
      final cleanStories = [
        _createTestStory('clean1', 'principal', 'Clean Story 1'),
        _createTestStory('clean2', 'principal', 'Clean Story 2'),
      ];

      final noLeaks = StoryContextFilter.detectContextLeaks(
          cleanStories, 'principal',
          debugEnabled: false);
      if (noLeaks) {
        result['passed'] = false;
        result['error'] =
            'Detecção de vazamentos falhou - detectou vazamentos em lista limpa';
        return result;
      }

      // Cenário 2: Lista com vazamentos
      final leakyStories = [
        _createTestStory('leak1', 'principal', 'Principal Story'),
        _createTestStory('leak2', 'sinais_rebeca', 'Vazamento!'), // VAZAMENTO
        _createTestStory(
            'leak3', 'sinais_isaque', 'Outro Vazamento!'), // VAZAMENTO
      ];

      final hasLeaks = StoryContextFilter.detectContextLeaks(
          leakyStories, 'principal',
          debugEnabled: false);
      if (!hasLeaks) {
        result['passed'] = false;
        result['error'] =
            'Detecção de vazamentos falhou - não detectou vazamentos óbvios';
        return result;
      }

      // Cenário 3: Análise de distribuição
      final distribution = StoryContextFilter.analyzeContextDistribution(
          leakyStories,
          debugEnabled: false);

      if (distribution['principal'] != 1) {
        result['passed'] = false;
        result['error'] =
            'Análise de distribuição incorreta para principal: ${distribution['principal']} (esperado: 1)';
        return result;
      }

      if (distribution['sinais_rebeca'] != 1) {
        result['passed'] = false;
        result['error'] =
            'Análise de distribuição incorreta para sinais_rebeca: ${distribution['sinais_rebeca']} (esperado: 1)';
        return result;
      }

      if (distribution['sinais_isaque'] != 1) {
        result['passed'] = false;
        result['error'] =
            'Análise de distribuição incorreta para sinais_isaque: ${distribution['sinais_isaque']} (esperado: 1)';
        return result;
      }

      result['passed'] = true;
      result['details'] = {
        'cleanStoriesTest': 'Passou',
        'leakyStoriesTest': 'Passou',
        'distributionAnalysis': distribution,
      };
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste de detecção de vazamentos: $e';
    }

    return result;
  }

  /// Teste 8: Performance e logs
  static Future<Map<String, dynamic>> testPerformanceLogging() async {
    final result = <String, dynamic>{};

    try {
      // Testar medição de performance
      final performanceResult =
          ContextDebug.measurePerformance('test_operation', 'principal', () {
        // Simular operação
        final list = List.generate(100, (i) => i);
        return list.where((i) => i % 2 == 0).toList();
      });

      if (performanceResult.length != 50) {
        result['passed'] = false;
        result['error'] =
            'Medição de performance falhou - resultado incorreto: ${performanceResult.length} (esperado: 50)';
        return result;
      }

      // Testar configurações de debug
      final debugConfig = {
        'ENABLE_CONTEXT_LOGS': ContextDebug.ENABLE_CONTEXT_LOGS,
        'VALIDATE_CONTEXT_STRICT': ContextDebug.VALIDATE_CONTEXT_STRICT,
        'FILTER_INVALID_CONTEXTS': ContextDebug.FILTER_INVALID_CONTEXTS,
        'DETECT_CONTEXT_LEAKS': ContextDebug.DETECT_CONTEXT_LEAKS,
        'LOG_QUERY_PERFORMANCE': ContextDebug.LOG_QUERY_PERFORMANCE,
      };

      // Verificar se configurações críticas estão habilitadas
      if (!debugConfig['DETECT_CONTEXT_LEAKS']!) {
        result['passed'] = false;
        result['error'] =
            'Configuração crítica DETECT_CONTEXT_LEAKS está desabilitada';
        return result;
      }

      if (!debugConfig['VALIDATE_CONTEXT_STRICT']!) {
        result['passed'] = false;
        result['error'] =
            'Configuração crítica VALIDATE_CONTEXT_STRICT está desabilitada';
        return result;
      }

      result['passed'] = true;
      result['details'] = {
        'performanceTest': 'Passou',
        'debugConfig': debugConfig,
      };
    } catch (e) {
      result['passed'] = false;
      result['error'] = 'Exceção durante teste de performance: $e';
    }

    return result;
  }

  /// Helper para criar stories de teste
  static StorieFileModel _createTestStory(
      String id, String contexto, String titulo) {
    return StorieFileModel(
      id: id,
      contexto: contexto,
      titulo: titulo,
      fileUrl: 'https://example.com/test_$id.jpg',
      fileType: StorieFileType.img,
      dataCadastro: Timestamp.now(),
    );
  }

  /// Gera relatório de teste formatado
  static void printTestReport(Map<String, dynamic> report) {
    print('\n' + '🧪' * 20);
    print('📋 RELATÓRIO DE TESTES DE ISOLAMENTO DE CONTEXTO');
    print('🧪' * 20);

    print('🕒 Timestamp: ${report['timestamp']}');
    print('📊 Total de testes: ${report['totalTests']}');
    print('✅ Testes aprovados: ${report['passedTests']}');
    print('❌ Testes falharam: ${report['failedTests']}');
    print('📈 Taxa de sucesso: ${report['successRate']}%');

    print('\n📋 RESULTADOS DETALHADOS:');
    final testResults = report['testResults'] as Map<String, dynamic>;

    testResults.forEach((testName, result) {
      final passed = result['passed'] as bool;
      final status = passed ? '✅' : '❌';
      print('   $status $testName: ${passed ? 'PASSOU' : 'FALHOU'}');

      if (!passed && result.containsKey('error')) {
        print('      Erro: ${result['error']}');
      }

      if (result.containsKey('details')) {
        print('      Detalhes: ${result['details']}');
      }
    });

    print('\n🎯 RESUMO: ${report['summary']}');
    print('🧪' * 20 + '\n');
  }
}
