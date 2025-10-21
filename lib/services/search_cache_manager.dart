import 'dart:async';
import '../models/search_filters.dart';
import '../models/search_result.dart';
import '../utils/enhanced_logger.dart';

/// Gerenciador de cache inteligente para resultados de busca
/// 
/// Oferece cache com TTL, LRU eviction, estatísticas detalhadas
/// e invalidação baseada em filtros específicos.
class SearchCacheManager {
  static SearchCacheManager? _instance;
  static SearchCacheManager get instance => _instance ??= SearchCacheManager._();
  
  SearchCacheManager._() {
    _initialize();
  }

  /// Cache principal de resultados
  final Map<String, CachedSearchResult> _cache = {};
  
  /// Cache de metadados (para estatísticas rápidas)
  final Map<String, CacheMetadata> _metadata = {};
  
  /// Timer para limpeza automática
  Timer? _cleanupTimer;
  
  /// Configurações do cache
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  static const Duration cleanupInterval = Duration(minutes: 2);
  
  /// Cache específico por tipo de filtro
  final Map<String, Map<String, CachedSearchResult>> _filterTypeCache = {};
  
  /// Estatísticas globais
  int _totalRequests = 0;
  int _totalHits = 0;
  int _totalMisses = 0;
  int _totalStores = 0;
  int _totalEvictions = 0;

  /// Inicializa o gerenciador de cache
  void _initialize() {
    _startCleanupTimer();
    
    EnhancedLogger.info('Search cache manager initialized', 
      tag: 'SEARCH_CACHE_MANAGER',
      data: {
        'maxSize': maxCacheSize,
        'defaultTTL': defaultCacheDuration.inMinutes,
        'cleanupInterval': cleanupInterval.inMinutes,
      }
    );
  }

  /// Para o gerenciador de cache
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _metadata.clear();
    
    EnhancedLogger.info('Search cache manager disposed', 
      tag: 'SEARCH_CACHE_MANAGER'
    );
  }

  /// Obtém resultado do cache se disponível e válido
  Future<SearchResult?> getCachedResult({
    required String query,
    SearchFilters? filters,
    required int limit,
    Duration? maxAge,
  }) async {
    _totalRequests++;
    
    final cacheKey = _generateCacheKey(query, filters, limit);
    final cached = _cache[cacheKey];
    
    if (cached == null) {
      _totalMisses++;
      _updateMetadata(cacheKey, hit: false);
      return null;
    }
    
    // Verificar se ainda é válido
    final age = DateTime.now().difference(cached.cachedAt);
    final maxCacheAge = maxAge ?? defaultCacheDuration;
    
    if (age > maxCacheAge) {
      _cache.remove(cacheKey);
      _metadata.remove(cacheKey);
      _totalMisses++;
      _updateMetadata(cacheKey, hit: false, expired: true);
      
      EnhancedLogger.debug('Cache entry expired', 
        tag: 'SEARCH_CACHE_MANAGER',
        data: {
          'cacheKey': cacheKey,
          'age': age.inSeconds,
          'maxAge': maxCacheAge.inSeconds,
        }
      );
      
      return null;
    }
    
    // Atualizar estatísticas de acesso
    cached.accessCount++;
    cached.lastAccessed = DateTime.now();
    _totalHits++;
    _updateMetadata(cacheKey, hit: true);
    
    EnhancedLogger.debug('Cache hit', 
      tag: 'SEARCH_CACHE_MANAGER',
      data: {
        'cacheKey': cacheKey,
        'age': age.inSeconds,
        'accessCount': cached.accessCount,
        'resultCount': cached.result.profiles.length,
      }
    );
    
    return cached.result.copyWith(fromCache: true);
  }

  /// Armazena resultado no cache
  Future<void> cacheResult({
    required String query,
    SearchFilters? filters,
    required int limit,
    required SearchResult result,
  }) async {
    // Não cachear resultados vazios ou com erro
    if (result.profiles.isEmpty) return;
    
    final cacheKey = _generateCacheKey(query, filters, limit);
    
    // Verificar limite do cache
    if (_cache.length >= maxCacheSize) {
      _evictLeastRecentlyUsed();
    }
    
    final now = DateTime.now();
    _cache[cacheKey] = CachedSearchResult(
      result: result,
      cachedAt: now,
      lastAccessed: now,
      accessCount: 0,
      query: query,
      filters: filters,
      limit: limit,
    );
    
    // Adicionar ao cache específico por tipo de filtro
    _addToFilterTypeCache(query, filters, limit, result);
    
    _totalStores++;
    _updateMetadata(cacheKey, stored: true);
    
    EnhancedLogger.debug('Result cached', 
      tag: 'SEARCH_CACHE_MANAGER',
      data: {
        'cacheKey': cacheKey,
        'query': query,
        'hasFilters': filters != null,
        'resultCount': result.profiles.length,
        'cacheSize': _cache.length,
        'strategy': result.strategy,
      }
    );
  }

  /// Remove entrada específica do cache
  void removeEntry({
    required String query,
    SearchFilters? filters,
    required int limit,
  }) {
    final cacheKey = _generateCacheKey(query, filters, limit);
    _cache.remove(cacheKey);
    _metadata.remove(cacheKey);
    
    // Remover do cache por tipo de filtro também
    _removeFromFilterTypeCache(query, filters, limit);
    
    EnhancedLogger.debug('Cache entry removed', 
      tag: 'SEARCH_CACHE_MANAGER',
      data: {
        'cacheKey': cacheKey,
        'query': query,
        'hasFilters': filters != null,
      }
    );
  }

  /// Limpa todo o cache
  Future<void> clearCache() async {
    final size = _cache.length;
    _cache.clear();
    _metadata.clear();
    _filterTypeCache.clear();
    
    // Reset estatísticas
    _totalRequests = 0;
    _totalHits = 0;
    _totalMisses = 0;
    _totalStores = 0;
    _totalEvictions = 0;
    
    EnhancedLogger.info('Cache cleared completely', 
      tag: 'SEARCH_CACHE_MANAGER',
      data: {'entriesRemoved': size}
    );
  }

  /// Limpa entradas expiradas
  void cleanupExpired({Duration? maxAge}) {
    final now = DateTime.now();
    final maxCacheAge = maxAge ?? defaultCacheDuration;
    final keysToRemove = <String>[];
    
    _cache.forEach((key, cached) {
      final age = now.difference(cached.cachedAt);
      if (age > maxCacheAge) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _metadata.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      EnhancedLogger.debug('Expired entries cleaned', 
        tag: 'SEARCH_CACHE_MANAGER',
        data: {'entriesRemoved': keysToRemove.length}
      );
    }
  }

  /// Remove entrada menos recentemente usada
  void _evictLeastRecentlyUsed() {
    if (_cache.isEmpty) return;
    
    String? lruKey;
    DateTime? oldestAccess;
    
    _cache.forEach((key, cached) {
      if (oldestAccess == null || cached.lastAccessed.isBefore(oldestAccess!)) {
        oldestAccess = cached.lastAccessed;
        lruKey = key;
      }
    });
    
    if (lruKey != null) {
      final cached = _cache[lruKey];
      _cache.remove(lruKey);
      _metadata.remove(lruKey);
      
      // Remover do cache por tipo de filtro também
      if (cached != null) {
        _removeFromFilterTypeCache(cached.query, cached.filters, cached.limit);
      }
      
      _totalEvictions++;
      
      EnhancedLogger.debug('LRU entry evicted', 
        tag: 'SEARCH_CACHE_MANAGER',
        data: {
          'evictedKey': lruKey,
          'age': oldestAccess != null ? 
            DateTime.now().difference(oldestAccess!).inSeconds : 0,
        }
      );
    }
  }
  
  /// Gera chave de cache baseada nos parâmetros
  String _generateCacheKey(String query, SearchFilters? filters, int limit) {
    final buffer = StringBuffer();
    buffer.write('q:${query.toLowerCase()}');
    buffer.write('|l:$limit');
    
    if (filters != null) {
      if (filters.minAge != null) buffer.write('|minAge:${filters.minAge}');
      if (filters.maxAge != null) buffer.write('|maxAge:${filters.maxAge}');
      if (filters.city != null && filters.city!.isNotEmpty) {
        buffer.write('|city:${filters.city!.toLowerCase()}');
      }
      if (filters.state != null && filters.state!.isNotEmpty) {
        buffer.write('|state:${filters.state!.toLowerCase()}');
      }
      if (filters.interests != null && filters.interests!.isNotEmpty) {
        final sortedInterests = List<String>.from(filters.interests!)
          ..sort()
          ..map((i) => i.toLowerCase());
        buffer.write('|interests:${sortedInterests.join(',')}');
      }
      if (filters.isVerified != null) {
        buffer.write('|verified:${filters.isVerified}');
      }
      if (filters.hasCompletedCourse != null) {
        buffer.write('|course:${filters.hasCompletedCourse}');
      }
    }
    
    return buffer.toString();
  }
  
  /// Adiciona ao cache específico por tipo de filtro
  void _addToFilterTypeCache(String query, SearchFilters? filters, int limit, SearchResult result) {
    final filterType = _getFilterType(filters);
    final filterCache = _filterTypeCache[filterType] ??= {};
    final cacheKey = _generateCacheKey(query, filters, limit);
    
    filterCache[cacheKey] = CachedSearchResult(
      result: result,
      cachedAt: DateTime.now(),
      lastAccessed: DateTime.now(),
      accessCount: 0,
      query: query,
      filters: filters,
      limit: limit,
    );
  }
  
  /// Remove do cache específico por tipo de filtro
  void _removeFromFilterTypeCache(String query, SearchFilters? filters, int limit) {
    final filterType = _getFilterType(filters);
    final filterCache = _filterTypeCache[filterType];
    if (filterCache != null) {
      final cacheKey = _generateCacheKey(query, filters, limit);
      filterCache.remove(cacheKey);
      
      // Remover cache vazio
      if (filterCache.isEmpty) {
        _filterTypeCache.remove(filterType);
      }
    }
  }
  
  /// Determina o tipo de filtro para cache específico
  String _getFilterType(SearchFilters? filters) {
    if (filters == null) return 'no_filters';
    
    final types = <String>[];
    
    if (filters.minAge != null || filters.maxAge != null) types.add('age');
    if (filters.city != null && filters.city!.isNotEmpty) types.add('city');
    if (filters.state != null && filters.state!.isNotEmpty) types.add('state');
    if (filters.interests != null && filters.interests!.isNotEmpty) types.add('interests');
    if (filters.isVerified == true) types.add('verified');
    if (filters.hasCompletedCourse == true) types.add('course');
    
    return types.isEmpty ? 'no_filters' : types.join('_');
  }
  
  /// Invalida cache baseado em tipo de filtro
  void invalidateByFilterType(String filterType) {
    final filterCache = _filterTypeCache[filterType];
    if (filterCache != null) {
      // Remover entradas do cache principal
      for (final key in filterCache.keys) {
        _cache.remove(key);
        _metadata.remove(key);
      }
      
      // Limpar cache específico
      _filterTypeCache.remove(filterType);
      
      EnhancedLogger.info('Cache invalidated by filter type', 
        tag: 'SEARCH_CACHE_MANAGER',
        data: {
          'filterType': filterType,
          'entriesRemoved': filterCache.length,
        }
      );
    }
  }

  /// Atualiza metadados de cache
  void _updateMetadata(String cacheKey, {
    bool hit = false,
    bool expired = false,
    bool stored = false,
  }) {
    final metadata = _metadata[cacheKey] ??= CacheMetadata();
    
    if (hit) metadata.hits++;
    if (expired) metadata.expirations++;
    if (stored) metadata.stores++;
    if (!hit && !expired) metadata.misses++;
  }

  /// Inicia timer de limpeza automática
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      cleanupExpired();
    });
  }

  /// Obtém estatísticas completas do cache
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    
    // Estatísticas de metadados
    int metadataHits = 0;
    int metadataMisses = 0;
    int metadataStores = 0;
    int metadataExpirations = 0;
    
    _metadata.values.forEach((meta) {
      metadataHits += meta.hits;
      metadataMisses += meta.misses;
      metadataStores += meta.stores;
      metadataExpirations += meta.expirations;
    });
    
    // Calcular idade média das entradas
    double averageAge = 0.0;
    if (_cache.isNotEmpty) {
      final totalAge = _cache.values.fold(0, (sum, cached) => 
        sum + now.difference(cached.cachedAt).inMilliseconds);
      averageAge = totalAge / _cache.length;
    }
    
    // Estatísticas por tipo de filtro
    final filterTypeStats = <String, Map<String, dynamic>>{};
    _filterTypeCache.forEach((filterType, cache) {
      filterTypeStats[filterType] = {
        'entries': cache.length,
        'averageAge': cache.isEmpty ? 0 : cache.values.fold(0, (sum, cached) => 
          sum + now.difference(cached.cachedAt).inMilliseconds) / cache.length,
      };
    });
    
    final hitRate = _totalRequests == 0 ? 0.0 : _totalHits / _totalRequests;
    
    return {
      'timestamp': now.toIso8601String(),
      'size': _cache.length,
      'maxSize': maxCacheSize,
      'usagePercentage': maxCacheSize == 0 ? 0.0 : _cache.length / maxCacheSize,
      'hitRate': hitRate,
      'hitRatePercentage': '${(hitRate * 100).toStringAsFixed(1)}%',
      'totalRequests': _totalRequests,
      'totalHits': _totalHits,
      'totalMisses': _totalMisses,
      'totalStores': _totalStores,
      'totalEvictions': _totalEvictions,
      'averageAge': Duration(milliseconds: averageAge.round()).inSeconds,
      'filterTypeStats': filterTypeStats,
      'metadata': {
        'hits': metadataHits,
        'misses': metadataMisses,
        'stores': metadataStores,
        'expirations': metadataExpirations,
      },
      'configuration': {
        'defaultTTL': defaultCacheDuration.inMinutes,
        'cleanupInterval': cleanupInterval.inMinutes,
        'maxSize': maxCacheSize,
      },
    };
  }

  /// Obtém informações detalhadas sobre uma entrada
  CacheEntryInfo? getEntryInfo({
    required String query,
    SearchFilters? filters,
    required int limit,
  }) {
    final cacheKey = _generateCacheKey(query, filters, limit);
    final cached = _cache[cacheKey];
    final metadata = _metadata[cacheKey];
    
    if (cached == null) return null;
    
    final now = DateTime.now();
    return CacheEntryInfo(
      cacheKey: cacheKey,
      age: now.difference(cached.cachedAt),
      lastAccessed: cached.lastAccessed,
      accessCount: cached.accessCount,
      resultCount: cached.result.profiles.length,
      hits: metadata?.hits ?? 0,
      misses: metadata?.misses ?? 0,
      query: query,
      filters: filters,
      strategy: cached.result.strategy,
    );
  }
  
  /// Lista todas as entradas do cache
  List<CacheEntryInfo> getAllEntries() {
    final entries = <CacheEntryInfo>[];
    final now = DateTime.now();
    
    _cache.forEach((cacheKey, cached) {
      final metadata = _metadata[cacheKey];
      entries.add(CacheEntryInfo(
        cacheKey: cacheKey,
        age: now.difference(cached.cachedAt),
        lastAccessed: cached.lastAccessed,
        accessCount: cached.accessCount,
        resultCount: cached.result.profiles.length,
        hits: metadata?.hits ?? 0,
        misses: metadata?.misses ?? 0,
        query: cached.query,
        filters: cached.filters,
        strategy: cached.result.strategy,
      ));
    });
    
    // Ordenar por último acesso (mais recente primeiro)
    entries.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
    
    return entries;
  }
  
  /// Pré-aquece o cache com buscas comuns
  Future<void> warmupCache() async {
    EnhancedLogger.info('Starting cache warmup', 
      tag: 'SEARCH_CACHE_MANAGER'
    );
    
    // Aqui você pode adicionar buscas comuns para pré-aquecer o cache
    // Por exemplo, perfis verificados sem filtros
    
    EnhancedLogger.info('Cache warmup completed', 
      tag: 'SEARCH_CACHE_MANAGER'
    );
  }
}

/// Resultado em cache com metadados
class CachedSearchResult {
  final SearchResult result;
  final DateTime cachedAt;
  DateTime lastAccessed;
  int accessCount;
  final String query;
  final SearchFilters? filters;
  final int limit;

  CachedSearchResult({
    required this.result,
    required this.cachedAt,
    required this.lastAccessed,
    required this.accessCount,
    required this.query,
    required this.filters,
    required this.limit,
  });
}

/// Metadados de cache por chave
class CacheMetadata {
  int hits = 0;
  int misses = 0;
  int stores = 0;
  int expirations = 0;
}



/// Informações sobre uma entrada específica do cache
class CacheEntryInfo {
  final String cacheKey;
  final Duration age;
  final DateTime lastAccessed;
  final int accessCount;
  final int resultCount;
  final int hits;
  final int misses;
  final String query;
  final SearchFilters? filters;
  final String strategy;

  const CacheEntryInfo({
    required this.cacheKey,
    required this.age,
    required this.lastAccessed,
    required this.accessCount,
    required this.resultCount,
    required this.hits,
    required this.misses,
    required this.query,
    required this.filters,
    required this.strategy,
  });

  Map<String, dynamic> toJson() {
    return {
      'cacheKey': cacheKey,
      'age': age.inMilliseconds,
      'ageSeconds': age.inSeconds,
      'lastAccessed': lastAccessed.toIso8601String(),
      'accessCount': accessCount,
      'resultCount': resultCount,
      'hits': hits,
      'misses': misses,
      'query': query,
      'hasFilters': filters != null,
      'strategy': strategy,
      'filterType': filters != null ? _getFilterTypeSummary(filters!) : 'none',
    };
  }
  
  String _getFilterTypeSummary(SearchFilters filters) {
    final types = <String>[];
    
    if (filters.minAge != null || filters.maxAge != null) types.add('age');
    if (filters.city != null && filters.city!.isNotEmpty) types.add('city');
    if (filters.state != null && filters.state!.isNotEmpty) types.add('state');
    if (filters.interests != null && filters.interests!.isNotEmpty) types.add('interests');
    if (filters.isVerified == true) types.add('verified');
    if (filters.hasCompletedCourse == true) types.add('course');
    
    return types.isEmpty ? 'none' : types.join('+');
  }
}