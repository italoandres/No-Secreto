import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/spiritual_profile_model.dart';
import '../../models/search_filters.dart';
import '../../models/search_result.dart';
import '../../utils/enhanced_logger.dart';
import 'search_strategy.dart';

/// Estratégia de fallback para quando outras estratégias falham
///
/// Implementa busca ultra-simples que sempre funciona,
/// mesmo quando há problemas com índices ou conectividade.
class FallbackSearchStrategy extends BaseSearchStrategy {
  static const String _collection = 'spiritual_profiles';

  FallbackSearchStrategy()
      : super(
          name: 'Fallback',
          priority:
              999, // Prioridade mais baixa - usado apenas como último recurso
        );

  @override
  bool get isAvailable {
    // Esta estratégia está sempre disponível como último recurso
    return true;
  }

  @override
  Future<SearchResult> executeSearch({
    required String query,
    SearchFilters? filters,
    int limit = 20,
  }) async {
    try {
      EnhancedLogger.warning('Using fallback search strategy',
          tag: 'FALLBACK_STRATEGY',
          data: {
            'query': query,
            'hasFilters': filters != null,
            'limit': limit,
            'reason': 'Other strategies failed or unavailable',
          });

      // Busca mais básica possível - apenas perfis ativos
      final profiles = await _performBasicSearch(limit * 2);

      // Aplicar filtros manualmente no código
      final filteredProfiles = _applyAllFiltersInCode(
        profiles: profiles,
        query: query,
        filters: filters,
      );

      // Limitar resultados
      final finalProfiles = filteredProfiles.take(limit).toList();

      EnhancedLogger.info('Fallback search completed',
          tag: 'FALLBACK_STRATEGY',
          data: {
            'query': query,
            'totalFetched': profiles.length,
            'afterFilters': filteredProfiles.length,
            'finalResults': finalProfiles.length,
          });

      return SearchResult.success(
        profiles: finalProfiles,
        strategyUsed: SearchStrategy.fallback,
        searchTime: Duration.zero, // Será atualizado pela classe base
        fromCache: false,
        metadata: {
          'totalFetched': profiles.length,
          'afterFilters': filteredProfiles.length,
          'hasMore': filteredProfiles.length > limit,
        },
      );
    } catch (e) {
      EnhancedLogger.error('Even fallback search failed',
          tag: 'FALLBACK_STRATEGY',
          error: e,
          data: {
            'query': query,
            'hasFilters': filters != null,
          });

      // Como último recurso, retorna resultado vazio
      return SearchResult(
        profiles: [],
        query: query,
        totalResults: 0,
        hasMore: false,
        appliedFilters: filters,
        strategy: name,
        executionTime: 0,
        fromCache: false,
      );
    }
  }

  /// Executa a busca mais básica possível
  Future<List<SpiritualProfileModel>> _performBasicSearch(int limit) async {
    try {
      // Query mais simples possível - apenas isActive
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return SpiritualProfileModel.fromMap(data);
            } catch (e) {
              // Ignora documentos com problemas de parsing
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<SpiritualProfileModel>()
          .toList();
    } catch (e) {
      EnhancedLogger.error('Basic Firebase query failed',
          tag: 'FALLBACK_STRATEGY', error: e);

      // Se até isso falhar, tenta sem filtros
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection(_collection)
            .limit(limit)
            .get();

        return querySnapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return SpiritualProfileModel.fromMap(data);
              } catch (e) {
                return null;
              }
            })
            .where((profile) => profile != null)
            .cast<SpiritualProfileModel>()
            .toList();
      } catch (e2) {
        EnhancedLogger.error('Even basic query without filters failed',
            tag: 'FALLBACK_STRATEGY', error: e2);

        // Retorna lista vazia como último recurso
        return [];
      }
    }
  }

  /// Aplica todos os filtros no código Dart
  List<SpiritualProfileModel> _applyAllFiltersInCode({
    required List<SpiritualProfileModel> profiles,
    required String query,
    SearchFilters? filters,
  }) {
    var filteredProfiles = profiles;

    // Filtrar por query de texto (busca muito básica)
    if (query.isNotEmpty) {
      filteredProfiles = _filterByTextQuery(filteredProfiles, query);
    }

    // Aplicar filtros específicos
    if (filters != null) {
      filteredProfiles = _applySpecificFilters(filteredProfiles, filters);
    }

    return filteredProfiles;
  }

  /// Filtro de texto muito básico
  List<SpiritualProfileModel> _filterByTextQuery(
    List<SpiritualProfileModel> profiles,
    String query,
  ) {
    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return profiles;

    return profiles.where((profile) {
      // Busca muito simples em campos principais
      final searchableFields = [
        profile.displayName ?? '',
        profile.bio ?? '',
        profile.city ?? '',
        profile.state ?? '',
      ];

      final searchableText = searchableFields.join(' ').toLowerCase();

      // Busca por palavras individuais
      final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty);

      // Deve conter pelo menos uma palavra da query
      return queryWords.any((word) => searchableText.contains(word));
    }).toList();
  }

  /// Aplica filtros específicos
  List<SpiritualProfileModel> _applySpecificFilters(
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
        } else if (filters.minAge != null || filters.maxAge != null) {
          // Se idade é obrigatória mas não está definida, exclui
          return false;
        }
      }

      // Filtro de cidade (busca flexível)
      if (filters.city != null && filters.city!.isNotEmpty) {
        final profileCity = profile.city?.toLowerCase() ?? '';
        final filterCity = filters.city!.toLowerCase();
        if (profileCity.isEmpty || !profileCity.contains(filterCity)) {
          return false;
        }
      }

      // Filtro de estado (busca flexível)
      if (filters.state != null && filters.state!.isNotEmpty) {
        final profileState = profile.state?.toLowerCase() ?? '';
        final filterState = filters.state!.toLowerCase();
        if (profileState.isEmpty || !profileState.contains(filterState)) {
          return false;
        }
      }

      // Filtro de interesses (busca flexível)
      if (filters.interests != null && filters.interests!.isNotEmpty) {
        final profileInterests =
            (profile.interests ?? []).map((i) => i.toLowerCase()).toList();

        if (profileInterests.isEmpty) return false;

        final filterInterests =
            filters.interests!.map((i) => i.toLowerCase()).toList();

        // Deve ter pelo menos um interesse relacionado
        bool hasCommonInterest = false;
        for (final filterInterest in filterInterests) {
          for (final profileInterest in profileInterests) {
            if (profileInterest.contains(filterInterest) ||
                filterInterest.contains(profileInterest)) {
              hasCommonInterest = true;
              break;
            }
          }
          if (hasCommonInterest) break;
        }

        if (!hasCommonInterest) return false;
      }

      // Filtro de verificação
      if (filters.isVerified == true && profile.isVerified != true) {
        return false;
      }

      // Filtro de curso completo
      if (filters.hasCompletedCourse == true &&
          profile.hasCompletedCourse != true) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  bool canHandleFilters(SearchFilters? filters) {
    // A estratégia de fallback pode lidar com qualquer filtro
    // aplicando-os no código, mesmo que não seja eficiente
    return true;
  }

  @override
  int estimateExecutionTime(String query, SearchFilters? filters) {
    // Tempo estimado alto porque processa tudo no código
    int baseTime = 500; // Tempo base alto

    if (query.isNotEmpty) baseTime += 100;
    if (filters != null) baseTime += 200;

    return baseTime;
  }

  @override
  void clearCache() {
    // Fallback não usa cache próprio
  }

  @override
  Map<String, dynamic> getStats() {
    final baseStats = super.getStats();

    // Adicionar informações específicas do fallback
    baseStats['isFallback'] = true;
    baseStats['reliability'] = 'high'; // Sempre funciona
    baseStats['performance'] = 'low'; // Mas é lento

    return baseStats;
  }
}
