import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget para exibir notificação do sistema
/// Suporta: certificação aprovada/reprovada, atualizações, avisos
class SystemNotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SystemNotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String?;
    final isApproved = type == 'certification_approved';
    final isRejected = type == 'certification_rejected';
    final isUnread = !(notification['read'] ?? false);

    return Card(
      elevation: isUnread ? 3 : 1,
      color: isApproved 
          ? Colors.green.shade50 
          : (isRejected ? Colors.orange.shade50 : Colors.blue.shade50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isApproved 
            ? BorderSide(color: Colors.green.shade200, width: 2)
            : (isRejected 
                ? BorderSide(color: Colors.orange.shade200, width: 2)
                : BorderSide.none),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone do sistema
              _buildIcon(type),
              const SizedBox(width: 12),
              
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    _buildTitle(type),
                    const SizedBox(height: 4),
                    
                    // Mensagem
                    _buildMessage(),
                    
                    const SizedBox(height: 4),
                    
                    // Timestamp
                    _buildTimestamp(),
                    
                    // Botão de ação (se houver)
                    if (_hasAction(type)) ...[
                      const SizedBox(height: 8),
                      _buildActionButton(type),
                    ],
                  ],
                ),
              ),
              
              // Indicador de não lida
              if (isUnread)
                Column(
                  children: [
                    _buildUnreadIndicator(),
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

  /// Constrói ícone do sistema
  Widget _buildIcon(String? type) {
    IconData icon;
    Color color;
    Color backgroundColor;

    switch (type) {
      case 'certification_approved':
        icon = Icons.verified;
        color = Colors.green.shade600;
        backgroundColor = Colors.green.shade100;
        break;
      case 'certification_rejected':
        icon = Icons.info_outline;
        color = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade100;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.blue.shade600;
        backgroundColor = Colors.blue.shade100;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  /// Constrói título
  Widget _buildTitle(String? type) {
    String title;
    Color color;

    switch (type) {
      case 'certification_approved':
        title = '🎉 Certificação Aprovada!';
        color = Colors.green.shade700;
        break;
      case 'certification_rejected':
        title = 'Certificação Pendente';
        color = Colors.orange.shade700;
        break;
      default:
        title = notification['title'] ?? 'Notificação do Sistema';
        color = Colors.blue.shade700;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  /// Constrói mensagem
  Widget _buildMessage() {
    final message = notification['message'] ?? 
                   notification['body'] ?? 
                   'Você tem uma nova notificação';

    return Text(
      message,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Constrói timestamp
  Widget _buildTimestamp() {
    final createdAt = notification['createdAt'];
    if (createdAt == null) return const SizedBox.shrink();
    
    DateTime timestamp;
    if (createdAt is Timestamp) {
      timestamp = createdAt.toDate();
    } else if (createdAt is String) {
      timestamp = DateTime.parse(createdAt);
    } else {
      return const SizedBox.shrink();
    }
    
    final timeAgo = timeago.format(timestamp, locale: 'pt_BR');
    
    return Text(
      timeAgo,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
    );
  }

  /// Verifica se tem ação
  bool _hasAction(String? type) {
    return type == 'certification_approved' || type == 'certification_rejected';
  }

  /// Constrói botão de ação
  Widget _buildActionButton(String? type) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case 'certification_approved':
        label = 'Ver Perfil';
        icon = Icons.person;
        color = Colors.green.shade600;
        break;
      case 'certification_rejected':
        label = 'Tentar Novamente';
        icon = Icons.refresh;
        color = Colors.orange.shade600;
        break;
      default:
        return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
