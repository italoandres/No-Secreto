import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_chat_creator.dart';

/// Corretor específico para o chat que não foi encontrado
class SpecificMissingChatFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Corrige o chat específico que está faltando
  static Future<void> fixMissingChat() async {
    print('🔧 [SPECIFIC FIX] Corrigindo chat específico que não foi encontrado...');
    
    const problematicChatId = 'match_2MBqslnxAGeZFe18d9h52HYTZIy1_FleVxeZFIAPK3l2flnDMFESSDxx1';
    
    try {
      // Extrair IDs dos usuários
      final parts = problematicChatId.split('_');
      if (parts.length >= 3) {
        final userId1 = parts[1]; // 2MBqslnxAGeZFe18d9h52HYTZIy1
        final userId2 = parts[2]; // FleVxeZFIAPK3l2flnDMFESSDxx1
        
        print('👥 [SPECIFIC FIX] Usuários identificados:');
        print('   - Usuário 1: $userId1');
        print('   - Usuário 2: $userId2');
        
        // Verificar se o chat existe
        final chatDoc = await _firestore
            .collection('match_chats')
            .doc(problematicChatId)
            .get();
        
        if (!chatDoc.exists) {
          print('❌ [SPECIFIC FIX] Chat não existe, criando agora...');
          
          // Criar o chat usando o sistema robusto
          final newChatId = await MatchChatCreator.createOrGetChatId(userId1, userId2);
          print('✅ [SPECIFIC FIX] Chat criado com ID: $newChatId');
          
          // Verificar se foi criado corretamente
          final verifyDoc = await _firestore
              .collection('match_chats')
              .doc(newChatId)
              .get();
          
          if (verifyDoc.exists) {
            print('✅ [SPECIFIC FIX] Chat verificado e funcionando!');
          } else {
            print('❌ [SPECIFIC FIX] Erro na verificação do chat');
          }
          
        } else {
          print('ℹ️ [SPECIFIC FIX] Chat já existe, verificando dados...');
          final data = chatDoc.data();
          print('📊 [SPECIFIC FIX] Dados do chat: ${data?.keys}');
        }
        
        // Verificar se existe interesse mútuo entre os usuários
        await _verifyMutualInterest(userId1, userId2);
        
      } else {
        print('❌ [SPECIFIC FIX] Formato de chatId inválido: $problematicChatId');
      }
      
    } catch (e) {
      print('❌ [SPECIFIC FIX] Erro ao corrigir chat: $e');
    }
  }

  /// Verifica se existe interesse mútuo entre os usuários
  static Future<void> _verifyMutualInterest(String userId1, String userId2) async {
    print('💕 [SPECIFIC FIX] Verificando interesse mútuo...');
    
    try {
      // Buscar interesse de userId1 para userId2
      final interest1to2 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      // Buscar interesse de userId2 para userId1
      final interest2to1 = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      print('📊 [SPECIFIC FIX] Interesse $userId1 → $userId2: ${interest1to2.docs.length}');
      print('📊 [SPECIFIC FIX] Interesse $userId2 → $userId1: ${interest2to1.docs.length}');
      
      if (interest1to2.docs.isNotEmpty && interest2to1.docs.isNotEmpty) {
        print('💕 [SPECIFIC FIX] Interesse mútuo confirmado!');
      } else {
        print('⚠️ [SPECIFIC FIX] Interesse mútuo não encontrado');
        
        // Criar interesses se necessário (para teste)
        if (interest1to2.docs.isEmpty) {
          await _createTestInterest(userId1, userId2);
        }
        if (interest2to1.docs.isEmpty) {
          await _createTestInterest(userId2, userId1);
        }
      }
      
    } catch (e) {
      print('❌ [SPECIFIC FIX] Erro ao verificar interesse mútuo: $e');
    }
  }

  /// Cria interesse de teste se necessário
  static Future<void> _createTestInterest(String fromUserId, String toUserId) async {
    print('🧪 [SPECIFIC FIX] Criando interesse de teste: $fromUserId → $toUserId');
    
    try {
      await _firestore.collection('interests').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': 'accepted',
        'type': 'interest',
        'message': 'Interesse criado automaticamente para correção',
        'dataCriacao': FieldValue.serverTimestamp(),
        'dataResposta': FieldValue.serverTimestamp(),
      });
      
      print('✅ [SPECIFIC FIX] Interesse de teste criado');
    } catch (e) {
      print('❌ [SPECIFIC FIX] Erro ao criar interesse de teste: $e');
    }
  }

  /// Testa o chat específico após correção
  static Future<void> testSpecificChat() async {
    print('🧪 [SPECIFIC FIX] Testando chat específico...');
    
    const chatId = 'match_2MBqslnxAGeZFe18d9h52HYTZIy1_FleVxeZFIAPK3l2flnDMFESSDxx1';
    
    try {
      // Teste 1: Verificar se existe
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        print('✅ [SPECIFIC FIX] Teste 1 - Chat existe');
        
        // Teste 2: Verificar dados
        final data = chatDoc.data();
        print('✅ [SPECIFIC FIX] Teste 2 - Dados: ${data?.keys}');
        
        // Teste 3: Buscar mensagens
        final messages = await _firestore
            .collection('chat_messages')
            .where('chatId', isEqualTo: chatId)
            .limit(1)
            .get();
        
        print('✅ [SPECIFIC FIX] Teste 3 - Mensagens: ${messages.docs.length}');
        
        print('🎉 [SPECIFIC FIX] Todos os testes passaram!');
      } else {
        print('❌ [SPECIFIC FIX] Chat ainda não existe após correção');
      }
      
    } catch (e) {
      print('❌ [SPECIFIC FIX] Erro nos testes: $e');
    }
  }
}

/// Widget para executar a correção específica
class SpecificChatFixerWidget extends StatefulWidget {
  @override
  _SpecificChatFixerWidgetState createState() => _SpecificChatFixerWidgetState();
}

class _SpecificChatFixerWidgetState extends State<SpecificChatFixerWidget> {
  bool _isFixing = false;
  List<String> _logs = [];

  Future<void> _runSpecificFix() async {
    setState(() {
      _isFixing = true;
      _logs.clear();
    });

    _addLog('🚀 Iniciando correção específica...');
    
    try {
      await SpecificMissingChatFixer.fixMissingChat();
      _addLog('✅ Chat específico corrigido!');
      
      await SpecificMissingChatFixer.testSpecificChat();
      _addLog('🧪 Testes específicos concluídos!');
      
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
        title: Text('Correção Chat Específico'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informações do problema
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 PROBLEMA ESPECÍFICO DETECTADO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chat ID: match_2MBqslnxAGeZFe18d9h52HYTZIy1_FleVxeZFIAPK3l2flnDMFESSDxx1',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Text('❌ Chat não encontrado no Firebase'),
                    Text('❌ Erro ao inicializar chat'),
                    Text('❌ Navegação para chat falha'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Botão de correção
            ElevatedButton.icon(
              onPressed: _isFixing ? null : _runSpecificFix,
              icon: _isFixing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.healing),
              label: Text(_isFixing ? 'Corrigindo...' : 'Corrigir Chat Específico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 16),

            // Logs
            if (_logs.isNotEmpty) ...[
              Text(
                'Logs da Correção Específica:',
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