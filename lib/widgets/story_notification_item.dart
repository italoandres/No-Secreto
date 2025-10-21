import 'package:flutter/material.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/widgets/notification_item_factory.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget para exibir notificação de story
/// Suporta: curtidas, comentários, menções (@), respostas, curtidas em comentários
class StoryNotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const StoryNotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMention = notification.type == 'mention';
    final isUnread = !notification.isRead;

    return Card(
      elevation: isUnread ? 3 : 1,
      color: isMention 
          ? Colors.purple.shade50 
          : (isUnread ? Colors.white : Colors.grey.shade50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMention 
            ? BorderSide(color: Colors.purple.shade200, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar do usuário
              _buildAvatar(),
              const SizedBox(width: 12),
              
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do usuário + ação
                    _buildHeader(),
                    const SizedBox(height: 4),
                    
                    // Preview do conteúdo (se houver)
                    if (notification.message != null && notification.message!.isNotEmpty)
                      _buildPreview(),
                    
                    const SizedBox(height: 4),
                    
                    // Timestamp
                    _buildTimestamp(),
                  ],
                ),
              ),
              
              // Ícone do tipo + indicador de não lida
              Column(
                children: [
                  _buildTypeIcon(),
                  if (isUnread) ...[
                    const SizedBox(height: 8),
                    _buildUnreadIndicator(),
                  ],
                ],
              ),
              
              // Botão de deletar (se fornecido)
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                  color: Colors.grey.shade400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói avatar do usuário
  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.amber.shade100,
          backgroundImage: notification.fromUserAvatar.isNotEmpty
              ? NetworkImage(notification.fromUserAvatar)
              : null,
          child: notification.fromUserAvatar.isEmpty
              ? Text(
                  notification.fromUserName.isNotEmpty 
                      ? notification.fromUserName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                )
              : null,
        ),
        
        // Badge com emoji do tipo
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              NotificationItemFactory.getStoryNotificationEmoji(notification.type),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói header com nome e ação
  Widget _buildHeader() {
    final isMention = notification.type == 'mention';
    
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          // Nome do usuário
          TextSpan(
            text: notification.fromUserName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' '),
          
          // Ação
          TextSpan(
            text: NotificationItemFactory.getStoryNotificationAction(notification.type),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: isMention ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          
          // Badge de menção
          if (isMention) ...[
            const TextSpan(text: ' '),
            WidgetSpan(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '@',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Constrói preview do conteúdo
  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        notification.message ?? notification.content,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Constrói timestamp
  Widget _buildTimestamp() {
    final timestamp = notification.timestamp;
    final timeAgo = timeago.format(timestamp, locale: 'pt_BR');
    
    return Text(
      timeAgo,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
    );
  }

  /// Constrói ícone do tipo de notificação
  Widget _buildTypeIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: NotificationItemFactory.getStoryNotificationColor(notification.type).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        NotificationItemFactory.getStoryNotificationIcon(notification.type),
        size: 16,
        color: NotificationItemFactory.getStoryNotificationColor(notification.type),
      ),
    );
  }

  /// Constrói indicador de não lida (ponto azul)
  Widget _buildUnreadIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
      ),
    );
  }
}
