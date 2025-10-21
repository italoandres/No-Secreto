import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/interest_notification_repository.dart';
import '../models/interest_notification_model.dart';

/// Utilitário para testar a integração do sistema de matches com interesse
class TestMatchesIntegration {
  /// Criar notificação de interesse de teste
  static Future<void> createTestInterestNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Erro ❌',
          'Usuário não está logado',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Criar uma notificação de interesse de teste
      await InterestNotificationRepository.createInterestNotification(
        fromUserId: 'test_user_id',
        fromUserName: 'Usuário Teste',
        fromUserEmail: 'teste@exemplo.com',
        toUserId: currentUser.uid,
        toUserEmail: currentUser.email ?? '',
        message: 'Demonstrou interesse no seu perfil (TESTE)',
      );

      Get.snackbar(
        'Teste Criado! ✅',
        'Notificação de interesse de teste criada. Verifique o badge no botão "Gerencie seus Matches"!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Erro no Teste ❌',
        'Erro ao criar notificação de teste: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Navegar para o dashboard de interesse (teste da rota /matches)
  static void testMatchesRoute() {
    try {
      Get.toNamed('/matches');
      Get.snackbar(
        'Rota Testada! ✅',
        'Navegação para /matches funcionando corretamente!',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erro na Rota ❌',
        'Erro ao navegar para /matches: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Verificar quantas notificações não lidas existem
  static Future<void> checkUnreadNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final unreadCount = await InterestNotificationRepository.getUnreadNotificationsCount(currentUser.uid);

      Get.snackbar(
        'Status das Notificações 📊',
        'Você tem $unreadCount notificação${unreadCount != 1 ? 'ões' : ''} não lida${unreadCount != 1 ? 's' : ''} de interesse',
        backgroundColor: unreadCount > 0 ? Colors.orange : Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Erro na Verificação ❌',
        'Erro ao verificar notificações: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

/// Widget de teste para a integração
class TestMatchesIntegrationWidget extends StatelessWidget {
  const TestMatchesIntegrationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste: Integração Matches + Interesse'),
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Teste da Integração Sistema de Matches + Interesse',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botão 1: Criar notificação de teste
            ElevatedButton.icon(
              onPressed: TestMatchesIntegration.createTestInterestNotification,
              icon: const Icon(Icons.add_alert),
              label: const Text('1. Criar Notificação de Teste'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Botão 2: Testar rota /matches
            ElevatedButton.icon(
              onPressed: TestMatchesIntegration.testMatchesRoute,
              icon: const Icon(Icons.route),
              label: const Text('2. Testar Rota /matches'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Botão 3: Verificar notificações
            ElevatedButton.icon(
              onPressed: TestMatchesIntegration.checkUnreadNotifications,
              icon: const Icon(Icons.notifications),
              label: const Text('3. Verificar Notificações'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Como Testar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Clique "Criar Notificação de Teste"'),
                    Text('2. Volte para a tela principal'),
                    Text('3. Veja o badge vermelho no botão "Gerencie seus Matches"'),
                    Text('4. Clique no botão para ir ao dashboard'),
                    Text('5. Veja suas notificações de interesse!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}