import '../models/storie_file_model.dart';
import 'context_validator.dart';
import 'story_context_filter.dart';
import 'context_debug.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Classe para testar as utilidades de contexto
///
/// Esta classe fornece métodos para testar e validar o funcionamento
/// das utilidades de contexto criadas.
class ContextUtilsTest {
  /// Testa a validação de contextos
  static void testContextValidation() {
    print('🧪 TESTE: Iniciando testes de validação de contexto');

    // Testes de contextos válidos
    assert(ContextValidator.isValidContext('principal') == true);
    assert(ContextValidator.isValidContext('sinais_rebeca') == true);
    assert(ContextValidator.isValidContext('sinais_isaque') == true);

    // Testes de contextos inválidos
    assert(ContextValidator.isValidContext('invalido') == false);
    assert(ContextValidator.isValidContext('') == false);
    assert(ContextValidator.isValidContext(null) == false);

    // Testes de normalização
    assert(ContextValidator.normalizeContext('principal') == 'principal');
    assert(ContextValidator.normalizeContext('invalido') == 'principal');
    assert(ContextValidator.normalizeContext(null) == 'principal');

    // Testes de coleções
    assert(ContextValidator.getCollectionForContext('principal') ==
        'stories_files');
    assert(ContextValidator.getCollectionForContext('sinais_rebeca') ==
        'stories_sinais_rebeca');
    assert(ContextValidator.getCollectionForContext('sinais_isaque') ==
        'stories_sinais_isaque');

    print('✅ TESTE: Validação de contexto passou em todos os testes');
  }

  /// Testa o filtro de stories por contexto
  static void testStoryFiltering() {
    print('🧪 TESTE: Iniciando testes de filtro de stories');

    // Criar stories de teste
    final stories = [
      _createTestStory('1', 'principal'),
      _createTestStory('2', 'sinais_rebeca'),
      _createTestStory('3', 'principal'),
      _createTestStory('4', 'sinais_isaque'),
      _createTestStory('5', 'sinais_rebeca'),
    ];

    // Testar filtro por contexto principal
    final principalStories = StoryContextFilter.filterByContext(
        stories, 'principal',
        debugEnabled: false);
    assert(principalStories.length == 2);
    assert(principalStories.every((s) => s.contexto == 'principal'));

    // Testar filtro por contexto sinais_rebeca
    final rebecaStories = StoryContextFilter.filterByContext(
        stories, 'sinais_rebeca',
        debugEnabled: false);
    assert(rebecaStories.length == 2);
    assert(rebecaStories.every((s) => s.contexto == 'sinais_rebeca'));

    // Testar filtro por contexto sinais_isaque
    final isaqueStories = StoryContextFilter.filterByContext(
        stories, 'sinais_isaque',
        debugEnabled: false);
    assert(isaqueStories.length == 1);
    assert(isaqueStories.every((s) => s.contexto == 'sinais_isaque'));

    // Testar detecção de vazamentos
    final hasLeaks = StoryContextFilter.detectContextLeaks(stories, 'principal',
        debugEnabled: false);
    assert(hasLeaks ==
        true); // Deve detectar vazamentos pois há stories de outros contextos

    final noLeaks = StoryContextFilter.detectContextLeaks(
        principalStories, 'principal',
        debugEnabled: false);
    assert(noLeaks == false); // Não deve detectar vazamentos na lista filtrada

    print('✅ TESTE: Filtro de stories passou em todos os testes');
  }

  /// Testa a análise de distribuição de contextos
  static void testContextDistribution() {
    print('🧪 TESTE: Iniciando testes de distribuição de contextos');

    final stories = [
      _createTestStory('1', 'principal'),
      _createTestStory('2', 'principal'),
      _createTestStory('3', 'sinais_rebeca'),
      _createTestStory('4', 'sinais_isaque'),
    ];

    final distribution = StoryContextFilter.analyzeContextDistribution(stories,
        debugEnabled: false);

    assert(distribution['principal'] == 2);
    assert(distribution['sinais_rebeca'] == 1);
    assert(distribution['sinais_isaque'] == 1);

    print('✅ TESTE: Distribuição de contextos passou em todos os testes');
  }

  /// Testa a medição de performance
  static void testPerformanceMeasurement() {
    print('🧪 TESTE: Iniciando testes de medição de performance');

    final result =
        ContextDebug.measurePerformance('test_operation', 'principal', () {
      // Simular operação que demora um pouco
      final list = List.generate(100, (i) => i);
      return list.where((i) => i % 2 == 0).toList();
    });

    assert(result.length == 50);

    print('✅ TESTE: Medição de performance passou em todos os testes');
  }

  /// Executa todos os testes
  static void runAllTests() {
    print('🚀 INICIANDO TODOS OS TESTES DE CONTEXTO');
    print('=' * 50);

    try {
      testContextValidation();
      testStoryFiltering();
      testContextDistribution();
      testPerformanceMeasurement();

      print('=' * 50);
      print('🎉 TODOS OS TESTES PASSARAM COM SUCESSO!');
      print('✅ As utilidades de contexto estão funcionando corretamente');
    } catch (e, stackTrace) {
      print('=' * 50);
      print('❌ FALHA NOS TESTES: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Cria um story de teste
  static StorieFileModel _createTestStory(String id, String contexto) {
    return StorieFileModel(
      id: id,
      contexto: contexto,
      titulo: 'Test Story $id',
      fileUrl: 'https://example.com/story$id.jpg',
      fileType: StorieFileType.img,
      dataCadastro: Timestamp.now(),
    );
  }

  /// Simula um cenário de vazamento de contexto
  static void simulateContextLeak() {
    print('🧪 SIMULAÇÃO: Testando detecção de vazamento de contexto');

    // Simular stories que deveriam estar apenas no contexto sinais_rebeca
    // mas contêm stories de outros contextos (vazamento)
    final storiesWithLeak = [
      _createTestStory('1', 'sinais_rebeca'),
      _createTestStory('2', 'sinais_rebeca'),
      _createTestStory('3', 'principal'), // VAZAMENTO!
      _createTestStory('4', 'sinais_isaque'), // VAZAMENTO!
    ];

    print('📊 Stories antes da limpeza: ${storiesWithLeak.length}');
    StoryContextFilter.analyzeContextDistribution(storiesWithLeak);

    // Detectar vazamentos
    final hasLeaks =
        StoryContextFilter.detectContextLeaks(storiesWithLeak, 'sinais_rebeca');
    print('🚨 Vazamentos detectados: $hasLeaks');

    // Limpar vazamentos
    final cleanStories = StoryContextFilter.removeInvalidContextStories(
        storiesWithLeak, 'sinais_rebeca');
    print('🧹 Stories após limpeza: ${cleanStories.length}');

    // Verificar se limpeza foi efetiva
    final noMoreLeaks =
        StoryContextFilter.detectContextLeaks(cleanStories, 'sinais_rebeca');
    print('✅ Vazamentos após limpeza: $noMoreLeaks');

    assert(hasLeaks == true);
    assert(noMoreLeaks == false);
    assert(cleanStories.length == 2);

    print(
        '✅ SIMULAÇÃO: Detecção e limpeza de vazamentos funcionando corretamente');
  }
}
