import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para chats de matches
class ChatData {
  final String chatId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final Map<String, int> unreadCount;
  final bool isActive;
  final DateTime? expiresAt;

  const ChatData({
    required this.chatId,
    required this.participants,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    required this.unreadCount,
    required this.isActive,
    this.expiresAt,
  });

  /// Cria instância a partir de JSON
  factory ChatData.fromJson(Map<String, dynamic> json) {
    return ChatData(
      chatId: json['chatId'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: _parseTimestamp(json['createdAt']),
      lastMessageAt: _parseTimestamp(json['lastMessageAt']),
      lastMessage: json['lastMessage'],
      unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
      isActive: json['isActive'] ?? true,
      expiresAt: _parseTimestamp(json['expiresAt']),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Cria cópia com alterações
  ChatData copyWith({
    String? chatId,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    Map<String, int>? unreadCount,
    bool? isActive,
    DateTime? expiresAt,
  }) {
    return ChatData(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Verifica se o usuário participa do chat
  bool includesUser(String userId) {
    return participants.contains(userId);
  }

  /// Obtém o ID do outro usuário no chat
  String? getOtherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Obtém o contador de não lidas para um usuário
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Verifica se o chat tem mensagens não lidas para um usuário
  bool hasUnreadMessages(String userId) {
    return getUnreadCountForUser(userId) > 0;
  }

  /// Verifica se o chat expirou
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Verifica se o chat está ativo e não expirou
  bool get isActiveAndValid => isActive && !isExpired;

  /// Obtém o tempo desde a última mensagem
  String get timeSinceLastMessage {
    if (lastMessageAt == null) return 'Sem mensagens';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);
    
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
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  @override
  String toString() {
    return 'ChatData(chatId: $chatId, participants: $participants, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatData && other.chatId == chatId;
  }

  @override
  int get hashCode => chatId.hashCode;
}