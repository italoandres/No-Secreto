import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/repositories/notification_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp_chat/views/enhanced_stories_viewer_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Criar notificação de comentário em story
  static Future<void> createCommentNotification({
    required String storyId,
    required String storyAuthorId,
    required String commentAuthorId,
    required String commentAuthorName,
    required String commentAuthorAvatar,
    required String commentText,
    String? contexto,
  }) async {
    try {
      // Não criar notificação se o autor do comentário for o mesmo do story
      if (commentAuthorId == storyAuthorId) {
        return;
      }

      // Gerar ID único para a notificação
      final notificationId = _generateNotificationId(storyId, commentAuthorId);

      // Truncar o texto do comentário
      final truncatedComment = truncateComment(commentText);

      // Criar modelo da notificação
      final notification = NotificationModel(
        id: notificationId,
        userId: storyAuthorId,
        type: 'story_comment',
        relatedId: storyId,
        fromUserId: commentAuthorId,
        fromUserName: commentAuthorName,
        fromUserAvatar: commentAuthorAvatar,
        content: truncatedComment,
        isRead: false,
        timestamp: DateTime.now(),
        contexto: contexto,
      );

      // Salvar no Firestore
      await NotificationRepository.createNotification(notification);

      print('Notificação de comentário criada: $notificationId');
    } catch (e) {
      print('Erro ao criar notificação de comentário: $e');
      // Não relançar o erro para não bloquear a criação do comentário
    }
  }

  // Criar notificação de menção em comentário
  static Future<void> createMentionNotification({
    required String storyId,
    required String mentionedUserId,
    required String commentAuthorId,
    required String commentAuthorName,
    required String commentAuthorAvatar,
    required String commentText,
    String? contexto,
  }) async {
    try {
      // Não criar notificação se o autor do comentário for o mesmo usuário mencionado
      if (commentAuthorId == mentionedUserId) {
        return;
      }

      // Gerar ID único para a notificação de menção
      final notificationId = _generateMentionNotificationId(
          storyId, mentionedUserId, commentAuthorId);

      // Truncar o texto do comentário
      final truncatedComment = truncateComment(commentText);

      // Criar modelo da notificação
      final notification = NotificationModel(
        id: notificationId,
        userId: mentionedUserId,
        type: 'comment_mention',
        relatedId: storyId,
        fromUserId: commentAuthorId,
        fromUserName: commentAuthorName,
        fromUserAvatar: commentAuthorAvatar,
        content: truncatedComment,
        isRead: false,
        timestamp: DateTime.now(),
        contexto: contexto,
      );

      // Salvar no Firestore
      await NotificationRepository.createNotification(notification);

      print('Notificação de menção criada: $notificationId');
    } catch (e) {
      print('Erro ao criar notificação de menção: $e');
      // Não relançar o erro para não bloquear a criação do comentário
    }
  }

  // Criar notificação de curtida em comentário
  static Future<void> createCommentLikeNotification({
    required String storyId,
    required String commentId,
    required String commentAuthorId,
    required String likerUserId,
    required String likerUserName,
    required String likerUserAvatar,
    required String commentText,
    String? contexto,
  }) async {
    try {
      // Não criar notificação se quem curtiu for o próprio autor do comentário
      if (likerUserId == commentAuthorId) {
        return;
      }

      // Gerar ID único para a notificação de curtida
      final notificationId =
          _generateLikeNotificationId(commentId, likerUserId);

      // Truncar o texto do comentário
      final truncatedComment = truncateComment(commentText);

      // Criar modelo da notificação
      final notification = NotificationModel(
        id: notificationId,
        userId: commentAuthorId,
        type: 'comment_like',
        relatedId: commentId, // ID do comentário, não do story
        fromUserId: likerUserId,
        fromUserName: likerUserName,
        fromUserAvatar: likerUserAvatar,
        content: truncatedComment,
        isRead: false,
        timestamp: DateTime.now(),
        contexto: contexto,
      );

      // Salvar no Firestore
      await NotificationRepository.createNotification(notification);

      print('Notificação de curtida criada: $notificationId');
    } catch (e) {
      print('Erro ao criar notificação de curtida: $e');
      // Não relançar o erro para não bloquear a curtida
    }
  }

  // Criar notificação de resposta a comentário
  static Future<void> createCommentReplyNotification({
    required String storyId,
    required String parentCommentId,
    required String parentCommentAuthorId,
    required String replyAuthorId,
    required String replyAuthorName,
    required String replyAuthorAvatar,
    required String replyText,
    String? contexto,
  }) async {
    try {
      // Não criar notificação se quem respondeu for o próprio autor do comentário
      if (replyAuthorId == parentCommentAuthorId) {
        return;
      }

      // Gerar ID único para a notificação de resposta
      final notificationId =
          _generateReplyNotificationId(parentCommentId, replyAuthorId);

      // Truncar o texto da resposta
      final truncatedReply = truncateComment(replyText);

      // Criar modelo da notificação
      final notification = NotificationModel(
        id: notificationId,
        userId: parentCommentAuthorId,
        type: 'comment_reply',
        relatedId: parentCommentId, // ID do comentário pai
        fromUserId: replyAuthorId,
        fromUserName: replyAuthorName,
        fromUserAvatar: replyAuthorAvatar,
        content: truncatedReply,
        isRead: false,
        timestamp: DateTime.now(),
        contexto: contexto,
      );

      // Salvar no Firestore
      await NotificationRepository.createNotification(notification);

      print('Notificação de resposta criada: $notificationId');
    } catch (e) {
      print('Erro ao criar notificação de resposta: $e');
      // Não relançar o erro para não bloquear a resposta
    }
  }

  // Processar comentário e criar notificações necessárias
  static Future<void> processCommentNotifications({
    required String storyId,
    required String storyAuthorId,
    required String commentAuthorId,
    required String commentAuthorName,
    required String commentAuthorAvatar,
    required String commentText,
    String? contexto,
  }) async {
    // Criar notificação para o autor do story
    await createCommentNotification(
      storyId: storyId,
      storyAuthorId: storyAuthorId,
      commentAuthorId: commentAuthorId,
      commentAuthorName: commentAuthorName,
      commentAuthorAvatar: commentAuthorAvatar,
      commentText: commentText,
      contexto: contexto,
    );

    // Extrair menções do texto e criar notificações
    final mentionedUserIds = extractMentionsFromText(commentText);

    for (final mentionedUserId in mentionedUserIds) {
      await createMentionNotification(
        storyId: storyId,
        mentionedUserId: mentionedUserId,
        commentAuthorId: commentAuthorId,
        commentAuthorName: commentAuthorName,
        commentAuthorAvatar: commentAuthorAvatar,
        commentText: commentText,
        contexto: contexto,
      );
    }
  }

  // Formatar tempo relativo (ex: "há 2 horas", "há 1 dia")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'há ${minutes}min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'há ${hours}h';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'há ${days}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'há ${weeks}sem';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'há ${months}mês';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'há ${years}ano';
    }
  }

  // Truncar texto do comentário para exibição na notificação
  static String truncateComment(String comment, {int maxLength = 100}) {
    if (comment.length <= maxLength) {
      return comment;
    }

    // Truncar e adicionar reticências
    return '${comment.substring(0, maxLength - 3)}...';
  }

  // Gerar ID único para notificação baseado no story e usuário
  static String _generateNotificationId(String storyId, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'notif_${storyId}_${userId}_$timestamp';
  }

  // Gerar ID único para notificação de menção
  static String _generateMentionNotificationId(
      String storyId, String mentionedUserId, String authorId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'mention_${storyId}_${mentionedUserId}_${authorId}_$timestamp';
  }

  // Gerar ID único para notificação de curtida
  static String _generateLikeNotificationId(
      String commentId, String likerUserId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'like_${commentId}_${likerUserId}_$timestamp';
  }

  // Gerar ID único para notificação de resposta
  static String _generateReplyNotificationId(
      String parentCommentId, String replyAuthorId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'reply_${parentCommentId}_${replyAuthorId}_$timestamp';
  }

  // Extrair IDs de usuários mencionados do texto (@usuario)
  static List<String> extractMentionsFromText(String text) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);

    // Extrair usernames mencionados
    final usernames = <String>[];
    for (final match in matches) {
      final username = match.group(1);
      if (username != null) {
        usernames.add(username);
      }
    }

    return usernames;
  }

  // Extrair menções com informações completas do usuário
  static Future<List<String>> extractMentionUserIds(String text) async {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    final userIds = <String>[];

    for (final match in matches) {
      final username = match.group(1);
      if (username != null) {
        final userId = await _getUserIdByUsername(username);
        if (userId != null) {
          userIds.add(userId);
        }
      }
    }

    return userIds;
  }

  // Buscar ID do usuário pelo username
  static Future<String?> _getUserIdByUsername(String username) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      return null;
    } catch (e) {
      print('Erro ao buscar usuário por username: $e');
      return null;
    }
  }

  // Formatar texto da notificação baseado no tipo
  static String formatNotificationText(NotificationModel notification) {
    switch (notification.type) {
      case 'comment_mention':
        return '${notification.fromUserName} mencionou você: ${notification.content}';
      case 'comment_like':
        return '${notification.fromUserName} curtiu seu comentário: ${notification.content}';
      case 'comment_reply':
        return '${notification.fromUserName} respondeu seu comentário: ${notification.content}';
      default:
        return notification.content;
    }
  }

  // Verificar se o usuário atual pode receber notificações
  static bool canReceiveNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  // Obter ID do usuário atual
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Limpar notificações antigas automaticamente
  static Future<void> cleanupOldNotifications() async {
    try {
      await NotificationRepository.cleanOldNotifications();
    } catch (e) {
      print('Erro na limpeza automática de notificações: $e');
    }
  }

  // Marcar notificação como lida e navegar para o conteúdo
  static Future<void> handleNotificationTap(
      NotificationModel notification) async {
    try {
      // Marcar como lida se não estiver
      if (!notification.isRead) {
        await NotificationRepository.markAsRead(notification.id);
      }

      // Navegar baseado no tipo de notificação
      switch (notification.type) {
        case 'comment_mention':
        case 'comment_like':
        case 'comment_reply':
          // Para notificações de comentário, navegar para o story onde está o comentário
          await _navigateToStory(notification.relatedId);
          break;
        default:
          print('Tipo de notificação não reconhecido: ${notification.type}');
      }
    } catch (e) {
      print('Erro ao processar tap na notificação: $e');
    }
  }

  // Navegar para o story específico
  static Future<void> _navigateToStory(String storyId) async {
    try {
      // Navegar para o viewer de stories com o story específico
      Get.to(() => const EnhancedStoriesViewerView(
            contexto: 'notification',
            userSexo: null, // Todos os usuários
            // TODO: Adicionar parâmetro initialStoryId se disponível
          ));

      print('Navegando para story: $storyId');
    } catch (e) {
      print('Erro ao navegar para story: $e');

      // Fallback: mostrar mensagem informativa
      Get.snackbar(
        'Aviso',
        'Story não encontrado ou não disponível',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  // Verificar se uma notificação é válida
  static bool isValidNotification(NotificationModel notification) {
    return notification.id.isNotEmpty &&
        notification.userId.isNotEmpty &&
        notification.type.isNotEmpty &&
        notification.relatedId.isNotEmpty &&
        notification.fromUserId.isNotEmpty &&
        notification.fromUserName.isNotEmpty;
  }

  // Contar notificações não lidas para um usuário
  static Stream<int> getUnreadNotificationsCount(String userId) {
    return NotificationRepository.getUnreadCount(userId);
  }

  // Buscar notificações do usuário
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return NotificationRepository.getUserNotifications(userId);
  }

  // Contar notificações não lidas para um contexto específico
  static Stream<int> getContextUnreadCount(String userId, String contexto) {
    return NotificationRepository.getContextUnreadCount(userId, contexto);
  }

  // Buscar notificações do usuário para um contexto específico
  static Stream<List<NotificationModel>> getContextNotifications(
      String userId, String contexto) {
    return NotificationRepository.getContextNotifications(userId, contexto);
  }

  // Marcar todas as notificações de um contexto como lidas
  static Future<void> markContextNotificationsAsRead(
      String userId, String contexto) async {
    try {
      await NotificationRepository.markContextAsRead(userId, contexto);
    } catch (e) {
      print('Erro ao marcar notificações do contexto como lidas: $e');
      rethrow;
    }
  }

  // Marcar todas as notificações como lidas
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await NotificationRepository.markAllAsRead(userId);
    } catch (e) {
      print('Erro ao marcar todas as notificações como lidas: $e');
      rethrow;
    }
  }

  // Deletar uma notificação
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await NotificationRepository.deleteNotification(notificationId);
    } catch (e) {
      print('Erro ao deletar notificação: $e');
      rethrow;
    }
  }

  // ========== MÉTODOS PARA NOTIFICAÇÕES DE INTERESSE EM MATCHES ==========

  // Criar notificação de interesse em match
  static Future<void> createInterestNotification({
    required String interestedUserId,
    required String interestedUserName,
    required String interestedUserAvatar,
    required String targetUserId,
  }) async {
    try {
      // Validações de entrada
      if (interestedUserId.isEmpty || targetUserId.isEmpty) {
        print('IDs de usuário inválidos para notificação de interesse');
        return;
      }

      // Não criar notificação se o usuário demonstrar interesse em si mesmo
      if (interestedUserId == targetUserId) {
        print('Usuário tentou demonstrar interesse em si mesmo - ignorando');
        return;
      }

      // Verificar se já existe notificação similar recente (últimas 24h)
      final existingNotifications =
          await NotificationRepository.getContextNotifications(
                  targetUserId, 'interest_matches')
              .first;

      final recentNotification = existingNotifications
          .where((n) =>
              n.fromUserId == interestedUserId &&
              DateTime.now().difference(n.createdAt).inHours < 24)
          .isNotEmpty;

      if (recentNotification) {
        print(
            'Notificação de interesse já existe nas últimas 24h - ignorando duplicata');
        return;
      }

      // Gerar ID único para a notificação de interesse
      final notificationId =
          _generateInterestNotificationId(targetUserId, interestedUserId);

      // Criar modelo da notificação
      final notification = NotificationModel(
        id: notificationId,
        userId: targetUserId, // Quem recebe a notificação
        type: 'interest_match', // Novo tipo de notificação
        relatedId: interestedUserId, // ID do usuário que demonstrou interesse
        fromUserId: interestedUserId,
        fromUserName:
            interestedUserName.isNotEmpty ? interestedUserName : 'Usuário',
        fromUserAvatar: interestedUserAvatar,
        content: 'demonstrou interesse no seu perfil',
        isRead: false,
        timestamp: DateTime.now(),
        contexto: 'interest_matches', // Contexto específico
      );

      // Salvar no Firestore com retry
      await _createNotificationWithRetry(notification);

      print('Notificação de interesse criada: $notificationId');
    } catch (e) {
      print('Erro ao criar notificação de interesse: $e');
      // Não relançar o erro para não bloquear o processo de demonstração de interesse
    }
  }

  // Criar notificação com retry automático
  static Future<void> _createNotificationWithRetry(
      NotificationModel notification,
      {int maxRetries = 3}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await NotificationRepository.createNotification(notification);
        return; // Sucesso
      } catch (e) {
        attempts++;
        print('Tentativa $attempts de $maxRetries falhou: $e');

        if (attempts >= maxRetries) {
          rethrow; // Última tentativa falhou
        }

        // Aguardar antes da próxima tentativa
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  // Processar demonstração de interesse e criar notificação
  static Future<void> processInterestNotification({
    required String interestedUserId,
    required String targetUserId,
    String? interestedUserName,
    String? interestedUserAvatar,
  }) async {
    try {
      // Se não foram fornecidos nome e avatar, buscar do Firestore
      String userName = interestedUserName ?? 'Usuário';
      String userAvatar = interestedUserAvatar ?? '';

      if (interestedUserName == null || interestedUserAvatar == null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(interestedUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['nome'] ?? userData['displayName'] ?? 'Usuário';
          userAvatar = userData['photoUrl'] ?? userData['avatar'] ?? '';
        }

        // Se ainda não encontrou, tentar na coleção de perfis espirituais
        if (userName == 'Usuário') {
          final profileDoc = await FirebaseFirestore.instance
              .collection('spiritual_profiles')
              .doc(interestedUserId)
              .get();

          if (profileDoc.exists) {
            final profileData = profileDoc.data() as Map<String, dynamic>;
            userName = profileData['displayName'] ?? 'Usuário';
            userAvatar =
                profileData['mainPhotoUrl'] ?? profileData['photoUrl'] ?? '';
          }
        }
      }

      // Criar notificação de interesse com dados completos
      await createInterestNotification(
        interestedUserId: interestedUserId,
        interestedUserName: userName,
        interestedUserAvatar: userAvatar,
        targetUserId: targetUserId,
      );

      print(
          'Notificação de interesse processada com dados: nome=$userName, avatar=${userAvatar.isNotEmpty ? 'sim' : 'não'}');
    } catch (e) {
      print('Erro ao processar notificação de interesse: $e');
      // Fallback: criar notificação com dados básicos
      await createInterestNotification(
        interestedUserId: interestedUserId,
        interestedUserName: interestedUserName ?? 'Usuário',
        interestedUserAvatar: interestedUserAvatar ?? '',
        targetUserId: targetUserId,
      );
    }
  }

  // Gerar ID único para notificação de interesse
  static String _generateInterestNotificationId(
      String targetUserId, String interestedUserId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'interest_${targetUserId}_${interestedUserId}_$timestamp';
  }
}
