import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/interest_notification_model.dart';
import '../models/interest_status.dart';
import '../repositories/interest_notification_repository.dart';
import '../services/match_chat_integrator.dart';
import '../utils/enhanced_logger.dart';

/// Serviço integrador do sistema de interesse
class InterestSystemIntegrator {
  static final InterestSystemIntegrator _instance = InterestSystemIntegrator._internal();
  factory InterestSystemIntegrator() => _instance;
  InterestSystemIntegrator._internal();

  /// Enviar interesse para um usuário
  Future<bool> sendInterest({
    required String targetUserId,
    required String targetUserName,
    String? targetUserEmail,
    String? message,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        EnhancedLogger.error('Usuário não autenticado', tag: 'INTEREST_INTEGRATOR');
        _showErrorSnackbar('Você precisa estar logado para demonstrar interesse');
        return false;
      }

      // Verificar se já existe interesse
      final hasInterest = await InterestNotificationRepository.hasUserShownInterest(
        currentUser.uid,
        targetUserId,
      );

      if (hasInterest) {
        _showInfoSnackbar('Você já demonstrou interesse neste perfil');
        return false;
      }

      // Buscar dados do usuário do Firestore
      EnhancedLogger.info('Buscando dados do usuário do Firestore', 
        tag: 'INTEREST_INTEGRATOR',
        data: {'userId': currentUser.uid}
      );
      
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('Dados do usuário não encontrados');
      }
      
      final userData = userDoc.data()!;
      final fromUserName = userData['nome'] ?? userData['username'] ?? 'Usuário';
      final fromUserEmail = userData['email'] ?? currentUser.email ?? '';
      
      EnhancedLogger.info('Dados do usuário obtidos', 
        tag: 'INTEREST_INTEGRATOR',
        data: {
          'nome': fromUserName,
          'email': fromUserEmail,
        }
      );
      
      // Criar notificação de interesse
      await InterestNotificationRepository.createInterestNotification(
        fromUserId: currentUser.uid,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        toUserId: targetUserId,
        toUserEmail: targetUserEmail ?? '',
        message: message ?? 'Demonstrou interesse no seu perfil',
      );

      EnhancedLogger.info('Interesse enviado com sucesso', 
        tag: 'INTEREST_INTEGRATOR',
        data: {
          'fromUserId': currentUser.uid,
          'toUserId': targetUserId,
        }
      );

      _showSuccessSnackbar('Interesse enviado com sucesso! 💕');
      return true;

    } catch (e) {
      EnhancedLogger.error('Erro ao enviar interesse: $e', tag: 'INTEREST_INTEGRATOR');
      _showErrorSnackbar('Erro ao enviar interesse. Tente novamente.');
      return false;
    }
  }

  /// Responder a um interesse
  Future<bool> respondToInterest({
    required String notificationId,
    required InterestStatus response,
  }) async {
    try {
      await InterestNotificationRepository.respondToInterestNotification(notificationId, response.value);

      String message;
      switch (response) {
        case InterestStatus.accepted:
          message = 'Interesse aceito! Um chat foi criado para vocês! 💕';
          break;
        case InterestStatus.rejected:
          message = 'Resposta enviada';
          break;
        default:
          message = 'Status atualizado';
      }

      _showSuccessSnackbar(message);
      return true;

    } catch (e) {
      EnhancedLogger.error('Erro ao responder interesse: $e', tag: 'INTEREST_INTEGRATOR');
      _showErrorSnackbar('Erro ao responder. Tente novamente.');
      return false;
    }
  }

  /// Obter notificações de interesse para o usuário atual
  Stream<List<InterestNotificationModel>> getMyInterestNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return InterestNotificationRepository.getUserInterestNotifications(currentUser.uid);
  }

  /// Verificar se existe interesse entre dois usuários
  Future<bool> checkMutualInterest({
    required String userId1,
    required String userId2,
  }) async {
    try {
      return await InterestNotificationRepository.hasUserShownInterest(userId1, userId2);
    } catch (e) {
      EnhancedLogger.error('Erro ao verificar interesse mútuo: $e', tag: 'INTEREST_INTEGRATOR');
      return false;
    }
  }

  /// Obter estatísticas de interesse
  Future<Map<String, int>> getInterestStats(String userId) async {
    try {
      final stats = await InterestNotificationRepository.getUserInterestStats(userId);

      return {
        'sent': stats['sent'] ?? 0,
        'received': stats['received'] ?? 0,
        'accepted': stats['acceptedReceived'] ?? 0,
      };
    } catch (e) {
      EnhancedLogger.error('Erro ao obter estatísticas: $e', tag: 'INTEREST_INTEGRATOR');
      return {'sent': 0, 'received': 0, 'accepted': 0};
    }
  }

  // Métodos auxiliares para feedback visual
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Sucesso! ✅',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.favorite, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erro ❌',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'Informação ℹ️',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }


}