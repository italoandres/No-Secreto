import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/enhanced_image_manager.dart';
import '../utils/enhanced_logger.dart';

/// Widget de imagem robusta com fallbacks automáticos
class RobustImageWidget extends StatefulWidget {
  final String? imageUrl;
  final String fallbackText;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showInitialsOnError;
  final Color? backgroundColor;
  final Color? textColor;
  final bool enableRetry;
  final int maxRetries;
  final Duration retryDelay;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const RobustImageWidget({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showInitialsOnError = true,
    this.backgroundColor,
    this.textColor,
    this.enableRetry = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<RobustImageWidget> createState() => _RobustImageWidgetState();
}

class _RobustImageWidgetState extends State<RobustImageWidget> {
  int _retryCount = 0;
  bool _isRetrying = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(RobustImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _currentImageUrl = widget.imageUrl;
      _retryCount = 0;
      _isRetrying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (_currentImageUrl?.isNotEmpty == true) {
      imageWidget = CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(error),
        fadeInDuration: const Duration(milliseconds: 300),
        memCacheWidth: widget.width?.toInt(),
        memCacheHeight: widget.height?.toInt(),
      );
    } else {
      imageWidget = _buildFallbackWidget();
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: _getIconSize() * 0.6,
          height: _getIconSize() * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    EnhancedLogger.warning('Image load failed', tag: 'ROBUST_IMAGE', data: {
      'url': _currentImageUrl,
      'error': error.toString(),
      'retryCount': _retryCount,
    });

    // Se retry está habilitado e ainda temos tentativas
    if (widget.enableRetry && _retryCount < widget.maxRetries && !_isRetrying) {
      _scheduleRetry();
    }

    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    if (_isRetrying) {
      return _buildRetryingWidget();
    }

    if (widget.showInitialsOnError) {
      return _buildFallbackWidget();
    }

    return _buildDefaultErrorWidget();
  }

  Widget _buildRetryingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _getIconSize() * 0.5,
              height: _getIconSize() * 0.5,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tentando...',
              style: TextStyle(
                fontSize: _getIconSize() * 0.15,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return EnhancedImageManager.buildInitialsAvatar(
      widget.fallbackText,
      width: widget.width,
      height: widget.height,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey[600],
              size: _getIconSize() * 0.4,
            ),
            if (_retryCount >= widget.maxRetries) ...[
              const SizedBox(height: 4),
              Text(
                'Erro',
                style: TextStyle(
                  fontSize: _getIconSize() * 0.15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _scheduleRetry() {
    _isRetrying = true;
    _retryCount++;

    EnhancedLogger.info('Scheduling image retry', tag: 'ROBUST_IMAGE', data: {
      'url': _currentImageUrl,
      'retryCount': _retryCount,
      'maxRetries': widget.maxRetries,
    });

    Future.delayed(widget.retryDelay, () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          // Forçar reload da imagem adicionando timestamp
          _currentImageUrl = '${widget.imageUrl}?retry=$_retryCount';
        });
      }
    });
  }

  double _getIconSize() {
    return (widget.width ?? widget.height ?? 50);
  }
}

/// Widget especializado para fotos de perfil
class ProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String userName;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final bool enableRetry;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    required this.userName,
    this.size = 50,
    this.showBorder = false,
    this.borderColor,
    this.enableRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = RobustImageWidget(
      imageUrl: imageUrl,
      fallbackText: userName,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      enableRetry: enableRetry,
    );

    if (showBorder) {
      imageWidget = Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: 2,
          ),
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Widget para galeria de imagens com lazy loading
class ImageGalleryWidget extends StatelessWidget {
  final List<String> imageUrls;
  final String fallbackText;
  final double itemHeight;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Function(String imageUrl, int index)? onImageTap;

  const ImageGalleryWidget({
    super.key,
    required this.imageUrls,
    required this.fallbackText,
    this.itemHeight = 120,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                color: Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma foto',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = imageUrls[index];

        return GestureDetector(
          onTap: onImageTap != null ? () => onImageTap!(imageUrl, index) : null,
          child: RobustImageWidget(
            imageUrl: imageUrl,
            fallbackText: '$fallbackText ${index + 1}',
            borderRadius: BorderRadius.circular(12),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

/// Widget para preview de imagem com zoom
class ImagePreviewWidget extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const ImagePreviewWidget({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: RobustImageWidget(
                imageUrl: imageUrl,
                fallbackText: fallbackText,
                fit: BoxFit.contain,
                enableRetry: true,
              ),
            ),
          ),
          if (showCloseButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: onClose ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
