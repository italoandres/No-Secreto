import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Sistema SIMPLES de notificações de interesse que funciona SEM índices do Firebase
class SimpleInterestNotifications {
  
  /// Cria uma notificação de interesse de forma SIMPLES
  static Future<void> createInterestNotification({
    required String interestedUserId,
    required String interestedUserName,
    required String targetUserId,
    String? interestedUserAvatar,
  }) async {
    try {
      // Não criar se for o mesmo usuário
      if (interestedUserId == targetUserId) return;
      
      // Criar documento simples no Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'id': 'interest_${DateTime.now().millisecondsSinceEpoch}',
        'userId': targetUserId,
        'type': 'interest_match',
        'relatedId': interestedUserId,
        'fromUserId': interestedUserId,
        'fromUserName': interestedUserName,
        'fromUserAvatar': interestedUserAvatar ?? '',
        'content': 'demonstrou interesse no seu perfil',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'contexto': 'interest_matches',
      });
      
      print('✅ Notificação de interesse criada com sucesso!');
      
      // Mostrar feedback visual
      Get.snackbar(
        '💕 Interesse Demonstrado!',
        'Sua notificação foi enviada para $interestedUserName',
        backgroundColor: Colors.pink,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ Erro ao criar notificação: $e');
      
      // Mostrar erro amigável
      Get.snackbar(
        '⚠️ Ops!',
        'Não foi possível enviar a notificação, tente novamente',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  /// Demonstra interesse em um usuário
  static Future<void> expressInterest({
    required String targetUserId,
    String? targetUserName,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Erro', 'Você precisa estar logado');
        return;
      }
      
      // Buscar dados do usuário atual
      String currentUserName = 'Usuário';
      String currentUserAvatar = '';
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          currentUserName = userData['nome'] ?? userData['displayName'] ?? 'Usuário';
          currentUserAvatar = userData['photoUrl'] ?? userData['avatar'] ?? '';
        }
      } catch (e) {
        print('Erro ao buscar dados do usuário: $e');
      }
      
      // Criar notificação
      await createInterestNotification(
        interestedUserId: currentUser.uid,
        interestedUserName: currentUserName,
        targetUserId: targetUserId,
        interestedUserAvatar: currentUserAvatar,
      );
      
    } catch (e) {
      print('Erro ao demonstrar interesse: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível demonstrar interesse',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  /// Cria notificações de teste
  static Future<void> createTestNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Erro', 'Você precisa estar logado');
        return;
      }
      
      // Criar 3 notificações de teste
      final testUsers = [
        {'name': 'Maria Silva', 'avatar': 'https://via.placeholder.com/150/FF69B4'},
        {'name': 'Ana Costa', 'avatar': 'https://via.placeholder.com/150/87CEEB'},
        {'name': 'Julia Santos', 'avatar': 'https://via.placeholder.com/150/98FB98'},
      ];
      
      for (int i = 0; i < testUsers.length; i++) {
        final user = testUsers[i];
        
        await FirebaseFirestore.instance.collection('notifications').add({
          'id': 'test_interest_${DateTime.now().millisecondsSinceEpoch}_$i',
          'userId': currentUser.uid,
          'type': 'interest_match',
          'relatedId': 'test_user_$i',
          'fromUserId': 'test_user_$i',
          'fromUserName': user['name']!,
          'fromUserAvatar': user['avatar']!,
          'content': 'demonstrou interesse no seu perfil',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'contexto': 'interest_matches',
        });
        
        // Aguardar um pouco entre as criações
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      Get.snackbar(
        '✅ Sucesso!',
        '${testUsers.length} notificações de teste criadas!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      print('Erro ao criar notificações de teste: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível criar notificações de teste: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  /// Limpa notificações de teste
  static Future<void> cleanupTestNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Buscar notificações de teste
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: 'interest_match')
          .get();
      
      // Deletar notificações que começam com 'test_'
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['fromUserId']?.toString().startsWith('test_') == true) {
          await doc.reference.delete();
        }
      }
      
      Get.snackbar(
        '🧹 Limpeza Concluída!',
        'Notificações de teste removidas',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      
    } catch (e) {
      print('Erro ao limpar notificações: $e');
    }
  }
  
  /// Marca todas as notificações como lidas
  static Future<void> markAllAsRead() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Buscar notificações não lidas
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: 'interest_match')
          .where('isRead', isEqualTo: false)
          .get();
      
      // Marcar como lidas
      for (final doc in query.docs) {
        await doc.reference.update({'isRead': true});
      }
      
      Get.snackbar(
        '✅ Concluído!',
        'Todas as notificações foram marcadas como lidas',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
    } catch (e) {
      print('Erro ao marcar como lidas: $e');
    }
  }
  
  /// Conta notificações não lidas
  static Future<int> getUnreadCount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;
      
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: 'interest_match')
          .where('isRead', isEqualTo: false)
          .get();
      
      return query.docs.length;
    } catch (e) {
      print('Erro ao contar notificações: $e');
      return 0;
    }
  }
}