import '../models/interest_model.dart';
import '../models/real_notification_model.dart';
import '../models/user_data_model.dart';
import '../utils/enhanced_logger.dart';

class RealNotificationConverter {
  static final RealNotificationConverter _instance =
      RealNotificationConverter._internal();
  factory RealNotificationConverter() => _instance;
  RealNotificationConverter._internal();

  /// Converte Interest em RealNotification
  RealNotification convertInterestToNotification(
      Interest interest, UserData userData) {
    try {
      EnhancedLogger.debug(
          'Convertendo interesse em notificação: ${interest.id}');

      final notification = RealNotification.fromInterest(
        interestId: interest.id,
        fromUserId: interest.from,
        fromUserName: userData.getDisplayName(),
        fromUserPhoto: userData.getPhotoUrl(),
        timestamp: interest.timestamp,
        customMessage: _generateInterestMessage(userData, interest),
      );

      EnhancedLogger.success('Notificação criada: ${notification.message}');
      return notification;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro ao converter interesse em notificação',
          error: e, stackTrace: stackTrace);

      // Fallback com dados mínimos
      return _createFallbackNotification(interest, userData);
    }
  }

  /// Converte lista de interesses em notificações
  Future<List<RealNotification>> convertInterestsToNotifications(
    List<Interest> interests,
    Map<String, UserData> usersData,
  ) async {
    final List<RealNotification> notifications = [];

    EnhancedLogger.info(
        'Convertendo ${interests.length} interesses em notificações');

    for (final interest in interests) {
      try {
        final userData = usersData[interest.from];

        if (userData != null) {
          final notification =
              convertInterestToNotification(interest, userData);
          notifications.add(notification);
        } else {
          EnhancedLogger.warning(
              'Dados do usuário não encontrados para: ${interest.from}');

          // Cria notificação com dados de fallback
          final fallbackUserData = UserData.fallback(interest.from);
          final notification =
              convertInterestToNotification(interest, fallbackUserData);
          notifications.add(notification);
        }
      } catch (e) {
        EnhancedLogger.error('Erro ao converter interesse ${interest.id}',
            error: e);
        continue;
      }
    }

    // Ordena por timestamp (mais recente primeiro)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    EnhancedLogger.success(
        '${notifications.length} notificações criadas com sucesso');
    return notifications;
  }

  /// Valida e formata dados da notificação
  RealNotification formatNotificationData(RealNotification notification) {
    try {
      // Valida dados básicos
      if (!notification.isValid()) {
        EnhancedLogger.warning(
            'Notificação inválida detectada: ${notification.id}');
        return _fixInvalidNotification(notification);
      }

      // Formata nome do usuário
      final formattedName = _formatUserName(notification.fromUserName);

      // Formata mensagem
      final formattedMessage =
          _formatMessage(notification.message, formattedName);

      return notification.copyWith(
        fromUserName: formattedName,
        message: formattedMessage,
      );
    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro ao formatar notificação',
          error: e, stackTrace: stackTrace);
      return notification;
    }
  }

  /// Gera mensagem personalizada para interesse
  String _generateInterestMessage(UserData userData, Interest interest) {
    final userName = userData.getDisplayName();

    // Mensagens personalizadas baseadas no horário
    final hour = interest.timestamp.hour;

    if (hour >= 6 && hour < 12) {
      return '$userName se interessou por você esta manhã ☀️';
    } else if (hour >= 12 && hour < 18) {
      return '$userName se interessou por você esta tarde 🌤️';
    } else if (hour >= 18 && hour < 22) {
      return '$userName se interessou por você esta noite 🌙';
    } else {
      return '$userName se interessou por você 💕';
    }
  }

  /// Cria notificação de fallback para casos de erro
  RealNotification _createFallbackNotification(
      Interest interest, UserData userData) {
    EnhancedLogger.warning(
        'Criando notificação de fallback para interesse: ${interest.id}');

    return RealNotification(
      id: interest.id,
      type: 'interest',
      fromUserId: interest.from,
      fromUserName: userData.getDisplayName(),
      fromUserPhoto: userData.getPhotoUrl(),
      timestamp: interest.timestamp,
      message: '${userData.getDisplayName()} se interessou por você',
      isRead: false,
      additionalData: {
        'interestId': interest.id,
        'isFallback': true,
      },
    );
  }

  /// Corrige notificação inválida
  RealNotification _fixInvalidNotification(RealNotification notification) {
    EnhancedLogger.info('Corrigindo notificação inválida: ${notification.id}');

    return notification.copyWith(
      fromUserName: notification.fromUserName.isEmpty
          ? 'Usuário'
          : notification.fromUserName,
      message: notification.message.isEmpty
          ? 'Você recebeu um interesse'
          : notification.message,
    );
  }

  /// Formata nome do usuário
  String _formatUserName(String userName) {
    if (userName.isEmpty) return 'Usuário';

    // Remove caracteres especiais e limita tamanho
    final cleaned = userName.trim();
    if (cleaned.length > 30) {
      return '${cleaned.substring(0, 27)}...';
    }

    return cleaned;
  }

  /// Formata mensagem da notificação
  String _formatMessage(String message, String userName) {
    if (message.isEmpty) {
      return '$userName se interessou por você';
    }

    // Limita tamanho da mensagem
    if (message.length > 100) {
      return '${message.substring(0, 97)}...';
    }

    return message;
  }

  /// Agrupa notificações por usuário (para evitar spam)
  List<RealNotification> groupNotificationsByUser(
      List<RealNotification> notifications) {
    final Map<String, List<RealNotification>> grouped = {};

    // Agrupa por usuário
    for (final notification in notifications) {
      final userId = notification.fromUserId;
      grouped.putIfAbsent(userId, () => []).add(notification);
    }

    final List<RealNotification> result = [];

    // Para cada usuário, pega apenas a notificação mais recente
    for (final userNotifications in grouped.values) {
      if (userNotifications.length == 1) {
        result.add(userNotifications.first);
      } else {
        // Ordena por timestamp e pega a mais recente
        userNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final latest = userNotifications.first;

        // Se há múltiplas, ajusta a mensagem
        if (userNotifications.length > 1) {
          final count = userNotifications.length;
          final updatedMessage =
              '${latest.fromUserName} se interessou por você ($count vezes)';
          result.add(latest.copyWith(message: updatedMessage));
        } else {
          result.add(latest);
        }
      }
    }

    // Ordena resultado por timestamp
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    EnhancedLogger.info(
        'Agrupamento: ${notifications.length} → ${result.length} notificações');
    return result;
  }

  /// Debug: valida lista de notificações
  void debugValidateNotifications(List<RealNotification> notifications) {
    EnhancedLogger.debug('=== VALIDAÇÃO DE NOTIFICAÇÕES ===');
    EnhancedLogger.debug('Total: ${notifications.length}');

    int valid = 0;
    int invalid = 0;

    for (final notification in notifications) {
      if (notification.isValid()) {
        valid++;
        EnhancedLogger.debug('✅ ${notification.id}: ${notification.message}');
      } else {
        invalid++;
        EnhancedLogger.debug('❌ ${notification.id}: INVÁLIDA');
      }
    }

    EnhancedLogger.debug('Válidas: $valid, Inválidas: $invalid');
    EnhancedLogger.debug('=== FIM VALIDAÇÃO ===');
  }
}
