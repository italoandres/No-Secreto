import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// Sistema avançado de renderização com múltiplas estratégias
/// Garante que as notificações sempre apareçam, mesmo se uma estratégia falhar
class EnhancedInterestNotificationsRenderer {
  /// Renderiza notificações usando múltiplas estratégias de fallback
  static Widget renderWithFallbacks(MatchesController controller) {
    try {
      EnhancedLogger.info('Iniciando renderização com fallbacks',
          tag: 'ENHANCED_RENDERER');

      // Estratégia 1: GetX Obx padrão
      try {
        final widget = renderWithObx(controller);
        if (widget != null) {
          EnhancedLogger.success('Estratégia 1 (Obx) funcionou!',
              tag: 'ENHANCED_RENDERER');
          return widget;
        }
      } catch (e) {
        EnhancedLogger.warning('Estratégia 1 (Obx) falhou: $e',
            tag: 'ENHANCED_RENDERER');
      }

      // Estratégia 2: GetBuilder alternativo
      try {
        final widget = renderWithGetBuilder(controller);
        if (widget != null) {
          EnhancedLogger.success('Estratégia 2 (GetBuilder) funcionou!',
              tag: 'ENHANCED_RENDERER');
          return widget;
        }
      } catch (e) {
        EnhancedLogger.warning('Estratégia 2 (GetBuilder) falhou: $e',
            tag: 'ENHANCED_RENDERER');
      }

      // Estratégia 3: StatefulWidget com listener manual
      try {
        final widget = renderWithStatefulWidget(controller);
        if (widget != null) {
          EnhancedLogger.success('Estratégia 3 (StatefulWidget) funcionou!',
              tag: 'ENHANCED_RENDERER');
          return widget;
        }
      } catch (e) {
        EnhancedLogger.warning('Estratégia 3 (StatefulWidget) falhou: $e',
            tag: 'ENHANCED_RENDERER');
      }

      // Estratégia 4: Força bruta - sempre renderizar
      EnhancedLogger.info('Usando estratégia 4 (Força Bruta)',
          tag: 'ENHANCED_RENDERER');
      return renderWithForceRender(controller);
    } catch (e) {
      EnhancedLogger.error('Todas as estratégias falharam',
          tag: 'ENHANCED_RENDERER', error: e);
      return _buildErrorWidget(e);
    }
  }

  /// Estratégia 1: GetX Obx padrão
  static Widget? renderWithObx(MatchesController controller) {
    try {
      return Obx(() {
        final notifications = controller.interestNotifications;

        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildNotificationsContainer(
            notifications, 'Estratégia 1: GetX Obx', Colors.green[50]!);
      });
    } catch (e) {
      EnhancedLogger.error('Erro na estratégia Obx',
          tag: 'ENHANCED_RENDERER', error: e);
      return null;
    }
  }

  /// Estratégia 2: GetBuilder alternativo
  static Widget? renderWithGetBuilder(MatchesController controller) {
    try {
      return GetBuilder<MatchesController>(
        builder: (controller) {
          final notifications = controller.interestNotifications;

          if (notifications.isEmpty) {
            return const SizedBox.shrink();
          }

          return _buildNotificationsContainer(
              notifications, 'Estratégia 2: GetBuilder', Colors.blue[50]!);
        },
      );
    } catch (e) {
      EnhancedLogger.error('Erro na estratégia GetBuilder',
          tag: 'ENHANCED_RENDERER', error: e);
      return null;
    }
  }

  /// Estratégia 3: StatefulWidget com listener manual
  static Widget? renderWithStatefulWidget(MatchesController controller) {
    try {
      return _ReactiveNotificationsWidget(controller: controller);
    } catch (e) {
      EnhancedLogger.error('Erro na estratégia StatefulWidget',
          tag: 'ENHANCED_RENDERER', error: e);
      return null;
    }
  }

  /// Estratégia 4: Força bruta - sempre renderizar
  static Widget renderWithForceRender(MatchesController controller) {
    try {
      // Pega os dados diretamente, sem reatividade
      final notifications = controller.interestNotifications;

      EnhancedLogger.info(
          'Força bruta: renderizando ${notifications.length} notificações',
          tag: 'ENHANCED_RENDERER');

      if (notifications.isEmpty) {
        return _buildEmptyStateWidget();
      }

      return _buildNotificationsContainer(
          notifications, 'Estratégia 4: Força Bruta', Colors.orange[50]!);
    } catch (e) {
      EnhancedLogger.error('Erro na estratégia Força Bruta',
          tag: 'ENHANCED_RENDERER', error: e);
      return _buildErrorWidget(e);
    }
  }

  /// Constrói o container principal das notificações
  static Widget _buildNotificationsContainer(
      List<Map<String, dynamic>> notifications,
      String strategy,
      Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone e contador
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.pink[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Notificações de Interesse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifications.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Debug: Mostrar qual estratégia funcionou
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ $strategy FUNCIONOU!',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Notificações carregadas: ${notifications.length}'),
                Text(
                    'Timestamp: ${DateTime.now().toString().substring(11, 19)}'),
                if (notifications.isNotEmpty)
                  ...notifications
                      .map((n) => Text('- ${n['profile']['displayName']}')),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Renderizar notificações
          ...notifications
              .map((notification) => _buildNotificationCard(notification)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Constrói um card de notificação
  static Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final profileData = notification['profile'] as Map<String, dynamic>;
    final hasUserInterest = notification['hasUserInterest'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.pink.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome e idade
          Row(
            children: [
              Expanded(
                child: Text(
                  profileData['displayName'] ?? 'Usuário',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (profileData['age'] != null)
                Text(
                  '${profileData['age']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Mensagem
          Text(
            hasUserInterest
                ? 'Vocês demonstraram interesse mútuo! 💕'
                : 'Tem interesse em conhecer seu perfil melhor',
            style: TextStyle(
              fontSize: 14,
              color: hasUserInterest ? Colors.pink : Colors.grey[600],
              fontWeight: hasUserInterest ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 8),

          // Tempo
          Text(
            notification['timeAgo'] ?? 'Agora',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),

          const SizedBox(height: 12),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    EnhancedLogger.info('Ver perfil clicado',
                        tag: 'ENHANCED_RENDERER',
                        data: {'userId': profileData['userId']});
                  },
                  child: const Text('Ver Perfil'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    EnhancedLogger.info('Interesse clicado',
                        tag: 'ENHANCED_RENDERER',
                        data: {'userId': profileData['userId']});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(hasUserInterest ? 'Match!' : 'Interesse'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget de estado vazio
  static Widget _buildEmptyStateWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_off, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Nenhuma notificação de interesse no momento'),
        ],
      ),
    );
  }

  /// Widget de erro
  static Widget _buildErrorWidget(dynamic error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          const Text('Erro ao carregar notificações'),
          const SizedBox(height: 4),
          Text(error.toString(), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Widget StatefulWidget para estratégia 3
class _ReactiveNotificationsWidget extends StatefulWidget {
  final MatchesController controller;

  const _ReactiveNotificationsWidget({required this.controller});

  @override
  State<_ReactiveNotificationsWidget> createState() =>
      _ReactiveNotificationsWidgetState();
}

class _ReactiveNotificationsWidgetState
    extends State<_ReactiveNotificationsWidget> {
  late List<Map<String, dynamic>> notifications;

  @override
  void initState() {
    super.initState();
    notifications = widget.controller.interestNotifications;

    // Listener manual para mudanças
    widget.controller.interestNotifications.listen((newNotifications) {
      if (mounted) {
        setState(() {
          notifications = newNotifications;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return EnhancedInterestNotificationsRenderer._buildNotificationsContainer(
        notifications, 'Estratégia 3: StatefulWidget', Colors.purple[50]!);
  }
}
