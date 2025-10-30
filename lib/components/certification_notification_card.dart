import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

/// Card de notificação de certificação
class CertificationNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const CertificationNotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  Color _getBackgroundColor() {
    if (notification.isRead) {
      return Colors.grey.shade50;
    }

    switch (notification.type) {
      case 'certification_approved':
        return Colors.green.shade50;
      case 'certification_rejected':
        return Colors.red.shade50;
      case 'certification_new_request':
        return Colors.amber.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (notification.type) {
      case 'certification_approved':
        return Colors.green.shade200;
      case 'certification_rejected':
        return Colors.red.shade200;
      case 'certification_new_request':
        return Colors.amber.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'certification_approved':
        return Icons.check_circle;
      case 'certification_rejected':
        return Icons.cancel;
      case 'certification_new_request':
        return Icons.notification_important;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'certification_approved':
        return Colors.green.shade700;
      case 'certification_rejected':
        return Colors.red.shade700;
      case 'certification_new_request':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: _getBorderColor().withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getIconColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      color: _getIconColor(),
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Conteúdo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getIconColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Mensagem
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Data
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Seta
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
