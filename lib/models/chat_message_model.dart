import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de mensagem suportados
enum MessageType {
  text,
  image,
  system,
}

/// Extensão para MessageType
extension MessageTypeExtension on MessageType {
  String get name {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.system:
        return 'system';
    }
  }

  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Texto';
      case MessageType.image:
        return 'Imagem';
      case MessageType.system:
        return 'Sistema';
    }
  }

  bool get isUserMessage {
    return this == MessageType.text || this == MessageType.image;
  }

  bool get isSystemMessage {
    return this == MessageType.system;
  }
}

/// Modelo que representa uma mensagem individual no chat
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.type = MessageType.text,
  });

  /// Cria uma nova mensagem
  factory ChatMessageModel.create({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
  }) {
    return ChatMessageModel(
      id: _generateMessageId(),
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      message: message.trim(),
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );
  }

  /// Gera ID único para a mensagem
  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Gera string aleatória para garantir unicidade
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
        length,
        (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) %
            chars.length]).join();
  }

  /// Valida se a mensagem é válida
  bool get isValid {
    return message.trim().isNotEmpty &&
        message.trim().length <= 1000 && // Limite de 1000 caracteres
        senderId.isNotEmpty &&
        chatId.isNotEmpty;
  }

  /// Verifica se a mensagem foi enviada pelo usuário atual
  bool isSentByUser(String userId) {
    return senderId == userId;
  }

  /// Obtém texto formatado da mensagem
  String get formattedMessage {
    return message.trim();
  }

  /// Obtém timestamp formatado
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'agora';
    }
  }

  /// Cria cópia marcando como lida
  ChatMessageModel markAsRead() {
    return copyWith(isRead: true);
  }

  /// Cria cópia com campos atualizados
  ChatMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  /// Converte para Map para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name,
    };
  }

  /// Cria instância a partir de Map do Firebase
  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  /// Converte para JSON (para cache local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
    };
  }

  /// Cria instância a partir de JSON (para cache local)
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, chatId: $chatId, senderId: $senderId, '
        'message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}, '
        'timestamp: $timestamp, isRead: $isRead, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
