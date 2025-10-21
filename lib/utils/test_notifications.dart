import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/services/notification_service.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/repositories/notification_repository.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class TestNotifications {
  // Criar uma notificação de teste para verificar se o sistema está funcionando
  static Future<void> createTestNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    print('🧪 TESTE: Iniciando criação de notificação...');
    print('🧪 TESTE: Usuário atual: ${currentUser?.uid}');
    
    if (currentUser == null) {
      print('❌ TESTE: Usuário não autenticado');
      Get.snackbar(
        'Erro',
        'Usuário não autenticado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('🧪 TESTE: Criando notificação de comentário...');
      
      await NotificationService.createCommentNotification(
        storyId: 'test_story_id',
        storyAuthorId: currentUser.uid,
        commentAuthorId: 'test_user_id',
        commentAuthorName: 'Usuário Teste',
        commentAuthorAvatar: '',
        commentText: 'Este é um comentário de teste para verificar as notificações!',
      );
      
      print('✅ TESTE: Notificação criada com sucesso!');
      
      Get.snackbar(
        'Sucesso',
        'Notificação de teste criada!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      print('Notificação de teste criada com sucesso!');
    } catch (e) {
      print('❌ TESTE: Erro ao criar notificação: $e');
      
      Get.snackbar(
        'Erro',
        'Erro ao criar notificação: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      print('Erro ao criar notificação de teste: $e');
    }
  }

  // Criar uma notificação de menção de teste
  static Future<void> createTestMentionNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Erro',
        'Usuário não autenticado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await NotificationService.createMentionNotification(
        storyId: 'test_story_id',
        mentionedUserId: currentUser.uid,
        commentAuthorId: 'test_user_id',
        commentAuthorName: 'Usuário Teste',
        commentAuthorAvatar: '',
        commentText: 'Olá @usuario, este é um teste de menção!',
      );
      
      Get.snackbar(
        'Sucesso',
        'Notificação de menção criada!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      print('Notificação de menção de teste criada com sucesso!');
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao criar notificação: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Erro ao criar notificação de menção de teste: $e');
    }
  }

  // Criar notificação de curtida de teste
  static Future<void> createTestLikeNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    print('❤️ TESTE: Iniciando criação de notificação de curtida...');
    
    if (currentUser == null) {
      print('❌ TESTE: Usuário não autenticado');
      Get.snackbar(
        'Erro',
        'Usuário não autenticado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('❤️ TESTE: Criando notificação de curtida...');
      
      await NotificationService.createCommentLikeNotification(
        storyId: 'test_story_id',
        commentId: 'test_comment_id',
        commentAuthorId: currentUser.uid,
        likerUserId: 'test_liker_id',
        likerUserName: 'Usuário que Curtiu',
        likerUserAvatar: '',
        commentText: 'Este é meu comentário que foi curtido!',
      );
      
      print('✅ TESTE: Notificação de curtida criada!');
      
      Get.snackbar(
        'Sucesso',
        'Notificação de curtida criada!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      print('Notificação de curtida de teste criada com sucesso!');
    } catch (e) {
      print('❌ TESTE: Erro ao criar notificação de curtida: $e');
      
      Get.snackbar(
        'Erro',
        'Erro ao criar notificação: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      print('Erro ao criar notificação de curtida de teste: $e');
    }
  }

  // Criar notificação de resposta de teste
  static Future<void> createTestReplyNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Erro',
        'Usuário não autenticado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await NotificationService.createCommentReplyNotification(
        storyId: 'test_story_id',
        parentCommentId: 'test_parent_comment_id',
        parentCommentAuthorId: currentUser.uid,
        replyAuthorId: 'test_reply_author_id',
        replyAuthorName: 'Usuário que Respondeu',
        replyAuthorAvatar: '',
        replyText: 'Esta é uma resposta ao seu comentário!',
      );
      
      Get.snackbar(
        'Sucesso',
        'Notificação de resposta criada!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      print('Notificação de resposta de teste criada com sucesso!');
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao criar notificação: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Erro ao criar notificação de resposta de teste: $e');
    }
  }

  // Teste direto no repositório (mais simples)
  static Future<void> createDirectTestNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('❌ TESTE DIRETO: Usuário não autenticado');
      Get.snackbar(
        'Erro',
        'Usuário não autenticado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('🔥 TESTE DIRETO: Criando notificação diretamente...');
      
      final notification = NotificationModel(
        id: 'test_direct_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.uid,
        type: 'comment_like',
        relatedId: 'test_story_direct',
        fromUserId: 'test_direct_user',
        fromUserName: 'Teste Direto',
        fromUserAvatar: '',
        content: 'Esta é uma notificação criada diretamente!',
        isRead: false,
        timestamp: DateTime.now(),
      );
      
      await NotificationRepository.createNotification(notification);
      
      print('✅ TESTE DIRETO: Notificação criada com sucesso!');
      
      Get.snackbar(
        'Sucesso',
        'Notificação direta criada!',
        backgroundColor: Colors.purple,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      print('❌ TESTE DIRETO: Erro: $e');
      
      Get.snackbar(
        'Erro',
        'Erro no teste direto: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Criar todas as notificações de teste de uma vez
  static Future<void> createAllTestNotifications() async {
    Get.snackbar(
      'Teste',
      'Criando todas as notificações de teste...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // Aguardar um pouco entre cada criação para ver o efeito
    await createTestMentionNotification();
    await Future.delayed(const Duration(milliseconds: 500));
    
    await createTestLikeNotification();
    await Future.delayed(const Duration(milliseconds: 500));
    
    await createTestReplyNotification();
    
    Get.snackbar(
      'Concluído',
      'Todas as notificações de teste foram criadas!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Adicionar botão de teste na página de notificações (apenas para debug)
  static Widget buildTestButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            '🧪 Testes de Notificação',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Teste de Menção
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: createTestMentionNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.alternate_email, size: 20),
              label: const Text('Teste: @menção em comentário'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Teste de Curtida
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: createTestLikeNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.favorite_outline, size: 20),
              label: const Text('Teste: ❤️ curtida no comentário'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Teste de Resposta
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: createTestReplyNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.reply_outlined, size: 20),
              label: const Text('Teste: 💬 resposta ao comentário'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informação sobre os testes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Como testar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Toque em um dos botões acima\n'
                  '2. Veja a notificação aparecer na lista\n'
                  '3. Observe o ícone e contador atualizarem\n'
                  '4. Toque na notificação para navegar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botão para testar todas de uma vez
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: createAllTestNotifications,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: BorderSide(color: Colors.purple.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.rocket_launch_outlined, size: 20),
              label: const Text('🚀 Testar Todas as Notificações'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Botão de teste direto (para debug)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: createDirectTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.bug_report_outlined, size: 20),
              label: const Text('🔥 Teste Direto (Debug)'),
            ),
          ),
        ],
      ),
    );
  }
}