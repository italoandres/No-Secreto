class RealNotification {
  final String id;
  final String type; // 'interest', 'like', 'match'
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhoto;
  final DateTime timestamp;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  RealNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhoto,
    required this.timestamp,
    required this.message,
    this.isRead = false,
    this.additionalData,
  });

  factory RealNotification.fromInterest({
    required String interestId,
    required String fromUserId,
    required String fromUserName,
    String? fromUserPhoto,
    required DateTime timestamp,
    String? customMessage,
  }) {
    return RealNotification(
      id: interestId,
      type: 'interest',
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhoto: fromUserPhoto,
      timestamp: timestamp,
      message: customMessage ?? '$fromUserName se interessou por você',
      isRead: false,
      additionalData: {
        'interestId': interestId,
      },
    );
  }

  RealNotification copyWith({
    String? id,
    String? type,
    String? fromUserId,
    String? fromUserName,
    String? fromUserPhoto,
    DateTime? timestamp,
    String? message,
    bool? isRead,
    Map<String, dynamic>? additionalData,
  }) {
    return RealNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPhoto: fromUserPhoto ?? this.fromUserPhoto,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool isValid() {
    return id.isNotEmpty &&
        fromUserId.isNotEmpty &&
        fromUserName.isNotEmpty &&
        message.isNotEmpty;
  }

  String getDisplayName() {
    return fromUserName.isNotEmpty ? fromUserName : 'Usuário';
  }

  String getFormattedMessage() {
    return message;
  }

  @override
  String toString() {
    return 'RealNotification(id: $id, type: $type, from: $fromUserName, message: $message)';
  }
}
