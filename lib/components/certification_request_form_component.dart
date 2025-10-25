import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'file_upload_component.dart';

/// Formulário para solicitação de certificação espiritual
class CertificationRequestFormComponent extends StatefulWidget {
  final Function(String purchaseEmail, PlatformFile proofFile) onSubmit;
  final bool enabled;

  const CertificationRequestFormComponent({
    Key? key,
    required this.onSubmit,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CertificationRequestFormComponent> createState() =>
      _CertificationRequestFormComponentState();
}

class _CertificationRequestFormComponentState
    extends State<CertificationRequestFormComponent> {
  final _formKey = GlobalKey<FormState>();
  final _purchaseEmailController = TextEditingController();
  final _appEmailController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _purchaseEmailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _purchaseEmailController.dispose();
    _appEmailController.dispose();
    super.dispose();
  }

  /// Carregar email do usuário autenticado
  void _loadUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _appEmailController.text = user.email!;
    }
  }

  /// Validar formulário
  void _validateForm() {
    setState(() {
      _isValid =
          _formKey.currentState?.validate() == true && _selectedFile != null;
    });
  }

  /// Validar email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  /// Callback quando arquivo é selecionado
  void _onFileSelected(PlatformFile? file) {
    setState(() {
      _selectedFile = file;
    });
    _validateForm();
  }

  /// Submeter formulário
  void _submit() {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      widget.onSubmit(
        _purchaseEmailController.text.trim(),
        _selectedFile!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Solicitação de Certificação',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
          ),

          const SizedBox(height: 8),

          // Descrição
          Text(
            'Preencha os dados abaixo para solicitar sua certificação espiritual "Sinais de meu Isaque, Sinais de minha Rebeca".',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),

          const SizedBox(height: 24),

          // Email do App (pré-preenchido, somente leitura)
          Text(
            'Email no App',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _appEmailController,
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Seu email no aplicativo',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Email da Compra
          Text(
            'Email da Compra *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _purchaseEmailController,
            enabled: widget.enabled,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email usado na compra do curso',
              prefixIcon: Icon(
                Icons.shopping_cart_outlined,
                color: Colors.amber.shade700,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.amber.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: _validateEmail,
          ),

          const SizedBox(height: 8),

          // Dica sobre email da compra
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Informe o email que você usou para comprar a mentoria "Sinais de meu Isaque, Sinais de minha Rebeca"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Upload de Diploma
          Text(
            'Comprovante Diploma Sinais *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          FileUploadComponent(
            onFileSelected: _onFileSelected,
          ),

          const SizedBox(height: 24),

          // Botão de Enviar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isValid && widget.enabled) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isValid ? 4 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    color: _isValid ? Colors.white : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enviar Solicitação',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isValid ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nota sobre prazo
          Center(
            child: Text(
              'Você receberá resposta em até 3 dias úteis',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
