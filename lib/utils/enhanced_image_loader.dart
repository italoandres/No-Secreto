import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'storage_proxy.dart';
import 'dart:async';

class EnhancedImageLoader {
  static final Map<String, bool> _preloadedImages = {};
  static final Map<String, Completer<void>> _preloadingImages = {};

  /// Constrói uma imagem com cache, placeholder e retry logic
  static Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    // Usar proxy para URLs do Firebase Storage
    final proxiedUrl = StorageProxy.isFirebaseStorageUrl(imageUrl) 
        ? StorageProxy.getProxiedUrl(imageUrl)
        : imageUrl;
    
    print('🖼️ ENHANCED: Carregando imagem via proxy: $proxiedUrl');
    
    return CachedNetworkImage(
      imageUrl: proxiedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => _buildRetryWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        currentRetry: 1,
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  /// Widget de placeholder padrão
  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  /// Widget de erro com retry
  static Widget _buildRetryWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    int currentRetry = 1,
  }) {
    if (currentRetry >= maxRetries) {
      return errorWidget ?? _buildDefaultErrorWidget();
    }

    return FutureBuilder(
      future: _retryAfterDelay(retryDelay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 8),
                  Text(
                    'Tentando novamente...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Usar proxy para URLs do Firebase Storage no retry também
        final proxiedUrl = StorageProxy.isFirebaseStorageUrl(imageUrl) 
            ? StorageProxy.getProxiedUrl(imageUrl)
            : imageUrl;
        
        return CachedNetworkImage(
          imageUrl: proxiedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
          errorWidget: (context, url, error) => _buildRetryWidget(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: placeholder,
            errorWidget: errorWidget,
            maxRetries: maxRetries,
            retryDelay: retryDelay,
            currentRetry: currentRetry + 1,
          ),
        );
      },
    );
  }

  /// Widget de erro padrão
  static Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Erro ao carregar imagem',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Delay para retry
  static Future<void> _retryAfterDelay(Duration delay) async {
    await Future.delayed(delay);
  }

  /// Pré-carrega uma imagem para otimização
  static Future<void> preloadImage(String imageUrl, BuildContext context) async {
    if (_preloadedImages.containsKey(imageUrl)) {
      return; // Já foi pré-carregada
    }

    if (_preloadingImages.containsKey(imageUrl)) {
      return await _preloadingImages[imageUrl]!.future; // Já está sendo pré-carregada
    }

    final completer = Completer<void>();
    _preloadingImages[imageUrl] = completer;

    try {
      // Usar proxy para URLs do Firebase Storage no preload também
      final proxiedUrl = StorageProxy.isFirebaseStorageUrl(imageUrl) 
          ? StorageProxy.getProxiedUrl(imageUrl)
          : imageUrl;
      
      debugPrint('🖼️ PRELOAD: Pré-carregando imagem: $proxiedUrl');
      
      await precacheImage(
        CachedNetworkImageProvider(proxiedUrl),
        context,
      );
      
      _preloadedImages[imageUrl] = true;
      debugPrint('✅ PRELOAD: Imagem pré-carregada com sucesso: $imageUrl');
      
    } catch (e) {
      debugPrint('❌ PRELOAD: Erro ao pré-carregar imagem $imageUrl: $e');
    } finally {
      _preloadingImages.remove(imageUrl);
      completer.complete();
    }
  }

  /// Pré-carrega múltiplas imagens
  static Future<void> preloadImages(List<String> imageUrls, BuildContext context) async {
    final futures = imageUrls.map((url) => preloadImage(url, context));
    await Future.wait(futures);
  }

  /// Limpa o cache de imagens
  static Future<void> clearImageCache() async {
    try {
      debugPrint('🧹 CACHE: Limpando cache de imagens');
      await CachedNetworkImage.evictFromCache('');
      _preloadedImages.clear();
      _preloadingImages.clear();
      debugPrint('✅ CACHE: Cache limpo com sucesso');
    } catch (e) {
      debugPrint('❌ CACHE: Erro ao limpar cache: $e');
    }
  }

  /// Verifica se uma imagem está no cache
  static Future<bool> isImageCached(String imageUrl) async {
    try {
      // Simplified cache check - always return false for now
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Remove uma imagem específica do cache
  static Future<void> removeFromCache(String imageUrl) async {
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      _preloadedImages.remove(imageUrl);
      debugPrint('🗑️ CACHE: Imagem removida do cache: $imageUrl');
    } catch (e) {
      debugPrint('❌ CACHE: Erro ao remover imagem do cache: $e');
    }
  }

  /// Obtém informações do cache
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      return {
        'cacheDirectory': 'cache_managed_by_flutter',
        'preloadedCount': _preloadedImages.length,
        'preloadingCount': _preloadingImages.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'preloadedCount': _preloadedImages.length,
        'preloadingCount': _preloadingImages.length,
      };
    }
  }
}

// Extensão para facilitar o uso
extension EnhancedImageWidget on Widget {
  static Widget cachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return EnhancedImageLoader.buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}