import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../services/enhanced_image_manager.dart';
import '../services/profile_data_synchronizer.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';

class ProfilePhotosTaskController extends GetxController {
  final SpiritualProfileModel profile;

  final Rx<Uint8List?> mainPhotoData = Rx<Uint8List?>(null);
  final Rx<Uint8List?> secondaryPhoto1Data = Rx<Uint8List?>(null);
  final Rx<Uint8List?> secondaryPhoto2Data = Rx<Uint8List?>(null);

  final RxBool isSaving = false.obs;
  final ImagePicker _picker = ImagePicker();

  ProfilePhotosTaskController(this.profile);

  @override
  void onInit() {
    super.onInit();
    debugPrint(
        '🔄 ProfilePhotosTaskController iniciado para perfil: ${profile.id}');
  }

  Future<void> selectMainPhoto() async {
    try {
      debugPrint('📸 Selecionando foto principal...');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        mainPhotoData.value = bytes;
        debugPrint('✅ Foto principal selecionada: ${bytes.length} bytes');
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar foto principal: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível selecionar a foto. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> selectSecondaryPhoto1() async {
    try {
      debugPrint('📸 Selecionando foto secundária 1...');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        secondaryPhoto1Data.value = bytes;
        debugPrint('✅ Foto secundária 1 selecionada: ${bytes.length} bytes');
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar foto secundária 1: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível selecionar a foto. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> selectSecondaryPhoto2() async {
    try {
      debugPrint('📸 Selecionando foto secundária 2...');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        secondaryPhoto2Data.value = bytes;
        debugPrint('✅ Foto secundária 2 selecionada: ${bytes.length} bytes');
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar foto secundária 2: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível selecionar a foto. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<String?> _uploadPhoto(Uint8List photoData, String fileName) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('☁️ Fazendo upload da foto: $fileName');

      final ref = FirebaseStorage.instance
          .ref()
          .child('spiritual_profiles')
          .child(currentUser.uid)
          .child(fileName);

      final uploadTask = ref.putData(
        photoData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Upload concluído: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erro no upload da foto $fileName: $e');
      rethrow;
    }
  }

  Future<void> savePhotos() async {
    try {
      isSaving.value = true;
      debugPrint('💾 Salvando fotos do perfil...');

      final Map<String, dynamic> updates = {};

      // Upload main photo if changed
      if (mainPhotoData.value != null) {
        final mainPhotoUrl = await _uploadPhoto(
          mainPhotoData.value!,
          'main_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        updates['mainPhotoUrl'] = mainPhotoUrl;
        debugPrint('✅ Foto principal salva: $mainPhotoUrl');
      }

      // Upload secondary photo 1 if changed
      if (secondaryPhoto1Data.value != null) {
        final secondaryPhoto1Url = await _uploadPhoto(
          secondaryPhoto1Data.value!,
          'secondary1_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        updates['secondaryPhoto1Url'] = secondaryPhoto1Url;
        debugPrint('✅ Foto secundária 1 salva: $secondaryPhoto1Url');
      }

      // Upload secondary photo 2 if changed
      if (secondaryPhoto2Data.value != null) {
        final secondaryPhoto2Url = await _uploadPhoto(
          secondaryPhoto2Data.value!,
          'secondary2_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        updates['secondaryPhoto2Url'] = secondaryPhoto2Url;
        debugPrint('✅ Foto secundária 2 salva: $secondaryPhoto2Url');
      }

      // Update profile in Firestore if there are changes
      if (updates.isNotEmpty) {
        await SpiritualProfileRepository.updateProfile(profile.id!, updates);
        debugPrint('✅ Perfil atualizado no Firestore');
      }

      // Mark photos task as completed
      await SpiritualProfileRepository.updateTaskCompletion(
        profile.id!,
        'photos',
        true,
      );

      debugPrint('🎉 Fotos salvas com sucesso!');

      Get.snackbar(
        'Sucesso!',
        'Suas fotos foram salvas com sucesso.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar fotos: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível salvar as fotos. Verifique sua conexão e tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  bool get hasMainPhoto =>
      mainPhotoData.value != null || (profile.mainPhotoUrl?.isNotEmpty == true);

  bool get hasSecondaryPhoto1 =>
      secondaryPhoto1Data.value != null ||
      (profile.secondaryPhoto1Url?.isNotEmpty == true);

  bool get hasSecondaryPhoto2 =>
      secondaryPhoto2Data.value != null ||
      (profile.secondaryPhoto2Url?.isNotEmpty == true);

  bool get hasAnyChanges =>
      mainPhotoData.value != null ||
      secondaryPhoto1Data.value != null ||
      secondaryPhoto2Data.value != null;

  int get photoCount {
    int count = 0;
    if (hasMainPhoto) count++;
    if (hasSecondaryPhoto1) count++;
    if (hasSecondaryPhoto2) count++;
    return count;
  }

  void clearMainPhoto() {
    mainPhotoData.value = null;
  }

  void clearSecondaryPhoto1() {
    secondaryPhoto1Data.value = null;
  }

  void clearSecondaryPhoto2() {
    secondaryPhoto2Data.value = null;
  }

  // Novos métodos para trabalhar com EnhancedImageManager

  /// Atualiza a foto principal
  Future<void> updateMainPhoto(String imageUrl) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.info('Updating main photo', tag: 'PHOTOS_TASK', data: {
          'profileId': profile.id,
          'userId': profile.userId,
          'imageUrl': imageUrl,
        });

        // 1. Atualizar no perfil espiritual
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'mainPhotoUrl': imageUrl,
          'lastSyncAt': FieldValue.serverTimestamp(),
        });

        // 2. Atualizar diretamente na collection usuarios (CRÍTICO para chats/stories)
        if (profile.userId != null) {
          try {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(profile.userId!)
                .update({
              'imgUrl': imageUrl,
              'lastSyncAt': FieldValue.serverTimestamp(),
            });

            EnhancedLogger.success(
                'Profile image synced to usuarios collection',
                tag: 'PHOTOS_TASK',
                data: {'userId': profile.userId});
          } catch (e) {
            EnhancedLogger.error('Failed to sync image to usuarios collection',
                tag: 'PHOTOS_TASK', error: e, data: {'userId': profile.userId});
            // Tentar método alternativo
            await ProfileDataSynchronizer.updateProfileImage(
                profile.userId!, imageUrl);
          }
        }

        // 3. Atualizar modelo local
        profile.mainPhotoUrl = imageUrl;

        // 4. Marcar tarefa como completa
        await _checkAndUpdateTaskCompletion();

        EnhancedLogger.success('Main photo updated successfully',
            tag: 'PHOTOS_TASK');

        // 5. Mostrar feedback ao usuário
        Get.snackbar(
          'Foto Atualizada!',
          'Sua foto de perfil foi atualizada e já está visível para outros usuários.',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
      context: 'ProfilePhotosTaskController.updateMainPhoto',
      showUserMessage: true,
    );
  }

  /// Remove a foto principal
  Future<void> removeMainPhoto() async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.info('Removing main photo', tag: 'PHOTOS_TASK', data: {
          'profileId': profile.id,
        });

        // Atualizar no perfil espiritual
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'mainPhotoUrl': null,
        });

        // Sincronizar com collection usuarios
        if (profile.userId != null) {
          await ProfileDataSynchronizer.updateProfileImage(
              profile.userId!, null);
        }

        // Atualizar modelo local
        profile.mainPhotoUrl = null;

        // Atualizar status da tarefa
        await _checkAndUpdateTaskCompletion();

        EnhancedLogger.success('Main photo removed successfully',
            tag: 'PHOTOS_TASK');
      },
      context: 'ProfilePhotosTaskController.removeMainPhoto',
    );
  }

  /// Atualiza foto secundária 1
  Future<void> updateSecondaryPhoto1(String imageUrl) async {
    await ErrorHandler.safeExecute(
      () async {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'secondaryPhoto1Url': imageUrl,
        });

        profile.secondaryPhoto1Url = imageUrl;
        await _checkAndUpdateTaskCompletion();

        EnhancedLogger.success('Secondary photo 1 updated', tag: 'PHOTOS_TASK');
      },
      context: 'ProfilePhotosTaskController.updateSecondaryPhoto1',
    );
  }

  /// Remove foto secundária 1
  Future<void> removeSecondaryPhoto1() async {
    await ErrorHandler.safeExecute(
      () async {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'secondaryPhoto1Url': null,
        });

        profile.secondaryPhoto1Url = null;

        EnhancedLogger.success('Secondary photo 1 removed', tag: 'PHOTOS_TASK');
      },
      context: 'ProfilePhotosTaskController.removeSecondaryPhoto1',
    );
  }

  /// Atualiza foto secundária 2
  Future<void> updateSecondaryPhoto2(String imageUrl) async {
    await ErrorHandler.safeExecute(
      () async {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'secondaryPhoto2Url': imageUrl,
        });

        profile.secondaryPhoto2Url = imageUrl;
        await _checkAndUpdateTaskCompletion();

        EnhancedLogger.success('Secondary photo 2 updated', tag: 'PHOTOS_TASK');
      },
      context: 'ProfilePhotosTaskController.updateSecondaryPhoto2',
    );
  }

  /// Remove foto secundária 2
  Future<void> removeSecondaryPhoto2() async {
    await ErrorHandler.safeExecute(
      () async {
        await SpiritualProfileRepository.updateProfile(profile.id!, {
          'secondaryPhoto2Url': null,
        });

        profile.secondaryPhoto2Url = null;

        EnhancedLogger.success('Secondary photo 2 removed', tag: 'PHOTOS_TASK');
      },
      context: 'ProfilePhotosTaskController.removeSecondaryPhoto2',
    );
  }

  /// Verifica e atualiza o status de conclusão da tarefa
  Future<void> _checkAndUpdateTaskCompletion() async {
    try {
      final isComplete = profile.mainPhotoUrl?.isNotEmpty == true;

      await SpiritualProfileRepository.updateTaskCompletion(
        profile.id!,
        'photos',
        isComplete,
      );

      EnhancedLogger.debug('Photos task completion updated',
          tag: 'PHOTOS_TASK',
          data: {
            'isComplete': isComplete,
            'hasMainPhoto': profile.mainPhotoUrl?.isNotEmpty == true,
          });
    } catch (e) {
      EnhancedLogger.error('Failed to update task completion',
          tag: 'PHOTOS_TASK', error: e);
    }
  }

  @override
  void onClose() {
    try {
      debugPrint('🔄 ProfilePhotosTaskController fechado');
      // Limpar dados das imagens para evitar vazamentos de memória
      mainPhotoData.value = null;
      secondaryPhoto1Data.value = null;
      secondaryPhoto2Data.value = null;
    } catch (e) {
      debugPrint('⚠️ Erro ao fechar ProfilePhotosTaskController: $e');
    } finally {
      super.onClose();
    }
  }
}
