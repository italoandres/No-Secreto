import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/repositories/chat_repository.dart';
import 'package:whatsapp_chat/token_usuario.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';

class AutomaticMessageService {
  static Timer? _timer;
  static const Duration _inactivityDuration = Duration(days: 3);
  
  // Inicializar o serviço de mensagens automáticas
  static void initialize() {
    _startInactivityTimer();
  }

  // Parar o serviço
  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // Resetar o timer quando o usuário enviar uma mensagem
  static void resetInactivityTimer() {
    _timer?.cancel();
    _startInactivityTimer();
  }

  // Iniciar o timer de inatividade
  static void _startInactivityTimer() {
    _timer = Timer(_inactivityDuration, () async {
      await _sendAutomaticMessages();
    });
  }

  // Enviar mensagens automáticas para todos os contextos
  static Future<void> _sendAutomaticMessages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Verificar se o usuário realmente está inativo há 3 dias
      final isInactive = await _checkUserInactivity();
      if (!isInactive) return;

      // Enviar mensagem para o chat principal
      await ChatRepository.sendAutomaticPaiMessage();

      // Enviar mensagem para Sinais de Isaque
      await ChatRepository.sendAutomaticPaiMessageToContext('sinais_isaque');

      // Enviar mensagem para Sinais de Rebeca
      await ChatRepository.sendAutomaticPaiMessageToContext('sinais_rebeca');

      print('Mensagens automáticas do Pai enviadas após 3 dias de inatividade');
      
      // Reiniciar o timer para o próximo ciclo
      _startInactivityTimer();
      
    } catch (e) {
      print('Erro ao enviar mensagens automáticas: $e');
      // Reiniciar o timer mesmo em caso de erro
      _startInactivityTimer();
    }
  }

  // Verificar se o usuário está realmente inativo há 3 dias
  static Future<bool> _checkUserInactivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      // Verificar atividade no chat principal
      final chatQuery = await FirebaseFirestore.instance
          .collection('chat')
          .where('idDe', isEqualTo: user.uid)
          .where('dataCadastro', isGreaterThan: threeDaysAgo)
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) return false;

      // Verificar atividade no chat Sinais de Isaque
      final sinaisIsaqueQuery = await FirebaseFirestore.instance
          .collection('chat_sinais_isaque')
          .where('idDe', isEqualTo: user.uid)
          .where('dataCadastro', isGreaterThan: threeDaysAgo)
          .limit(1)
          .get();

      if (sinaisIsaqueQuery.docs.isNotEmpty) return false;

      // Verificar atividade no chat Sinais de Rebeca
      final sinaisRebecaQuery = await FirebaseFirestore.instance
          .collection('chat_sinais_rebeca')
          .where('idDe', isEqualTo: user.uid)
          .where('dataCadastro', isGreaterThan: threeDaysAgo)
          .limit(1)
          .get();

      if (sinaisRebecaQuery.docs.isNotEmpty) return false;

      // Se não encontrou atividade em nenhum chat, usuário está inativo
      return true;
      
    } catch (e) {
      print('Erro ao verificar inatividade do usuário: $e');
      return false;
    }
  }

  // Método para enviar mensagem imediata (para testes)
  static Future<void> sendImmediateTestMessage() async {
    await _sendAutomaticMessages();
  }

  // Verificar se há mensagens pendentes para envio
  static Future<bool> hasPendingMessages() async {
    return _timer != null && _timer!.isActive;
  }

  // Obter tempo restante até a próxima mensagem
  static Duration? getTimeUntilNextMessage() {
    if (_timer == null || !_timer!.isActive) return null;
    
    // Como Timer não expõe o tempo restante, retornamos uma estimativa
    // baseada no tempo de inatividade configurado
    return _inactivityDuration;
  }
}