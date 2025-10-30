import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_chat/components/video_player.dart';
import 'package:whatsapp_chat/constants.dart';
import 'package:whatsapp_chat/controllers/notification_controller.dart';
import '../locale/language.dart';
import '../repositories/stories_repository.dart';
import '../theme.dart';
import '../token_usuario.dart';
import '../utils/debug_logger.dart';

class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? fileType;
  final String? extension;
  final double? maxSizeMB;

  FileValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fileType,
    this.extension,
    this.maxSizeMB,
  });
}

class StoriesController {
  static String formatarDataParaHorasAtras(DateTime data) {
    DateTime agora = DateTime.now();
    Duration diferenca = agora.difference(data);

    if (diferenca.inMinutes < 1) {
      return 'Há ${diferenca.inMinutes} s';
    } else if (diferenca.inHours < 1) {
      return 'Há ${diferenca.inMinutes} min';
    } else if (diferenca.inHours < 24) {
      return 'Há ${diferenca.inHours} h';
    } else {
      return DateFormat('dd/MM/yyyy').format(data);
    }
  }

  static Future<void> getFile({String? contexto}) async {
    print('DEBUG: Iniciando seleção de arquivo');

    try {
      // Mostrar loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      FilePickerResult? result;

      // Tentar diferentes tipos de seleção
      try {
        result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
          allowCompression: true,
        );
      } catch (e) {
        print('DEBUG: Erro com FileType.custom, tentando FileType.image: $e');
        try {
          result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.image,
          );
        } catch (e2) {
          print('DEBUG: Erro com FileType.image, tentando FileType.any: $e2');
          result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.any,
          );
        }
      }

      // Fechar loading
      Get.back();

      print(
          'DEBUG: Resultado do FilePicker: ${result?.files.length ?? 0} arquivos');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print(
            'DEBUG: Arquivo selecionado: ${file.name}, tamanho: ${file.size} bytes');

        // Verificar se é uma imagem válida
        final extension = file.name.split('.').last.toLowerCase();
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];

        if (!validExtensions.contains(extension)) {
          Get.rawSnackbar(
            message:
                'Formato não suportado! Use: ${validExtensions.join(', ')}',
            backgroundColor: Colors.red,
          );
          return;
        }

        // Verificar tamanho
        final mb = file.size / 1024 / 1024;
        if (mb > 16) {
          Get.rawSnackbar(
            message:
                'Arquivo muito grande! Máximo 16MB (atual: ${mb.toStringAsFixed(1)}MB)',
            backgroundColor: Colors.red,
          );
          return;
        }

        // Obter bytes
        Uint8List? bytes;

        try {
          if (file.bytes != null) {
            bytes = file.bytes;
            print('DEBUG: Usando bytes diretos do arquivo');
          } else if (file.path != null) {
            bytes = await File(file.path!).readAsBytes();
            print('DEBUG: Lendo bytes do caminho: ${file.path}');
          }
        } catch (e) {
          print('DEBUG: Erro ao obter bytes: $e');
          Get.rawSnackbar(
            message: 'Erro ao processar arquivo: $e',
            backgroundColor: Colors.red,
          );
          return;
        }

        if (bytes != null && bytes.isNotEmpty) {
          print('DEBUG: Processando imagem com ${bytes.length} bytes');
          _preImg(bytes, contexto: contexto);
        } else {
          Get.rawSnackbar(
            message: 'Erro: Não foi possível processar a imagem.',
            backgroundColor: Colors.red,
          );
        }
      } else {
        print('DEBUG: Nenhum arquivo selecionado');
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('DEBUG: Erro geral ao selecionar arquivo: $e');
      Get.rawSnackbar(
        message: 'Erro ao acessar galeria: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
    }
  }

  static Future<bool> _isFilePickerAvailable() async {
    try {
      // Teste simples para verificar se FilePicker está funcionando
      return true; // FilePicker geralmente está sempre disponível
    } catch (e) {
      return false;
    }
  }

  static Future<FilePickerResult?> _pickFileWeb() async {
    DebugLogger.debug('StoriesController', 'web_file_picker_start');

    try {
      return await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: [
          'png',
          'jpg',
          'jpeg',
          'gif',
          'bmp',
          'webp',
          'avif',
          'mp4',
          '3gp',
          'avi',
          'mov',
          'webm',
          'mkv'
        ],
        allowCompression: true,
        withData:
            true, // Importante para web - garante que bytes estejam disponíveis
      );
    } catch (e) {
      DebugLogger.error(
          'StoriesController', 'web_file_picker_error', e.toString());
      rethrow;
    }
  }

  static Future<FilePickerResult?> _pickFileMobile() async {
    DebugLogger.debug('StoriesController', 'mobile_file_picker_start');

    try {
      return await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: [
          'png',
          'jpg',
          'jpeg',
          'gif',
          'bmp',
          'webp',
          'avif',
          'mp4',
          '3gp',
          'avi',
          'mov',
          'webm',
          'mkv'
        ],
        allowCompression: true,
      );
    } catch (e) {
      DebugLogger.error(
          'StoriesController', 'mobile_file_picker_error', e.toString());
      rethrow;
    }
  }

  /*
  // Método não utilizado - comentado para evitar erros de compilação
  static Future<void> _processSelectedFile(PlatformFile file, {String? contexto}) async {
    DebugLogger.debug('StoriesController', 'process_file_start', {
      'fileName': file.name,
      'sizeBytes': file.size,
      'hasPath': file.path != null,
      'hasBytes': file.bytes != null
    });
    
    String? fileName = file.name;
    int size = file.size;
    final mb = size / 1024 / 1024;
    
    // Validação básica do arquivo
    if (fileName == null || fileName.isEmpty) {
      throw Exception('Nome do arquivo não disponível');
    }
    
    if (size <= 0) {
      throw Exception('Arquivo vazio ou tamanho inválido');
    }
    
    // Validação de tipo de arquivo
    FileValidationResult typeValidation = _validateFileType(fileName);
    if (!typeValidation.isValid) {
      DebugLogger.error('StoriesController', 'file_type_invalid', typeValidation.errorMessage ?? 'Invalid file type', {
        'fileName': fileName,
        'detectedExtension': typeValidation.extension
      });
      _showWarningSnackbar(typeValidation.errorMessage ?? 'Tipo de arquivo inválido');
      return;
    }
    
    // Validação de tamanho
    FileValidationResult sizeValidation = _validateFileSize(size, TokenUsuario().isAdmin == true);
    if (!sizeValidation.isValid) {
      DebugLogger.error('StoriesController', 'file_size_invalid', sizeValidation.errorMessage ?? 'File size invalid', {
        'fileSizeMB': mb,
        'maxSizeMB': sizeValidation.maxSizeMB,
        'isAdmin': TokenUsuario().isAdmin == true
      });
      _showWarningSnackbar(sizeValidation.errorMessage ?? 'Tamanho de arquivo inválido');
      return;
    }
    
    DebugLogger.debug('StoriesController', 'file_validation_passed', {
      'fileName': fileName,
      'sizeBytes': size,
      'sizeMB': mb.toStringAsFixed(2),
      'fileType': typeValidation.fileType,
      'extension': typeValidation.extension
    });
    
    // Obter bytes do arquivo
    Uint8List? fileBytes = await _getFileBytes(file);
    
    if (fileBytes != null) {
      // Validação adicional dos bytes do arquivo
      FileValidationResult bytesValidation = await _validateFileBytes(fileBytes, typeValidation.extension!);
      if (!bytesValidation.isValid) {
        DebugLogger.error('StoriesController', 'file_bytes_invalid', bytesValidation.errorMessage ?? 'File bytes invalid', {
          'fileName': fileName,
          'bytesLength': fileBytes.length
        });
        _showErrorSnackbar(bytesValidation.errorMessage ?? 'Dados do arquivo inválidos');
        return;
      }
      
      DebugLogger.success('StoriesController', 'file_processing_complete', {
        'fileName': fileName,
        'sizeMB': mb.toStringAsFixed(2),
        'bytesLength': fileBytes.length,
        'fileType': typeValidation.fileType
      });
      
      if (typeValidation.fileType == 'image') {
        _preImg(fileBytes, contexto: contexto);
      } else if (typeValidation.fileType == 'video') {
        // Para vídeos, precisamos do path
        if (file.path != null) {
          _preVideo(file.path!);
        } else {
          throw Exception('Caminho do vídeo não disponível');
        }
      }
    } else {
      throw Exception('Não foi possível obter os dados do arquivo');
    }
  }
  */

  static FileValidationResult _validateFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    // Listas de extensões suportadas
    const imageExtensions = [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'avif'
    ];
    const videoExtensions = ['mp4', '3gp', 'avi', 'mov', 'webm', 'mkv'];

    if (imageExtensions.contains(extension)) {
      return FileValidationResult(
          isValid: true, fileType: 'image', extension: extension);
    } else if (videoExtensions.contains(extension)) {
      return FileValidationResult(
          isValid: true, fileType: 'video', extension: extension);
    } else {
      return FileValidationResult(
          isValid: false,
          errorMessage:
              'Formato não suportado: .$extension\n\nFormatos aceitos:\n• Imagens: ${imageExtensions.join(', ')}\n• Vídeos: ${videoExtensions.join(', ')}',
          extension: extension);
    }
  }

  static FileValidationResult _validateFileSize(int sizeBytes, bool isAdmin) {
    final mb = sizeBytes / 1024 / 1024;
    final maxSizeMB = isAdmin ? 50 : 16;

    if (sizeBytes <= 0) {
      return FileValidationResult(
          isValid: false, errorMessage: 'Arquivo vazio ou corrompido');
    }

    if (mb > maxSizeMB) {
      return FileValidationResult(
          isValid: false,
          errorMessage:
              'Arquivo muito grande!\n\nTamanho atual: ${mb.toStringAsFixed(1)}MB\nTamanho máximo: ${maxSizeMB}MB',
          maxSizeMB: maxSizeMB.toDouble());
    }

    return FileValidationResult(isValid: true, maxSizeMB: maxSizeMB.toDouble());
  }

  static Future<FileValidationResult> _validateFileBytes(
      Uint8List bytes, String extension) async {
    if (bytes.isEmpty) {
      return FileValidationResult(
          isValid: false, errorMessage: 'Arquivo vazio ou corrompido');
    }

    // Validação básica de assinatura de arquivo (magic numbers)
    if (extension == 'png' && !_isPngFile(bytes)) {
      return FileValidationResult(
          isValid: false, errorMessage: 'Arquivo PNG inválido ou corrompido');
    } else if (['jpg', 'jpeg'].contains(extension) && !_isJpegFile(bytes)) {
      return FileValidationResult(
          isValid: false, errorMessage: 'Arquivo JPEG inválido ou corrompido');
    }

    return FileValidationResult(isValid: true);
  }

  static bool _isPngFile(Uint8List bytes) {
    if (bytes.length < 8) return false;
    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  static bool _isJpegFile(Uint8List bytes) {
    if (bytes.length < 3) return false;
    // JPEG signature: FF D8 FF
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  static Future<Uint8List?> _getFileBytes(PlatformFile file) async {
    DebugLogger.debug('StoriesController', 'get_file_bytes_start', {
      'hasBytes': file.bytes != null,
      'hasPath': file.path != null,
      'platform': GetPlatform.isWeb ? 'web' : 'mobile'
    });

    // Priorizar bytes se disponíveis (web)
    if (file.bytes != null) {
      DebugLogger.success('StoriesController', 'using_file_bytes');
      return file.bytes;
    }

    // Fallback para path (mobile)
    if (file.path != null) {
      try {
        DebugLogger.debug(
            'StoriesController', 'reading_file_from_path', {'path': file.path});
        File fileFromPath = File(file.path!);
        Uint8List bytes = await fileFromPath.readAsBytes();
        DebugLogger.success('StoriesController', 'file_read_from_path',
            {'bytesLength': bytes.length});
        return bytes;
      } catch (e) {
        DebugLogger.error('StoriesController', 'file_read_error', e.toString(),
            {'path': file.path});
      }
    }

    DebugLogger.error('StoriesController', 'no_file_data_available',
        'Neither bytes nor path available for file processing');
    return null;
  }

  static String _getUserFriendlyErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'Permissão negada para acessar arquivos. Verifique as permissões do app.';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    } else if (errorStr.contains('timeout')) {
      return 'Operação demorou muito. Tente novamente.';
    } else if (errorStr.contains('storage') || errorStr.contains('space')) {
      return 'Espaço insuficiente no dispositivo.';
    } else if (errorStr.contains('format') || errorStr.contains('type')) {
      return 'Formato de arquivo não suportado. Use PNG, JPG ou JPEG.';
    } else if (errorStr.contains('firebase')) {
      return 'Erro no servidor. Tente novamente em alguns minutos.';
    } else if (errorStr.contains('auth')) {
      return 'Erro de autenticação. Faça login novamente.';
    } else {
      return 'Erro inesperado. Tente novamente.';
    }
  }

  static void _showErrorDialog(String title, String message,
      {List<Widget>? actions}) {
    Get.defaultDialog(
      title: title,
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
      actions: actions ??
          [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Ok'),
            )
          ],
    );
  }

  static void _showSuccessSnackbar(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void _showErrorSnackbar(String message, {Duration? duration}) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.red,
      duration: duration ?? const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void _showWarningSnackbar(String message) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static _preImg(Uint8List img, {String? contexto}) {
    _showStoryForm(
      mediaWidget: Image.memory(img,
          width: ((Get.width - 96) / 3),
          height: ((Get.width - 96) / 3) * (16 / 9),
          fit: BoxFit.cover),
      onSave: (data) async {
        // Testar autenticação antes do upload
        final isAuthenticated = await StoriesRepository.testAuthentication();
        if (!isAuthenticated) {
          throw Exception('Usuário não autenticado. Faça login novamente.');
        }

        return await StoriesRepository.addImg(
          link: data['link'],
          img: img,
          idioma: data['idioma'],
          contexto: data['contexto'],
          titulo: data['titulo'],
          descricao: data['descricao'],
          tituloNotificacaoMasculino: data['tituloNotifMasculino'],
          tituloNotificacaoFeminino: data['tituloNotifFeminino'],
          notificacaoMasculino: data['notifMasculino'],
          notificacaoFeminino: data['notifFeminino'],
          enviarNotificacao: data['enviarNotificacao'],
        );
      },
      title: 'Nova Imagem',
      isVideo: false,
      contextoFornecido: contexto,
    );
  }

  /// Formulário otimizado para criação de stories
  static void _showStoryForm({
    required Widget mediaWidget,
    required Future<bool> Function(Map<String, dynamic>) onSave,
    required String title,
    required bool isVideo,
    String? contextoFornecido,
  }) {
    final linkController = TextEditingController();
    final idioma = ''.obs;

    // Usar contexto fornecido ou detectar automaticamente
    String contextoDetectado =
        contextoFornecido ?? 'principal'; // Usar fornecido ou padrão

    // Se não foi fornecido, tentar detectar através dos argumentos da rota atual
    if (contextoFornecido == null) {
      final arguments = Get.arguments;
      if (arguments != null &&
          arguments is Map &&
          arguments.containsKey('contexto')) {
        contextoDetectado = arguments['contexto'];
      } else {
        // Tentar detectar através da rota atual
        final currentRoute = Get.currentRoute;
        if (currentRoute.contains('sinais_rebeca') ||
            currentRoute.contains('SinaisRebecaView')) {
          contextoDetectado = 'sinais_rebeca';
        } else if (currentRoute.contains('sinais_isaque') ||
            currentRoute.contains('SinaisIsaqueView')) {
          contextoDetectado = 'sinais_isaque';
        } else if (currentRoute.contains('nosso_proposito') ||
            currentRoute.contains('NossoPropositoView')) {
          contextoDetectado = 'nosso_proposito';
        }
      }
    }

    final contexto = contextoDetectado.obs;

    // Novos campos para título e descrição do story
    final tituloStoryController = TextEditingController();
    final descricaoStoryController = TextEditingController();

    // Campos para notificações separadas por sexo
    final tituloNotifMasculinoController = TextEditingController();
    final tituloNotifFemininoController = TextEditingController();
    final notifMasculinoController = TextEditingController();
    final notifFemininoController = TextEditingController();
    final enviarNotificacao = false.obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview da mídia
                    Center(child: mediaWidget),

                    const SizedBox(height: 24),

                    // Seção: Informações do Story
                    const Text(
                      '📱 Informações do Story',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Título do Story
                    TextField(
                      controller: tituloStoryController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Story',
                        hintText: 'Ex: Palavra de hoje, Reflexão...',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 100,
                    ),

                    const SizedBox(height: 16),

                    // Descrição do Story
                    TextField(
                      controller: descricaoStoryController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        hintText: 'Descreva o conteúdo do story...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 16),

                    // Link opcional
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: 'Link (opcional)',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nota sobre contexto
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Escolha onde o story será publicado',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Seção: Configurações
                    const Text(
                      '⚙️ Configurações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Seleção de idioma
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Obx(() => DropdownButton<String>(
                            value: idioma.value.isEmpty ? null : idioma.value,
                            hint: const Text('Selecionar idioma'),
                            underline: const SizedBox(),
                            isExpanded: true,
                            onChanged: (String? value) {
                              idioma.value = value!;
                            },
                            items: AppLanguage.languages()
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Text(AppLanguage.lang('${value}Flag',
                                        idioma: idioma.value)),
                                    const SizedBox(width: 8),
                                    Text(AppLanguage.lang(value,
                                        idioma: idioma.value)),
                                  ],
                                ),
                              );
                            }).toList(),
                          )),
                    ),

                    const SizedBox(height: 16),

                    // Seleção de contexto (RESTAURADO)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Obx(() => DropdownButton<String>(
                            value: contexto.value,
                            hint: const Text('Selecionar contexto'),
                            underline: const SizedBox(),
                            isExpanded: true,
                            onChanged: (String? value) {
                              contexto.value = value!;
                            },
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'principal',
                                child: Row(
                                  children: [
                                    Icon(Icons.chat, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Chat Principal'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'sinais_isaque',
                                child: Row(
                                  children: [
                                    Text('🤵', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 8),
                                    Text('Sinais de Meu Isaque'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'sinais_rebeca',
                                child: Row(
                                  children: [
                                    Text('👰‍♀️',
                                        style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 8),
                                    Text('Sinais de Minha Rebeca'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'nosso_proposito',
                                child: Row(
                                  children: [
                                    Text('💕', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 8),
                                    Text('Nosso Propósito'),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    ),

                    const SizedBox(height: 24),

                    // Seção: Notificações
                    Row(
                      children: [
                        const Text(
                          '🔔 Notificações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const Spacer(),
                        Obx(() => Switch(
                              value: enviarNotificacao.value,
                              onChanged: (value) =>
                                  enviarNotificacao.value = value,
                            )),
                      ],
                    ),

                    Obx(() => enviarNotificacao.value
                        ? Column(
                            children: [
                              const SizedBox(height: 12),

                              // Notificação para homens
                              const Text(
                                '👨 Notificação para Homens',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                controller: tituloNotifMasculinoController,
                                decoration: const InputDecoration(
                                  labelText: 'Título da notificação (homens)',
                                  hintText:
                                      'Ex: Nova palavra para você, irmão!',
                                  prefixIcon: Icon(Icons.title),
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 50,
                              ),

                              const SizedBox(height: 8),

                              TextField(
                                controller: notifMasculinoController,
                                decoration: const InputDecoration(
                                  labelText: 'Mensagem da notificação (homens)',
                                  hintText: 'Confira esta palavra especial...',
                                  prefixIcon: Icon(Icons.message),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                                maxLength: 150,
                              ),

                              const SizedBox(height: 16),

                              // Notificação para mulheres
                              const Text(
                                '👩 Notificação para Mulheres',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                controller: tituloNotifFemininoController,
                                decoration: const InputDecoration(
                                  labelText: 'Título da notificação (mulheres)',
                                  hintText: 'Ex: Nova palavra para você, irmã!',
                                  prefixIcon: Icon(Icons.title),
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 50,
                              ),

                              const SizedBox(height: 8),

                              TextField(
                                controller: notifFemininoController,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Mensagem da notificação (mulheres)',
                                  hintText: 'Confira esta palavra especial...',
                                  prefixIcon: Icon(Icons.message),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                                maxLength: 150,
                              ),
                            ],
                          )
                        : const SizedBox()),

                    const SizedBox(height: 32),

                    // Botão de salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Validações
                            if (enviarNotificacao.value) {
                              if (tituloNotifMasculinoController.text.isEmpty ||
                                  notifMasculinoController.text.isEmpty ||
                                  tituloNotifFemininoController.text.isEmpty ||
                                  notifFemininoController.text.isEmpty) {
                                Get.rawSnackbar(
                                  message:
                                      'Preencha todos os campos de notificação ou desative as notificações',
                                  backgroundColor: Colors.orange,
                                );
                                return;
                              }
                            }

                            // Preparar dados
                            final data = {
                              'link': linkController.text.trim(),
                              'idioma':
                                  idioma.value.isEmpty ? null : idioma.value,
                              'contexto': contexto.value,
                              'titulo': tituloStoryController.text.trim(),
                              'descricao': descricaoStoryController.text.trim(),
                              'tituloNotifMasculino':
                                  tituloNotifMasculinoController.text.trim(),
                              'tituloNotifFeminino':
                                  tituloNotifFemininoController.text.trim(),
                              'notifMasculino':
                                  notifMasculinoController.text.trim(),
                              'notifFeminino':
                                  notifFemininoController.text.trim(),
                              'enviarNotificacao': enviarNotificacao.value,
                            };

                            // Salvar story
                            bool resultado = await onSave(data);

                            if (resultado) {
                              // Enviar notificações se habilitado
                              if (enviarNotificacao.value) {
                                await _sendGenderSpecificNotifications(data);
                              }

                              Get.rawSnackbar(
                                message: 'Story salvo com sucesso!',
                                backgroundColor: Colors.green,
                              );
                              Get.back();
                            }
                          } catch (e) {
                            Get.rawSnackbar(
                              message: 'Erro ao salvar story: $e',
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Publicar Story',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
    );
  }

  /// Envia notificações específicas por gênero
  static Future<void> _sendGenderSpecificNotifications(
      Map<String, dynamic> data) async {
    try {
      // Notificação para homens
      if (data['notifMasculino'].isNotEmpty) {
        await NotificationController.sendNotificationToTopic(
          titulo: data['tituloNotifMasculino'].isNotEmpty
              ? data['tituloNotifMasculino']
              : Constants.appName,
          msg: data['notifMasculino'],
          abrirStories: true,
          topico: 'masculino', // Tópico específico para homens
        );
      }

      // Notificação para mulheres
      if (data['notifFeminino'].isNotEmpty) {
        await NotificationController.sendNotificationToTopic(
          titulo: data['tituloNotifFeminino'].isNotEmpty
              ? data['tituloNotifFeminino']
              : Constants.appName,
          msg: data['notifFeminino'],
          abrirStories: true,
          topico: 'feminino', // Tópico específico para mulheres
        );
      }
    } catch (e) {
      print('DEBUG: Erro ao enviar notificações: $e');
    }
  }

  static _preVideo(String videoPath) {
    _showStoryForm(
      mediaWidget: VideoPlayer(
          url: videoPath,
          isLoacal: true,
          width: ((Get.width - 96) / 3),
          height: ((Get.width - 96) / 3) * (16 / 9)),
      onSave: (data) async {
        return await StoriesRepository.addVideo(
          link: data['link'],
          video: File(videoPath),
          idioma: data['idioma'],
          contexto: data['contexto'],
          titulo: data['titulo'],
          descricao: data['descricao'],
          tituloNotificacaoMasculino: data['tituloNotifMasculino'],
          tituloNotificacaoFeminino: data['tituloNotifFeminino'],
          notificacaoMasculino: data['notifMasculino'],
          notificacaoFeminino: data['notifFeminino'],
          enviarNotificacao: data['enviarNotificacao'],
        );
      },
      title: 'Novo Vídeo',
      isVideo: true,
    );
  }
}
