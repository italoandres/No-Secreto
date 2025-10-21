import 'package:flutter/material.dart';
import 'fix_existing_profile_for_exploration.dart';

/// Widget para corrigir perfil existente
class FixProfileWidget extends StatefulWidget {
  const FixProfileWidget({Key? key}) : super(key: key);

  @override
  State<FixProfileWidget> createState() => _FixProfileWidgetState();
}

class _FixProfileWidgetState extends State<FixProfileWidget> {
  String _status = 'Pronto para corrigir seu perfil';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrigir Perfil'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Instruções
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 O que será feito:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Verificar seu perfil de vitrine existente\n'
                    '• Corrigir campos necessários para exploração\n'
                    '• Adicionar palavras-chave de busca\n'
                    '• Criar registro de engajamento\n'
                    '• Testar visibilidade no sistema',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _runCompleteCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('🚀 CORRIGIR MEU PERFIL'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _checkVisibility,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('🔍 VERIFICAR VISIBILIDADE'),
              ),
            ],

            const SizedBox(height: 24),

            // Aviso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Importante:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta correção irá modificar seu perfil de vitrine existente para que ele apareça no sistema "Explorar Perfis". Seus dados pessoais não serão alterados, apenas campos técnicos necessários para o funcionamento.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runCompleteCheck() async {
    setState(() {
      _isLoading = true;
      _status = '🚀 Executando correção completa...';
    });

    try {
      await FixExistingProfileForExploration.runCompleteCheck();
      setState(() {
        _status = '🎉 Correção concluída!\n'
                  'Seu perfil agora deve aparecer no Explorar Perfis.\n'
                  'Teste tocando no ícone 🔍 na barra superior.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro durante correção: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkVisibility() async {
    setState(() {
      _isLoading = true;
      _status = '🔍 Verificando visibilidade...';
    });

    try {
      final isVisible = await FixExistingProfileForExploration.checkProfileVisibility();
      setState(() {
        _status = isVisible 
            ? '✅ Seu perfil está visível no Explorar Perfis!'
            : '❌ Seu perfil não está visível. Clique em "CORRIGIR MEU PERFIL".';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erro ao verificar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}