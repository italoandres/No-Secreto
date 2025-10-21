import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'deep_investigation_real_notifications.dart';

/// Widget de teste para investigação profunda
class TestDeepInvestigation extends StatelessWidget {
  const TestDeepInvestigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Investigação Profunda'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              '🔍 INVESTIGAÇÃO PROFUNDA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Procurar notificações REAIS do @italo2 para @itala',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                Get.snackbar(
                  '🔍 Investigação',
                  'Iniciando investigação profunda...',
                  backgroundColor: Colors.purple,
                  colorText: Colors.white,
                );
                
                await DeepInvestigationRealNotifications.runCompleteInvestigation();
                
                Get.snackbar(
                  '✅ Investigação',
                  'Investigação completa! Veja os logs no console.',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '🚀 EXECUTAR INVESTIGAÇÃO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}