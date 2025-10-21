import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/models/notification_category.dart';
import 'package:whatsapp_chat/controllers/unified_notification_controller.dart';
import 'package:whatsapp_chat/widgets/notification_category_tab.dart';
import 'package:whatsapp_chat/widgets/notification_category_content.dart';
import 'package:whatsapp_chat/widgets/notification_item_factory.dart';
import 'package:whatsapp_chat/repositories/interest_notification_repository.dart';
import 'package:whatsapp_chat/views/story_favorites_view.dart';

/// View principal do sistema unificado de notificações
/// Exibe 3 categorias: Stories, Interesse/Match e Sistema
class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UnifiedNotificationController _controller;

  // Índices das categorias
  static const int STORIES_TAB = 0;
  static const int INTEREST_TAB = 1;
  static const int SYSTEM_TAB = 2;

  @override
  void initState() {
    super.initState();
    
    // Inicializar TabController
    _tabController = TabController(length: 3, vsync: this);
    
    // Inicializar controller GetX
    _controller = Get.put(UnifiedNotificationController());
    
    // Sincronizar TabController com controller
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.switchCategory(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<UnifiedNotificationController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barra de categorias
          _buildCategoryBar(),
          
          // Conteúdo das categorias
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  /// Constrói AppBar com badge total
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Notificações',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.amber.shade700,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        // Botão de Stories Salvos (Bookmark)
        IconButton(
          onPressed: () {
            // Navegar para stories salvos
            final contexto = 'principal';
            
            print('🔖 Abrindo stories salvos - contexto: $contexto');
            
            // Navegar para StoryFavoritesView
            Get.to(() => StoryFavoritesView(contexto: contexto));
          },
          icon: const Icon(Icons.bookmark, color: Colors.white),
          tooltip: 'Stories Salvos',
        ),
        
        // Botão Marcar todas como lidas com Badge total
        Obx(() {
          final totalBadge = _controller.getTotalBadgeCount();
          
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  // Marcar categoria atual como lida
                  final category = _controller.getActiveCategory();
                  _controller.markCategoryAsRead(category);
                  
                  Get.snackbar(
                    'Sucesso',
                    'Notificações marcadas como lidas',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
                icon: const Icon(Icons.done_all, color: Colors.white),
                tooltip: 'Marcar todas como lidas',
              ),
              
              if (totalBadge > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      totalBadge > 99 ? '99+' : totalBadge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
        
        const SizedBox(width: 8),
      ],
    );
  }

  /// Constrói barra de categorias horizontais
  Widget _buildCategoryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            // Tab Stories
            Expanded(
              child: NotificationCategoryTab(
                category: NotificationCategory.stories,
                badgeCount: _controller.storiesBadgeCount.value,
                isActive: _controller.activeCategory.value == STORIES_TAB,
                onTap: () => _tabController.animateTo(STORIES_TAB),
              ),
            ),
            const SizedBox(width: 8),
            
            // Tab Interesse
            Expanded(
              child: NotificationCategoryTab(
                category: NotificationCategory.interest,
                badgeCount: _controller.interestBadgeCount.value,
                isActive: _controller.activeCategory.value == INTEREST_TAB,
                onTap: () => _tabController.animateTo(INTEREST_TAB),
              ),
            ),
            const SizedBox(width: 8),
            
            // Tab Sistema
            Expanded(
              child: NotificationCategoryTab(
                category: NotificationCategory.system,
                badgeCount: _controller.systemBadgeCount.value,
                isActive: _controller.activeCategory.value == SYSTEM_TAB,
                onTap: () => _tabController.animateTo(SYSTEM_TAB),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Constrói TabBarView com conteúdo das categorias
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Stories
        _buildStoriesContent(),
        
        // Interesse/Match
        _buildInterestContent(),
        
        // Sistema
        _buildSystemContent(),
      ],
    );
  }

  /// Constrói conteúdo da categoria Stories
  Widget _buildStoriesContent() {
    return Obx(() {
      return NotificationCategoryContent(
        category: NotificationCategory.stories,
        notifications: _controller.storiesNotifications,
        isLoading: _controller.isLoading.value,
        errorMessage: _controller.errorMessage.value,
        onRefresh: () => _controller.refreshCategory(NotificationCategory.stories),
        onNotificationTap: _handleStoryNotificationTap,
        onNotificationDelete: _handleStoryNotificationDelete,
        itemBuilder: (context, notification, index) {
          return NotificationItemFactory.createNotificationItem(
            category: NotificationCategory.stories,
            notification: notification,
            onTap: _handleStoryNotificationTap,
            onDelete: _handleStoryNotificationDelete,
          );
        },
      );
    });
  }

  /// Constrói conteúdo da categoria Interesse
  Widget _buildInterestContent() {
    return Obx(() {
      return NotificationCategoryContent(
        category: NotificationCategory.interest,
        notifications: _controller.interestNotifications,
        isLoading: _controller.isLoading.value,
        errorMessage: _controller.errorMessage.value,
        onRefresh: () => _controller.refreshCategory(NotificationCategory.interest),
        onNotificationTap: _handleInterestNotificationTap,
        onNotificationDelete: _handleInterestNotificationDelete,
        itemBuilder: (context, notification, index) {
          return NotificationItemFactory.createNotificationItem(
            category: NotificationCategory.interest,
            notification: notification,
            onTap: _handleInterestNotificationTap,
            onDelete: _handleInterestNotificationDelete,
          );
        },
      );
    });
  }

  /// Constrói conteúdo da categoria Sistema
  Widget _buildSystemContent() {
    return Obx(() {
      return NotificationCategoryContent(
        category: NotificationCategory.system,
        notifications: _controller.systemNotifications,
        isLoading: _controller.isLoading.value,
        errorMessage: _controller.errorMessage.value,
        onRefresh: () => _controller.refreshCategory(NotificationCategory.system),
        onNotificationTap: _handleSystemNotificationTap,
        onNotificationDelete: _handleSystemNotificationDelete,
        itemBuilder: (context, notification, index) {
          return NotificationItemFactory.createNotificationItem(
            category: NotificationCategory.system,
            notification: notification,
            onTap: _handleSystemNotificationTap,
            onDelete: _handleSystemNotificationDelete,
          );
        },
      );
    });
  }

  // ==================== HANDLERS DE AÇÕES ====================

  /// Handler para tap em notificação de story
  void _handleStoryNotificationTap(dynamic notification) {
    try {
      print('📖 Tap em notificação de story: ${notification.id}');
      
      // Aqui você pode navegar para o story específico
      // Por exemplo: Get.toNamed('/story/${notification.storyId}');
      
      // Marcar como lida
      // NotificationRepository.markAsRead(notification.id);
      
      Get.snackbar(
        'Story',
        'Navegando para o story...',
        backgroundColor: Colors.amber.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ Erro ao abrir notificação de story: $e');
      _showErrorSnackbar('Erro ao abrir notificação');
    }
  }

  /// Handler para deletar notificação de story
  void _handleStoryNotificationDelete(dynamic notification) async {
    try {
      final confirmed = await _showDeleteConfirmation();
      if (confirmed != true) return;
      
      // NotificationRepository.deleteNotification(notification.id);
      
      Get.snackbar(
        'Sucesso',
        'Notificação excluída',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ Erro ao deletar notificação: $e');
      _showErrorSnackbar('Erro ao excluir notificação');
    }
  }

  /// Handler para tap em notificação de interesse
  void _handleInterestNotificationTap(dynamic notification) async {
    try {
      print('💕 Tap em notificação de interesse: ${notification.id}');
      
      // Navegar para Interest Dashboard (Vitrine de Propósito)
      // onde ficam as notificações oficiais de interesse
      Get.toNamed('/interest-dashboard');
      
      Get.snackbar(
        '✨ Vitrine de Propósito',
        'Descubra quem tem interesse em você!',
        backgroundColor: Colors.purple.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.storefront, color: Colors.white),
      );
      
    } catch (e) {
      print('❌ Erro ao abrir notificação de interesse: $e');
      _showErrorSnackbar('Erro ao abrir notificação');
    }
  }

  /// Handler para responder interesse (aceitar/rejeitar)
  Future<void> _handleInterestResponse(dynamic notification, bool accept) async {
    try {
      final action = accept ? 'accepted' : 'rejected';
      
      await InterestNotificationRepository.respondToInterestNotification(
        notification.id!,
        action,
      );
      
      Get.snackbar(
        accept ? 'Interesse Aceito!' : 'Interesse Rejeitado',
        accept 
            ? 'Você aceitou o interesse de ${notification.fromUserName}' 
            : 'Você rejeitou o interesse',
        backgroundColor: accept ? Colors.green : Colors.grey.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      print('❌ Erro ao responder interesse: $e');
      _showErrorSnackbar('Erro ao responder interesse');
    }
  }

  /// Handler para deletar notificação de interesse
  void _handleInterestNotificationDelete(dynamic notification) async {
    try {
      final confirmed = await _showDeleteConfirmation();
      if (confirmed != true) return;
      
      // Implementar delete
      
      Get.snackbar(
        'Sucesso',
        'Notificação excluída',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ Erro ao deletar notificação: $e');
      _showErrorSnackbar('Erro ao excluir notificação');
    }
  }

  /// Handler para tap em notificação de sistema
  void _handleSystemNotificationTap(dynamic notification) async {
    try {
      print('⚙️ Tap em notificação de sistema: ${notification['id']}');
      
      final type = notification['type'];
      final notificationId = notification['id'] as String?;
      final userId = notification['userId'] as String?;
      
      // Marcar como lida ANTES de navegar
      if (notificationId != null) {
        await _controller.markSystemNotificationAsRead(notificationId);
        print('✅ Notificação marcada como lida: $notificationId');
      }
      
      if (type == 'certification_approved') {
        // Sempre passar o userId (da notificação ou do usuário atual)
        final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
        
        if (targetUserId != null && targetUserId.isNotEmpty) {
          Get.toNamed('/vitrine-display', arguments: {
            'userId': targetUserId,
            'isOwnProfile': true,
          });
          print('📱 Navegando para vitrine-display com userId: $targetUserId');
        } else {
          _showErrorSnackbar('Erro: ID do usuário não encontrado');
          return;
        }
        
        Get.snackbar(
          '🎉 Certificação Aprovada',
          'Veja seu perfil na vitrine!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
      } else if (type == 'certification_rejected') {
        // Navegar para tela de certificação
        Get.toNamed('/spiritual-certification-request');
        
        Get.snackbar(
          'Certificação Pendente',
          'Navegando para solicitar novamente...',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
      } else {
        Get.snackbar(
          'Sistema',
          'Notificação do sistema',
          backgroundColor: Colors.blue.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      
    } catch (e) {
      print('❌ Erro ao abrir notificação de sistema: $e');
      _showErrorSnackbar('Erro ao abrir notificação');
    }
  }

  /// Handler para deletar notificação de sistema
  void _handleSystemNotificationDelete(dynamic notification) async {
    try {
      final confirmed = await _showDeleteConfirmation();
      if (confirmed != true) return;
      
      // Implementar delete
      
      Get.snackbar(
        'Sucesso',
        'Notificação excluída',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ Erro ao deletar notificação: $e');
      _showErrorSnackbar('Erro ao excluir notificação');
    }
  }

  // ==================== DIÁLOGOS ====================

  /// Mostra diálogo de confirmação de exclusão
  Future<bool?> _showDeleteConfirmation() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir Notificação'),
        content: const Text('Tem certeza que deseja excluir esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo de ação para interesse
  Future<bool?> _showInterestActionDialog(dynamic notification) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text('${notification.fromUserName} tem interesse em você'),
        content: Text(notification.message ?? 'Demonstrou interesse em conhecer você melhor'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Rejeitar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
            ),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }

  /// Mostra snackbar de erro
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erro',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}
