import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/search_filters.dart';
import '../models/search_result.dart';
import '../models/search_params.dart' as params;
import '../models/spiritual_profile_model.dart';
import '../utils/enhanced_logger.dart';
import 'search_analytics_service.dart';
import 'search_alert_service.dart';

/// Serviço principal para busca de perfis - versão funcional
class SearchProfilesService {
  static SearchProfilesService? _instance;
  static SearchProfilesService get instance =>
      _instance ??= SearchProfilesService._();

  SearchProfilesService._();

  /// Firebase Firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Serviço de analytics
  final SearchAnalyticsService _analyticsService =
      SearchAnalyticsService.instance;

  /// Serviço de alertas
  final SearchAlertService _alertService = SearchAlertService.instance;

  /// Busca perfis usando estratégia Firebase
  Future<SearchResult> searchProfiles({
    required String query,
    SearchFilters? filters,
    int limit = 20,
    bool useCache = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      EnhancedLogger.info('Starting profile search',
          tag: 'SEARCH_PROFILES_SERVICE',
          data: {
            'query': query,
            'hasFilters': filters != null,
            'limit': limit,
            'useCache': useCache,
          });

      // Buscar perfis no Firebase
      final profiles = await _searchProfilesInFirebase(query, filters, limit);

      final result = SearchResult(
        profiles: profiles,
        totalFound: profiles.length,
        strategy: 'firebaseSimple',
        executionTime: stopwatch.elapsedMilliseconds,
        fromCache: false,
      );

      // Track analytics
      _analyticsService.trackSearchEvent(
        query: query,
        result: result,
        strategy: 'firebaseSimple',
      );

      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();

      EnhancedLogger.error('Search profiles failed',
          tag: 'SEARCH_PROFILES_SERVICE', data: {'error': e.toString()});

      return SearchResult.error(
        error: e.toString(),
        strategy: 'error',
        executionTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Busca perfis no Firebase Firestore - SEM ÍNDICES COMPOSTOS
  Future<List<SpiritualProfileModel>> _searchProfilesInFirebase(
    String query,
    SearchFilters? filters,
    int limit,
  ) async {
    try {
      // ESTRATÉGIA SIMPLES: Buscar apenas com isActive e filtrar o resto no código
      Query firestoreQuery = _firestore
          .collection('spiritual_profiles')
          .where('isActive', isEqualTo: true)
          .limit(limit * 3); // Buscar mais para compensar filtros

      // Executar query simples
      final snapshot = await firestoreQuery.get();

      EnhancedLogger.info('Firebase query executed',
          tag: 'SEARCH_PROFILES_SERVICE',
          data: {'documentsFound': snapshot.docs.length});

      // Converter documentos para modelos
      List<SpiritualProfileModel> profiles = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final profile = SpiritualProfileModel.fromMap({
            'id': doc.id,
            ...data,
          });
          profiles.add(profile);
        } catch (e) {
          EnhancedLogger.warning('Failed to parse profile document',
              tag: 'SEARCH_PROFILES_SERVICE',
              data: {'docId': doc.id, 'error': e.toString()});
        }
      }

      EnhancedLogger.info('Profiles parsed',
          tag: 'SEARCH_PROFILES_SERVICE',
          data: {'profilesParsed': profiles.length});

      // Aplicar todos os filtros no código
      profiles = _applyAllFilters(profiles, query, filters);

      EnhancedLogger.info('Filters applied',
          tag: 'SEARCH_PROFILES_SERVICE',
          data: {'profilesAfterFilter': profiles.length});

      // Limitar ao número solicitado
      return profiles.take(limit).toList();
    } catch (e) {
      EnhancedLogger.error('Firebase search failed',
          tag: 'SEARCH_PROFILES_SERVICE', data: {'error': e.toString()});
      return [];
    }
  }

  /// Aplica todos os filtros no código (sem precisar de índices Firebase)
  List<SpiritualProfileModel> _applyAllFilters(
    List<SpiritualProfileModel> profiles,
    String query,
    SearchFilters? filters,
  ) {
    List<SpiritualProfileModel> filteredProfiles = profiles;

    // Filtro de verificação
    if (filters?.isVerified == true) {
      filteredProfiles = filteredProfiles.where((profile) {
        return profile.isVerified == true;
      }).toList();
    }

    // Filtro de curso completo
    if (filters?.hasCompletedCourse == true) {
      filteredProfiles = filteredProfiles.where((profile) {
        return profile.hasCompletedCourse == true;
      }).toList();
    }

    // Filtros de idade
    if (filters?.minAge != null) {
      filteredProfiles = filteredProfiles.where((profile) {
        final age = profile.age;
        return age != null && age >= filters!.minAge!;
      }).toList();
    }

    if (filters?.maxAge != null) {
      filteredProfiles = filteredProfiles.where((profile) {
        final age = profile.age;
        return age != null && age <= filters!.maxAge!;
      }).toList();
    }

    // Filtros de localização
    if (filters?.city != null && filters!.city!.isNotEmpty) {
      filteredProfiles = filteredProfiles.where((profile) {
        return profile.city?.toLowerCase() == filters.city!.toLowerCase();
      }).toList();
    }

    if (filters?.state != null && filters!.state!.isNotEmpty) {
      filteredProfiles = filteredProfiles.where((profile) {
        return profile.state?.toLowerCase() == filters.state!.toLowerCase();
      }).toList();
    }

    // Filtro de texto
    if (query.isNotEmpty) {
      filteredProfiles = _applyTextFilter(filteredProfiles, query);
    }

    // Filtro de interesses
    if (filters?.interests != null && filters!.interests!.isNotEmpty) {
      filteredProfiles =
          _applyInterestsFilter(filteredProfiles, filters.interests!);
    }

    return filteredProfiles;
  }

  /// Aplica filtro de texto nos perfis
  List<SpiritualProfileModel> _applyTextFilter(
    List<SpiritualProfileModel> profiles,
    String query,
  ) {
    final queryLower = query.toLowerCase();

    return profiles.where((profile) {
      // Campos pesquisáveis
      final searchableText = [
        profile.displayName ?? '',
        profile.bio ?? '',
        profile.city ?? '',
        profile.state ?? '',
        ...(profile.interests ?? []),
      ].join(' ').toLowerCase();

      // Busca por palavras individuais
      final queryWords =
          queryLower.split(' ').where((word) => word.isNotEmpty).toList();

      // Deve conter pelo menos uma palavra
      return queryWords.any((word) => searchableText.contains(word));
    }).toList();
  }

  /// Aplica filtro de interesses
  List<SpiritualProfileModel> _applyInterestsFilter(
    List<SpiritualProfileModel> profiles,
    List<String> interests,
  ) {
    return profiles.where((profile) {
      final profileInterests =
          (profile.interests ?? []).map((i) => i.toLowerCase()).toList();

      if (profileInterests.isEmpty) return false;

      final filterInterests = interests.map((i) => i.toLowerCase()).toList();

      // Deve ter pelo menos um interesse em comum
      return filterInterests.any((filterInterest) => profileInterests.any(
          (profileInterest) =>
              profileInterest.contains(filterInterest) ||
              filterInterest.contains(profileInterest)));
    }).toList();
  }

  /// Obtém estatísticas do serviço
  Map<String, dynamic> getStats() {
    return {
      'version': '1.0.0',
      'status': 'active',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa o cache
  Future<void> clearCache() async {
    EnhancedLogger.info('Cache cleared', tag: 'SEARCH_PROFILES_SERVICE');
  }

  /// Busca com estratégia específica
  Future<List<SpiritualProfileModel>> searchWithStrategy({
    required String strategyName,
    required String query,
    SearchFilters? filters,
    required int limit,
  }) async {
    EnhancedLogger.info('Search with strategy: $strategyName',
        tag: 'SEARCH_PROFILES_SERVICE');

    // Por enquanto, usar a mesma implementação
    final result = await searchProfiles(
      query: query,
      filters: filters,
      limit: limit,
      useCache: false,
    );

    return result.profiles;
  }

  /// Testa todas as estratégias
  Future<Map<String, dynamic>> testAllStrategies({
    required String query,
    SearchFilters? filters,
    required int limit,
  }) async {
    EnhancedLogger.info('Testing all strategies',
        tag: 'SEARCH_PROFILES_SERVICE');
    return {};
  }

  /// Track interação com resultado de busca
  void trackResultInteraction({
    required String query,
    required String profileId,
    required String interactionType,
    int? resultPosition,
    Map<String, dynamic>? context,
  }) {
    _analyticsService.trackResultInteraction(
      query: query,
      profileId: profileId,
      interactionType: interactionType,
      resultPosition: resultPosition,
      context: {
        'service': 'SearchProfilesService',
        ...?context,
      },
    );
  }

  /// Obtém relatório de analytics
  Map<String, dynamic> getAnalyticsReport() {
    return _analyticsService.getAnalyticsReport();
  }

  /// Obtém alertas ativos
  List<dynamic> getActiveAlerts() {
    return [];
  }

  /// Força verificação de alertas
  void checkAlertsNow() {
    EnhancedLogger.info('Checking alerts', tag: 'SEARCH_PROFILES_SERVICE');
  }
}
