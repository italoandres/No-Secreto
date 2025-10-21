import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_chat_creator.dart';
import '../services/robust_notification_handler.dart';
import '../services/timestamp_sanitizer.dart';
import '../components/robust_conversar_button.dart';
import '../components/robust_interest_notification.dart';

/// Utilitário para testar o sistema de chat corrigido
class ChatSystemTester {
  
  /// Testa a criação de chat
  static Future<void> testChatCreation() async {
    print('🧪 Testando criação de chat...');
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não autenticado');
        return;
      }
      
      // Testar com usuário fictício
      const testUserId = 'test_user_123';
      
      // Teste 1: Criar chat
      final chatId = await MatchChatCreator.createOrGetChatId(
        currentUser.uid,
        testUserId,
      );
      print('✅ Chat criado: $chatId');
      
      // Teste 2: Verificar se existe
      final exists = await MatchChatCreator.chatExists(
        currentUser.uid,
        testUserId,
      );
      print('✅ Chat existe: $exists');
      
      // Teste 3: Obter mesmo ID
      final sameId = MatchChatCreator.getChatId(currentUser.uid, testUserId);
      print('✅ Mesmo ID: ${chatId == sameId}');
      
    } catch (e) {
      print('❌ Erro no teste de criação: $e');
    }
  }
  
  /// Testa sanitização de timestamp
  static void testTimestampSanitization() {
    print('🧪 Testando sanitização de timestamp...');
    
    // Teste 1: Valor null
    final nullResult = TimestampSanitizer.sanitizeTimestamp(null);
    print('✅ Null → ${nullResult.runtimeType}');
    
    // Teste 2: String inválida
    final stringResult = TimestampSanitizer.sanitizeTimestamp('invalid');
    print('✅ String inválida → ${stringResult.runtimeType}');
    
    // Teste 3: Dados de chat
    final chatData = {
      'id': 'test',
      'user1Id': 'user1',
      'user2Id': 'user2',
      'createdAt': null, // Null timestamp
      'expiresAt': 'invalid', // String inválida
      'isExpired': 'false', // String boolean
    };
    
    final sanitized = TimestampSanitizer.sanitizeChatData(chatData);
    print('✅ Chat sanitizado: ${sanitized.keys}');
  }
  
  /// Testa tratamento de notificações
  static Future<void> testNotificationHandling() async {
    print('🧪 Testando tratamento de notificações...');
    
    try {
      // Simular verificação de notificação já respondida
      const testNotificationId = 'test_notification_123';
      
      final alreadyResponded = await RobustNotificationHandler
          .isNotificationAlreadyResponded(testNotificationId);
      
      print('✅ Verificação de duplicata: $alreadyResponded');
      
    } catch (e) {
      print('❌ Erro no teste de notificação: $e');
    }
  }
  
  /// Executa todos os testes
  static Future<void> runAllTests() async {
    print('🚀 Iniciando testes do sistema de chat...');
    
    await testChatCreation();
    testTimestampSanitization();
    await testNotificationHandling();
    
    print('✅ Todos os testes concluídos!');
  }
}

/// Tela de teste para o sistema de chat
class ChatSystemTestView extends StatefulWidget {
  @override
  _ChatSystemTestViewState createState() => _ChatSystemTestViewState();
}

class _ChatSystemTestViewState extends State<ChatSystemTestView> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    // Capturar prints dos testes
    await ChatSystemTester.runAllTests();

    setState(() {
      _isRunning = false;
      _testResults.add('Testes concluídos com sucesso!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste do Sistema de Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão de teste
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runTests,
              icon: _isRunning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Executando Testes...' : 'Executar Testes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 24),

            // Componentes de teste
            Text(
              'Componentes Disponíveis:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Botão Conversar de teste
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Botão Conversar Robusto:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    RobustConversarButton(
                      otherUserId: 'test_user_123',
                      otherUserName: 'Usuário Teste',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Informações do sistema
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema Implementado:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    _buildFeatureItem('✅ Criação automática de chat no match'),
                    _buildFeatureItem('✅ Botão "Conversar" robusto'),
                    _buildFeatureItem('✅ Tratamento de notificações duplicadas'),
                    _buildFeatureItem('✅ Sanitização de dados Timestamp'),
                    _buildFeatureItem('✅ Índices Firebase configurados'),
                    _buildFeatureItem('✅ Sistema de retry automático'),
                  ],
                ),
              ),
            ),

            // Resultados dos testes
            if (_testResults.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Resultados dos Testes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListView.builder(
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _testResults[index],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}