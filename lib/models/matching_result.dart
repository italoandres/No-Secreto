import 'package:cloud_firestore/cloud_firestore.dart';
import 'scored_profile.dart';

/// Resultado de uma busca de matching
class MatchingResult {
  /// Lista de perfis com pontuação
  final List<ScoredProfile> profiles;

  /// Número total de perfis encontrados
  final int totalCount;

  /// Número de perfis com match excelente (80+)
  final int excellentMatchCount;

  /// Último documento para paginação
  final DocumentSnapshot? lastDocument;

  /// Timestamp da busca
  final DateTime timestamp;

  MatchingResult({
    required this.profiles,
    required this.totalCount,
    required this.excellentMatchCount,
    this.lastDocument,
    required this.timestamp,
  });

  /// Verifica se há mais perfis para carregar
  bool get hasMore => lastDocument != null;

  /// Verifica se não encontrou nenhum perfil
  bool get isEmpty => profiles.isEmpty;

  /// Verifica se encontrou perfis
  bool get isNotEmpty => profiles.isNotEmpty;

  /// Número de perfis bons ou melhores (60+)
  int get goodOrBetterCount {
    return profiles.where((p) => p.score.isGoodOrBetter).length;
  }

  /// Pontuação média dos perfis
  double get averageScore {
    if (profiles.isEmpty) return 0;
    final sum = profiles.fold<double>(
      0,
      (sum, profile) => sum + profile.score.totalScore,
    );
    return sum / profiles.length;
  }

  /// Distância média dos perfis
  double get averageDistance {
    if (profiles.isEmpty) return 0;
    final sum = profiles.fold<double>(
      0,
      (sum, profile) => sum + profile.distance,
    );
    return sum / profiles.length;
  }

  /// Serializa para JSON (sem lastDocument pois não é serializável)
  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'totalCount': totalCount,
      'excellentMatchCount': excellentMatchCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Cria MatchingResult a partir de JSON
  factory MatchingResult.fromJson(Map<String, dynamic> json) {
    return MatchingResult(
      profiles: (json['profiles'] as List)
          .map((p) => ScoredProfile.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      excellentMatchCount: json['excellentMatchCount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Cria uma cópia com valores modificados
  MatchingResult copyWith({
    List<ScoredProfile>? profiles,
    int? totalCount,
    int? excellentMatchCount,
    DocumentSnapshot? lastDocument,
    DateTime? timestamp,
  }) {
    return MatchingResult(
      profiles: profiles ?? this.profiles,
      totalCount: totalCount ?? this.totalCount,
      excellentMatchCount: excellentMatchCount ?? this.excellentMatchCount,
      lastDocument: lastDocument ?? this.lastDocument,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Cria resultado vazio
  factory MatchingResult.empty() {
    return MatchingResult(
      profiles: [],
      totalCount: 0,
      excellentMatchCount: 0,
      timestamp: DateTime.now(),
    );
  }

  /// Combina com outro resultado (para paginação)
  MatchingResult merge(MatchingResult other) {
    return MatchingResult(
      profiles: [...profiles, ...other.profiles],
      totalCount: totalCount + other.totalCount,
      excellentMatchCount: excellentMatchCount + other.excellentMatchCount,
      lastDocument: other.lastDocument,
      timestamp: timestamp,
    );
  }

  @override
  String toString() {
    return 'MatchingResult(profiles: ${profiles.length}, totalCount: $totalCount, excellentMatchCount: $excellentMatchCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchingResult &&
        other.totalCount == totalCount &&
        other.excellentMatchCount == excellentMatchCount &&
        other.profiles.length == profiles.length;
  }

  @override
  int get hashCode =>
      totalCount.hashCode ^
      excellentMatchCount.hashCode ^
      profiles.length.hashCode;
}
