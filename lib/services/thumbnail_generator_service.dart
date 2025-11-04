import 'dart:io';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Serviço para gerar thumbnails (frames) de vídeos
/// 
/// Usado para criar múltiplos frames distribuídos uniformemente ao longo do vídeo,
/// permitindo que o usuário escolha qual frame usar como capa do story.
class ThumbnailGeneratorService {
  /// Gera múltiplos frames do vídeo distribuídos uniformemente
  /// 
  /// [videoPath] - Caminho do arquivo de vídeo
  /// [frameCount] - Número de frames a gerar (padrão: 10)
  /// 
  /// Retorna lista de File com os frames gerados
  static Future<List<File>> generateFrames({
    required String videoPath,
    int frameCount = 10,
  }) async {
    print('🎬 THUMBNAIL_GEN: Iniciando geração de $frameCount frames');
    print('🎬 THUMBNAIL_GEN: Vídeo: $videoPath');
    
    final List<File> frames = [];
    final tempDir = await getTemporaryDirectory();
    
    try {
      // Obter duração do vídeo usando VideoPlayerController
      final videoDuration = await _getVideoDuration(videoPath);
      
      if (videoDuration == null || videoDuration.inMilliseconds == 0) {
        print('⚠️ THUMBNAIL_GEN: Não foi possível obter duração, usando intervalos fixos');
        // Fallback: gerar frames em intervalos fixos
        return await _generateFramesWithFixedInterval(
          videoPath: videoPath,
          frameCount: frameCount,
          tempDir: tempDir,
        );
      }
      
      print('✅ THUMBNAIL_GEN: Duração do vídeo: ${videoDuration.inSeconds}s');
      
      // Calcular intervalo entre frames
      final intervalMs = videoDuration.inMilliseconds / frameCount;
      
      for (int i = 0; i < frameCount; i++) {
        // Calcular timestamp para este frame
        final timeMs = (i * intervalMs).toInt();
        
        print('🎬 THUMBNAIL_GEN: Gerando frame $i em ${timeMs}ms');
        
        try {
          final thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: '${tempDir.path}/frame_$i.jpg',
            imageFormat: ImageFormat.JPEG,
            maxWidth: 720, // Otimizado para performance
            quality: 85,
            timeMs: timeMs,
          );
          
          if (thumbnailPath != null) {
            final file = File(thumbnailPath);
            if (await file.exists()) {
              frames.add(file);
              print('✅ THUMBNAIL_GEN: Frame $i gerado (${await file.length()} bytes)');
            }
          }
        } catch (e) {
          print('⚠️ THUMBNAIL_GEN: Erro ao gerar frame $i: $e');
          // Continuar tentando gerar outros frames
        }
      }
      
      print('✅ THUMBNAIL_GEN: ${frames.length}/$frameCount frames gerados com sucesso');
      
      // Se não conseguiu gerar nenhum frame, tentar fallback
      if (frames.isEmpty) {
        print('⚠️ THUMBNAIL_GEN: Nenhum frame gerado, tentando fallback');
        return await _generateFramesWithFixedInterval(
          videoPath: videoPath,
          frameCount: frameCount,
          tempDir: tempDir,
        );
      }
      
      return frames;
      
    } catch (e) {
      print('❌ THUMBNAIL_GEN: Erro geral: $e');
      
      // Tentar fallback em caso de erro
      try {
        return await _generateFramesWithFixedInterval(
          videoPath: videoPath,
          frameCount: frameCount,
          tempDir: tempDir,
        );
      } catch (fallbackError) {
        print('❌ THUMBNAIL_GEN: Fallback também falhou: $fallbackError');
        return [];
      }
    }
  }
  
  /// Gera frames com intervalo fixo (fallback quando não consegue obter duração)
  static Future<List<File>> _generateFramesWithFixedInterval({
    required String videoPath,
    required int frameCount,
    required Directory tempDir,
  }) async {
    print('🔄 THUMBNAIL_GEN: Usando método de intervalo fixo');
    
    final List<File> frames = [];
    
    // Gerar frames a cada 2 segundos (ou menos se frameCount for maior)
    final intervalSeconds = 2;
    
    for (int i = 0; i < frameCount; i++) {
      final timeMs = i * intervalSeconds * 1000;
      
      try {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: '${tempDir.path}/frame_fixed_$i.jpg',
          imageFormat: ImageFormat.JPEG,
          maxWidth: 720,
          quality: 85,
          timeMs: timeMs,
        );
        
        if (thumbnailPath != null) {
          final file = File(thumbnailPath);
          if (await file.exists()) {
            frames.add(file);
          }
        }
      } catch (e) {
        print('⚠️ THUMBNAIL_GEN: Erro no frame $i (intervalo fixo): $e');
        // Se falhar, parar de tentar (provavelmente passou do fim do vídeo)
        break;
      }
    }
    
    print('✅ THUMBNAIL_GEN: ${frames.length} frames gerados (intervalo fixo)');
    return frames;
  }
  
  /// Obtém duração do vídeo usando VideoPlayerController
  static Future<Duration?> _getVideoDuration(String videoPath) async {
    VideoPlayerController? controller;
    
    try {
      controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      
      final duration = controller.value.duration;
      print('✅ THUMBNAIL_GEN: Duração obtida: ${duration.inSeconds}s');
      
      return duration;
      
    } catch (e) {
      print('⚠️ THUMBNAIL_GEN: Erro ao obter duração: $e');
      return null;
    } finally {
      controller?.dispose();
    }
  }
  
  /// Gera thumbnail do primeiro frame (padrão)
  /// 
  /// Usado quando usuário não escolhe nenhum frame manualmente
  static Future<File?> generateDefaultThumbnail(String videoPath) async {
    print('🎬 THUMBNAIL_GEN: Gerando thumbnail padrão (primeiro frame)');
    
    final tempDir = await getTemporaryDirectory();
    
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: '${tempDir.path}/default_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 85,
        timeMs: 0, // Primeiro frame
      );
      
      if (thumbnailPath != null) {
        final file = File(thumbnailPath);
        if (await file.exists()) {
          print('✅ THUMBNAIL_GEN: Thumbnail padrão gerado (${await file.length()} bytes)');
          return file;
        }
      }
      
      print('⚠️ THUMBNAIL_GEN: Thumbnail padrão retornou null');
      return null;
      
    } catch (e) {
      print('❌ THUMBNAIL_GEN: Erro ao gerar thumbnail padrão: $e');
      return null;
    }
  }
  
  /// Gera thumbnail de bytes de vídeo (para Web)
  /// 
  /// [videoBytes] - Bytes do vídeo
  /// [timeMs] - Timestamp em milissegundos (padrão: 0 = primeiro frame)
  /// 
  /// Retorna Uint8List com os bytes da thumbnail
  static Future<Uint8List?> generateThumbnailFromBytes({
    required Uint8List videoBytes,
    int timeMs = 0,
  }) async {
    print('🎬 THUMBNAIL_GEN WEB: Gerando thumbnail de bytes');
    
    try {
      // Salvar bytes temporariamente
      final tempDir = await getTemporaryDirectory();
      final tempVideoPath = '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final tempVideoFile = File(tempVideoPath);
      await tempVideoFile.writeAsBytes(videoBytes);
      
      print('✅ THUMBNAIL_GEN WEB: Vídeo temporário salvo: $tempVideoPath');
      
      // Gerar thumbnail
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: tempVideoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 85,
        timeMs: timeMs,
      );
      
      // Limpar arquivo temporário
      try {
        await tempVideoFile.delete();
      } catch (e) {
        print('⚠️ THUMBNAIL_GEN WEB: Erro ao deletar arquivo temporário: $e');
      }
      
      if (thumbnailData != null) {
        print('✅ THUMBNAIL_GEN WEB: Thumbnail gerado (${thumbnailData.length} bytes)');
        return thumbnailData;
      }
      
      print('⚠️ THUMBNAIL_GEN WEB: Thumbnail retornou null');
      return null;
      
    } catch (e) {
      print('❌ THUMBNAIL_GEN WEB: Erro: $e');
      return null;
    }
  }
}
