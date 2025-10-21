import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Seção que exibe galeria de fotos do perfil
/// 
/// Exibe foto principal e fotos secundárias em um grid
/// Permite clicar para ver em tela cheia
class PhotoGallerySection extends StatelessWidget {
  final String? mainPhotoUrl;
  final String? secondaryPhoto1Url;
  final String? secondaryPhoto2Url;

  const PhotoGallerySection({
    Key? key,
    this.mainPhotoUrl,
    this.secondaryPhoto1Url,
    this.secondaryPhoto2Url,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Coletar apenas fotos secundárias (não incluir a principal)
    final secondaryPhotos = _getSecondaryPhotos();
    
    // Se não houver fotos secundárias, não renderizar galeria
    if (secondaryPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
            children: [
              if (secondaryPhoto1Url?.isNotEmpty == true)
                Expanded(
                  child: _buildSecondaryPhotoItem(
                    secondaryPhoto1Url!,
                    0,
                    secondaryPhotos,
                  ),
                ),
              if (secondaryPhoto1Url?.isNotEmpty == true &&
                  secondaryPhoto2Url?.isNotEmpty == true)
                const SizedBox(width: 12),
              if (secondaryPhoto2Url?.isNotEmpty == true)
                Expanded(
                  child: _buildSecondaryPhotoItem(
                    secondaryPhoto2Url!,
                    secondaryPhoto1Url?.isNotEmpty == true ? 1 : 0,
                    secondaryPhotos,
                  ),
                ),
            ],
          ),
    );
  }

  /// Constrói um item de foto secundária (formato quadrado)
  Widget _buildSecondaryPhotoItem(
      String photoUrl, int index, List<String> allPhotos) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(index, allPhotos),
      child: AspectRatio(
        aspectRatio: 1, // Formato quadrado
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover, // Cobre o quadrado (corta se necessário)
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Ícone de expandir
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre o visualizador de fotos em tela cheia
  void _openPhotoViewer(int initialIndex, List<String> photos) {
    // Debug: verificar URLs
    print('📸 Opening photo viewer');
    print('📸 Initial index: $initialIndex');
    print('📸 Photos: $photos');
    print('📸 Photos length: ${photos.length}');
    
    if (photos.isEmpty) {
      print('❌ No photos to display');
      return;
    }
    
    try {
      Get.to(
        () => PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
        transition: Transition.fadeIn,
      );
    } catch (e) {
      print('❌ Error opening photo viewer: $e');
    }
  }

  /// Retorna lista apenas de fotos secundárias
  List<String> _getSecondaryPhotos() {
    final photos = <String>[];
    
    if (secondaryPhoto1Url?.isNotEmpty == true) {
      photos.add(secondaryPhoto1Url!);
    }
    
    if (secondaryPhoto2Url?.isNotEmpty == true) {
      photos.add(secondaryPhoto2Url!);
    }
    
    return photos;
  }
}

/// Tela de visualização de fotos em tela cheia
class PhotoViewerScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Debug
    print('📸 PhotoViewerScreen initState');
    print('📸 Photos: ${widget.photos}');
    print('📸 Initial index: ${widget.initialIndex}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('📸 PhotoViewerScreen build');
    print('📸 Photos count: ${widget.photos.length}');
    
    if (widget.photos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma foto disponível',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // PageView de fotos
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photoUrl = widget.photos[index];
                print('📸 Building photo at index $index: $photoUrl');
                
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error loading image: $error');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Erro ao carregar imagem',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('✅ Image loaded successfully');
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Botão de fechar
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () {
                  print('📸 Closing photo viewer');
                  Get.back();
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            
            // Indicador de posição
            if (widget.photos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
