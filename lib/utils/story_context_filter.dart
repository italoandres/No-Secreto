import '../models/storie_file_model.dart';
import 'context_validator.dart';

/// Utilitário para filtrar stories por contexto
/// 
/// Esta classe fornece métodos para filtrar listas de stories,
/// garantindo que apenas stories do contexto correto sejam processados.
class StoryContextFilter {
  /// Filtra uma lista de stories por contexto específico
  /// 
  /// [stories] - Lista de stories a serem filtrados
  /// [expectedContext] - O contexto esperado
  /// [debugEnabled] - Se deve fazer log de debug
  /// Retorna lista filtrada contendo apenas stories do contexto esperado
  static List<StorieFileModel> filterByContext(
    List<StorieFileModel> stories, 
    String expectedContext,
    {bool debugEnabled = true}
  ) {
    final normalizedContext = ContextValidator.normalizeContext(expectedContext);
    
    if (debugEnabled) {
      print('🔍 STORY_FILTER: Iniciando filtro por contexto "$normalizedContext"');
      print('🔍 STORY_FILTER: Stories recebidos: ${stories.length}');
    }
    
    final filteredStories = stories.where((story) {
      final storyContext = ContextValidator.normalizeContext(story.contexto);
      final matches = storyContext == normalizedContext;
      
      if (debugEnabled && !matches) {
        print('⚠️ STORY_FILTER: Story ${story.id} removido - contexto "${story.contexto}" não corresponde ao esperado "$normalizedContext"');
      }
      
      return matches;
    }).toList();
    
    if (debugEnabled) {
      print('✅ STORY_FILTER: Stories após filtro: ${filteredStories.length}');
      if (filteredStories.length != stories.length) {
        print('🚨 STORY_FILTER: VAZAMENTO DETECTADO! ${stories.length - filteredStories.length} stories de contextos incorretos foram removidos');
      }
    }
    
    return filteredStories;
  }
  
  /// Valida se um story pertence ao contexto esperado
  /// 
  /// [story] - O story a ser validado
  /// [expectedContext] - O contexto esperado
  /// [debugEnabled] - Se deve fazer log de debug
  /// Retorna true se o story pertence ao contexto esperado
  static bool validateStoryContext(
    StorieFileModel story, 
    String expectedContext,
    {bool debugEnabled = true}
  ) {
    final normalizedExpected = ContextValidator.normalizeContext(expectedContext);
    final normalizedStory = ContextValidator.normalizeContext(story.contexto);
    final isValid = normalizedStory == normalizedExpected;
    
    if (debugEnabled) {
      if (isValid) {
        print('✅ STORY_VALIDATOR: Story ${story.id} válido para contexto "$normalizedExpected"');
      } else {
        print('❌ STORY_VALIDATOR: Story ${story.id} inválido - contexto "${story.contexto}" não corresponde ao esperado "$normalizedExpected"');
      }
    }
    
    return isValid;
  }
  
  /// Remove stories que não pertencem ao contexto esperado
  /// 
  /// [stories] - Lista de stories a serem limpos
  /// [expectedContext] - O contexto esperado
  /// [debugEnabled] - Se deve fazer log de debug
  /// Retorna lista limpa e logs detalhados sobre remoções
  static List<StorieFileModel> removeInvalidContextStories(
    List<StorieFileModel> stories,
    String expectedContext,
    {bool debugEnabled = true}
  ) {
    final normalizedContext = ContextValidator.normalizeContext(expectedContext);
    
    if (debugEnabled) {
      print('🧹 STORY_CLEANER: Limpando stories para contexto "$normalizedContext"');
    }
    
    final validStories = <StorieFileModel>[];
    final invalidStories = <StorieFileModel>[];
    
    for (final story in stories) {
      if (validateStoryContext(story, normalizedContext, debugEnabled: false)) {
        validStories.add(story);
      } else {
        invalidStories.add(story);
        if (debugEnabled) {
          print('🗑️ STORY_CLEANER: Removendo story ${story.id} (contexto: "${story.contexto}", título: "${story.titulo ?? 'Sem título'}")');
        }
      }
    }
    
    if (debugEnabled && invalidStories.isNotEmpty) {
      print('🚨 STORY_CLEANER: VAZAMENTO CRÍTICO! ${invalidStories.length} stories de contextos incorretos foram encontrados:');
      for (final story in invalidStories) {
        print('   - Story ${story.id}: contexto "${story.contexto}" (esperado: "$normalizedContext")');
      }
    }
    
    return validStories;
  }
  
  /// Analisa uma lista de stories e retorna estatísticas por contexto
  /// 
  /// [stories] - Lista de stories a serem analisados
  /// [debugEnabled] - Se deve fazer log de debug
  /// Retorna mapa com contagem de stories por contexto
  static Map<String, int> analyzeContextDistribution(
    List<StorieFileModel> stories,
    {bool debugEnabled = true}
  ) {
    final distribution = <String, int>{};
    
    for (final story in stories) {
      final context = ContextValidator.normalizeContext(story.contexto);
      distribution[context] = (distribution[context] ?? 0) + 1;
    }
    
    if (debugEnabled) {
      print('📊 STORY_ANALYZER: Distribuição de stories por contexto:');
      distribution.forEach((context, count) {
        print('   - $context: $count stories');
      });
    }
    
    return distribution;
  }
  
  /// Detecta vazamentos de contexto em uma lista de stories
  /// 
  /// [stories] - Lista de stories a serem analisados
  /// [expectedContext] - O contexto que deveria estar presente
  /// [debugEnabled] - Se deve fazer log de debug
  /// Retorna true se vazamentos foram detectados
  static bool detectContextLeaks(
    List<StorieFileModel> stories,
    String expectedContext,
    {bool debugEnabled = true}
  ) {
    final distribution = analyzeContextDistribution(stories, debugEnabled: false);
    final normalizedExpected = ContextValidator.normalizeContext(expectedContext);
    
    // Remove o contexto esperado da distribuição
    final leaks = Map<String, int>.from(distribution);
    leaks.remove(normalizedExpected);
    
    final hasLeaks = leaks.isNotEmpty;
    
    if (debugEnabled) {
      if (hasLeaks) {
        print('🚨 LEAK_DETECTOR: VAZAMENTOS DETECTADOS para contexto "$normalizedExpected":');
        leaks.forEach((context, count) {
          print('   - $count stories do contexto "$context" encontrados incorretamente');
        });
      } else {
        print('✅ LEAK_DETECTOR: Nenhum vazamento detectado para contexto "$normalizedExpected"');
      }
    }
    
    return hasLeaks;
  }
}