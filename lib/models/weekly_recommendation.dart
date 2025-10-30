import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para recomendações semanais de perfis
class WeeklyRecommendation {
  /// ID do usuário que recebe as recomendações
  final String userId;

  /// Chave da semana (formato: "2025-W42")
  final String weekKey;

  /// IDs dos perfis recomendados (máximo 6)
  final List<String> profileIds;

  /// Data de geração das recomendações
  final DateTime generatedAt;

  /// IDs dos perfis já visualizados
  final List<String> viewedProfiles;

  /// IDs dos perfis que o usuário passou (não interessou)
  final List<String> passedProfiles;

  /// IDs dos perfis que o usuário demonstrou interesse
  final List<String> interestedProfiles;

  WeeklyRecommendation({
    required this.userId,
    required this.weekKey,
    required this.profileIds,
    required this.generatedAt,
    this.viewedProfiles = const [],
    this.passedProfiles = const [],
    this.interestedProfiles = const [],
  });

  /// Quantidade de perfis restantes para visualizar
  int get remainingProfiles {
    return profileIds.length - viewedProfiles.length;
  }

  /// Se todas as recomendações foram visualizadas
  bool get allViewed {
    return viewedProfiles.length >= profileIds.length;
  }

  /// Próximo perfil a ser exibido (null se todos foram visualizados)
  String? get nextProfile {
    for (final profileId in profileIds) {
      if (!viewedProfiles.contains(profileId)) {
        return profileId;
      }
    }
    return null;
  }

  /// Cria WeeklyRecommendation a partir de documento Firestore
  factory WeeklyRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyRecommendation(
      userId: data['userId'] as String,
      weekKey: data['weekKey'] as String,
      profileIds: List<String>.from(data['profileIds'] ?? []),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      viewedProfiles: List<String>.from(data['viewedProfiles'] ?? []),
      passedProfiles: List<String>.from(data['passedProfiles'] ?? []),
      interestedProfiles: List<String>.from(data['interestedProfiles'] ?? []),
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weekKey': weekKey,
      'profileIds': profileIds,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'viewedProfiles': viewedProfiles,
      'passedProfiles': passedProfiles,
      'interestedProfiles': interestedProfiles,
    };
  }

  /// Cria uma cópia com valores modificados
  WeeklyRecommendation copyWith({
    String? userId,
    String? weekKey,
    List<String>? profileIds,
    DateTime? generatedAt,
    List<String>? viewedProfiles,
    List<String>? passedProfiles,
    List<String>? interestedProfiles,
  }) {
    return WeeklyRecommendation(
      userId: userId ?? this.userId,
      weekKey: weekKey ?? this.weekKey,
      profileIds: profileIds ?? this.profileIds,
      generatedAt: generatedAt ?? this.generatedAt,
      viewedProfiles: viewedProfiles ?? this.viewedProfiles,
      passedProfiles: passedProfiles ?? this.passedProfiles,
      interestedProfiles: interestedProfiles ?? this.interestedProfiles,
    );
  }

  /// Marca um perfil como visualizado
  WeeklyRecommendation markAsViewed(String profileId) {
    if (viewedProfiles.contains(profileId)) {
      return this;
    }
    return copyWith(
      viewedProfiles: [...viewedProfiles, profileId],
    );
  }

  /// Marca um perfil como passado
  WeeklyRecommendation markAsPassed(String profileId) {
    if (passedProfiles.contains(profileId)) {
      return this;
    }
    return copyWith(
      passedProfiles: [...passedProfiles, profileId],
      viewedProfiles: viewedProfiles.contains(profileId)
          ? viewedProfiles
          : [...viewedProfiles, profileId],
    );
  }

  /// Marca um perfil como interessado
  WeeklyRecommendation markAsInterested(String profileId) {
    if (interestedProfiles.contains(profileId)) {
      return this;
    }
    return copyWith(
      interestedProfiles: [...interestedProfiles, profileId],
      viewedProfiles: viewedProfiles.contains(profileId)
          ? viewedProfiles
          : [...viewedProfiles, profileId],
    );
  }

  @override
  String toString() {
    return 'WeeklyRecommendation(userId: $userId, weekKey: $weekKey, profiles: ${profileIds.length}, remaining: $remainingProfiles)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeeklyRecommendation &&
        other.userId == userId &&
        other.weekKey == weekKey;
  }

  @override
  int get hashCode => userId.hashCode ^ weekKey.hashCode;
}
