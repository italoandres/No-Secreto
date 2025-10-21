import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_data.dart';
import '../services/notification_orchestrator.dart';
import '../services/chat_system_manager.dart';
import '../views/romantic_match_chat_view.dart';

/// Card de notificação para matches mútuos
class MutualMatchNotificationCard extends StatefulWidget {
  final NotificationData notification;
  final VoidCallback? onProfileView;
  final VoidCallback? onChatOpen;
  final VoidCallback? onNotificationUpdate;

  const MutualMatchNotificationCard({
    Key? key,
    required this.notification,
    this.onProfileView,
    this.onChatOpen,
    this.onNotificationUpdate,
  }) : super(key: key);

  @override
  State<MutualMatchNotificationCard> createState() => _MutualMatchNotificationCardState();
}

class _MutualMatchNotificationCardState extends State<MutualMatchNotificationCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.pink.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.withOpacity(0.1),
              Colors.purple.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildMessage(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              if (widget.notification.timeAgo.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTimeStamp(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MATCH MÚTUO! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              Text(
                'com ${widget.notification.fromUserName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (!widget.notification.isViewed)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.pink,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.pink.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '💕',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.notification.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleViewProfile,
            icon: const Icon(Icons.person, size: 18),
            label: const Text('Ver Perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleStartChat,
            icon: _isLoading 
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.chat, size: 18),
            label: Text(_isLoading ? 'Preparando...' : 'Conversar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStamp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          widget.notification.timeAgo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Future<void> _handleViewProfile() async {
    try {
      // Marcar notificação como visualizada
      await NotificationOrchestrator.markAsViewed(widget.notification.id);
      
      // Chamar callback de visualização de perfil
      widget.onProfileView?.call();
      
      // Atualizar estado da notificação
      widget.onNotificationUpdate?.call();
      
    } catch (e) {
      print('❌ Erro ao visualizar perfil: $e');
      _showErrorSnackBar('Erro ao abrir perfil. Tente novamente.');
    }
  }

  Future<void> _handleStartChat() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Marcar notificação como visualizada
      await NotificationOrchestrator.markAsViewed(widget.notification.id);
      
      // Obter ID do chat dos metadados ou gerar
      String? chatId = widget.notification.chatId;
      
      if (chatId == null) {
        // Gerar ID determinístico do chat
        final otherUserId = widget.notification.otherUserId ?? widget.notification.fromUserId;
        chatId = 'match_${widget.notification.toUserId}_$otherUserId';
      }
      
      // Garantir que o chat existe
      await ChatSystemManager.ensureChatExists(chatId);
      
      // Navegar para a view de chat romântico
      Get.to(
        () => RomanticMatchChatView(
          chatId: chatId!,
          otherUserId: widget.notification.fromUserId,
          otherUserName: widget.notification.fromUserName,
          otherUserPhotoUrl: widget.notification.fromUserPhotoUrl,
        ),
        transition: Transition.rightToLeft,
      );
      
      // Chamar callback de abertura do chat
      widget.onChatOpen?.call();
      
      // Atualizar estado da notificação
      widget.onNotificationUpdate?.call();
      
    } catch (e) {
      print('❌ Erro ao abrir chat: $e');
      _showErrorSnackBar('Erro ao preparar chat. Tente novamente em alguns segundos.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Card simplificado para lista de notificações
class MutualMatchNotificationListTile extends StatelessWidget {
  final NotificationData notification;
  final VoidCallback? onTap;

  const MutualMatchNotificationListTile({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.pink,
          size: 20,
        ),
      ),
      title: Text(
        'MATCH MÚTUO! 🎉',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: notification.isViewed ? Colors.grey[600] : Colors.pink,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('com ${notification.fromUserName}'),
          const SizedBox(height: 4),
          Text(
            notification.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!notification.isViewed)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}