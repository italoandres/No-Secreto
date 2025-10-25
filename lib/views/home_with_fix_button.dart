import 'package:flutter/material.dart';
import '../utils/navigate_to_fix_screen.dart';

/// Tela principal com botão de correção automática
/// VOCÊ SÓ PRECISA USAR ESTA TELA - NÃO PRECISA ENTENDER O CÓDIGO!
class HomeWithFixButton extends StatelessWidget {
  const HomeWithFixButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu App'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Boas-vindas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.home,
                    size: 48,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '👋 Bem-vindo ao seu App!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua tela principal está funcionando perfeitamente!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Aviso sobre o problema
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ PROBLEMA DETECTADO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu perfil não está aparecendo no "Explorar Perfis" 🔍\n\n'
                    'Isso significa que outros usuários não conseguem te encontrar quando fazem buscas.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Solução
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    size: 40,
                    color: Colors.green[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '✅ SOLUÇÃO AUTOMÁTICA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Criamos uma correção automática que resolve tudo para você!\n\n'
                    '• Corrige seu perfil automaticamente\n'
                    '• Cria dados de teste\n'
                    '• Faz tudo funcionar\n'
                    '• Você não precisa fazer nada!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // BOTÃO PRINCIPAL - ESTE É O BOTÃO QUE RESOLVE TUDO!
            NavigateToFixScreen.buildNavigationButton(context),

            const SizedBox(height: 24),

            // Instruções simples
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Como usar (super fácil):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStep('1', 'Clique no botão azul acima'),
                  _buildStep(
                      '2', 'Na tela que abrir, clique no botão vermelho'),
                  _buildStep(
                      '3', 'Aguarde 1 minuto (o sistema faz tudo sozinho)'),
                  _buildStep('4', 'Teste o ícone 🔍 na barra superior'),
                  _buildStep('5', 'Pronto! Agora você aparece nas buscas!'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Resultado esperado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 40,
                    color: Colors.purple[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎉 RESULTADO GARANTIDO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Após usar o botão acima:\n\n'
                    '✅ Seu perfil aparecerá no Explorar Perfis\n'
                    '✅ Outros usuários poderão te encontrar\n'
                    '✅ Você verá 7 perfis quando tocar em 🔍\n'
                    '✅ Tudo funcionará perfeitamente!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple[700],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
