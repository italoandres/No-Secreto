import 'package:flutter/material.dart';
import '../utils/fix_existing_profile_for_exploration.dart';

/// Botão de acesso rápido para corrigir perfil
class QuickFixProfileButton extends StatefulWidget {
  const QuickFixProfileButton({Key? key}) : super(key: key);

  @override
  State<QuickFixProfileButton> createState() => _QuickFixProfileButtonState();
}

class _QuickFixProfileButtonState extends State<QuickFixProfileButton> {
  bool _isLoading = false;
  bool _isFixed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _fixProfile,
        icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_isFixed ? Icons.check_circle : Icons.build_circle),
        label: Text(
          _isLoading 
              ? 'Corrigindo...'
              : _isFixed 
                  ? 'Perfil Corrigido!'
                  : 'Corrigir Perfil 🔍',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFixed ? Colors.green[600] : Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _fixProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Executar correção completa
      await FixExistingProfileForExploration.runCompleteCheck();
      
      setState(() {
        _isFixed = true;
      });

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Perfil corrigido! Agora teste o ícone 🔍 na barra superior',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}