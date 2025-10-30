# Design Document - Correção Sistema de Busca de Perfis

## Overview

O sistema atual de busca de perfis falha devido a dependência de índices compostos complexos do Firebase. A solução proposta implementa uma estratégia de busca em camadas que funciona sem índices específicos, usando queries simples do Firebase combinadas com filtros no código Dart.

## Architecture

### Estratégia de Busca em Camadas

1. **Camada 1: Query Firebase Simples**
   - Usar apenas filtros básicos que não requerem índices compostos
   - Buscar mais resultados do que necessário para filtrar depois

2. **Camada 2: Filtros no Código Dart**
   - Aplicar filtros complexos no código após receber dados do Firebase
   - Implementar busca por texto usando algoritmos de matching

3. **Camada 3: Fallback e Cache**
   - Sistema de fallback para quando queries falham
   - Cache de resultados para melhorar performance

## Components and Interfaces

### SearchProfilesService
```dart
class SearchProfilesService {
  // Busca principal com estratégia em camadas
  Future<List<SpiritualProfileModel>> searchProfiles({
    String? query,
    SearchFilters? filters,
    int limit = 30,
  });
  
  // Busca simples sem filtros complexos
  Future<List<SpiritualProfileModel>> simpleSearch(String query);
  
  // Aplicar filtros no código Dart
  List<SpiritualProfileModel> applyFilters(
    List<SpiritualProfileModel> profiles,
    SearchFilters filters
  );
}
```

### SearchStrategy (Strategy Pattern)
```dart
abstract class SearchStrategy {
  Future<List<SpiritualProfileModel>> search(SearchParams params);
}

class FirebaseSimpleSearchStrategy implements SearchStrategy {
  // Busca usando apenas campos indexados simples
}

class DisplayNameSearchStrategy implements SearchStrategy {
  // Busca por displayName usando range queries
}

class FallbackSearchStrategy implements SearchStrategy {
  // Busca básica quando outras falham
}
```

### TextMatcher
```dart
class TextMatcher {
  // Algoritmos de matching de texto
  bool matches(String text, String query);
  double similarity(String text, String query);
  List<String> extractKeywords(String text);
}
```

## Data Models

### SearchFilters
```dart
class SearchFilters {
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? state;
  final List<String>? interests;
  final bool? isVerified;
  final bool? hasCompletedCourse;
}
```

### SearchParams
```dart
class SearchParams {
  final String? query;
  final SearchFilters? filters;
  final int limit;
  final SearchStrategy? preferredStrategy;
}
```

### SearchResult
```dart
class SearchResult {
  final List<SpiritualProfileModel> profiles;
  final int totalFound;
  final String strategyUsed;
  final Duration searchTime;
  final bool fromCache;
}
```

## Error Handling

### Estratégia de Fallback
1. **Tentativa 1**: Query com displayName + filtros básicos
2. **Tentativa 2**: Query apenas com filtros básicos + busca por texto no código
3. **Tentativa 3**: Query simples sem filtros + todos os filtros no código
4. **Fallback Final**: Retornar perfis populares com aviso

### Tratamento de Erros Específicos
- **failed-precondition**: Automaticamente usar estratégia alternativa
- **permission-denied**: Log e retornar lista vazia
- **unavailable**: Usar cache se disponível
- **timeout**: Reduzir limite e tentar novamente

## Testing Strategy

### Unit Tests
- Testar cada SearchStrategy individualmente
- Testar TextMatcher com diferentes tipos de texto
- Testar aplicação de filtros no código Dart

### Integration Tests
- Testar fluxo completo de busca com dados reais
- Testar fallback quando Firebase retorna erro
- Testar performance com grandes volumes de dados

### Performance Tests
- Medir tempo de resposta para diferentes tipos de busca
- Testar com diferentes tamanhos de resultado
- Validar uso de memória com filtros no código

## Implementation Details

### Query Firebase Otimizada
```dart
// Em vez de query complexa que requer índice:
query.where('displayName', isGreaterThanOrEqualTo: searchTerm)
     .where('displayName', isLessThan: searchTerm + 'z')
     .where('isActive', isEqualTo: true)
     .where('isVerified', isEqualTo: true)
     .where('hasCompletedSinaisCourse', isEqualTo: true);

// Usar query simples:
query.where('isActive', isEqualTo: true)
     .where('isVerified', isEqualTo: true)
     .where('hasCompletedSinaisCourse', isEqualTo: true)
     .limit(100); // Buscar mais para filtrar depois
```

### Filtro de Texto no Código
```dart
bool matchesSearchQuery(SpiritualProfileModel profile, String query) {
  final searchableText = [
    profile.displayName,
    profile.username,
    profile.bio,
  ].where((text) => text != null).join(' ').toLowerCase();
  
  return searchableText.contains(query.toLowerCase()) ||
         calculateSimilarity(searchableText, query) > 0.7;
}
```

### Cache Strategy
- Cache de resultados por 5 minutos
- Cache separado para diferentes tipos de filtro
- Invalidar cache quando perfil é atualizado

### Monitoring e Logs
- Log de qual estratégia foi usada
- Métricas de performance por estratégia
- Alertas quando fallback é usado frequentemente