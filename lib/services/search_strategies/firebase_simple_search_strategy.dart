import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/spiritual_profile_model.dart';
import '../../models/search_filters.dart';
import '../../models/search_result.dart';
import '../../utils/enhanced_logger.dart';
import 'search_strategy.dart';

/// Estratégia de busca simples usando Firebase
/// 
/// Implementa busca básica sem queries complexas que podem falhar
/// por falta de índices. Foca em queries simples e filtros no código.
class FirebaseSimpleSearchStrategy extends BaseSearchStrategy {
  static const String _collection = 'spiritual_profiles';
  
  FirebaseSimpleSearchStrategy() : super(
    name: 'Firebase Simple',
    priority: 1, // Alta prioridade por ser mais confiável
  );
  
  @override
  bool get isAvailable {
    try {
      // Verifica se o Firebase está disponível
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
      EnhancedLogger.info('Executing Firebase simple search', 
        tag: 'FIREBASE_SIMPLE_STRATEGY',
        data: {
          'query': query,
          'hasFilters': filters != null,
          'limit': limit,
        }
      );
      
      // Busca básica sem queries complexas
      Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(limit * 3); // Busca mais para compensar filtros no código
      
      // Aplicar apenas filtros simples que não requerem índices complexos
      if (filters?.isVerified == true) {
        baseQuery = baseQuery.where('isVerified', isEqualTo: true);
      }
      
      final querySnapshot = await baseQuery.get();
      
      EnhancedLogger.info('Firebase query executed', 
        tag: 'FIREBASE_SIMPLE_STRATEGY',
        data: {
          'documentsFound': querySnapshot.docs.length,
        }
      );
      
      // Converter documentos para modelos
      final allProfiles = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return SpiritualProfileModel.fromMap(data);
            } catch (e) {
              EnhancedLogger.warning('Failed to parse profile document', 
                tag: 'FIREBASE_SIMPLE_STRATEGY',
                data: {'docId': doc.id},
                error: e
              );
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<SpiritualProfileModel>()
          .toList();
      
      // Aplicar filtros no código
      final filteredProfiles = _applyFiltersInCode(
        profiles: allProfiles,
        query: query,
        filters: filters,
      );
      
      // Limitar resultados finais
      final finalProfiles = filteredProfiles.take(limit).toList();
      
      EnhancedLogger.success('Firebase simple search completed', 
        tag: 'FIREBASE_SIMPLE_STRATEGY',
        data: {
          'query': query,
          'totalFound': allProfiles.length,
          'afterFilters': filteredProfiles.length,
          'finalResults': finalProfiles.length,
        }
      );
      
      return SearchResult.success(
        profiles: finalProfiles,
        strategyUsed: SearchStrategy.firebaseSimple,
        searchTime: Duration.zero, // Será atualizado pela classe base
        fromCache: false,
        metadata: {
          'totalFound': allProfiles.length,
          'afterFilters': filteredProfiles.length,
          'hasMore': filteredProfiles.length > limit,
        },
      );
      
    } catch (e) {
      EnhancedLogger.error('Firebase simple search failed', 
        tag: 'FIREBASE_SIMPLE_STRATEGY',
        error: e,
        data: {
          'query': query,
          'hasFilters': filters != null,
        }
      );
      
      throw SearchStrategyException(
        message: 'Falha na busca simples do Firebase: ${e.toString()}',
        strategyName: name,
        originalError: e,
      );
    }
  }
  
  /// Aplica filtros no código Dart após busca básica
  List<SpiritualProfileModel> _applyFiltersInCode({
    required List<SpiritualProfileModel> profiles,
    required String query,
    SearchFilters? filters,
  }) {
    var filteredProfiles = profiles;
    
    // Filtro por query de texto
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      filteredProfiles = filteredProfiles.where((profile) {
        return _matchesTextQuery(profile, queryLower);
      }).toList();
    }
    
    // Aplicar filtros específicos
    if (filters != null) {
      filteredProfiles = _applySpecificFilters(filteredProfiles, filters);
    }
    
    return filteredProfiles;
  }
  
  /// Verifica se o perfil corresponde à query de texto
  bool _matchesTextQuery(SpiritualProfileModel profile, String queryLower) {
    // Busca em campos principais
    final searchableText = [
      profile.displayName ?? '',
      profile.bio ?? '',
      profile.city ?? '',
      profile.state ?? '',
      ...(profile.interests ?? []),
    ].join(' ').toLowerCase();
    
    // Busca por palavras individuais
    final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty);
    
    return queryWords.every((word) => searchableText.contains(word));
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
        }
      }
      
      // Filtro de cidade
      if (filters.city != null && filters.city!.isNotEmpty) {
        final profileCity = profile.city?.toLowerCase() ?? '';
        final filterCity = filters.city!.toLowerCase();
        if (!profileCity.contains(filterCity)) return false;
      }
      
      // Filtro de estado
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
        
        // Deve ter pelo menos um interesse em comum
        if (!filterInterests.any((interest) => 
            profileInterests.any((pInterest) => pInterest.contains(interest)))) {
          return false;
        }
      }
      
      // Filtro de verificação
      if (filters.isVerified == true && profile.isVerified != true) {
        return false;
      }
      
      // Filtro de curso completo
      if (filters.hasCompletedCourse == true && profile.hasCompletedCourse != true) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  @override
  bool canHandleFilters(SearchFilters? filters) {
    // Esta estratégia pode lidar com todos os filtros aplicando-os no código
    return true;
  }
  
  @override
  int estimateExecutionTime(String query, SearchFilters? filters) {
    // Estimativa baseada na complexidade
    int baseTime = 200; // Tempo base para query simples
    
    if (query.isNotEmpty) baseTime += 50;
    if (filters != null) baseTime += 100;
    
    return baseTime;
  }
}