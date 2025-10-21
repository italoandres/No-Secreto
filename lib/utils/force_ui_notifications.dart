import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/enhanced_logger.dart';
import '../models/real_notification_model.dart';
import '../controllers/matches_controller.dart';

/// FORÇA NOTIFICAÇÕES DIRETAMENTE NA INTERFACE
class ForceUINotifications {
  
  /// FORÇA notificações a aparecerem na interface AGORA
  static void forceShowInUI(String userId) {
    EnhancedLogger.info('🚀 FORÇANDO NOTIFICAÇÕES NA INTERFACE PARA: $userId');
    
    try {
      // 1. Cria notificações fake para forçar exibição
      final fakeNotifications = [
        RealNotification(
          id: 'force_ui_1',
          type: 'interest',
          fromUserId: 'test_force_ui',
          fromUserName: '🚀 SISTEMA TESTE',
          message: 'NOTIFICAÇÃO FORÇADA NA INTERFACE!',
          timestamp: DateTime.now(),
          isRead: false,
        ),
        RealNotification(
          id: 'force_ui_2', 
          type: 'like',
          fromUserId: 'test_force_ui_2',
          fromUserName: '✅ TESTE FUNCIONANDO',
          message: 'Esta notificação foi forçada diretamente na UI!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
      ];
      
      // 2. Força no controller
      final controller = Get.find<MatchesController>();
      controller.realInterestNotifications.value = fakeNotifications;
      controller.realInterestNotificationsCount.value = fakeNotifications.length;
      
      // 3. Força atualização da interface
      controller.update();
      
      // 4. Mostra snackbar de confirmação
      Get.snackbar(
        '🚀 SUCESSO!',
        'Notificações forçadas na interface! Total: ${fakeNotifications.length}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );
      
      EnhancedLogger.success('✅ NOTIFICAÇÕES FORÇADAS NA INTERFACE!');
      EnhancedLogger.info('📊 Total forçado: ${fakeNotifications.length}');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro ao forçar na interface', error: e, stackTrace: stackTrace);
      
      // Fallback: Mostra snackbar de erro
      Get.snackbar(
        '❌ ERRO',
        'Erro ao forçar notificações: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  /// Limpa notificações forçadas
  static void clearForcedNotifications() {
    try {
      final controller = Get.find<MatchesController>();
      controller.realInterestNotifications.clear();
      controller.realInterestNotificationsCount.value = 0;
      controller.update();
      
      Get.snackbar(
        '🧹 LIMPO!',
        'Notificações forçadas removidas',
        backgroundColor: Colors.grey,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      EnhancedLogger.info('🧹 Notificações forçadas removidas da interface');
      
    } catch (e) {
      EnhancedLogger.error('❌ Erro ao limpar notificações forçadas', error: e);
    }
  }
  
  /// Widget para mostrar botão de força
  static Widget buildForceUIButton(String userId) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => forceShowInUI(userId),
            icon: const Icon(Icons.visibility),
            label: const Text('🚀 FORÇAR NA INTERFACE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => clearForcedNotifications(),
            icon: const Icon(Icons.clear),
            label: const Text('🧹 LIMPAR INTERFACE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}