/// Modelo para representar o status de completude do perfil espiritual
class ProfileCompletionStatus {
  final bool isComplete;
  final double completionPercentage;
  final List<String> missingTasks;
  final DateTime? completedAt;
  final bool hasBeenShown; // Flag para evitar mostrar múltiplas vezes

  const ProfileCompletionStatus({
    required this.isComplete,
    required this.completionPercentage,
    required this.missingTasks,
    this.completedAt,
    this.hasBeenShown = false,
  });

  /// Cria uma instância a partir de um perfil espiritual
  factory ProfileCompletionStatus.fromProfile(dynamic profile) {
    if (profile == null) {
      return const ProfileCompletionStatus(
        isComplete: false,
        completionPercentage: 0.0,
        missingTasks: ['profile_not_found'],
      );
    }

    final isComplete = profile.isProfileComplete ?? false;
    final percentage = profile.completionPercentage ?? 0.0;
    final missingTasks = profile.missingRequiredFields ?? <String>[];
    final hasBeenShown = profile.hasBeenShown ?? false;

    return ProfileCompletionStatus(
      isComplete: isComplete,
      completionPercentage: percentage,
      missingTasks: missingTasks,
      completedAt: isComplete ? DateTime.now() : null,
      hasBeenShown: hasBeenShown,
    );
  }

  /// Cria uma cópia com valores atualizados
  ProfileCompletionStatus copyWith({
    bool? isComplete,
    double? completionPercentage,
    List<String>? missingTasks,
    DateTime? completedAt,
    bool? hasBeenShown,
  }) {
    return ProfileCompletionStatus(
      isComplete: isComplete ?? this.isComplete,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      missingTasks: missingTasks ?? this.missingTasks,
      completedAt: completedAt ?? this.completedAt,
      hasBeenShown: hasBeenShown ?? this.hasBeenShown,
    );
  }

  /// Converte para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'isComplete': isComplete,
      'completionPercentage': completionPercentage,
      'missingTasks': missingTasks,
      'completedAt': completedAt?.toIso8601String(),
      'hasBeenShown': hasBeenShown,
    };
  }

  /// Cria instância a partir de Map
  factory ProfileCompletionStatus.fromMap(Map<String, dynamic> map) {
    return ProfileCompletionStatus(
      isComplete: map['isComplete'] ?? false,
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
      missingTasks: List<String>.from(map['missingTasks'] ?? []),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      hasBeenShown: map['hasBeenShown'] ?? false,
    );
  }

  @override
  String toString() {
    return 'ProfileCompletionStatus(isComplete: $isComplete, '
        'percentage: ${(completionPercentage * 100).toInt()}%, '
        'missingTasks: ${missingTasks.length}, '
        'hasBeenShown: $hasBeenShown)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileCompletionStatus &&
        other.isComplete == isComplete &&
        other.completionPercentage == completionPercentage &&
        other.missingTasks.length == missingTasks.length &&
        other.hasBeenShown == hasBeenShown;
  }

  @override
  int get hashCode {
    return isComplete.hashCode ^
        completionPercentage.hashCode ^
        missingTasks.length.hashCode ^
        hasBeenShown.hashCode;
  }
}
