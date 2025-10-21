import 'package:flutter/material.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/services/notification_service.dart';

class NotificationItemComponent extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationItemComponent({
    Key? key,
    required this.notification,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead 
              ? Colors.transparent 
              : Colors.amber.shade200,
          width: notification.isRead ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead 
                ? Colors.white 
                : Colors.amber.shade50,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar do usuário
              _buildUserAvatar(),
              
              const SizedBox(width: 12),
              
              // Conteúdo da notificação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do usuário e tempo
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.fromUserName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Tempo relativo
                        Text(
                          NotificationService.getRelativeTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Tipo da notificação
                    _buildNotificationTypeLabel(),
                    
                    const SizedBox(height: 8),
                    
                    // Conteúdo da notificação
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Indicador de não lida e menu
              Column(
                children: [
                  // Indicador de não lida
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Menu de opções
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Excluir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construir avatar do usuário
  Widget _buildUserAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ClipOval(
        child: notification.fromUserAvatar.isNotEmpty
            ? Image.network(
                notification.fromUserAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  // Avatar padrão quando não há imagem
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.person,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  // Label do tipo de notificação
  Widget _buildNotificationTypeLabel() {
    String label;
    Color color;
    IconData icon;

    switch (notification.type) {
      case 'comment_mention':
        label = 'mencionou você';
        color = Colors.orange;
        icon = Icons.alternate_email;
        break;
      case 'comment_like':
        label = 'curtiu seu comentário';
        color = Colors.red;
        icon = Icons.favorite_outline;
        break;
      case 'comment_reply':
        label = 'respondeu seu comentário';
        color = Colors.blue;
        icon = Icons.reply_outlined;
        break;
      default:
        label = 'notificação';
        color = Colors.grey;
        icon = Icons.notifications_outlined;
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Versão compacta do item de notificação
class CompactNotificationItemComponent extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const CompactNotificationItemComponent({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.amber.shade50,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar pequeno
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: notification.fromUserAvatar.isNotEmpty
                    ? Image.network(
                        notification.fromUserAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: Colors.grey.shade400,
                            size: 16,
                          );
                        },
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCompactNotificationText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Text(
                    notification.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Tempo e indicador
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NotificationService.getRelativeTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                if (!notification.isRead)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Texto compacto baseado no tipo de notificação
  String _getCompactNotificationText() {
    switch (notification.type) {
      case 'comment_mention':
        return '${notification.fromUserName} mencionou você';
      case 'comment_like':
        return '${notification.fromUserName} curtiu seu comentário';
      case 'comment_reply':
        return '${notification.fromUserName} respondeu';
      default:
        return '${notification.fromUserName} interagiu';
    }
  }
}