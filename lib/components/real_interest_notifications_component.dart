import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../models/real_notification_model.dart';
import '../utils/test_real_notifications.dart';
import '../utils/create_firebase_index_interests.dart';

class RealInterestNotificationsComponent extends StatelessWidget {
  final MatchesController controller = Get.find<MatchesController>();

  RealInterestNotificationsComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com título e botões de debug
        _buildHeader(context),
        
        // Aviso sobre índice Firebase se necessário
        _buildFirebaseIndexWarning(context),
        
        // Lista de notificações reais
        Obx(() => _buildNotificationsList(context)),
        
        // Widget de teste (apenas em debug)
        if (kDebugMode) _buildTestWidget(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red),
          SizedBox(width: 8),
          Text(
            'Notificações Reais de Interesse',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Obx(() => Badge(
            label: Text('${controller.realInterestNotificationsCount.value}'),
            child: Icon(Icons.notifications),
          )),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.refreshRealInterestNotifications(),
            tooltip: 'Atualizar notificações',
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseIndexWarning(BuildContext context) {
    return FutureBuilder<bool>(
      future: CreateFirebaseIndexInterests.checkIndexExists(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          return CreateFirebaseIndexInterests.buildIndexCreationWidget(context);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    if (controller.realInterestNotifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: controller.realInterestNotifications.length,
      itemBuilder: (context, index) {
        final notification = controller.realInterestNotifications[index];
        return _buildNotificationCard(context, notification);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhuma notificação de interesse',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Quando alguém se interessar por você, aparecerá aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.forceLoadRealInterestNotifications(),
            child: Text('Verificar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, RealNotification notification) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: notification.fromUserPhoto != null
              ? NetworkImage(notification.fromUserPhoto!)
              : null,
          child: notification.fromUserPhoto == null
              ? Icon(Icons.person)
              : null,
        ),
        title: Text(
          notification.fromUserName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view_profile',
                  child: Text('Ver perfil'),
                ),
                PopupMenuItem(
                  value: 'accept',
                  child: Text('Aceitar interesse'),
                ),
                PopupMenuItem(
                  value: 'reject',
                  child: Text('Rejeitar'),
                ),
              ],
              onSelected: (value) => _handleNotificationAction(context, notification, value),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(context, notification),
      ),
    );
  }

  Widget _buildTestWidget(BuildContext context) {
    return TestRealNotifications.buildTestWidget(
      context, 
      Get.find<MatchesController>().matches.isNotEmpty 
          ? 'current_user_id' // Substitua pelo ID real do usuário atual
          : 'St2kw3cgX2MMPxlLRmBDjYm2nO22', // ID de teste
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(BuildContext context, RealNotification notification) {
    // Implementar navegação para perfil ou chat
    print('Tapped notification: ${notification.id}');
  }

  void _handleNotificationAction(BuildContext context, RealNotification notification, String action) {
    switch (action) {
      case 'view_profile':
        // Implementar navegação para perfil
        print('View profile: ${notification.fromUserId}');
        break;
      case 'accept':
        // Implementar aceitar interesse
        print('Accept interest: ${notification.id}');
        break;
      case 'reject':
        // Implementar rejeitar interesse
        print('Reject interest: ${notification.id}');
        break;
    }
  }
}

// kDebugMode já está disponível via import 'package:flutter/foundation.dart'