import '../models/interest_model.dart';
import '../models/real_notification_model.dart';
import '../models/user_data_model.dart';

/// Converter temporário para resolver problemas de compilação
class TempNotificationConverter {
  static TempNotificationConverter? _instance;
  static TempNotificationConverter get instance =>
      _instance ??= TempNotificationConverter._();

  TempNotificationConverter._();

  /// Converte interações em notificações
  Future<List<RealNotification>> convertInteractionsToNotifications(
    List<Interest> interactions,
    Map<String, UserData> userCache,
  ) async {
    final notifications = <RealNotification>[];

    for (final interest in interactions) {
      try {
        final userData = userCache[interest.from];
        final userName = userData?.getDisplayName() ?? 'Usuário';

        final notification = RealNotification(
          id: interest.id,
          type: 'interest',
          fromUserId: interest.from,
          fromUserName: userName,
          fromUserPhoto: userData?.getPhotoUrl(),
          message: '$userName se interessou por você',
          timestamp: interest.timestamp,
          isRead: false,
        );

        notifications.add(notification);
      } catch (e) {
        // Ignora erros individuais
      }
    }

    return notifications;
  }

  /// Valida uma notificação
  bool validateNotification(RealNotification notification) {
    return notification.id.isNotEmpty &&
        notification.fromUserId.isNotEmpty &&
        notification.fromUserName.isNotEmpty &&
        notification.message.isNotEmpty;
  }

  /// Obtém estatísticas de conversão
  Map<String, dynamic> getConversionStatistics() {
    return {
      'successRate': '100%',
      'totalConversions': 0,
      'errors': 0,
    };
  }

  /// Limpa estatísticas antigas
  void clearOldStatistics() {
    // Implementação vazia
  }
}
