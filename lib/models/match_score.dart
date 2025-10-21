import 'package:flutter/material.dart';
import 'match_level.dart';

/// Pontuação de compatibilidade de um perfil
class MatchScore {
  /// Pontuação total normalizada (0-100)
  final double totalScore;

  /// Nível de match baseado na pontuação
  final MatchLevel level;

  /// Breakdown detalhado da pontuação por critério
  final Map<String, double> breakdown;

  MatchScore({
    required this.totalScore,
    required this.level,
    required this.breakdown,
  });

  /// Cor do badge baseada no nível
  Color get badgeColor => level.color;

  /// Label do match baseado no nível
  String get label => level.label;

  /// Ícone do match baseado no nível
  IconData get icon => level.icon;

  /// Pontuação formatada como porcentagem
  String get formattedScore => '${totalScore.toStringAsFixed(0)}%';

  /// Verifica se é um excelente match
  bool get isExcellent => level == MatchLevel.excellent;

  /// Verifica se é um bom match ou melhor
  bool get isGoodOrBetter =>
      level == MatchLevel.excellent || level == MatchLevel.good;

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'totalScore': totalScore,
      'level': level.toJson(),
      'breakdown': breakdown,
    };
  }

  /// Cria MatchScore a partir de JSON
  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      totalScore: (json['totalScore'] as num).toDouble(),
      level: MatchLevelExtension.fromJson(json['level'] as String),
      breakdown: Map<String, double>.from(json['breakdown'] as Map),
    );
  }

  /// Cria uma cópia com valores modificados
  MatchScore copyWith({
    double? totalScore,
    MatchLevel? level,
    Map<String, double>? breakdown,
  }) {
    return MatchScore(
      totalScore: totalScore ?? this.totalScore,
      level: level ?? this.level,
      breakdown: breakdown ?? this.breakdown,
    );
  }

  @override
  String toString() {
    return 'MatchScore(totalScore: $totalScore, level: $level, breakdown: $breakdown)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchScore &&
        other.totalScore == totalScore &&
        other.level == level &&
        _mapsEqual(other.breakdown, breakdown);
  }

  @override
  int get hashCode => totalScore.hashCode ^ level.hashCode ^ breakdown.hashCode;

  bool _mapsEqual(Map<String, double> map1, Map<String, double> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }
}
