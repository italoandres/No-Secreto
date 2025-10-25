import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../components/certification_request_form_component.dart';
import '../services/spiritual_certification_service.dart';
import '../utils/certification_status_helper.dart';
import '../repositories/spiritual_certification_repository.dart';
import '../models/certification_request_model.dart';

/// Tela para solicitação de certificação espiritual com toggle de preparação
class SpiritualCertificationRequestView extends StatefulWidget {
  const SpiritualCertificationRequestView({Key? key}) : super(key: key);

  @override
  State<SpiritualCertificationRequestView> createState() =>
      _SpiritualCertificationRequestViewState();
}

class _SpiritualCertificationRequestViewState
    extends State<SpiritualCertificationRequestView> {
  final SpiritualCertificationService _service =
      SpiritualCertificationService();
  final SpiritualCertificationRepository _repository =
      SpiritualCertificationRepository();

  bool _isLoading = false;
  bool _isCheckingStatus = true;
  double _uploadProgress = 0.0;
  bool _showProgress = false;
  bool _mounted = true;

  // Status da certificação
  bool _hasApprovedCertification = false;
  bool _hasPendingCertification = false;
  CertificationRequestModel? _latestCertification;

  // Toggle: Eu estou preparado para encontrar meu Isaque/Rebeca
  final RxBool _isReady = false.obs;

  @override
  void initState() {
    super.initState();
    _checkCertificationStatus();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (_mounted && mounted) {
      setState(fn);
    }
  }

  /// Verificar status da certificação do usuário
  Future<void> _checkCertificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _safeSetState(() {
        _isCheckingStatus = false;
      });
      return;
    }

    try {
      // Verificar se tem certificação aprovada
      final hasApproved =
          await CertificationStatusHelper.hasApprovedCertification(user.uid);

      // Verificar se tem certificação pendente
      final hasPending =
          await CertificationStatusHelper.hasPendingCertification(user.uid);

      _safeSetState(() {
        _hasApprovedCertification = hasApproved;
        _hasPendingCertification = hasPending;
        _isCheckingStatus = false;

        // Se tem aprovada ou pendente, toggle fica ligado
        if (hasApproved || hasPending) {
          _isReady.value = true;
        }
      });
    } catch (e) {
      print('❌ Erro ao verificar status de certificação: $e');
      _safeSetState(() {
        _isCheckingStatus = false;
      });
    }
  }

  /// Widget para exibir um benefício
  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Submeter solicitação
  Future<void> _submitRequest(
      String purchaseEmail, PlatformFile proofFile) async {
    if (!_mounted || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (_mounted && mounted) {
        _showErrorDialog('Erro', 'Usuário não autenticado');
      }
      return;
    }

    _safeSetState(() {
      _isLoading = true;
      _showProgress = true;
      _uploadProgress = 0.0;
    });

    try {
      final result = await _service.createCertificationRequest(
        userId: user.uid,
        userName: user.displayName ?? 'Usuário',
        userEmail: user.email ?? '',
        purchaseEmail: purchaseEmail,
        proofFile: proofFile,
        onUploadProgress: (progress) {
          _safeSetState(() {
            _uploadProgress = progress;
          });
        },
      );

      _safeSetState(() {
        _isLoading = false;
        _showProgress = false;
      });

      if (_mounted && mounted) {
        if (result.success) {
          // Atualizar status após envio bem-sucedido
          await _checkCertificationStatus();
          _showSuccessDialog(
              result.message ?? 'Solicitação enviada com sucesso!');
        } else {
          _showErrorDialog(
              'Erro', result.message ?? 'Erro ao enviar solicitação');
        }
      }
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _showProgress = false;
      });
      if (_mounted && mounted) {
        _showErrorDialog('Erro', 'Erro inesperado: $e');
      }
    }
  }

  /// Mostrar diálogo de sucesso
  void _showSuccessDialog(String message) {
    if (!_mounted || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sucesso!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Você será notificado quando sua solicitação for analisada.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Fechar diálogo
              if (_mounted && mounted) {
                Navigator.of(context).pop(); // Voltar para tela anterior
              }
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de erro
  void _showErrorDialog(String title, String message) {
    if (!_mounted || !mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade100,
              Colors.amber.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar customizada
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Certificação Espiritual',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            'Destaque seu Perfil',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ícone decorativo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: _isCheckingStatus
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.amber.shade700),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Verificando status...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Obx(() => Column(
                              children: [
                                // Card com informações da mentoria
                                _buildMentoriaInfoCard(),

                                const SizedBox(height: 24),

                                // Toggle: Eu estou preparado
                                _buildReadyToggle(),

                                const SizedBox(height: 24),

                                // Conteúdo condicional
                                if (_isReady.value) ...[
                                  if (_hasApprovedCertification)
                                    _buildApprovedCertificationCard()
                                  else if (_hasPendingCertification)
                                    _buildPendingCertificationCard()
                                  else
                                    _buildCertificationForm(),
                                ] else
                                  _buildMentoriaCallToAction(),
                              ],
                            )),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card com informações da mentoria
  Widget _buildMentoriaInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone grande
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified,
              size: 64,
              color: Colors.amber.shade700,
            ),
          ),

          const SizedBox(height: 16),

          // Título
          Text(
            'Selo de Certificação',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),

          const SizedBox(height: 8),

          // Descrição
          Text(
            'Destaque seu perfil com o selo dourado de certificação espiritual',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle: Eu estou preparado
  Widget _buildReadyToggle() {
    // Se tem certificação aprovada ou pendente, não pode desabilitar
    final canToggle = !_hasApprovedCertification && !_hasPendingCertification;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isReady.value ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isReady.value ? Colors.green : Colors.grey)
                .shade200
                .withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eu estou preparado(a) para encontrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'meu Isaque, minha Rebeca',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canToggle
                      ? 'Ative se você já fez a mentoria'
                      : '✓ Certificação ativa',
                  style: TextStyle(
                    fontSize: 13,
                    color: canToggle
                        ? Colors.grey.shade600
                        : Colors.green.shade600,
                    fontWeight: canToggle ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _isReady.value,
            onChanged: canToggle
                ? (value) {
                    _isReady.value = value;
                  }
                : null, // null = desabilitado
            activeColor: Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  /// Formulário de certificação (quando toggle ligado)
  Widget _buildCertificationForm() {
    return Column(
      children: [
        // Mensagem de sucesso
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.celebration, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Parabéns! Agora você pode solicitar seu selo de certificação.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Formulário de solicitação
        CertificationRequestFormComponent(
          onSubmit: _submitRequest,
          enabled: !_isLoading,
        ),

        // Progress indicator
        if (_showProgress) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Enviando... ${(_uploadProgress * 100).toInt()}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// Card de certificação aprovada
  Widget _buildApprovedCertificationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade50,
            Colors.yellow.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade200.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone grande dourado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade300,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 64,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Título
          Text(
            '🎉 Certificação Aprovada!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Mensagem
          Text(
            'Seu perfil agora possui o selo dourado de certificação espiritual',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Benefícios ativos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Benefícios Ativos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBenefit('Selo dourado visível em seu perfil'),
                _buildBenefit('Destaque na comunidade'),
                _buildBenefit('Maior credibilidade'),
                _buildBenefit('Prioridade em matches'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de certificação pendente
  Widget _buildPendingCertificationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.blue.shade600,
            ),
          ),

          const SizedBox(height: 20),

          // Título
          Text(
            'Solicitação em Análise',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Mensagem
          Text(
            'Sua solicitação está sendo analisada. Você será notificado em breve!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Info adicional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aguarde a análise do administrador',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Call to action para fazer a mentoria (quando toggle desligado)
  Widget _buildMentoriaCallToAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              size: 48,
              color: Colors.purple.shade600,
            ),
          ),

          const SizedBox(height: 20),

          // Título
          Text(
            'Faça a Mentoria',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Descrição
          Text(
            'Sinais de meu Isaque e de minha Rebeca',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.pink.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Benefícios
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefícios da Mentoria:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefit('Aprenda a identificar os sinais de Deus'),
                _buildBenefit('Prepare-se espiritualmente para o casamento'),
                _buildBenefit('Desenvolva discernimento e sabedoria'),
                _buildBenefit('Receba o selo dourado em seu perfil'),
                _buildBenefit('Destaque-se na comunidade'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botão CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Abrir link da mentoria
                Get.snackbar(
                  'Em breve',
                  'Link para a mentoria será disponibilizado em breve!',
                  backgroundColor: Colors.purple.shade100,
                  colorText: Colors.purple.shade900,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 3),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.purple.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_circle_filled, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Fazer a Mentoria Agora',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Texto informativo
          Text(
            'Após concluir a mentoria, ative o toggle acima para solicitar seu selo',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
