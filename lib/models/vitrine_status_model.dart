import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum para representar os diferentes status da vitrine
enum VitrineStatus { active, inactive, pending, suspended }

/// Extensão para conversão de string para enum
extension VitrineStatusExtension on VitrineStatus {
  String get value {
    switch (this) {
      case VitrineStatus.active:
        return 'active';
      case VitrineStatus.inactive:
        return 'inactive';
      case VitrineStatus.pending:
        return 'pending';
      case VitrineStatus.suspended:
        return 'suspended';
    }
  }

  static VitrineStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return VitrineStatus.active;
      case 'inactive':
        return VitrineStatus.inactive;
      case 'pending':
        return VitrineStatus.pending;
      case 'suspended':
        return VitrineStatus.suspended;
      default:
        return VitrineStatus.active; // Padrão seguro
    }
  }
}

/// Modelo para informações de status da vitrine
class VitrineStatusInfo {
  final String userId;
  final VitrineStatus status;
  final DateTime lastUpdated;
  final String? reason;
  final Map<String, dynamic>? metadata;

  const VitrineStatusInfo({
    required this.userId,
    required this.status,
    required this.lastUpdated,
    this.reason,
    this.metadata,
  });

  /// Verifica se a vitrine está publicamente visível
  bool get isPubliclyVisible => status == VitrineStatus.active;

  /// Verifica se a vitrine pode ser compartilhada
  bool get canBeShared => status == VitrineStatus.active;

  /// Verifica se o status permite edição
  bool get canBeEdited => status != VitrineStatus.suspended;

  /// Converte para formato do Firestore
  Map<String, dynamic> toFirestore() {
    final data = {
      'userId': userId,
      'status': status.value,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };

    if (reason != null) {
      data['reason'] = reason!;
    }

    if (metadata != null) {
      data['metadata'] = metadata!;
    }

    return data;
  }

  /// Cria instância a partir de dados do Firestore
  factory VitrineStatusInfo.fromFirestore(Map<String, dynamic> data) {
    return VitrineStatusInfo(
      userId: data['userId'] as String,
      status: VitrineStatusExtension.fromString(data['status'] as String),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      reason: data['reason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Cria cópia com valores atualizados
  VitrineStatusInfo copyWith({
    String? userId,
    VitrineStatus? status,
    DateTime? lastUpdated,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    return VitrineStatusInfo(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'VitrineStatusInfo('
        'userId: $userId, '
        'status: ${status.value}, '
        'lastUpdated: $lastUpdated, '
        'reason: $reason'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VitrineStatusInfo &&
        other.userId == userId &&
        other.status == status &&
        other.lastUpdated == lastUpdated &&
        other.reason == reason;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        status.hashCode ^
        lastUpdated.hashCode ^
        reason.hashCode;
  }
}
