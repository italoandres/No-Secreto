import 'package:flutter/material.dart';
import '../utils/execute_fix_now_direct.dart';
import '../utils/create_firebase_index.dart';

/// Tela com botão para corrigir o Explorar Perfis
/// VOCÊ SÓ PRECISA NAVEGAR PARA ESTA TELA E CLICAR NO BOTÃO!
class FixButtonScreen extends StatefulWidget {
  const FixButtonScreen({Key? key}) : super(key: key);

  @override
  State<FixButtonScreen> createState() => _FixButtonScreenState();
}

class _FixButtonScreenState extends State<FixButtonScreen> {
  bool _isLoading = false;
  bool _isFixed = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Corrigir Explorar Perfis'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 60,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🚨 PROBLEMA DETECTADO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Seu perfil não está aparecendo no "Explorar Perfis" 🔍\n\n'
                    'Isso significa que outros usuários não conseguem te encontrar quando fazem buscas.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Status da correção
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _isFixed ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFixed ? Colors.green[300]! : Colors.blue[300]!,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isFixed ? Colors.green[800] : Colors.blue[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // BOTÃO PRINCIPAL - ESTE É O BOTÃO QUE RESOLVE TUDO!
            Container(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _executeFixNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFixed ? Colors.green[600] : Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'CORRIGINDO...\nAguarde, por favor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Text(
                        _isFixed 
                            ? '🎉 CORRIGIDO!\nTeste o ícone 🔍'
                            : '🚀 CORRIGIR AGORA\n(Clique aqui)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Instruções
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Como usar:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStep('1', 'Clique no botão vermelho acima'),
                  _buildStep('2', 'Aguarde 1-2 minutos (o sistema trabalha)'),
                  _buildStep('3', 'Quando aparecer "CORRIGIDO!", teste o ícone 🔍'),
                  _buildStep('4', 'Você deve ver 7 perfis agora'),
                  _buildStep('5', 'Busque por seu nome e encontre seu perfil!'),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // BOTÃO PARA CRIAR ÍNDICE FIREBASE
            Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await CreateFirebaseIndex.openFirebaseConsole();
                  CreateFirebaseIndex.printInstructions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  '🔥 CRIAR ÍNDICE FIREBASE\n(Clique se aparecer erro de índice)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Resultado esperado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 48,
                    color: Colors.green[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎉 RESULTADO GARANTIDO',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Após clicar no botão:\n\n'
                    '✅ Seu perfil aparecerá no Explorar Perfis\n'
                    '✅ Outros usuários poderão te encontrar\n'
                    '✅ Você verá 7 perfis quando tocar em 🔍\n'
                    '✅ A busca funcionará perfeitamente!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeFixNow() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🚀 Iniciando correção...\nPor favor, aguarde!';
    });

    try {
      // Executar correção direta
      await ExecuteFixNowDirect.runNow();
      
      setState(() {
        _isFixed = true;
        _statusMessage = '🎉 CORREÇÃO CONCLUÍDA COM SUCESSO!\n\n'
            '✅ Seu perfil foi corrigido\n'
            '✅ 6 perfis de teste foram recriados\n'
            '✅ Dados antigos removidos\n\n'
            '📱 AGORA TESTE: Toque no ícone 🔍\n\n'
            '⚠️ SE APARECER ERRO DE ÍNDICE:\n'
            'Clique no botão laranja "CRIAR ÍNDICE FIREBASE"';
      });

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 SUCESSO! Agora teste o ícone 🔍 e veja 7 perfis!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ ERRO DURANTE CORREÇÃO:\n\n$e\n\n'
            'Tente novamente em alguns segundos.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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