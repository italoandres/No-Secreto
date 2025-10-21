import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/spiritual_profile_model.dart';
import '../../models/search_filters.dart';
import '../../models/search_result.dart';
import '../../utils/enhanced_logger.dart';
import '../../utils/text_matcher.dart';
import 'search_strategy.dart';

/// Estratégia de busca otimizada para nomes de usuário
/// 
/// Usa técnicas específicas para busca por nome, incluindo
/// matching fuzzy e busca por partes do nome.
class DisplayNameSearchStrategy extends BaseSearchStrategy {
  static const String _collection = 'spiritual_profiles';
  final TextMatcher _textMatcher = TextMatcher();
  
  DisplayNameSearchStrategy() : super(
    name: 'Display Name Search',
    priority: 2, // Prioridade média - específica para nomes
  );
  
  @override
  bool get isAvailable {
    try {
      FirebaseFirestore.instance;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<SearchResult> executeSearch({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  }) async {
    try {
      EnhancedLogger.info('Executing display name search', 
        tag: 'DISPLAY_NAME_STRATEGY',
        data: {
          'query': query,
          'hasFilters': filters != null,
          'limit': limit,
        }
      );
      
      // Buscar perfis com foco em displayName
      final profiles = await _searchByDisplayName(query, filters, limit);
      
      // Aplicar ranking baseado na relevância do nome
      final rankedProfiles = _rankByNameRelevance(profiles, query);
      
      // Limitar resultados finais
      final finalProfiles = rankedProfiles.take(limit).toList();
      
      EnhancedLogger.success('Display name search completed', 
        tag: 'DISPLAY_NAME_STRATEGY',
        data: {
          'query': query,
          'totalFound': profiles.length,
          'finalResults': finalProfiles.length,
        }
      );
      
      return SearchResult.success(
        profiles: finalProfiles,
        strategyUsed: SearchStrategy.displayName,
        searchTime: Duration.zero, // Será atualizado pela classe base
        fromCache: false,
        metadata: {
          'totalFound': profiles.length,
          'hasMore': profiles.length > limit,
        },
      );
      
    } catch (e) {
      EnhancedLogger.error('Display name search failed', 
        tag: 'DISPLAY_NAME_STRATEGY',
        error: e,
        data: {
          'query': query,
          'hasFilters': filters != null,
        }
      );
      
      throw SearchStrategyException(
        message: 'Falha na busca por nome: ${e.toString()}',
        strategyName: name,
        originalError: e,
      );
    }
  }
  
  /// Busca perfis focando no campo displayName
  Future<List<SpiritualProfileModel>> _searchByDisplayName(
    String query,
    SearchFilters? filters,
    int limit,
  ) async {
    final queryLower = query.toLowerCase().trim();
    
    // Busca básica sem filtros complexos
    Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .limit(limit * 4); // Busca mais para compensar filtros
    
    // Aplicar filtros simples se disponíveis
    if (filters?.isVerified == true) {
      baseQuery = baseQuery.where('isVerified', isEqualTo: true);
    }
    
    final querySnapshot = await baseQuery.get();
    
    // Converter e filtrar por nome
    final allProfiles = querySnapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            return SpiritualProfileModel.fromMap(data);
          } catch (e) {
            EnhancedLogger.warning('Failed to parse profile document', 
              tag: 'DISPLAY_NAME_STRATEGY',
              data: {'docId': doc.id},
              error: e
            );
            return null;
          }
        })
        .where((profile) => profile != null)
        .cast<SpiritualProfileModel>()
        .toList();
    
    // Filtrar por nome usando TextMatcher
    final nameMatchedProfiles = allProfiles.where((profile) {
      final displayName = profile.displayName?.toLowerCase() ?? '';
      return _textMatcher.matches(displayName, queryLower);
    }).toList();
    
    // Aplicar outros filtros se necessário
    if (filters != null) {
      return _applyAdditionalFilters(nameMatchedProfiles, filters);
    }
    
    return nameMatchedProfiles;
  }
  
  /// Aplica filtros adicionais além do nome
  List<SpiritualProfileModel> _applyAdditionalFilters(
    List<SpiritualProfileModel> profiles,
    SearchFilters filters,
  ) {
    return profiles.where((profile) {
      // Filtro de idade
      if (filters.minAge != null || filters.maxAge != null) {
        final age = profile.age;
        if (age != null) {
          if (filters.minAge != null && age < filters.minAge!) return false;
          if (filters.maxAge != null && age > filters.maxAge!) return false;
        }
      }
      
      // Filtro de localização
      if (filters.city != null && filters.city!.isNotEmpty) {
        final profileCity = profile.city?.toLowerCase() ?? '';
        final filterCity = filters.city!.toLowerCase();
        if (!profileCity.contains(filterCity)) return false;
      }
      
      if (filters.state != null && filters.state!.isNotEmpty) {
        final profileState = profile.state?.toLowerCase() ?? '';
        final filterState = filters.state!.toLowerCase();
        if (!profileState.contains(filterState)) return false;
      }
      
      // Filtro de interesses
      if (filters.interests != null && filters.interests!.isNotEmpty) {
        final profileInterests = (profile.interests ?? [])
            .map((i) => i.toLowerCase()).toSet();
        final filterInterests = filters.interests!
            .map((i) => i.toLowerCase()).toSet();
        
        if (!filterInterests.any((interest) => 
            profileInterests.any((pInterest) => pInterest.contains(interest)))) {
          return false;
        }
      }
      
      // Outros filtros
      if (filters.hasCompletedCourse == true && profile.hasCompletedCourse != true) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  /// Ordena perfis por relevância do nome
  List<SpiritualProfileModel> _rankByNameRelevance(
    List<SpiritualProfileModel> profiles,
    String query,
  ) {
    final queryLower = query.toLowerCase().trim();
    
    // Calcular score de relevância para cada perfil
    final profilesWithScore = profiles.map((profile) {
      final displayName = profile.displayName?.toLowerCase() ?? '';
      final score = _calculateNameScore(displayName, queryLower);
      return MapEntry(profile, score);
    }).toList();
    
    // Ordenar por score (maior primeiro)
    profilesWithScore.sort((a, b) => b.value.compareTo(a.value));
    
    return profilesWithScore.map((entry) => entry.key).toList();
  }
  
  /// Calcula score de relevância do nome
  double _calculateNameScore(String displayName, String query) {
    if (displayName.isEmpty || query.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // Match exato tem score máximo
    if (displayName == query) {
      score += 100.0;
    }
    // Começa com a query
    else if (displayName.startsWith(query)) {
      score += 80.0;
    }
    // Contém a query
    else if (displayName.contains(query)) {
      score += 60.0;
    }
    
    // Bonus por similaridade usando TextMatcher
    final similarity = _textMatcher.calculateSimilarity(displayName, query);
    score += similarity * 40.0; // Até 40 pontos por similaridade
    
    // Bonus por palavras em comum
    final displayWords = displayName.split(' ');
    final queryWords = query.split(' ');
    
    int commonWords = 0;
    for (final queryWord in queryWords) {
      if (queryWord.isNotEmpty) {
        for (final displayWord in displayWords) {
          if (displayWord.contains(queryWord) || queryWord.contains(displayWord)) {
            commonWords++;
            break;
          }
        }
      }
    }
    
    if (queryWords.isNotEmpty) {
      score += (commonWords / queryWords.length) * 20.0; // Até 20 pontos
    }
    
    return score;
  }
  
  @override
  bool canHandleFilters(SearchFilters? filters) {
    // Esta estratégia funciona melhor com queries de nome
    // Pode lidar com a maioria dos filtros
    return true;
  }
  
  @override
  int estimateExecutionTime(String query, SearchFilters? filters) {
    // Estimativa baseada na complexidade da busca por nome
    int baseTime = 300; // Tempo base maior devido ao ranking
    
    if (query.length > 10) baseTime += 50; // Nomes longos demoram mais
    if (filters != null) baseTime += 100;
    
    return baseTime;
  }
  
  /// Verifica se a query parece ser um nome
  static bool isNameQuery(String query) {
    final trimmed = query.trim();
    
    // Muito curto ou muito longo provavelmente não é nome
    if (trimmed.length < 2 || trimmed.length > 50) return false;
    
    // Contém apenas letras, espaços e alguns caracteres especiais
    final namePattern = RegExp(r'^[a-zA-ZÀ-ÿ\s\-\'\.]+$');
    if (!namePattern.hasMatch(trimmed)) return false;
    
    // Não deve ter muitas palavras (nomes geralmente têm 1-4 palavras)
    final words = trimmed.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length > 4) return false;
    
    return true;
  }
}