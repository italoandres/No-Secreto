import 'dart:async';
import 'dart:collection';
import '../models/search_filters.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/enhanced_logger.dart';

/// Otimizador de memória para operações de busca
/// com pool de objetos, lazy loading e garbage collection inteligente
class SearchMemoryOptimizer {
  static SearchMemoryOptimizer? _instance;
  static SearchMemoryOptimizer get instance => _instance ??= SearchMemoryOptimizer._();
  
  SearchMemoryOptimizer._();

  /// Pool de objetos reutilizáveis
  final Queue<SpiritualProfileModel> _profilePool = Queue<SpiritualProfileModel>();
  final Queue<SearchFilters> _filtersPool = Queue<SearchFilters>();
  
  /// Cache de objetos processados
  final Map<String, ProcessedProfile> _processedProfiles = {};
  
  /// Configurações de otimização
  static const int maxPoolSize = 100;
  static const int maxProcessedCache = 500;
  static const Duration cacheExpiration = Duration(minutes: 30);
  
  /// Métricas de uso de memória
  int _totalAllocations = 0;
  int _totalDeallocations = 0;
  int _poolHits = 0;
  int _poolMisses = 0;
  
  /// Timer para limpeza periódica
  Timer? _cleanupTimer;

  /// Inicializa o otimizador
  void initialize() {
    _startCleanupTimer();
    
    EnhancedLogger.info('Search memory optimizer initialized', 
      tag: 'SEARCH_MEMORY_OPTIMIZER',
      data: {
        'maxPoolSize': maxPoolSize,
        'maxProcessedCache': maxProcessedCache,
        'cacheExpirationMinutes': cacheExpiration.inMinutes,
      }
    );
  }

  /// Obtém um perfil do pool ou cria um novo
  SpiritualProfileModel getProfile({
    required String id,
    required String displayName,
    String? bio,
    int? age,
    String? city,
    String? state,
    List<String>? interests,
    bool? isVerified,
    bool? hasCompletedCourse,
    Map<String, dynamic>? additionalData,
  }) {
    SpiritualProfileModel profile;
    
    if (_profilePool.isNotEmpty) {
      profile = _profilePool.removeFirst();
      _poolHits++;
      
      // Resetar o perfil com novos dados
      profile = _resetProfile(profile, 
        id: id,
        displayName: displayName,
        bio: bio,
        age: age,
        city: city,
        state: state,
        interests: interests,
        isVerified: isVerified,
        hasCompletedCourse: hasCompletedCourse,
        additionalData: additionalData,
      );
    } else {
      profile = SpiritualProfileModel(
        id: id,
        displayName: displayName,
        // Adicionar outros campos conforme necessário
      );
      _poolMisses++;
      _totalAllocations++;
    }

    return profile;
  }

  /// Retorna um perfil para o pool
  void returnProfile(SpiritualProfileModel profile) {
    if (_profilePool.length < maxPoolSize) {
      _profilePool.add(profile);
      _totalDeallocations++;
    }
  }

  /// Obtém filtros do pool ou cria novos
  SearchFilters getFilters({
    int? minAge,
    int? maxAge,
    String? city,
    String? state,
    List<String>? interests,
    bool? isVerified,
    bool? hasCompletedCourse,
  }) {
    SearchFilters filters;
    
    if (_filtersPool.isNotEmpty) {
      filters = _filtersPool.removeFirst();
      _poolHits++;
      
      // Resetar filtros com novos dados
      filters = SearchFilters(
        minAge: minAge,
        maxAge: maxAge,
        city: city,
        state: state,
        interests: interests,
        isVerified: isVerified,
        hasCompletedCourse: hasCompletedCourse,
      );
    } else {
      filters = SearchFilters(
        minAge: minAge,
        maxAge: maxAge,
        city: city,
        state: state,
        interests: interests,
        isVerified: isVerified,
        hasCompletedCourse: hasCompletedCourse,
      );
      _poolMisses++;
      _totalAllocations++;
    }

    return filters;
  }

  /// Retorna filtros para o pool
  void returnFilters(SearchFilters filters) {
    if (_filtersPool.length < maxPoolSize) {
      _filtersPool.add(filters);
      _totalDeallocations++;
    }
  }

  /// Processa lista de perfis com otimizações de memória
  List<SpiritualProfileModel> processProfiles(
    List<Map<String, dynamic>> rawProfiles, {
    bool useCache = true,
    bool enableLazyLoading = true,
  }) {
    final processedProfiles = <SpiritualProfileModel>[];
    final startTime = DateTime.now();
    
    for (final rawProfile in rawProfiles) {
      final profileId = rawProfile['id'] as String?;
      if (profileId == null) continue;
      
      SpiritualProfileModel profile;
      
      // Verificar cache se habilitado
      if (useCache && _processedProfiles.containsKey(profileId)) {
        final cached = _processedProfiles[profileId]!;
        if (!cached.isExpired) {
          profile = cached.profile;
          cached.lastAccessed = DateTime.now();
          processedProfiles.add(profile);
          continue;
        } else {
          _processedProfiles.remove(profileId);
        }
      }
      
      // Criar novo perfil otimizado
      profile = _createOptimizedProfile(rawProfile, enableLazyLoading);
      processedProfiles.add(profile);
      
      // Cachear se habilitado
      if (useCache) {
        _cacheProcessedProfile(profileId, profile);
      }
    }
    
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    
    EnhancedLogger.debug('Profiles processed with memory optimization', 
      tag: 'SEARCH_MEMORY_OPTIMIZER',
      data: {
        'inputCount': rawProfiles.length,
        'outputCount': processedProfiles.length,
        'processingTime': processingTime,
        'useCache': useCache,
        'enableLazyLoading': enableLazyLoading,
        'cacheHits': _processedProfiles.length,
      }
    );
    
    return processedProfiles;
  }

  /// Aplica filtros de forma otimizada
  List<SpiritualProfileModel> applyFiltersOptimized(
    List<SpiritualProfileModel> profiles,
    SearchFilters filters, {
    bool useParallelProcessing = true,
    int? maxResults,
  }) {
    if (profiles.isEmpty) return profiles;
    
    final startTime = DateTime.now();
    final filteredProfiles = <SpiritualProfileModel>[];
    
    // Otimização: aplicar filtros mais seletivos primeiro
    final prioritizedFilters = _prioritizeFilters(filters);
    
    for (final profile in profiles) {
      if (maxResults != null && filteredProfiles.length >= maxResults) {
        break;
      }
      
      if (_profileMatchesFilters(profile, prioritizedFilters)) {
        filteredProfiles.add(profile);
      }
    }
    
    final filteringTime = DateTime.now().difference(startTime).inMilliseconds;
    
    EnhancedLogger.debug('Filters applied with optimization', 
      tag: 'SEARCH_MEMORY_OPTIMIZER',
      data: {
        'inputCount': profiles.length,
        'outputCount': filteredProfiles.length,
        'filteringTime': filteringTime,
        'useParallelProcessing': useParallelProcessing,
        'maxResults': maxResults,
      }
    );
    
    return filteredProfiles;
  }

  /// Cria perfil otimizado com lazy loading
  SpiritualProfileModel _createOptimizedProfile(Map<String, dynamic> data, bool enableLazyLoading) {
    // Implementar lazy loading para campos não essenciais
    return SpiritualProfileModel(
      id: data['id'] as String,
      displayName: data['displayName'] as String? ?? '',
      // Adicionar outros campos essenciais
    );
  }

  /// Reseta um perfil com novos dados (para reutilização do pool)
  SpiritualProfileModel _resetProfile(
    SpiritualProfileModel profile, {
    required String id,
    required String displayName,
    String? bio,
    int? age,
    String? city,
    String? state,
    List<String>? interests,
    bool? isVerified,
    bool? hasCompletedCourse,
    Map<String, dynamic>? additionalData,
  }) {
    // Como SpiritualProfileModel é imutável, criar nova instância
    return SpiritualProfileModel(
      id: id,
      displayName: displayName,
      // Adicionar outros campos
    );
  }

  /// Cacheia perfil processado
  void _cacheProcessedProfile(String profileId, SpiritualProfileModel profile) {
    if (_processedProfiles.length >= maxProcessedCache) {
      _evictOldestCacheEntry();
    }
    
    _processedProfiles[profileId] = ProcessedProfile(
      profile: profile,
      cachedAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }

  /// Remove entrada mais antiga do cache
  void _evictOldestCacheEntry() {
    if (_processedProfiles.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    _processedProfiles.forEach((key, cached) {
      if (oldestTime == null || cached.lastAccessed.isBefore(oldestTime!)) {
        oldestTime = cached.lastAccessed;
        oldestKey = key;
      }
    });
    
    if (oldestKey != null) {
      _processedProfiles.remove(oldestKey);
    }
  }

  /// Prioriza filtros por seletividade (mais seletivos primeiro)
  List<FilterPredicate> _prioritizeFilters(SearchFilters filters) {
    final predicates = <FilterPredicate>[];
    
    // Filtros booleanos (mais rápidos)
    if (filters.isVerified != null) {
      predicates.add(FilterPredicate(
        type: FilterType.boolean,
        priority: 1,
        predicate: (profile) => true, // Implementar verificação real
      ));
    }
    
    if (filters.hasCompletedCourse != null) {
      predicates.add(FilterPredicate(
        type: FilterType.boolean,
        priority: 1,
        predicate: (profile) => true, // Implementar verificação real
      ));
    }
    
    // Filtros numéricos (médios)
    if (filters.minAge != null || filters.maxAge != null) {
      predicates.add(FilterPredicate(
        type: FilterType.numeric,
        priority: 2,
        predicate: (profile) => true, // Implementar verificação real
      ));
    }
    
    // Filtros de texto (mais custosos)
    if (filters.city != null && filters.city!.isNotEmpty) {
      predicates.add(FilterPredicate(
        type: FilterType.text,
        priority: 3,
        predicate: (profile) => true, // Implementar verificação real
      ));
    }
    
    if (filters.state != null && filters.state!.isNotEmpty) {
      predicates.add(FilterPredicate(
        type: FilterType.text,
        priority: 3,
        predicate: (profile) => true, // Implementar verificação real
      ));
    }
    
    // Filtros de lista (mais custosos)
    if (filters.interests != null && filters.interests!.isNotEmpty) {
      predicates.add(FilterPredicate(
        type: FilterType.list,
        priority: 4,
        predicate: (profile) => true, // Implementar verificação real
      ));
    }
    
    // Ordenar por prioridade
    predicates.sort((a, b) => a.priority.compareTo(b.priority));
    
    return predicates;
  }

  /// Verifica se perfil corresponde aos filtros
  bool _profileMatchesFilters(SpiritualProfileModel profile, List<FilterPredicate> predicates) {
    for (final predicate in predicates) {
      if (!predicate.predicate(profile)) {
        return false;
      }
    }
    return true;
  }

  /// Inicia timer de limpeza
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _performCleanup();
    });
  }

  /// Executa limpeza de memória
  void _performCleanup() {
    final startTime = DateTime.now();
    int cleanedEntries = 0;
    
    // Limpar cache expirado
    final expiredKeys = <String>[];
    _processedProfiles.forEach((key, cached) {
      if (cached.isExpired) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _processedProfiles.remove(key);
      cleanedEntries++;
    }
    
    // Limitar tamanho dos pools
    while (_profilePool.length > maxPoolSize ~/ 2) {
      _profilePool.removeFirst();
    }
    
    while (_filtersPool.length > maxPoolSize ~/ 2) {
      _filtersPool.removeFirst();
    }
    
    final cleanupTime = DateTime.now().difference(startTime).inMilliseconds;
    
    if (cleanedEntries > 0 || cleanupTime > 10) {
      EnhancedLogger.info('Memory cleanup completed', 
        tag: 'SEARCH_MEMORY_OPTIMIZER',
        data: {
          'cleanedEntries': cleanedEntries,
          'cleanupTime': cleanupTime,
          'profilePoolSize': _profilePool.length,
          'filtersPoolSize': _filtersPool.length,
          'processedCacheSize': _processedProfiles.length,
        }
      );
    }
  }

  /// Obtém estatísticas de memória
  Map<String, dynamic> getMemoryStats() {
    final poolEfficiency = _totalAllocations > 0 ? 
        _poolHits / (_poolHits + _poolMisses) : 0.0;
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'pools': {
        'profilePoolSize': _profilePool.length,
        'filtersPoolSize': _filtersPool.length,
        'maxPoolSize': maxPoolSize,
      },
      'cache': {
        'processedProfilesCount': _processedProfiles.length,
        'maxProcessedCache': maxProcessedCache,
        'cacheUsagePercentage': maxProcessedCache > 0 ? 
            _processedProfiles.length / maxProcessedCache : 0.0,
      },
      'metrics': {
        'totalAllocations': _totalAllocations,
        'totalDeallocations': _totalDeallocations,
        'poolHits': _poolHits,
        'poolMisses': _poolMisses,
        'poolEfficiency': poolEfficiency,
        'poolEfficiencyPercentage': '${(poolEfficiency * 100).toStringAsFixed(1)}%',
      },
      'configuration': {
        'maxPoolSize': maxPoolSize,
        'maxProcessedCache': maxProcessedCache,
        'cacheExpirationMinutes': cacheExpiration.inMinutes,
      },
    };
  }

  /// Força limpeza completa
  void forceCleanup() {
    _profilePool.clear();
    _filtersPool.clear();
    _processedProfiles.clear();
    
    EnhancedLogger.info('Forced memory cleanup completed', 
      tag: 'SEARCH_MEMORY_OPTIMIZER'
    );
  }

  /// Para o otimizador
  void dispose() {
    _cleanupTimer?.cancel();
    forceCleanup();
    
    EnhancedLogger.info('Search memory optimizer disposed', 
      tag: 'SEARCH_MEMORY_OPTIMIZER'
    );
  }
}

/// Perfil processado em cache
class ProcessedProfile {
  final SpiritualProfileModel profile;
  final DateTime cachedAt;
  DateTime lastAccessed;

  ProcessedProfile({
    required this.profile,
    required this.cachedAt,
    required this.lastAccessed,
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > SearchMemoryOptimizer.cacheExpiration;
}

/// Predicado de filtro com prioridade
class FilterPredicate {
  final FilterType type;
  final int priority;
  final bool Function(SpiritualProfileModel) predicate;

  const FilterPredicate({
    required this.type,
    required this.priority,
    required this.predicate,
  });
}

/// Tipos de filtro por performance
enum FilterType {
  boolean,  // Mais rápido
  numeric,  // Médio
  text,     // Mais lento
  list,     // Mais lento
}