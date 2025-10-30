# Design Document

## Overview

O problema identificado é que há vazamento de dados entre contextos diferentes no sistema de stories. Stories do contexto "principal" estão aparecendo em outros contextos como "sinais_rebeca", violando o isolamento que deveria existir entre eles. Este design propõe uma solução sistemática para garantir isolamento completo entre contextos.

## Architecture

### Problema Atual
- Stories do contexto "principal" aparecem na view "sinais_rebeca"
- Favoritos não respeitam completamente a separação por contexto
- Consultas ao banco não aplicam filtros de contexto consistentemente
- Círculos de notificação calculam incorretamente devido ao vazamento

### Solução Proposta
- Implementar filtros rigorosos por contexto em todas as consultas
- Corrigir métodos que misturam contextos
- Adicionar validação de contexto em operações críticas
- Implementar logs detalhados para debugging

## Components and Interfaces

### 1. StoriesRepository - Correções

**Problema Identificado:**
- Método `getAllSinaisRebeca()` pode estar retornando stories de outros contextos
- Consultas não aplicam filtro WHERE contexto = 'sinais_rebeca' consistentemente

**Correções Necessárias:**
```dart
// Adicionar filtro explícito por contexto
static Stream<List<StorieFileModel>> getAllSinaisRebeca() {
  return FirebaseFirestore.instance
    .collection('stories_sinais_rebeca')
    .where('contexto', isEqualTo: 'sinais_rebeca') // FILTRO EXPLÍCITO
    .snapshots()
    .map((event) => event.docs.map((e) {
      StorieFileModel story = StorieFileModel.fromJson(e.data());
      story.id = e.id;
      return story;
    }).toList());
}
```

### 2. StoryInteractionsRepository - Correções

**Problema Identificado:**
- Favoritos podem não estar sendo filtrados corretamente por contexto
- Método `getUserFavoritesStream` precisa garantir isolamento

**Correções Necessárias:**
```dart
// Garantir que apenas favoritos do contexto correto sejam retornados
static Stream<List<String>> getUserFavoritesStream({String contexto = 'principal'}) {
  return _firestore
    .collection('story_favorites')
    .where('userId', isEqualTo: userId)
    .where('contexto', isEqualTo: contexto) // FILTRO RIGOROSO
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => doc.data()['storyId'] as String)
        .toList());
}
```

### 3. Enhanced Stories Viewer - Validação

**Problema Identificado:**
- Viewer pode carregar stories de contextos misturados
- Necessário validar contexto antes de exibir

**Correções Necessárias:**
- Adicionar validação de contexto no carregamento
- Filtrar stories por contexto antes de exibir
- Logs detalhados para debugging

### 4. Story Favorites View - Isolamento

**Problema Identificado:**
- View de favoritos pode mostrar stories de contextos incorretos
- Título e comportamento devem ser específicos por contexto

**Correções Necessárias:**
- Validar contexto dos stories carregados
- Filtrar stories que não pertencem ao contexto
- Adicionar logs para rastreamento

## Data Models

### Context Validation Model
```dart
class ContextValidator {
  static bool isValidContext(String? contexto) {
    return ['principal', 'sinais_rebeca', 'sinais_isaque'].contains(contexto);
  }
  
  static String getDefaultContext() => 'principal';
  
  static String normalizeContext(String? contexto) {
    return isValidContext(contexto) ? contexto! : getDefaultContext();
  }
}
```

### Story Context Filter
```dart
class StoryContextFilter {
  static List<StorieFileModel> filterByContext(
    List<StorieFileModel> stories, 
    String expectedContext
  ) {
    return stories.where((story) => 
      story.contexto == expectedContext
    ).toList();
  }
  
  static bool validateStoryContext(StorieFileModel story, String expectedContext) {
    return story.contexto == expectedContext;
  }
}
```

## Error Handling

### Context Mismatch Detection
- Detectar quando stories de contextos incorretos são carregados
- Logs detalhados para identificar origem do problema
- Filtros de segurança para remover stories incorretos

### Validation Layers
1. **Database Level**: Filtros WHERE nas consultas
2. **Repository Level**: Validação após carregamento
3. **View Level**: Filtros finais antes da exibição
4. **Debug Level**: Logs detalhados em cada camada

## Testing Strategy

### Unit Tests
- Testar filtros de contexto em isolamento
- Validar que consultas retornam apenas o contexto correto
- Testar edge cases (contexto null, inválido, etc.)

### Integration Tests
- Testar fluxo completo de carregamento por contexto
- Validar que favoritos respeitam contexto
- Testar navegação entre contextos

### Debug Logging
- Logs detalhados em cada operação de contexto
- Rastreamento de origem dos stories
- Validação de contexto em tempo real

## Implementation Plan

### Phase 1: Repository Fixes
- Corrigir métodos getAllSinaisRebeca() e getAllSinaisIsaque()
- Adicionar filtros explícitos por contexto
- Implementar validação de contexto

### Phase 2: Interactions Fixes  
- Corrigir sistema de favoritos
- Garantir isolamento por contexto
- Adicionar logs detalhados

### Phase 3: View Validation
- Adicionar validação nas views
- Implementar filtros de segurança
- Melhorar debugging

### Phase 4: Testing & Monitoring
- Implementar logs de monitoramento
- Adicionar métricas de contexto
- Validação contínua

## Debug Strategy

### Logging Points
1. **Repository Load**: Log de stories carregados com contexto
2. **Context Validation**: Log de validações de contexto
3. **Filter Application**: Log de filtros aplicados
4. **View Rendering**: Log de stories exibidos

### Debug Flags
```dart
class ContextDebug {
  static const bool ENABLE_CONTEXT_LOGS = true;
  static const bool VALIDATE_CONTEXT_STRICT = true;
  static const bool FILTER_INVALID_CONTEXTS = true;
}
```

### Monitoring Metrics
- Contagem de stories por contexto
- Detecção de vazamentos entre contextos
- Performance de consultas filtradas
- Taxa de sucesso de isolamento