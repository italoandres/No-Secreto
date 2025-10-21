import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// FORÇA BRUTA ABSOLUTA - Garante que as notificações sempre apareçam visualmente
class ForceVisualNotifications {
  
  /// Cria um widget que SEMPRE aparece, independente de qualquer problema
  static Widget createAlwaysVisibleNotifications(MatchesController controller) {
    try {
      EnhancedLogger.info('🔥 FORÇA BRUTA: Criando notificações sempre visíveis', tag: 'FORCE_VISUAL');
      
      // Pegar dados diretamente do controller
      final notifications = controller.interestNotifications;
      final count = controller.interestNotificationsCount.value;
      
      EnhancedLogger.info('🔥 FORÇA BRUTA: Dados obtidos', 
        tag: 'FORCE_VISUAL',
        data: {
          'notifications_length': notifications.length,
          'count_value': count,
          'should_show': notifications.isNotEmpty,
        }
      );
      
      // SEMPRE mostrar algo, mesmo se não há dados
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header SEMPRE visível
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '🔥 FORÇA BRUTA ATIVADA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status SEMPRE visível
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎯 SISTEMA FUNCIONANDO: ${notifications.isNotEmpty ? "SIM" : "NÃO"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: notifications.isNotEmpty ? Colors.green : Colors.orange,
                    )
                  ),
                  const SizedBox(height: 8),
                  Text('📊 Notificações no Controller: ${notifications.length}'),
                  Text('📊 Contador: $count'),
                  Text('📊 Deve Mostrar: ${notifications.isNotEmpty ? "SIM" : "NÃO"}'),
                  Text('📊 Timestamp: ${DateTime.now().toString().substring(11, 19)}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Se há notificações, mostrar elas
            if (notifications.isNotEmpty) ...[
              const Text(
                '💕 NOTIFICAÇÕES ENCONTRADAS:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              
              // Mostrar cada notificação
              ...notifications.map((notification) => _buildForceNotificationCard(notification)),
              
            ] else ...[
              // Se não há notificações, mostrar mensagem
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma notificação encontrada no momento',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Botão para forçar reload
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _forceReloadNotifications(controller),
                icon: const Icon(Icons.refresh),
                label: const Text('🔄 FORÇAR RELOAD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
      
    } catch (e) {
      EnhancedLogger.error('🔥 FORÇA BRUTA: Erro ao criar widget', tag: 'FORCE_VISUAL');
      
      // Mesmo com erro, mostrar algo
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text(
              '🔥 FORÇA BRUTA ATIVA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('Erro: $e'),
            const SizedBox(height: 8),
            const Text('Mas pelo menos você está vendo isso! 😅'),
          ],
        ),
      );
    }
  }
  
  /// Constrói um card de notificação com força bruta
  static Widget _buildForceNotificationCard(Map<String, dynamic> notification) {
    try {
      final profileData = notification['profile'] as Map<String, dynamic>;
      final hasUserInterest = notification['hasUserInterest'] as bool? ?? false;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUserInterest ? Colors.green : Colors.pink,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome e idade
            Row(
              children: [
                Icon(
                  hasUserInterest ? Icons.favorite : Icons.favorite_border,
                  color: hasUserInterest ? Colors.green : Colors.pink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profileData['displayName'] ?? 'Usuário Desconhecido',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (profileData['age'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${profileData['age']} anos',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mensagem
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasUserInterest ? Colors.green[50] : Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasUserInterest 
                  ? '🎉 MATCH! Vocês demonstraram interesse mútuo!'
                  : '💕 Esta pessoa tem interesse em conhecer você melhor',
                style: TextStyle(
                  fontSize: 14,
                  color: hasUserInterest ? Colors.green[700] : Colors.pink[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Tempo
            Text(
              '⏰ ${notification['timeAgo'] ?? 'Agora'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        '👀 Ver Perfil',
                        'Clicou para ver o perfil de ${profileData['displayName']}',
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                      );
                    },
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('Ver Perfil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                if (!hasUserInterest) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          '❌ Não Tenho Interesse',
                          'Rejeitou ${profileData['displayName']}',
                          backgroundColor: Colors.grey,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Não Tenho'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        hasUserInterest ? '💬 Conversar' : '💕 Também Tenho Interesse',
                        hasUserInterest 
                          ? 'Iniciando conversa com ${profileData['displayName']}'
                          : 'Demonstrou interesse em ${profileData['displayName']}',
                        backgroundColor: hasUserInterest ? Colors.green : Colors.pink,
                        colorText: Colors.white,
                      );
                    },
                    icon: Icon(
                      hasUserInterest ? Icons.chat : Icons.favorite,
                      size: 16,
                    ),
                    label: Text(
                      hasUserInterest ? 'Conversar' : 'Interesse',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasUserInterest ? Colors.green : Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Text('Erro ao mostrar notificação: $e'),
      );
    }
  }
  
  /// Força reload das notificações
  static Future<void> _forceReloadNotifications(MatchesController controller) async {
    try {
      EnhancedLogger.info('🔄 FORÇA BRUTA: Forçando reload', tag: 'FORCE_VISUAL');
      
      Get.snackbar(
        '🔄 Recarregando...',
        'Forçando reload das notificações',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Forçar carregamento
      await controller.forceLoadInterestNotifications();
      
      // Aguardar um pouco
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Forçar update
      controller.update();
      
      Get.snackbar(
        '✅ Reload Concluído',
        'Notificações: ${controller.interestNotifications.length}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      Get.snackbar(
        '❌ Erro no Reload',
        'Erro: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}