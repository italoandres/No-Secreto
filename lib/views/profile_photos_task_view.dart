import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/spiritual_profile_model.dart';
import '../controllers/profile_photos_task_controller.dart';
import '../components/enhanced_image_picker.dart';
import '../components/robust_image_widget.dart';

class ProfilePhotosTaskView extends StatelessWidget {
  final SpiritualProfileModel profile;
  final Function(String) onCompleted;

  const ProfilePhotosTaskView({
    super.key,
    required this.profile,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // Usar tag única para evitar conflitos e dispose automático
    final controllerTag =
        'photos_task_${profile.id}_${DateTime.now().millisecondsSinceEpoch}';
    final controller = Get.put(
      ProfilePhotosTaskController(profile),
      tag: controllerTag,
    );

    // Controller será automaticamente removido pelo GetX quando a tela for fechada

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '📸 Fotos do Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuidanceCard(),
            const SizedBox(height: 24),
            _buildMainPhotoSection(controller),
            const SizedBox(height: 24),
            _buildSecondaryPhotosSection(controller),
            const SizedBox(height: 32),
            _buildSaveButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[100]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.purple[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Orientação para Fotos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Mantenha um "olhar com propósito", não sensualidade\n'
            '• Foto principal: seu rosto de forma natural\n'
            '• Fotos secundárias: atividades que representem seu propósito\n'
            '• Evite fotos provocativas ou inadequadas para um ambiente espiritual',
            style: TextStyle(
              fontSize: 14,
              color: Colors.purple[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPhotoSection(ProfilePhotosTaskController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Foto Principal (Obrigatória)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: EnhancedImagePicker(
              userId: controller.profile.userId!,
              currentImageUrl: controller.profile.mainPhotoUrl,
              fallbackText: 'Foto Principal',
              onImageUploaded: (imageUrl) =>
                  controller.updateMainPhoto(imageUrl),
              onImageRemoved: () => controller.removeMainPhoto(),
              size: 150,
              imageType: 'main_photo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryPhotosSection(ProfilePhotosTaskController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fotos Secundárias (Opcionais)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Usar SingleChildScrollView para evitar overflow em telas pequenas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                EnhancedImagePicker(
                  userId: controller.profile.userId!,
                  currentImageUrl: controller.profile.secondaryPhoto1Url,
                  fallbackText: 'Foto 2',
                  onImageUploaded: (imageUrl) =>
                      controller.updateSecondaryPhoto1(imageUrl),
                  onImageRemoved: () => controller.removeSecondaryPhoto1(),
                  size: 120,
                  imageType: 'secondary_photo_1',
                ),
                const SizedBox(width: 16),
                EnhancedImagePicker(
                  userId: controller.profile.userId!,
                  currentImageUrl: controller.profile.secondaryPhoto2Url,
                  fallbackText: 'Foto 3',
                  onImageUploaded: (imageUrl) =>
                      controller.updateSecondaryPhoto2(imageUrl),
                  onImageRemoved: () => controller.removeSecondaryPhoto2(),
                  size: 120,
                  imageType: 'secondary_photo_2',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ProfilePhotosTaskController controller) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isSaving.value
                ? null
                : () => _savePhotos(controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: controller.isSaving.value
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Salvando...'),
                    ],
                  )
                : const Text(
                    'Salvar Fotos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ));
  }

  Future<void> _savePhotos(ProfilePhotosTaskController controller) async {
    try {
      // Validate that main photo is present
      if (controller.mainPhotoData.value == null &&
          (controller.profile.mainPhotoUrl?.isEmpty ?? true)) {
        Get.snackbar(
          'Foto Obrigatória',
          'A foto principal é obrigatória para continuar.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await controller.savePhotos();

      // Mark task as completed
      onCompleted('photos');

      // Return to previous screen
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível salvar as fotos. Tente novamente.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
