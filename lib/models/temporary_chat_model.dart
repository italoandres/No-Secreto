import 'package:cloud_firestore/cloud_firestore.dart';

class TemporaryChatModel {
  String? id;
  String mutualInterestId; // Reference to MutualInterestModel
  String user1Id;
  String user2Id;
  String chatRoomId; // Unique chat room identifier
  DateTime createdAt;
  DateTime expiresAt; // 7 days from creation
  bool isActive;
  bool movedToNossoProposito;
  DateTime? movedAt;

  // Chat metadata
  String? lastMessage;
  DateTime? lastMessageAt;
  String? lastMessageSenderId;
  int messageCount;

  // User info for quick access
  String? user1Name;
  String? user1Username;
  String? user1PhotoUrl;
  String? user2Name;
  String? user2Username;
  String? user2PhotoUrl;

  TemporaryChatModel({
    this.id,
    required this.mutualInterestId,
    required this.user1Id,
    required this.user2Id,
    required this.chatRoomId,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.movedToNossoProposito = false,
    this.movedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.messageCount = 0,
    this.user1Name,
    this.user1Username,
    this.user1PhotoUrl,
    this.user2Name,
    this.user2Username,
    this.user2PhotoUrl,
  });

  static TemporaryChatModel fromJson(Map<String, dynamic> json) {
    return TemporaryChatModel(
      id: json['id'],
      mutualInterestId: json['mutualInterestId'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      chatRoomId: json['chatRoomId'],
      createdAt: json['createdAt'].toDate(),
      expiresAt: json['expiresAt'].toDate(),
      isActive: json['isActive'] ?? true,
      movedToNossoProposito: json['movedToNossoProposito'] ?? false,
      movedAt: json['movedAt']?.toDate(),
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt']?.toDate(),
      lastMessageSenderId: json['lastMessageSenderId'],
      messageCount: json['messageCount'] ?? 0,
      user1Name: json['user1Name'],
      user1Username: json['user1Username'],
      user1PhotoUrl: json['user1PhotoUrl'],
      user2Name: json['user2Name'],
      user2Username: json['user2Username'],
      user2PhotoUrl: json['user2PhotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mutualInterestId': mutualInterestId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'chatRoomId': chatRoomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'movedToNossoProposito': movedToNossoProposito,
      'movedAt': movedAt != null ? Timestamp.fromDate(movedAt!) : null,
      'lastMessage': lastMessage,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'messageCount': messageCount,
      'user1Name': user1Name,
      'user1Username': user1Username,
      'user1PhotoUrl': user1PhotoUrl,
      'user2Name': user2Name,
      'user2Username': user2Username,
      'user2PhotoUrl': user2PhotoUrl,
    };
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());

  String get timeRemainingText {
    final remaining = timeUntilExpiration;

    if (remaining.isNegative) {
      return 'Expirado';
    }

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h restantes';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m restantes';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m restantes';
    } else {
      return 'Expira em breve';
    }
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  String? getOtherUserName(String currentUserId) {
    return currentUserId == user1Id ? user2Name : user1Name;
  }

  String? getOtherUserUsername(String currentUserId) {
    return currentUserId == user1Id ? user2Username : user1Username;
  }

  String? getOtherUserPhotoUrl(String currentUserId) {
    return currentUserId == user1Id ? user2PhotoUrl : user1PhotoUrl;
  }

  bool isParticipant(String userId) {
    return userId == user1Id || userId == user2Id;
  }

  TemporaryChatModel copyWith({
    String? id,
    String? mutualInterestId,
    String? user1Id,
    String? user2Id,
    String? chatRoomId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    bool? movedToNossoProposito,
    DateTime? movedAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    int? messageCount,
    String? user1Name,
    String? user1Username,
    String? user1PhotoUrl,
    String? user2Name,
    String? user2Username,
    String? user2PhotoUrl,
  }) {
    return TemporaryChatModel(
      id: id ?? this.id,
      mutualInterestId: mutualInterestId ?? this.mutualInterestId,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      movedToNossoProposito:
          movedToNossoProposito ?? this.movedToNossoProposito,
      movedAt: movedAt ?? this.movedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      messageCount: messageCount ?? this.messageCount,
      user1Name: user1Name ?? this.user1Name,
      user1Username: user1Username ?? this.user1Username,
      user1PhotoUrl: user1PhotoUrl ?? this.user1PhotoUrl,
      user2Name: user2Name ?? this.user2Name,
      user2Username: user2Username ?? this.user2Username,
      user2PhotoUrl: user2PhotoUrl ?? this.user2PhotoUrl,
    );
  }
}

class TemporaryChatMessageModel {
  String? id;
  String chatRoomId;
  String senderId;
  String senderName;
  String? senderUsername;
  String? senderPhotoUrl;
  String message;
  DateTime timestamp;
  bool isRead;
  String messageType; // 'text', 'system', 'welcome'

  TemporaryChatMessageModel({
    this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderUsername,
    this.senderPhotoUrl,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
  });

  static TemporaryChatMessageModel fromJson(Map<String, dynamic> json) {
    return TemporaryChatMessageModel(
      id: json['id'],
      chatRoomId: json['chatRoomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderUsername: json['senderUsername'],
      senderPhotoUrl: json['senderPhotoUrl'],
      message: json['message'],
      timestamp: json['timestamp'].toDate(),
      isRead: json['isRead'] ?? false,
      messageType: json['messageType'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderUsername': senderUsername,
      'senderPhotoUrl': senderPhotoUrl,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType,
    };
  }

  bool get isSystemMessage =>
      messageType == 'system' || messageType == 'welcome';

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
}
