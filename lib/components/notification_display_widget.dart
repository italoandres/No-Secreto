import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/real_notification_model.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// Widget dedicado para exibir notificações na tela de matches
class NotificationDisplayWidget extends StatelessWidget {
  final List<RealNotification>? notifications;
  final bool? isLoading;
  final String? error;
  final VoidCallback? onRefresh;
  final Function(RealNotification)? onNotificationTap;

  const NotificationDisplayWidget({
    Key? key,
    this.notifications,
    this.isLoading,
    this.error,
    this.onRefresh,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Usar apenas Obx para reatividade simples e direta
      return Obx(() {
        final controller = Get.find<MatchesController>();
        return _buildNotificationContent(controller);
      });
    } catch (e) {
      EnhancedLogger.error('❌ [NOTIFICATION_WIDGET] Erro no build',
          tag: 'NOTIFICATION_DISPLAY_WIDGET', error: e);
      return _buildErrorWidget('Erro ao carregar notificações');
    }
  }

  Widget _buildNotificationContent(MatchesController controller) {
    try {
      // Usar dados do controller se não foram passados como parâmetros
      final notificationsList = notifications ?? controller.realNotifications;
      final loading = isLoading ?? controller.isLoadingNotifications.value;
      final errorMessage = error ?? controller.notificationError.value;

      EnhancedLogger.info('🔄 [NOTIFICATION_WIDGET] Construindo UI',
          tag: 'NOTIFICATION_DISPLAY_WIDGET',
          data: {
            'notificationsCount': notificationsList.length,
            'isLoading': loading,
            'hasError': errorMessage.isNotEmpty,
          });

      // Estado de carregamento
      if (loading) {
        return _buildLoadingWidget();
      }

      // Estado de erro
      if (errorMessage.isNotEmpty) {
        return _buildErrorWidget(errorMessage);
      }

      // Estado vazio
      if (notificationsList.isEmpty) {
        return _buildEmptyWidget();
      }

      // Estado com notificações
      return _buildNotificationsList(notificationsList);
    } catch (e) {
      EnhancedLogger.error('❌ [NOTIFICATION_WIDGET] Erro ao construir conteúdo',
          tag: 'NOTIFICATION_DISPLAY_WIDGET', error: e);
      return _buildErrorWidget('Erro interno');
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Carregando notificações...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRefresh,
              tooltip: 'Tentar novamente',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Row(
        children: [
          Icon(
            Icons.notifications_none,
            color: Colors.grey,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            'Nenhuma notificação no momento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<RealNotification> notificationsList) {
    try {
      EnhancedLogger.success(
          '✅ [NOTIFICATION_WIDGET] Renderizando lista de notificações',
          tag: 'NOTIFICATION_DISPLAY_WIDGET',
          data: {'count': notificationsList.length});

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.pink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Novos Interesses (${notificationsList.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: onRefresh,
                    tooltip: 'Atualizar',
                  ),
              ],
            ),
          ),

          // Lista de notificações
          ...notificationsList
              .map((notification) => _buildNotificationItem(notification))
              .toList(),
        ],
      );
    } catch (e) {
      EnhancedLogger.error('❌ [NOTIFICATION_WIDGET] Erro ao construir lista',
          tag: 'NOTIFICATION_DISPLAY_WIDGET', error: e);
      return _buildErrorWidget('Erro ao exibir notificações');
    }
  }

  Widget _buildNotificationItem(RealNotification notification) {
    try {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.pink.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.pink.shade200,
            width: 1,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.pink.shade100,
            child: notification.fromUserPhoto != null
                ? ClipOval(
                    child: Image.network(
                      notification.fromUserPhoto!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.pink,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.pink,
                  ),
          ),
          title: Text(
            notification.getDisplayName(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.getFormattedMessage(),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
          onTap: () {
            try {
              EnhancedLogger.info('👆 [NOTIFICATION_WIDGET] Notificação tocada',
                  tag: 'NOTIFICATION_DISPLAY_WIDGET',
                  data: {
                    'notificationId': notification.id,
                    'fromUser': notification.fromUserName,
                  });

              if (onNotificationTap != null) {
                onNotificationTap!(notification);
              }
            } catch (e) {
              EnhancedLogger.error(
                  '❌ [NOTIFICATION_WIDGET] Erro ao tocar notificação',
                  tag: 'NOTIFICATION_DISPLAY_WIDGET',
                  error: e);
            }
          },
        ),
      );
    } catch (e) {
      EnhancedLogger.error('❌ [NOTIFICATION_WIDGET] Erro ao construir item',
          tag: 'NOTIFICATION_DISPLAY_WIDGET',
          error: e,
          data: {'notificationId': notification.id});
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: const Text(
          'Erro ao exibir notificação',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    try {
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inMinutes < 1) {
        return 'Agora mesmo';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m atrás';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h atrás';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d atrás';
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    } catch (e) {
      return 'Data inválida';
    }
  }
}

/// Widget simplificado para casos específicos
class SimpleNotificationDisplayWidget extends StatelessWidget {
  final MatchesController controller;

  const SimpleNotificationDisplayWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.realNotifications.isEmpty) {
        return const SizedBox.shrink();
      }

      return NotificationDisplayWidget(
        notifications: controller.realNotifications,
        isLoading: controller.isLoadingNotifications.value,
        error: controller.notificationError.value,
        onRefresh: () => controller.refreshRealInterestNotifications(),
        onNotificationTap: (notification) {
          // Implementar navegação para perfil
          EnhancedLogger.info('Navegando para perfil do usuário',
              data: {'userId': notification.fromUserId});
        },
      );
    });
  }
}
