import '../models/spiritual_profile_model.dart';

/// Estratégias de busca disponíveis
enum SearchStrategy {
  auto,
  firebase,
  cache,
  fallback,
  hybrid,
}

/// Resultado de uma busca de perfis
class SearchResult {
  final List<SpiritualProfileModel> profiles;
  final int totalFound;
  final String strategy;
  final int executionTime;
  final bool fromCache;
  final String? error;
  final Map<String, dynamic>? metadata;

  const SearchResult({
    required this.profiles,
    required this.totalFound,
    required this.strategy,
    required this.executionTime,
    this.fromCache = false,
    this.error,
    this.metadata,
  });

  /// Cria um resultado de sucesso
  factory SearchResult.success({
    required List<SpiritualProfileModel> profiles,
    required String strategy,
    required int executionTime,
    bool fromCache = false,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      profiles: profiles,
      totalFound: profiles.length,
      strategy: strategy,
      executionTime: executionTime,
      fromCache: fromCache,
      metadata: metadata,
    );
  }

  /// Cria um resultado de erro
  factory SearchResult.error({
    required String error,
    required String strategy,
    required int executionTime,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      profiles: const [],
      totalFound: 0,
      strategy: strategy,
      executionTime: executionTime,
      error: error,
      metadata: metadata,
    );
  }

  /// Cria um resultado vazio
  factory SearchResult.empty({
    required String strategy,
    required int executionTime,
    bool fromCache = false,
  }) {
    return SearchResult(
      profiles: const [],
      totalFound: 0,
      strategy: strategy,
      executionTime: executionTime,
      fromCache: fromCache,
    );
  }

  /// Verifica se a busca foi bem-sucedida
  bool get isSuccess => error == null;

  /// Verifica se tem resultados
  bool get hasResults => profiles.isNotEmpty;

  /// Verifica se a busca foi rápida (menos de 1 segundo)
  bool get isFast => executionTime < 1000;

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'totalFound': totalFound,
      'strategy': strategy,
      'executionTime': executionTime,
      'fromCache': fromCache,
      'error': error,
      'metadata': metadata,
    };
  }

  /// Cria a partir de JSON
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      profiles: (json['profiles'] as List<dynamic>?)
              ?.map((p) =>
                  SpiritualProfileModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalFound: json['totalFound'] as int? ?? 0,
      strategy: json['strategy'] as String? ?? 'auto',
      executionTime: json['executionTime'] as int? ?? 0,
      fromCache: json['fromCache'] as bool? ?? false,
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Cria uma cópia com novos valores
  SearchResult copyWith({
    List<SpiritualProfileModel>? profiles,
    int? totalFound,
    String? strategy,
    int? executionTime,
    bool? fromCache,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      profiles: profiles ?? this.profiles,
      totalFound: totalFound ?? this.totalFound,
      strategy: strategy ?? this.strategy,
      executionTime: executionTime ?? this.executionTime,
      fromCache: fromCache ?? this.fromCache,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Combina com outro resultado
  SearchResult merge(SearchResult other) {
    final allProfiles = <SpiritualProfileModel>[...profiles];

    // Adiciona perfis que não estão duplicados
    for (final profile in other.profiles) {
      if (!allProfiles.any((p) => p.id == profile.id)) {
        allProfiles.add(profile);
      }
    }

    return SearchResult(
      profiles: allProfiles,
      totalFound: allProfiles.length,
      strategy: strategy, // Mantém a estratégia original
      executionTime: executionTime + other.executionTime,
      fromCache: fromCache && other.fromCache,
      metadata: {
        ...?metadata,
        ...?other.metadata,
        'merged': true,
        'originalCount': profiles.length,
        'mergedCount': other.profiles.length,
      },
    );
  }

  /// Filtra os resultados
  SearchResult filter(bool Function(SpiritualProfileModel) predicate) {
    final filteredProfiles = profiles.where(predicate).toList();

    return copyWith(
      profiles: filteredProfiles,
      totalFound: filteredProfiles.length,
      metadata: {
        ...?metadata,
        'filtered': true,
        'originalCount': profiles.length,
        'filteredCount': filteredProfiles.length,
      },
    );
  }

  /// Limita o número de resultados
  SearchResult limit(int maxResults) {
    if (profiles.length <= maxResults) return this;

    return copyWith(
      profiles: profiles.take(maxResults).toList(),
      metadata: {
        ...?metadata,
        'limited': true,
        'originalCount': profiles.length,
        'limitedTo': maxResults,
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchResult &&
        _listEquals(other.profiles, profiles) &&
        other.totalFound == totalFound &&
        other.strategy == strategy &&
        other.executionTime == executionTime &&
        other.fromCache == fromCache &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      profiles,
      totalFound,
      strategy,
      executionTime,
      fromCache,
      error,
    );
  }

  @override
  String toString() {
    return 'SearchResult(profiles: ${profiles.length}, totalFound: $totalFound, '
        'strategy: $strategy, time: ${executionTime}ms, '
        'fromCache: $fromCache, error: $error)';
  }
}

/// Função auxiliar para comparar listas
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
