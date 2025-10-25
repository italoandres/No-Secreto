import 'dart:io';
import 'package:share_handler/share_handler.dart';

class SafeShareHandler {
  static Future<void> initializeSafely({
    Function(File file, String extension)? onImageReceived,
    Function(File file)? onVideoReceived,
    Function(File file, String extension, String fileName)? onFileReceived,
  }) async {
    try {
      final handler = ShareHandlerPlatform.instance;
      SharedMedia? media = await handler.getInitialSharedMedia();

      if (media != null && media.attachments != null) {
        _processAttachments(
          media.attachments!,
          onImageReceived: onImageReceived,
          onVideoReceived: onVideoReceived,
          onFileReceived: onFileReceived,
        );
      }

      handler.sharedMediaStream.listen((SharedMedia media) {
        if (media.attachments != null) {
          _processAttachments(
            media.attachments!,
            onImageReceived: onImageReceived,
            onVideoReceived: onVideoReceived,
            onFileReceived: onFileReceived,
          );
        }
      });

      print('✅ SHARE_HANDLER: Inicializado com sucesso');
    } catch (e) {
      print('❌ SHARE_HANDLER: Erro ao inicializar: $e');
      print(
          'ℹ️ SHARE_HANDLER: Continuando sem funcionalidade de compartilhamento');
      // Não propaga o erro - permite que o app continue funcionando
    }
  }

  static void _processAttachments(
    List<SharedAttachment?> attachments, {
    Function(File file, String extension)? onImageReceived,
    Function(File file)? onVideoReceived,
    Function(File file, String extension, String fileName)? onFileReceived,
  }) {
    for (var element in attachments) {
      if (element != null) {
        try {
          final file = File(element.path);
          final extension = element.path.split('.').last;
          final fileName = element.path.split('/').last;

          switch (element.type) {
            case SharedAttachmentType.image:
              onImageReceived?.call(file, extension);
              break;
            case SharedAttachmentType.video:
              onVideoReceived?.call(file);
              break;
            case SharedAttachmentType.audio:
              onFileReceived?.call(file, extension, fileName);
              break;
            default:
              print(
                  '⚠️ SHARE_HANDLER: Tipo de arquivo não suportado: ${element.type}');
          }
        } catch (e) {
          print('❌ SHARE_HANDLER: Erro ao processar anexo: $e');
        }
      }
    }
  }
}
