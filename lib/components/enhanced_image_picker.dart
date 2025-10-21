import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/enhanced_image_manager.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';

/// Componente aprimorado para seleção e upload de imagens
class EnhancedImagePicker extends StatefulWidget {
  final String userId;
  final String? currentImageUrl;
  final String fallbackText;
  final Function(String imageUrl)? onImageUploaded;
  final Function()? onImageRemoved;
  final double size;
  final bool allowRemove;
  final String imageType;
  
  const EnhancedImagePicker({
    super.key,
    required this.userId,
    this.currentImageUrl,
    required this.fallbackText,
    this.onImageUploaded,
    this.onImageRemoved,
    this.size = 120,
    this.allowRemove = true,
    this.imageType = 'main_photo',
  });

  @override
  State<EnhancedImagePicker> createState() => _EnhancedImagePickerState();
}

class _EnhancedImagePickerState extends State<EnhancedImagePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildImageContainer(),
        const SizedBox(height: 12),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildImageContainer() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImageOptions,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isUploading ? Colors.blue[300]! : Colors.grey[300]!,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            // Imagem principal
            Positioned.fill(
              child: ClipOval(
                child: _isUploading 
                    ? _buildUploadingWidget()
                    : EnhancedImageManager.buildRobustImage(
                        widget.currentImageUrl,
                        widget.fallbackText,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            
            // Overlay de edição
            if (!_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            
            // Indicador de progresso
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: _uploadProgress,
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.cloud_upload,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Enviando...',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.photo_library,
          label: 'Galeria',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.camera_alt,
          label: 'Câmera',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        if (widget.allowRemove && widget.currentImageUrl?.isNotEmpty == true) ...[
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.delete,
            label: 'Remover',
            onTap: _removeImage,
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.blue[600]!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: buttonColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: buttonColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: buttonColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecionar Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildBottomSheetOption(
              icon: Icons.photo_library,
              title: 'Galeria',
              subtitle: 'Escolher da galeria de fotos',
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            
            _buildBottomSheetOption(
              icon: Icons.camera_alt,
              title: 'Câmera',
              subtitle: 'Tirar uma nova foto',
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            
            if (widget.allowRemove && widget.currentImageUrl?.isNotEmpty == true)
              _buildBottomSheetOption(
                icon: Icons.delete,
                title: 'Remover Foto',
                subtitle: 'Usar avatar com iniciais',
                onTap: () {
                  Get.back();
                  _removeImage();
                },
                color: Colors.red,
              ),
            
            const SizedBox(height: 10),
            
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? Colors.blue[600]!;
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: optionColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: optionColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.info('Starting image selection', tag: 'IMAGE_PICKER', data: {
          'source': source.name,
          'userId': widget.userId,
          'imageType': widget.imageType,
        });
        
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 90,
        );
        
        if (image == null) {
          EnhancedLogger.info('Image selection cancelled', tag: 'IMAGE_PICKER');
          return;
        }
        
        // Validar tamanho do arquivo
        final fileSize = await image.length();
        if (fileSize > 10 * 1024 * 1024) { // 10MB
          ErrorHandler.showWarning('Imagem muito grande. Escolha uma imagem menor que 10MB.');
          return;
        }
        
        // Ler dados da imagem
        final imageData = await image.readAsBytes();
        
        // Validar se é uma imagem válida
        if (!EnhancedImageManager.isValidImageData(imageData)) {
          ErrorHandler.showWarning('Arquivo selecionado não é uma imagem válida.');
          return;
        }
        
        // Obter informações da imagem
        final imageInfo = EnhancedImageManager.getImageInfo(imageData);
        EnhancedLogger.debug('Image selected', tag: 'IMAGE_PICKER', data: {
          'size': imageInfo?.sizeFormatted ?? 'unknown',
          'dimensions': imageInfo != null ? '${imageInfo.width}x${imageInfo.height}' : 'unknown',
          'format': imageInfo?.format ?? 'unknown',
        });
        
        // Iniciar upload
        await _uploadImage(imageData);
      },
      context: 'EnhancedImagePicker._pickImage',
      showUserMessage: true,
    );
  }

  Future<void> _uploadImage(Uint8List imageData) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simular progresso (o Firebase não fornece progresso real para putData)
      _simulateProgress();
      
      final imageUrl = await EnhancedImageManager.uploadProfileImage(
        imageData,
        widget.userId,
        imageType: widget.imageType,
      );

      if (imageUrl != null && mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
        
        // Aguardar um pouco para mostrar 100%
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (widget.onImageUploaded != null) {
          widget.onImageUploaded!(imageUrl);
        }
        
        EnhancedLogger.success('Image upload completed', tag: 'IMAGE_PICKER', data: {
          'userId': widget.userId,
          'imageType': widget.imageType,
          'url': imageUrl,
        });
      } else {
        throw Exception('Failed to get image URL');
      }
    } catch (e) {
      EnhancedLogger.error('Image upload failed', 
        tag: 'IMAGE_PICKER', 
        error: e,
        data: {'userId': widget.userId, 'imageType': widget.imageType}
      );
      
      ErrorHandler.showWarning('Falha no upload da imagem. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _simulateProgress() {
    // Simular progresso de upload
    const duration = Duration(milliseconds: 100);
    const increment = 0.1;
    
    void updateProgress() {
      if (!mounted || !_isUploading) return;
      
      setState(() {
        _uploadProgress = (_uploadProgress + increment).clamp(0.0, 0.9);
      });
      
      if (_uploadProgress < 0.9) {
        Future.delayed(duration, updateProgress);
      }
    }
    
    Future.delayed(duration, updateProgress);
  }

  Future<void> _removeImage() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remover Foto'),
        content: const Text('Tem certeza que deseja remover sua foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remover do Firebase Storage se existir
        if (widget.currentImageUrl?.isNotEmpty == true) {
          await EnhancedImageManager.deleteImage(widget.currentImageUrl!);
        }
        
        if (widget.onImageRemoved != null) {
          widget.onImageRemoved!();
        }
        
        EnhancedLogger.info('Image removed', tag: 'IMAGE_PICKER', data: {
          'userId': widget.userId,
          'imageType': widget.imageType,
        });
        
        ErrorHandler.showSuccess('Foto removida com sucesso!');
      } catch (e) {
        EnhancedLogger.error('Failed to remove image', 
          tag: 'IMAGE_PICKER', 
          error: e,
          data: {'userId': widget.userId, 'imageType': widget.imageType}
        );
        
        ErrorHandler.showWarning('Erro ao remover foto. Tente novamente.');
      }
    }
  }
}