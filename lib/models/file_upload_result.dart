/// Resultado do upload de arquivo
class FileUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int fileSize;
  final String fileType;

  FileUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
    required this.fileType,
  });

  /// Verifica se é uma imagem
  bool get isImage => fileType.startsWith('image/');

  /// Verifica se é um PDF
  bool get isPdf => fileType == 'application/pdf';

  /// Tamanho formatado em MB
  String get fileSizeFormatted {
    final sizeInMB = fileSize / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(2)} MB';
  }

  /// Cria uma cópia com alterações
  FileUploadResult copyWith({
    String? downloadUrl,
    String? storagePath,
    int? fileSize,
    String? fileType,
  }) {
    return FileUploadResult(
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'fileSize': fileSize,
      'fileType': fileType,
    };
  }

  /// Cria a partir de Map
  factory FileUploadResult.fromMap(Map<String, dynamic> map) {
    return FileUploadResult(
      downloadUrl: map['downloadUrl'] ?? '',
      storagePath: map['storagePath'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileType: map['fileType'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FileUploadResult(downloadUrl: $downloadUrl, storagePath: $storagePath, fileSize: $fileSizeFormatted, fileType: $fileType)';
  }
}
