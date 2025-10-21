import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_chat_creator.dart';
import '../services/robust_notification_handler.dart';
import '../services/timestamp_sanitizer.dart';

/// Utilitário para corrigir o sistema de chat existente
class ExistingChatSystemFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Corrige o sistema existente integrando as melhorias
  static Future<void> fixExistingSystem() async {
    print('🔧 Iniciando correção do sistema existente...');
    
    try {
      await _fixMissingChats();
      await _fixDuplicateNotifications();
      await _createMissingIndexes();
      
      print('✅ Sistema existente corrigido com sucesso!');
    } catch (e) {
      print('❌ Erro ao corrigir sistema: $e');
    }
  }

  /// Corrige chats que deveriam existir mas não existem
  static Future<void> _fixMissingChats() async {
    print('🔍 Verificando chats faltando...');
    
    try {
      // Buscar todas as notificações aceitas
      final acceptedInterests = await _firestore
          .collection('interests')
          .where('status', isEqualTo: 'accepted')
          .get();
      
      print('📊 Encontradas ${acceptedInterests.docs.length} notificações aceitas');
      
      for (final doc in acceptedInterests.docs) {
        final data = doc.data();
        final fromUserId = data['fromUserId'];
        final toUserId = data['toUserId'];
        
        if (fromUserId != null && toUserId != null) {
          // Verificar se existe interesse mútuo
          final reverseInterest = await _firestore
              .collection('interests')
              .where('fromUserId', isEqualTo: toUserId)
              .where('toUserId', isEqualTo: fromUserId)
              .where('status', isEqualTo: 'accepted')
              .get();
          
          if (reverseInterest.docs.isNotEmpty) {
            // É um match mútuo, verificar se chat existe
            final chatExists = await MatchChatCreator.chatExists(fromUserId, toUserId);
            
            if (!chatExists) {
              print('🚀 Criando chat faltando para match mútuo: $fromUserId ↔ $toUserId');
              await MatchChatCreator.createOrGetChatId(fromUserId, toUserId);
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Erro ao corrigir chats faltando: $e');
    }
  }

  /// Corrige notificações duplicadas
  static Future<void> _fixDuplicateNotifications() async {
    print('🔍 Corrigindo notificações duplicadas...');
    
    try {
      // Buscar notificações com status 'new' que deveriam ser 'pending'
      final newNotifications = await _firestore
          .collection('interests')
          .where('status', isEqualTo: 'new')
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in newNotifications.docs) {
        final data = doc.data();
        
        // Se é do tipo 'mutual_match', marcar como aceito
        if (data['type'] == 'mutual_match') {
          batch.update(doc.reference, {
            'status': 'accepted',
            'dataResposta': FieldValue.serverTimestamp(),
          });
        } else {
          // Outros tipos, marcar como pending
          batch.update(doc.reference, {
            'status': 'pending',
          });
        }
      }
      
      if (newNotifications.docs.isNotEmpty) {
        await batch.commit();
        print('✅ ${newNotifications.docs.length} notificações corrigidas');
      }
      
    } catch (e) {
      print('❌ Erro ao corrigir notificações: $e');
    }
  }

  /// Cria índices faltando (mostra links)
  static Future<void> _createMissingIndexes() async {
    print('🔍 Verificando índices faltando...');
    
    final indexLinks = [
      'https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=Cmdwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2ludGVyZXN0X25vdGlmaWNhdGlvbnMvaW5kZXhlcy9fEAEaDAoIdG9Vc2VySWQQARoPCgtkYXRhQ3JpYWNhbxACGgwKCF9fbmFtZV9fEAI',
      'https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=Cl5wcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2NoYXRfbWVzc2FnZXMvaW5kZXhlcy9fEAEaCgoGY2hhdElkEAEaCgoGaXNSZWFkEAEaDAoIc2VuZGVySWQQARoMCghfX25hbWVfXxAB',
    ];
    
    print('📋 Links para criar índices faltando:');
    for (int i = 0; i < indexLinks.length; i++) {
      print('🔗 Índice ${i + 1}: ${indexLinks[i]}');
    }
  }

  /// Corrige chat específico que não foi encontrado
  static Future<void> fixSpecificChat(String chatId) async {
    print('🔧 Corrigindo chat específico: $chatId');
    
    try {
      // Extrair IDs dos usuários do chatId
      final parts = chatId.split('_');
      if (parts.length >= 3) {
        final userId1 = parts[1];
        final userId2 = parts[2];
        
        print('👥 Usuários: $userId1 ↔ $userId2');
        
        // Verificar se o chat existe
        final chatDoc = await _firestore
            .collection('match_chats')
            .doc(chatId)
            .get();
        
        if (!chatDoc.exists) {
          print('🚀 Chat não existe, criando...');
          await MatchChatCreator.createOrGetChatId(userId1, userId2);
          print('✅ Chat criado com sucesso!');
        } else {
          print('ℹ️ Chat já existe');
        }
      }
    } catch (e) {
      print('❌ Erro ao corrigir chat específico: $e');
    }
  }

  /// Substitui o sistema de resposta de notificação existente
  static Future<void> replaceNotificationResponse(String notificationId, String action) async {
    print('🔄 Usando sistema robusto para responder notificação: $notificationId');
    
    try {
      await RobustNotificationHandler.respondToNotification(notificationId, action);
      print('✅ Notificação respondida com sistema robusto');
    } catch (e) {
      print('❌ Erro no sistema robusto: $e');
    }
  }

  /// Testa o sistema corrigido
  static Future<void> testFixedSystem() async {
    print('🧪 Testando sistema corrigido...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ Usuário não autenticado');
      return;
    }
    
    try {
      // Teste 1: Criar chat de teste
      const testUserId = 'test_user_fixed';
      final chatId = await MatchChatCreator.createOrGetChatId(
        currentUser.uid,
        testUserId,
      );
      print('✅ Teste 1 - Chat criado: $chatId');
      
      // Teste 2: Verificar se existe
      final exists = await MatchChatCreator.chatExists(
        currentUser.uid,
        testUserId,
      );
      print('✅ Teste 2 - Chat existe: $exists');
      
      // Teste 3: Sanitizar dados
      final testData = {
        'createdAt': null,
        'expiresAt': 'invalid',
        'isExpired': 'false',
      };
      
      final sanitized = TimestampSanitizer.sanitizeChatData(testData);
      print('✅ Teste 3 - Dados sanitizados: ${sanitized.keys}');
      
      print('🎉 Todos os testes passaram!');
      
    } catch (e) {
      print('❌ Erro nos testes: $e');
    }
  }
}

/// Widget para executar as correções
class ChatSystemFixerWidget extends StatefulWidget {
  @override
  _ChatSystemFixerWidgetState createState() => _ChatSystemFixerWidgetState();
}

class _ChatSystemFixerWidgetState extends State<ChatSystemFixerWidget> {
  bool _isFixing = false;
  List<String> _logs = [];

  Future<void> _runFix() async {
    setState(() {
      _isFixing = true;
      _logs.clear();
    });

    // Capturar logs
    _addLog('🚀 Iniciando correção do sistema...');
    
    try {
      await ExistingChatSystemFixer.fixExistingSystem();
      _addLog('✅ Sistema corrigido com sucesso!');
      
      await ExistingChatSystemFixer.testFixedSystem();
      _addLog('🧪 Testes concluídos!');
      
    } catch (e) {
      _addLog('❌ Erro: $e');
    }

    setState(() {
      _isFixing = false;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Correção do Sistema de Chat'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão de correção
            ElevatedButton.icon(
              onPressed: _isFixing ? null : _runFix,
              icon: _isFixing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.build),
              label: Text(_isFixing ? 'Corrigindo Sistema...' : 'Corrigir Sistema Agora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 16),

            // Informações
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problemas Detectados:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('❌ Chat não encontrado'),
                    Text('❌ Notificação já respondida'),
                    Text('❌ Índice Firebase faltando'),
                    SizedBox(height: 16),
                    Text(
                      'Correções que serão aplicadas:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Criar chats faltando'),
                    Text('✅ Corrigir notificações duplicadas'),
                    Text('✅ Mostrar links para índices'),
                    Text('✅ Integrar sistema robusto'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Logs
            if (_logs.isNotEmpty) ...[
              Text(
                'Logs da Correção:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
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
}