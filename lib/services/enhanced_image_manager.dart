import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image/image.dart' as img;
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';
import '../services/profile_data_synchronizer.dart';

/// Serviço aprimorado para gerenciamento de imagens
class EnhancedImageManager {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Faz upload de uma imagem de perfil com otimização
  static Future<String?> uploadProfileImage(
    Uint8List imageData, 
    String userId, {
    String imageType = 'main_photo',
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    return await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.image('Starting image upload', userId: userId, data: {
          'imageType': imageType,
          'originalSize': imageData.length,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
        });
        
        // Otimizar imagem antes do upload
        final optimizedData = await _optimizeImage(
          imageData, 
          maxWidth: maxWidth, 
          maxHeight: maxHeight,
          quality: quality,
        );
        
        // Gerar nome único para o arquivo
        final fileName = '${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'spiritual_profiles/$userId/$fileName';
        
        // Fazer upload
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putData(
          optimizedData,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': userId,
              'imageType': imageType,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
        
        // Monitorar progresso
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          EnhancedLogger.progress('Image upload progress', 
            tag: 'IMAGE_UPLOAD', 
            percentage: progress,
            data: {'userId': userId, 'imageType': imageType}
          );
        });
        
        // Aguardar conclusão
        await uploadTask;
        final downloadUrl = await ref.getDownloadURL();
        
        EnhancedLogger.success('Image uploaded successfully', 
          tag: 'IMAGE_UPLOAD',
          data: {
            'userId': userId,
            'imageType': imageType,
            'url': downloadUrl,
            'optimizedSize': optimizedData.length,
            'compressionRatio': ((imageData.length - optimizedData.length) / imageData.length * 100).toStringAsFixed(1) + '%',
          }
        );
        
        return downloadUrl;
      },
      context: 'EnhancedImageManager.uploadProfileImage',
      maxRetries: 2,
    );
  }
  
  /// Otimiza uma imagem reduzindo tamanho e qualidade
  static Future<Uint8List> _optimizeImage(
    Uint8List imageData, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      // Decodificar imagem
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Calcular novo tamanho mantendo proporção
      final originalWidth = image.width;
      final originalHeight = image.height;
      
      double scale = 1.0;
      if (originalWidth > maxWidth || originalHeight > maxHeight) {
        final scaleWidth = maxWidth / originalWidth;
        final scaleHeight = maxHeight / originalHeight;
        scale = math.min(scaleWidth, scaleHeight);
      }
      
      final newWidth = (originalWidth * scale).round();
      final newHeight = (originalHeight * scale).round();
      
      // Redimensionar se necessário
      img.Image resizedImage = image;
      if (scale < 1.0) {
        resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
      }
      
      // Converter para JPEG com qualidade especificada
      final optimizedData = img.encodeJpg(resizedImage, quality: quality);
      
      EnhancedLogger.debug('Image optimized', tag: 'IMAGE_OPTIMIZATION', data: {
        'originalSize': imageData.length,
        'optimizedSize': optimizedData.length,
        'originalDimensions': '${originalWidth}x${originalHeight}',
        'newDimensions': '${newWidth}x${newHeight}',
        'compressionRatio': ((imageData.length - optimizedData.length) / imageData.length * 100).toStringAsFixed(1) + '%',
      });
      
      return Uint8List.fromList(optimizedData);
    } catch (e) {
      EnhancedLogger.warning('Image optimization failed, using original', 
        tag: 'IMAGE_OPTIMIZATION', 
        data: {'error': e.toString()}
      );
      return imageData;
    }
  }
  
  /// Constrói um widget de imagem robusta com fallbacks
  static Widget buildRobustImage(
    String? imageUrl, 
    String fallbackText, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    bool showInitialsOnError = true,
  }) {
    Widget imageWidget;
    
    if (imageUrl?.isNotEmpty == true) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(width, height),
        errorWidget: (context, url, error) {
          EnhancedLogger.warning('Failed to load image', 
            tag: 'IMAGE_LOAD',
            data: {'url': url, 'error': error.toString()}
          );
          
          return showInitialsOnError 
              ? buildInitialsAvatar(fallbackText, width: width, height: height)
              : _buildErrorPlaceholder(width, height);
        },
        fadeInDuration: const Duration(milliseconds: 300),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      );
    } else {
      imageWidget = showInitialsOnError 
          ? buildInitialsAvatar(fallbackText, width: width, height: height)
          : _buildErrorPlaceholder(width, height);
    }
    
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  /// Constrói um avatar com iniciais do nome
  static Widget buildInitialsAvatar(
    String name, {
    double? width,
    double? height,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final initials = _getInitials(name);
    final size = width ?? height ?? 50;
    final bgColor = backgroundColor ?? _generateColorFromName(name);
    final txtColor = textColor ?? _getContrastColor(bgColor);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: txtColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  /// Extrai iniciais de um nome
  static String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, math.min(2, words[0].length)).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
    }
  }
  
  /// Gera uma cor baseada no nome
  static Color _generateColorFromName(String name) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
      Colors.pink[600]!,
      Colors.amber[600]!,
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
  
  /// Determina cor de contraste para texto
  static Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
  
  /// Placeholder para carregamento
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: width == height ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: SizedBox(
          width: math.min(24, (width ?? 50) * 0.4),
          height: math.min(24, (height ?? 50) * 0.4),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
  
  /// Placeholder para erro
  static Widget _buildErrorPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: width == height ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[600],
          size: math.min(24, (width ?? 50) * 0.4),
        ),
      ),
    );
  }
  
  /// Limpa cache de uma imagem específica
  static Future<void> clearImageCache(String imageUrl) async {
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      EnhancedLogger.debug('Image cache cleared', tag: 'IMAGE_CACHE', data: {
        'url': imageUrl,
      });
    } catch (e) {
      EnhancedLogger.warning('Failed to clear image cache', 
        tag: 'IMAGE_CACHE',
        data: {'url': imageUrl, 'error': e.toString()}
      );
    }
  }
  
  /// Limpa todo o cache de imagens
  static Future<void> clearAllImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      EnhancedLogger.info('All image cache cleared', tag: 'IMAGE_CACHE');
    } catch (e) {
      EnhancedLogger.warning('Failed to clear all image cache', 
        tag: 'IMAGE_CACHE',
        data: {'error': e.toString()}
      );
    }
  }
  
  /// Remove uma imagem do Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    return await ErrorHandler.safeExecute(
      () async {
        // Extrair path da URL
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        
        // Encontrar o path após 'o/'
        final oIndex = pathSegments.indexOf('o');
        if (oIndex == -1 || oIndex >= pathSegments.length - 1) {
          throw Exception('Invalid Firebase Storage URL');
        }
        
        final storagePath = pathSegments.sublist(oIndex + 1).join('/');
        final decodedPath = Uri.decodeComponent(storagePath);
        
        // Deletar do Storage
        final ref = _storage.ref().child(decodedPath);
        await ref.delete();
        
        // Limpar cache
        await clearImageCache(imageUrl);
        
        EnhancedLogger.success('Image deleted successfully', 
          tag: 'IMAGE_DELETE',
          data: {'url': imageUrl, 'path': decodedPath}
        );
        
        return true;
      },
      context: 'EnhancedImageManager.deleteImage',
      fallbackValue: false,
    ) ?? false;
  }
  
  /// Atualiza foto de perfil principal com sincronização
  static Future<bool> updateMainProfilePhoto(String userId, Uint8List imageData) async {
    return await ErrorHandler.safeExecute(
      () async {
        // Upload da nova imagem
        final imageUrl = await uploadProfileImage(
          imageData, 
          userId,
          imageType: 'main_photo',
        );
        
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
        
        // Sincronizar com ambas as collections
        await ProfileDataSynchronizer.updateProfileImage(userId, imageUrl);
        
        EnhancedLogger.success('Main profile photo updated', 
          tag: 'PROFILE_PHOTO',
          data: {'userId': userId, 'imageUrl': imageUrl}
        );
        
        ErrorHandler.showSuccess('Foto de perfil atualizada com sucesso!');
        return true;
      },
      context: 'EnhancedImageManager.updateMainProfilePhoto',
      fallbackValue: false,
    ) ?? false;
  }
  
  /// Valida se um arquivo é uma imagem válida
  static bool isValidImageData(Uint8List data) {
    try {
      final image = img.decodeImage(data);
      return image != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtém informações sobre uma imagem
  static ImageInfo? getImageInfo(Uint8List data) {
    try {
      final image = img.decodeImage(data);
      if (image == null) return null;
      
      return ImageInfo(
        width: image.width,
        height: image.height,
        size: data.length,
        format: _detectImageFormat(data),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Detecta formato da imagem
  static String _detectImageFormat(Uint8List data) {
    if (data.length < 4) return 'unknown';
    
    // JPEG
    if (data[0] == 0xFF && data[1] == 0xD8) return 'JPEG';
    
    // PNG
    if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) return 'PNG';
    
    // GIF
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) return 'GIF';
    
    // WebP
    if (data.length >= 12 && 
        data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
        data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
      return 'WebP';
    }
    
    return 'unknown';
  }
  
  /// Obtém estatísticas de uso de storage
  static Future<StorageStats> getStorageStats(String userId) async {
    return await ErrorHandler.safeExecute(
      () async {
        final ref = _storage.ref().child('spiritual_profiles/$userId');
        final result = await ref.listAll();
        
        int totalFiles = result.items.length;
        int totalSize = 0;
        
        for (final item in result.items) {
          try {
            final metadata = await item.getMetadata();
            totalSize += metadata.size ?? 0;
          } catch (e) {
            // Ignorar erros de metadata individual
          }
        }
        
        return StorageStats(
          totalFiles: totalFiles,
          totalSize: totalSize,
          userId: userId,
        );
      },
      context: 'EnhancedImageManager.getStorageStats',
      fallbackValue: StorageStats(totalFiles: 0, totalSize: 0, userId: userId),
    ) ?? StorageStats(totalFiles: 0, totalSize: 0, userId: userId);
  }
}

/// Informações sobre uma imagem
class ImageInfo {
  final int width;
  final int height;
  final int size;
  final String format;
  
  ImageInfo({
    required this.width,
    required this.height,
    required this.size,
    required this.format,
  });
  
  double get aspectRatio => width / height;
  String get sizeFormatted => _formatBytes(size);
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Estatísticas de uso de storage
class StorageStats {
  final int totalFiles;
  final int totalSize;
  final String userId;
  
  StorageStats({
    required this.totalFiles,
    required this.totalSize,
    required this.userId,
  });
  
  String get totalSizeFormatted => _formatBytes(totalSize);
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}