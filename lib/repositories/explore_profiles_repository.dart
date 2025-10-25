import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../models/profile_engagement_model.dart';
import '../models/search_filters.dart';
import '../services/search_profiles_service.dart';
import '../utils/enhanced_logger.dart';
import '../utils/text_matcher.dart';
// REMOVIDO: import '../utils/unified_profile_search.dart'; (arquivo deletado)
import '../utils/vitrine_profile_filter.dart';

/// Repository para exploração de perfis
class ExploreProfilesRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca perfis verificados com curso Sinais usando o novo sistema robusto
  static Future<List<SpiritualProfileModel>> getVerifiedProfiles({
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      EnhancedLogger.info(
          'Fetching verified profiles with robust search system',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {'searchQuery': searchQuery, 'limit': limit});

      // Usar o novo sistema de busca robusto para perfis verificados
      final filters = SearchFilters(
        isVerified: true,
        hasCompletedCourse: true,
      );

      final searchService = SearchProfilesService.instance;
      final result = await searchService.searchProfiles(
        query: searchQuery ?? '',
        filters: filters,
        limit: limit,
        useCache: true,
      );

      EnhancedLogger.success('Verified profiles fetched successfully',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'count': result.profiles.length,
            'strategy': result.strategy,
            'fromCache': result.fromCache,
            'executionTime': result.executionTime,
          });

      return result.profiles;
    } catch (e) {
      EnhancedLogger.error('Failed to fetch verified profiles',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});

      // Fallback para método legado
      return await _legacyGetVerifiedProfiles(searchQuery, limit);
    }
  }

  /// Método legado para buscar perfis verificados (fallback ultra-seguro)
  static Future<List<SpiritualProfileModel>> _legacyGetVerifiedProfiles(
    String? searchQuery,
    int limit,
  ) async {
    try {
      EnhancedLogger.warning('Using legacy fallback for verified profiles',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {'searchQuery': searchQuery, 'limit': limit});

      // Query mais básica possível para evitar problemas de índices
      Query query = _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit * 3); // Buscar mais para compensar filtros

      final snapshot = await query.get();

      List<SpiritualProfileModel> profiles = snapshot.docs
          .map((doc) {
            try {
              return SpiritualProfileModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            } catch (e) {
              EnhancedLogger.warning('Failed to parse profile document',
                  tag: 'EXPLORE_PROFILES_REPOSITORY',
                  data: {'docId': doc.id, 'error': e.toString()});
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<SpiritualProfileModel>()
          .toList();

      // Aplicar filtros no código Dart
      profiles = profiles.where((profile) {
        // Filtros obrigatórios
        if (profile.isVerified != true) return false;
        if (profile.hasCompletedCourse != true) return false;

        // Filtro de busca textual
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final searchableText = [
            profile.displayName ?? '',
            profile.bio ?? '',
            profile.city ?? '',
            profile.state ?? '',
            ...(profile.interests ?? []),
          ].join(' ').toLowerCase();

          final queryWords = searchQuery.toLowerCase().split(' ');
          final hasMatch = queryWords
              .any((word) => word.isNotEmpty && searchableText.contains(word));

          if (!hasMatch) return false;
        }

        return true;
      }).toList();

      final result = profiles.take(limit).toList();

      EnhancedLogger.info('Legacy verified profiles fetch completed',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'totalFetched': profiles.length,
            'afterFilters': result.length,
            'searchQuery': searchQuery,
          });

      return result;
    } catch (e) {
      EnhancedLogger.error('Legacy verified profiles fetch failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      return [];
    }
  }

  /// Busca perfis ordenados por engajamento
  static Future<List<SpiritualProfileModel>> getProfilesByEngagement({
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      EnhancedLogger.info('Fetching profiles by engagement',
          tag: 'EXPLORE_PROFILES',
          data: {'searchQuery': searchQuery, 'limit': limit});

      // Primeiro buscar métricas de engajamento
      final engagementQuery = await _firestore
          .collection('profile_engagement')
          .where('isEligibleForExploration', isEqualTo: true)
          .orderBy('engagementScore', descending: true)
          .limit(limit * 2) // Buscar mais para filtrar depois
          .get();

      final userIds = engagementQuery.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

      if (userIds.isEmpty) {
        return [];
      }

      // Buscar perfis espirituais correspondentes
      Query profilesQuery = _firestore
          .collection('spiritual_profiles')
          .where('userId',
              whereIn: userIds.take(10).toList()) // Firestore limit
          .where('isActive',
              isEqualTo: true); // 🔧 CORREÇÃO FINAL - apenas perfis ativos

      // Adicionar filtro de busca se fornecido
      if (searchQuery != null && searchQuery.isNotEmpty) {
        profilesQuery = profilesQuery.where('searchKeywords',
            arrayContains: searchQuery.toLowerCase());
      }

      final profilesSnapshot = await profilesQuery.get();

      final profiles = profilesSnapshot.docs
          .map((doc) => SpiritualProfileModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Ordenar por prioridade de engajamento
      profiles.sort((a, b) {
        final aIndex = userIds.indexOf(a.userId ?? '');
        final bIndex = userIds.indexOf(b.userId ?? '');
        return aIndex.compareTo(bIndex);
      });

      EnhancedLogger.success('Profiles by engagement fetched',
          tag: 'EXPLORE_PROFILES', data: {'count': profiles.length});

      return profiles.take(limit).toList();
    } catch (e) {
      EnhancedLogger.error('Failed to fetch profiles by engagement',
          tag: 'EXPLORE_PROFILES', data: {'error': e.toString()});
      return [];
    }
  }

  /// Atualiza métricas de engajamento de um perfil
  static Future<void> updateEngagementMetrics(
    String userId, {
    int? storyCommentsIncrement,
    int? storyLikesIncrement,
    int? screenTimeIncrement,
  }) async {
    try {
      final docRef = _firestore.collection('profile_engagement').doc(userId);

      final updateData = <String, dynamic>{
        'lastActivity': Timestamp.now(),
      };

      if (storyCommentsIncrement != null) {
        updateData['storyCommentsCount'] =
            FieldValue.increment(storyCommentsIncrement);
      }

      if (storyLikesIncrement != null) {
        updateData['storyLikesCount'] =
            FieldValue.increment(storyLikesIncrement);
      }

      if (screenTimeIncrement != null) {
        updateData['totalScreenTime'] =
            FieldValue.increment(screenTimeIncrement);
      }

      await docRef.set(updateData, SetOptions(merge: true));

      // Recalcular score de engajamento
      await _recalculateEngagementScore(userId);

      EnhancedLogger.info('Engagement metrics updated',
          tag: 'EXPLORE_PROFILES', data: {'userId': userId});
    } catch (e) {
      EnhancedLogger.error('Failed to update engagement metrics',
          tag: 'EXPLORE_PROFILES',
          data: {'userId': userId, 'error': e.toString()});
    }
  }

  /// Recalcula score de engajamento
  static Future<void> _recalculateEngagementScore(String userId) async {
    try {
      final doc =
          await _firestore.collection('profile_engagement').doc(userId).get();

      if (doc.exists) {
        final engagement = ProfileEngagementModel.fromJson(doc.data()!);
        final newScore = engagement.calculateEngagementScore();

        await doc.reference.update({
          'engagementScore': newScore,
          'isEligibleForExploration': engagement.isEligibleForExploration,
          'priority': engagement.priority,
        });
      }
    } catch (e) {
      EnhancedLogger.error('Failed to recalculate engagement score',
          tag: 'EXPLORE_PROFILES',
          data: {'userId': userId, 'error': e.toString()});
    }
  }

  /// Busca perfis usando estratégia em camadas com fallback automático
  static Future<List<SpiritualProfileModel>> searchProfiles({
    String? query,
    int? minAge,
    int? maxAge,
    String? city,
    String? state,
    List<String>? interests,
    int limit = 30,
    bool requireVerified = false, // 🔧 CORREÇÃO FINAL - padrão alterado
    bool requireCompletedCourse = false, // 🔧 CORREÇÃO FINAL - padrão alterado
  }) async {
    final startTime = DateTime.now();

    try {
      EnhancedLogger.info('Searching profiles with layered strategy system',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'query': query,
            'minAge': minAge,
            'maxAge': maxAge,
            'city': city,
            'state': state,
            'interests': interests,
            'limit': limit,
            'requireVerified': requireVerified,
            'requireCompletedCourse': requireCompletedCourse,
          });

      // Criar filtros de busca
      final filters = SearchFilters(
        minAge: minAge,
        maxAge: maxAge,
        city: city,
        state: state,
        interests: interests,
        isVerified: requireVerified,
        hasCompletedCourse: requireCompletedCourse,
      );

      // ESTRATÉGIA EM CAMADAS - Tentar do mais específico para o mais geral
      List<SpiritualProfileModel> result = [];

      // Camada 0: Busca APENAS perfis de vitrine completos (NOVA CORREÇÃO)
      try {
        result = await VitrineProfileFilter.searchCompleteVitrineProfiles(
          query: query,
          limit: limit,
        );

        if (result.isNotEmpty) {
          final executionTime =
              DateTime.now().difference(startTime).inMilliseconds;

          EnhancedLogger.success(
              'Layer 0 search successful (Complete Vitrine Only)',
              tag: 'EXPLORE_PROFILES_REPOSITORY',
              data: {
                'results': result.length,
                'strategy': 'completeVitrineOnly',
                'executionTime': executionTime,
                'onlyCompleteVitrineProfiles': true,
                'requiresUsername': true,
                'requiresCompleteData': true,
              });

          return result.take(limit).toList();
        }
      } catch (e) {
        EnhancedLogger.warning(
            'Layer 0 complete vitrine search failed, trying Layer 1',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {'error': e.toString()});
      }

      // Camada 1: Usar o serviço de busca robusto (mais eficiente)
      try {
        final searchService = SearchProfilesService.instance;
        final searchResult = await searchService.searchProfiles(
          query: query ?? '',
          filters: filters,
          limit: limit,
          useCache: true,
        );

        result = searchResult.profiles;

        if (result.isNotEmpty) {
          final executionTime =
              DateTime.now().difference(startTime).inMilliseconds;

          EnhancedLogger.success('Layer 1 search successful (SearchService)',
              tag: 'EXPLORE_PROFILES_REPOSITORY',
              data: {
                'results': result.length,
                'strategy': searchResult.strategy,
                'fromCache': searchResult.fromCache,
                'executionTime': executionTime,
              });

          return result;
        }
      } catch (e) {
        EnhancedLogger.warning('Layer 1 search failed, trying Layer 2',
            tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      }

      // Camada 2: Busca Firebase simplificada com filtros básicos
      try {
        result = await _layeredFirebaseSearch(query, filters, limit);

        if (result.isNotEmpty) {
          final executionTime =
              DateTime.now().difference(startTime).inMilliseconds;

          EnhancedLogger.success(
              'Layer 2 search successful (Simplified Firebase)',
              tag: 'EXPLORE_PROFILES_REPOSITORY',
              data: {
                'results': result.length,
                'executionTime': executionTime,
              });

          return result;
        }
      } catch (e) {
        EnhancedLogger.warning('Layer 2 search failed, trying Layer 3',
            tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      }

      // Camada 3: Busca básica com filtros aplicados no código Dart
      try {
        result = await _basicSearchWithDartFilters(query, filters, limit);

        final executionTime =
            DateTime.now().difference(startTime).inMilliseconds;

        EnhancedLogger.success(
            'Layer 3 search completed (Basic + Dart filters)',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {
              'results': result.length,
              'executionTime': executionTime,
            });

        return result;
      } catch (e) {
        final executionTime =
            DateTime.now().difference(startTime).inMilliseconds;

        EnhancedLogger.error('All search layers failed',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            error: e,
            data: {'executionTime': executionTime});

        return [];
      }
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      EnhancedLogger.error('Critical error in layered search',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          error: e,
          data: {'executionTime': executionTime});

      return [];
    }
  }

  /// Camada 2: Busca Firebase simplificada com filtros essenciais
  static Future<List<SpiritualProfileModel>> _layeredFirebaseSearch(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.info('Executing Layer 2: Simplified Firebase search',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {'query': query, 'limit': limit});

    // Construir query Firebase com apenas filtros essenciais e seguros
    Query profilesQuery = _firestore
        .collection('spiritual_profiles')
        .where('isActive', isEqualTo: true);

    // 🔧 CORREÇÃO FINAL - Filtros restritivos removidos temporariamente
    // Mantendo apenas filtro de perfis ativos (sempre aplicado)
    // if (filters.isVerified == true) {
    //   profilesQuery = profilesQuery.where('isVerified', isEqualTo: true);
    // }

    if (filters.hasCompletedCourse == true) {
      profilesQuery =
          profilesQuery.where('hasCompletedCourse', isEqualTo: true);
    }

    // Limitar resultados para buscar mais e filtrar depois
    profilesQuery = profilesQuery.limit(limit * 3);

    final snapshot = await profilesQuery.get();
    final profiles = _parseProfileDocuments(snapshot.docs);

    // Aplicar filtros restantes no código Dart
    final filteredProfiles = _applyOptimizedFilters(profiles, query, filters);

    return filteredProfiles.take(limit).toList();
  }

  /// Camada 3: Busca básica com todos os filtros aplicados no código Dart
  static Future<List<SpiritualProfileModel>> _basicSearchWithDartFilters(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.info('Executing Layer 3: Basic search with Dart filters',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {'query': query, 'limit': limit});

    // Query mais básica possível - apenas isActive
    final snapshot = await _firestore
        .collection('spiritual_profiles')
        .where('isActive', isEqualTo: true)
        .limit(limit * 5) // Buscar mais para compensar filtros
        .get();

    final profiles = _parseProfileDocuments(snapshot.docs);

    // Aplicar TODOS os filtros no código Dart
    final filteredProfiles = _applyOptimizedFilters(profiles, query, filters);

    return filteredProfiles.take(limit).toList();
  }

  /// Fallback manual ultra-robusto para quando tudo falha
  static Future<List<SpiritualProfileModel>> _manualFallbackSearch(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.warning('Executing manual fallback search (last resort)',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {
          'query': query,
          'hasFilters': filters != null,
          'limit': limit,
        });

    try {
      // Query mais básica possível - apenas isActive
      Query profilesQuery = _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit * 4); // Buscar mais para compensar filtros no código

      // Tentar adicionar filtros básicos se possível
      try {
        // 🔧 CORREÇÃO FINAL - Filtro isVerified removido temporariamente
        // if (filters.isVerified == true) {
        //   profilesQuery = profilesQuery.where('isVerified', isEqualTo: true);
        // }
      } catch (e) {
        EnhancedLogger.warning('Could not add isVerified filter',
            tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      }

      try {
        if (filters.hasCompletedCourse == true) {
          profilesQuery =
              profilesQuery.where('hasCompletedCourse', isEqualTo: true);
        }
      } catch (e) {
        EnhancedLogger.warning('Could not add hasCompletedCourse filter',
            tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      }

      final snapshot = await profilesQuery.get();

      List<SpiritualProfileModel> profiles = snapshot.docs
          .map((doc) {
            try {
              return SpiritualProfileModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            } catch (e) {
              EnhancedLogger.warning('Failed to parse profile in fallback',
                  tag: 'EXPLORE_PROFILES_REPOSITORY',
                  data: {'docId': doc.id, 'error': e.toString()});
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<SpiritualProfileModel>()
          .toList();

      // Aplicar filtros no código Dart
      profiles = _applyOptimizedFilters(profiles, query, filters);

      final result = profiles.take(limit).toList();

      EnhancedLogger.info('Manual fallback search completed',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'totalFetched': snapshot.docs.length,
            'afterParsing': profiles.length,
            'finalResults': result.length,
          });

      return result;
    } catch (e) {
      EnhancedLogger.error('Manual fallback search failed completely',
          tag: 'EXPLORE_PROFILES_REPOSITORY', error: e);

      // Último recurso - tentar busca sem filtros
      try {
        final snapshot = await _firestore
            .collection('spiritual_profiles')
            .limit(limit)
            .get();

        final profiles = snapshot.docs
            .map((doc) {
              try {
                return SpiritualProfileModel.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                });
              } catch (e) {
                return null;
              }
            })
            .where((profile) => profile != null)
            .cast<SpiritualProfileModel>()
            .toList();

        EnhancedLogger.warning('Using emergency fallback with no filters',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {'results': profiles.length});

        return profiles;
      } catch (emergencyError) {
        EnhancedLogger.error('Emergency fallback also failed',
            tag: 'EXPLORE_PROFILES_REPOSITORY', error: emergencyError);
        return [];
      }
    }
  }

  /// Aplica filtros manualmente no código Dart (ultra-robusto)
  static List<SpiritualProfileModel> _applyManualFilters(
    List<SpiritualProfileModel> profiles,
    String? query,
    SearchFilters filters,
  ) {
    return profiles.where((profile) {
      try {
        // Filtro de texto com busca flexível
        if (query != null && query.isNotEmpty) {
          final searchableText = [
            profile.displayName ?? '',
            profile.bio ?? '',
            profile.city ?? '',
            profile.state ?? '',
            ...(profile.interests ?? []),
          ].join(' ').toLowerCase();

          // Busca por palavras individuais
          final queryWords = query
              .toLowerCase()
              .split(' ')
              .where((word) => word.isNotEmpty)
              .toList();

          if (queryWords.isNotEmpty) {
            final hasMatch =
                queryWords.any((word) => searchableText.contains(word));
            if (!hasMatch) return false;
          }
        }

        // Filtros de idade com validação
        if (filters.minAge != null) {
          if (profile.age == null || profile.age! < filters.minAge!) {
            return false;
          }
        }
        if (filters.maxAge != null) {
          if (profile.age == null || profile.age! > filters.maxAge!) {
            return false;
          }
        }

        // Filtros de localização com busca flexível
        if (filters.city != null && filters.city!.isNotEmpty) {
          final profileCity = profile.city?.toLowerCase() ?? '';
          final filterCity = filters.city!.toLowerCase();
          if (profileCity.isEmpty || !profileCity.contains(filterCity)) {
            return false;
          }
        }

        if (filters.state != null && filters.state!.isNotEmpty) {
          final profileState = profile.state?.toLowerCase() ?? '';
          final filterState = filters.state!.toLowerCase();
          if (profileState.isEmpty || !profileState.contains(filterState)) {
            return false;
          }
        }

        // Filtros de interesses com busca flexível
        if (filters.interests != null && filters.interests!.isNotEmpty) {
          final profileInterests =
              (profile.interests ?? []).map((i) => i.toLowerCase()).toList();

          if (profileInterests.isEmpty) return false;

          final filterInterests =
              filters.interests!.map((i) => i.toLowerCase()).toList();

          // Deve ter pelo menos um interesse relacionado
          final hasCommonInterest = filterInterests.any((filterInterest) =>
              profileInterests.any((profileInterest) =>
                  profileInterest.contains(filterInterest) ||
                  filterInterest.contains(profileInterest)));

          if (!hasCommonInterest) return false;
        }

        // Filtros booleanos
        if (filters.isVerified == true && profile.isVerified != true) {
          return false;
        }
        if (filters.hasCompletedCourse == true &&
            profile.hasCompletedCourse != true) {
          return false;
        }

        return true;
      } catch (e) {
        // Se houver erro ao processar um perfil, excluí-lo dos resultados
        EnhancedLogger.warning('Error applying manual filters to profile',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {'profileId': profile.id, 'error': e.toString()});
        return false;
      }
    }).toList();
  }

  /// Registra visualização de perfil
  static Future<void> recordProfileView(
      String viewerId, String profileId) async {
    try {
      await _firestore.collection('profile_views').add({
        'viewerId': viewerId,
        'profileId': profileId,
        'viewedAt': Timestamp.now(),
      });

      // TODO: Implementar contador de visualizações se necessário
      // await _firestore.collection('spiritual_profiles').doc(profileId).update({
      //   'viewsCount': FieldValue.increment(1),
      // });

      EnhancedLogger.info('Profile view recorded',
          tag: 'EXPLORE_PROFILES',
          data: {'viewerId': viewerId, 'profileId': profileId});
    } catch (e) {
      EnhancedLogger.error('Failed to record profile view',
          tag: 'EXPLORE_PROFILES', error: e);
    }
  }

  /// Obtém perfis populares (mais visualizados) - VERSÃO CORRIGIDA
  static Future<List<SpiritualProfileModel>> getPopularProfiles(
      {int limit = 10}) async {
    try {
      // Buscar sem orderBy para evitar índice composto
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .where('isActive',
              isEqualTo: true) // 🔧 CORREÇÃO FINAL - apenas perfis ativos
          .limit(limit * 2)
          .get();

      List<SpiritualProfileModel> profiles = snapshot.docs
          .map((doc) => SpiritualProfileModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Ordenar no código Dart - usando createdAt como alternativa
      profiles.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      profiles = profiles.take(limit).toList();

      EnhancedLogger.success('Popular profiles fetched',
          tag: 'EXPLORE_PROFILES', data: {'count': profiles.length});

      return profiles;
    } catch (e) {
      EnhancedLogger.error('Failed to fetch popular profiles',
          tag: 'EXPLORE_PROFILES', error: e);
      return [];
    }
  }

  /// Obtém estatísticas completas do sistema de busca
  static Map<String, dynamic> getSearchStats() {
    try {
      final searchService = SearchProfilesService.instance;
      final stats = searchService.getStats();

      return {
        'searchService': stats,
        'timestamp': DateTime.now().toIso8601String(),
        'repositoryVersion': '2.0.0',
        'features': [
          'robust_search',
          'automatic_fallback',
          'intelligent_cache',
          'multiple_strategies',
          'comprehensive_logging',
        ],
      };
    } catch (e) {
      EnhancedLogger.error('Failed to get search stats',
          tag: 'EXPLORE_PROFILES_REPOSITORY', error: e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'repositoryVersion': '2.0.0',
        'status': 'error',
      };
    }
  }

  /// Limpa o cache do sistema de busca
  static Future<void> clearSearchCache() async {
    try {
      final searchService = SearchProfilesService.instance;
      await searchService.clearCache();

      EnhancedLogger.info('Search cache cleared successfully',
          tag: 'EXPLORE_PROFILES_REPOSITORY');
    } catch (e) {
      EnhancedLogger.error('Failed to clear search cache',
          tag: 'EXPLORE_PROFILES_REPOSITORY', error: e);
    }
  }

  /// Testa uma busca específica com estratégia forçada (para debug)
  static Future<List<SpiritualProfileModel>> testSearchWithStrategy({
    required String? query,
    required SearchFilters? filters,
    required int limit,
    String? strategyName,
  }) async {
    try {
      EnhancedLogger.info('Testing search with specific strategy',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'query': query,
            'strategyName': strategyName,
            'hasFilters': filters != null,
            'limit': limit,
          });

      final searchService = SearchProfilesService.instance;

      List<SpiritualProfileModel> result;

      if (strategyName != null) {
        // Forçar estratégia específica
        result = await searchService.searchWithStrategy(
          strategyName: strategyName,
          query: query ?? '',
          filters: filters,
          limit: limit,
        );
      } else {
        // Usar busca normal
        final searchResult = await searchService.searchProfiles(
          query: query ?? '',
          filters: filters,
          limit: limit,
          useCache: false, // Não usar cache para testes
        );
        result = searchResult.profiles;
      }

      EnhancedLogger.success('Test search completed successfully',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'query': query,
            'results': result.length,
            'strategyName': strategyName,
          });

      return result;
    } catch (e) {
      EnhancedLogger.error('Test search failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          error: e,
          data: {
            'query': query,
            'strategyName': strategyName,
          });
      return [];
    }
  }

  /// Testa todas as estratégias disponíveis (para debug completo)
  static Future<Map<String, List<SpiritualProfileModel>>> testAllStrategies({
    required String query,
    SearchFilters? filters,
    int limit = 10,
  }) async {
    try {
      EnhancedLogger.info('Testing all search strategies',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'query': query,
            'hasFilters': filters != null,
            'limit': limit,
          });

      final searchService = SearchProfilesService.instance;
      final results = await searchService.testAllStrategies(
        query: query,
        filters: filters,
        limit: limit,
      );

      // Converter SearchResult para List<SpiritualProfileModel>
      final convertedResults = <String, List<SpiritualProfileModel>>{};
      for (final entry in results.entries) {
        convertedResults[entry.key] = entry.value.profiles;
      }

      EnhancedLogger.success('All strategies tested successfully',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {
            'query': query,
            'strategiesTested': convertedResults.keys.length,
            'totalResults': convertedResults.values
                .fold(0, (sum, profiles) => sum + profiles.length),
          });

      return convertedResults;
    } catch (e) {
      EnhancedLogger.error('Failed to test all strategies',
          tag: 'EXPLORE_PROFILES_REPOSITORY', error: e);
      return {};
    }
  }

  // ========== MÉTODOS DE CLASSIFICAÇÃO DE ERRO E FALLBACKS ESPECÍFICOS ==========

  /// Classifica o tipo de erro do Firebase para escolher melhor estratégia de fallback
  static FirebaseErrorType _classifyFirebaseError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Erros de índice faltando
    if (errorString.contains('index') ||
        errorString.contains('composite') ||
        errorString.contains('requires an index') ||
        errorString.contains('inequality filter') ||
        errorString.contains('order by')) {
      return FirebaseErrorType.indexMissing;
    }

    // Erros de permissão
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('unauthorized') ||
        errorString.contains('insufficient permissions')) {
      return FirebaseErrorType.permissionDenied;
    }

    // Erros de rede
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unavailable') ||
        errorString.contains('deadline exceeded')) {
      return FirebaseErrorType.networkError;
    }

    // Erros de quota
    if (errorString.contains('quota') ||
        errorString.contains('limit') ||
        errorString.contains('exceeded') ||
        errorString.contains('resource exhausted')) {
      return FirebaseErrorType.quotaExceeded;
    }

    return FirebaseErrorType.unknown;
  }

  /// Tratamento específico para erros Firebase com retry inteligente
  static Future<List<SpiritualProfileModel>> _handleFirebaseError(
    dynamic error,
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    final errorType = _classifyFirebaseError(error);

    EnhancedLogger.warning('Handling Firebase error with specific strategy',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {
          'errorType': errorType.toString(),
          'query': query,
          'limit': limit,
        });

    switch (errorType) {
      case FirebaseErrorType.indexMissing:
        return await _indexMissingFallback(query, filters, limit);
      case FirebaseErrorType.permissionDenied:
        return await _permissionDeniedFallback(query, filters, limit);
      case FirebaseErrorType.networkError:
        return await _networkErrorFallback(query, filters, limit);
      case FirebaseErrorType.quotaExceeded:
        return await _quotaExceededFallback(query, filters, limit);
      default:
        return await _manualFallbackSearch(query, filters, limit);
    }
  }

  /// Fallback específico para erro de índice faltando
  static Future<List<SpiritualProfileModel>> _indexMissingFallback(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.warning('Using index missing fallback',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {'query': query, 'limit': limit});

    try {
      // Query mais simples possível - apenas campos indexados básicos
      Query profilesQuery = _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit * 3);

      // Tentar adicionar apenas filtros que certamente têm índice
      // 🔧 CORREÇÃO FINAL - Filtro isVerified removido temporariamente
      // if (filters.isVerified == true) {
      //   try {
      //     profilesQuery = profilesQuery.where('isVerified', isEqualTo: true);
      //   } catch (e) {
      //     EnhancedLogger.warning('Could not add isVerified filter in index fallback',
      //       tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      //   }
      // }

      final snapshot = await profilesQuery.get();
      final profiles = _parseProfileDocuments(snapshot.docs);

      // Aplicar todos os outros filtros no código
      final filteredProfiles = _applyOptimizedFilters(profiles, query, filters);

      return filteredProfiles.take(limit).toList();
    } catch (e) {
      EnhancedLogger.error('Index missing fallback failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      return await _emergencyFallback(limit);
    }
  }

  /// Fallback específico para erro de permissão
  static Future<List<SpiritualProfileModel>> _permissionDeniedFallback(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.warning('Using permission denied fallback',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {'query': query, 'limit': limit});

    try {
      // Tentar query mais básica sem filtros sensíveis
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(limit * 2)
          .get();

      final profiles = _parseProfileDocuments(snapshot.docs);
      final filteredProfiles = _applyOptimizedFilters(profiles, query, filters);

      return filteredProfiles.take(limit).toList();
    } catch (e) {
      EnhancedLogger.error('Permission denied fallback failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      return [];
    }
  }

  /// Fallback específico para erro de rede
  static Future<List<SpiritualProfileModel>> _networkErrorFallback(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.warning('Using network error fallback',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {'query': query, 'limit': limit});

    // Para erros de rede, tentar cache local primeiro
    try {
      final searchService = SearchProfilesService.instance;
      final cachedResult = await searchService.searchProfiles(
        query: query ?? '',
        filters: filters,
        limit: limit,
        useCache: true,
      );

      if (cachedResult.profiles.isNotEmpty) {
        EnhancedLogger.info('Using cached results for network error',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {'cachedResults': cachedResult.profiles.length});
        return cachedResult.profiles;
      }
    } catch (e) {
      EnhancedLogger.warning('Cache fallback failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
    }

    // Se não há cache, tentar query simples com timeout menor
    try {
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get()
          .timeout(Duration(seconds: 5));

      final profiles = _parseProfileDocuments(snapshot.docs);
      return _applyOptimizedFilters(profiles, query, filters)
          .take(limit)
          .toList();
    } catch (e) {
      EnhancedLogger.error('Network error fallback failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      return [];
    }
  }

  /// Fallback específico para erro de quota excedida
  static Future<List<SpiritualProfileModel>> _quotaExceededFallback(
    String? query,
    SearchFilters filters,
    int limit,
  ) async {
    EnhancedLogger.warning('Using quota exceeded fallback',
        tag: 'EXPLORE_PROFILES_REPOSITORY',
        data: {'query': query, 'limit': limit});

    // Para quota excedida, usar apenas cache
    try {
      final searchService = SearchProfilesService.instance;
      final cachedResult = await searchService.searchProfiles(
        query: query ?? '',
        filters: filters,
        limit: limit,
        useCache: true,
      );

      EnhancedLogger.info('Using cached results for quota exceeded',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {'cachedResults': cachedResult.profiles.length});

      return cachedResult.profiles;
    } catch (e) {
      EnhancedLogger.error('Quota exceeded fallback failed',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      return [];
    }
  }

  /// Fallback de emergência - última tentativa
  static Future<List<SpiritualProfileModel>> _emergencyFallback(
      int limit) async {
    EnhancedLogger.warning('Using emergency fallback (last resort)',
        tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'limit': limit});

    try {
      // Query mais básica possível
      final snapshot = await _firestore
          .collection('spiritual_profiles')
          .limit(limit)
          .get()
          .timeout(Duration(seconds: 3));

      final profiles = _parseProfileDocuments(snapshot.docs);

      EnhancedLogger.info('Emergency fallback completed',
          tag: 'EXPLORE_PROFILES_REPOSITORY',
          data: {'results': profiles.length});

      return profiles;
    } catch (e) {
      EnhancedLogger.error('Emergency fallback failed completely',
          tag: 'EXPLORE_PROFILES_REPOSITORY', data: {'error': e.toString()});
      return [];
    }
  }

  /// Método auxiliar para parsing seguro de documentos
  static List<SpiritualProfileModel> _parseProfileDocuments(
      List<QueryDocumentSnapshot> docs) {
    final profiles = <SpiritualProfileModel>[];

    for (final doc in docs) {
      try {
        final profile = SpiritualProfileModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        profiles.add(profile);
      } catch (e) {
        EnhancedLogger.warning('Failed to parse profile document',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {'docId': doc.id, 'error': e.toString()});
        // Continuar com outros documentos
      }
    }

    return profiles;
  }

  /// Método otimizado para aplicação de filtros manuais
  static List<SpiritualProfileModel> _applyOptimizedFilters(
    List<SpiritualProfileModel> profiles,
    String? query,
    SearchFilters filters,
  ) {
    if (profiles.isEmpty) return profiles;

    return profiles.where((profile) {
      try {
        // Filtros rápidos primeiro (booleanos)
        if (filters.isVerified == true && profile.isVerified != true) {
          return false;
        }
        if (filters.hasCompletedCourse == true &&
            profile.hasCompletedCourse != true) {
          return false;
        }

        // Filtros de idade (numéricos)
        if (filters.minAge != null &&
            (profile.age == null || profile.age! < filters.minAge!)) {
          return false;
        }
        if (filters.maxAge != null &&
            (profile.age == null || profile.age! > filters.maxAge!)) {
          return false;
        }

        // Filtros de texto (mais custosos)
        if (query != null && query.isNotEmpty) {
          if (!_matchesTextQuery(profile, query)) {
            return false;
          }
        }

        // Filtros de localização
        if (!_matchesLocationFilters(profile, filters)) {
          return false;
        }

        // Filtros de interesses
        if (!_matchesInterestFilters(profile, filters)) {
          return false;
        }

        return true;
      } catch (e) {
        EnhancedLogger.warning('Error applying optimized filters to profile',
            tag: 'EXPLORE_PROFILES_REPOSITORY',
            data: {'profileId': profile.id, 'error': e.toString()});
        return false;
      }
    }).toList();
  }

  /// Verifica se o perfil corresponde à query de texto
  static bool _matchesTextQuery(SpiritualProfileModel profile, String query) {
    final searchableText = [
      profile.displayName ?? '',
      profile.bio ?? '',
      profile.city ?? '',
      profile.state ?? '',
      ...(profile.interests ?? []),
    ].join(' ').toLowerCase();

    final queryWords = query
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    if (queryWords.isEmpty) return true;

    // Usar TextMatcher para busca mais inteligente
    try {
      return queryWords.any(
          (word) => TextMatcher.matches(searchableText, word, threshold: 0.6));
    } catch (e) {
      // Fallback para busca simples
      return queryWords.any((word) => searchableText.contains(word));
    }
  }

  /// Verifica se o perfil corresponde aos filtros de localização
  static bool _matchesLocationFilters(
      SpiritualProfileModel profile, SearchFilters filters) {
    if (filters.city != null && filters.city!.isNotEmpty) {
      final profileCity = profile.city?.toLowerCase() ?? '';
      final filterCity = filters.city!.toLowerCase();
      if (profileCity.isEmpty || !profileCity.contains(filterCity)) {
        return false;
      }
    }

    if (filters.state != null && filters.state!.isNotEmpty) {
      final profileState = profile.state?.toLowerCase() ?? '';
      final filterState = filters.state!.toLowerCase();
      if (profileState.isEmpty || !profileState.contains(filterState)) {
        return false;
      }
    }

    return true;
  }

  /// Verifica se o perfil corresponde aos filtros de interesses
  static bool _matchesInterestFilters(
      SpiritualProfileModel profile, SearchFilters filters) {
    if (filters.interests == null || filters.interests!.isEmpty) {
      return true;
    }

    final profileInterests =
        (profile.interests ?? []).map((i) => i.toLowerCase()).toList();

    if (profileInterests.isEmpty) return false;

    final filterInterests =
        filters.interests!.map((i) => i.toLowerCase()).toList();

    // Deve ter pelo menos um interesse relacionado
    return filterInterests.any((filterInterest) => profileInterests.any(
        (profileInterest) =>
            profileInterest.contains(filterInterest) ||
            filterInterest.contains(profileInterest)));
  }
}

/// Enum para classificação de tipos de erro do Firebase
enum FirebaseErrorType {
  indexMissing,
  permissionDenied,
  networkError,
  quotaExceeded,
  unknown,
}
