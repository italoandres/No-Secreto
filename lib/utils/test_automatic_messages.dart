import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/services/automatic_message_service.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';

class TestAutomaticMessages {
  
  // Testar envio imediato de mensagem automática
  static Future<void> testImmediateMessage() async {
    try {
      Get.rawSnackbar(
        message: 'Enviando mensagem automática de teste...',
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      );
      
      await AutomaticMessageService.sendImmediateTestMessage();
      
      Get.rawSnackbar(
        message: '✅ Mensagem automática enviada com sucesso!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.rawSnackbar(
        message: '❌ Erro ao enviar mensagem automática: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  // Verificar status do timer
  static Future<void> checkTimerStatus() async {
    try {
      final hasPending = await AutomaticMessageService.hasPendingMessages();
      final timeUntil = AutomaticMessageService.getTimeUntilNextMessage();
      
      String message = hasPending 
        ? '⏰ Timer ativo - Próxima mensagem em: ${timeUntil?.inHours ?? 0}h'
        : '⏸️ Timer inativo';
        
      Get.rawSnackbar(
        message: message,
        backgroundColor: hasPending ? Colors.orange : Colors.grey,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.rawSnackbar(
        message: '❌ Erro ao verificar status: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  // Resetar timer manualmente
  static void resetTimer() {
    try {
      AutomaticMessageService.resetInactivityTimer();
      
      Get.rawSnackbar(
        message: '🔄 Timer resetado com sucesso!',
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      Get.rawSnackbar(
        message: '❌ Erro ao resetar timer: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  // Testar mensagem específica para um contexto
  static Future<void> testContextMessage(String contexto) async {
    try {
      Get.rawSnackbar(
        message: 'Enviando mensagem para contexto: $contexto',
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      );
      
      await ChatRepository.sendAutomaticPaiMessageToContext(contexto);
      
      Get.rawSnackbar(
        message: '✅ Mensagem enviada para $contexto!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.rawSnackbar(
        message: '❌ Erro ao enviar para $contexto: $e',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  // Widget de teste para debug
  static Widget buildTestWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Teste de Mensagens Automáticas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: testImmediateMessage,
            child: const Text('Enviar Mensagem Imediata'),
          ),
          
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: checkTimerStatus,
            child: const Text('Verificar Status do Timer'),
          ),
          
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: resetTimer,
            child: const Text('Resetar Timer'),
          ),
          
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => testContextMessage('sinais_isaque'),
            child: const Text('Testar Sinais Isaque'),
          ),
          
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: () => testContextMessage('sinais_rebeca'),
            child: const Text('Testar Sinais Rebeca'),
          ),
        ],
      ),
    );
  }
  
  // Mostrar dialog de teste
  static void showTestDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Teste de Mensagens Automáticas'),
        content: buildTestWidget(),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}