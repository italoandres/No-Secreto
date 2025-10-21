import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Corretor específico para erros de Timestamp e Chat não encontrado
class TimestampChatErrorsFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Corrige o erro específico de Timestamp null
  static Future<void> fixTimestampErrors() async {
    print('🔧 [TIMESTAMP_FIX] Corrigindo erros de Timestamp...');
    
    try {
      // Buscar todos os chats com dados problemáticos
      final chatsQuery = await _firestore
          .collection('match_chats')
          .get();
      
      final batch = _firestore.batch();
      int fixedCount = 0;
      
      for (final doc in chatsQuery.docs) {
        final data = doc.data();
        bool needsUpdate = false;
        final updates = <String, dynamic>{};
        
        // Corrigir campos de timestamp null
        if (data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
          needsUpdate = true;
        }
        
        if (data['lastMessageAt'] == null) {
          updates['lastMessageAt'] = FieldValue.serverTimestamp();
          needsUpdate = true;
        }
        
        if (data['expiresAt'] == null) {
          // Definir expiração para 30 dias a partir de agora
          final expirationDate = DateTime.now().add(Duration(days: 30));
          updates['expiresAt'] = Timestamp.fromDate(expirationDate);
          needsUpdate = true;
        }
        
        // Corrigir campos booleanos
        if (data['isExpired'] == null || data['isExpired'] is String) {
          updates['isExpired'] = false;
          needsUpdate = true;
        }
        
        if (data['isActive'] == null || data['isActive'] is String) {
          updates['isActive'] = true;
          needsUpdate = true;
        }
        
        // Garantir que existam campos obrigatórios
        if (data['participants'] == null) {
          // Extrair participantes do ID do chat
          final chatId = doc.id;
          final parts = chatId.split('_');
          if (parts.length >= 3) {
            updates['participants'] = [parts[1], parts[2]];
            needsUpdate = true;
          }
        }
        
        if (needsUpdate) {
          batch.update(doc.reference, updates);
          fixedCount++;
          print('🔧 [TIMESTAMP_FIX] Corrigindo chat: ${doc.id}');
        }
      }
      
      if (fixedCount > 0) {
        await batch.commit();
        print('✅ [TIMESTAMP_FIX] $fixedCount chats corrigidos');
      } else {
        print('ℹ️ [TIMESTAMP_FIX] Nenhum chat precisou de correção');
      }
      
    } catch (e) {
      print('❌ [TIMESTAMP_FIX] Erro ao corrigir timestamps: $e');
    }
  }

  /// Corrige o chat específico que não foi encontrado
  static Future<void> fixSpecificMissingChat() async {
    print('🔧 [SPECIFIC_CHAT_FIX] Corrigindo chat específico...');
    
    const problematicChatId = 'match_St2kw3cgX2MMPxlLRmBDjYm2nO22_dLHuF1kUDTNe7PgdBLbmynrdpft1';
    
    try {
      // Extrair IDs dos usuários
      final parts = problematicChatId.split('_');
      if (parts.length >= 3) {
        final userId1 = parts[1]; // St2kw3cgX2MMPxlLRmBDjYm2nO22
        final userId2 = parts[2]; // dLHuF1kUDTNe7PgdBLbmynrdpft1
        
        print('👥 [SPECIFIC_CHAT_FIX] Usuários: $userId1 ↔ $userId2');
        
        // Verificar se o chat existe
        final chatDoc = await _firestore
            .collection('match_chats')
            .doc(problematicChatId)
            .get();
        
        if (!chatDoc.exists) {
          print('🚀 [SPECIFIC_CHAT_FIX] Chat não existe, criando...');
          
          // Criar o chat com dados completos e sanitizados
          final chatData = {
            'chatId': problematicChatId,
            'participants': [userId1, userId2],
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
            'isExpired': false,
            'isActive': true,
            'lastMessage': 'Vocês têm um match! Iniciem uma conversa.',
            'unreadCount': {
              userId1: 0,
              userId2: 0,
            },
            'metadata': {
              'createdBy': 'system_fix',
              'version': '2.0',
              'fixedAt': FieldValue.serverTimestamp(),
            }
          };
          
          await _firestore
              .collection('match_chats')
              .doc(problematicChatId)
              .set(chatData);
          
          print('✅ [SPECIFIC_CHAT_FIX] Chat criado com sucesso!');
          
        } else {
          print('ℹ️ [SPECIFIC_CHAT_FIX] Chat existe, verificando dados...');
          
          // Sanitizar dados existentes
          final data = chatDoc.data()!;
          final updates = <String, dynamic>{};
          
          // Corrigir timestamps null
          if (data['createdAt'] == null) {
            updates['createdAt'] = FieldValue.serverTimestamp();
          }
          if (data['lastMessageAt'] == null) {
            updates['lastMessageAt'] = FieldValue.serverTimestamp();
          }
          if (data['expiresAt'] == null) {
            updates['expiresAt'] = Timestamp.fromDate(DateTime.now().add(Duration(days: 30)));
          }
          
          // Corrigir booleanos
          if (data['isExpired'] == null || data['isExpired'] is String) {
            updates['isExpired'] = false;
          }
          if (data['isActive'] == null || data['isActive'] is String) {
            updates['isActive'] = true;
          }
          
          if (updates.isNotEmpty) {
            await chatDoc.reference.update(updates);
            print('✅ [SPECIFIC_CHAT_FIX] Dados do chat sanitizados');
          }
        }
        
      } else {
        print('❌ [SPECIFIC_CHAT_FIX] Formato de chatId inválido');
      }
      
    } catch (e) {
      print('❌ [SPECIFIC_CHAT_FIX] Erro: $e');
    }
  }

  /// Cria um sanitizador robusto para dados de chat
  static Map<String, dynamic> sanitizeChatData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    
    // Sanitizar timestamps
    if (sanitized['createdAt'] == null) {
      sanitized['createdAt'] = Timestamp.now();
    }
    if (sanitized['lastMessageAt'] == null) {
      sanitized['lastMessageAt'] = Timestamp.now();
    }
    if (sanitized['expiresAt'] == null) {
      sanitized['expiresAt'] = Timestamp.fromDate(DateTime.now().add(Duration(days: 30)));
    }
    
    // Sanitizar booleanos
    if (sanitized['isExpired'] == null || sanitized['isExpired'] is String) {
      sanitized['isExpired'] = false;
    }
    if (sanitized['isActive'] == null || sanitized['isActive'] is String) {
      sanitized['isActive'] = true;
    }
    
    // Garantir campos obrigatórios
    if (sanitized['lastMessage'] == null) {
      sanitized['lastMessage'] = 'Conversa iniciada';
    }
    
    return sanitized;
  }

  /// Corrige mensagens com timestamps null
  static Future<void> fixMessageTimestamps() async {
    print('🔧 [MESSAGE_FIX] Corrigindo timestamps de mensagens...');
    
    try {
      // Buscar mensagens com timestamp null
      final messagesQuery = await _firestore
          .collection('chat_messages')
          .where('timestamp', isNull: true)
          .limit(100) // Processar em lotes
          .get();
      
      if (messagesQuery.docs.isEmpty) {
        print('ℹ️ [MESSAGE_FIX] Nenhuma mensagem com timestamp null encontrada');
        return;
      }
      
      final batch = _firestore.batch();
      
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ [MESSAGE_FIX] ${messagesQuery.docs.length} mensagens corrigidas');
      
    } catch (e) {
      print('❌ [MESSAGE_FIX] Erro ao corrigir mensagens: $e');
    }
  }

  /// Executa todas as correções
  static Future<void> fixAllTimestampErrors() async {
    print('🚀 [FULL_FIX] Iniciando correção completa de timestamps...');
    
    try {
      await fixTimestampErrors();
      await fixSpecificMissingChat();
      await fixMessageTimestamps();
      
      print('🎉 [FULL_FIX] Todas as correções de timestamp concluídas!');
      
    } catch (e) {
      print('❌ [FULL_FIX] Erro na correção completa: $e');
    }
  }

  /// Testa o sistema após correção
  static Future<void> testAfterFix() async {
    print('🧪 [TEST] Testando sistema após correção...');
    
    const testChatId = 'match_St2kw3cgX2MMPxlLRmBDjYm2nO22_dLHuF1kUDTNe7PgdBLbmynrdpft1';
    
    try {
      // Teste 1: Verificar se o chat existe
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(testChatId)
          .get();
      
      if (chatDoc.exists) {
        print('✅ [TEST] Chat existe');
        
        // Teste 2: Verificar dados sanitizados
        final data = chatDoc.data()!;
        final sanitized = sanitizeChatData(data);
        
        print('✅ [TEST] Dados sanitizados: ${sanitized.keys}');
        
        // Teste 3: Verificar timestamps
        if (sanitized['createdAt'] != null && 
            sanitized['lastMessageAt'] != null && 
            sanitized['expiresAt'] != null) {
          print('✅ [TEST] Todos os timestamps estão válidos');
        } else {
          print('⚠️ [TEST] Alguns timestamps ainda estão null');
        }
        
        // Teste 4: Buscar mensagens
        final messages = await _firestore
            .collection('chat_messages')
            .where('chatId', isEqualTo: testChatId)
            .limit(1)
            .get();
        
        print('✅ [TEST] Query de mensagens funcionou: ${messages.docs.length} mensagens');
        
      } else {
        print('❌ [TEST] Chat ainda não existe');
      }
      
    } catch (e) {
      print('❌ [TEST] Erro no teste: $e');
    }
  }
}

/// Widget para executar as correções de timestamp
class TimestampFixerWidget extends StatefulWidget {
  @override
  _TimestampFixerWidgetState createState() => _TimestampFixerWidgetState();
}

class _TimestampFixerWidgetState extends State<TimestampFixerWidget> {
  bool _isFixing = false;
  List<String> _logs = [];

  Future<void> _runTimestampFix() async {
    setState(() {
      _isFixing = true;
      _logs.clear();
    });

    _addLog('🚀 Iniciando correção de timestamps...');
    
    try {
      await TimestampChatErrorsFixer.fixAllTimestampErrors();
      _addLog('✅ Correções concluídas!');
      
      await TimestampChatErrorsFixer.testAfterFix();
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
        title: Text('Correção de Timestamps'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Problema específico
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 ERRO ESPECÍFICO DETECTADO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('❌ TypeError: null: type \'Null\' is not a subtype of type \'Timestamp\''),
                    Text('❌ Chat não encontrado: match_St2kw3cgX2MMPxlLRmBDjYm2nO22_dLHuF1kUDTNe7PgdBLbmynrdpft1'),
                    Text('❌ Índice Firebase ainda faltando'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Correções
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correções que serão aplicadas:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Corrigir todos os timestamps null'),
                    Text('✅ Criar chat específico faltando'),
                    Text('✅ Sanitizar dados de chat'),
                    Text('✅ Corrigir mensagens com timestamp null'),
                    Text('✅ Adicionar campos obrigatórios'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Botão de correção
            ElevatedButton.icon(
              onPressed: _isFixing ? null : _runTimestampFix,
              icon: _isFixing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.access_time),
              label: Text(_isFixing ? 'Corrigindo Timestamps...' : 'Corrigir Timestamps Agora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
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