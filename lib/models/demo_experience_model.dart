import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para dados da experiência de demonstração da vitrine
class DemoExperienceData {
  final String userId;
  final DateTime completionTime;
  final bool hasViewedVitrine;
  final bool hasSharedVitrine;
  final int viewCount;
  final List<String> actionsPerformed;

  // Analytics adicionais
  final Duration? timeToFirstView;
  final String? shareMethod;
  final Map<String, dynamic>? engagementMetrics;
  final DateTime? firstViewTime;
  final DateTime? lastShareTime;
  final String? currentStatus;

  const DemoExperienceData({
    required this.userId,
    required this.completionTime,
    required this.hasViewedVitrine,
    required this.hasSharedVitrine,
    required this.viewCount,
    required this.actionsPerformed,
    this.timeToFirstView,
    this.shareMethod,
    this.engagementMetrics,
    this.firstViewTime,
    this.lastShareTime,
    this.currentStatus,
  });

  /// Calcula o tempo até a primeira visualização
  Duration? get calculatedTimeToFirstView {
    if (firstViewTime != null) {
      return firstViewTime!.difference(completionTime);
    }
    return timeToFirstView;
  }

  /// Verifica se o usuário está engajado (visualizou e/ou compartilhou)
  bool get isEngaged => hasViewedVitrine || hasSharedVitrine;

  /// Calcula score de engajamento baseado nas ações
  double get engagementScore {
    double score = 0.0;

    if (hasViewedVitrine) score += 1.0;
    if (hasSharedVitrine) score += 2.0;
    score += (viewCount * 0.5);
    score += (actionsPerformed.length * 0.2);

    return score;
  }

  /// Converte para formato do Firestore
  Map<String, dynamic> toFirestore() {
    final data = {
      'userId': userId,
      'completionTime': Timestamp.fromDate(completionTime),
      'hasViewedVitrine': hasViewedVitrine,
      'hasSharedVitrine': hasSharedVitrine,
      'viewCount': viewCount,
      'actionsPerformed': actionsPerformed,
      'engagementScore': engagementScore,
      'lastUpdated': Timestamp.now(),
    };

    if (timeToFirstView != null) {
      data['timeToFirstViewSeconds'] = timeToFirstView!.inSeconds;
    }

    if (shareMethod != null) {
      data['shareMethod'] = shareMethod!;
    }

    if (engagementMetrics != null) {
      data['engagementMetrics'] = engagementMetrics!;
    }

    if (firstViewTime != null) {
      data['firstViewTime'] = Timestamp.fromDate(firstViewTime!);
    }

    if (lastShareTime != null) {
      data['lastShareTime'] = Timestamp.fromDate(lastShareTime!);
    }

    if (currentStatus != null) {
      data['currentStatus'] = currentStatus!;
    }

    return data;
  }

  /// Cria instância a partir de dados do Firestore
  factory DemoExperienceData.fromFirestore(Map<String, dynamic> data) {
    // Converter timeToFirstView de segundos para Duration
    Duration? timeToFirstView;
    if (data['timeToFirstViewSeconds'] != null) {
      timeToFirstView =
          Duration(seconds: data['timeToFirstViewSeconds'] as int);
    }

    // Converter timestamps para DateTime
    DateTime? firstViewTime;
    if (data['firstViewTime'] != null) {
      firstViewTime = (data['firstViewTime'] as Timestamp).toDate();
    }

    DateTime? lastShareTime;
    if (data['lastShareTime'] != null) {
      lastShareTime = (data['lastShareTime'] as Timestamp).toDate();
    }

    return DemoExperienceData(
      userId: data['userId'] as String,
      completionTime: (data['completionTime'] as Timestamp).toDate(),
      hasViewedVitrine: data['hasViewedVitrine'] as bool? ?? false,
      hasSharedVitrine: data['hasSharedVitrine'] as bool? ?? false,
      viewCount: data['viewCount'] as int? ?? 0,
      actionsPerformed:
          List<String>.from(data['actionsPerformed'] as List? ?? []),
      timeToFirstView: timeToFirstView,
      shareMethod: data['shareMethod'] as String?,
      engagementMetrics: data['engagementMetrics'] as Map<String, dynamic>?,
      firstViewTime: firstViewTime,
      lastShareTime: lastShareTime,
      currentStatus: data['currentStatus'] as String?,
    );
  }

  /// Cria cópia com valores atualizados
  DemoExperienceData copyWith({
    String? userId,
    DateTime? completionTime,
    bool? hasViewedVitrine,
    bool? hasSharedVitrine,
    int? viewCount,
    List<String>? actionsPerformed,
    Duration? timeToFirstView,
    String? shareMethod,
    Map<String, dynamic>? engagementMetrics,
    DateTime? firstViewTime,
    DateTime? lastShareTime,
    String? currentStatus,
  }) {
    return DemoExperienceData(
      userId: userId ?? this.userId,
      completionTime: completionTime ?? this.completionTime,
      hasViewedVitrine: hasViewedVitrine ?? this.hasViewedVitrine,
      hasSharedVitrine: hasSharedVitrine ?? this.hasSharedVitrine,
      viewCount: viewCount ?? this.viewCount,
      actionsPerformed: actionsPerformed ?? this.actionsPerformed,
      timeToFirstView: timeToFirstView ?? this.timeToFirstView,
      shareMethod: shareMethod ?? this.shareMethod,
      engagementMetrics: engagementMetrics ?? this.engagementMetrics,
      firstViewTime: firstViewTime ?? this.firstViewTime,
      lastShareTime: lastShareTime ?? this.lastShareTime,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  /// Adiciona uma nova ação à lista
  DemoExperienceData addAction(String action) {
    final updatedActions = List<String>.from(actionsPerformed);
    if (!updatedActions.contains(action)) {
      updatedActions.add(action);
    }

    return copyWith(actionsPerformed: updatedActions);
  }

  /// Incrementa o contador de visualizações
  DemoExperienceData incrementViewCount() {
    return copyWith(viewCount: viewCount + 1);
  }

  @override
  String toString() {
    return 'DemoExperienceData('
        'userId: $userId, '
        'hasViewedVitrine: $hasViewedVitrine, '
        'hasSharedVitrine: $hasSharedVitrine, '
        'viewCount: $viewCount, '
        'engagementScore: ${engagementScore.toStringAsFixed(1)}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DemoExperienceData &&
        other.userId == userId &&
        other.completionTime == completionTime &&
        other.hasViewedVitrine == hasViewedVitrine &&
        other.hasSharedVitrine == hasSharedVitrine &&
        other.viewCount == viewCount;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        completionTime.hashCode ^
        hasViewedVitrine.hashCode ^
        hasSharedVitrine.hashCode ^
        viewCount.hashCode;
  }
}
