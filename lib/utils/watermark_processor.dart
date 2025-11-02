import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class WatermarkProcessor {
  /// Processa vídeo - VERSÃO SEM FFMPEG (retorna null)
  static Future<String?> processVideoWithWatermark({
    required String inputVideoPath,
    required double videoDuration,
    Function(double progress, String status)? onProgress,
  }) async {
    print('⚠️ FFMPEG não disponível - vídeos não podem ser processados');
    onProgress?.call(0.0, 'Vídeos não suportam marca d\'água');
    return null;
  }
  
  /// Processa imagem com marca d'água - VERSÃO DEFINITIVA
  /// Usa tamanho FIXO para logo baseado no tamanho da imagem
  static Future<String?> processImageWithWatermark({
    required String inputImagePath,
    Function(double progress, String status)? onProgress,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🎨 PROCESSAMENTO DE MARCA D\'ÁGUA - INÍCIO');
      print('═══════════════════════════════════════════════════════');
      
      onProgress?.call(0.1, 'Carregando imagem...');
      
      // 1. Carregar imagem original
      final originalBytes = await File(inputImagePath).readAsBytes();
      final original = img.decodeImage(originalBytes);
      
      if (original == null) {
        print('❌ ERRO: Não foi possível decodificar a imagem');
        return null;
      }
      
      print('📸 IMAGEM ORIGINAL:');
      print('   • Dimensões: ${original.width}x${original.height} pixels');
      print('   • Tamanho arquivo: ${(originalBytes.length / 1024).toStringAsFixed(2)} KB');
      
      onProgress?.call(0.3, 'Carregando logo...');
      
      // 2. Carregar logo
      final logoData = await rootBundle.load('lib/assets/img/logo_leao.png');
      final logoBytes = logoData.buffer.asUint8List();
      final logo = img.decodeImage(logoBytes);
      
      if (logo == null) {
        print('❌ ERRO: Não foi possível carregar a logo');
        return null;
      }
      
      print('🦁 LOGO ORIGINAL:');
      print('   • Dimensões: ${logo.width}x${logo.height} pixels');
      print('   • Tamanho arquivo: ${(logoBytes.length / 1024).toStringAsFixed(2)} KB');
      
      onProgress?.call(0.5, 'Calculando tamanho ideal...');
      
      // 3. CALCULAR TAMANHO IDEAL DA LOGO (TAMANHO FIXO POR FAIXA)
      int logoTargetWidth;
      
      if (original.width < 600) {
        // Imagens muito pequenas (ex: thumbnails)
        logoTargetWidth = 100;
        print('📏 FAIXA: Imagem MUITO PEQUENA');
      } else if (original.width < 800) {
        // Imagens pequenas (ex: 640x480)
        logoTargetWidth = 140;
        print('📏 FAIXA: Imagem PEQUENA');
      } else if (original.width < 1000) {
        // Imagens médias (ex: 800x600)
        logoTargetWidth = 180;
        print('📏 FAIXA: Imagem MÉDIA');
      } else if (original.width < 1400) {
        // Imagens grandes (ex: 1080x1920)
        logoTargetWidth = 220;
        print('📏 FAIXA: Imagem GRANDE');
      } else {
        // Imagens muito grandes (ex: 4K)
        logoTargetWidth = 280;
        print('📏 FAIXA: Imagem MUITO GRANDE');
      }
      
      // GARANTIR que logo não fique maior que 25% da largura da imagem
      final maxLogoWidth = (original.width * 0.25).toInt();
      logoTargetWidth = min(logoTargetWidth, maxLogoWidth);
      
      print('🎯 TAMANHO ALVO DA LOGO: ${logoTargetWidth}px');
      print('   • Razão de redução: ${(logo.width / logoTargetWidth).toStringAsFixed(2)}x');
      
      onProgress?.call(0.6, 'Redimensionando logo...');
      
      // 4. Redimensionar logo com ALTA QUALIDADE
      final logoResized = img.copyResize(
        logo,
        width: logoTargetWidth,
        interpolation: img.Interpolation.cubic, // Melhor qualidade
      );
      
      print('✅ LOGO REDIMENSIONADA:');
      print('   • Dimensões finais: ${logoResized.width}x${logoResized.height} pixels');
      print('   • Manteve proporção: ${logoResized.width == logoResized.height ? "Sim" : "Não"}');
      
      onProgress?.call(0.7, 'Posicionando marca d\'água...');
      
      // 5. Calcular posição (canto inferior direito)
      final x = original.width - logoResized.width - 30; // 30px de margem
      final y = original.height - logoResized.height - 30; // 30px de margem
      
      print('📍 POSIÇÃO DA LOGO:');
      print('   • X: ${x}px (${((x / original.width) * 100).toStringAsFixed(1)}% da largura)');
      print('   • Y: ${y}px (${((y / original.height) * 100).toStringAsFixed(1)}% da altura)');
      
      onProgress?.call(0.8, 'Aplicando marca d\'água...');
      
      // 6. Aplicar logo com alpha blending
      img.compositeImage(
        original,
        logoResized,
        dstX: x,
        dstY: y,
        blend: img.BlendMode.alpha,
      );
      
      print('✅ Marca d\'água aplicada com sucesso!');
      
      onProgress?.call(0.9, 'Salvando imagem...');
      
      // 7. Salvar com MÁXIMA QUALIDADE (PNG sem compressão)
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(tempDir.path, 'watermarked_$timestamp.png');
      
      print('💾 SALVANDO IMAGEM:');
      print('   • Formato: PNG (sem perda de qualidade)');
      print('   • Compressão: Level 0 (nenhuma)');
      
      // Encode PNG com ZERO compressão (máxima qualidade)
      final encodedImage = img.encodePng(
        original,
        level: 0, // 0 = sem compressão, máxima qualidade
      );
      
      await File(outputPath).writeAsBytes(encodedImage);
      
      final fileSizeKB = (encodedImage.length / 1024).toStringAsFixed(2);
      final fileSizeMB = (encodedImage.length / (1024 * 1024)).toStringAsFixed(2);
      
      print('═══════════════════════════════════════════════════════');
      print('✅ PROCESSAMENTO CONCLUÍDO COM SUCESSO!');
      print('═══════════════════════════════════════════════════════');
      print('📊 RESULTADO FINAL:');
      print('   • Arquivo: ${path.basename(outputPath)}');
      print('   • Tamanho: ${fileSizeKB} KB (${fileSizeMB} MB)');
      print('   • Caminho: $outputPath');
      print('═══════════════════════════════════════════════════════');
      
      onProgress?.call(1.0, 'Imagem processada!');
      
      return outputPath;
      
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ ERRO NO PROCESSAMENTO!');
      print('═══════════════════════════════════════════════════════');
      print('Erro: $e');
      print('Stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════════════');
      onProgress?.call(0.0, 'Erro: $e');
      return null;
    }
  }
}