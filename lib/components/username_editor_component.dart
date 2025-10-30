import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/username_management_service.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';
import '../utils/data_validator.dart';

/// Componente para edição de username com validação e sugestões
class UsernameEditorComponent extends StatefulWidget {
  final String userId;
  final String? currentUsername;
  final Function(String newUsername)? onUsernameChanged;
  final bool showSuggestions;

  const UsernameEditorComponent({
    super.key,
    required this.userId,
    this.currentUsername,
    this.onUsernameChanged,
    this.showSuggestions = true,
  });

  @override
  State<UsernameEditorComponent> createState() =>
      _UsernameEditorComponentState();
}

class _UsernameEditorComponentState extends State<UsernameEditorComponent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isValidating = false;
  bool _isAvailable = true;
  String? _validationMessage;
  List<String> _suggestions = [];
  UsernameChangeInfo? _changeInfo;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentUsername ?? '';
    _loadChangeInfo();

    // Debounce para validação
    _controller.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadChangeInfo() async {
    try {
      final info = await UsernameManagementService.getChangeInfo(widget.userId);
      if (mounted) {
        setState(() {
          _changeInfo = info;
        });
      }
    } catch (e) {
      EnhancedLogger.error('Failed to load username change info',
          tag: 'USERNAME_EDITOR', error: e, data: {'userId': widget.userId});
    }
  }

  void _onUsernameChanged() {
    final username = _controller.text.trim();

    // Cancelar validação anterior
    if (_isValidating) return;

    // Validar após 500ms de inatividade
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller.text.trim() == username && mounted) {
        _validateUsername(username);
      }
    });
  }

  Future<void> _validateUsername(String username) async {
    if (username.isEmpty || username == widget.currentUsername) {
      setState(() {
        _validationMessage = null;
        _isAvailable = true;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      // Validar formato
      if (!DataValidator.isValidUsernameFormat(username)) {
        setState(() {
          _validationMessage =
              'Username deve ter 3-30 caracteres, começar com letra/número';
          _isAvailable = false;
          _isValidating = false;
        });
        return;
      }

      // Verificar disponibilidade
      final isAvailable =
          await UsernameManagementService.isUsernameAvailable(username);

      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _validationMessage =
              isAvailable ? null : 'Este username já está em uso';
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationMessage = 'Erro ao verificar disponibilidade';
          _isAvailable = false;
          _isValidating = false;
        });
      }
    }
  }

  Future<void> _generateSuggestions() async {
    if (!widget.showSuggestions) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar nome do usuário ou username atual como base
      final baseName = widget.currentUsername ?? 'user';
      final suggestions =
          await UsernameManagementService.generateSuggestions(baseName);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      EnhancedLogger.error('Failed to generate username suggestions',
          tag: 'USERNAME_EDITOR', error: e);
    }
  }

  Future<void> _saveUsername() async {
    final newUsername = _controller.text.trim();

    if (newUsername == widget.currentUsername) {
      _cancelEditing();
      return;
    }

    if (!_isAvailable || newUsername.isEmpty) {
      ErrorHandler.showWarning('Username inválido ou não disponível');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await UsernameManagementService.updateUsername(
          widget.userId, newUsername);

      if (success && mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        if (widget.onUsernameChanged != null) {
          widget.onUsernameChanged!(newUsername);
        }

        // Recarregar informações de alteração
        await _loadChangeInfo();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      EnhancedLogger.error('Failed to save username',
          tag: 'USERNAME_EDITOR',
          error: e,
          data: {'userId': widget.userId, 'newUsername': newUsername});
    }
  }

  void _startEditing() {
    if (_changeInfo?.canChange != true) {
      _showChangeRestrictionDialog();
      return;
    }

    setState(() {
      _isEditing = true;
      _suggestions.clear();
    });

    _focusNode.requestFocus();

    if (widget.showSuggestions) {
      _generateSuggestions();
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.currentUsername ?? '';
      _validationMessage = null;
      _isAvailable = true;
      _suggestions.clear();
    });
  }

  void _showChangeRestrictionDialog() {
    final info = _changeInfo;
    if (info == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Alteração de Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Você só pode alterar seu username a cada 30 dias.'),
            const SizedBox(height: 12),
            if (info.lastChangeDate != null) ...[
              Text('Última alteração: ${_formatDate(info.lastChangeDate!)}'),
              const SizedBox(height: 8),
            ],
            Text('Próxima alteração em: ${info.daysUntilNextChange} dias'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUsernameField(),
        if (_validationMessage != null) ...[
          const SizedBox(height: 8),
          _buildValidationMessage(),
        ],
        if (_isEditing && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSuggestions(),
        ],
        if (_changeInfo != null && !_changeInfo!.canChange) ...[
          const SizedBox(height: 8),
          _buildChangeRestriction(),
        ],
      ],
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? (_isAvailable ? Colors.blue[300]! : Colors.red[300]!)
              : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.alternate_email,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isEditing ? _buildEditingField() : _buildDisplayField(),
            ),
            if (_isLoading) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
            ] else if (_isEditing) ...[
              const SizedBox(width: 8),
              _buildEditingActions(),
            ] else ...[
              const SizedBox(width: 8),
              _buildEditButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.currentUsername?.isNotEmpty == true
              ? '@${widget.currentUsername}'
              : 'Definir username',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.currentUsername?.isNotEmpty == true
                ? Colors.black87
                : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildEditingField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        hintText: 'Digite seu username',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onSubmitted: (_) => _saveUsername(),
    );
  }

  Widget _buildEditingActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _cancelEditing,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isAvailable && !_isValidating ? _saveUsername : null,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.check,
              size: 18,
              color: _isAvailable && !_isValidating
                  ? Colors.green[600]
                  : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Text(
          widget.currentUsername?.isNotEmpty == true ? 'Editar' : 'Definir',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationMessage() {
    return Row(
      children: [
        Icon(
          _isValidating
              ? Icons.hourglass_empty
              : (_isAvailable ? Icons.check_circle : Icons.error),
          size: 16,
          color: _isValidating
              ? Colors.orange[600]
              : (_isAvailable ? Colors.green[600] : Colors.red[600]),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _isValidating
                ? 'Verificando disponibilidade...'
                : (_validationMessage ?? 'Username disponível'),
            style: TextStyle(
              fontSize: 12,
              color: _isValidating
                  ? Colors.orange[600]
                  : (_isAvailable ? Colors.green[600] : Colors.red[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _suggestions
              .map(
                (suggestion) => GestureDetector(
                  onTap: () {
                    _controller.text = suggestion;
                    _validateUsername(suggestion);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      '@$suggestion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildChangeRestriction() {
    final info = _changeInfo!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: Colors.orange[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Próxima alteração em ${info.daysUntilNextChange} dias',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
