import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;           // Destinatário da notificação
  final String type;             // 'story_comment' ou 'interest'
  final String relatedId;        // ID do story
  final String fromUserId;       // Usuário que gerou a notificação
  final String fromUserName;     // Nome do usuário
  final String fromUserAvatar;   // Avatar do usuário
  final String content;          // Conteúdo da notificação
  final bool isRead;             // Status de lida
  final DateTime timestamp;      // Data de criação (padronizado como timestamp)
  final String? contexto;        // Contexto da notificação (nosso_proposito, sinais_isaque, etc.)
  
  // Campos adicionais para compatibilidade
  final String? title;           // Título da notificação
  final String? message;         // Mensagem da notificação
  final Map<String, dynamic>? data; // Dados adicionais

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.relatedId = '',
    this.fromUserId = '',
    this.fromUserName = '',
    this.fromUserAvatar = '',
    this.content = '',
    required this.isRead,
    required this.timestamp,
    this.contexto,
    this.title,
    this.message,
    this.data,
  });

  // Getter para compatibilidade com código antigo
  DateTime get createdAt => timestamp;

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'relatedId': relatedId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserAvatar': fromUserAvatar,
      'content': content,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'contexto': contexto,
    };
  }

  // Criar instância a partir de Map do Firestore
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      relatedId: map['relatedId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      fromUserAvatar: map['fromUserAvatar'] ?? '',
      content: map['content'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: (map['createdAt'] as Timestamp).toDate(),
      contexto: map['contexto'],
    );
  }

  // Criar instância a partir de DocumentSnapshot
  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  // Criar cópia com campos modificados
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? relatedId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserAvatar,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    String? contexto,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      timestamp: createdAt ?? this.timestamp,
      contexto: contexto ?? this.contexto,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, type: $type, fromUserName: $fromUserName, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}