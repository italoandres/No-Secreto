/// Modelo que representa um match aceito na lista de matches
class AcceptedMatchModel {
  final String notificationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final int? otherUserAge;
  final String? otherUserCity;
  final DateTime matchDate;
  final String chatId;
  final int unreadMessages;
  final bool chatExpired;
  final int daysRemaining;

  AcceptedMatchModel({
    required this.notificationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.otherUserAge,
    this.otherUserCity,
    required this.matchDate,
    required this.chatId,
    required this.unreadMessages,
    required this.chatExpired,
    required this.daysRemaining,
  });

  /// Cria instância a partir de notificação de interesse aceita
  factory AcceptedMatchModel.fromNotification({
    required String notificationId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    int? otherUserAge,
    String? otherUserCity,
    required DateTime matchDate,
    required String chatId,
    int unreadMessages = 0,
    bool chatExpired = false,
    int daysRemaining = 30,
  }) {
    return AcceptedMatchModel(
      notificationId: notificationId,
      otherUserId: otherUserId,
      otherUserName: otherUserName.trim(),
      otherUserPhoto: otherUserPhoto,
      otherUserAge: otherUserAge,
      otherUserCity: otherUserCity,
      matchDate: matchDate,
      chatId: chatId,
      unreadMessages: unreadMessages,
      chatExpired: chatExpired,
      daysRemaining: daysRemaining,
    );
  }

  /// Verifica se há mensagens não lidas
  bool get hasUnreadMessages => unreadMessages > 0;

  /// Verifica se o chat ainda está ativo
  bool get isChatActive => !chatExpired && daysRemaining > 0;

  /// Obtém status do chat para exibição
  String get chatStatus {
    if (chatExpired) return 'Chat Expirado';
    if (daysRemaining <= 0) return 'Chat Expirado';
    if (daysRemaining == 1) return '1 dia restante';
    if (daysRemaining <= 7) return '$daysRemaining dias restantes';
    return '$daysRemaining dias restantes';
  }

  /// Obtém cor do status baseada no tempo restante
  String get statusColor {
    if (chatExpired || daysRemaining <= 0) return 'red';
    if (daysRemaining <= 1) return 'red';
    if (daysRemaining <= 7) return 'orange';
    return 'green';
  }

  /// Obtém texto do contador de mensagens não lidas
  String get unreadText {
    if (unreadMessages <= 0) return '';
    if (unreadMessages > 99) return '99+';
    return unreadMessages.toString();
  }

  /// Obtém nome formatado do usuário
  String get formattedName {
    if (otherUserName.isEmpty) return 'Usuário';
    return otherUserName.length > 20
        ? '${otherUserName.substring(0, 20)}...'
        : otherUserName;
  }

  /// Obtém nome com idade para exibição
  String get nameWithAge {
    if (otherUserAge != null) {
      return '$formattedName, $otherUserAge';
    }
    return formattedName;
  }

  /// Obtém localização formatada
  String get formattedLocation {
    if (otherUserCity != null && otherUserCity!.isNotEmpty) {
      return otherUserCity!;
    }
    return '';
  }

  /// Obtém data formatada do match
  String get formattedMatchDate {
    final now = DateTime.now();
    final difference = now.difference(matchDate);

    // Normalizar datas para comparação (ignorar hora)
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(matchDate.year, matchDate.month, matchDate.day);
    final daysDifference = today.difference(matchDay).inDays;

    // Hoje (mesmo dia, independente da hora)
    if (daysDifference == 0) {
      if (difference.inHours == 0) {
        return 'agora mesmo';
      }
      return 'hoje';
    }

    // Ontem (1 dia atrás)
    if (daysDifference == 1) {
      return 'ontem';
    }

    // 2-30 dias atrás
    if (daysDifference <= 30) {
      return '$daysDifference dia${daysDifference > 1 ? 's' : ''} atrás';
    }

    // Mais de 30 dias (meses)
    final months = (daysDifference / 30).floor();
    return '$months mês${months > 1 ? 'es' : ''} atrás';
  }

  /// Cria cópia com campos atualizados
  AcceptedMatchModel copyWith({
    String? notificationId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhoto,
    int? otherUserAge,
    String? otherUserCity,
    DateTime? matchDate,
    String? chatId,
    int? unreadMessages,
    bool? chatExpired,
    int? daysRemaining,
  }) {
    return AcceptedMatchModel(
      notificationId: notificationId ?? this.notificationId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhoto: otherUserPhoto ?? this.otherUserPhoto,
      otherUserAge: otherUserAge ?? this.otherUserAge,
      otherUserCity: otherUserCity ?? this.otherUserCity,
      matchDate: matchDate ?? this.matchDate,
      chatId: chatId ?? this.chatId,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      chatExpired: chatExpired ?? this.chatExpired,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhoto': otherUserPhoto,
      'otherUserAge': otherUserAge,
      'otherUserCity': otherUserCity,
      'matchDate': matchDate.toIso8601String(),
      'chatId': chatId,
      'unreadMessages': unreadMessages,
      'chatExpired': chatExpired,
      'daysRemaining': daysRemaining,
    };
  }

  /// Cria instância a partir de Map
  factory AcceptedMatchModel.fromMap(Map<String, dynamic> map) {
    return AcceptedMatchModel(
      notificationId: map['notificationId'] ?? '',
      otherUserId: map['otherUserId'] ?? '',
      otherUserName: map['otherUserName'] ?? '',
      otherUserPhoto: map['otherUserPhoto'],
      otherUserAge: map['otherUserAge'],
      otherUserCity: map['otherUserCity'],
      matchDate: DateTime.parse(map['matchDate']),
      chatId: map['chatId'] ?? '',
      unreadMessages: map['unreadMessages'] ?? 0,
      chatExpired: map['chatExpired'] ?? false,
      daysRemaining: map['daysRemaining'] ?? 0,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => toMap();

  /// Cria instância a partir de JSON
  factory AcceptedMatchModel.fromJson(Map<String, dynamic> json) =>
      AcceptedMatchModel.fromMap(json);

  @override
  String toString() {
    return 'AcceptedMatchModel(notificationId: $notificationId, '
        'otherUserId: $otherUserId, otherUserName: $otherUserName, '
        'matchDate: $matchDate, chatId: $chatId, '
        'unreadMessages: $unreadMessages, chatExpired: $chatExpired, '
        'daysRemaining: $daysRemaining)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AcceptedMatchModel &&
        other.notificationId == notificationId &&
        other.otherUserId == otherUserId;
  }

  @override
  int get hashCode => notificationId.hashCode ^ otherUserId.hashCode;
}
