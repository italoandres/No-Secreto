import 'package:flutter/material.dart';

/// Níveis de compatibilidade de match
enum MatchLevel {
  excellent,  // 80-100%
  good,       // 60-79%
  moderate,   // 40-59%
  low,        // 0-39%
}

extension MatchLevelExtension on MatchLevel {
  /// Retorna a cor associada ao nível de match
  Color get color {
    switch (this) {
      case MatchLevel.excellent:
        return Colors.green;
      case MatchLevel.good:
        return Colors.blue;
      case MatchLevel.moderate:
        return Colors.orange;
      case MatchLevel.low:
        return Colors.grey;
    }
  }

  /// Retorna o label em português para o nível
  String get label {
    switch (this) {
      case MatchLevel.excellent:
        return 'Excelente Match';
      case MatchLevel.good:
        return 'Bom Match';
      case MatchLevel.moderate:
        return 'Match Moderado';
      case MatchLevel.low:
        return 'Match Baixo';
    }
  }

  /// Retorna o ícone associado ao nível
  IconData get icon {
    switch (this) {
      case MatchLevel.excellent:
        return Icons.favorite;
      case MatchLevel.good:
        return Icons.thumb_up;
      case MatchLevel.moderate:
        return Icons.star_half;
      case MatchLevel.low:
        return Icons.star_border;
    }
  }

  /// Converte para string para serialização
  String toJson() => name;

  /// Cria MatchLevel a partir de string
  static MatchLevel fromJson(String json) {
    return MatchLevel.values.firstWhere(
      (level) => level.name == json,
      orElse: () => MatchLevel.low,
    );
  }

  /// Determina o nível baseado na pontuação
  static MatchLevel fromScore(double score) {
    if (score >= 80) return MatchLevel.excellent;
    if (score >= 60) return MatchLevel.good;
    if (score >= 40) return MatchLevel.moderate;
    return MatchLevel.low;
  }
}
