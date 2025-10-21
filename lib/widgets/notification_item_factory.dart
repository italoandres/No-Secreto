import 'package:flutter/material.dart';
import 'package:whatsapp_chat/models/notification_category.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';
import 'package:whatsapp_chat/widgets/story_notification_item.dart';
import 'package:whatsapp_chat/widgets/interest_notification_item.dart';
import 'package:whatsapp_chat/widgets/system_notification_item.dart';

/// Factory para criar widgets de notificação apropriados para cada categoria
class NotificationItemFactory {
  /// Cria widget de notificação baseado na categoria
  static Widget createNotificationItem({
    required NotificationCategory category,
    required dynamic notification,
    required Function(dynamic) onTap,
    Function(dynamic)? onDelete,
  }) {
    switch (category) {
      case NotificationCategory.stories:
        // Notificações de stories (curtidas, comentários, menções, respostas)
        if (notification is NotificationModel) {
          return StoryNotificationItem(
            notification: notification,
            onTap: () => onTap(notification),
            onDelete: onDelete != null ? () => onDelete(notification) : null,
          );
        }
        break;

      case NotificationCategory.interest:
        // Notificações de interesse/match
        if (notification is InterestNotificationModel) {
          return InterestNotificationItem(
            notification: notification,
            onTap: () => onTap(notification),
            onDelete: onDelete != null ? () => onDelete(notification) : null,
          );
        }
        break;

      case NotificationCategory.system:
        // Notificações do sistema (certificação, atualizações)
        if (notification is Map<String, dynamic>) {
          return SystemNotificationItem(
            notification: notification,
            onTap: () => onTap(notification),
            onDelete: onDelete != null ? () => onDelete(notification) : null,
          );
        }
        break;
    }

    // Fallback: widget de erro se tipo não reconhecido
    return _buildErrorItem(category, notification);
  }

  /// Widget de erro quando tipo não é reconhecido
  static Widget _buildErrorItem(NotificationCategory category, dynamic notification) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de notificação não reconhecido',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Categoria: ${category.displayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtém ícone apropriado para tipo de notificação de story
  static IconData getStoryNotificationIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'mention':
        return Icons.alternate_email;
      case 'reply':
        return Icons.reply;
      case 'comment_like':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  /// Obtém cor apropriada para tipo de notificação de story
  static Color getStoryNotificationColor(String? type) {
    switch (type) {
      case 'like':
        return Colors.red.shade400;
      case 'comment':
        return Colors.blue.shade400;
      case 'mention':
        return Colors.purple.shade400;
      case 'reply':
        return Colors.green.shade400;
      case 'comment_like':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  /// Obtém texto de ação para tipo de notificação de story
  static String getStoryNotificationAction(String? type) {
    switch (type) {
      case 'like':
        return 'curtiu seu story';
      case 'comment':
        return 'comentou no seu story';
      case 'mention':
        return 'mencionou você';
      case 'reply':
        return 'respondeu seu comentário';
      case 'comment_like':
        return 'curtiu seu comentário';
      default:
        return 'interagiu com seu story';
    }
  }

  /// Obtém emoji para tipo de notificação de story
  static String getStoryNotificationEmoji(String? type) {
    switch (type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'mention':
        return '@';
      case 'reply':
        return '↩️';
      case 'comment_like':
        return '👍';
      default:
        return '📖';
    }
  }

  /// Verifica se é uma notificação de menção (deve ser destacada)
  static bool isMentionNotification(dynamic notification) {
    if (notification is NotificationModel) {
      return notification.type == 'mention';
    }
    return false;
  }

  /// Verifica se é uma notificação de match mútuo (deve ser destacada)
  static bool isMutualMatchNotification(dynamic notification) {
    if (notification is InterestNotificationModel) {
      return notification.type == 'mutual_match';
    }
    return false;
  }

  /// Verifica se é uma notificação de certificação aprovada
  static bool isCertificationApproved(dynamic notification) {
    if (notification is Map<String, dynamic>) {
      return notification['type'] == 'certification_approved';
    }
    return false;
  }

  /// Verifica se é uma notificação de certificação reprovada
  static bool isCertificationRejected(dynamic notification) {
    if (notification is Map<String, dynamic>) {
      return notification['type'] == 'certification_rejected';
    }
    return false;
  }
}
