import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/preferences_data.dart';
import '../models/preferences_result.dart';
import '../services/preferences_service.dart';
import '../utils/enhanced_logger.dart';

/// Nova implementação limpa para configuração de preferências de interação
/// Substitui a implementação problemática anterior
class PreferencesInteractionView extends StatefulWidget {
  final String profileId;
  final Function(String taskName) onTaskCompleted;

  const PreferencesInteractionView({
    super.key,
    required this.profileId,
    required this.onTaskCompleted,
  });

  @override
  State<PreferencesInteractionView> createState() =>
      _PreferencesInteractionViewState();
}

class _PreferencesInteractionViewState
    extends State<PreferencesInteractionView> {
  static const String _tag = 'PREFERENCES_VIEW_V2';

  // Estado local limpo
  bool _allowInteractions = true;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String? _successMessage;
  PreferencesData? _currentData;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  /// Carrega preferências atuais
  Future<void> _loadCurrentPreferences() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      EnhancedLogger.info('Loading current preferences',
          tag: _tag, data: {'profileId': widget.profileId});

      final result = await PreferencesService.loadPreferences(widget.profileId);

      if (result.success && result.data != null) {
        setState(() {
          _currentData = result.data;
          _allowInteractions = result.data!.allowInteractions;
          _isInitialLoading = false;
        });

        if (result.hadCorrections) {
          EnhancedLogger.info('Data corrections were applied during load',
              tag: _tag,
              data: {
                'corrections': result.appliedCorrections,
                'profileId': widget.profileId,
              });
        }
      } else {
        setState(() {
          _errorMessage = result.userFriendlyMessage;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar preferências. Tente novamente.';
        _isInitialLoading = false;
      });

      EnhancedLogger.error('Failed to load preferences in view',
          tag: _tag, error: e, data: {'profileId': widget.profileId});
    }
  }

  /// Salva preferências
  Future<void> _savePreferences() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      EnhancedLogger.info('Saving preferences from view', tag: _tag, data: {
        'profileId': widget.profileId,
        'allowInteractions': _allowInteractions,
      });

      final result = await PreferencesService.savePreferences(
        profileId: widget.profileId,
        allowInteractions: _allowInteractions,
      );

      if (result.success) {
        setState(() {
          _currentData = result.data;
          _successMessage = result.userFriendlyMessage;
          _isLoading = false;
        });

        // Log de sucesso com detalhes
        EnhancedLogger.success('Preferences saved successfully from view',
            tag: _tag,
            data: {
              'profileId': widget.profileId,
              'allowInteractions': _allowInteractions,
              'strategy': result.strategyUsed,
              'corrections': result.appliedCorrections,
              'duration': result.operationDuration?.inMilliseconds,
            });

        // Notificar conclusão da tarefa
        widget.onTaskCompleted('preferences');

        // Aguardar um pouco para mostrar sucesso, depois voltar
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Get.back();
        }
      } else {
        setState(() {
          _errorMessage = result.userFriendlyMessage;
          _isLoading = false;
        });

        EnhancedLogger.error('Failed to save preferences from view',
            tag: _tag,
            data: {
              'profileId': widget.profileId,
              'errorType': result.errorType?.toString(),
              'errorMessage': result.errorMessage,
            });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado. Tente novamente.';
        _isLoading = false;
      });

      EnhancedLogger.error('Unexpected error in save preferences',
          tag: _tag, error: e, data: {'profileId': widget.profileId});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '⚙️ Preferências de Interação',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isInitialLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuidanceCard(),
                  const SizedBox(height: 24),
                  _buildPreferencesForm(),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) _buildErrorMessage(),
                  if (_successMessage != null) _buildSuccessMessage(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando preferências...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[100]!, Colors.orange[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Controle de Interações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Configure como outros usuários podem interagir com seu perfil. Você sempre pode alterar essas configurações depois.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações de Interação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Allow interactions switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permitir Demonstrações de Interesse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _allowInteractions
                            ? 'Outros usuários podem demonstrar interesse em seu perfil'
                            : 'Seu perfil será visível, mas sem opção de interesse',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _allowInteractions,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _allowInteractions = value;
                            _errorMessage = null;
                            _successMessage = null;
                          });
                        },
                  activeColor: Colors.orange[700],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Information about interactions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Como funcionam as interações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Outros usuários podem clicar em "Tenho Interesse" no seu perfil\n'
                  '• Se vocês dois demonstrarem interesse, será liberado um chat temporário\n'
                  '• O chat dura 7 dias para vocês se conhecerem melhor\n'
                  '• Depois podem decidir se querem continuar no "Nosso Propósito"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Salvando...'),
                ],
              )
            : const Text(
                'Salvar Preferências',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
