import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/vitrine_confirmation_data.dart';
import '../repositories/usuario_repository.dart';
import '../services/profile_completion_detector.dart';
import '../utils/vitrine_navigation_helper.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';

/// Controller para a tela de confirmação da vitrine
class VitrineConfirmationController extends GetxController {
  static const String _tag = 'VITRINE_CONFIRMATION_CONTROLLER';

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<VitrineConfirmationData?> confirmationData =
      Rx<VitrineConfirmationData?>(null);
  final RxBool canShowVitrine = false.obs;

  String? _userId;

  /// Inicializa o controller com dados do usuário
  Future<void> initialize(String userId) async {
    if (_userId == userId) return; // Evitar reinicialização

    _userId = userId;

    // Resetar estado
    isLoading.value = true;
    errorMessage.value = '';
    confirmationData.value = null;
    canShowVitrine.value = false;

    // Carregar dados de forma assíncrona
    _loadConfirmationData();
  }

  /// Carrega os dados necessários para a confirmação
  Future<void> _loadConfirmationData() async {
    if (_userId == null) return;

    await ErrorHandler.safeExecute(
      () async {
        isLoading.value = true;
        errorMessage.value = '';

        EnhancedLogger.info('Loading confirmation data',
            tag: _tag, data: {'userId': _userId});

        // Verificar se pode mostrar a vitrine
        final canShow = await VitrineNavigationHelper.canShowVitrine(_userId!);
        canShowVitrine.value = canShow;

        if (!canShow) {
          throw Exception('Profile not ready for vitrine display');
        }

        // Buscar dados do usuário
        final userData = await UsuarioRepository.getUserById(_userId!);

        if (userData == null) {
          throw Exception('User data not found');
        }

        // Criar dados de confirmação
        final data = VitrineConfirmationData.fromUserAndProfile(
          userId: _userId!,
          userName: userData.nome ?? 'Usuário',
          userPhoto: userData.imgUrl,
          canShowVitrine: canShow,
        );

        confirmationData.value = data;

        EnhancedLogger.success('Confirmation data loaded successfully',
            tag: _tag,
            data: {
              'userId': _userId,
              'userName': data.userName,
              'canShowVitrine': canShow,
            });
      },
      context: 'VitrineConfirmationController._loadConfirmationData',
      showUserMessage: false,
    );

    isLoading.value = false;
  }

  /// Navega para a visualização da vitrine
  Future<void> navigateToVitrine() async {
    if (_userId == null) {
      _handleError('ID do usuário não encontrado');
      return;
    }

    await ErrorHandler.safeExecute(
      () async {
        isLoading.value = true;

        EnhancedLogger.info('Navigating to vitrine from confirmation',
            tag: _tag, data: {'userId': _userId});

        // Verificar novamente se pode mostrar a vitrine
        final canShow = await VitrineNavigationHelper.canShowVitrine(_userId!);

        if (!canShow) {
          throw Exception('Cannot show vitrine - profile validation failed');
        }

        // Navegar para a vitrine com flag de celebration
        await VitrineNavigationHelper.navigateToVitrineDisplay(_userId!,
            fromCelebration: true);

        // Registrar analytics
        _trackUserAction('view_vitrine');

        EnhancedLogger.success('Successfully navigated to vitrine',
            tag: _tag, data: {'userId': _userId});
      },
      context: 'VitrineConfirmationController.navigateToVitrine',
      showUserMessage: true,
    );

    isLoading.value = false;
  }

  /// Manipula a opção "Depois"
  void handleSkip() {
    EnhancedLogger.info('User chose to skip vitrine viewing',
        tag: _tag, data: {'userId': _userId});

    // Registrar analytics
    _trackUserAction('skip_vitrine');

    // Voltar para tela anterior
    Get.back();
  }

  /// Navega para o início
  void navigateToHome() {
    EnhancedLogger.info('User chose to go to home',
        tag: _tag, data: {'userId': _userId});

    // Registrar analytics
    _trackUserAction('go_to_home');

    // Ir para home - fechar todas as telas até a home
    try {
      // Tentar usar a rota nomeada primeiro
      if (Get.currentRoute != '/home') {
        Get.until((route) => route.settings.name == '/home' || route.isFirst);
      }
    } catch (e) {
      // Se falhar, apenas voltar para a tela anterior
      EnhancedLogger.warning(
        'Failed to navigate to home, going back instead',
        tag: _tag,
        data: {'error': e.toString()},
      );
      Get.back();
    }
  }

  /// Recarrega os dados
  @override
  Future<void> refresh() async {
    await _loadConfirmationData();
  }

  /// Verifica se os dados estão prontos
  bool get isDataReady => confirmationData.value != null && !isLoading.value;

  /// Obtém o nome do usuário
  String get userName => confirmationData.value?.userName ?? 'Usuário';

  /// Obtém a foto do usuário
  String? get userPhoto => confirmationData.value?.userPhoto;

  /// Manipula erros
  void _handleError(String error) {
    errorMessage.value = error;

    EnhancedLogger.error('Confirmation controller error',
        tag: _tag, error: Exception(error), data: {'userId': _userId});

    // Mostrar erro para o usuário
    Get.snackbar(
      'Ops! Algo deu errado',
      error,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: refresh,
        child: const Text('Tentar novamente'),
      ),
    );
  }

  /// Registra ações do usuário para analytics
  void _trackUserAction(String action) {
    try {
      // Aqui você pode integrar com seu sistema de analytics
      EnhancedLogger.info('User action tracked', tag: _tag, data: {
        'userId': _userId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silenciar erros de analytics para não afetar a experiência
      EnhancedLogger.warning('Failed to track user action: $e',
          tag: _tag, data: {'error': e.toString()});
    }
  }

  /// Valida se o perfil ainda está completo
  Future<bool> validateProfileCompletion() async {
    if (_userId == null) return false;

    return await ErrorHandler.safeExecute<bool>(
          () async {
            final isComplete =
                await ProfileCompletionDetector.isProfileComplete(_userId!);

            if (!isComplete) {
              EnhancedLogger.warning('Profile is no longer complete',
                  tag: _tag, data: {'userId': _userId});

              // Mostrar mensagem e redirecionar para completar perfil
              Get.snackbar(
                'Perfil Incompleto',
                'Seu perfil não está mais completo. Complete as tarefas pendentes.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange[100],
                colorText: Colors.orange[800],
                duration: const Duration(seconds: 4),
                mainButton: TextButton(
                  onPressed: () =>
                      VitrineNavigationHelper.navigateToProfileCompletion(),
                  child: const Text('Completar'),
                ),
              );
            }

            return isComplete;
          },
          context: 'VitrineConfirmationController.validateProfileCompletion',
          fallbackValue: false,
        ) ??
        false;
  }

  /// Mostra informações sobre a vitrine
  void showVitrineInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Sobre sua Vitrine de Propósito',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua vitrine é um espaço sagrado onde você pode:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text('• Compartilhar seu propósito de vida'),
            Text('• Conectar-se com pessoas de valores similares'),
            Text('• Mostrar sua jornada espiritual'),
            Text('• Receber mensagens de outros usuários'),
            SizedBox(height: 12),
            Text(
              'Lembre-se: este é um terreno sagrado para conexões espirituais autênticas.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    EnhancedLogger.info('VitrineConfirmationController disposed',
        tag: _tag, data: {'userId': _userId});
    super.onClose();
  }
}
