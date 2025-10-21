import '../models/storie_file_model.dart';
import 'context_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Exemplos de como usar o sistema de debug de contexto
/// 
/// Este arquivo contém exemplos práticos de como usar as utilidades
/// de debug e análise de contexto no seu código.
class ContextDebugExample {
  
  /// Exemplo 1: Analisar stories carregados de um repositório
  static Future<void> exampleAnalyzeRepositoryStories() async {
    print('🔍 EXEMPLO 1: Analisando stories do repositório');
    
    // Simular stories carregados (normalmente viriam do repositório)
    final stories = [
      _createExampleStory('1', 'sinais_rebeca', 'Story Correto 1'),
      _createExampleStory('2', 'sinais_rebeca', 'Story Correto 2'),
      _createExampleStory('3', 'principal', 'Story Vazado!'), // VAZAMENTO!
      _createExampleStory('4', 'sinais_rebeca', 'Story Correto 3'),
    ];
    
    // Analisar stories
    final report = ContextUtils.analyzeStories(stories, 'sinais_rebeca');
    
    // Imprimir relatório
    ContextUtils.printReport(report);
    
    // Verificar se há problemas
    if (report['hasLeaks'] == true) {
      print('🚨 AÇÃO NECESSÁRIA: Vazamentos detectados!');
      print('📋 Detalhes dos vazamentos:');
      final invalidStories = report['invalidStoriesDetails'] as List<dynamic>;
      for (final story in invalidStories) {
        print('   - Story ${story['storyId']}: contexto "${story['actualContext']}" deveria ser "${story['expectedContext']}"');
      }
    } else {
      print('✅ TUDO OK: Nenhum vazamento detectado');
    }
  }
  
  /// Exemplo 2: Verificar saúde do sistema
  static void exampleSystemHealthCheck() {
    print('\n🔍 EXEMPLO 2: Verificando saúde do sistema');
    
    // Gerar relatório de saúde
    final healthReport = ContextUtils.generateHealthReport();
    
    // Imprimir relatório
    ContextUtils.printReport(healthReport);
    
    // Verificar configurações
    final debugConfig = healthReport['debugConfiguration'] as Map<String, dynamic>;
    
    if (debugConfig['ENABLE_CONTEXT_LOGS'] != true) {
      print('⚠️ AVISO: Logs de contexto estão desabilitados');
    }
    
    if (debugConfig['DETECT_CONTEXT_LEAKS'] != true) {
      print('🚨 CRÍTICO: Detecção de vazamentos está desabilitada');
    }
    
    print('✅ Verificação de saúde concluída');
  }
  
  /// Exemplo 3: Executar testes do sistema
  static void exampleSystemTests() {
    print('\n🔍 EXEMPLO 3: Executando testes do sistema');
    
    // Executar testes
    final testReport = ContextUtils.runSystemTests();
    
    // Imprimir relatório
    ContextUtils.printReport(testReport);
    
    // Verificar resultados
    if (testReport['allTestsPassed'] == true) {
      print('🎉 SUCESSO: Todos os testes passaram!');
    } else {
      print('❌ FALHA: Alguns testes falharam');
      
      final testResults = testReport['testResults'] as Map<String, dynamic>;
      testResults.forEach((testName, result) {
        if (result['passed'] != true) {
          print('   ❌ $testName: ${result['error'] ?? 'Falhou'}');
        }
      });
    }
  }
  
  /// Exemplo 4: Debug de favoritos por contexto
  static Future<void> exampleDebugFavorites() async {
    print('\n🔍 EXEMPLO 4: Debug de favoritos por contexto');
    
    // Simular cenário onde favoritos têm contextos misturados
    final favoriteStories = [
      _createExampleStory('fav1', 'sinais_rebeca', 'Favorito Correto 1'),
      _createExampleStory('fav2', 'principal', 'Favorito Vazado!'), // VAZAMENTO!
      _createExampleStory('fav3', 'sinais_rebeca', 'Favorito Correto 2'),
    ];
    
    print('📚 Analisando favoritos para contexto "sinais_rebeca"...');
    
    // Analisar favoritos
    final report = ContextUtils.analyzeStories(favoriteStories, 'sinais_rebeca');
    
    // Imprimir relatório resumido
    print('📊 Resultado da análise:');
    print('   - Total de favoritos: ${report['totalStories']}');
    print('   - Favoritos válidos: ${report['validStories']}');
    print('   - Favoritos inválidos: ${report['invalidStories']}');
    print('   - Taxa de vazamento: ${report['leakPercentage']}%');
    
    if (report['hasLeaks'] == true) {
      print('\n🚨 PROBLEMA DETECTADO:');
      print('   Há favoritos salvos com contexto incorreto!');
      print('   Isso pode causar stories aparecendo em contextos errados.');
      print('\n🔧 SOLUÇÕES SUGERIDAS:');
      print('   1. Verificar método toggleFavorite no StoryInteractionsRepository');
      print('   2. Executar migração de favoritos legacy');
      print('   3. Adicionar validação de contexto ao salvar favoritos');
    }
  }
  
  /// Exemplo 5: Monitoramento de performance
  static Future<void> examplePerformanceMonitoring() async {
    print('\n🔍 EXEMPLO 5: Monitoramento de performance');
    
    // Simular operação com medição de performance
    final result = ContextDebug.measurePerformance('example_operation', 'sinais_rebeca', () {
      // Simular operação que demora um tempo
      final list = List.generate(1000, (i) => i);
      return list.where((i) => i % 2 == 0).toList();
    });
    
    print('⚡ Operação concluída');
    print('📊 Resultado: ${result.length} itens processados');
    print('ℹ️ Verifique os logs para ver o tempo de execução');
  }
  
  /// Exemplo 6: Simular e detectar vazamentos
  static void exampleLeakDetection() {
    print('\n🔍 EXEMPLO 6: Simulação e detecção de vazamentos');
    
    // Executar simulação de vazamento
    print('🧪 Executando simulação de vazamento...');
    ContextUtils.simulateLeak();
    
    print('✅ Simulação concluída');
    print('ℹ️ Verifique os logs acima para ver como vazamentos são detectados');
  }
  
  /// Exemplo 7: Uso em produção - Monitoramento contínuo
  static Future<void> exampleProductionMonitoring(List<StorieFileModel> stories, String context) async {
    print('\n🔍 EXEMPLO 7: Monitoramento em produção');
    
    // Em produção, você faria isso periodicamente ou em pontos críticos
    try {
      // Analisar stories carregados
      final report = ContextUtils.analyzeStories(stories, context);
      
      // Verificar se há problemas críticos
      final leakPercentage = double.parse(report['leakPercentage'] as String);
      
      if (leakPercentage > 5.0) {
        // Log crítico para sistema de monitoramento
        print('🚨 ALERTA CRÍTICO: Taxa de vazamento alta (${leakPercentage}%)');
        print('📧 Enviando alerta para equipe de desenvolvimento...');
        
        // Aqui você enviaria um alerta real (email, Slack, etc.)
        // await sendCriticalAlert(report);
      } else if (leakPercentage > 0) {
        // Log de aviso
        print('⚠️ AVISO: Vazamentos detectados (${leakPercentage}%)');
        print('📝 Registrando para investigação...');
        
        // Aqui você registraria para investigação posterior
        // await logForInvestigation(report);
      } else {
        // Tudo OK
        print('✅ Sistema funcionando corretamente - Nenhum vazamento detectado');
      }
      
    } catch (e) {
      print('❌ ERRO no monitoramento: $e');
      // Em produção, você logaria este erro em um sistema de monitoramento
    }
  }
  
  /// Executar todos os exemplos
  static Future<void> runAllExamples() async {
    print('🚀 EXECUTANDO TODOS OS EXEMPLOS DE DEBUG DE CONTEXTO');
    print('=' * 60);
    
    await exampleAnalyzeRepositoryStories();
    exampleSystemHealthCheck();
    exampleSystemTests();
    await exampleDebugFavorites();
    await examplePerformanceMonitoring();
    exampleLeakDetection();
    
    // Exemplo de produção com dados simulados
    final productionStories = [
      _createExampleStory('prod1', 'principal', 'Story Produção 1'),
      _createExampleStory('prod2', 'principal', 'Story Produção 2'),
    ];
    await exampleProductionMonitoring(productionStories, 'principal');
    
    print('=' * 60);
    print('🎉 TODOS OS EXEMPLOS EXECUTADOS COM SUCESSO!');
    print('📚 Consulte CONTEXT_LOGGING_GUIDE.md para mais informações');
  }
  
  /// Helper para criar stories de exemplo
  static StorieFileModel _createExampleStory(String id, String contexto, String titulo) {
    return StorieFileModel(
      id: id,
      contexto: contexto,
      titulo: titulo,
      fileUrl: 'https://example.com/$id.jpg',
      fileType: StorieFileType.img,
      dataCadastro: Timestamp.now(),
    );
  }
}