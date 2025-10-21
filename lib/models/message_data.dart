import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para mensagens de chat
class MessageData {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String messageType; // 'text', 'image', 'system'

  const MessageData({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.messageType,
  });

  /// Cria instância a partir de JSON
  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Usuário',
      message: json['message'] ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      isRead: json['isRead'] ?? false,
      messageType: json['messageType'] ?? 'text',
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType,
    };
  }

  /// Cria cópia com alterações
  MessageData copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? messageType,
  }) {
    return MessageData(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
    );
  }

  /// Verifica se é mensagem de texto
  bool get isTextMessage => messageType == 'text';

  /// Verifica se é mensagem de imagem
  bool get isImageMessage => messageType == 'image';

  /// Verifica se é mensagem do sistema
  bool get isSystemMessage => messageType == 'system';

  /// Verifica se a mensagem foi enviada pelo usuário atual
  bool isSentByUser(String userId) => senderId == userId;

  /// Obtém o tempo da mensagem em formato amigável
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}sem';
    }
  }

  /// Obtém o horário da mensagem formatado
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Obtém a data da mensagem formatada
  String get formattedDate {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$day/$month/$year';
  }

  /// Verifica se a mensagem é de hoje
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }

  /// Verifica se a mensagem é de ontem
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
           timestamp.month == yesterday.month &&
           timestamp.day == yesterday.day;
  }

  /// Obtém preview da mensagem (limitado a 50 caracteres)
  String get preview {
    if (message.length <= 50) return message;
    return '${message.substring(0, 47)}...';
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
    return 'MessageData(id: $id, sender: $senderName, message: ${preview}, time: $formattedTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}