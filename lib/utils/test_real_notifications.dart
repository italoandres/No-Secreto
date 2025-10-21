import 'package:flutter/material.dart';
import '../utils/debug_real_notifications.dart';
import '../services/real_interest_notification_service.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar notificações reais diretamente
class TestRealNotifications {
  static final EnhancedLogger _logger = EnhancedLogger('TestRealNotifications');
  static final RealInterestNotificationService _service = RealInterestNotificationService();

  /// Executa teste completo e mostra resultados
  static Future<void> executeCompleteTest(BuildContext context, String userId) async {
    _logger.info('🚀 EXECUTANDO TESTE COMPLETO DE NOTIFICAÇÕES REAIS');
    
    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testando notificações reais...'),
            ],
          ),
        ),
      );

      // Executa debug completo
      await DebugRealNotifications.runCompleteDebug(userId);

      // Busca notificações
      final notifications = await _service.getRealInterestNotifications(userId);

      // Fecha loading
      Navigator.of(context).pop();

      // Mostra resultados
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Resultado do Teste'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✅ Teste concluído com sucesso!'),
                SizedBox(height: 16),
                Text('📊 Notificações encontradas: ${notifications.length}'),
                SizedBox(height: 16),
                if (notifications.isNotEmpty) ...[
                  Text('📧 Notificações:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...notifications.map((notification) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('• ${notification.fromUserName}: ${notification.message}'),
                  )),
                ] else ...[
                  Text('⚠️ Nenhuma notificação encontrada'),
                  SizedBox(height: 8),
                  Text('Verifique os logs para mais detalhes.'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      // Fecha loading se ainda estiver aberto
      Navigator.of(context).pop();
      
      // Mostra erro
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erro no Teste'),
          content: Text('❌ Erro ao executar teste: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      
      _logger.error('❌ Erro no teste completo', error: e);
    }
  }

  /// Teste rápido sem UI
  static Future<void> quickTest(String userId) async {
    await DebugRealNotifications.quickTest(userId);
  }

  /// Cria interesse de teste
  static Future<void> createTestInterest(BuildContext context, String fromUserId, String toUserId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Criando interesse de teste...'),
            ],
          ),
        ),
      );

      await DebugRealNotifications.createTestInterest(fromUserId, toUserId);

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sucesso'),
          content: Text('✅ Interesse de teste criado com sucesso!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erro'),
          content: Text('❌ Erro ao criar interesse de teste: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Widget de teste para incluir na UI
  static Widget buildTestWidget(BuildContext context, String userId) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Teste de Notificações Reais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text('Usuário: $userId'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => executeCompleteTest(context, userId),
                    child: Text('Teste Completo'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => quickTest(userId),
                    child: Text('Teste Rápido'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCreateTestDialog(context, userId),
                child: Text('Criar Interesse de Teste'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra dialog para criar interesse de teste
  static void _showCreateTestDialog(BuildContext context, String toUserId) {
    final TextEditingController fromController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Criar Interesse de Teste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Para: $toUserId'),
            SizedBox(height: 16),
            TextField(
              controller: fromController,
              decoration: InputDecoration(
                labelText: 'ID do usuário que vai demonstrar interesse',
                hintText: 'Ex: gSb3IzY7nzWA0OQqKdrpB5V8Rgj2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (fromController.text.isNotEmpty) {
                createTestInterest(context, fromController.text, toUserId);
              }
            },
            child: Text('Criar'),
          ),
        ],
      ),
    );
  }
}