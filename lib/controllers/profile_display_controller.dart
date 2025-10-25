import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spiritual_profile_model.dart';
import '../models/usuario_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../repositories/usuario_repository.dart';
import '../repositories/temporary_chat_repository.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';
// import 'package:whatsapp_chat/views/temporary_chat_view.dart'; // Temporariamente comentado

class ProfileDisplayController extends GetxController {
  final String userId;

  final Rx<SpiritualProfileModel?> spiritualProfile =
      Rx<SpiritualProfileModel?>(null);
  final Rx<UsuarioModel?> user = Rx<UsuarioModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // Interaction states
  final RxBool hasExpressedInterest = false.obs;
  final RxBool hasMutualInterest = false.obs;
  final RxBool isProcessingInterest = false.obs;
  final Rx<MutualInterestModel?> mutualInterestData =
      Rx<MutualInterestModel?>(null);

  ProfileDisplayController(this.userId);

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

        EnhancedLogger.info('Loading public profile',
            tag: 'PROFILE_DISPLAY', data: {'userId': userId});

        // Check if trying to view own profile
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser?.uid == userId) {
          errorMessage.value =
              'Você não pode visualizar seu próprio perfil aqui.\nUse "Vitrine de Propósito" para editar.';
          return;
        }

        // Load user basic info
        final userDoc = await UsuarioRepository.getUserById(userId);
        if (userDoc == null) {
          errorMessage.value = 'Usuário não encontrado.';
          return;
        }

        EnhancedLogger.debug('User data loaded', tag: 'PROFILE_DISPLAY', data: {
          'userId': userId,
          'nome': userDoc.nome,
          'username': userDoc.username,
          'email': userDoc.email,
          'hasPhoto': userDoc.imgUrl != null,
        });

        user.value = userDoc;

        // Load spiritual profile
        final profile =
            await SpiritualProfileRepository.getProfileByUserId(userId);
        if (profile == null) {
          errorMessage.value =
              'Este usuário ainda não criou sua vitrine de propósito.';
          return;
        }

        EnhancedLogger.info('Spiritual profile loaded',
            tag: 'PROFILE_DISPLAY',
            data: {
              'profileId': profile.id,
              'isComplete': profile.isProfileComplete,
              'canShowPublic': profile.canShowPublicProfile,
            });

        // Check if profile is complete and public
        if (!profile.canShowPublicProfile) {
          errorMessage.value =
              'Este usuário ainda está completando sua vitrine de propósito.';
          return;
        }

        // Check if user is blocked
        final isBlocked =
            await SpiritualProfileRepository.isUserBlocked(userId);
        if (isBlocked) {
          errorMessage.value = 'Você não pode visualizar este perfil.';
          return;
        }

        spiritualProfile.value = profile;

        // Load interaction states if current user is authenticated
        if (currentUser != null) {
          await _loadInteractionStates();
        }

        EnhancedLogger.success('Profile loaded successfully',
            tag: 'PROFILE_DISPLAY',
            data: {
              'profileId': profile.id,
              'hasInteractions': profile.allowInteractions,
            });
      },
      context: 'ProfileDisplayController.loadProfile',
      showUserMessage: false, // Vamos mostrar nossa própria mensagem de erro
      maxRetries: 2,
    );

    isLoading.value = false;
  }

  Future<void> _loadInteractionStates() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      debugPrint('🔄 Carregando estados de interação...');

      // Check if current user has expressed interest
      final expressedInterest =
          await SpiritualProfileRepository.hasExpressedInterest(userId);
      hasExpressedInterest.value = expressedInterest;

      // Check for mutual interest
      final mutualInterest = await SpiritualProfileRepository.getMutualInterest(
          currentUser.uid, userId);
      if (mutualInterest != null) {
        hasMutualInterest.value = true;
        mutualInterestData.value = mutualInterest;
        debugPrint('💕 Interesse mútuo detectado: ${mutualInterest.id}');
      }

      debugPrint('✅ Estados de interação carregados');
      debugPrint('   - Interesse expressado: $expressedInterest');
      debugPrint('   - Interesse mútuo: ${hasMutualInterest.value}');
    } catch (e) {
      debugPrint('❌ Erro ao carregar estados de interação: $e');
    }
  }

  Future<void> expressInterest() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Erro',
          'Você precisa estar logado para demonstrar interesse.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Check if current user has a complete profile
      final currentUserProfile =
          await SpiritualProfileRepository.getCurrentUserProfile();
      if (currentUserProfile == null ||
          !currentUserProfile.canShowPublicProfile) {
        Get.snackbar(
          'Complete seu Perfil',
          'Complete sua vitrine de propósito antes de demonstrar interesse.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Check if both users are single
      if (currentUserProfile.relationshipStatus !=
              RelationshipStatus.solteiro ||
          spiritualProfile.value?.relationshipStatus !=
              RelationshipStatus.solteiro) {
        Get.snackbar(
          'Não Disponível',
          'Demonstrações de interesse são apenas para usuários solteiros.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isProcessingInterest.value = true;
      debugPrint('💝 Expressando interesse em: $userId');

      final success = await SpiritualProfileRepository.expressInterest(userId);

      if (success) {
        hasExpressedInterest.value = true;

        // Check if this created a mutual interest
        await _loadInteractionStates();

        if (hasMutualInterest.value) {
          Get.snackbar(
            '💕 Interesse Mútuo!',
            'Vocês demonstraram interesse um no outro! Agora podem se conhecer melhor.',
            backgroundColor: Colors.green[100],
            colorText: Colors.green[800],
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar(
            'Interesse Demonstrado!',
            'Seu interesse foi registrado. Se a pessoa também demonstrar interesse, vocês poderão conversar.',
            backgroundColor: Colors.blue[100],
            colorText: Colors.blue[800],
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao expressar interesse: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível demonstrar interesse. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessingInterest.value = false;
    }
  }

  Future<void> startTemporaryChat() async {
    try {
      debugPrint('💬 Iniciando chat temporário...');

      final mutualInterest = mutualInterestData.value;
      if (mutualInterest == null) {
        Get.snackbar(
          'Erro',
          'Interesse mútuo não encontrado.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Check if temporary chat already exists
      var existingChat =
          await TemporaryChatRepository.getChatByMutualInterestId(
              mutualInterest.id!);

      if (existingChat == null) {
        // Create new temporary chat
        existingChat =
            await TemporaryChatRepository.createTemporaryChat(mutualInterest);

        Get.snackbar(
          '💬 Chat Criado!',
          'Seu chat temporário de 7 dias foi criado. Conversem com respeito e propósito!',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }

      // Navigate to temporary chat
      // TODO: Temporariamente comentado devido a erro de build
      // Get.to(() => TemporaryChatView(chatRoomId: existingChat!.chatRoomId));

      // Mensagem temporária até resolver o problema de build
      Get.snackbar(
        'Chat Temporário',
        'Funcionalidade temporariamente indisponível. Será reativada em breve.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('❌ Erro ao iniciar chat temporário: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível iniciar o chat. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> blockUser() async {
    try {
      debugPrint('🚫 Bloqueando usuário: $userId');

      await SpiritualProfileRepository.blockUser(userId);

      Get.snackbar(
        'Usuário Bloqueado',
        'Este usuário foi bloqueado e não poderá mais interagir com você.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
      );

      // Return to previous screen
      Get.back();
    } catch (e) {
      debugPrint('❌ Erro ao bloquear usuário: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível bloquear o usuário. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> reportUser() async {
    try {
      debugPrint('🚨 Reportando usuário: $userId');

      // For now, show a placeholder message
      // In the future, this will integrate with a reporting system
      Get.snackbar(
        'Usuário Reportado',
        'Obrigado pelo reporte. Nossa equipe irá analisar.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.BOTTOM,
      );

      // TODO: Implement user reporting system
      // This should:
      // 1. Create a report record
      // 2. Notify administrators
      // 3. Track report history
    } catch (e) {
      debugPrint('❌ Erro ao reportar usuário: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível enviar o reporte. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper methods
  bool get canInteract {
    final profile = spiritualProfile.value;
    if (profile == null) return false;

    return profile.allowInteractions &&
        profile.relationshipStatus == RelationshipStatus.solteiro;
  }

  bool get isProfileComplete {
    return spiritualProfile.value?.canShowPublicProfile ?? false;
  }

  String get profileCompletionStatus {
    final profile = spiritualProfile.value;
    if (profile == null) return 'Perfil não encontrado';

    if (profile.canShowPublicProfile) {
      return 'Perfil completo';
    } else {
      final missing = profile.missingRequiredFields;
      return 'Faltam: ${missing.join(', ')}';
    }
  }

  @override
  void onClose() {
    debugPrint('🔄 ProfileDisplayController fechado');
    super.onClose();
  }
}
