import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/vitrine_demo_controller.dart';
import '../services/profile_completion_detector.dart';
import '../services/vitrine_status_manager.dart';
import '../models/vitrine_confirmation_data.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';

/// Helper para navegação relacionada à vitrine de propósito
class VitrineNavigationHelper {
  static const String _tag = 'VITRINE_NAVIGATION';
  static final VitrineStatusManager _statusManager = VitrineStatusManager();

  /// Verifica se pode mostrar a vitrine
  static Future<bool> canShowVitrine(String userId) async {
    return await ErrorHandler.safeExecute<bool>(
          () async {
            EnhancedLogger.info('Checking if can show vitrine',
                tag: _tag, data: {'userId': userId});

            // Verificar se o perfil está completo
            final isComplete =
                await ProfileCompletionDetector.isProfileComplete(userId);

            if (!isComplete) {
              EnhancedLogger.warning(
                  'Cannot show vitrine - profile not complete',
                  tag: _tag,
                  data: {'userId': userId});
              return false;
            }

            // Verificar se pode ativar a vitrine usando o status manager existente
            final canActivate = await _statusManager.canActivateVitrine(userId);

            if (!canActivate) {
              EnhancedLogger.warning(
                  'Cannot show vitrine - status manager validation failed',
                  tag: _tag,
                  data: {'userId': userId});
              return false;
            }

            EnhancedLogger.success('Can show vitrine',
                tag: _tag, data: {'userId': userId});

            return true;
          },
          context: 'VitrineNavigationHelper.canShowVitrine',
          fallbackValue: false,
        ) ??
        false;
  }

  /// Navega para a tela de confirmação da vitrine
  static Future<void> navigateToVitrineConfirmation(String userId) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.info('Navigating to vitrine confirmation',
            tag: _tag, data: {'userId': userId});

        // Verificar se pode mostrar a vitrine
        final canShow = await canShowVitrine(userId);
        if (!canShow) {
          throw Exception('Cannot show vitrine - profile not ready');
        }

        // Por enquanto, vamos direto para a vitrine até criarmos a tela de confirmação
        await navigateToVitrineDisplay(userId);

        EnhancedLogger.success('Successfully navigated to vitrine confirmation',
            tag: _tag, data: {'userId': userId});
      },
      context: 'VitrineNavigationHelper.navigateToVitrineConfirmation',
      showUserMessage: true,
    );
  }

  /// Navega para a visualização da vitrine
  static Future<void> navigateToVitrineDisplay(String userId,
      {bool fromCelebration = false}) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.info('Navigating to vitrine display',
            tag: _tag,
            data: {'userId': userId, 'fromCelebration': fromCelebration});

        // Verificar se pode mostrar a vitrine
        final canShow = await canShowVitrine(userId);
        if (!canShow) {
          throw Exception('Cannot show vitrine - profile not ready');
        }

        // Navegar diretamente para a tela da vitrine
        Get.toNamed('/vitrine-display', arguments: {
          'userId': userId,
          'isOwnProfile': true,
          'fromCelebration': fromCelebration,
        });

        EnhancedLogger.success('Successfully navigated to vitrine display',
            tag: _tag,
            data: {'userId': userId, 'fromCelebration': fromCelebration});
      },
      context: 'VitrineNavigationHelper.navigateToVitrineDisplay',
      showUserMessage: true,
    );
  }

  /// Trata erros de navegação
  static Future<void> handleNavigationError(String error) async {
    EnhancedLogger.error('Navigation error occurred',
        tag: _tag, error: Exception(error));

    // Mostrar mensagem de erro apropriada
    String userMessage;

    if (error.contains('profile not ready') || error.contains('not complete')) {
      userMessage =
          'Seu perfil ainda não está completo. Complete todas as tarefas primeiro.';
    } else if (error.contains('network') || error.contains('connection')) {
      userMessage =
          'Problema de conexão. Verifique sua internet e tente novamente.';
    } else {
      userMessage =
          'Não foi possível abrir a vitrine. Tente novamente em alguns instantes.';
    }

    Get.snackbar(
      'Ops! Algo deu errado',
      userMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Text('OK'),
      ),
    );
  }

  /// Navega para o perfil de completude
  static Future<void> navigateToProfileCompletion() async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.info('Navigating to profile completion', tag: _tag);

        Get.toNamed('/profile-completion');

        EnhancedLogger.success('Successfully navigated to profile completion',
            tag: _tag);
      },
      context: 'VitrineNavigationHelper.navigateToProfileCompletion',
      showUserMessage: true,
    );
  }

  /// Cria dados de confirmação a partir de informações do usuário
  static Future<VitrineConfirmationData?> createConfirmationData(
      String userId) async {
    return await ErrorHandler.safeExecute<VitrineConfirmationData?>(
      () async {
        // Aqui você pode buscar dados do usuário do repositório
        // Por enquanto, retornamos dados básicos
        return VitrineConfirmationData.fromUserAndProfile(
          userId: userId,
          userName: 'Usuário', // Buscar do repositório
          canShowVitrine: await canShowVitrine(userId),
        );
      },
      context: 'VitrineNavigationHelper.createConfirmationData',
      fallbackValue: null,
    );
  }

  // ===== MÉTODOS EXISTENTES MANTIDOS PARA COMPATIBILIDADE =====

  /// Navega para a demonstração da vitrine do usuário atual
  static Future<void> navigateToMyVitrine() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para acessar sua vitrine',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      EnhancedLogger.info('Navigating to user vitrine',
          tag: _tag, data: {'userId': user.uid});

      // Usar o novo método de verificação
      final canShow = await canShowVitrine(user.uid);
      if (!canShow) {
        final missingFields =
            await _statusManager.getMissingRequiredFields(user.uid);

        Get.snackbar(
          'Perfil Incompleto',
          'Complete seu perfil para ativar sua vitrine: ${missingFields.take(2).join(', ')}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );

        // Navegar para completar perfil
        Get.toNamed('/profile-completion');
        return;
      }

      // Usar o novo método de navegação
      await navigateToVitrineDisplay(user.uid);
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to navigate to vitrine',
          tag: _tag, error: e, stackTrace: stackTrace);

      Get.snackbar(
        'Erro',
        'Não foi possível acessar sua vitrine. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Navega para a vitrine de outro usuário
  static Future<void> navigateToUserVitrine(String userId) async {
    try {
      EnhancedLogger.info('Navigating to user vitrine',
          tag: _tag, data: {'targetUserId': userId});

      // Verificar se a vitrine está ativa
      final status = await _statusManager.getVitrineStatus(userId);
      if (!status.isPubliclyVisible) {
        Get.snackbar(
          'Vitrine Privada',
          'Esta vitrine não está disponível publicamente',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Navegar diretamente para a visualização da vitrine
      Get.toNamed('/vitrine-display', arguments: {'userId': userId});

      EnhancedLogger.success('Successfully navigated to user vitrine',
          tag: _tag, data: {'targetUserId': userId});
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to navigate to user vitrine',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'targetUserId': userId});

      Get.snackbar(
        'Erro',
        'Não foi possível acessar esta vitrine. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Verifica se o usuário atual pode acessar sua vitrine
  static Future<bool> canAccessMyVitrine() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      return await canShowVitrine(user.uid);
    } catch (e) {
      return false;
    }
  }

  /// Obtém o status da vitrine do usuário atual
  static Future<String> getMyVitrineStatusText() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Não logado';

      final status = await _statusManager.getVitrineStatus(user.uid);
      return status.displayName;
    } catch (e) {
      return 'Erro';
    }
  }

  /// Obtém campos faltantes para ativar a vitrine
  static Future<List<String>> getMissingFieldsForVitrine() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return ['Usuário não logado'];

      return await _statusManager.getMissingRequiredFields(user.uid);
    } catch (e) {
      return ['Erro ao verificar campos'];
    }
  }

  /// Navega para a tela de configurações da vitrine
  static Future<void> navigateToVitrineSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para acessar as configurações',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Por enquanto, navegar para a demonstração que inclui controles
      await navigateToMyVitrine();
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to navigate to vitrine settings',
          tag: _tag, error: e, stackTrace: stackTrace);

      Get.snackbar(
        'Erro',
        'Não foi possível acessar as configurações da vitrine',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Cria um botão para acessar a vitrine
  static Widget createVitrineAccessButton({
    String? text,
    VoidCallback? onPressed,
    bool showStatus = false,
  }) {
    return FutureBuilder<bool>(
      future: canAccessMyVitrine(),
      builder: (context, snapshot) {
        final canAccess = snapshot.data ?? false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: onPressed ?? () => navigateToMyVitrine(),
              icon: Icon(canAccess ? Icons.visibility : Icons.visibility_off),
              label: Text(text ?? 'Minha Vitrine de Propósito'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canAccess ? Colors.blue[700] : Colors.grey[600],
                foregroundColor: Colors.white,
              ),
            ),
            if (showStatus) ...[
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: getMyVitrineStatusText(),
                builder: (context, statusSnapshot) {
                  return Text(
                    'Status: ${statusSnapshot.data ?? 'Carregando...'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
