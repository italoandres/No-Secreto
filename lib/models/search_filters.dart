/// Modelo para filtros de busca de perfis
class SearchFilters {
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? state;
  final List<String>? interests;
  final bool? isVerified;
  final bool? hasCompletedCourse;

  const SearchFilters({
    this.minAge,
    this.maxAge,
    this.city,
    this.state,
    this.interests,
    this.isVerified,
    this.hasCompletedCourse,
  });

  /// Cria uma cópia com novos valores
  SearchFilters copyWith({
    int? minAge,
    int? maxAge,
    String? city,
    String? state,
    List<String>? interests,
    bool? isVerified,
    bool? hasCompletedCourse,
  }) {
    return SearchFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      city: city ?? this.city,
      state: state ?? this.state,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
      hasCompletedCourse: hasCompletedCourse ?? this.hasCompletedCourse,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'city': city,
      'state': state,
      'interests': interests,
      'isVerified': isVerified,
      'hasCompletedCourse': hasCompletedCourse,
    };
  }

  /// Cria a partir de JSON
  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      minAge: json['minAge'] as int?,
      maxAge: json['maxAge'] as int?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      isVerified: json['isVerified'] as bool?,
      hasCompletedCourse: json['hasCompletedCourse'] as bool?,
    );
  }

  /// Verifica se tem filtros ativos
  bool get hasActiveFilters {
    return minAge != null ||
        maxAge != null ||
        (city != null && city!.isNotEmpty) ||
        (state != null && state!.isNotEmpty) ||
        (interests != null && interests!.isNotEmpty) ||
        isVerified != null ||
        hasCompletedCourse != null;
  }

  /// Valida se os filtros são válidos
  bool get isValid {
    // Idade mínima não pode ser maior que máxima
    if (minAge != null && maxAge != null && minAge! > maxAge!) {
      return false;
    }

    // Idades devem ser positivas
    if (minAge != null && minAge! < 0) return false;
    if (maxAge != null && maxAge! < 0) return false;

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchFilters &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.city == city &&
        other.state == state &&
        _listEquals(other.interests, interests) &&
        other.isVerified == isVerified &&
        other.hasCompletedCourse == hasCompletedCourse;
  }

  @override
  int get hashCode {
    return Object.hash(
      minAge,
      maxAge,
      city,
      state,
      interests,
      isVerified,
      hasCompletedCourse,
    );
  }

  @override
  String toString() {
    return 'SearchFilters(minAge: $minAge, maxAge: $maxAge, city: $city, '
        'state: $state, interests: $interests, isVerified: $isVerified, '
        'hasCompletedCourse: $hasCompletedCourse)';
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
