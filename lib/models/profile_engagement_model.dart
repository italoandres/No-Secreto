import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para métricas de engajamento do perfil
class ProfileEngagementModel {
  final String userId;
  final int storyCommentsCount;
  final int storyLikesCount;
  final int totalScreenTime; // em minutos
  final DateTime lastActivity;
  final double engagementScore;
  final bool hasCompletedSinaisCourse;
  final bool isVerified;
  final List<String> completedCourses;
  final Map<String, dynamic> interactionMetrics;

  ProfileEngagementModel({
    required this.userId,
    this.storyCommentsCount = 0,
    this.storyLikesCount = 0,
    this.totalScreenTime = 0,
    required this.lastActivity,
    this.engagementScore = 0.0,
    this.hasCompletedSinaisCourse = false,
    this.isVerified = false,
    this.completedCourses = const [],
    this.interactionMetrics = const {},
  });

  /// Calcula score de engajamento baseado nas métricas
  double calculateEngagementScore() {
    double score = 0.0;

    // Peso para comentários em stories (40%)
    score += (storyCommentsCount * 2.0) * 0.4;

    // Peso para likes em stories (20%)
    score += (storyLikesCount * 1.0) * 0.2;

    // Peso para tempo de tela (30%)
    score += (totalScreenTime / 60.0) * 0.3; // Convertendo para horas

    // Peso para curso Sinais (10%)
    if (hasCompletedSinaisCourse) {
      score += 50.0 * 0.1;
    }

    // Bonus para verificação
    if (isVerified) {
      score *= 1.2;
    }

    return score;
  }

  /// Verifica se o perfil é elegível para aparecer na exploração
  bool get isEligibleForExploration {
    return isVerified && hasCompletedSinaisCourse && engagementScore > 10.0;
  }

  /// Prioridade do perfil (maior = mais prioritário)
  int get priority {
    if (!isEligibleForExploration) return 0;

    int basePriority = 1;

    // Prioridade por engajamento
    if (engagementScore > 100)
      basePriority += 5;
    else if (engagementScore > 50)
      basePriority += 3;
    else if (engagementScore > 25)
      basePriority += 2;
    else if (engagementScore > 10) basePriority += 1;

    // Prioridade por atividade recente
    final daysSinceLastActivity =
        DateTime.now().difference(lastActivity).inDays;
    if (daysSinceLastActivity <= 1)
      basePriority += 3;
    else if (daysSinceLastActivity <= 7)
      basePriority += 2;
    else if (daysSinceLastActivity <= 30) basePriority += 1;

    // Prioridade por cursos completados
    basePriority += completedCourses.length;

    return basePriority;
  }

  factory ProfileEngagementModel.fromJson(Map<String, dynamic> json) {
    return ProfileEngagementModel(
      userId: json['userId'] ?? '',
      storyCommentsCount: json['storyCommentsCount'] ?? 0,
      storyLikesCount: json['storyLikesCount'] ?? 0,
      totalScreenTime: json['totalScreenTime'] ?? 0,
      lastActivity:
          (json['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      engagementScore: (json['engagementScore'] ?? 0.0).toDouble(),
      hasCompletedSinaisCourse: json['hasCompletedSinaisCourse'] ?? false,
      isVerified: json['isVerified'] ?? false,
      completedCourses: List<String>.from(json['completedCourses'] ?? []),
      interactionMetrics:
          Map<String, dynamic>.from(json['interactionMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'storyCommentsCount': storyCommentsCount,
      'storyLikesCount': storyLikesCount,
      'totalScreenTime': totalScreenTime,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'engagementScore': engagementScore,
      'hasCompletedSinaisCourse': hasCompletedSinaisCourse,
      'isVerified': isVerified,
      'completedCourses': completedCourses,
      'interactionMetrics': interactionMetrics,
    };
  }

  ProfileEngagementModel copyWith({
    String? userId,
    int? storyCommentsCount,
    int? storyLikesCount,
    int? totalScreenTime,
    DateTime? lastActivity,
    double? engagementScore,
    bool? hasCompletedSinaisCourse,
    bool? isVerified,
    List<String>? completedCourses,
    Map<String, dynamic>? interactionMetrics,
  }) {
    return ProfileEngagementModel(
      userId: userId ?? this.userId,
      storyCommentsCount: storyCommentsCount ?? this.storyCommentsCount,
      storyLikesCount: storyLikesCount ?? this.storyLikesCount,
      totalScreenTime: totalScreenTime ?? this.totalScreenTime,
      lastActivity: lastActivity ?? this.lastActivity,
      engagementScore: engagementScore ?? this.engagementScore,
      hasCompletedSinaisCourse:
          hasCompletedSinaisCourse ?? this.hasCompletedSinaisCourse,
      isVerified: isVerified ?? this.isVerified,
      completedCourses: completedCourses ?? this.completedCourses,
      interactionMetrics: interactionMetrics ?? this.interactionMetrics,
    );
  }
}
