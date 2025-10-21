import 'package:flutter/material.dart';
import '../models/real_notification_model.dart';
import '../services/ui_state_manager.dart';
import '../services/unified_notification_interface.dart';
import 'sync_status_indicator.dart';
import '../utils/enhanced_logger.dart';

/// Widget unificado de notificações com estado gerenciado
class UnifiedNotificationWidget extends StatefulWidget {
  final String userId;
  final bool showSyncStatus;
  final bool showRefreshButton;
  final Function(RealNotificationModel)? onNotificationTap;
  final VoidCallback? onRefresh;

  const UnifiedNotificationWidget({
    Key? key,
    required this.userId,
    this.showSyncStatus = true,
    this.showRefreshButton = true,
    this.onNotificationTap,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<UnifiedNotificationWidget> createState() => _UnifiedNotificationWidgetState();
}

class _UnifiedNotificationWidgetState extends State<UnifiedNotificationWidget> {
  final UIStateManager _uiStateManager = UIStateManager();
  final UnifiedNotificationInterface _unifiedInterface = UnifiedNotificationInterface();

  @override
  void initState() {
    super.initState();
    EnhancedLogger.log('🎨 [UNIFIED_WIDGET] Inicializando para: ${widget.userId}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NotificationUIState>(
      stream: _uiStateManager.getUIStateStream(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const NotificationLoadingIndicator(
            message: 'Inicializando sistema de notificações...',
          );
        }

        final state = snapshot.data!;
        
        return Column(
          children: [
            if (widget.showSyncStatus) _buildSyncStatusBar(state),
            Expanded(child: _buildNotificationContent(state)),
          ],
        );
      },
    );
  }

  Widget _buildSyncStatusBar(NotificationUIState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          SyncStatusIndicator(
            status: state.syncStatus,
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
            onRetry: () => _handleForceSync(),
          ),
          const Spacer(),
          if (widget.showRefreshButton) _buildRefreshButton(state),
          _buildLastUpdateInfo(state),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(NotificationUIState state) {
    return GestureDetector(
      onTap: state.isLoading ? null : _handleForceSync,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: state.isLoading ? Colors.grey[200] : Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: state.isLoading ? Colors.grey[300]! : Colors.blue[200]!,
          ),
        ),
        child: Icon(
          Icons.refresh,
          size: 16,
          color: state.isLoading ? Colors.grey[500] : Colors.blue[600],
        ),
      ),
    );
  }

  Widget _buildLastUpdateInfo(NotificationUIState state) {
    final timeDiff = DateTime.now().difference(state.lastUpdate);
    String timeText;
    
    if (timeDiff.inMinutes < 1) {
      timeText = 'agora';
    } else if (timeDiff.inMinutes < 60) {
      timeText = '${timeDiff.inMinutes}min';
    } else {
      timeText = '${timeDiff.inHours}h';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        'Atualizado $timeText',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildNotificationContent(NotificationUIState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const NotificationLoadingIndicator();
    }

    if (state.hasError && state.notifications.isEmpty) {
      return _buildErrorState(state);
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNotificationList(state);
  }

  Widget _buildErrorState(NotificationUIState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar notificações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? 'Erro desconhecido',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleForceSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const NotificationFeedback(
      notificationCount: 0,
      hasNewNotifications: false,
    );
  }

  Widget _buildNotificationList(NotificationUIState state) {
    return Column(
      children: [
        NotificationFeedback(
          notificationCount: state.totalCount,
          hasNewNotifications: state.syncStatus == SyncStatus.synced,
          onTap: () {
            // Scroll para primeira notificação ou ação personalizada
          },
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _buildNotificationItem(notification);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(RealNotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: notification.fromUserPhoto != null
              ? NetworkImage(notification.fromUserPhoto!)
              : null,
          backgroundColor: Colors.blue[100],
          child: notification.fromUserPhoto == null
              ? Icon(Icons.person, color: Colors.blue[600])
              : null,
        ),
        title: Text(
          notification.fromUserName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: notification.count > 1
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notification.count}x',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              )
            : null,
        onTap: () {
          widget.onNotificationTap?.call(notification);
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'agora';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min atrás';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h atrás';
    } else {
      return '${diff.inDays}d atrás';
    }
  }

  Future<void> _handleForceSync() async {
    EnhancedLogger.log('🚀 [UNIFIED_WIDGET] Forçando sincronização');
    
    try {
      await _uiStateManager.forceSync(widget.userId);
      widget.onRefresh?.call();
    } catch (e) {
      EnhancedLogger.log('❌ [UNIFIED_WIDGET] Erro na sincronização: $e');
    }
  }

  @override
  void dispose() {
    EnhancedLogger.log('🧹 [UNIFIED_WIDGET] Disposing para: ${widget.userId}');
    super.dispose();
  }
}