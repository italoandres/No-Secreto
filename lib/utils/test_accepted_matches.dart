import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utilitário para testar o sistema de matches aceitos
class TestAcceptedMatches {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cria uma notificação de interesse aceita para teste
  static Future<void> createTestAcceptedMatch() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não está logado');
      }

      print('🧪 Criando match aceito de teste...');

      // Criar notificação de interesse aceita
      final testNotification = {
        'fromUserId': 'test_match_user_id',
        'fromUserName': 'Usuário Teste Match',
        'fromUserEmail': 'teste.match@gmail.com',
        'toUserId': currentUser.uid,
        'toUserEmail': currentUser.email ?? '',
        'type': 'interest',
        'message': 'Demonstrou interesse no seu perfil (TESTE MATCH)',
        'status': 'accepted', // Já aceito
        'dataCriacao': Timestamp.now(),
        'dataResposta': Timestamp.now(), // Data de aceitação
        'isRead': false,
      };

      final docRef = await _firestore
          .collection('interest_notifications')
          .add(testNotification);

      print('✅ Notificação de match aceito criada: ${docRef.id}');

      // Criar usuário teste se não existir
      await _createTestUser();

      // Criar chat de teste
      await _createTestChat(currentUser.uid);

      Get.snackbar(
        'Teste Criado! 🎉',
        'Match aceito de teste criado com sucesso!\nVerifique o botão de matches.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.favorite, color: Colors.white),
      );

    } catch (e) {
      print('❌ Erro ao criar match aceito de teste: $e');
      Get.snackbar(
        'Erro',
        'Erro ao criar teste: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Cria usuário de teste se não existir
  static Future<void> _createTestUser() async {
    try {
      const testUserId = 'test_match_user_id';
      
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(testUserId)
          .get();

      if (!userDoc.exists) {
        await _firestore
            .collection('usuarios')
            .doc(testUserId)
            .set({
          'nome': 'Usuário Teste Match',
          'email': 'teste.match@gmail.com',
          'username': 'teste_match',
          'photoURL': null,
          'dataCadastro': Timestamp.now(),
          'isActive': true,
        });

        print('✅ Usuário de teste criado');
      } else {
        print('ℹ️ Usuário de teste já existe');
      }
    } catch (e) {
      print('⚠️ Erro ao criar usuário de teste: $e');
    }
  }

  /// Cria chat de teste
  static Future<void> _createTestChat(String currentUserId) async {
    try {
      const testUserId = 'test_match_user_id';
      
      // Gerar ID único do chat
      final sortedIds = [currentUserId, testUserId]..sort();
      final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

      final chatDoc = await _firestore
          .collection('match_chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        await _firestore
            .collection('match_chats')
            .doc(chatId)
            .set({
          'user1Id': sortedIds[0],
          'user2Id': sortedIds[1],
          'createdAt': Timestamp.now(),
          'lastMessage': 'Chat criado a partir de interesse aceito!',
          'lastMessageAt': Timestamp.now(),
          'isExpired': false,
          'unreadCount': {
            currentUserId: 1, // 1 mensagem não lida para o usuário atual
            testUserId: 0,
          },
        });

        // Adicionar mensagem de boas-vindas
        await _firestore
            .collection('chat_messages')
            .add({
          'chatId': chatId,
          'senderId': 'system',
          'senderName': 'Sistema',
          'message': '🎉 Vocês têm um match! Este é um chat de teste. Aproveitem para se conhecer melhor! 💕',
          'timestamp': Timestamp.now(),
          'type': 'system',
          'isRead': false,
        });

        print('✅ Chat de teste criado: $chatId');
      } else {
        print('ℹ️ Chat de teste já existe');
      }
    } catch (e) {
      print('⚠️ Erro ao criar chat de teste: $e');
    }
  }

  /// Remove todos os dados de teste
  static Future<void> cleanupTestData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      print('🧹 Limpando dados de teste...');

      // Remover notificações de teste
      final testNotifications = await _firestore
          .collection('interest_notifications')
          .where('fromUserId', isEqualTo: 'test_match_user_id')
          .get();

      for (final doc in testNotifications.docs) {
        await doc.reference.delete();
      }

      // Remover chat de teste
      const testUserId = 'test_match_user_id';
      final sortedIds = [currentUser.uid, testUserId]..sort();
      final chatId = 'match_${sortedIds[0]}_${sortedIds[1]}';

      await _firestore.collection('match_chats').doc(chatId).delete();

      // Remover mensagens do chat de teste
      final testMessages = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .get();

      for (final doc in testMessages.docs) {
        await doc.reference.delete();
      }

      // Remover usuário de teste
      await _firestore.collection('usuarios').doc(testUserId).delete();

      print('✅ Dados de teste removidos');

      Get.snackbar(
        'Limpeza Concluída! 🧹',
        'Todos os dados de teste foram removidos.',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );

    } catch (e) {
      print('❌ Erro ao limpar dados de teste: $e');
      Get.snackbar(
        'Erro na Limpeza',
        'Erro ao remover dados de teste: $e',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Mostra diálogo de teste
  static void showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.blue),
            SizedBox(width: 8),
            Text('Teste de Matches Aceitos'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este teste criará:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Um usuário de teste'),
            Text('• Uma notificação de interesse aceita'),
            Text('• Um chat com mensagem de boas-vindas'),
            Text('• Contador de mensagens não lidas'),
            SizedBox(height: 16),
            Text(
              'Após o teste, você poderá ver o match na tela de "Matches Aceitos" e abrir o chat.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await cleanupTestData();
            },
            child: const Text('Limpar Testes', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await createTestAcceptedMatch();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Criar Teste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}