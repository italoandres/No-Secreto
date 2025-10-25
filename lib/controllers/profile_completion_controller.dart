import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spiritual_profile_model.dart';
import '../models/usuario_model.dart';
import '../models/profile_completion_status.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../repositories/usuario_repository.dart';
import '../services/profile_data_synchronizer.dart';
import '../services/profile_completion_detector.dart';
import '../services/username_management_service.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';
import '../utils/vitrine_navigation_helper.dart';
// REMOVIDO: import '../utils/debug_profile_completion.dart'; (arquivo deletado)
import '../views/vitrine_confirmation_view.dart';
import 'vitrine_demo_controller.dart';
import '../views/profile_photos_task_view.dart';
import '../views/profile_identity_task_view.dart';
import '../views/profile_biography_task_view.dart';
import '../views/preferences_interaction_view.dart';
import '../views/spiritual_certification_request_view.dart';

class ProfileCompletionController extends GetxController {
  final Rx<SpiritualProfileModel?> profile = Rx<SpiritualProfileModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ProfileCompletionStatus?> completionStatus =
      Rx<ProfileCompletionStatus?>(null);
  final RxBool hasShownConfirmation = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    await ErrorHandler.safeExecute(
      () async {
        isLoading.value = true;
        errorMessage.value = '';

        EnhancedLogger.info('Loading spiritual profile',
            tag: 'PROFILE_COMPLETION');

        // Get or create profile for current user
        final userProfile =
            await SpiritualProfileRepository.getOrCreateCurrentUserProfile();

        // Sync with user data using the new synchronizer
        await ProfileDataSynchronizer.syncUserData(userProfile.userId!);

        // Reload profile after sync to get updated data
        final syncedProfile =
            await SpiritualProfileRepository.getProfileByUserId(
                userProfile.userId!);

        profile.value = syncedProfile ?? userProfile;

        EnhancedLogger.success('Profile loaded successfully',
            tag: 'PROFILE_COMPLETION',
            data: {
              'profileId': profile.value?.id,
              'progress': (profile.value?.completionPercentage ?? 0) * 100,
            });

        // Log user data for debugging
        final userData =
            await UsuarioRepository.getUserById(userProfile.userId!);
        EnhancedLogger.debug('User data loaded',
            tag: 'PROFILE_COMPLETION',
            data: {
              'userId': userProfile.userId,
              'nome': userData?.nome,
              'username': userData?.username,
              'email': userData?.email,
              'hasPhoto': userData?.imgUrl != null,
            });
      },
      context: 'ProfileCompletionController.loadProfile',
      showUserMessage: true,
    );

    isLoading.value = false;

    // Verificar se o perfil foi completado após o carregamento inicial
    await _checkAndHandleProfileCompletion();
  }

  /// Sincroniza dados do perfil do usuário (Editar Perfil) com a Vitrine de Propósito
  Future<void> _syncWithUserData(SpiritualProfileModel spiritualProfile) async {
    try {
      debugPrint('🔄 Sincronizando dados do usuário...');

      // Get user data from "Editar Perfil"
      final userStream = UsuarioRepository.getUser();
      final userData = await userStream.first;

      if (userData == null) {
        debugPrint('⚠️ Dados do usuário não encontrados');
        return;
      }

      // Check if we need to update spiritual profile with user data
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};

      // Sync main photo if spiritual profile doesn't have one but user does
      if ((spiritualProfile.mainPhotoUrl?.isEmpty ?? true) &&
          (userData.imgUrl?.isNotEmpty ?? false)) {
        updates['mainPhotoUrl'] = userData.imgUrl;
        needsUpdate = true;
        debugPrint('📸 Sincronizando foto principal: ${userData.imgUrl}');
      }

      // Force sync user data for display (não salva no perfil espiritual, apenas para exibição)
      debugPrint('👤 Dados do usuário carregados:');
      debugPrint('   Nome: ${userData.nome}');
      debugPrint('   Username: ${userData.username}');
      debugPrint('   Email: ${userData.email}');
      debugPrint('   Foto: ${userData.imgUrl}');

      // Update spiritual profile if needed
      if (needsUpdate && spiritualProfile.id != null) {
        await SpiritualProfileRepository.updateProfile(
            spiritualProfile.id!, updates);

        // Update local profile object
        spiritualProfile.mainPhotoUrl = updates['mainPhotoUrl'];

        debugPrint('✅ Dados sincronizados com sucesso');
      }
    } catch (e) {
      debugPrint('❌ Erro ao sincronizar dados: $e');
      // Don't throw error, just log it - sync is not critical
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();

    // Verificar se o perfil foi completado após o refresh
    await _checkAndHandleProfileCompletion();
  }

  /// Verifica se o perfil foi completado e trata adequadamente
  Future<void> _checkAndHandleProfileCompletion() async {
    await ErrorHandler.safeExecute(
      () async {
        if (profile.value?.userId == null) return;

        EnhancedLogger.info('Checking profile completion after refresh',
            tag: 'PROFILE_COMPLETION', data: {'userId': profile.value!.userId});

        // Usar o novo detector de completude
        final status = await ProfileCompletionDetector.getCompletionStatus(
            profile.value!.userId!);
        completionStatus.value = status;

        EnhancedLogger.info('Profile completion status updated',
            tag: 'PROFILE_COMPLETION',
            data: {
              'userId': profile.value!.userId,
              'isComplete': status.isComplete,
              'hasBeenShown': status.hasBeenShown,
              'localHasShown': hasShownConfirmation.value,
            });

        // Se o perfil está completo e ainda não foi mostrada a confirmação
        if (status.isComplete &&
            !status.hasBeenShown &&
            !hasShownConfirmation.value) {
          EnhancedLogger.info('Profile completed - showing confirmation',
              tag: 'PROFILE_COMPLETION',
              data: {'userId': profile.value!.userId});

          // Marcar como mostrado localmente para evitar múltiplas exibições
          hasShownConfirmation.value = true;

          // Usar um delay para garantir que a UI está pronta
          Future.delayed(const Duration(milliseconds: 1000), () {
            _navigateToVitrineConfirmation();
          });
        } else {
          // Debug detalhado por que não está mostrando
          EnhancedLogger.warning(
              'Profile completion check - not showing confirmation',
              tag: 'PROFILE_COMPLETION',
              data: {
                'userId': profile.value!.userId,
                'isComplete': status.isComplete,
                'hasBeenShown': status.hasBeenShown,
                'localHasShown': hasShownConfirmation.value,
                'reason': !status.isComplete
                    ? 'not_complete'
                    : status.hasBeenShown
                        ? 'already_shown_remote'
                        : hasShownConfirmation.value
                            ? 'already_shown_local'
                            : 'unknown'
              });
        }

        if (!status.isComplete) {
          // Debug quando perfil não está completo
          EnhancedLogger.warning('Profile not complete - debugging',
              tag: 'PROFILE_COMPLETION',
              data: {
                'userId': profile.value!.userId,
                'percentage': (status.completionPercentage * 100).toInt(),
                'missingTasks': status.missingTasks,
              });

          // REMOVIDO: Debug detalhado (arquivo deletado)
          // DebugProfileCompletion.debugProfileStatus(profile.value!.userId!);
        }
      },
      context: 'ProfileCompletionController._checkAndHandleProfileCompletion',
      showUserMessage: false,
    );
  }

  /// Força a sincronização dos dados do usuário com a Vitrine de Propósito
  Future<void> syncUserData() async {
    if (profile.value != null) {
      await _syncWithUserData(profile.value!);
      // Refresh profile to show updated data
      await refreshProfile();
    }
  }

  void openTask(String taskKey) {
    debugPrint('🎯 Abrindo tarefa: $taskKey');

    switch (taskKey) {
      case 'photos':
        Get.to(() => ProfilePhotosTaskView(
              profile: profile.value!,
              onCompleted: _onTaskCompleted,
            ));
        break;

      case 'identity':
        Get.to(() => ProfileIdentityTaskView(
              profile: profile.value!,
              onCompleted: _onTaskCompleted,
            ));
        break;

      case 'biography':
        Get.to(() => ProfileBiographyTaskView(
              profile: profile.value!,
              onCompleted: _onTaskCompleted,
            ));
        break;

      case 'preferences':
        Get.to(() => PreferencesInteractionView(
              profileId: profile.value!.id!,
              onTaskCompleted: _onTaskCompleted,
            ));
        break;

      case 'certification':
        // Navegar para tela de certificação
        try {
          Get.to(() => const SpiritualCertificationRequestView());
        } catch (e) {
          debugPrint('❌ Erro ao abrir certificação: $e');
          Get.snackbar(
            'Erro',
            'Não foi possível abrir a certificação. Tente novamente.',
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        break;

      default:
        Get.snackbar(
          'Em Desenvolvimento',
          'Esta tarefa ainda está sendo desenvolvida.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }

  void _onTaskCompleted(String taskKey) {
    EnhancedLogger.info('Task completed',
        tag: 'PROFILE_COMPLETION',
        data: {'taskKey': taskKey, 'userId': profile.value?.userId});

    // Show success message
    Get.snackbar(
      'Tarefa Concluída!',
      'Sua tarefa "$taskKey" foi concluída com sucesso.',
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    // Refresh profile and check completion after a delay to allow Firestore to update
    Future.delayed(const Duration(milliseconds: 1500), () async {
      EnhancedLogger.info('Refreshing profile after task completion',
          tag: 'PROFILE_COMPLETION', data: {'taskKey': taskKey});

      await refreshProfile();

      // Notificar o detector para verificar mudanças
      if (profile.value?.userId != null) {
        await ProfileCompletionDetector.checkAndNotify(profile.value!.userId!);
      }
    });
  }

  /// Força navegação direta para vitrine (sem confirmação)
  Future<void> forceNavigateToVitrine() async {
    if (profile.value?.userId == null) return;

    EnhancedLogger.info('Forcing direct navigation to vitrine',
        tag: 'PROFILE_COMPLETION', data: {'userId': profile.value!.userId});

    try {
      await VitrineNavigationHelper.navigateToVitrineDisplay(
          profile.value!.userId!);
    } catch (e) {
      _handleVitrineNavigationError('Erro ao navegar para vitrine: $e');
    }
  }

  /// Força a exibição da confirmação da vitrine (para debug/correção)
  Future<void> forceShowVitrineConfirmation() async {
    if (profile.value?.userId == null) return;

    EnhancedLogger.info('Forcing vitrine confirmation display',
        tag: 'PROFILE_COMPLETION', data: {'userId': profile.value!.userId});

    // Resetar flags
    hasShownConfirmation.value = false;

    // Navegar para confirmação
    await _navigateToVitrineConfirmation();
  }

  /// Navega para a tela de confirmação da vitrine
  Future<void> _navigateToVitrineConfirmation() async {
    await ErrorHandler.safeExecute(
      () async {
        if (profile.value?.userId == null) {
          throw Exception('User ID not found');
        }

        EnhancedLogger.info('Navigating to vitrine confirmation',
            tag: 'PROFILE_COMPLETION', data: {'userId': profile.value!.userId});

        // Marcar como mostrado no Firestore para não mostrar novamente
        await SpiritualProfileRepository.updateProfile(profile.value!.id!, {
          'hasBeenShown': true,
        });

        // Navegar para a tela de confirmação
        await VitrineConfirmationView.show(
          userId: profile.value!.userId!,
          onContinue: () async {
            // Callback quando usuário escolhe ver a vitrine
            await VitrineNavigationHelper.navigateToVitrineDisplay(
                profile.value!.userId!);
          },
          onSkip: () {
            // Callback quando usuário escolhe "Depois"
            Get.back();
          },
        );

        EnhancedLogger.success('Successfully navigated to vitrine confirmation',
            tag: 'PROFILE_COMPLETION', data: {'userId': profile.value!.userId});
      },
      context: 'ProfileCompletionController._navigateToVitrineConfirmation',
      showUserMessage: false,
    );
  }

  /// Trata erros de navegação para a vitrine
  void _handleVitrineNavigationError(String error) {
    EnhancedLogger.error('Vitrine navigation error',
        tag: 'PROFILE_COMPLETION',
        error: Exception(error),
        data: {'userId': profile.value?.userId});

    // Resetar flag para permitir nova tentativa
    hasShownConfirmation.value = false;

    // Usar o helper para tratar o erro
    VitrineNavigationHelper.handleNavigationError(error);
  }

  /// Inicia a demonstração da vitrine após completar o perfil (método legado mantido para compatibilidade)
  Future<void> _startVitrineDemo() async {
    try {
      debugPrint('🚀 DEBUG: Iniciando demonstração da vitrine...');
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔍 DEBUG: User UID = ${user?.uid}');

      if (user?.uid != null) {
        EnhancedLogger.info('Starting vitrine demo after profile completion',
            tag: 'PROFILE_COMPLETION', data: {'userId': user!.uid});

        // Usar o novo helper de navegação
        await VitrineNavigationHelper.navigateToVitrineDisplay(user.uid);

        EnhancedLogger.success('Vitrine demo started successfully',
            tag: 'PROFILE_COMPLETION', data: {'userId': user.uid});
      } else {
        throw Exception('User not found');
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to start vitrine demo',
          tag: 'PROFILE_COMPLETION', error: e, stackTrace: stackTrace);

      _handleVitrineNavigationError(
          'Não foi possível mostrar a vitrine. Você pode acessá-la depois nas configurações.');
    }
  }

  Future<void> updateTaskCompletion(String taskKey, bool isCompleted) async {
    try {
      if (profile.value?.id == null) {
        throw Exception('Perfil não encontrado');
      }

      debugPrint('🔄 Atualizando tarefa $taskKey: $isCompleted');

      await SpiritualProfileRepository.updateTaskCompletion(
        profile.value!.id!,
        taskKey,
        isCompleted,
      );

      // Update local profile
      final updatedTasks =
          Map<String, bool>.from(profile.value!.completionTasks);
      updatedTasks[taskKey] = isCompleted;

      profile.value = profile.value!.copyWith(
        completionTasks: updatedTasks,
        updatedAt: DateTime.now(),
      );

      debugPrint('✅ Tarefa atualizada localmente');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar tarefa: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível atualizar a tarefa. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper methods for task validation
  bool isPhotosTaskComplete() {
    return profile.value?.hasRequiredPhotos ?? false;
  }

  bool isIdentityTaskComplete() {
    return profile.value?.hasBasicInfo ?? false;
  }

  bool isBiographyTaskComplete() {
    return profile.value?.hasBiography ?? false;
  }

  bool isPreferencesTaskComplete() {
    // Check if interaction preferences are set
    return profile.value?.allowInteractions != null;
  }

  bool isCertificationTaskComplete() {
    // This is optional, so it's always "complete" unless user wants to add it
    return true;
  }

  // Get missing fields for better user guidance
  List<String> getMissingRequiredFields() {
    return profile.value?.missingRequiredFields ?? [];
  }

  // Check if profile can be made public
  bool canShowPublicProfile() {
    return profile.value?.canShowPublicProfile ?? false;
  }

  // Get completion percentage
  double getCompletionPercentage() {
    return profile.value?.completionPercentage ?? 0.0;
  }

  // Get completion status text
  String getCompletionStatusText() {
    final percentage = (getCompletionPercentage() * 100).toInt();

    if (percentage == 100) {
      return 'Perfil Completo';
    } else if (percentage >= 75) {
      return 'Quase Pronto';
    } else if (percentage >= 50) {
      return 'Meio Caminho';
    } else if (percentage >= 25) {
      return 'Começando Bem';
    } else {
      return 'Iniciando';
    }
  }

  // Get next recommended task
  String? getNextRecommendedTask() {
    final tasks = profile.value?.completionTasks ?? {};

    // Priority order for tasks
    const taskPriority = [
      'photos', // Most important - required for public profile
      'identity', // Basic info
      'biography', // Core spiritual content
      'preferences', // Interaction settings
      'certification', // Optional enhancement
    ];

    for (final taskKey in taskPriority) {
      if (tasks[taskKey] != true) {
        return taskKey;
      }
    }

    return null; // All tasks completed
  }

  // Username management methods

  /// Atualiza o username do usuário
  Future<bool> updateUsername(String newUsername) async {
    return await ErrorHandler.safeExecute(
          () async {
            if (profile.value?.userId == null) {
              throw Exception('Perfil não encontrado');
            }

            final success = await UsernameManagementService.updateUsername(
                profile.value!.userId!, newUsername);

            if (success) {
              // Refresh profile to show updated data
              await refreshProfile();
            }

            return success;
          },
          context: 'ProfileCompletionController.updateUsername',
          fallbackValue: false,
        ) ??
        false;
  }

  /// Obtém informações sobre alteração de username
  Future<UsernameChangeInfo> getUsernameChangeInfo() async {
    return await ErrorHandler.safeExecute(
          () async {
            if (profile.value?.userId == null) {
              return UsernameChangeInfo(
                canChange: false,
                daysUntilNextChange: 30,
                lastChangeDate: null,
                currentUsername: null,
              );
            }

            return await UsernameManagementService.getChangeInfo(
                profile.value!.userId!);
          },
          context: 'ProfileCompletionController.getUsernameChangeInfo',
          fallbackValue: UsernameChangeInfo(
            canChange: false,
            daysUntilNextChange: 30,
            lastChangeDate: null,
            currentUsername: null,
          ),
        ) ??
        UsernameChangeInfo(
          canChange: false,
          daysUntilNextChange: 30,
          lastChangeDate: null,
          currentUsername: null,
        );
  }

  /// Gera sugestões de username
  Future<List<String>> generateUsernameSuggestions() async {
    return await ErrorHandler.safeExecute(
          () async {
            // Usar nome do usuário como base para sugestões
            final userData =
                await UsuarioRepository.getUserById(profile.value!.userId!);
            final baseName = userData?.nome ?? 'user';

            return await UsernameManagementService.generateSuggestions(
                baseName);
          },
          context: 'ProfileCompletionController.generateUsernameSuggestions',
          fallbackValue: <String>[],
        ) ??
        <String>[];
  }

  /// Obtém dados do usuário atual
  Future<UsuarioModel?> getCurrentUserData() async {
    return await ErrorHandler.safeExecute<UsuarioModel?>(
      () async {
        if (profile.value?.userId == null) return null;

        final userData =
            await UsuarioRepository.getUserById(profile.value!.userId!);
        return userData;
      },
      context: 'ProfileCompletionController.getCurrentUserData',
      fallbackValue: null,
    );
  }

  @override
  void onClose() {
    debugPrint('🔄 ProfileCompletionController fechado');
    super.onClose();
  }
}
