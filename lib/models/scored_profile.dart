import 'match_score.dart';

/// Perfil de usuário com pontuação de compatibilidade
class ScoredProfile {
  /// ID do usuário
  final String userId;

  /// Dados do perfil
  final Map<String, dynamic> profileData;

  /// Pontuação de compatibilidade
  final MatchScore score;

  /// Distância em quilômetros
  final double distance;

  ScoredProfile({
    required this.userId,
    required this.profileData,
    required this.score,
    required this.distance,
  });

  /// Nome do usuário
  String get name => profileData['name'] as String? ?? 'Usuário';

  /// Idade do usuário
  int get age => profileData['age'] as int? ?? 0;

  /// URL da foto principal
  String? get photoUrl => profileData['photoUrl'] as String?;

  /// Altura em cm
  int get height => profileData['height'] as int? ?? 0;

  /// Educação
  String? get education => profileData['education'] as String?;

  /// Idiomas
  List<String> get languages {
    final langs = profileData['languages'];
    if (langs is List) {
      return langs.cast<String>();
    }
    return [];
  }

  /// Filhos
  String? get children => profileData['children'] as String?;

  /// Beber
  String? get drinking => profileData['drinking'] as String?;

  /// Fumar
  String? get smoking => profileData['smoking'] as String?;

  /// Bio/descrição
  String? get bio => profileData['bio'] as String?;

  /// Propósito (o que busca no app)
  String? get purpose => profileData['purpose'] as String?;

  /// Certificação espiritual
  bool get hasCertification => profileData['hasCertification'] as bool? ?? false;

  /// Membro do movimento Deus é Pai
  bool get isDeusEPaiMember => profileData['isDeusEPaiMember'] as bool? ?? false;

  /// Status de virgindade
  String? get virginityStatus => profileData['virginityStatus'] as String?;

  /// Hobbies do perfil
  List<String> get hobbies {
    final hobs = profileData['hobbies'];
    if (hobs is List) {
      return hobs.cast<String>();
    }
    return [];
  }

  /// Lista de URLs de fotos
  List<String> get photos {
    final pics = profileData['photos'];
    if (pics is List) {
      return pics.cast<String>();
    }
    // Fallback para foto principal se não houver galeria
    if (photoUrl != null) {
      return [photoUrl!];
    }
    return [];
  }

  /// Cidade
  String? get city => profileData['city'] as String?;

  /// Estado
  String? get state => profileData['state'] as String?;

  /// Localização formatada
  String get formattedLocation {
    if (city != null && state != null) {
      return '$city, $state';
    }
    if (city != null) return city!;
    if (state != null) return state!;
    return 'Localização não informada';
  }

  /// Número de hobbies em comum (será calculado pelo serviço)
  int get commonHobbies => profileData['commonHobbies'] as int? ?? 0;

  /// Se corresponde à preferência de virgindade (será calculado pelo serviço)
  bool get matchesVirginityPreference => profileData['matchesVirginityPreference'] as bool? ?? false;

  /// Distância formatada
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  /// Serializa para JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileData': profileData,
      'score': score.toJson(),
      'distance': distance,
    };
  }

  /// Cria ScoredProfile a partir de JSON
  factory ScoredProfile.fromJson(Map<String, dynamic> json) {
    return ScoredProfile(
      userId: json['userId'] as String,
      profileData: Map<String, dynamic>.from(json['profileData'] as Map),
      score: MatchScore.fromJson(json['score'] as Map<String, dynamic>),
      distance: (json['distance'] as num).toDouble(),
    );
  }

  /// Cria uma cópia com valores modificados
  ScoredProfile copyWith({
    String? userId,
    Map<String, dynamic>? profileData,
    MatchScore? score,
    double? distance,
  }) {
    return ScoredProfile(
      userId: userId ?? this.userId,
      profileData: profileData ?? this.profileData,
      score: score ?? this.score,
      distance: distance ?? this.distance,
    );
  }

  @override
  String toString() {
    return 'ScoredProfile(userId: $userId, name: $name, score: ${score.totalScore}, distance: ${distance}km)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScoredProfile &&
        other.userId == userId &&
        other.score == score &&
        other.distance == distance;
  }

  @override
  int get hashCode => userId.hashCode ^ score.hashCode ^ distance.hashCode;
}
