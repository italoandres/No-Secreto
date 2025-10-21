import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para corrigir o loop infinito nas notificações
class FixInfiniteLoopNotifications {
  
  /// Corrige o método _buildInterestNotifications para evitar loop infinito
  static Widget buildInterestNotificationsFixed(MatchesController controller) {
    return Obx(() {
      final notifications = controller.interestNotifications;
      
      // Log apenas quando necessário (não a cada rebuild)
      if (notifications.isEmpty) {
        return const SizedBox.shrink();
      }

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
            
            // Debug: Mostrar informações de debug
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEBUG: Notificações carregadas: ${notifications.length}'),
                  Text('Controller count: ${controller.interestNotificationsCount.value}'),
                  Text('Should show: ${notifications.isNotEmpty}'),
                  if (notifications.isNotEmpty)
                    ...notifications.map((n) => Text('- ${n['profile']['displayName']}')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Renderizar notificações normalmente
            ...notifications.map((notification) => 
              _buildNotificationCard(notification)
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }
  
  /// Constrói um card de notificação simples
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
                      tag: 'NOTIFICATIONS',
                      data: {'userId': profileData['userId']}
                    );
                  },
                  child: const Text('Ver Perfil'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    EnhancedLogger.info('Interesse clicado', 
                      tag: 'NOTIFICATIONS',
                      data: {'userId': profileData['userId']}
                    );
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
  
  /// Testa se as notificações estão funcionando
  static Future<void> testNotifications() async {
    try {
      EnhancedLogger.info('Testando notificações corrigidas', tag: 'FIX_LOOP');
      
      final controller = Get.find<MatchesController>();
      
      // Verificar estado atual
      final currentState = {
        'notificationsCount': controller.interestNotifications.length,
        'notificationsCountValue': controller.interestNotificationsCount.value,
        'hasNotifications': controller.interestNotifications.isNotEmpty,
      };
      
      EnhancedLogger.success('Estado atual das notificações', 
        tag: 'FIX_LOOP',
        data: currentState
      );
      
      // Forçar carregamento se necessário
      if (controller.interestNotifications.isEmpty) {
        EnhancedLogger.info('Forçando carregamento das notificações', tag: 'FIX_LOOP');
        await controller.forceLoadInterestNotifications();
      }
      
      // Estado final
      final finalState = {
        'notificationsCount': controller.interestNotifications.length,
        'notificationsCountValue': controller.interestNotificationsCount.value,
        'hasNotifications': controller.interestNotifications.isNotEmpty,
      };
      
      EnhancedLogger.success('Teste de notificações concluído', 
        tag: 'FIX_LOOP',
        data: finalState
      );
      
    } catch (e) {
      EnhancedLogger.error('Erro ao testar notificações', 
        tag: 'FIX_LOOP',
        error: e
      );
    }
  }
}