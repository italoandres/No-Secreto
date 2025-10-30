# Design Document

## Overview

O algoritmo de matching inteligente é um sistema de pontuação multi-critério que avalia perfis de usuários baseado em 8 filtros configuráveis. O sistema utiliza uma abordagem híbrida: filtragem inicial no Firestore para critérios obrigatórios (distância, idade, altura) e pontuação em memória para critérios opcionais (idiomas, educação, estilo de vida). A pontuação final é normalizada para 0-100 e os perfis são ordenados por relevância.

## Architecture

### Componentes Principais

```
┌─────────────────────────────────────────────────────────────┐
│                    ExploreProfilesController                 │
│  - Gerencia estado dos filtros                              │
│  - Coordena busca e exibição                                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    ProfileMatchingService                    │
│  - Executa queries no Firestore                             │
│  - Calcula pontuações de compatibilidade                    │
│  - Ordena e pagina resultados                               │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├──────────────┬──────────────┬──────────────┐
                 ▼              ▼              ▼              ▼
┌──────────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ DistanceCalculator│  │ScoreCalculator│  │ CacheManager │  │QueryBuilder  │
│ - Haversine       │  │ - Pontuação   │  │ - Cache 5min │  │ - Queries    │
│ - Geo filtering   │  │ - Normalização│  │ - Invalidação│  │ - Composição │
└──────────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

### Fluxo de Dados

```
1. Usuário configura filtros
   ↓
2. Controller chama ProfileMatchingService.searchProfiles()
   ↓
3. QueryBuilder constrói query Firestore com filtros obrigatórios
   ↓
4. Firestore retorna perfis candidatos (max 50)
   ↓
5. Para cada perfil:
   - DistanceCalculator calcula distância real
   - ScoreCalculator avalia cada filtro ativo
   - Aplica pesos para filtros priorizados
   ↓
6. Perfis são ordenados por pontuação
   ↓
7. CacheManager armazena resultados
   ↓
8. Controller exibe perfis paginados (20 por vez)
```

## Components and Interfaces

### 1. ProfileMatchingService

```dart
class ProfileMatchingService {
  final FirebaseFirestore _firestore;
  final DistanceCalculator _distanceCalculator;
  final ScoreCalculator _scoreCalculator;
  final CacheManager _cacheManager;
  
  /// Busca perfis baseado nos filtros
  Future<MatchingResult> searchProfiles({
    required SearchFilters filters,
    required UserLocation userLocation,
    required String currentUserId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  });
  
  /// Calcula pontuação para um perfil específico
  MatchScore calculateMatchScore({
    required UserProfile profile,
    required SearchFilters filters,
    required UserLocation userLocation,
  });
  
  /// Invalida cache quando filtros mudam
  void invalidateCache();
}
```

### 2. DistanceCalculator

```dart
class DistanceCalculator {
  /// Calcula distância usando fórmula de Haversine
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  });
  
  /// Verifica se perfil está dentro do raio
  bool isWithinRadius({
    required UserLocation userLocation,
    required UserLocation profileLocation,
    required double maxDistanceKm,
  });
}
```

### 3. ScoreCalculator

```dart
class ScoreCalculator {
  /// Calcula pontuação total do perfil
  MatchScore calculateScore({
    required UserProfile profile,
    required SearchFilters filters,
    required double distance,
  });
  
  /// Calcula pontos para idiomas
  double _calculateLanguageScore(List<String> userLangs, List<String> profileLangs);
  
  /// Calcula pontos para educação
  double _calculateEducationScore(String? userEdu, String? profileEdu);
  
  /// Calcula pontos para filhos
  double _calculateChildrenScore(String? userChildren, String? profileChildren);
  
  /// Calcula pontos para beber
  double _calculateDrinkingScore(String? userDrinking, String? profileDrinking);
  
  /// Calcula pontos para fumar
  double _calculateSmokingScore(String? userSmoking, String? profileSmoking);
  
  /// Normaliza pontuação para 0-100
  double _normalizeScore(double rawScore, double maxPossibleScore);
}
```

### 4. QueryBuilder

```dart
class QueryBuilder {
  /// Constrói query Firestore com filtros obrigatórios
  Query<Map<String, dynamic>> buildQuery({
    required SearchFilters filters,
    required String currentUserId,
    int limit = 50,
  });
  
  /// Adiciona filtro de idade
  Query<Map<String, dynamic>> _addAgeFilter(Query query, int minAge, int maxAge);
  
  /// Adiciona filtro de altura
  Query<Map<String, dynamic>> _addHeightFilter(Query query, int minHeight, int maxHeight);
}
```

### 5. CacheManager

```dart
class CacheManager {
  final Map<String, CachedResult> _cache = {};
  final Duration _cacheDuration = Duration(minutes: 5);
  
  /// Armazena resultado no cache
  void cacheResult(String key, MatchingResult result);
  
  /// Recupera resultado do cache
  MatchingResult? getCachedResult(String key);
  
  /// Invalida cache
  void invalidate();
  
  /// Gera chave de cache baseada nos filtros
  String _generateCacheKey(SearchFilters filters);
}
```

## Data Models

### MatchingResult

```dart
class MatchingResult {
  final List<ScoredProfile> profiles;
  final int totalCount;
  final int excellentMatchCount;
  final DocumentSnapshot? lastDocument;
  final DateTime timestamp;
  
  MatchingResult({
    required this.profiles,
    required this.totalCount,
    required this.excellentMatchCount,
    this.lastDocument,
    required this.timestamp,
  });
}
```

### ScoredProfile

```dart
class ScoredProfile {
  final UserProfile profile;
  final MatchScore score;
  final double distance;
  
  ScoredProfile({
    required this.profile,
    required this.score,
    required this.distance,
  });
}
```

### MatchScore

```dart
class MatchScore {
  final double totalScore; // 0-100
  final MatchLevel level; // Excelente, Bom, Moderado, Baixo
  final Map<String, double> breakdown; // Pontuação por filtro
  
  MatchScore({
    required this.totalScore,
    required this.level,
    required this.breakdown,
  });
  
  Color get badgeColor {
    switch (level) {
      case MatchLevel.excellent: return Colors.green;
      case MatchLevel.good: return Colors.blue;
      case MatchLevel.moderate: return Colors.orange;
      case MatchLevel.low: return Colors.grey;
    }
  }
  
  String get label {
    switch (level) {
      case MatchLevel.excellent: return 'Excelente Match';
      case MatchLevel.good: return 'Bom Match';
      case MatchLevel.moderate: return 'Match Moderado';
      case MatchLevel.low: return 'Match Baixo';
    }
  }
}

enum MatchLevel { excellent, good, moderate, low }
```

## Algoritmo de Pontuação

### Sistema de Pontos Base

```dart
// Pontos base por critério (quando não priorizado)
const Map<String, double> BASE_POINTS = {
  'distance': 10.0,      // Dentro do raio
  'age': 10.0,           // Dentro da faixa
  'height': 10.0,        // Dentro da faixa
  'language': 15.0,      // Por idioma em comum
  'education': 20.0,     // Correspondência exata
  'children': 15.0,      // Correspondência
  'drinking': 10.0,      // Correspondência
  'smoking': 10.0,       // Correspondência
};

// Multiplicador quando filtro é priorizado
const double PRIORITY_MULTIPLIER = 2.0;
```

### Cálculo de Pontuação

```dart
double calculateTotalScore(UserProfile profile, SearchFilters filters) {
  double totalScore = 0.0;
  double maxPossibleScore = 0.0;
  
  // 1. Distância (se dentro do raio)
  if (distance <= filters.maxDistance) {
    double points = BASE_POINTS['distance']!;
    if (filters.prioritizeDistance) points *= PRIORITY_MULTIPLIER;
    totalScore += points;
  }
  maxPossibleScore += BASE_POINTS['distance']! * 
    (filters.prioritizeDistance ? PRIORITY_MULTIPLIER : 1.0);
  
  // 2. Idade (se dentro da faixa)
  if (profile.age >= filters.minAge && profile.age <= filters.maxAge) {
    double points = BASE_POINTS['age']!;
    if (filters.prioritizeAge) points *= PRIORITY_MULTIPLIER;
    totalScore += points;
  }
  maxPossibleScore += BASE_POINTS['age']! * 
    (filters.prioritizeAge ? PRIORITY_MULTIPLIER : 1.0);
  
  // 3. Altura (se dentro da faixa)
  if (profile.height >= filters.minHeight && profile.height <= filters.maxHeight) {
    double points = BASE_POINTS['height']!;
    if (filters.prioritizeHeight) points *= PRIORITY_MULTIPLIER;
    totalScore += points;
  }
  maxPossibleScore += BASE_POINTS['height']! * 
    (filters.prioritizeHeight ? PRIORITY_MULTIPLIER : 1.0);
  
  // 4. Idiomas (por idioma em comum)
  if (filters.selectedLanguages.isNotEmpty) {
    int commonLanguages = filters.selectedLanguages
      .where((lang) => profile.languages.contains(lang))
      .length;
    double points = BASE_POINTS['language']! * commonLanguages;
    if (filters.prioritizeLanguages) points *= PRIORITY_MULTIPLIER;
    totalScore += points;
    maxPossibleScore += BASE_POINTS['language']! * 
      filters.selectedLanguages.length * 
      (filters.prioritizeLanguages ? PRIORITY_MULTIPLIER : 1.0);
  }
  
  // 5. Educação
  if (filters.selectedEducation != null) {
    if (profile.education == filters.selectedEducation) {
      double points = BASE_POINTS['education']!;
      if (filters.prioritizeEducation) points *= PRIORITY_MULTIPLIER;
      totalScore += points;
    }
    maxPossibleScore += BASE_POINTS['education']! * 
      (filters.prioritizeEducation ? PRIORITY_MULTIPLIER : 1.0);
  }
  
  // 6. Filhos
  if (filters.selectedChildren != null && filters.selectedChildren != 'Não tenho preferência') {
    if (profile.children == filters.selectedChildren) {
      double points = BASE_POINTS['children']!;
      if (filters.prioritizeChildren) points *= PRIORITY_MULTIPLIER;
      totalScore += points;
    }
    maxPossibleScore += BASE_POINTS['children']! * 
      (filters.prioritizeChildren ? PRIORITY_MULTIPLIER : 1.0);
  }
  
  // 7. Beber
  if (filters.selectedDrinking != null && filters.selectedDrinking != 'Não tenho preferência') {
    if (profile.drinking == filters.selectedDrinking) {
      double points = BASE_POINTS['drinking']!;
      if (filters.prioritizeDrinking) points *= PRIORITY_MULTIPLIER;
      totalScore += points;
    }
    maxPossibleScore += BASE_POINTS['drinking']! * 
      (filters.prioritizeDrinking ? PRIORITY_MULTIPLIER : 1.0);
  }
  
  // 8. Fumar
  if (filters.selectedSmoking != null && filters.selectedSmoking != 'Não tenho preferência') {
    if (profile.smoking == filters.selectedSmoking) {
      double points = BASE_POINTS['smoking']!;
      if (filters.prioritizeSmoking) points *= PRIORITY_MULTIPLIER;
      totalScore += points;
    }
    maxPossibleScore += BASE_POINTS['smoking']! * 
      (filters.prioritizeSmoking ? PRIORITY_MULTIPLIER : 1.0);
  }
  
  // Normalizar para 0-100
  return maxPossibleScore > 0 ? (totalScore / maxPossibleScore) * 100 : 0;
}
```

### Classificação de Match

```dart
MatchLevel getMatchLevel(double score) {
  if (score >= 80) return MatchLevel.excellent;
  if (score >= 60) return MatchLevel.good;
  if (score >= 40) return MatchLevel.moderate;
  return MatchLevel.low;
}
```

## Firestore Query Strategy

### Query Otimizada

```dart
Query buildOptimizedQuery(SearchFilters filters, String userId) {
  Query query = _firestore.collection('users')
    .where('userId', isNotEqualTo: userId) // Excluir próprio perfil
    .where('profileComplete', isEqualTo: true); // Apenas perfis completos
  
  // Filtros obrigatórios (aplicados no Firestore)
  if (filters.minAge > 18 || filters.maxAge < 100) {
    query = query
      .where('age', isGreaterThanOrEqualTo: filters.minAge)
      .where('age', isLessThanOrEqualTo: filters.maxAge);
  }
  
  // Nota: Distância e altura serão filtrados em memória
  // devido a limitações do Firestore (máximo 1 range query)
  
  return query.limit(50);
}
```

### Filtragem em Memória

```dart
List<UserProfile> filterInMemory(
  List<UserProfile> profiles,
  SearchFilters filters,
  UserLocation userLocation,
) {
  return profiles.where((profile) {
    // Filtro de altura
    if (profile.height < filters.minHeight || 
        profile.height > filters.maxHeight) {
      return false;
    }
    
    // Filtro de distância
    double distance = _distanceCalculator.calculateDistance(
      lat1: userLocation.latitude,
      lon1: userLocation.longitude,
      lat2: profile.location.latitude,
      lon2: profile.location.longitude,
    );
    if (distance > filters.maxDistance) {
      return false;
    }
    
    return true;
  }).toList();
}
```

## UI Components

### ProfileMatchCard

```dart
class ProfileMatchCard extends StatelessWidget {
  final ScoredProfile scoredProfile;
  
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Foto do perfil
          ProfileImage(url: scoredProfile.profile.photoUrl),
          
          // Badge de compatibilidade
          MatchBadge(
            score: scoredProfile.score.totalScore,
            level: scoredProfile.score.level,
          ),
          
          // Informações básicas
          ProfileInfo(profile: scoredProfile.profile),
          
          // Distância
          DistanceIndicator(distance: scoredProfile.distance),
          
          // Breakdown de pontuação (expandível)
          ScoreBreakdown(breakdown: scoredProfile.score.breakdown),
        ],
      ),
    );
  }
}
```

### MatchBadge

```dart
class MatchBadge extends StatelessWidget {
  final double score;
  final MatchLevel level;
  
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor(level),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            '${score.toStringAsFixed(0)}% ${_getLabel(level)}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

### MatchCountHeader

```dart
class MatchCountHeader extends StatelessWidget {
  final int totalCount;
  final int excellentCount;
  
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$totalCount perfis encontrados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (excellentCount > 0)
            Chip(
              avatar: Icon(Icons.star, color: Colors.white, size: 16),
              label: Text('$excellentCount excelentes'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
```

## Error Handling

### Cenários de Erro

1. **Sem localização do usuário**
   - Exibir mensagem pedindo para configurar localização
   - Desabilitar busca até localização ser configurada

2. **Erro no Firestore**
   - Tentar novamente automaticamente (max 3 tentativas)
   - Exibir mensagem de erro amigável
   - Registrar erro no log

3. **Nenhum perfil encontrado**
   - Exibir mensagem sugerindo ajustar filtros
   - Mostrar quais filtros estão muito restritivos
   - Oferecer botão "Resetar Filtros"

4. **Timeout na busca**
   - Cancelar busca após 30 segundos
   - Exibir mensagem de timeout
   - Permitir tentar novamente

## Testing Strategy

### Unit Tests

1. **DistanceCalculator**
   - Testar cálculo de Haversine com coordenadas conhecidas
   - Testar casos extremos (polos, linha do equador)

2. **ScoreCalculator**
   - Testar pontuação com todos filtros ativos
   - Testar pontuação com filtros priorizados
   - Testar normalização para 0-100

3. **QueryBuilder**
   - Testar construção de query com diferentes combinações de filtros
   - Verificar exclusão do próprio perfil

4. **CacheManager**
   - Testar armazenamento e recuperação
   - Testar expiração de cache
   - Testar invalidação

### Integration Tests

1. Testar fluxo completo de busca
2. Testar paginação
3. Testar atualização quando filtros mudam
4. Testar performance com 50 perfis

## Performance Considerations

### Otimizações

1. **Índices Firestore**
   ```
   - Criar índice composto: (age ASC, profileComplete ASC)
   - Criar índice: (userId ASC)
   ```

2. **Cálculos em Paralelo**
   - Calcular distância e pontuação em paralelo usando `Future.wait()`

3. **Lazy Loading**
   - Carregar fotos apenas quando visíveis na tela
   - Usar `ListView.builder` para renderização eficiente

4. **Cache Inteligente**
   - Cachear resultados por 5 minutos
   - Invalidar apenas quando filtros mudam significativamente

5. **Limites**
   - Máximo 50 perfis por query
   - Máximo 20 perfis exibidos por vez
   - Paginação automática

## Logging

### Eventos Registrados

```dart
// Início da busca
EnhancedLogger.info('Starting profile search', data: {
  'filters': filters.toJson(),
  'userId': userId,
});

// Resultados da query
EnhancedLogger.info('Firestore query completed', data: {
  'profilesFound': profiles.length,
  'queryTime': queryTime,
});

// Pontuação calculada
EnhancedLogger.debug('Profile scored', data: {
  'profileId': profile.id,
  'score': score.totalScore,
  'breakdown': score.breakdown,
});

// Cache hit/miss
EnhancedLogger.debug('Cache check', data: {
  'hit': cacheHit,
  'key': cacheKey,
});

// Erro
EnhancedLogger.error('Matching error', data: {
  'error': error.toString(),
  'stackTrace': stackTrace,
});
```
