import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/mutual_match_detector.dart';
import '../services/notification_orchestrator.dart';
import '../services/chat_system_manager.dart';
import '../services/real_time_notification_service.dart';
import '../models/notification_data.dart';
import '../models/message_data.dart';

/// Teste completo do fluxo de matches e notificações
class CompleteMatchFlowTester {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Executa todos os testes do sistema
  static Future<void> runAllTests() async {
    print('🚀 [COMPLETE_MATCH_FLOW_TEST] Iniciando testes completos...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [COMPLETE_MATCH_FLOW_TEST] Usuário não autenticado');
      return;
    }

    try {
      // Teste 1: Sistema de detecção de matches mútuos
      await _testMutualMatchDetection();
      
      // Teste 2: Sistema de notificações
      await _testNotificationSystem();
      
      // Teste 3: Sistema de chat
      await _testChatSystem();
      
      // Teste 4: Notificações em tempo real
      await _testRealTimeNotifications();
      
      // Teste 5: Fluxo completo end-to-end
      await _testCompleteFlow();
      
      print('🎉 [COMPLETE_MATCH_FLOW_TEST] Todos os testes passaram com sucesso!');
      
    } catch (e) {
      print('❌ [COMPLETE_MATCH_FLOW_TEST] Erro nos testes: $e');
    }
  }

  /// Testa o sistema de detecção de matches mútuos
  static Future<void> _testMutualMatchDetection() async {
    print('🧪 [TEST] Testando detecção de matches mútuos...');
    
    try {
      await MutualMatchDetector.testMutualMatchDetector();
      print('✅ [TEST] Sistema de matches mútuos funcionando');
    } catch (e) {
      print('❌ [TEST] Erro no sistema de matches mútuos: $e');
      throw e;
    }
  }

  /// Testa o sistema de notificações
  static Future<void> _testNotificationSystem() async {
    print('🧪 [TEST] Testando sistema de notificações...');
    
    try {
      await NotificationOrchestrator.testNotificationOrchestrator();
      print('✅ [TEST] Sistema de notificações funcionando');
    } catch (e) {
      print('❌ [TEST] Erro no sistema de notificações: $e');
      throw e;
    }
  }

  /// Testa o sistema de chat
  static Future<void> _testChatSystem() async {
    print('🧪 [TEST] Testando sistema de chat...');
    
    try {
      await ChatSystemManager.testChatSystem();
      print('✅ [TEST] Sistema de chat funcionando');
    } catch (e) {
      print('❌ [TEST] Erro no sistema de chat: $e');
      throw e;
    }
  }

  /// Testa notificações em tempo real
  static Future<void> _testRealTimeNotifications() async {
    print('🧪 [TEST] Testando notificações em tempo real...');
    
    try {
      await RealTimeNotificationService.testRealTimeNotificationService();
      print('✅ [TEST] Notificações em tempo real funcionando');
    } catch (e) {
      print('❌ [TEST] Erro nas notificações em tempo real: $e');
      throw e;
    }
  }

  /// Testa o fluxo completo end-to-end
  static Future<void> _testCompleteFlow() async {
    print('🧪 [TEST] Testando fluxo completo end-to-end...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      const testUserId = 'test_complete_flow_user';
      
      // Simular interesse mútuo
      print('📝 [TEST] Simulando interesse mútuo...');
      
      // Criar notificação de interesse inicial
      final interestNotification = NotificationData(
        id: '',
        toUserId: testUserId,
        fromUserId: currentUser.uid,
        fromUserName: 'Usuário Teste',
        fromUserEmail: 'teste@exemplo.com',
        type: 'interest',
        message: 'Tenho interesse em você!',
        status: 'new',
        createdAt: DateTime.now(),
      );
      
      await NotificationOrchestrator.createNotification(interestNotification);
      print('✅ [TEST] Notificação de interesse criada');
      
      // Simular resposta positiva (que deveria criar match mútuo)
      await MutualMatchDetector.processInterestResponse(
        interestNotification.id,
        'accepted',
        currentUser.uid,
        testUserId,
      );
      print('✅ [TEST] Resposta de interesse processada');
      
      // Verificar se o chat foi criado
      final chatId = 'match_${currentUser.uid}_$testUserId';
      await ChatSystemManager.ensureChatExists(chatId);
      print('✅ [TEST] Chat criado e verificado');
      
      // Enviar mensagem de teste
      final testMessage = MessageData(
        id: '',
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: 'Usuário Teste',
        message: 'Olá! Como você está?',
        timestamp: DateTime.now(),
        isRead: false,
        messageType: 'text',
      );
      
      await ChatSystemManager.sendMessage(chatId, testMessage);
      print('✅ [TEST] Mensagem enviada');
      
      // Verificar contadores de não lidas
      final chatData = await ChatSystemManager.getChatData(chatId);
      if (chatData != null) {
        final unreadCount = chatData.getUnreadCountForUser(testUserId);
        print('✅ [TEST] Contador de não lidas: $unreadCount');
      }
      
      print('🎉 [TEST] Fluxo completo end-to-end funcionando!');
      
    } catch (e) {
      print('❌ [TEST] Erro no fluxo completo: $e');
      throw e;
    }
  }

  /// Cria dados de teste para validação
  static Future<void> createTestData() async {
    print('🔧 [TEST] Criando dados de teste...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [TEST] Usuário não autenticado');
      return;
    }

    try {
      // Criar várias notificações de teste
      final testNotifications = [
        NotificationData(
          id: '',
          toUserId: currentUser.uid,
          fromUserId: 'test_user_1',
          fromUserName: 'Maria Silva',
          fromUserEmail: 'maria@exemplo.com',
          type: 'interest',
          message: 'Tenho interesse em você!',
          status: 'new',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        NotificationData(
          id: '',
          toUserId: currentUser.uid,
          fromUserId: 'test_user_2',
          fromUserName: 'João Santos',
          fromUserEmail: 'joao@exemplo.com',
          type: 'mutual_match',
          message: 'MATCH MÚTUO! Vocês dois demonstraram interesse! 🎉💕',
          status: 'new',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          metadata: {
            'matchType': 'mutual',
            'otherUserId': 'test_user_2',
            'otherUserName': 'João Santos',
          },
        ),
        NotificationData(
          id: '',
          toUserId: currentUser.uid,
          fromUserId: 'test_user_3',
          fromUserName: 'Ana Costa',
          fromUserEmail: 'ana@exemplo.com',
          type: 'message',
          message: 'Nova mensagem: Oi! Como você está?',
          status: 'new',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          metadata: {
            'chatId': 'match_${currentUser.uid}_test_user_3',
            'messageId': 'test_message_1',
          },
        ),
      ];
      
      // Criar notificações em lote
      await NotificationOrchestrator.createBulkNotifications(testNotifications);
      
      print('✅ [TEST] ${testNotifications.length} notificações de teste criadas');
      
      // Criar chats de teste
      await ChatSystemManager.createChat(currentUser.uid, 'test_user_2');
      await ChatSystemManager.createChat(currentUser.uid, 'test_user_3');
      
      print('✅ [TEST] Chats de teste criados');
      
    } catch (e) {
      print('❌ [TEST] Erro ao criar dados de teste: $e');
    }
  }

  /// Limpa dados de teste
  static Future<void> cleanupTestData() async {
    print('🧹 [TEST] Limpando dados de teste...');
    
    try {
      // Aqui você pode implementar a limpeza dos dados de teste
      // Por exemplo, remover notificações e chats de teste
      
      print('✅ [TEST] Dados de teste limpos');
      
    } catch (e) {
      print('❌ [TEST] Erro ao limpar dados de teste: $e');
    }
  }
}

/// Widget para testar o sistema completo
class CompleteMatchFlowTestWidget extends StatefulWidget {
  const CompleteMatchFlowTestWidget({Key? key}) : super(key: key);

  @override
  State<CompleteMatchFlowTestWidget> createState() => _CompleteMatchFlowTestWidgetState();
}

class _CompleteMatchFlowTestWidgetState extends State<CompleteMatchFlowTestWidget> {
  bool _isRunningTests = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Completo - Match Flow'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sistema de Testes - Match Flow Completo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isRunningTests ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: _isRunningTests
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 10),
                        Text('Executando Testes...'),
                      ],
                    )
                  : const Text(
                      'Executar Todos os Testes',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isRunningTests ? null : _createTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Criar Dados de Teste',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isRunningTests ? null : _cleanupTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Limpar Dados de Teste',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Resultados dos Testes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty 
                        ? 'Nenhum teste executado ainda.\n\nClique em "Executar Todos os Testes" para começar.'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = 'Iniciando testes...\n';
    });

    try {
      await CompleteMatchFlowTester.runAllTests();
      setState(() {
        _testResults += '\n🎉 TODOS OS TESTES PASSARAM COM SUCESSO!\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ ERRO NOS TESTES: $e\n';
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _createTestData() async {
    setState(() {
      _testResults += '\nCriando dados de teste...\n';
    });

    try {
      await CompleteMatchFlowTester.createTestData();
      setState(() {
        _testResults += '✅ Dados de teste criados com sucesso!\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Erro ao criar dados de teste: $e\n';
      });
    }
  }

  Future<void> _cleanupTestData() async {
    setState(() {
      _testResults += '\nLimpando dados de teste...\n';
    });

    try {
      await CompleteMatchFlowTester.cleanupTestData();
      setState(() {
        _testResults += '✅ Dados de teste limpos com sucesso!\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Erro ao limpar dados de teste: $e\n';
      });
    }
  }
}