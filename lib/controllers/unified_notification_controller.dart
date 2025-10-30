import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/models/notification_category.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';
import 'package:whatsapp_chat/repositories/notification_repository.dart';
import 'package:whatsapp_chat/repositories/interest_notification_repository.dart';
import 'package:whatsapp_chat/services/certification_notification_service.dart';

/// Controller GetX que gerencia o estado unificado de notificações
/// Agrega notificações de múltiplas fontes e calcula badges em tempo real
class UnifiedNotificationController extends GetxController {
  // ==================== OBSERVABLES ====================

  /// Lista de notificações de stories (curtidas, comentários, menções, respostas)
  final RxList<NotificationModel> storiesNotifications =
      <NotificationModel>[].obs;

  /// Lista de notificações de interesse/match
  final RxList<InterestNotificationModel> interestNotifications =
      <InterestNotificationModel>[].obs;

  /// Lista de notificações do sistema (certificação, atualizações)
  final RxList<Map<String, dynamic>> systemNotifications =
      <Map<String, dynamic>>[].obs;

  /// Contador de badges para categoria Stories
  final RxInt storiesBadgeCount = 0.obs;

  /// Contador de badges para categoria Interesse
  final RxInt interestBadgeCount = 0.obs;

  /// Contador de badges para categoria Sistema
  final RxInt systemBadgeCount = 0.obs;

  /// Contador de notificações não lidas - Stories
  final RxInt storiesUnreadCount = 0.obs;

  /// Contador de notificações não lidas - Interesse
  final RxInt interestUnreadCount = 0.obs;

  /// Contador de notificações não lidas - Sistema
  final RxInt systemUnreadCount = 0.obs;

  /// Estado de loading
  final RxBool isLoading = false.obs;

  /// Mensagem de erro
  final RxString errorMessage = ''.obs;

  /// Índice da categoria ativa (0: Stories, 1: Interesse, 2: Sistema)
  final RxInt activeCategory = 0.obs;

  // ==================== STREAMS ====================

  StreamSubscription<List<NotificationModel>>? _storiesSubscription;
  StreamSubscription<List<InterestNotificationModel>>? _interestSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _systemSubscription;

  // ==================== SERVICES ====================

  final CertificationNotificationService _certificationService =
      CertificationNotificationService();

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    loadAllNotifications();
  }

  @override
  void onClose() {
    _storiesSubscription?.cancel();
    _interestSubscription?.cancel();
    _systemSubscription?.cancel();
    super.onClose();
  }

  // ==================== MÉTODOS DE CARREGAMENTO ====================

  /// Carrega todas as notificações das 3 categorias
  Future<void> loadAllNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        errorMessage.value = 'Usuário não autenticado';
        isLoading.value = false;
        return;
      }

      // Carregar as 3 categorias em paralelo
      await Future.wait([
        _loadStoriesNotifications(userId),
        _loadInterestNotifications(userId),
        _loadSystemNotifications(userId),
      ]);

      isLoading.value = false;
    } catch (e) {
      print('❌ Erro ao carregar notificações: $e');
      errorMessage.value = 'Erro ao carregar notificações: ${e.toString()}';
      isLoading.value = false;
    }
  }

  /// Carrega notificações de stories (curtidas, comentários, menções, respostas)
  Future<void> _loadStoriesNotifications(String userId) async {
    try {
      // Cancelar subscription anterior se existir
      await _storiesSubscription?.cancel();

      // Usar stream existente do NotificationRepository
      _storiesSubscription =
          NotificationRepository.getUserNotifications(userId).listen(
        (notifications) {
          // Filtrar apenas notificações de stories (todos os tipos)
          final storyNotifications = notifications.where((n) {
            final type = n.type;
            return type == 'like' ||
                type == 'comment' ||
                type == 'mention' ||
                type == 'reply' ||
                type == 'comment_like';
          }).toList();

          storiesNotifications.value = storyNotifications;
          _updateStoriesBadgeCount();
        },
        onError: (error) {
          print('❌ Erro no stream de stories: $error');
        },
      );
    } catch (e) {
      print('❌ Erro ao carregar notificações de stories: $e');
      throw e;
    }
  }

  /// Carrega notificações de interesse/match
  Future<void> _loadInterestNotifications(String userId) async {
    try {
      print(
          '🔍 [UNIFIED_CONTROLLER] Iniciando carregamento de notificações de interesse para: $userId');

      // Cancelar subscription anterior se existir
      await _interestSubscription?.cancel();

      // Usar stream existente do InterestNotificationRepository
      _interestSubscription =
          InterestNotificationRepository.getUserInterestNotifications(userId)
              .listen(
        (notifications) {
          print(
              '📊 [UNIFIED_CONTROLLER] Notificações recebidas: ${notifications.length}');

          if (notifications.isNotEmpty) {
            print('📋 [UNIFIED_CONTROLLER] Detalhes das notificações:');
            for (var notif in notifications) {
              print(
                  '   - ID: ${notif.id}, Type: ${notif.type}, Status: ${notif.status}, From: ${notif.fromUserName}');
            }
          } else {
            print('⚠️ [UNIFIED_CONTROLLER] Nenhuma notificação recebida');
          }

          interestNotifications.value = notifications;
          _updateInterestBadgeCount();

          print(
              '✅ [UNIFIED_CONTROLLER] Badge count atualizado: ${interestBadgeCount.value}');
        },
        onError: (error) {
          print('❌ [UNIFIED_CONTROLLER] Erro no stream de interesse: $error');
        },
      );
    } catch (e) {
      print(
          '❌ [UNIFIED_CONTROLLER] Erro ao carregar notificações de interesse: $e');
      throw e;
    }
  }

  /// Carrega notificações do sistema (certificação, atualizações)
  Future<void> _loadSystemNotifications(String userId) async {
    try {
      // Cancelar subscription anterior se existir
      await _systemSubscription?.cancel();

      // Usar stream existente do CertificationNotificationService
      _systemSubscription =
          _certificationService.getAllNotifications(userId).listen(
        (notifications) {
          systemNotifications.value = notifications;
          _updateSystemBadgeCount();
        },
        onError: (error) {
          print('❌ Erro no stream de sistema: $error');
        },
      );
    } catch (e) {
      print('❌ Erro ao carregar notificações de sistema: $e');
      throw e;
    }
  }

  // ==================== CÁLCULO DE BADGES ====================

  /// Atualiza contador de badges para Stories
  void _updateStoriesBadgeCount() {
    final unreadCount = storiesNotifications.where((n) => !n.isRead).length;
    storiesBadgeCount.value = unreadCount;
    storiesUnreadCount.value = unreadCount;
  }

  /// Atualiza contador de badges para Interesse
  void _updateInterestBadgeCount() {
    final unreadCount = interestNotifications.where((n) => n.isPending).length;
    interestBadgeCount.value = unreadCount;
    interestUnreadCount.value = unreadCount;
  }

  /// Atualiza contador de badges para Sistema
  void _updateSystemBadgeCount() {
    final unreadCount =
        systemNotifications.where((n) => !(n['read'] ?? false)).length;
    systemBadgeCount.value = unreadCount;
    systemUnreadCount.value = unreadCount;
  }

  /// Retorna o contador total de badges (soma de todas as categorias)
  int getTotalBadgeCount() {
    return storiesBadgeCount.value +
        interestBadgeCount.value +
        systemBadgeCount.value;
  }

  /// Retorna o contador de badges para uma categoria específica
  int getBadgeCountForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.stories:
        return storiesBadgeCount.value;
      case NotificationCategory.interest:
        return interestBadgeCount.value;
      case NotificationCategory.system:
        return systemBadgeCount.value;
    }
  }

  // ==================== MÉTODOS DE AÇÃO ====================

  /// Atualiza notificações de uma categoria específica (pull-to-refresh)
  Future<void> refreshCategory(NotificationCategory category) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      switch (category) {
        case NotificationCategory.stories:
          await _loadStoriesNotifications(userId);
          break;
        case NotificationCategory.interest:
          await _loadInterestNotifications(userId);
          break;
        case NotificationCategory.system:
          await _loadSystemNotifications(userId);
          break;
      }
    } catch (e) {
      print('❌ Erro ao atualizar categoria ${category.displayName}: $e');
      errorMessage.value = 'Erro ao atualizar: ${e.toString()}';
    }
  }

  /// Marca todas as notificações de uma categoria como lidas
  Future<void> markCategoryAsRead(NotificationCategory category) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      switch (category) {
        case NotificationCategory.stories:
          await NotificationRepository.markAllAsRead(userId);
          break;

        case NotificationCategory.interest:
          // Para interesse, marcar como "viewed" as que estão pendentes
          for (final notification in interestNotifications) {
            if (notification.isPending) {
              // Aqui você pode implementar lógica específica se necessário
              // Por enquanto, apenas atualizar o badge
            }
          }
          break;

        case NotificationCategory.system:
          await _certificationService.markAllAsRead(userId);
          break;
      }

      // Forçar atualização dos badges
      _updateAllBadgeCounts();
    } catch (e) {
      print('❌ Erro ao marcar categoria como lida: $e');
      errorMessage.value = 'Erro ao marcar como lida: ${e.toString()}';
    }
  }

  /// Troca a categoria ativa
  void switchCategory(int index) {
    if (index >= 0 && index <= 2) {
      activeCategory.value = index;
    }
  }

  /// Obtém a categoria ativa atual
  NotificationCategory getActiveCategory() {
    switch (activeCategory.value) {
      case 0:
        return NotificationCategory.stories;
      case 1:
        return NotificationCategory.interest;
      case 2:
        return NotificationCategory.system;
      default:
        return NotificationCategory.stories;
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Atualiza todos os contadores de badges
  void _updateAllBadgeCounts() {
    _updateStoriesBadgeCount();
    _updateInterestBadgeCount();
    _updateSystemBadgeCount();
  }

  /// Verifica se há notificações em uma categoria
  bool hasNotificationsInCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.stories:
        return storiesNotifications.isNotEmpty;
      case NotificationCategory.interest:
        return interestNotifications.isNotEmpty;
      case NotificationCategory.system:
        return systemNotifications.isNotEmpty;
    }
  }

  /// Retorna o número total de notificações em uma categoria
  int getNotificationCountForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.stories:
        return storiesNotifications.length;
      case NotificationCategory.interest:
        return interestNotifications.length;
      case NotificationCategory.system:
        return systemNotifications.length;
    }
  }

  /// Limpa mensagem de erro
  void clearError() {
    errorMessage.value = '';
  }

  /// Força reload de todas as notificações
  Future<void> forceReload() async {
    await loadAllNotifications();
  }

  // ==================== MÉTODOS PÚBLICOS PARA NOTIFICAÇÕES ====================

  /// Marca uma notificação de sistema como lida
  Future<void> markSystemNotificationAsRead(String notificationId) async {
    try {
      await _certificationService.markAsRead(notificationId);
      print('✅ Notificação de sistema marcada como lida: $notificationId');

      // Aguardar um pouco para o Firebase atualizar
      await Future.delayed(const Duration(milliseconds: 300));

      // Forçar atualização do badge
      _updateSystemBadgeCount();
    } catch (e) {
      print('❌ Erro ao marcar notificação de sistema como lida: $e');
      rethrow;
    }
  }

  /// Atualiza manualmente o contador de badges do sistema
  void updateSystemBadgeCount() {
    _updateSystemBadgeCount();
  }
}
