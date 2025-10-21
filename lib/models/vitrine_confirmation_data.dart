/// Modelo para dados da tela de confirmação da vitrine
class VitrineConfirmationData {
  final String userId;
  final String userName;
  final String? userPhoto;
  final DateTime completedAt;
  final bool canShowVitrine;
  final String? profileId;
  
  const VitrineConfirmationData({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.completedAt,
    required this.canShowVitrine,
    this.profileId,
  });

  /// Cria instância a partir de dados do usuário e perfil
  factory VitrineConfirmationData.fromUserAndProfile({
    required String userId,
    required String userName,
    String? userPhoto,
    String? profileId,
    bool canShowVitrine = true,
  }) {
    return VitrineConfirmationData(
      userId: userId,
      userName: userName,
      userPhoto: userPhoto,
      completedAt: DateTime.now(),
      canShowVitrine: canShowVitrine,
      profileId: profileId,
    );
  }

  /// Cria uma cópia com valores atualizados
  VitrineConfirmationData copyWith({
    String? userId,
    String? userName,
    String? userPhoto,
    DateTime? completedAt,
    bool? canShowVitrine,
    String? profileId,
  }) {
    return VitrineConfirmationData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      completedAt: completedAt ?? this.completedAt,
      canShowVitrine: canShowVitrine ?? this.canShowVitrine,
      profileId: profileId ?? this.profileId,
    );
  }

  /// Converte para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'completedAt': completedAt.toIso8601String(),
      'canShowVitrine': canShowVitrine,
      'profileId': profileId,
    };
  }

  /// Cria instância a partir de Map
  factory VitrineConfirmationData.fromMap(Map<String, dynamic> map) {
    return VitrineConfirmationData(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'],
      completedAt: DateTime.parse(map['completedAt']),
      canShowVitrine: map['canShowVitrine'] ?? false,
      profileId: map['profileId'],
    );
  }

  @override
  String toString() {
    return 'VitrineConfirmationData(userId: $userId, '
           'userName: $userName, '
           'canShowVitrine: $canShowVitrine, '
           'profileId: $profileId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VitrineConfirmationData &&
      other.userId == userId &&
      other.userName == userName &&
      other.userPhoto == userPhoto &&
      other.canShowVitrine == canShowVitrine &&
      other.profileId == profileId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
      userName.hashCode ^
      userPhoto.hashCode ^
      canShowVitrine.hashCode ^
      profileId.hashCode;
  }
}