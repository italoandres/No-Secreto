import 'search_filters.dart';

/// Estratégias de busca disponíveis
enum SearchStrategy {
  firebaseSimple,
  displayName,
  fallback,
  auto, // Escolhe automaticamente a melhor estratégia
}

/// Parâmetros para busca de perfis
class SearchParams {
  final String? query;
  final SearchFilters? filters;
  final int limit;
  final SearchStrategy? preferredStrategy;
  final bool useCache;
  final Duration? timeout;

  const SearchParams({
    this.query,
    this.filters,
    this.limit = 30,
    this.preferredStrategy,
    this.useCache = true,
    this.timeout,
  });

  /// Cria uma cópia com novos valores
  SearchParams copyWith({
    String? query,
    SearchFilters? filters,
    int? limit,
    SearchStrategy? preferredStrategy,
    bool? useCache,
    Duration? timeout,
  }) {
    return SearchParams(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      limit: limit ?? this.limit,
      preferredStrategy: preferredStrategy ?? this.preferredStrategy,
      useCache: useCache ?? this.useCache,
      timeout: timeout ?? this.timeout,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'filters': filters?.toJson(),
      'limit': limit,
      'preferredStrategy': preferredStrategy?.name,
      'useCache': useCache,
      'timeout': timeout?.inMilliseconds,
    };
  }

  /// Cria a partir de JSON
  factory SearchParams.fromJson(Map<String, dynamic> json) {
    return SearchParams(
      query: json['query'] as String?,
      filters: json['filters'] != null 
          ? SearchFilters.fromJson(json['filters'] as Map<String, dynamic>)
          : null,
      limit: json['limit'] as int? ?? 30,
      preferredStrategy: json['preferredStrategy'] != null
          ? SearchStrategy.values.firstWhere(
              (e) => e.name == json['preferredStrategy'],
              orElse: () => SearchStrategy.auto,
            )
          : null,
      useCache: json['useCache'] as bool? ?? true,
      timeout: json['timeout'] != null
          ? Duration(milliseconds: json['timeout'] as int)
          : null,
    );
  }

  /// Verifica se é uma busca vazia
  bool get isEmpty {
    return (query == null || query!.trim().isEmpty) &&
           (filters == null || !filters!.hasActiveFilters);
  }

  /// Verifica se tem query de texto
  bool get hasTextQuery {
    return query != null && query!.trim().isNotEmpty;
  }

  /// Verifica se tem filtros
  bool get hasFilters {
    return filters != null && filters!.hasActiveFilters;
  }

  /// Valida se os parâmetros são válidos
  bool get isValid {
    // Limite deve ser positivo
    if (limit <= 0) return false;
    
    // Query não pode ser apenas espaços
    if (query != null && query!.trim().isEmpty && query!.isNotEmpty) {
      return false;
    }
    
    // Filtros devem ser válidos se existirem
    if (filters != null && !filters!.isValid) {
      return false;
    }
    
    return true;
  }

  /// Gera uma chave única para cache
  String get cacheKey {
    final parts = <String>[];
    
    if (hasTextQuery) {
      parts.add('q:${query!.toLowerCase().trim()}');
    }
    
    if (hasFilters) {
      final f = filters!;
      if (f.minAge != null) parts.add('minAge:${f.minAge}');
      if (f.maxAge != null) parts.add('maxAge:${f.maxAge}');
      if (f.city != null) parts.add('city:${f.city}');
      if (f.state != null) parts.add('state:${f.state}');
      if (f.interests != null && f.interests!.isNotEmpty) {
        parts.add('interests:${f.interests!.join(',')}');
      }
      if (f.isVerified != null) parts.add('verified:${f.isVerified}');
      if (f.hasCompletedCourse != null) parts.add('course:${f.hasCompletedCourse}');
    }
    
    parts.add('limit:$limit');
    
    return parts.join('|');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SearchParams &&
           other.query == query &&
           other.filters == filters &&
           other.limit == limit &&
           other.preferredStrategy == preferredStrategy &&
           other.useCache == useCache &&
           other.timeout == timeout;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      filters,
      limit,
      preferredStrategy,
      useCache,
      timeout,
    );
  }

  @override
  String toString() {
    return 'SearchParams(query: $query, filters: $filters, limit: $limit, '
           'strategy: $preferredStrategy, useCache: $useCache, timeout: $timeout)';
  }
}