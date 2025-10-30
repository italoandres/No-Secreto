import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Componente para upload de comprovante de certificação
class ProofUploadComponent extends StatefulWidget {
  final File? selectedFile;
  final Function(File?) onFileSelected;
  final Color primaryColor;
  final String? errorMessage;

  const ProofUploadComponent({
    super.key,
    this.selectedFile,
    required this.onFileSelected,
    required this.primaryColor,
    this.errorMessage,
  });

  @override
  State<ProofUploadComponent> createState() => _ProofUploadComponentState();
}

class _ProofUploadComponentState extends State<ProofUploadComponent> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  /// Mostra opções de seleção de arquivo
  void _showFileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Selecionar Comprovante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildOptionTile(
                      icon: Icons.camera_alt,
                      title: 'Tirar Foto',
                      subtitle: 'Use a câmera para fotografar o comprovante',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.photo_library,
                      title: 'Galeria de Fotos',
                      subtitle: 'Escolher uma foto da galeria',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.insert_drive_file,
                      title: 'Selecionar PDF',
                      subtitle: 'Escolher um arquivo PDF',
                      onTap: () {
                        Navigator.pop(context);
                        _pickPdfFile();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: widget.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Captura foto da câmera
  Future<void> _pickImageFromCamera() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onFileSelected(File(image.path));
      }
    } catch (e) {
      _showError('Erro ao capturar foto: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Seleciona imagem da galeria
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onFileSelected(File(image.path));
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Seleciona arquivo PDF
  Future<void> _pickPdfFile() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        widget.onFileSelected(File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Erro ao selecionar PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selectedFile == null)
          _buildUploadButton()
        else
          _buildFilePreview(),
        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return InkWell(
      onTap: _isLoading ? null : _showFileOptions,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.errorMessage != null ? Colors.red : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Column(
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: widget.primaryColor,
              ),
            const SizedBox(height: 12),
            Text(
              _isLoading ? 'Carregando...' : 'Anexar Comprovante',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Foto ou PDF (máx. 5MB)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final file = widget.selectedFile!;
    final fileName = file.path.split('/').last;
    final isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(0.05),
      ),
      child: Row(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 32,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileSize(file),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => widget.onFileSelected(null),
          ),
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
