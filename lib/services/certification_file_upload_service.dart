import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

/// Resultado do upload de arquivo
class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? error;

  UploadResult.success(this.downloadUrl)
      : success = true,
        error = null;

  UploadResult.error(this.error)
      : success = false,
        downloadUrl = null;
}

/// Serviço para upload de comprovantes de certificação
class CertificationFileUploadService {
  final FirebaseStorage _storage;

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = [
    '.pdf',
    '.jpg',
    '.jpeg',
    '.png',
  ];

  CertificationFileUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Validar arquivo antes do upload
  bool validateFile(PlatformFile file) {
    // Verificar tamanho
    final fileSize = file.size;
    if (fileSize > maxFileSizeBytes) {
      return false;
    }

    // Verificar extensão
    final extension = '.${file.extension ?? ''}'.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return false;
    }

    return true;
  }

  /// Obter mensagem de erro de validação
  String? getValidationError(PlatformFile file) {
    // Verificar tamanho
    final fileSize = file.size;
    if (fileSize > maxFileSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return 'O arquivo deve ter no máximo 5MB (atual: ${sizeMB}MB)';
    }

    // Verificar extensão
    final extension = '.${file.extension ?? ''}'.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Apenas PDF, JPG, JPEG ou PNG são permitidos';
    }

    return null;
  }

  /// Fazer upload do arquivo de comprovante
  Future<UploadResult> uploadProofFile({
    required String userId,
    required PlatformFile file,
    required Function(double) onProgress,
  }) async {
    try {
      // Validar arquivo
      final validationError = getValidationError(file);
      if (validationError != null) {
        return UploadResult.error(validationError);
      }

      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = '.${file.extension ?? 'bin'}';
      final fileName = 'proof_$timestamp$extension';

      // Caminho no Storage: /certifications/{userId}/{fileName}
      final storagePath = 'certifications/$userId/$fileName';
      final storageRef = _storage.ref().child(storagePath);

      // Fazer upload com monitoramento de progresso
      // Para web, usar bytes; para mobile, usar path
      final UploadTask uploadTask;
      if (file.bytes != null) {
        // Web - usar bytes
        uploadTask = storageRef.putData(file.bytes!);
      } else if (file.path != null) {
        // Mobile - usar path
        uploadTask = storageRef.putFile(File(file.path!));
      } else {
        return UploadResult.error('Arquivo inválido');
      }

      // Monitorar progresso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      // Aguardar conclusão
      final snapshot = await uploadTask;

      // Obter URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return UploadResult.success(downloadUrl);
    } on FirebaseException catch (e) {
      return UploadResult.error('Erro no Firebase: ${e.message}');
    } catch (e) {
      return UploadResult.error('Erro ao enviar arquivo: $e');
    }
  }

  /// Obter URL de download de um arquivo
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Deletar arquivo do Storage
  Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verificar se extensão é permitida
  bool isExtensionAllowed(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Obter tamanho máximo em MB
  double get maxFileSizeMB => maxFileSizeBytes / (1024 * 1024);

  /// Formatar tamanho de arquivo
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
