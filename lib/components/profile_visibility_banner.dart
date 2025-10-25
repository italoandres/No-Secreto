import 'package:flutter/material.dart';
import '../utils/fix_existing_profile_for_exploration.dart';

/// Banner que aparece quando o perfil não está visível no Explorar Perfis
class ProfileVisibilityBanner extends StatefulWidget {
  const ProfileVisibilityBanner({Key? key}) : super(key: key);

  @override
  State<ProfileVisibilityBanner> createState() =>
      _ProfileVisibilityBannerState();
}

class _ProfileVisibilityBannerState extends State<ProfileVisibilityBanner> {
  bool _isVisible = true;
  bool _isLoading = false;
  bool _isFixed = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    try {
      final isVisible =
          await FixExistingProfileForExploration.checkProfileVisibility();
      if (mounted) {
        setState(() {
          _isVisible = isVisible;
        });
      }
    } catch (e) {
      // Em caso de erro, assumir que não está visível
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se está visível ou já foi corrigido, não mostrar banner
    if (_isVisible || _isFixed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seu perfil não está aparecendo no "Explorar Perfis" 🔍',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no botão abaixo para corrigir automaticamente e aparecer nas buscas de outros usuários.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fixProfile,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                _isLoading ? 'Corrigindo...' : '🚀 Corrigir Agora',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fixProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FixExistingProfileForExploration.runCompleteCheck();

      setState(() {
        _isFixed = true;
      });

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Perfil corrigido! Agora você aparece no Explorar Perfis. Teste o ícone 🔍!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
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
