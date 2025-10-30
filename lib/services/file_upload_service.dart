import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/file_upload_result.dart';

/// Exceções de upload de arquivo
class FileUploadException implements Exception {
  final String message;
  final FileUploadError errorType;

  FileUploadException(this.message, this.errorType);

  @override
  String toString() => 'FileUploadException: $message';
}

/// Tipos de erro de upload
enum FileUploadError {
  networkError,
  storageError,
  permissionDenied,
  fileTooLarge,
  invalidFormat,
}

/// Serviço para gerenciar upload de arquivos para Firebase Storage
class FileUploadService {
  final FirebaseStorage _storage;

  FileUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Tamanho máximo de arquivo (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Tipos de arquivo permitidos
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedDocumentTypes = [
    'application/pdf',
  ];

  /// Upload de comprovante de certificação
  ///
  /// [userId] - ID do usuário
  /// [file] - Arquivo a ser enviado
  /// [onProgress] - Callback de progresso (0.0 a 1.0)
  ///
  /// Retorna [FileUploadResult] com URL de download e metadados
  Future<FileUploadResult> uploadCertificationProof({
    required String userId,
    required File file,
    required Function(double) onProgress,
  }) async {
    try {
      // Validar arquivo
      validateFile(file);

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final fileName = '${timestamp}_proof$extension';

      // Caminho no Storage
      final storagePath = 'certification_proofs/$userId/$fileName';
      final storageRef = _storage.ref().child(storagePath);

      // Obter tipo MIME do arquivo
      final mimeType = _getMimeType(file);

      // Configurar metadados
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      // Fazer upload
      final uploadTask = storageRef.putFile(file, metadata);

      // Monitorar progresso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      // Aguardar conclusão
      final snapshot = await uploadTask;

      // Obter URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Obter tamanho do arquivo
      final fileSize = await file.length();

      return FileUploadResult(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        fileSize: fileSize,
        fileType: mimeType,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized') {
        throw FileUploadException(
          'Permissão negada para fazer upload',
          FileUploadError.permissionDenied,
        );
      } else if (e.code == 'canceled') {
        throw FileUploadException(
          'Upload cancelado',
          FileUploadError.networkError,
        );
      } else {
        throw FileUploadException(
          'Erro ao fazer upload: ${e.message}',
          FileUploadError.storageError,
        );
      }
    } catch (e) {
      throw FileUploadException(
        'Erro inesperado ao fazer upload: $e',
        FileUploadError.networkError,
      );
    }
  }

  /// Deletar comprovante
  ///
  /// [proofUrl] - URL do comprovante a ser deletado
  Future<void> deleteProof(String proofUrl) async {
    try {
      // Extrair caminho do Storage da URL
      final ref = _storage.refFromURL(proofUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        // Arquivo já foi deletado, não é erro
        return;
      } else if (e.code == 'unauthorized') {
        throw FileUploadException(
          'Permissão negada para deletar arquivo',
          FileUploadError.permissionDenied,
        );
      } else {
        throw FileUploadException(
          'Erro ao deletar arquivo: ${e.message}',
          FileUploadError.storageError,
        );
      }
    } catch (e) {
      throw FileUploadException(
        'Erro inesperado ao deletar arquivo: $e',
        FileUploadError.networkError,
      );
    }
  }

  /// Validar arquivo antes do upload
  ///
  /// Lança [FileUploadException] se o arquivo for inválido
  bool validateFile(File file) {
    // Verificar se arquivo existe
    if (!file.existsSync()) {
      throw FileUploadException(
        'Arquivo não encontrado',
        FileUploadError.invalidFormat,
      );
    }

    // Verificar tamanho
    final fileSize = file.lengthSync();
    if (fileSize > maxFileSize) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      throw FileUploadException(
        'Arquivo muito grande ($sizeMB MB). Máximo permitido: 5 MB',
        FileUploadError.fileTooLarge,
      );
    }

    // Verificar tipo
    final mimeType = _getMimeType(file);
    if (!_isAllowedType(mimeType)) {
      throw FileUploadException(
        'Tipo de arquivo não permitido. Use imagens (JPG, PNG) ou PDF',
        FileUploadError.invalidFormat,
      );
    }

    return true;
  }

  /// Obter extensão do arquivo
  String getFileExtension(File file) {
    return path.extension(file.path).toLowerCase();
  }

  /// Obter tipo MIME do arquivo baseado na extensão
  String _getMimeType(File file) {
    final extension = getFileExtension(file);

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Verificar se o tipo MIME é permitido
  bool _isAllowedType(String mimeType) {
    return allowedImageTypes.contains(mimeType) ||
        allowedDocumentTypes.contains(mimeType);
  }

  /// Verificar se é uma imagem
  bool isImage(File file) {
    final mimeType = _getMimeType(file);
    return allowedImageTypes.contains(mimeType);
  }

  /// Verificar se é um PDF
  bool isPdf(File file) {
    final mimeType = _getMimeType(file);
    return allowedDocumentTypes.contains(mimeType);
  }

  /// Formatar tamanho de arquivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
