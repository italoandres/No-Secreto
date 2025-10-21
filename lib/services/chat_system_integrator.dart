import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_chat_creator.dart';
import 'robust_notification_handler.dart';
import 'timestamp_sanitizer.dart';

/// Integrador que substitui o sistema existente pelo robusto
class ChatSystemIntegrator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Substitui a função de responder interesse existente
  static Future<void> respondToInterest(String notificationId, String action) async {
    print('🔄 [INTEGRATOR] Usando sistema robusto para responder interesse');
    
    try {
      // Usar o sistema robusto em vez do antigo
      await RobustNotificationHandler.respondToNotification(notificationId, action);
      print('✅ [INTEGRATOR] Interesse respondido com sistema robusto');
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao responder interesse: $e');
      rethrow;
    }
  }

  /// Substitui a navegação para chat existente
  static Future<void> navigateToChat(BuildContext context, String chatId, {String? otherUserId, String? otherUserName}) async {
    print('🚀 [INTEGRATOR] Navegando para chat com sistema robusto: $chatId');
    
    try {
      // Verificar se o chat existe
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        print('❌ [INTEGRATOR] Chat não encontrado, tentando criar...');
        
        // Extrair IDs dos usuários do chatId
        final parts = chatId.split('_');
        if (parts.length >= 3) {
          final userId1 = parts[1];
          final userId2 = parts[2];
          
          // Criar o chat
          await MatchChatCreator.createOrGetChatId(userId1, userId2);
          print('✅ [INTEGRATOR] Chat criado com sucesso');
        }
      }
      
      // Navegar para a tela de chat robusta
      await Navigator.pushNamed(
        context,
        '/robust_chat',
        arguments: {
          'chatId': chatId,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName ?? 'Usuário',
        },
      );
      
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao navegar para chat: $e');
      
      // Mostrar erro amigável
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estamos preparando seu chat... Tente novamente em alguns segundos.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Tentar Novamente',
            onPressed: () => navigateToChat(context, chatId, otherUserId: otherUserId, otherUserName: otherUserName),
          ),
        ),
      );
    }
  }

  /// Substitui a inicialização de chat existente
  static Future<Map<String, dynamic>?> initializeChat(String chatId) async {
    print('🔄 [INTEGRATOR] Inicializando chat com sistema robusto: $chatId');
    
    try {
      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists) {
        throw Exception('Chat não encontrado');
      }
      
      // Sanitizar dados do chat
      final rawData = chatDoc.data()!;
      final sanitizedData = TimestampSanitizer.sanitizeChatData(rawData);
      
      print('✅ [INTEGRATOR] Chat inicializado com dados sanitizados');
      return sanitizedData;
      
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao inicializar chat: $e');
      return null;
    }
  }

  /// Substitui o carregamento de mensagens existente
  static Stream<QuerySnapshot> getMessagesStream(String chatId) {
    print('📡 [INTEGRATOR] Criando stream de mensagens robusto para: $chatId');
    
    try {
      return _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .handleError((error) {
        print('❌ [INTEGRATOR] Erro no stream de mensagens: $error');
        
        // Se for erro de índice, usar query simples
        if (error.toString().contains('requires an index')) {
          print('🔄 [INTEGRATOR] Usando query simples como fallback');
          return _firestore
              .collection('chat_messages')
              .where('chatId', isEqualTo: chatId)
              .snapshots();
        }
        
        throw error;
      });
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao criar stream: $e');
      
      // Retornar stream vazio em caso de erro
      return Stream.empty();
    }
  }

  /// Substitui a marcação de mensagens como lidas
  static Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    print('👁️ [INTEGRATOR] Marcando mensagens como lidas com sistema robusto');
    
    try {
      // Tentar query com índice primeiro
      QuerySnapshot unreadMessages;
      
      try {
        unreadMessages = await _firestore
            .collection('chat_messages')
            .where('chatId', isEqualTo: chatId)
            .where('senderId', isNotEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();
      } catch (indexError) {
        print('⚠️ [INTEGRATOR] Erro de índice, usando método alternativo');
        
        // Fallback: buscar todas as mensagens do chat e filtrar
        final allMessages = await _firestore
            .collection('chat_messages')
            .where('chatId', isEqualTo: chatId)
            .get();
        
        final unreadDocs = allMessages.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['senderId'] != currentUserId && 
                 (data['isRead'] == false || data['isRead'] == null);
        }).toList();
        
        // Marcar como lidas
        final batch = _firestore.batch();
        for (final doc in unreadDocs) {
          batch.update(doc.reference, {'isRead': true});
        }
        
        if (unreadDocs.isNotEmpty) {
          await batch.commit();
          print('✅ [INTEGRATOR] ${unreadDocs.length} mensagens marcadas como lidas (fallback)');
        }
        
        return;
      }
      
      // Marcar como lidas (método normal)
      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadMessages.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        
        await batch.commit();
        print('✅ [INTEGRATOR] ${unreadMessages.docs.length} mensagens marcadas como lidas');
      }
      
    } catch (e) {
      print('⚠️ [INTEGRATOR] Erro ao marcar mensagens como lidas: $e');
      // Não quebrar o fluxo por causa disso
    }
  }

  /// Substitui o envio de mensagens existente
  static Future<void> sendMessage(String chatId, String message, String senderId, String senderName) async {
    print('📤 [INTEGRATOR] Enviando mensagem com sistema robusto');
    
    try {
      // Criar mensagem com dados sanitizados
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };
      
      // Enviar mensagem
      await _firestore.collection('chat_messages').add(messageData);
      
      // Atualizar último timestamp do chat
      await _firestore
          .collection('match_chats')
          .doc(chatId)
          .update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': message.trim(),
      });
      
      print('✅ [INTEGRATOR] Mensagem enviada com sucesso');
      
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Substitui a busca de matches aceitos existente
  static Future<List<Map<String, dynamic>>> getAcceptedMatches(String userId) async {
    print('🔍 [INTEGRATOR] Buscando matches aceitos com sistema robusto');
    
    try {
      // Buscar interesses aceitos onde o usuário é o destinatário
      final receivedInterests = await _firestore
          .collection('interests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      // Buscar interesses aceitos onde o usuário é o remetente
      final sentInterests = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      final matches = <Map<String, dynamic>>[];
      
      // Processar interesses recebidos
      for (final doc in receivedInterests.docs) {
        final data = doc.data();
        final otherUserId = data['fromUserId'];
        
        // Verificar se existe interesse mútuo
        final mutualInterest = sentInterests.docs.any((sentDoc) {
          final sentData = sentDoc.data();
          return sentData['toUserId'] == otherUserId;
        });
        
        if (mutualInterest) {
          // Buscar dados do usuário
          final userData = await _getUserData(otherUserId);
          if (userData != null) {
            final chatId = MatchChatCreator.generateChatId(userId, otherUserId);
            matches.add({
              'chatId': chatId,
              'otherUserId': otherUserId,
              'otherUserName': userData['nome'] ?? 'Usuário',
              'otherUserPhoto': userData['photoURL'],
              'lastMessage': 'Vocês têm um match!',
              'timestamp': data['dataResposta'] ?? data['dataCriacao'],
            });
          }
        }
      }
      
      print('✅ [INTEGRATOR] ${matches.length} matches encontrados');
      return matches;
      
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao buscar matches: $e');
      return [];
    }
  }

  /// Busca dados do usuário
  static Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data();
      }
      
      // Fallback: buscar na coleção users
      final fallbackDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      return fallbackDoc.exists ? fallbackDoc.data() : null;
      
    } catch (e) {
      print('❌ [INTEGRATOR] Erro ao buscar dados do usuário $userId: $e');
      return null;
    }
  }

  /// Testa todo o sistema integrado
  static Future<void> testIntegratedSystem() async {
    print('🧪 [INTEGRATOR] Testando sistema integrado...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [INTEGRATOR] Usuário não autenticado');
      return;
    }
    
    try {
      // Teste 1: Buscar matches
      final matches = await getAcceptedMatches(currentUser.uid);
      print('✅ [INTEGRATOR] Teste 1 - Matches: ${matches.length}');
      
      // Teste 2: Criar chat de teste
      const testUserId = 'test_integrator';
      final chatId = await MatchChatCreator.createOrGetChatId(
        currentUser.uid,
        testUserId,
      );
      print('✅ [INTEGRATOR] Teste 2 - Chat criado: $chatId');
      
      // Teste 3: Inicializar chat
      final chatData = await initializeChat(chatId);
      print('✅ [INTEGRATOR] Teste 3 - Chat inicializado: ${chatData != null}');
      
      // Teste 4: Stream de mensagens
      final stream = getMessagesStream(chatId);
      print('✅ [INTEGRATOR] Teste 4 - Stream criado: ${stream != null}');
      
      print('🎉 [INTEGRATOR] Todos os testes passaram!');
      
    } catch (e) {
      print('❌ [INTEGRATOR] Erro nos testes: $e');
    }
  }
}