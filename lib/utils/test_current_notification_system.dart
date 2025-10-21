import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/interest_notification_repository.dart';

/// Teste do sistema atual de notificações de interesse
class TestCurrentNotificationSystem {
  
  /// Testar o fluxo completo de notificações
  static Future<void> testCompleteFlow() async {
    print('🧪 TESTANDO SISTEMA ATUAL DE NOTIFICAÇÕES');
    print('=' * 50);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não logado');
        return;
      }
      
      print('✅ Usuário logado: ${currentUser.uid}');
      
      // 1. Testar busca de notificações
      await _testGetNotifications(currentUser.uid);
      
      // 2. Testar estatísticas
      await _testGetStats(currentUser.uid);
      
      // 3. Testar contador de não lidas
      await _testUnreadCount(currentUser.uid);
      
      print('');
      print('🎯 TESTE CONCLUÍDO!');
      
    } catch (e) {
      print('❌ Erro no teste: $e');
    }
  }
  
  /// Testar busca de notificações
  static Future<void> _testGetNotifications(String userId) async {
    print('');
    print('📋 TESTANDO BUSCA DE NOTIFICAÇÕES:');
    
    try {
      // Stream de notificações
      final stream = InterestNotificationRepository.getUserInterestNotifications(userId);
      
      await for (final notifications in stream.take(1)) {
        print('💕 Encontradas ${notifications.length} notificações');
        
        for (int i = 0; i < notifications.length; i++) {
          final notification = notifications[i];
          print('   ${i + 1}. ${notification.fromUserName} - ${notification.status}');
          print('      Tipo: ${notification.type}');
          print('      Mensagem: ${notification.message}');
          print('      Data: ${notification.dataCriacao}');
        }
        
        if (notifications.isEmpty) {
          print('   ℹ️ Nenhuma notificação encontrada');
        }
        
        break; // Sair do loop após o primeiro resultado
      }
      
    } catch (e) {
      print('❌ Erro ao buscar notificações: $e');
    }
  }
  
  /// Testar estatísticas
  static Future<void> _testGetStats(String userId) async {
    print('');
    print('📊 TESTANDO ESTATÍSTICAS:');
    
    try {
      final stats = await InterestNotificationRepository.getUserInterestStats(userId);
      
      print('   📤 Enviados: ${stats['sent']}');
      print('   📥 Recebidos: ${stats['received']}');
      print('   ✅ Aceitos (enviados): ${stats['acceptedSent']}');
      print('   ✅ Aceitos (recebidos): ${stats['acceptedReceived']}');
      
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
    }
  }
  
  /// Testar contador de não lidas
  static Future<void> _testUnreadCount(String userId) async {
    print('');
    print('🔔 TESTANDO CONTADOR DE NÃO LIDAS:');
    
    try {
      final count = await InterestNotificationRepository.getUnreadNotificationsCount(userId);
      print('   📱 Notificações não lidas: $count');
      
      // Testar stream do contador
      final stream = InterestNotificationRepository.getUnreadNotificationsCountStream(userId);
      
      await for (final streamCount in stream.take(1)) {
        print('   📱 Stream contador: $streamCount');
        break;
      }
      
    } catch (e) {
      print('❌ Erro ao testar contador: $e');
    }
  }
  
  /// Simular demonstração de interesse
  static Future<void> simulateInterest({
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String toUserId,
    required String toUserEmail,
  }) async {
    print('');
    print('💕 SIMULANDO DEMONSTRAÇÃO DE INTERESSE:');
    print('   De: $fromUserName ($fromUserId)');
    print('   Para: $toUserId');
    
    try {
      await InterestNotificationRepository.createInterestNotification(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        toUserId: toUserId,
        toUserEmail: toUserEmail,
        message: 'Demonstrou interesse no seu perfil! 💕',
      );
      
      print('✅ Interesse demonstrado com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao demonstrar interesse: $e');
    }
  }
  
  /// Widget de teste para usar na interface
  static Widget buildTestWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Sistema Notificações'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sistema de Notificações de Interesse',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: () => testCompleteFlow(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Executar Teste Completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: () => _showTestResults(),
              icon: const Icon(Icons.analytics),
              label: const Text('Ver Resultados no Console'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status do Sistema:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Repositório de notificações implementado'),
                    Text('✅ Dashboard de interesse implementado'),
                    Text('✅ Botão com badge de notificações implementado'),
                    Text('✅ Sistema de estatísticas implementado'),
                    Text('✅ Notificações de aceitação implementadas'),
                    Text('✅ Sistema de match mútuo implementado'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static void _showTestResults() {
    print('');
    print('📋 INSTRUÇÕES PARA VER RESULTADOS:');
    print('1. Abra o console/debug do seu IDE');
    print('2. Execute o teste clicando no botão');
    print('3. Veja os logs detalhados no console');
    print('4. Verifique se há erros ou problemas');
  }
}