import 'package:get/get.dart';
import 'package:whatsapp_chat/views/unified_notifications_view.dart';

/// Helper para navegação e integração do sistema unificado de notificações
class UnifiedNotificationsHelper {
  /// Navega para a tela de notificações unificadas
  static void openNotifications() {
    Get.to(() => const UnifiedNotificationsView());
  }

  /// Navega para a tela de notificações com categoria específica
  static void openNotificationsWithCategory(int categoryIndex) {
    Get.to(() => const UnifiedNotificationsView());
    // TODO: Passar categoryIndex como parâmetro quando implementar
  }

  /// Registra rota no GetX
  static void registerRoute() {
    Get.lazyPut(() => const UnifiedNotificationsView());
  }
}
