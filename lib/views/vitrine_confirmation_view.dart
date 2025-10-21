import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../controllers/vitrine_demo_controller.dart';
import '../controllers/vitrine_confirmation_controller.dart';
import '../models/vitrine_confirmation_data.dart';
import '../utils/vitrine_navigation_helper.dart';
import '../utils/enhanced_logger.dart';
import '../theme.dart';

/// Tela de confirmação celebrativa após completar a vitrine de propósito
class VitrineConfirmationView extends StatelessWidget {
  final String? userId;
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;
  
  const VitrineConfirmationView({
    Key? key,
    this.userId,
    this.onContinue,
    this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final demoController = Get.put(VitrineDemoController());
    final confirmationController = Get.put(VitrineConfirmationController());
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final finalUserId = userId ?? arguments['userId'] as String? ?? '';
    
    // Log da inicialização da tela
    EnhancedLogger.info('VitrineConfirmationView initialized', 
      tag: 'VITRINE_CONFIRMATION',
      data: {'userId': finalUserId}
    );
    
    // Inicializar controllers
    if (finalUserId.isNotEmpty) {
      if (demoController.currentUserId.value != finalUserId) {
        demoController.currentUserId.value = finalUserId;
      }
      // Usar SchedulerBinding para inicializar após o build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        confirmationController.initialize(finalUserId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
          tooltip: 'Voltar',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCelebrationHeader(),
            Expanded(child: _buildMainContent(demoController, confirmationController, finalUserId)),
            _buildActionButtons(demoController, confirmationController, finalUserId),
            _buildAdditionalOptions(confirmationController),
          ],
        ),
      ),
    );
  }

  /// Header celebrativo com animação
  Widget _buildCelebrationHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Ícone animado de sucesso
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.celebration,
                    size: 50,
                    color: AppColors.success,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Título principal
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Text(
                    'Parabéns!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Conteúdo principal da tela
  Widget _buildMainContent(VitrineDemoController demoController, VitrineConfirmationController confirmationController, String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mensagem principal
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Agora você tem um perfil vitrine do meu propósito',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sua vitrine está pronta para receber visitas e conectar você com pessoas que compartilham seus valores espirituais.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _buildVitrinePreview(demoController, confirmationController),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Status indicator
          _buildStatusIndicator(demoController),
          const SizedBox(height: 16),
          // Error handling
          Obx(() {
            if (confirmationController.errorMessage.value.isNotEmpty) {
              return _buildErrorMessage(confirmationController);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Preview da vitrine
  Widget _buildVitrinePreview(VitrineDemoController demoController, VitrineConfirmationController confirmationController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar com foto do usuário ou placeholder
          Obx(() {
            final userPhoto = confirmationController.userPhoto;
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: userPhoto?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      userPhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 30,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 30,
                  ),
            );
          }),
          const SizedBox(width: 12),
          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return Text(
                    '${confirmationController.userName} - Vitrine',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Obx(() {
                  return Text(
                    confirmationController.canShowVitrine.value
                      ? 'Pronta para ser descoberta'
                      : 'Aguardando validação',
                    style: TextStyle(
                      fontSize: 14,
                      color: confirmationController.canShowVitrine.value
                        ? AppColors.textSecondary
                        : Colors.orange,
                    ),
                  );
                }),
              ],
            ),
          ),
          // Ícone de visualização
          Icon(
            Icons.visibility,
            color: AppColors.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// Indicador de status da vitrine
  Widget _buildStatusIndicator(VitrineDemoController controller) {
    return Obx(() {
      final isActive = controller.isVitrineActive.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? AppColors.success.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.success : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.public : Icons.public_off,
              size: 16,
              color: isActive ? AppColors.success : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'Vitrine Pública' : 'Vitrine Privada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.success : Colors.grey,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Botões de ação principais
  Widget _buildActionButtons(VitrineDemoController demoController, VitrineConfirmationController confirmationController, String userId) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Botão principal - Ver vitrine
          Obx(() {
            final isLoading = confirmationController.isLoading.value;
            final canShow = confirmationController.canShowVitrine.value;
            
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (isLoading || !canShow) 
                  ? null 
                  : () => confirmationController.navigateToVitrine(),
                icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.visibility),
                label: Text(
                  isLoading 
                    ? 'Carregando...' 
                    : 'Ver meu perfil vitrine de propósito',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canShow ? AppColors.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Botão secundário - Informações sobre a vitrine
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => confirmationController.showVitrineInfo(),
              icon: const Icon(
                Icons.info_outline,
                size: 20,
              ),
              label: const Text(
                'Sobre sua vitrine de propósito',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opções adicionais
  Widget _buildAdditionalOptions(VitrineConfirmationController confirmationController) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () => confirmationController.handleSkip(),
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Depois'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 32),
          TextButton.icon(
            onPressed: () => confirmationController.navigateToHome(),
            icon: const Icon(Icons.home, size: 18),
            label: const Text('Início'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }



  /// Widget para mostrar mensagens de erro
  Widget _buildErrorMessage(VitrineConfirmationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ops! Algo deu errado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => controller.refresh(),
            child: Text(
              'Tentar novamente',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Manipula o clique no botão "Ver meu perfil vitrine de propósito"
  Future<void> _handleViewVitrine(VitrineDemoController controller, String userId) async {
    try {
      EnhancedLogger.info('User clicked to view vitrine', 
        tag: 'VITRINE_CONFIRMATION',
        data: {'userId': userId}
      );

      // Executar callback personalizado se fornecido
      if (onContinue != null) {
        onContinue!();
        return;
      }

      // Usar o helper de navegação para ir para a vitrine
      await VitrineNavigationHelper.navigateToVitrineDisplay(userId);

      EnhancedLogger.success('Successfully navigated to vitrine from confirmation', 
        tag: 'VITRINE_CONFIRMATION',
        data: {'userId': userId}
      );

    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to navigate to vitrine from confirmation', 
        tag: 'VITRINE_CONFIRMATION',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId}
      );

      // Mostrar erro amigável
      Get.snackbar(
        'Ops! Algo deu errado',
        'Não foi possível carregar sua vitrine. Tente novamente em alguns instantes.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () => _handleViewVitrine(controller, userId),
          child: const Text('Tentar novamente'),
        ),
      );
    }
  }

  /// Manipula a opção "Depois" ou voltar
  void _handleSkip() {
    EnhancedLogger.info('User chose to skip vitrine viewing', 
      tag: 'VITRINE_CONFIRMATION'
    );

    // Executar callback personalizado se fornecido
    if (onSkip != null) {
      onSkip!();
      return;
    }

    // Comportamento padrão - voltar para tela anterior
    Get.back();
  }

  /// Cria uma instância da tela com dados específicos
  static Widget withData(VitrineConfirmationData data) {
    return VitrineConfirmationView(
      userId: data.userId,
      onContinue: () async {
        await VitrineNavigationHelper.navigateToVitrineDisplay(data.userId);
      },
      onSkip: () {
        Get.back();
      },
    );
  }

  /// Navega para esta tela com dados específicos
  static Future<void> show({
    required String userId,
    VoidCallback? onContinue,
    VoidCallback? onSkip,
  }) async {
    EnhancedLogger.info('Showing vitrine confirmation', 
      tag: 'VITRINE_CONFIRMATION',
      data: {'userId': userId}
    );

    Get.to(
      () => VitrineConfirmationView(
        userId: userId,
        onContinue: onContinue,
        onSkip: onSkip,
      ),
      arguments: {'userId': userId},
    );
  }
}