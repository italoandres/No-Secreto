import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/usuario_model.dart';
import '../repositories/interest_notification_repository.dart';
import '../views/profile_display_view.dart';

/// Serviço para navegação de perfis
class ProfileNavigationService {
  
  /// Navegar para o perfil de um usuário por ID
  static Future<void> navigateToProfile(String userId) async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Buscar dados do usuário
      final user = await InterestNotificationRepository.getUserById(userId);
      
      // Fechar loading
      Get.back();
      
      if (user == null) {
        Get.snackbar(
          'Erro',
          'Perfil não encontrado',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Navegar para o perfil usando userId
      Get.to(() => ProfileDisplayView(userId: userId));
      
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Erro ao navegar para perfil: $e');
      Get.snackbar(
        'Erro',
        'Erro ao carregar perfil: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Navegar para o perfil com dados do usuário já carregados
  static void navigateToProfileWithUser(UsuarioModel user) {
    if (user.id != null) {
      Get.to(() => ProfileDisplayView(userId: user.id!));
    }
  }

  /// Verificar se o perfil existe antes de navegar
  static Future<bool> profileExists(String userId) async {
    try {
      final user = await InterestNotificationRepository.getUserById(userId);
      return user != null;
    } catch (e) {
      print('❌ Erro ao verificar se perfil existe: $e');
      return false;
    }
  }

  /// Obter dados básicos do usuário para preview
  static Future<Map<String, dynamic>?> getUserPreview(String userId) async {
    try {
      final user = await InterestNotificationRepository.getUserById(userId);
      if (user == null) return null;
      
      return {
        'id': user.id,
        'nome': user.nome,
        'email': user.email,
        'sexo': user.sexo?.name,
        'username': user.username,
        'imgUrl': user.imgUrl,
      };
    } catch (e) {
      print('❌ Erro ao obter preview do usuário: $e');
      return null;
    }
  }

  /// Navegar para perfil com animação personalizada
  static Future<void> navigateToProfileWithAnimation(String userId) async {
    try {
      // Mostrar loading com animação
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando perfil...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Buscar dados do usuário
      final user = await InterestNotificationRepository.getUserById(userId);
      
      // Fechar loading
      Get.back();
      
      if (user == null) {
        Get.snackbar(
          'Perfil não encontrado',
          'Este usuário pode ter sido removido',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.warning, color: Colors.white),
        );
        return;
      }

      // Navegar com transição personalizada
      Get.to(
        () => ProfileDisplayView(userId: userId),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
      
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Erro ao navegar para perfil: $e');
      Get.snackbar(
        'Erro de Conexão',
        'Não foi possível carregar o perfil. Tente novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  /// Navegar para perfil e marcar notificação como visualizada
  static Future<void> navigateToProfileFromNotification(
    String userId, 
    String? notificationId
  ) async {
    try {
      // Navegar para o perfil
      await navigateToProfileWithAnimation(userId);
      
      // Marcar notificação como visualizada se fornecida
      if (notificationId != null) {
        await InterestNotificationRepository.respondToInterestNotification(
          notificationId,
          'viewed',
        );
      }
      
    } catch (e) {
      print('❌ Erro ao navegar para perfil da notificação: $e');
      // Mesmo com erro na notificação, tenta navegar para o perfil
      await navigateToProfileWithAnimation(userId);
    }
  }

  /// Navegar para perfil SEM marcar como visualizada
  static Future<void> navigateToProfileWithoutMarking(String userId) async {
    await navigateToProfileWithAnimation(userId);
  }
}