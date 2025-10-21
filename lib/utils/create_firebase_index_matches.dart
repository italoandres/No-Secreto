import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilitário para criar índice do Firebase para matches aceitos
class CreateFirebaseIndexMatches {
  
  /// URL para criar o índice necessário para matches aceitos
  static const String indexUrl = 'https://console.firebase.google.com/v1/r/project/app-no-secreto-com-o-pai/firestore/indexes?create_composite=Cmdwcm9qZWN0cy9hcHAtbm8tc2VjcmV0by1jb20tby1wYWkvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2ludGVyZXN0X25vdGlmaWNhdGlvbnMvaW5kZXhlcy9fEAEaCgoGc3RhdHVzEAEaDAoIdG9Vc2VySWQQARoQCgxkYXRhUmVzcG9zdGEQAhoMCghfX25hbWVfXxAC';

  /// Abre o link para criar o índice no Firebase
  static Future<void> openIndexCreationLink() async {
    try {
      final uri = Uri.parse(indexUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Link do índice Firebase aberto com sucesso');
      } else {
        print('❌ Não foi possível abrir o link do índice');
        throw Exception('Não foi possível abrir o link');
      }
    } catch (e) {
      print('❌ Erro ao abrir link do índice: $e');
      rethrow;
    }
  }

  /// Mostra diálogo explicativo sobre o índice
  static void showIndexDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Índice Firebase Necessário'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para que os matches aceitos funcionem corretamente, é necessário criar um índice no Firebase.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Clique em "Criar Índice" para abrir o Firebase Console e criar o índice automaticamente.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Após criar o índice, pode levar alguns minutos para ficar ativo.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await openIndexCreationLink();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link do Firebase aberto! Crie o índice e aguarde alguns minutos.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao abrir link: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Criar Índice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Instruções para criar o índice manualmente
  static const String manualInstructions = '''
COMO CRIAR O ÍNDICE MANUALMENTE:

1. Acesse: https://console.firebase.google.com/project/app-no-secreto-com-o-pai/firestore/indexes

2. Clique em "Create Index"

3. Configure:
   - Collection: interest_notifications
   - Fields:
     * toUserId (Ascending)
     * status (Ascending) 
     * dataResposta (Descending)

4. Clique em "Create"

5. Aguarde alguns minutos para o índice ficar ativo
''';

  /// Copia as instruções para o clipboard
  static void copyInstructions() {
    // Implementar cópia para clipboard se necessário
    print('📋 Instruções copiadas:');
    print(manualInstructions);
  }
}