import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para notificações
class NotificationData {
  final String id;
  final String toUserId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String type; // 'interest', 'mutual_match', 'message'
  final String message;
  final String status; // 'new', 'pending', 'viewed', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final Map<String, dynamic> metadata;

  const NotificationData({
    required this.id,
    required this.toUserId,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    required this.type,
    required this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.metadata = const {},
  });

  /// Cria instância a partir de JSON
  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] ?? '',
      toUserId: json['toUserId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? 'Usuário',
      fromUserEmail: json['fromUserEmail'] ?? '',
      type: json['type'] ?? 'interest',
      message: json['message'] ?? '',
      status: json['status'] ?? 'new',
      createdAt: _parseTimestamp(json['dataCriacao'] ?? json['createdAt']),
      respondedAt: _parseTimestamp(json['dataResposta'] ?? json['respondedAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'type': type,
      'message': message,
      'status': status,
      'dataCriacao': Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'dataResposta': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'metadata': metadata,
    };
  }

  /// Cria cópia com alterações
  NotificationData copyWith({
    String? id,
    String? toUserId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserEmail,
    String? type,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationData(
      id: id ?? this.id,
      toUserId: toUserId ?? this.toUserId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserEmail: fromUserEmail ?? this.fromUserEmail,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Verifica se é notificação de interesse
  bool get isInterestNotification => type == 'interest';

  /// Verifica se é notificação de match mútuo
  bool get isMutualMatchNotification => type == 'mutual_match';

  /// Verifica se é notificação de mensagem
  bool get isMessageNotification => type == 'message';

  /// Verifica se está pendente de resposta
  bool get isPending => status == 'pending' || status == 'new';

  /// Verifica se foi aceita
  bool get isAccepted => status == 'accepted';

  /// Verifica se foi rejeitada
  bool get isRejected => status == 'rejected';

  /// Verifica se foi visualizada
  bool get isViewed => status == 'viewed';

  /// Verifica se já foi respondida
  bool get isResponded => isAccepted || isRejected;

  /// Obtém o ID do chat se disponível
  String? get chatId => metadata['chatId'];

  /// Obtém o nome do outro usuário
  String get otherUserName => metadata['otherUserName'] ?? fromUserName;

  /// Obtém o ID do outro usuário
  String? get otherUserId => metadata['otherUserId'] ?? fromUserId;

  /// Verifica se a notificação expirou (mais de 30 dias)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays > 30;
  }

  /// Obtém a idade da notificação em texto amigável
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${(difference.inDays / 7).floor()}sem atrás';
    }
  }

  /// Converte Timestamp para DateTime
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() {
    return 'NotificationData(id: $id, type: $type, fromUser: $fromUserName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}