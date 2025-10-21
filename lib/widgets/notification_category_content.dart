import 'package:flutter/material.dart';
import 'package:whatsapp_chat/models/notification_category.dart';

/// Widget que exibe o conteúdo de uma categoria de notificações
/// Inclui lista, pull-to-refresh, estados vazios, loading e erro
class NotificationCategoryContent extends StatelessWidget {
  /// Categoria da notificação
  final NotificationCategory category;
  
  /// Lista de notificações (pode ser de qualquer tipo)
  final List<dynamic> notifications;
  
  /// Se está carregando
  final bool isLoading;
  
  /// Callback para refresh
  final Future<void> Function() onRefresh;
  
  /// Callback ao tocar em uma notificação
  final Function(dynamic) onNotificationTap;
  
  /// Callback opcional para deletar notificação
  final Function(dynamic)? onNotificationDelete;
  
  /// Mensagem de erro (se houver)
  final String? errorMessage;
  
  /// Builder customizado para item de notificação
  final Widget Function(BuildContext, dynamic, int)? itemBuilder;

  const NotificationCategoryContent({
    Key? key,
    required this.category,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
    required this.onNotificationTap,
    this.onNotificationDelete,
    this.errorMessage,
    this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Estado de erro
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return _buildErrorState(context);
    }
    
    // Estado de loading inicial
    if (isLoading && notifications.isEmpty) {
      return _buildLoadingState();
    }
    
    // Estado vazio
    if (notifications.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Lista de notificações
    return _buildNotificationList(context);
  }

  /// Constrói a lista de notificações com pull-to-refresh
  Widget _buildNotificationList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: category.color,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          
          // Usar builder customizado se fornecido
          if (itemBuilder != null) {
            return itemBuilder!(context, notification, index);
          }
          
          // Builder padrão simples
          return _buildDefaultNotificationItem(context, notification, index);
        },
      ),
    );
  }

  /// Constrói item de notificação padrão (placeholder)
  Widget _buildDefaultNotificationItem(BuildContext context, dynamic notification, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone da categoria
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificação ${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conteúdo da notificação',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botão de deletar (se fornecido)
              if (onNotificationDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => onNotificationDelete!(notification),
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói estado vazio
  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: category.color,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone grande
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 50,
                    color: category.color.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                Text(
                  category.emptyStateTitle,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Mensagem
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    category.emptyStateMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Dica de pull-to-refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Puxe para atualizar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói estado de loading
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(category.color),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando notificações...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone de erro
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            
            // Título
            Text(
              'Erro ao carregar notificações',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Mensagem de erro
            Text(
              errorMessage ?? 'Ocorreu um erro desconhecido',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Botão de tentar novamente
            ElevatedButton.icon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: category.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de shimmer effect para loading incremental
class NotificationShimmerItem extends StatefulWidget {
  final NotificationCategory category;

  const NotificationShimmerItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<NotificationShimmerItem> createState() => _NotificationShimmerItemState();
}

class _NotificationShimmerItemState extends State<NotificationShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar shimmer
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment(_animation.value - 1, 0),
                      end: Alignment(_animation.value, 0),
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade100,
                        Colors.grey.shade300,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Conteúdo shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment(_animation.value - 1, 0),
                            end: Alignment(_animation.value, 0),
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade100,
                              Colors.grey.shade300,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment(_animation.value - 1, 0),
                            end: Alignment(_animation.value, 0),
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade100,
                              Colors.grey.shade300,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
