/// Status de resposta a um interesse
enum InterestStatus {
  /// Interesse aceito - cria chat
  accepted,
  
  /// Interesse rejeitado
  rejected,
  
  /// Interesse pendente (ainda não respondido)
  pending,
  
  /// Notificação apenas visualizada
  viewed,
}

/// Extensão para converter enum para string
extension InterestStatusExtension on InterestStatus {
  String get value {
    switch (this) {
      case InterestStatus.accepted:
        return 'accepted';
      case InterestStatus.rejected:
        return 'rejected';
      case InterestStatus.pending:
        return 'pending';
      case InterestStatus.viewed:
        return 'viewed';
    }
  }
  
  /// Criar enum a partir de string
  static InterestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return InterestStatus.accepted;
      case 'rejected':
        return InterestStatus.rejected;
      case 'pending':
        return InterestStatus.pending;
      case 'viewed':
        return InterestStatus.viewed;
      default:
        return InterestStatus.pending;
    }
  }
}