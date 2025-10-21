import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Visualizador de comprovante de certificação
class CertificationProofViewer extends StatefulWidget {
  final String proofUrl;
  final String fileName;

  const CertificationProofViewer({
    Key? key,
    required this.proofUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  State<CertificationProofViewer> createState() => _CertificationProofViewerState();
}

class _CertificationProofViewerState extends State<CertificationProofViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadProof();
  }

  /// Carregar comprovante
  Future<void> _loadProof() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Verificar se o arquivo existe
      final ref = FirebaseStorage.instance.refFromURL(widget.proofUrl);
      await ref.getMetadata();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erro ao carregar comprovante: $e';
      });
    }
  }

  /// Verificar se é PDF
  bool get _isPdf {
    return widget.fileName.toLowerCase().endsWith('.pdf');
  }

  /// Verificar se é imagem
  bool get _isImage {
    final ext = widget.fileName.toLowerCase();
    return ext.endsWith('.jpg') || 
           ext.endsWith('.jpeg') || 
           ext.endsWith('.png');
  }

  /// Abrir arquivo
  Future<void> _openFile() async {
    try {
      final uri = Uri.parse(widget.proofUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Não foi possível abrir o arquivo');
      }
    } catch (e) {
      _showErrorDialog('Erro ao abrir arquivo: $e');
    }
  }

  /// Fazer download do arquivo
  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Obter diretório de downloads
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.fileName}';
      final file = File(filePath);

      // Fazer download
      final ref = FirebaseStorage.instance.refFromURL(widget.proofUrl);
      final downloadTask = ref.writeToFile(file);

      // Monitorar progresso
      downloadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _downloadProgress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        });
      });

      await downloadTask;

      setState(() {
        _isDownloading = false;
      });

      // Mostrar sucesso
      _showSuccessDialog('Arquivo baixado com sucesso!', filePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showErrorDialog('Erro ao baixar arquivo: $e');
    }
  }

  /// Compartilhar arquivo
  Future<void> _shareFile() async {
    try {
      await Share.shareUri(Uri.parse(widget.proofUrl));
    } catch (e) {
      _showErrorDialog('Erro ao compartilhar: $e');
    }
  }

  /// Mostrar diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Erro'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de sucesso
  void _showSuccessDialog(String message, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Sucesso'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(
              'Salvo em: $filePath',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.fileName,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // Botão Compartilhar
          IconButton(
            onPressed: _shareFile,
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
          ),
          
          // Botão Download
          IconButton(
            onPressed: _isDownloading ? null : _downloadFile,
            icon: _isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _downloadProgress,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Baixar',
          ),
          
          // Botão Abrir Externamente
          IconButton(
            onPressed: _openFile,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Abrir externamente',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar comprovante',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Erro desconhecido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProof,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Visualização baseada no tipo de arquivo
    if (_isImage) {
      return _buildImageViewer();
    } else if (_isPdf) {
      return _buildPdfViewer();
    } else {
      return _buildUnsupportedViewer();
    }
  }

  /// Visualizador de imagem
  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.proofUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Visualizador de PDF
  Widget _buildPdfViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Documento PDF',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.fileName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'O PDF será aberto em um aplicativo externo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Visualizador para tipos não suportados
  Widget _buildUnsupportedViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Tipo de arquivo não suportado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.fileName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _downloadFile,
            icon: const Icon(Icons.download),
            label: const Text('Baixar Arquivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
