import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/thumbnail_generator_service.dart';

/// Controller para a tela de edição de thumbnail de vídeo
/// 
/// Gerencia o estado da tela, geração de frames, seleção de thumbnail
/// e navegação para o formulário de publicação.
class VideoThumbnailEditorController extends GetxController {
  // Vídeo selecionado (Mobile)
  File? videoFile;
  
  // Vídeo selecionado (Web)
  Uint8List? videoBytes;
  String? videoFileName;
  
  // Contexto do story (principal, sinais_isaque, etc.)
  String? contexto;
  
  // Frames gerados do vídeo
  final RxList<File> frames = <File>[].obs;
  
  // Frame/imagem selecionada como thumbnail
  final Rx<File?> selectedThumbnail = Rx<File?>(null);
  
  // Índice do frame selecionado no slider
  final RxInt selectedFrameIndex = 0.obs;
  
  // Loading states
  final RxBool isGeneratingFrames = false.obs;
  final RxBool isUploadingStory = false.obs;
  
  // Tipo de thumbnail (frame ou upload)
  final RxString thumbnailSource = 'frame'.obs; // 'frame' ou 'upload'
  
  @override
  void onInit() {
    super.onInit();
    print('🎬 THUMBNAIL_EDITOR: Controller inicializado');
    // NÃO chamar _generateFrames() aqui
    // Será chamado manualmente pela View após setar videoFile
  }
  
  @override
  void onClose() {
    print('🎬 THUMBNAIL_EDITOR: Controller fechado');
    super.onClose();
  }
  
  /// Gera frames do vídeo
  Future<void> generateFrames() async {
    print('🎬 THUMBNAIL_EDITOR: Iniciando geração de frames');
    isGeneratingFrames.value = true;
    
    try {
      if (videoFile != null) {
        // Mobile: usar arquivo
        print('🎬 THUMBNAIL_EDITOR: Gerando frames do arquivo: ${videoFile!.path}');
        
        final generatedFrames = await ThumbnailGeneratorService.generateFrames(
          videoPath: videoFile!.path,
          frameCount: 10,
        );
        
        frames.value = generatedFrames;
        print('✅ THUMBNAIL_EDITOR: ${generatedFrames.length} frames gerados');
        
        // Selecionar primeiro frame por padrão
        if (generatedFrames.isNotEmpty) {
          selectedThumbnail.value = generatedFrames[0];
          selectedFrameIndex.value = 0;
          thumbnailSource.value = 'frame';
          print('✅ THUMBNAIL_EDITOR: Primeiro frame selecionado por padrão');
        } else {
          print('⚠️ THUMBNAIL_EDITOR: Nenhum frame gerado, tentando gerar thumbnail padrão');
          // Fallback: gerar thumbnail padrão
          final defaultThumb = await ThumbnailGeneratorService.generateDefaultThumbnail(
            videoFile!.path,
          );
          if (defaultThumb != null) {
            selectedThumbnail.value = defaultThumb;
            frames.add(defaultThumb);
            print('✅ THUMBNAIL_EDITOR: Thumbnail padrão gerado como fallback');
          }
        }
      } else if (videoBytes != null) {
        // Web: usar bytes
        print('🎬 THUMBNAIL_EDITOR WEB: Gerando thumbnail de bytes');
        
        // Para web, gerar apenas thumbnail padrão (primeiro frame)
        // Gerar múltiplos frames de bytes é mais complexo e pode ser implementado depois
        final thumbnailData = await ThumbnailGeneratorService.generateThumbnailFromBytes(
          videoBytes: videoBytes!,
          timeMs: 0,
        );
        
        if (thumbnailData != null) {
          // Salvar thumbnail como arquivo temporário
          final tempFile = await _saveThumbnailToTempFile(thumbnailData);
          if (tempFile != null) {
            frames.add(tempFile);
            selectedThumbnail.value = tempFile;
            selectedFrameIndex.value = 0;
            thumbnailSource.value = 'frame';
            print('✅ THUMBNAIL_EDITOR WEB: Thumbnail gerado');
          }
        }
      } else {
        print('❌ THUMBNAIL_EDITOR: Nenhum vídeo fornecido');
        Get.snackbar(
          'Erro',
          'Nenhum vídeo foi fornecido para gerar frames',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
        );
      }
    } catch (e) {
      print('❌ THUMBNAIL_EDITOR: Erro ao gerar frames: $e');
      Get.snackbar(
        'Erro ao Gerar Frames',
        'Não foi possível processar o vídeo. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      );
    } finally {
      isGeneratingFrames.value = false;
    }
  }
  
  /// Salva thumbnail bytes em arquivo temporário
  Future<File?> _saveThumbnailToTempFile(Uint8List bytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      print('❌ THUMBNAIL_EDITOR: Erro ao salvar thumbnail temporário: $e');
      return null;
    }
  }
  
  /// Seleciona frame do slider
  void selectFrame(int index) {
    if (index >= 0 && index < frames.length) {
      print('🎬 THUMBNAIL_EDITOR: Frame $index selecionado');
      selectedFrameIndex.value = index;
      selectedThumbnail.value = frames[index];
      thumbnailSource.value = 'frame';
    }
  }
  
  /// Faz upload de imagem da galeria
  Future<void> uploadImageFromGallery() async {
    print('📷 THUMBNAIL_EDITOR: Abrindo galeria para upload de imagem');
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (image != null) {
        print('✅ THUMBNAIL_EDITOR: Imagem selecionada: ${image.name}');
        
        final imageFile = File(image.path);
        selectedThumbnail.value = imageFile;
        thumbnailSource.value = 'upload';
        
        Get.snackbar(
          'Imagem Selecionada',
          'Sua capa personalizada foi carregada com sucesso',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
        );
      } else {
        print('⚠️ THUMBNAIL_EDITOR: Nenhuma imagem selecionada');
      }
    } catch (e) {
      print('❌ THUMBNAIL_EDITOR: Erro ao selecionar imagem: $e');
      Get.snackbar(
        'Erro ao Selecionar Imagem',
        'Não foi possível carregar a imagem da galeria',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      );
    }
  }
  
  /// Continua para o formulário de publicação
  /// 
  /// Fecha o editor e retorna a thumbnail selecionada para o fluxo de publicação
  void continueToForm() {
    if (selectedThumbnail.value == null) {
      print('⚠️ THUMBNAIL_EDITOR: Nenhuma thumbnail selecionada');
      Get.snackbar(
        'Selecione uma Capa',
        'Escolha um frame do vídeo ou faça upload de uma imagem',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
      );
      return;
    }
    
    print('✅ THUMBNAIL_EDITOR: Continuando para formulário');
    print('✅ THUMBNAIL_EDITOR: Thumbnail source: ${thumbnailSource.value}');
    
    // Retornar dados para o fluxo de publicação
    Get.back(result: {
      'thumbnailFile': selectedThumbnail.value,
      'thumbnailSource': thumbnailSource.value,
      'videoFile': videoFile,
      'videoBytes': videoBytes,
      'videoFileName': videoFileName,
      'contexto': contexto,
    });
  }
  
  /// Cancela e volta para a tela anterior
  void cancel() {
    print('❌ THUMBNAIL_EDITOR: Cancelado pelo usuário');
    Get.back();
  }
}
