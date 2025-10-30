import 'package:flutter/material.dart';
import 'dart:async';
import '../services/search_alert_service.dart';
import '../utils/enhanced_logger.dart';

/// Widget de notificação para alertas de busca
/// Exibe alertas em tempo real na interface
class SearchAlertNotification extends StatefulWidget {
  final Widget child;
  final bool showInAppNotifications;
  final Duration notificationDuration;

  const SearchAlertNotification({
    Key? key,
    required this.child,
    this.showInAppNotifications = true,
    this.notificationDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<SearchAlertNotification> createState() =>
      _SearchAlertNotificationState();
}

class _SearchAlertNotificationState extends State<SearchAlertNotification> {
  final SearchAlertService _alertService = SearchAlertService.instance;
  StreamSubscription? _alertSubscription;
  final List<SearchAlert> _displayedAlerts = [];
  OverlayEntry? _currentOverlay;

  @override
  void initState() {
    super.initState();
    _setupAlertListener();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _currentOverlay?.remove();
    super.dispose();
  }

  void _setupAlertListener() {
    _alertService.addAlertCallback(_handleNewAlert);
  }

  void _handleNewAlert(SearchAlert alert) {
    if (!widget.showInAppNotifications) return;
    if (!mounted) return;

    // Evitar alertas duplicados
    if (_displayedAlerts.any((a) => a.id == alert.id)) return;

    _displayedAlerts.add(alert);
    _showAlertOverlay(alert);

    EnhancedLogger.info('Alert notification displayed',
        tag: 'SEARCH_ALERT_NOTIFICATION',
        data: {
          'alertId': alert.id,
          'type': alert.type,
          'severity': alert.severity.toString(),
        });
  }

  void _showAlertOverlay(SearchAlert alert) {
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => _AlertOverlayWidget(
        alert: alert,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _displayedAlerts.removeWhere((a) => a.id == alert.id);
        },
        duration: widget.notificationDuration,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 16,
          child: _AlertBadge(
            alertService: _alertService,
            onTap: () => _showAlertDialog(context),
          ),
        ),
      ],
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AlertDialog(alertService: _alertService),
    );
  }
}

/// Widget de overlay para exibir alerta
class _AlertOverlayWidget extends StatefulWidget {
  final SearchAlert alert;
  final VoidCallback onDismiss;
  final Duration duration;

  const _AlertOverlayWidget({
    required this.alert,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_AlertOverlayWidget> createState() => _AlertOverlayWidgetState();
}

class _AlertOverlayWidgetState extends State<_AlertOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startDismissTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _startDismissTimer() {
    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getAlertColor(widget.alert.severity),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getAlertBorderColor(widget.alert.severity),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAlertIcon(widget.alert.severity),
                        color: _getAlertIconColor(widget.alert.severity),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.alert.type,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.alert.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red[50]!;
      case AlertSeverity.warning:
        return Colors.orange[50]!;
      case AlertSeverity.info:
        return Colors.blue[50]!;
    }
  }

  Color _getAlertBorderColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
        return Icons.info;
    }
  }

  Color _getAlertIconColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }
}

/// Badge de alertas no canto da tela
class _AlertBadge extends StatefulWidget {
  final SearchAlertService alertService;
  final VoidCallback onTap;

  const _AlertBadge({
    required this.alertService,
    required this.onTap,
  });

  @override
  State<_AlertBadge> createState() => _AlertBadgeState();
}

class _AlertBadgeState extends State<_AlertBadge> {
  Timer? _updateTimer;
  int _alertCount = 0;
  AlertSeverity? _highestSeverity;

  @override
  void initState() {
    super.initState();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateAlertCount();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateAlertCount();
    });
  }

  void _updateAlertCount() {
    final alerts = widget.alertService.getActiveAlerts();
    final criticalAlerts =
        widget.alertService.getAlertsBySeverity(AlertSeverity.critical);
    final warningAlerts =
        widget.alertService.getAlertsBySeverity(AlertSeverity.warning);

    AlertSeverity? severity;
    if (criticalAlerts.isNotEmpty) {
      severity = AlertSeverity.critical;
    } else if (warningAlerts.isNotEmpty) {
      severity = AlertSeverity.warning;
    } else if (alerts.isNotEmpty) {
      severity = AlertSeverity.info;
    }

    if (mounted) {
      setState(() {
        _alertCount = alerts.length;
        _highestSeverity = severity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alertCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getBadgeColor(),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getBadgeIcon(),
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _alertCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (_highestSeverity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
      case null:
        return Colors.grey;
    }
  }

  IconData _getBadgeIcon() {
    switch (_highestSeverity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
        return Icons.info;
      case null:
        return Icons.notifications;
    }
  }
}

/// Dialog para exibir todos os alertas
class _AlertDialog extends StatelessWidget {
  final SearchAlertService alertService;

  const _AlertDialog({required this.alertService});

  @override
  Widget build(BuildContext context) {
    final alerts = alertService.getActiveAlerts();

    return AlertDialog(
      title: const Text('Alertas de Busca'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: alerts.isEmpty
            ? const Center(
                child: Text('Nenhum alerta ativo'),
              )
            : ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getAlertIcon(alert.severity),
                        color: _getAlertColor(alert.severity),
                      ),
                      title: Text(
                        alert.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.message),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(alert.timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          alertService.resolveAlert(alert.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            alertService.clearAllAlerts();
            Navigator.of(context).pop();
          },
          child: const Text('Limpar Todos'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
        return Icons.info;
    }
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}
