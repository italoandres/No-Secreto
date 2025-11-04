import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/video_thumbnail_editor_controller.dart';

/// Tela moderna de edição de thumbnail de vídeo
/// 
/// Permite ao usuário escolher um frame específico do vídeo ou fazer upload
/// de uma imagem personalizada para usar como capa do story.
class VideoThumbnailEditorView extends StatefulWidget {
  final File? videoFile;
  final String? contexto;
  
  const VideoThumbnailEditorView({
    Key? key,
    this.videoFile,
    this.contexto,
  }) : super(key: key);
  
  @override
  State<VideoThumbnailEditorView> createState() => _VideoThumbnailEditorViewState();
}

class _VideoThumbnailEditorViewState extends State<VideoThumbnailEditorView> {
  late VideoThumbnailEditorController controller;
  VideoPlayerController? _videoController;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controller COM os dados ANTES do Get.put
    controller = Get.put(VideoThumbnailEditorController());
    // Setar dados ANTES do onInit ser chamado
    controller.videoFile = widget.videoFile;
    controller.contexto = widget.contexto;
    
    // Chamar geração de frames manualmente após setar os dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.generateFrames();
    });
    
    // Inicializar video player para preview
    if (widget.videoFile != null) {
      _videoController = VideoPlayerController.file(widget.videoFile!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        })
        ..setLooping(true)
        ..play();
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    Get.delete<VideoThumbnailEditorController>();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Preview do vídeo (fundo)
            _buildVideoPreview(),
            
            // Overlay com controles
            Column(
              children: [
                // Header com botão voltar
                _buildHeader(),
                
                const Spacer(),
                
                // Preview da thumbnail selecionada
                _buildThumbnailPreview(),
                
                const SizedBox(height: 16),
                
                // Slider de frames (estilo TikTok)
                _buildFramesSlider(),
                
                const SizedBox(height: 16),
                
                // Botões de ação
                _buildActionButtons(),
                
                const SizedBox(height: 24),
              ],
            ),
            
            // Loading overlay
            Obx(() => controller.isGeneratingFrames.value
              ? _buildLoadingOverlay()
              : const SizedBox.shrink()
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPreview() {
    return Center(
      child: _videoController != null && _videoController!.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
        : Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => controller.cancel(),
          ),
          const Spacer(),
          const Text(
            'Escolher Capa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Espaço para centralizar título
        ],
      ),
    );
  }
  
  Widget _buildThumbnailPreview() {
    return Obx(() {
      final thumbnail = controller.selectedThumbnail.value;
      
      if (thumbnail == null) {
        return const SizedBox.shrink();
      }
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            thumbnail,
            height: 140,
            width: 140,
            fit: BoxFit.cover,
          ),
        ),
      );
    });
  }
  
  Widget _buildFramesSlider() {
    return Obx(() {
      if (controller.frames.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Escolha um frame:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.frames.length,
              itemBuilder: (context, index) {
                final isSelected = controller.selectedFrameIndex.value == index &&
                                 controller.thumbnailSource.value == 'frame';
                
                return GestureDetector(
                  onTap: () => controller.selectFrame(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.white.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        controller.frames[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Botão Upload da Galeria
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => controller.uploadImageFromGallery(),
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: const Text(
                'Galeria',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Botão Continuar
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => controller.continueToForm(),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Continuar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gerando frames...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Isso pode levar alguns segundos',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
