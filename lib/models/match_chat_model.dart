import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa um chat entre dois usuários matched
class MatchChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final bool isExpired;
  final Map<String, int> unreadCount; // userId -> count

  MatchChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.expiresAt,
    this.lastMessageAt,
    this.lastMessage,
    required this.isExpired,
    required this.unreadCount,
  });

  /// Cria um novo chat entre dois usuários
  factory MatchChatModel.create({
    required String user1Id,
    required String user2Id,
  }) {
    final now = DateTime.now();
    final chatId = _generateChatId(user1Id, user2Id);

    return MatchChatModel(
      id: chatId,
      user1Id: user1Id,
      user2Id: user2Id,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      isExpired: false,
      unreadCount: {
        user1Id: 0,
        user2Id: 0,
      },
    );
  }

  /// Gera ID único para o chat baseado nos IDs dos usuários
  static String _generateChatId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Verifica se o chat expirou
  bool get hasExpired => DateTime.now().isAfter(expiresAt);

  /// Calcula dias restantes até expiração
  int get daysRemaining {
    if (hasExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Obtém o ID do outro usuário no chat
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Obtém contagem de mensagens não lidas para um usuário
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Cria cópia com campos atualizados
  MatchChatModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    bool? isExpired,
    Map<String, int>? unreadCount,
  }) {
    return MatchChatModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      isExpired: isExpired ?? this.isExpired,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Converte para Map para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage,
      'isExpired': isExpired,
      'unreadCount': unreadCount,
    };
  }

  /// Cria instância a partir de Map do Firebase
  factory MatchChatModel.fromMap(Map<String, dynamic> map) {
    return MatchChatModel(
      id: map['id'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessage: map['lastMessage'],
      isExpired: map['isExpired'] ?? false,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => toMap();

  /// Cria instância a partir de JSON
  factory MatchChatModel.fromJson(Map<String, dynamic> json) =>
      MatchChatModel.fromMap(json);

  @override
  String toString() {
    return 'MatchChatModel(id: $id, user1Id: $user1Id, user2Id: $user2Id, '
        'createdAt: $createdAt, expiresAt: $expiresAt, isExpired: $isExpired, '
        'daysRemaining: $daysRemaining)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Retorna a data de criação formatada
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Retorna a data de expiração formatada
  String get formattedExpirationDate {
    return '${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year}';
  }
}
