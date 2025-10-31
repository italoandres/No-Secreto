import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart'; // Removido temporariamente
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/storie_visto_model.dart';
import '/locale/language.dart';
import '/models/storie_file_model.dart';
import '/models/usuario_model.dart';
import '../utils/debug_logger.dart';
import '../token_usuario.dart';
import '../controllers/stories_gallery_controller.dart';
import '../services/stories_history_service.dart';
import '../utils/context_utils.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class StoriesRepository {
  static final StoriesHistoryService _historyService = StoriesHistoryService();

  // 🔧 NOVO: Método helper para obter nome da coleção baseado no contexto
  static String getCollectionNameFromContext(String contexto) {
    switch (contexto) {
      case 'sinais_isaque':
        return 'stories_sinais_isaque';
      case 'sinais_rebeca':
        return 'stories_sinais_rebeca';
      case 'nosso_proposito':
        return 'stories_nosso_proposito';
      case 'principal':
      default:
        return 'stories_files';
    }
  }

  // Método para testar autenticação
  static Future<bool> testAuthentication() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      safePrint('🔍 TESTE AUTH: Usuário atual: ${user?.email ?? "null"}');

      if (user == null) {
        safePrint('❌ TESTE AUTH: Usuário não autenticado');
        return false;
      }

      // Testar se o token ainda é válido
      final token = await user.getIdToken(true);
      safePrint('✅ TESTE AUTH: Token obtido com sucesso');

      // Testar acesso ao Firestore
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      safePrint('✅ TESTE AUTH: Acesso ao Firestore OK');

      return true;
    } catch (e) {
      safePrint('❌ TESTE AUTH: Erro: $e');
      return false;
    }
  }

  static void _showProgressDialog(String message) {
    Get.defaultDialog(
        title: 'Salvando Story',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        barrierDismissible: false);
  }

  // Método helper para definir público-alvo baseado no contexto
  static String? _getPublicoAlvoByContext(String? contexto) {
    switch (contexto) {
      case 'sinais_isaque':
        return UserSexo.feminino.name;
      case 'sinais_rebeca':
        return UserSexo.masculino.name;
      default:
        return null; // Visível para todos
    }
  }

  // Método helper para buscar stories por contexto
  static Stream<List<StorieFileModel>> _getStoriesByContext(String contexto) {
    switch (contexto) {
      case 'sinais_isaque':
        return getAllSinaisIsaque();
      case 'sinais_rebeca':
        return getAllSinaisRebeca();
      default:
        return getAll();
    }
  }

  static void _updateProgressDialog(String message) {
    // Fechar dialog atual e abrir novo com mensagem atualizada
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    _showProgressDialog(message);
  }

  static Future<bool> addImg({
    required String link,
    required Uint8List img,
    required String? idioma,
    String? contexto,
    String? titulo,
    String? descricao,
    String? tituloNotificacaoMasculino,
    String? tituloNotificacaoFeminino,
    String? notificacaoMasculino,
    String? notificacaoFeminino,
    bool? enviarNotificacao,
  }) async {
    print('DEBUG REPO: Iniciando addImg');
    print('DEBUG REPO: Contexto: $contexto');
    print('DEBUG REPO: Tamanho da imagem: ${img.length} bytes');

    Get.defaultDialog(
        title: 'Salvando Story',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fazendo upload da imagem...'),
          ],
        ),
        barrierDismissible: false);

    try {
      // Validar dados da imagem antes do upload
      if (img.isEmpty) {
        throw Exception('Dados da imagem estão vazios');
      }

      // Upload da imagem
      print('DEBUG REPO: Fazendo upload da imagem');
      String fileUrl = await _uploadImg(img);
      print('DEBUG REPO: Upload concluído. URL: $fileUrl');

      // Verificar se a URL foi obtida corretamente
      if (fileUrl.isEmpty || !fileUrl.startsWith('https://')) {
        throw Exception('URL de upload inválida: $fileUrl');
      }

      // Preparar dados do documento - usar contexto fornecido ou principal como padrão
      final contextoFinal = contexto ?? 'principal';
      var body = {
        'link': link,
        'fileUrl': fileUrl,
        'videoDuration': 10, // 10 segundos para imagens
        'dataCadastro': Timestamp.now(), // Usar Timestamp em vez de DateTime
        'fileType': StorieFileType.img.name,
        'contexto': contextoFinal,
        'publicoAlvo': null, // Visível para todos no contexto principal
        // Novos campos
        'titulo': titulo,
        'descricao': descricao,
        'tituloNotificacaoMasculino': tituloNotificacaoMasculino,
        'tituloNotificacaoFeminino': tituloNotificacaoFeminino,
        'notificacaoMasculino': notificacaoMasculino,
        'notificacaoFeminino': notificacaoFeminino,
        'enviarNotificacao': enviarNotificacao ?? false,
      };

      if (idioma != null && idioma.isNotEmpty) {
        body['idioma'] = idioma;
      }

      print('DEBUG REPO: Dados preparados: $body');

      // Selecionar coleção baseada no contexto
      String colecao;
      switch (contextoFinal) {
        case 'sinais_isaque':
          colecao = 'stories_sinais_isaque';
          break;
        case 'sinais_rebeca':
          colecao = 'stories_sinais_rebeca';
          break;
        case 'nosso_proposito':
          colecao = 'stories_nosso_proposito';
          break;
        default:
          colecao = 'stories_files';
          break;
      }
      print(
          'DEBUG REPO: Salvando na coleção: $colecao (contexto: $contextoFinal)');

      DocumentReference docRef =
          await FirebaseFirestore.instance.collection(colecao).add(body);
      print('DEBUG REPO: Documento salvo com ID: ${docRef.id}');

      // Verificar se foi realmente salvo
      DocumentSnapshot verifyDoc = await docRef.get();
      if (!verifyDoc.exists) {
        throw Exception('Documento não foi criado corretamente');
      }
      print('DEBUG REPO: Verificação passou - documento existe');

      Get.back();
      print('DEBUG REPO: addImg concluído com sucesso');

      return true;
    } catch (e, stackTrace) {
      print('DEBUG REPO: Erro em addImg: $e');
      print('DEBUG REPO: Stack trace: $stackTrace');
      Get.back();

      // Mostrar erro amigável para o usuário
      String errorMessage = _getFirebaseErrorMessage(e.toString());
      Get.rawSnackbar(
        title: 'Erro ao salvar story',
        message: errorMessage,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );

      rethrow;
    }
  }

  /// Converte erros do Firebase em mensagens amigáveis
  static String _getFirebaseErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('unauthorized') ||
        errorLower.contains('permission')) {
      return '❌ Sem permissão para salvar. Verifique se você está logado.';
    } else if (errorLower.contains('network') ||
        errorLower.contains('connection')) {
      return '❌ Erro de conexão. Verifique sua internet e tente novamente.';
    } else if (errorLower.contains('timeout')) {
      return '❌ Upload demorou muito. Tente novamente com uma conexão melhor.';
    } else if (errorLower.contains('quota') ||
        errorLower.contains('storage') ||
        errorLower.contains('limite')) {
      return '❌ Limite de armazenamento atingido. Contate o administrador.';
    } else if (errorLower.contains('invalid') ||
        errorLower.contains('format')) {
      return '❌ Formato de arquivo inválido. Use PNG, JPG ou JPEG.';
    } else if (errorLower.contains('too large') ||
        errorLower.contains('size') ||
        errorLower.contains('grande')) {
      return '❌ Arquivo muito grande. Reduza o tamanho e tente novamente.';
    } else if (errorLower.contains('firebase') ||
        errorLower.contains('unknown')) {
      return '❌ Erro no servidor. Tente novamente em alguns minutos.';
    } else if (errorLower.contains('retry') ||
        errorLower.contains('tentativas')) {
      return '❌ Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    } else {
      return '❌ Erro inesperado ao salvar story. Tente novamente.';
    }
  }

  static void _validateAddImgParameters(
      String link, Uint8List img, String? idioma, String? contexto) {
    if (img.isEmpty) {
      throw ArgumentError('Image data cannot be empty');
    }

    if (contexto != null &&
        !['principal', 'sinais_isaque'].contains(contexto)) {
      throw ArgumentError('Invalid context: $contexto');
    }

    if (idioma != null && idioma.trim().isEmpty) {
      throw ArgumentError('Language cannot be empty string');
    }
  }

  static Map<String, dynamic> _prepareDocumentData(
      String link, String fileUrl, String? idioma, String contextoFinal) {
    var body = {
      'link': link,
      'fileUrl': fileUrl,
      'videoDuration': '0',
      'dataCadastro': Timestamp.now(), // Usar Timestamp em vez de DateTime
      'fileType': StorieFileType.img.name,
      'contexto': contextoFinal,
      'publicoAlvo': _getPublicoAlvoByContext(contextoFinal),
    };

    if (idioma != null && idioma.isNotEmpty) {
      body['idioma'] = idioma;
    }

    return body;
  }

  static Future<String> _uploadImgWithRetry(Uint8List img,
      {int maxRetries = 3}) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        attempts++;
        DebugLogger.debug('StoriesRepository', 'upload_attempt',
            {'attempt': attempts, 'maxRetries': maxRetries});

        return await _uploadImg(img);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        DebugLogger.error('StoriesRepository', 'upload_attempt_failed',
            e.toString(), {'attempt': attempts, 'maxRetries': maxRetries});

        if (attempts < maxRetries) {
          // Aguardar antes de tentar novamente (exponential backoff)
          int delaySeconds = attempts * 2;
          DebugLogger.debug('StoriesRepository', 'retry_delay',
              {'delaySeconds': delaySeconds});
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }

    throw lastException ??
        Exception('Upload failed after $maxRetries attempts');
  }

  static Future<DocumentReference> _saveDocumentWithRetry(
      String collection, Map<String, dynamic> data,
      {int maxRetries = 3}) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        attempts++;
        DebugLogger.debug('StoriesRepository', 'firestore_save_attempt', {
          'attempt': attempts,
          'maxRetries': maxRetries,
          'collection': collection
        });

        return await FirebaseFirestore.instance
            .collection(collection)
            .add(data);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        DebugLogger.error('StoriesRepository', 'firestore_save_attempt_failed',
            e.toString(), {
          'attempt': attempts,
          'maxRetries': maxRetries,
          'collection': collection
        });

        if (attempts < maxRetries) {
          // Aguardar antes de tentar novamente
          int delaySeconds = attempts;
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }

    throw lastException ??
        Exception('Firestore save failed after $maxRetries attempts');
  }

  static Future<void> _verifyDocumentCreation(DocumentReference docRef) async {
    try {
      DocumentSnapshot verifyDoc = await docRef.get();
      if (!verifyDoc.exists) {
        throw Exception(
            'Document verification failed: document does not exist');
      }

      // Verificar se os dados estão corretos
      Map<String, dynamic>? data = verifyDoc.data() as Map<String, dynamic>?;
      if (data == null || data.isEmpty) {
        throw Exception('Document verification failed: document has no data');
      }

      // Verificar campos obrigatórios
      List<String> requiredFields = [
        'fileUrl',
        'dataCadastro',
        'fileType',
        'contexto'
      ];
      for (String field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          throw Exception(
              'Document verification failed: missing required field $field');
        }
      }
    } catch (e) {
      DebugLogger.error('StoriesRepository', 'document_verification_error',
          e.toString(), {'documentId': docRef.id});
      rethrow;
    }
  }

  static Future<void> _rollbackOnError(
      String? uploadedFileUrl, DocumentReference? createdDoc) async {
    DebugLogger.debug('StoriesRepository', 'rollback_start', {
      'hasUploadedFile': uploadedFileUrl != null,
      'hasCreatedDoc': createdDoc != null
    });

    try {
      // Tentar deletar documento criado
      if (createdDoc != null) {
        await createdDoc.delete();
        DebugLogger.debug('StoriesRepository', 'rollback_document_deleted',
            {'documentId': createdDoc.id});
      }

      // Tentar deletar arquivo do Storage
      if (uploadedFileUrl != null) {
        try {
          Reference ref = FirebaseStorage.instance.refFromURL(uploadedFileUrl);
          await ref.delete();
          DebugLogger.debug('StoriesRepository', 'rollback_file_deleted',
              {'fileUrl': uploadedFileUrl});
        } catch (e) {
          DebugLogger.error(
              'StoriesRepository', 'rollback_file_delete_failed', e.toString());
          // Não relançar erro de rollback de arquivo
        }
      }
    } catch (e) {
      DebugLogger.error('StoriesRepository', 'rollback_error', e.toString());
      // Não relançar erros de rollback
    }
  }

  static Future<bool> addVideo({
    required String link,
    required File video,
    required String? idioma,
    String? contexto,
    String? titulo,
    String? descricao,
    String? tituloNotificacaoMasculino,
    String? tituloNotificacaoFeminino,
    String? notificacaoMasculino,
    String? notificacaoFeminino,
    bool? enviarNotificacao,
  }) async {
    Get.defaultDialog(
        title: AppLanguage.lang('validando'),
        content: const CircularProgressIndicator(),
        barrierDismissible: false);

    // Validação do vídeo usando video_thumbnail
    print('🎬 VIDEO: Iniciando validação do vídeo');
    print('🎬 VIDEO: Caminho: ${video.path}');
    print('🎬 VIDEO: Arquivo existe: ${await video.exists()}');
    
    // Verificar se o arquivo existe
    if (!await video.exists()) {
      Get.back();
      Get.rawSnackbar(
        message: 'Erro: Arquivo de vídeo não encontrado no caminho: ${video.path}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
    
    try {
      print('🎬 VIDEO: Gerando thumbnail de validação (128px)...');
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 25,
      );

      if (thumbnail == null) {
        Get.back();
        print('❌ VIDEO: Thumbnail de validação retornou null');
        Get.rawSnackbar(
          message: 'Erro ao gerar thumbnail do vídeo. Formato pode não ser suportado.',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
        return false;
      }
      
      print('✅ VIDEO: Thumbnail de validação gerado com sucesso (${thumbnail.length} bytes)');
    } catch (e) {
      Get.back();
      print('❌ VIDEO: Erro ao gerar thumbnail de validação: $e');
      Get.rawSnackbar(
        message: 'Erro ao validar vídeo: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return false;
    }

    print('🎬 VIDEO: Gerando thumbnail final (480px)...');
    Uint8List? thumbnail = await VideoThumbnail.thumbnailData(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 480,
      quality: 25,
    );

    if (thumbnail == null) {
      Get.back();
      print('❌ VIDEO: Thumbnail final retornou null');
      Get.rawSnackbar(
        message: 'Erro ao gerar thumbnail final do vídeo',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
    
    print('✅ VIDEO: Thumbnail final gerado com sucesso (${thumbnail.length} bytes)');

    String thumbnailImg = await _uploadImg(thumbnail);

    String fileUrl = await _uploadVideo(video);

    var body = {
      'link': link,
      'fileUrl': fileUrl,
      'videoThumbnail': thumbnailImg,
      'dataCadastro': Timestamp.now(), // Usar Timestamp em vez de DateTime
      'videoDuration': 0, // Vídeos mantêm duração original (sem limites)
      'fileType': StorieFileType.video.name,
      'contexto': 'principal', // Sempre salvar no contexto principal
      'publicoAlvo': null, // Visível para todos no contexto principal
      // Novos campos
      'titulo': titulo,
      'descricao': descricao,
      'tituloNotificacaoMasculino': tituloNotificacaoMasculino,
      'tituloNotificacaoFeminino': tituloNotificacaoFeminino,
      'notificacaoMasculino': notificacaoMasculino,
      'notificacaoFeminino': notificacaoFeminino,
      'enviarNotificacao': enviarNotificacao ?? false,
    };

    if (idioma != null && idioma.isNotEmpty) {
      body['idioma'] = idioma;
    }

    // Escolhe a coleção baseada no contexto
    String colecao;
    switch (contexto) {
      case 'sinais_isaque':
        colecao = 'stories_sinais_isaque';
        break;
      case 'sinais_rebeca':
        colecao = 'stories_sinais_rebeca';
        break;
      case 'nosso_proposito':
        colecao = 'stories_nosso_proposito';
        break;
      default:
        colecao = 'stories_files';
    }
    try {
      await FirebaseFirestore.instance.collection(colecao).add(body);
      Get.back();
      return true;
    } catch (e) {
      print('DEBUG REPO: Erro ao salvar vídeo no Firestore: $e');
      Get.back();

      // Mostrar erro amigável para o usuário
      String errorMessage = _getFirebaseErrorMessage(e.toString());
      Get.rawSnackbar(
        title: 'Erro ao salvar vídeo',
        message: errorMessage,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  /// Método para upload de vídeo na WEB (usando bytes ao invés de File)
  static Future<bool> addVideoWeb({
    required String link,
    required Uint8List videoBytes,
    required String fileName,
    required String? idioma,
    String? contexto,
    String? titulo,
    String? descricao,
    String? tituloNotificacaoMasculino,
    String? tituloNotificacaoFeminino,
    String? notificacaoMasculino,
    String? notificacaoFeminino,
    bool? enviarNotificacao,
  }) async {
    print('🎬 WEB REPO: Iniciando upload de vídeo web');
    print('🎬 WEB REPO: Tamanho: ${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
    
    Get.defaultDialog(
        title: 'Salvando Vídeo',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fazendo upload do vídeo...'),
          ],
        ),
        barrierDismissible: false);

    try {
      // Para web, não conseguimos gerar thumbnail facilmente
      // Vamos usar uma imagem placeholder ou pular a validação
      print('🎬 WEB REPO: Pulando validação de thumbnail (web)');
      
      // Upload do vídeo direto usando bytes
      print('🎬 WEB REPO: Fazendo upload do vídeo...');
      String fileUrl = await _uploadVideoBytes(videoBytes, fileName);
      print('🎬 WEB REPO: Upload concluído. URL: $fileUrl');

      // Usar uma thumbnail padrão ou null
      String? thumbnailImg;
      
      var body = {
        'link': link,
        'fileUrl': fileUrl,
        'videoThumbnail': thumbnailImg,
        'dataCadastro': Timestamp.now(),
        'videoDuration': 0,
        'fileType': StorieFileType.video.name,
        'contexto': contexto ?? 'principal',
        'publicoAlvo': null,
        'titulo': titulo,
        'descricao': descricao,
        'tituloNotificacaoMasculino': tituloNotificacaoMasculino,
        'tituloNotificacaoFeminino': tituloNotificacaoFeminino,
        'notificacaoMasculino': notificacaoMasculino,
        'notificacaoFeminino': notificacaoFeminino,
        'enviarNotificacao': enviarNotificacao ?? false,
      };

      if (idioma != null && idioma.isNotEmpty) {
        body['idioma'] = idioma;
      }

      // Escolhe a coleção baseada no contexto
      String colecao;
      switch (contexto) {
        case 'sinais_isaque':
          colecao = 'stories_sinais_isaque';
          break;
        case 'sinais_rebeca':
          colecao = 'stories_sinais_rebeca';
          break;
        case 'nosso_proposito':
          colecao = 'stories_nosso_proposito';
          break;
        default:
          colecao = 'stories_files';
      }
      
      print('🎬 WEB REPO: Salvando no Firestore (coleção: $colecao)');
      await FirebaseFirestore.instance.collection(colecao).add(body);
      
      Get.back();
      print('🎬 WEB REPO: Vídeo salvo com sucesso!');
      
      Get.rawSnackbar(
        message: 'Vídeo publicado com sucesso!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
      
      return true;
    } catch (e, stackTrace) {
      print('❌ WEB REPO: Erro ao salvar vídeo: $e');
      print('❌ WEB REPO: Stack trace: $stackTrace');
      Get.back();

      Get.rawSnackbar(
        title: 'Erro ao salvar vídeo',
        message: 'Erro: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  /// Upload de vídeo usando bytes (para web)
  static Future<String> _uploadVideoBytes(Uint8List videoBytes, String fileName) async {
    print('🎬 WEB UPLOAD: Iniciando upload de vídeo com bytes');
    print('🎬 WEB UPLOAD: Tamanho: ${videoBytes.length} bytes');
    print('🎬 WEB UPLOAD: Nome do arquivo: $fileName');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = user.uid;
      final extension = fileName.split('.').last;
      final storagePath = 'stories_files/${userId}_${timestamp}.$extension';

      print('🎬 WEB UPLOAD: Caminho no storage: $storagePath');

      // Criar referência do Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);

      // Configurar metadados
      SettableMetadata metadata = SettableMetadata(
        contentType: 'video/$extension',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': timestamp.toString(),
          'fileType': 'story_video',
          'fileSize': videoBytes.length.toString(),
          'platform': 'web',
        },
      );

      print('🎬 WEB UPLOAD: Iniciando upload...');

      // Fazer upload com monitoramento
      final uploadTask = ref.putData(videoBytes, metadata);

      // Monitorar progresso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('🎬 WEB UPLOAD: Progresso: ${progress.toStringAsFixed(1)}%');
      });

      // Aguardar conclusão
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload cancelado por timeout (10 minutos)');
        },
      );

      print('🎬 WEB UPLOAD: Upload concluído. Estado: ${snapshot.state}');

      // Verificar se o upload foi bem-sucedido
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload falhou. Estado: ${snapshot.state}');
      }

      // Obter URL de download
      String downloadUrl = await ref.getDownloadURL();
      print('🎬 WEB UPLOAD: URL de download: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ WEB UPLOAD: Firebase Exception: ${e.code} - ${e.message}');
      throw Exception('Erro no Firebase Storage: ${e.message}');
    } catch (e) {
      print('❌ WEB UPLOAD: Erro: $e');
      rethrow;
    }
  }

  static Stream<List<StorieFileModel>> getAll() {
    const String expectedContext = 'principal';
    const String collectionName = 'stories_files';

    // Validar contexto antes de prosseguir
    if (!ContextValidator.isValidContext(expectedContext)) {
      ContextDebug.logCriticalError(
          'getAll', 'Contexto inválido', expectedContext);
      return Stream.value([]);
    }

    // Validar se a coleção corresponde ao contexto
    if (!ContextValidator.validateContextForCollection(
        expectedContext, collectionName)) {
      ContextDebug.logCriticalError(
          'getAll', 'Coleção não corresponde ao contexto', expectedContext);
      return Stream.value([]);
    }

    ContextDebug.logSummary('getAll', expectedContext,
        {'collection': collectionName, 'operation': 'LOAD_PRINCIPAL_STORIES'});

    // Mover stories expirados para o histórico (executa em background)
    _historyService.moveExpiredStoriesToHistory().catchError((e) {
      print('⚠️ REPO: Erro ao mover stories expirados: $e');
    });

    return ContextDebug.measurePerformance('getAll_query', expectedContext, () {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .where('contexto',
              isEqualTo:
                  expectedContext) // FILTRO EXPLÍCITO POR CONTEXTO PRINCIPAL
          .snapshots();
    }).asyncMap((event) async {
      ContextDebug.logLoad(
          expectedContext, collectionName, event.docs.length, 'getAll');

      // Processar documentos
      final stories = event.docs.map((e) {
        final data = e.data();
        ContextDebug.logSummary('processing_document', expectedContext, {
          'documentId': e.id,
          'documentContext': data['contexto'] ?? 'null'
        });

        StorieFileModel story = StorieFileModel.fromJson(data);
        story.id = e.id;
        return story;
      }).toList();

      // VALIDAÇÃO ADICIONAL: Filtrar stories que não pertencem ao contexto principal
      final validStories =
          StoryContextFilter.filterByContext(stories, expectedContext);

      // Detectar vazamentos de contexto
      final hasLeaks =
          StoryContextFilter.detectContextLeaks(stories, expectedContext);
      if (hasLeaks) {
        ContextDebug.logCriticalError(
            'getAll',
            'VAZAMENTO DE CONTEXTO DETECTADO - Stories de outros contextos na coleção principal',
            expectedContext);
      }

      ContextDebug.logFilter(
          expectedContext, stories.length, validStories.length, 'getAll');

      return validStories;
    });
  }

  // Nova função para buscar stories do contexto "Sinais de Meu Isaque"
  static Stream<List<StorieFileModel>> getAllSinaisIsaque() {
    const String expectedContext = 'sinais_isaque';
    const String collectionName = 'stories_sinais_isaque';

    // Validar contexto antes de prosseguir
    if (!ContextValidator.isValidContext(expectedContext)) {
      ContextDebug.logCriticalError(
          'getAllSinaisIsaque', 'Contexto inválido', expectedContext);
      return Stream.value([]);
    }

    // Validar se a coleção corresponde ao contexto
    if (!ContextValidator.validateContextForCollection(
        expectedContext, collectionName)) {
      ContextDebug.logCriticalError('getAllSinaisIsaque',
          'Coleção não corresponde ao contexto', expectedContext);
      return Stream.value([]);
    }

    ContextDebug.logSummary('getAllSinaisIsaque', expectedContext,
        {'collection': collectionName, 'operation': 'LOAD_STORIES_BY_CONTEXT'});

    // Mover stories expirados para o histórico (executa em background)
    _historyService.moveExpiredStoriesToHistory().catchError((e) {
      print('⚠️ REPO: Erro ao mover stories expirados: $e');
    });

    return ContextDebug.measurePerformance(
        'getAllSinaisIsaque_query', expectedContext, () {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .where('contexto',
              isEqualTo: expectedContext) // FILTRO EXPLÍCITO POR CONTEXTO
          .snapshots();
    }).asyncMap((event) async {
      ContextDebug.logLoad(expectedContext, collectionName, event.docs.length,
          'getAllSinaisIsaque');

      // Processar documentos
      final stories = event.docs.map((e) {
        final data = e.data();
        ContextDebug.logSummary('processing_document', expectedContext, {
          'documentId': e.id,
          'documentContext': data['contexto'] ?? 'null'
        });

        StorieFileModel story = StorieFileModel.fromJson(data);
        story.id = e.id;
        return story;
      }).toList();

      // VALIDAÇÃO ADICIONAL: Filtrar stories que não pertencem ao contexto esperado
      final validStories =
          StoryContextFilter.filterByContext(stories, expectedContext);

      // Detectar vazamentos de contexto
      final hasLeaks =
          StoryContextFilter.detectContextLeaks(stories, expectedContext);
      if (hasLeaks) {
        ContextDebug.logCriticalError('getAllSinaisIsaque',
            'VAZAMENTO DE CONTEXTO DETECTADO', expectedContext);
      }

      ContextDebug.logFilter(expectedContext, stories.length,
          validStories.length, 'getAllSinaisIsaque');

      return validStories;
    });
  }

  // Nova função para buscar stories do contexto "Sinais de Minha Rebeca"
  static Stream<List<StorieFileModel>> getAllSinaisRebeca() {
    const String expectedContext = 'sinais_rebeca';
    const String collectionName = 'stories_sinais_rebeca';

    // Validar contexto antes de prosseguir
    if (!ContextValidator.isValidContext(expectedContext)) {
      ContextDebug.logCriticalError(
          'getAllSinaisRebeca', 'Contexto inválido', expectedContext);
      return Stream.value([]);
    }

    // Validar se a coleção corresponde ao contexto
    if (!ContextValidator.validateContextForCollection(
        expectedContext, collectionName)) {
      ContextDebug.logCriticalError('getAllSinaisRebeca',
          'Coleção não corresponde ao contexto', expectedContext);
      return Stream.value([]);
    }

    ContextDebug.logSummary('getAllSinaisRebeca', expectedContext,
        {'collection': collectionName, 'operation': 'LOAD_STORIES_BY_CONTEXT'});

    // Mover stories expirados para o histórico (executa em background)
    _historyService.moveExpiredStoriesToHistory().catchError((e) {
      print('⚠️ REPO: Erro ao mover stories expirados: $e');
    });

    return ContextDebug.measurePerformance(
        'getAllSinaisRebeca_query', expectedContext, () {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .where('contexto',
              isEqualTo: expectedContext) // FILTRO EXPLÍCITO POR CONTEXTO
          .snapshots();
    }).asyncMap((event) async {
      ContextDebug.logLoad(expectedContext, collectionName, event.docs.length,
          'getAllSinaisRebeca');

      // Processar documentos
      final stories = event.docs.map((e) {
        final data = e.data();
        ContextDebug.logSummary('processing_document', expectedContext, {
          'documentId': e.id,
          'documentContext': data['contexto'] ?? 'null'
        });

        StorieFileModel story = StorieFileModel.fromJson(data);
        story.id = e.id;
        return story;
      }).toList();

      // VALIDAÇÃO ADICIONAL: Filtrar stories que não pertencem ao contexto esperado
      final validStories =
          StoryContextFilter.filterByContext(stories, expectedContext);

      // Detectar vazamentos de contexto
      final hasLeaks =
          StoryContextFilter.detectContextLeaks(stories, expectedContext);
      if (hasLeaks) {
        ContextDebug.logCriticalError('getAllSinaisRebeca',
            'VAZAMENTO DE CONTEXTO DETECTADO', expectedContext);
      }

      ContextDebug.logFilter(expectedContext, stories.length,
          validStories.length, 'getAllSinaisRebeca');

      return validStories;
    });
  }

  // Função para buscar stories por contexto
  static Stream<List<StorieFileModel>> getAllByContext(String contexto) {
    String colecao;
    switch (contexto) {
      case 'sinais_isaque':
        colecao = 'stories_sinais_isaque';
        break;
      case 'sinais_rebeca':
        colecao = 'stories_sinais_rebeca';
        break;
      case 'nosso_proposito':
        colecao = 'stories_nosso_proposito';
        break;
      default:
        colecao = 'stories_files';
    }

    print('DEBUG REPO: ===== CARREGANDO STORIES POR CONTEXTO =====');
    print('DEBUG REPO: Contexto solicitado: "$contexto"');
    print('DEBUG REPO: Coleção selecionada: "$colecao"');

    return FirebaseFirestore.instance
        .collection(colecao)
        .snapshots()
        .map((event) {
      print('DEBUG REPO: ===== RESULTADO DA CONSULTA =====');
      print(
          'DEBUG REPO: Recebidos ${event.docs.length} documentos da coleção $colecao');

      if (event.docs.isEmpty) {
        print(
            'DEBUG REPO: ⚠️  NENHUM DOCUMENTO ENCONTRADO na coleção $colecao');
      }

      return event.docs.map((e) {
        print('DEBUG REPO: 📄 Processando documento ${e.id}');
        print('DEBUG REPO: 📄 Dados: ${e.data()}');
        try {
          StorieFileModel story = StorieFileModel.fromJson(e.data());
          story.id = e.id;
          print('DEBUG REPO: ✅ Story processado com sucesso: ${story.id}');
          return story;
        } catch (error) {
          print('DEBUG REPO: ❌ Erro ao processar documento ${e.id}: $error');
          rethrow;
        }
      }).toList();
    });
  }

  static Stream<List<StorieFileModel>> getAllAntigos() {
    return FirebaseFirestore.instance
        .collection('stories_antigos')
        .snapshots()
        .map((event) => event.docs.map((e) {
              StorieFileModel story = StorieFileModel.fromJson(e.data());
              story.id = e.id;
              return story;
            }).toList());
  }

  static Stream<List<StorieVistoModel>> getStoreVisto() {
    return FirebaseFirestore.instance
        .collection('stores_visto')
        .where('idUser', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .map((event) => event.docs.map((e) {
              StorieVistoModel chat = StorieVistoModel.fromJson(e.data());
              chat.id = e.id;
              return chat;
            }).toList());
  }

  // Novo método para verificar stories vistos por contexto
  static Stream<List<StorieVistoModel>> getStoreVistoByContext(
      String contexto) {
    return FirebaseFirestore.instance
        .collection('stores_visto')
        .where('idUser', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('contexto', isEqualTo: contexto)
        .snapshots()
        .map((event) => event.docs.map((e) {
              StorieVistoModel chat = StorieVistoModel.fromJson(e.data());
              chat.id = e.id;
              return chat;
            }).toList());
  }

  // Método para verificar se todos os stories de um contexto foram vistos
  static Future<bool> allStoriesViewedInContext(
      String contexto, UserSexo? userSexo) async {
    try {
      // Validar e normalizar contexto
      final normalizedContext = ContextValidator.normalizeContext(contexto);
      if (!ContextValidator.validateAndLog(
          contexto, 'allStoriesViewedInContext')) {
        ContextDebug.logCriticalError(
            'allStoriesViewedInContext',
            'Contexto inválido, usando contexto normalizado',
            normalizedContext);
      }

      ContextDebug.logSummary('allStoriesViewedInContext', normalizedContext, {
        'originalContext': contexto,
        'normalizedContext': normalizedContext,
        'userSexo': userSexo?.name,
        'operation': 'CHECK_ALL_STORIES_VIEWED'
      });

      // Buscar todos os stories válidos do contexto NORMALIZADO
      final allStories = await _getStoriesByContext(normalizedContext).first;

      // VALIDAÇÃO ADICIONAL: Filtrar stories que não pertencem ao contexto esperado
      final contextFilteredStories =
          StoryContextFilter.filterByContext(allStories, normalizedContext);

      // Detectar vazamentos de contexto
      final hasLeaks =
          StoryContextFilter.detectContextLeaks(allStories, normalizedContext);
      if (hasLeaks) {
        ContextDebug.logCriticalError(
            'allStoriesViewedInContext',
            'VAZAMENTO DE CONTEXTO DETECTADO ao verificar stories vistos',
            normalizedContext);
      }

      ContextDebug.logFilter(
          normalizedContext,
          allStories.length,
          contextFilteredStories.length,
          'allStoriesViewedInContext_contextFilter');

      // Filtrar stories válidos (24h, idioma e público-alvo)
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      final validStories = contextFilteredStories.where((story) {
        // Verificar se está dentro de 24h
        final storyDate = story.dataCadastro?.toDate();
        if (storyDate == null || storyDate.isBefore(twentyFourHoursAgo)) {
          return false;
        }

        // Verificar idioma
        if (story.idioma != null && story.idioma != TokenUsuario().idioma) {
          return false;
        }

        // Verificar público-alvo
        if (story.publicoAlvo != null && story.publicoAlvo != userSexo) {
          return false;
        }

        // VALIDAÇÃO ADICIONAL: Verificar se o story realmente pertence ao contexto
        if (!StoryContextFilter.validateStoryContext(story, normalizedContext,
            debugEnabled: false)) {
          ContextDebug.logCriticalError(
              'allStoriesViewedInContext',
              'Story ${story.id} não pertence ao contexto $normalizedContext',
              normalizedContext);
          return false;
        }

        return true;
      }).toList();

      ContextDebug.logSummary(
          'allStoriesViewedInContext_validStories', normalizedContext, {
        'totalStories': allStories.length,
        'contextFilteredStories': contextFilteredStories.length,
        'validStories': validStories.length,
        'hasLeaks': hasLeaks
      });

      if (validStories.isEmpty) {
        ContextDebug.logSummary('allStoriesViewedInContext_noValidStories',
            normalizedContext, {'result': 'ALL_VIEWED_NO_STORIES'});
        return true; // Se não há stories válidos, considera como "todos vistos"
      }

      // Buscar stories vistos do contexto NORMALIZADO
      final storiesVistos =
          await getStoreVistoByContext(normalizedContext).first;
      final storiesVistosIds = storiesVistos.map((v) => v.idStore).toSet();

      // Verificar se todos os stories válidos foram vistos
      final allViewed =
          validStories.every((story) => storiesVistosIds.contains(story.id));

      ContextDebug.logSummary(
          'allStoriesViewedInContext_result', normalizedContext, {
        'validStories': validStories.length,
        'viewedStories': storiesVistosIds.length,
        'allViewed': allViewed,
        'unviewedCount': validStories.length - storiesVistosIds.length
      });

      return allViewed;
    } catch (e) {
      ContextDebug.logCriticalError('allStoriesViewedInContext',
          'Erro ao verificar stories vistos: $e', contexto);
      return false;
    }
  }

  /// Método para verificar se há stories não vistos (para o círculo verde)
  static Future<bool> hasUnviewedStories(
      String contexto, UserSexo? userSexo) async {
    try {
      // Validar e normalizar contexto
      final normalizedContext = ContextValidator.normalizeContext(contexto);
      if (!ContextValidator.validateAndLog(contexto, 'hasUnviewedStories')) {
        ContextDebug.logCriticalError(
            'hasUnviewedStories',
            'Contexto inválido, usando contexto normalizado',
            normalizedContext);
      }

      ContextDebug.logSummary('hasUnviewedStories', normalizedContext, {
        'originalContext': contexto,
        'normalizedContext': normalizedContext,
        'userSexo': userSexo?.name,
        'operation': 'CHECK_UNVIEWED_STORIES'
      });

      final allViewed = await allStoriesViewedInContext(
          normalizedContext, userSexo); // USAR CONTEXTO NORMALIZADO
      final hasUnviewed = !allViewed;

      ContextDebug.logSummary('hasUnviewedStories_result', normalizedContext,
          {'allViewed': allViewed, 'hasUnviewed': hasUnviewed});

      return hasUnviewed; // Retorna true se há stories não vistos
    } catch (e) {
      ContextDebug.logCriticalError('hasUnviewedStories',
          'Erro ao verificar stories não vistos: $e', contexto);
      return false;
    }
  }

  static Future<void> addVisto(String id, {String? contexto}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ContextDebug.logCriticalError(
            'addVisto', 'Usuário não autenticado', contexto ?? 'principal');
        return;
      }

      // Validar e normalizar contexto
      final normalizedContext = ContextValidator.normalizeContext(contexto);
      if (!ContextValidator.validateAndLog(contexto, 'addVisto')) {
        ContextDebug.logCriticalError(
            'addVisto',
            'Contexto inválido, usando contexto normalizado',
            normalizedContext);
      }

      // Validar parâmetros
      if (id.isEmpty) {
        ContextDebug.logCriticalError(
            'addVisto', 'Story ID vazio', normalizedContext);
        return;
      }

      ContextDebug.logSummary('addVisto', normalizedContext, {
        'storyId': id,
        'userId': userId,
        'originalContext': contexto,
        'normalizedContext': normalizedContext,
        'operation': 'MARK_STORY_AS_VIEWED'
      });

      final query = await FirebaseFirestore.instance
          .collection('stores_visto')
          .where('idUser', isEqualTo: userId)
          .where('idStore', isEqualTo: id)
          .get();

      if (query.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('stores_visto').add({
          'data': Timestamp.now(), // Usar Timestamp em vez de DateTime
          'idStore': id,
          'idUser': userId,
          'contexto': normalizedContext, // USAR CONTEXTO NORMALIZADO
        });

        ContextDebug.logSummary('addVisto_success', normalizedContext,
            {'storyId': id, 'markedAsViewed': true});
      } else {
        // Verificar se o contexto do registro existente está correto
        final existingDoc = query.docs.first;
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final existingContext = ContextValidator.normalizeContext(
            existingData['contexto'] as String?);

        if (existingContext != normalizedContext) {
          ContextDebug.logCriticalError(
              'addVisto',
              'VAZAMENTO DETECTADO - Registro existente tem contexto "$existingContext" mas deveria ser "$normalizedContext"',
              normalizedContext);
        }

        ContextDebug.logSummary('addVisto_already_viewed', normalizedContext, {
          'storyId': id,
          'alreadyViewed': true,
          'existingContext': existingContext
        });
      }
    } catch (e) {
      ContextDebug.logCriticalError('addVisto',
          'Erro ao marcar story como visto: $e', contexto ?? 'principal');
    }
  }

  static Future<List<StorieFileModel>> getAllFuture() async {
    List<StorieFileModel> all = [];
    final query =
        await FirebaseFirestore.instance.collection('stories_files').get();

    for (var e in query.docs) {
      StorieFileModel item = StorieFileModel.fromJson(e.data());
      item.id = e.id;
      all.add(item);
    }

    return all;
  }

  /// Busca um story específico por ID
  /// Busca um story específico por ID em todas as coleções
  static Future<StorieFileModel?> getStoryById(String storyId) async {
    try {
      print('🔍 STORIES: Buscando story com ID: $storyId');

      // Lista de coleções onde os stories podem estar
      final collections = [
        'stories_files',
        'stories_sinais_rebeca',
        'stories_sinais_isaque',
        'stories_nosso_proposito',
        'stories',
      ];

      // Busca em cada coleção
      for (final collection in collections) {
        try {
          print('🔍 STORIES: Verificando coleção: $collection');
          final doc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(storyId)
              .get();

          if (doc.exists) {
            print('✅ STORIES: Story encontrado na coleção: $collection');
            
            // 🔧 CORRIGIDO: Usar o mesmo padrão que corrigimos antes
            final storyData = doc.data()! as Map<String, dynamic>;
            final storyDataWithId = <String, dynamic>{
              ...storyData,
              'id': doc.id, // ✅ Injetar ID corretamente
            };
            
            final story = StorieFileModel.fromJson(storyDataWithId);
            print('✅ STORIES: Story ID injetado: ${story.id}');
            
            return story;
          }
        } catch (e) {
          print('⚠️ STORIES: Erro ao buscar na coleção $collection: $e');
          continue;
        }
      }

      print('❌ STORIES: Story não encontrado em nenhuma coleção');
      return null;
    } catch (e) {
      print('❌ STORIES: Erro geral ao buscar story por ID: $e');
      return null;
    }
  }

  /// Obtém stories por contexto (versão Future para uso na nova interface)
  static Future<List<StorieFileModel>> getStoriesByContexto(
      String contexto, UserSexo? userSexo) async {
    try {
      // Executar migração de histórico em background (não bloquear carregamento)
      _historyService.moveExpiredStoriesToHistory().catchError((e) {
        print('DEBUG REPO: Erro na migração de histórico: $e');
      });

      String colecao;
      switch (contexto) {
        case 'sinais_isaque':
          colecao = 'stories_sinais_isaque';
          break;
        case 'sinais_rebeca':
          colecao = 'stories_sinais_rebeca';
          break;
        case 'nosso_proposito':
          colecao = 'stories_nosso_proposito';
          break;
        default:
          colecao = 'stories_files';
      }

      print('DEBUG REPO: Carregando stories da coleção $colecao');

      Query query = FirebaseFirestore.instance.collection(colecao);

      // Filtrar por público-alvo se especificado
      // Não usar whereIn com null - Firebase não permite
      // Vamos filtrar no código depois da consulta

      // Ordenar por data de cadastro para garantir ordem consistente
      query = query.orderBy('dataCadastro', descending: false);

      final snapshot = await query.get();

      List<StorieFileModel> stories = [];
      for (var doc in snapshot.docs) {
        try {
          StorieFileModel story =
              StorieFileModel.fromJson(doc.data() as Map<String, dynamic>);
          story.id = doc.id;

          // Filtrar por idioma se necessário
          if (story.idioma == null || story.idioma == TokenUsuario().idioma) {
            // Filtrar por público-alvo (feito aqui para evitar problema com whereIn + null)
            bool publicoAlvoValido = true;
            if (userSexo != null) {
              // Se userSexo é especificado, aceitar apenas stories sem público-alvo ou com público-alvo correspondente
              publicoAlvoValido =
                  (story.publicoAlvo == null || story.publicoAlvo == userSexo);
            }

            if (publicoAlvoValido) {
              // Verificar se a mídia ainda está acessível
              if (await _isMediaAccessible(story)) {
                stories.add(story);
              } else {
                print('DEBUG REPO: Mídia inacessível para story ${story.id}');
              }
            }
          }
        } catch (e) {
          print('DEBUG REPO: Erro ao processar documento ${doc.id}: $e');
        }
      }

      print(
          'DEBUG REPO: Carregados ${stories.length} stories válidos com mídia acessível');
      return stories;
    } catch (e) {
      print('DEBUG REPO: Erro ao carregar stories por contexto: $e');
      return [];
    }
  }

  /// Verifica se a mídia do story ainda está acessível
  static Future<bool> _isMediaAccessible(StorieFileModel story) async {
    try {
      if (story.fileUrl == null || story.fileUrl!.isEmpty) {
        return false;
      }

      // Para Firebase Storage, verificar se a URL ainda é válida
      if (story.fileUrl!.contains('firebasestorage.googleapis.com')) {
        try {
          // Tentar obter metadados do arquivo
          Reference ref = FirebaseStorage.instance.refFromURL(story.fileUrl!);
          await ref.getMetadata();
          return true;
        } catch (e) {
          print('DEBUG REPO: Mídia não acessível: ${story.fileUrl} - $e');
          return false;
        }
      }

      // Para outras URLs, assumir que estão acessíveis
      return true;
    } catch (e) {
      print('DEBUG REPO: Erro ao verificar acessibilidade da mídia: $e');
      return false;
    }
  }

  static Future<String> _uploadImg(Uint8List fileData) async {
    safePrint('DEBUG REPO: Iniciando upload para Firebase Storage');
    safePrint('DEBUG REPO: Tamanho: ${fileData.length} bytes');

    try {
      // Verificar se o usuário está autenticado
      final user = FirebaseAuth.instance.currentUser;
      safePrint('DEBUG REPO: Usuário atual: ${user?.email ?? "null"}');
      safePrint('DEBUG REPO: UID: ${user?.uid ?? "null"}');
      safePrint('DEBUG REPO: Está autenticado: ${user != null}');

      if (user == null) {
        // Tentar reautenticar
        safePrint('DEBUG REPO: Tentando reautenticar...');
        await FirebaseAuth.instance.authStateChanges().first;
        final userAfterWait = FirebaseAuth.instance.currentUser;

        if (userAfterWait == null) {
          throw Exception('Usuário não autenticado. Faça login novamente.');
        }

        safePrint(
            'DEBUG REPO: Reautenticação bem-sucedida: ${userAfterWait.email}');
      }

      // Validar dados do arquivo
      if (fileData.isEmpty) {
        throw Exception('Dados do arquivo estão vazios');
      }

      if (fileData.length > 50 * 1024 * 1024) {
        // 50MB max
        throw Exception('Arquivo muito grande (máximo 50MB)');
      }

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = user?.uid ?? FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('UID do usuário não disponível');
      }

      final fileName = 'stories_files/${userId}_${timestamp}.png';

      safePrint('DEBUG REPO: Nome do arquivo: $fileName');

      // Criar referência do Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      // Configurar metadados básicos
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': timestamp.toString(),
          'fileType': 'story_image',
        },
      );

      print('DEBUG REPO: Iniciando upload...');

      // Fazer upload simples
      final uploadTask = ref.putData(fileData, metadata);

      // Aguardar conclusão com timeout
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload cancelado por timeout (5 minutos)');
        },
      );

      print('DEBUG REPO: Upload concluído. Estado: ${snapshot.state}');

      // Verificar se o upload foi bem-sucedido
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload falhou. Estado: ${snapshot.state}');
      }

      // Obter URL de download
      String downloadUrl = await ref.getDownloadURL();

      print('DEBUG REPO: URL de download obtida: $downloadUrl');

      // Verificar se a URL é válida
      if (downloadUrl.isEmpty || !downloadUrl.startsWith('https://')) {
        throw Exception('URL de download inválida: $downloadUrl');
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('DEBUG REPO: Erro do Firebase: ${e.code} - ${e.message}');

      // Tratar erros específicos do Firebase de forma simples
      String errorMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage =
              'ERRO DE AUTORIZAÇÃO:\n\n1. Usuário não está logado no Firebase\n2. Regras do Storage muito restritivas\n3. Token de autenticação expirado\n\nTente fazer login novamente.';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload cancelado pelo usuário.';
          break;
        case 'storage/unknown':
          errorMessage =
              'Erro desconhecido do Firebase Storage. Tente novamente.';
          break;
        case 'storage/quota-exceeded':
          errorMessage =
              'Cota de armazenamento excedida. Contate o administrador.';
          break;
        default:
          errorMessage = 'Erro do Firebase Storage: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      safePrint('DEBUG REPO: Erro geral no upload: $e');

      // Tratar outros tipos de erro de forma simples
      if (e.toString().contains('timeout')) {
        throw Exception(
            'Upload demorou muito. Verifique sua conexão e tente novamente.');
      } else if (e.toString().contains('network')) {
        throw Exception('Erro de rede. Verifique sua conexão com a internet.');
      } else {
        throw Exception('Erro ao fazer upload: ${e.toString()}');
      }
    }
  }

  static void _validateImageData(Uint8List fileData) {
    if (fileData.isEmpty) {
      throw ArgumentError('Image data cannot be empty');
    }

    if (fileData.length < 100) {
      throw ArgumentError('Image data too small, possibly corrupted');
    }

    if (fileData.length > 50 * 1024 * 1024) {
      // 50MB max
      throw ArgumentError('Image data too large (max 50MB)');
    }

    // Verificar assinatura básica de imagem
    if (!_hasValidImageSignature(fileData)) {
      throw ArgumentError('Invalid image format or corrupted data');
    }
  }

  static bool _hasValidImageSignature(Uint8List data) {
    if (data.length < 8) return false;

    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return true;
    }

    // JPEG signature: FF D8 FF
    if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
      return true;
    }

    // GIF signature: GIF87a or GIF89a
    if (data.length >= 6) {
      String header = String.fromCharCodes(data.sublist(0, 6));
      if (header == 'GIF87a' || header == 'GIF89a') {
        return true;
      }
    }

    // WEBP signature: RIFF....WEBP
    if (data.length >= 12) {
      if (data[0] == 0x52 &&
          data[1] == 0x49 &&
          data[2] == 0x46 &&
          data[3] == 0x46 &&
          data[8] == 0x57 &&
          data[9] == 0x45 &&
          data[10] == 0x42 &&
          data[11] == 0x50) {
        return true;
      }
    }

    return false;
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
        length, (index) => chars[(random + index) % chars.length]).join();
  }

  static Future<void> _verifyUploadedFile(
      Reference ref, int expectedSize) async {
    try {
      FullMetadata metadata = await ref.getMetadata();

      if (metadata.size == null) {
        throw Exception('Could not verify uploaded file size');
      }

      if (metadata.size! != expectedSize) {
        throw Exception(
            'Uploaded file size mismatch: expected $expectedSize, got ${metadata.size}');
      }

      DebugLogger.debug('StoriesRepository', 'file_verification_passed', {
        'expectedSize': expectedSize,
        'actualSize': metadata.size,
        'contentType': metadata.contentType
      });
    } catch (e) {
      DebugLogger.error(
          'StoriesRepository', 'file_verification_error', e.toString());
      rethrow;
    }
  }

  static Future<String> _uploadVideo(File file) async {
    print('DEBUG REPO: Iniciando upload de vídeo');
    print('DEBUG REPO: Caminho do arquivo: ${file.path}');

    try {
      // Verificar se o usuário está autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      // Verificar se o arquivo existe
      if (!await file.exists()) {
        throw Exception('Arquivo de vídeo não encontrado');
      }

      // Verificar tamanho do arquivo
      final fileSize = await file.length();
      print('DEBUG REPO: Tamanho do vídeo: ${fileSize} bytes');

      if (fileSize == 0) {
        throw Exception('Arquivo de vídeo está vazio');
      }

      if (fileSize > 100 * 1024 * 1024) {
        // 100MB max para vídeos
        throw Exception('Vídeo muito grande (máximo 100MB)');
      }

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = user.uid;
      final fileName = 'stories_files/${userId}_${timestamp}.mp4';

      print('DEBUG REPO: Nome do arquivo: $fileName');

      // Criar referência do Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      // Configurar metadados
      SettableMetadata metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': timestamp.toString(),
          'fileType': 'story_video',
          'fileSize': fileSize.toString(),
        },
      );

      print('DEBUG REPO: Iniciando upload do vídeo...');

      // Fazer upload com monitoramento
      final uploadTask = ref.putFile(file, metadata);

      // Monitorar progresso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print(
            'DEBUG REPO: Progresso do upload do vídeo: ${progress.toStringAsFixed(1)}%');
      });

      // Aguardar conclusão com timeout maior para vídeos
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload do vídeo cancelado por timeout (10 minutos)');
        },
      );

      print('DEBUG REPO: Upload do vídeo concluído. Estado: ${snapshot.state}');

      // Verificar se o upload foi bem-sucedido
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload do vídeo falhou. Estado: ${snapshot.state}');
      }

      // Obter URL de download
      String downloadUrl = await ref.getDownloadURL();

      print('DEBUG REPO: URL de download do vídeo: $downloadUrl');

      // Verificar se a URL é válida
      if (downloadUrl.isEmpty || !downloadUrl.startsWith('https://')) {
        throw Exception('URL de download do vídeo inválida: $downloadUrl');
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      print(
          'DEBUG REPO: Erro do Firebase no upload do vídeo: ${e.code} - ${e.message}');

      // Tratar erros específicos do Firebase
      switch (e.code) {
        case 'storage/unauthorized':
          throw Exception(
              'Sem permissão para fazer upload de vídeo. Verifique as configurações do Firebase.');
        case 'storage/canceled':
          throw Exception('Upload do vídeo cancelado pelo usuário.');
        case 'storage/unknown':
          throw Exception(
              'Erro desconhecido do Firebase Storage no upload do vídeo. Tente novamente.');
        case 'storage/invalid-format':
          throw Exception('Formato de vídeo inválido.');
        case 'storage/quota-exceeded':
          throw Exception('Cota de armazenamento excedida para vídeos.');
        default:
          throw Exception(
              'Erro do Firebase Storage no vídeo: ${e.message ?? e.code}');
      }
    } catch (e, stackTrace) {
      print('DEBUG REPO: Erro geral no upload do vídeo: $e');
      print('DEBUG REPO: Stack trace: $stackTrace');

      // Tratar outros tipos de erro
      if (e.toString().contains('timeout')) {
        throw Exception(
            'Upload do vídeo demorou muito. Verifique sua conexão e tente novamente.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Erro de rede no upload do vídeo. Verifique sua conexão com a internet.');
      } else {
        throw Exception('Erro ao fazer upload do vídeo: ${e.toString()}');
      }
    }
  }

  static Future<void> delete({required String id, String? contexto}) async {
    DebugLogger.info('StoriesRepository', 'delete_start',
        {'documentId': id, 'contexto': contexto});

    String? deletedFromContext;

    try {
      if (contexto == null) {
        // Tentar deletar de ambas as coleções se o contexto não for especificado
        try {
          await FirebaseFirestore.instance
              .collection('stories_files')
              .doc(id)
              .delete();
          deletedFromContext = 'principal';
          DebugLogger.success('StoriesRepository', 'delete_success',
              {'documentId': id, 'collection': 'stories_files'});
        } catch (e) {
          await FirebaseFirestore.instance
              .collection('stories_sinais_isaque')
              .doc(id)
              .delete();
          deletedFromContext = 'sinais_isaque';
          DebugLogger.success('StoriesRepository', 'delete_success',
              {'documentId': id, 'collection': 'stories_sinais_isaque'});
        }
      } else {
        String colecao;
        switch (contexto) {
          case 'sinais_isaque':
            colecao = 'stories_sinais_isaque';
            break;
          case 'sinais_rebeca':
            colecao = 'stories_sinais_rebeca';
            break;
          case 'nosso_proposito':
            colecao = 'stories_nosso_proposito';
            break;
          default:
            colecao = 'stories_files';
        }
        await FirebaseFirestore.instance.collection(colecao).doc(id).delete();
        deletedFromContext = contexto;
        DebugLogger.success('StoriesRepository', 'delete_success',
            {'documentId': id, 'collection': colecao, 'contexto': contexto});
      }

      // Notificar controller da galeria sobre story deletado
      try {
        if (Get.isRegistered<StoriesGalleryController>()) {
          if (deletedFromContext != null) {
            StoriesGalleryController.instance
                .notifyStoryDeleted(deletedFromContext);
          }
        }
      } catch (e) {
        DebugLogger.error(
            'StoriesRepository', 'delete_notification_error', e.toString());
      }
    } catch (e, stackTrace) {
      DebugLogger.error('StoriesRepository', 'delete_error', e.toString(), {
        'documentId': id,
        'contexto': contexto,
        'stackTrace': stackTrace.toString()
      });
      rethrow;
    }
  }

  // ========== MÉTODOS DE HISTÓRICO ==========

  /// Obtém stories do histórico do usuário
  static Future<List<StorieFileModel>> getHistoryStories({
    int limit = 50,
    String? lastDocumentId,
  }) async {
    try {
      print('📚 REPO: Carregando stories do histórico');

      final historyData = await _historyService.getHistoryStories(
        limit: limit,
        lastDocumentId: lastDocumentId,
      );

      List<StorieFileModel> stories = [];
      for (var data in historyData) {
        try {
          StorieFileModel story = StorieFileModel.fromJson(data);
          story.id = data['id'];
          stories.add(story);
        } catch (e) {
          print('DEBUG REPO: Erro ao processar story do histórico: $e');
        }
      }

      print('📚 REPO: Carregados ${stories.length} stories do histórico');
      return stories;
    } catch (e) {
      print('❌ REPO: Erro ao carregar histórico: $e');
      return [];
    }
  }

  /// Move um story específico para o histórico
  static Future<void> moveStoryToHistory(
      String storyId, String contexto) async {
    try {
      print('📦 REPO: Movendo story $storyId para histórico');

      String colecao;
      switch (contexto) {
        case 'sinais_isaque':
          colecao = 'stories_sinais_isaque';
          break;
        case 'sinais_rebeca':
          colecao = 'stories_sinais_rebeca';
          break;
        case 'nosso_proposito':
          colecao = 'stories_nosso_proposito';
          break;
        default:
          colecao = 'stories_files';
      }

      // Obter dados do story
      final doc = await FirebaseFirestore.instance
          .collection(colecao)
          .doc(storyId)
          .get();

      if (!doc.exists) {
        throw Exception('Story não encontrado');
      }

      // Mover para histórico
      await _historyService.moveStoryToHistory(
        storyId,
        colecao,
        doc.data()!,
      );

      print('✅ REPO: Story movido para histórico com sucesso');
    } catch (e) {
      print('❌ REPO: Erro ao mover story para histórico: $e');
      rethrow;
    }
  }

  /// Executa migração manual de stories expirados
  static Future<void> migrateExpiredStories() async {
    try {
      print('🔄 REPO: Iniciando migração manual de stories expirados');
      await _historyService.moveExpiredStoriesToHistory();
      print('✅ REPO: Migração concluída');
    } catch (e) {
      print('❌ REPO: Erro na migração: $e');
      rethrow;
    }
  }

  /// Limpa stories antigos do histórico
  static Future<void> cleanOldHistoryStories({int daysToKeep = 30}) async {
    try {
      print('🧹 REPO: Limpando histórico antigo (>${daysToKeep} dias)');
      await _historyService.cleanOldHistoryStories(daysToKeep: daysToKeep);
      print('✅ REPO: Limpeza do histórico concluída');
    } catch (e) {
      print('❌ REPO: Erro na limpeza do histórico: $e');
      rethrow;
    }
  }

  /// Restaura um story do histórico
  static Future<void> restoreStoryFromHistory(String historyStoryId) async {
    try {
      print('🔄 REPO: Restaurando story $historyStoryId do histórico');
      await _historyService.restoreStoryFromHistory(historyStoryId);
      print('✅ REPO: Story restaurado com sucesso');
    } catch (e) {
      print('❌ REPO: Erro ao restaurar story: $e');
      rethrow;
    }
  }
}
