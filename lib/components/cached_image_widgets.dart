import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget otimizado para exibir imagens com cache automático
///
/// Usa cached_network_image para:
/// - Cache em disco
/// - Cache em memória
/// - Placeholder durante carregamento
/// - Error handling automático
///
/// USO:
/// ```dart
/// CachedImage(
///   imageUrl: user.imgUrl,
///   width: 100,
///   height: 100,
///   borderRadius: 50,
/// )
/// ```
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const CachedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não tem URL, mostra erro/placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,

        // Placeholder durante carregamento
        placeholder: (context, url) {
          return placeholder ?? _buildPlaceholder();
        },

        // Widget de erro
        errorWidget: (context, url, error) {
          return errorWidget ?? _buildErrorWidget();
        },

        // Cache settings
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),

        // Memory cache
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: (width ?? 100) * 0.3,
          height: (height ?? 100) * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[300],
      child: Icon(
        Icons.person,
        size: (width ?? 100) * 0.5,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Widget para foto de perfil circular com cache
///
/// USO:
/// ```dart
/// CachedProfileImage(
///   imageUrl: user.imgUrl,
///   size: 60,
/// )
/// ```
class CachedProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  const CachedProfileImage({
    Key? key,
    required this.imageUrl,
    this.size = 50,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget image = CachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: size / 2,
      fit: BoxFit.cover,
    );

    if (showBorder) {
      image = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: image,
      );
    }

    return image;
  }
}

/// Widget para imagem de fundo com cache
///
/// USO:
/// ```dart
/// CachedBackgroundImage(
///   imageUrl: user.imgBgUrl,
///   child: YourContent(),
/// )
/// ```
class CachedBackgroundImage extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final BoxFit fit;
  final Color? overlayColor;
  final double overlayOpacity;

  const CachedBackgroundImage({
    Key? key,
    required this.imageUrl,
    required this.child,
    this.fit = BoxFit.cover,
    this.overlayColor,
    this.overlayOpacity = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return child;
    }

    return Stack(
      children: [
        // Imagem de fundo com cache
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
            ),
          ),
        ),

        // Overlay opcional
        if (overlayColor != null && overlayOpacity > 0)
          Positioned.fill(
            child: Container(
              color: overlayColor!.withOpacity(overlayOpacity),
            ),
          ),

        // Conteúdo
        child,
      ],
    );
  }
}

/// Widget para grid de imagens com cache (stories, galeria, etc)
///
/// USO:
/// ```dart
/// CachedImageGrid(
///   imageUrls: story.photos,
///   crossAxisCount: 3,
///   spacing: 4,
/// )
/// ```
class CachedImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double spacing;
  final double aspectRatio;

  const CachedImageGrid({
    Key? key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.spacing = 4,
    this.aspectRatio = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return CachedImage(
          imageUrl: imageUrls[index],
          borderRadius: 8,
        );
      },
    );
  }
}

/// Helper para pre-carregar imagens em cache
///
/// USO:
/// ```dart
/// // Pre-carregar lista de perfis
/// await CachedImageHelper.precacheProfileImages(
///   context,
///   users.map((u) => u.imgUrl).toList(),
/// );
/// ```
class CachedImageHelper {
  /// Pre-carregar uma lista de imagens
  static Future<void> precacheImages(
    BuildContext context,
    List<String?> imageUrls,
  ) async {
    final validUrls =
        imageUrls.where((url) => url != null && url.isNotEmpty).toList();

    for (final url in validUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url!),
          context,
        );
      } catch (e) {
        print('❌ Erro ao pre-carregar imagem: $e');
      }
    }
  }

  /// Pre-carregar imagens de perfis
  static Future<void> precacheProfileImages(
    BuildContext context,
    List<String?> imageUrls,
  ) async {
    return precacheImages(context, imageUrls);
  }

  /// Limpar cache de imagens
  static Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      print('🗑️ CACHE DE IMAGENS LIMPO');
    } catch (e) {
      print('❌ Erro ao limpar cache de imagens: $e');
    }
  }

  /// Obter tamanho do cache
  static Future<String> getCacheSize() async {
    try {
      final cacheInfo = await DefaultCacheManager().getFileFromCache('');
      // Implementar cálculo de tamanho se necessário
      return '0 MB';
    } catch (e) {
      return 'Erro';
    }
  }
}
