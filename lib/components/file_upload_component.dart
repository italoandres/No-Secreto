import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

/// Componente para upload de arquivo com preview e validação
/// Funciona tanto em Web quanto em Mobile
class FileUploadComponent extends StatefulWidget {
  final Function(PlatformFile?) onFileSelected;
  final String? initialFileName;
  final List<String> allowedExtensions;
  final int maxFileSizeMB;

  const FileUploadComponent({
    Key? key,
    required this.onFileSelected,
    this.initialFileName,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.maxFileSizeMB = 5,
  }) : super(key: key);

  @override
  State<FileUploadComponent> createState() => _FileUploadComponentState();
}

class _FileUploadComponentState extends State<FileUploadComponent> {
  PlatformFile? _selectedFile;
  String? _fileName;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      FilePickerResult? result;
      
      if (kIsWeb) {
        // Configuração específica para Web (Chrome, Firefox, Safari)
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: widget.allowedExtensions,
          allowMultiple: false,
          withData: true, // CRUCIAL para web - carrega dados na memória
        );
      } else {
        // Configuração para Mobile (Android/iOS)
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validar tamanho
        final fileSize = file.size;
        final maxSizeBytes = widget.maxFileSizeMB * 1024 * 1024;
        
        if (fileSize > maxSizeBytes) {
          setState(() {
            _errorMessage = 'O arquivo deve ter no máximo ${widget.maxFileSizeMB}MB';
            _selectedFile = null;
            _fileName = null;
          });
          widget.onFileSelected(null);
          return;
        }

        // Para web, verificar se os dados foram carregados
        if (kIsWeb && file.bytes == null) {
          setState(() {
            _errorMessage = 'Erro ao carregar arquivo. Tente novamente.';
            _selectedFile = null;
            _fileName = null;
          });
          widget.onFileSelected(null);
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileName = file.name;
          _errorMessage = null;
        });

        widget.onFileSelected(file);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar arquivo: $e';
        _selectedFile = null;
        _fileName = null;
      });
      widget.onFileSelected(null);
      print('Erro detalhado no upload: $e'); // Para debug
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _errorMessage = null;
    });
    widget.onFileSelected(null);
  }

  String _getFileIcon() {
    if (_fileName == null) return '📎';
    
    final extension = _fileName!.toLowerCase();
    if (extension.endsWith('.pdf')) {
      return '📄';
    } else if (extension.endsWith('.jpg') || 
               extension.endsWith('.jpeg') || 
               extension.endsWith('.png')) {
      return '🖼️';
    } else {
      return '📎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão de seleção ou preview do arquivo
        if (_fileName == null)
          _buildSelectButton()
        else
          _buildFilePreview(),

        // Mensagem de erro
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],

        // Informação sobre tipos permitidos
        if (_fileName == null) ...[
          const SizedBox(height: 8),
          Text(
            kIsWeb 
              ? 'Formatos: ${widget.allowedExtensions.map((e) => e.toUpperCase()).join(', ')} • Máx: ${widget.maxFileSizeMB}MB (Web)'
              : 'Formatos: ${widget.allowedExtensions.map((e) => e.toUpperCase()).join(', ')} • Máx: ${widget.maxFileSizeMB}MB',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectButton() {
    return InkWell(
      onTap: _isLoading ? null : _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.attach_file,
                size: 24,
                color: Colors.grey,
              ),
            const SizedBox(width: 12),
            Text(
              _isLoading ? 'Selecionando...' : 'Anexar Diploma',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Ícone do arquivo
          Text(
            _getFileIcon(),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          
          // Nome do arquivo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(_selectedFile!.size),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Botão remover
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _removeFile,
            tooltip: 'Remover arquivo',
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
