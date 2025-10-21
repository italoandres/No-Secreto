import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/simple_accepted_matches_repository.dart';

/// Utilitário para debugar o sistema de matches aceitos
class DebugAcceptedMatches {
  
  /// Testa o sistema completo de matches aceitos
  static Future<void> testCompleteSystem() async {
    try {
      print('🔍 === DEBUG MATCHES ACEITOS ===');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não está logado');
        return;
      }
      
      print('✅ Usuário logado: ${currentUser.uid}');
      
      // Testar repositório
      final repository = SimpleAcceptedMatchesRepository();
      print('🔍 Testando repositório...');
      
      final matches = await repository.getAcceptedMatches(currentUser.uid);
      print('📊 Matches encontrados: ${matches.length}');
      
      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        print('   Match $i:');
        print('     - ID: ${match.notificationId}');
        print('     - Outro usuário: ${match.otherUserName} (${match.otherUserId})');
        print('     - Chat ID: ${match.chatId}');
        print('     - Mensagens não lidas: ${match.unreadMessages}');
        print('     - Expirado: ${match.chatExpired}');
        print('     - Dias restantes: ${match.daysRemaining}');
      }
      
      print('🔍 === FIM DEBUG MATCHES ACEITOS ===');
      
      // Mostrar resultado na tela
      Get.snackbar(
        'Debug Matches Aceitos',
        'Encontrados ${matches.length} matches. Verifique o console para detalhes.',
        backgroundColor: matches.length > 0 ? Colors.green : Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );
      
    } catch (e) {
      print('❌ Erro no debug: $e');
      Get.snackbar(
        'Erro no Debug',
        'Erro: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Mostra diálogo de debug
  static void showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.blue),
            SizedBox(width: 8),
            Text('Debug Matches Aceitos'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este debug irá:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Verificar se o usuário está logado'),
            Text('• Testar o repositório de matches'),
            Text('• Listar todos os matches encontrados'),
            Text('• Mostrar detalhes de cada match'),
            SizedBox(height: 16),
            Text(
              'Os resultados aparecerão no console.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              await testCompleteSystem();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Executar Debug'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}