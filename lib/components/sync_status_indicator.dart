import 'package:flutter/material.dart';
import '../services/ui_state_manager.dart';

/// Indicador visual de status de sincronização
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showText;

  const SyncStatusIndicator({
    Key? key,
    required this.status,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          if (showText) ...[
            const SizedBox(width: 8),
            _buildText(context),
          ],
          if (status == SyncStatus.error && onRetry != null) ...[
            const SizedBox(width: 8),
            _buildRetryButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
        ),
      );
    }

    return Icon(
      _getIconData(),
      size: 16,
      color: _getIconColor(),
    );
  }

  Widget _buildText(BuildContext context) {
    return Text(
      _getStatusText(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _getTextColor(),
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Tentar novamente',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (status) {
      case SyncStatus.idle:
        return Icons.sync_disabled;
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
    }
  }

  Color _getIconColor() {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey[600]!;
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return Colors.blue[600]!;
      case SyncStatus.success:
        return Colors.green[600]!;
      case SyncStatus.error:
        return Colors.red[600]!;
    }
  }

  Color _getBackgroundColor() {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey[100]!;
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return Colors.blue[50]!;
      case SyncStatus.success:
        return Colors.green[50]!;
      case SyncStatus.error:
        return Colors.red[50]!;
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey[300]!;
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return Colors.blue[200]!;
      case SyncStatus.success:
        return Colors.green[200]!;
      case SyncStatus.error:
        return Colors.red[200]!;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey[700]!;
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return Colors.blue[700]!;
      case SyncStatus.success:
        return Colors.green[700]!;
      case SyncStatus.error:
        return Colors.red[700]!;
    }
  }

  String _getStatusText() {
    switch (status) {
      case SyncStatus.idle:
        return 'Inativo';
      case SyncStatus.loading:
        return 'Carregando...';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.success:
        return 'Sincronizado';
      case SyncStatus.error:
        return errorMessage ?? 'Erro na sincronização';
    }
  }
}

/// Widget de feedback para notificações
class NotificationFeedback extends StatelessWidget {
  final int notificationCount;
  final bool hasNewNotifications;
  final VoidCallback? onTap;

  const NotificationFeedback({
    Key? key,
    required this.notificationCount,
    required this.hasNewNotifications,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notificationCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhuma notificação',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Você será notificado quando alguém demonstrar interesse',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasNewNotifications ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasNewNotifications ? Colors.blue[200]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasNewNotifications ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasNewNotifications ? Icons.notifications_active : Icons.notifications,
                size: 20,
                color: hasNewNotifications ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$notificationCount ${notificationCount == 1 ? 'notificação' : 'notificações'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasNewNotifications ? Colors.blue[800] : Colors.grey[700],
                    ),
                  ),
                  if (hasNewNotifications) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Toque para visualizar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasNewNotifications)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de loading para notificações
class NotificationLoadingIndicator extends StatelessWidget {
  final String? message;

  const NotificationLoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message ?? 'Carregando notificações...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}