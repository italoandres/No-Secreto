import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/interest_notification_model.dart';
import '../services/interest_system_integrator.dart';
import '../services/interest_cache_service.dart';
import '../services/profile_navigation_service.dart';
import '../theme.dart';
import '../utils/enhanced_logger.dart';

/// Componente de notificações de interesse com cache
class CachedInterestNotificationsComponent extends StatefulWidget {
  final bool showHeader;
  final int maxNotifications;
  final VoidCallback? onNotificationTap;

  const CachedInterestNotificationsComponent({
    Key? key,
    this.showHeader = true,
    this.maxNotifications = 10,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  State<CachedInterestNotificationsComponent> createState() => 
      _CachedInterestNotificationsComponentState();
}

class _CachedInterestNotificationsComponentState 
    extends State<CachedInterestNotificationsComponent> {
  
  final InterestSystemIntegrator _integrator = InterestSystemIntegrator();
  final InterestCacheService _cacheService = InterestCacheService();
  final ProfileNavigationService _navigationService = ProfileNavigationService();
  
  List<InterestNotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingFromCache = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // 1. Carregar do cache primeiro (resposta rápida)
      await _loadFromCache();
      
      // 2. Verificar se precisa sincronizar
      final isStale = await _cacheService.isCacheStale();
      
      if (isStale) {
        // 3. Sincronizar com Firebase se necessário
        await _syncWithFirebase();
      }
      
    } catch (e) {
      EnhancedLogger.error('Erro ao carregar notificações: $e', 
        tag: 'CACHED_NOTIFICATIONS'
      );
      setState(() {
        _errorMessage = 'Erro ao carregar notificações';
        _isLoading = false;
        _isLoadingFromCache = false;
      });
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedNotifications = await _cacheService.getCachedNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = cachedNotifications
              .take(widget.maxNotifications)
              .toList();
          _isLoadingFromCache = false;
        });
      }
      
      EnhancedLogger.info('Notificações carregadas do cache', 
        tag: 'CACHED_NOTIFICATIONS',
        data: {'count': cachedNotifications.length}
      );
    } catch (e) {
      EnhancedLogger.error('Erro ao carregar do cache: $e', 
        tag: 'CACHED_NOTIFICATIONS'
      );
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Obter notificações do Firebase
      final stream = _integrator.getMyInterestNotifications();
      final notifications = await stream.first;

      // Salvar no cache
      await _cacheService.cacheNotifications(notifications);

      if (mounted) {
        setState(() {
          _notifications = notifications
              .take(widget.maxNotifications)
              .toList();
          _isLoading = false;
        });
      }

      EnhancedLogger.info('Notificações sincronizadas com Firebase', 
        tag: 'CACHED_NOTIFICATIONS',
        data: {'count': notifications.length}
      );
    } catch (e) {
      EnhancedLogger.error('Erro ao sincronizar com Firebase: $e', 
        tag: 'CACHED_NOTIFICATIONS'
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Forçar sincronização
    await _syncWithFirebase();
  }

  Future<void> _respondToNotification(
    InterestNotificationModel notification,
    InterestStatus response,
  ) async {
    final success = await _integrator.respondToInterest(
      notificationId: notification.id,
      response: response,
    );

    if (success) {
      // Atualizar localmente
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(status: response);
        }
      });

      // Atualizar cache
      await _cacheService.cacheNotifications(_notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (widget.showHeader) _buildHeader(),
          
          // Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notificações de Interesse',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Indicador de cache/loading
          if (_isLoadingFromCache)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_isLoading)
            const Icon(Icons.sync, color: Colors.white, size: 20)
          else
            IconButton(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isLoadingFromCache && _notifications.isEmpty) {
      return _buildLoadingState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNotificationsList();
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando notificações...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshNotifications,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma notificação de interesse',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quando alguém demonstrar interesse no seu perfil, você verá aqui',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(InterestNotificationModel notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da notificação
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  notification.fromUserName.isNotEmpty 
                    ? notification.fromUserName[0].toUpperCase()
                    : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.fromUserName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator
              _buildStatusIndicator(notification.status),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Botões de ação
          if (notification.status == InterestStatus.pending)
            _buildActionButtons(notification),
          
          // Timestamp
          const SizedBox(height: 8),
          Text(
            _formatTimestamp(notification.timestamp),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(InterestStatus status) {
    switch (status) {
      case InterestStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pendente',
            style: TextStyle(color: Colors.orange, fontSize: 10),
          ),
        );
      case InterestStatus.accepted:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case InterestStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
    }
  }

  Widget _buildActionButtons(InterestNotificationModel notification) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _respondToNotification(notification, InterestStatus.accepted),
            icon: const Icon(Icons.favorite, size: 16),
            label: const Text('Também Tenho'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigationService.navigateFromInterestNotification(
              userId: notification.fromUserId,
              userName: notification.fromUserName,
              notificationId: notification.id,
            ),
            icon: const Icon(Icons.person, size: 16),
            label: const Text('Ver Perfil'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _respondToNotification(notification, InterestStatus.rejected),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Não Tenho'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}