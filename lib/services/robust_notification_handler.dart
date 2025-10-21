import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_chat_creator.dart';

/// Serviço robusto para tratamento de notificações sem duplicatas
class RobustNotificationHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Responde a uma notificação de forma robusta, evitando exceções de duplicata
  static Future<void> respondToNotification(String notificationId, String action) async {
    try {
      print('📝 Respondendo à notificação: $notificationId com ação: $action');
      
      final notificationRef = _firestore
          .collection('interests')
          .doc(notificationId);
      
      // Verificar estado atual da notificação
      final notificationDoc = await notificationRef.get();
      
      if (!notificationDoc.exists) {
        print('❌ Notificação não encontrada: $notificationId');
        throw Exception('Notificação não encontrada');
      }
      
      final notificationData = notificationDoc.data()!;
      final currentStatus = notificationData['status'];
      final fromUserId = notificationData['fromUserId'];
      final toUserId = notificationData['toUserId'];
      
      print('📊 Status atual da notificação: $currentStatus');
      
      // Se já foi respondida, tratar graciosamente
      if (currentStatus == 'accepted' || currentStatus == 'rejected') {
        print('ℹ️ Notificação já foi respondida com status: $currentStatus');
        
        // Se foi aceita e estamos aceitando novamente, é match mútuo
        if (currentStatus == 'accepted' && action == 'accepted') {
          print('💕 Detectado match mútuo! Criando chat...');
          
          if (fromUserId != null && toUserId != null) {
            await MatchChatCreator.createChatOnMutualMatch(fromUserId, toUserId);
          }
        }
        
        // Não gerar exceção, apenas retornar graciosamente
        return;
      }
      
      // Atualizar status da notificação
      await notificationRef.update({
        'status': action,
        'dataResposta': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notificação atualizada: $notificationId → $action');
      
      // Se aceito, verificar match mútuo e criar chat
      if (action == 'accepted') {
        await _checkMutualInterestAndCreateChat(notificationData);
      }
      
    } catch (e) {
      print('❌ Erro ao responder notificação: $e');
      
      // Se for erro de notificação já respondida, não propagar
      if (e.toString().contains('já foi respondida')) {
        print('ℹ️ Tratando erro de notificação duplicada graciosamente');
        return;
      }
      
      // Para outros erros, tentar novamente
      await Future.delayed(Duration(seconds: 1));
      await _retryRespondNotification(notificationId, action);
    }
  }

  /// Verifica interesse mútuo e cria chat se necessário
  static Future<void> _checkMutualInterestAndCreateChat(Map<String, dynamic> notificationData) async {
    try {
      final fromUserId = notificationData['fromUserId'];
      final toUserId = notificationData['toUserId'];
      
      if (fromUserId == null || toUserId == null) {
        print('❌ IDs de usuário inválidos para verificação de match mútuo');
        return;
      }
      
      print('🔍 Verificando interesse mútuo entre $fromUserId e $toUserId');
      
      // Buscar notificação reversa (de toUserId para fromUserId)
      final reverseQuery = await _firestore
          .collection('interests')
          .where('fromUserId', isEqualTo: toUserId)
          .where('toUserId', isEqualTo: fromUserId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      if (reverseQuery.docs.isNotEmpty) {
        print('💕 Match mútuo confirmado! Criando chat...');
        await MatchChatCreator.createChatOnMutualMatch(fromUserId, toUserId);
      } else {
        print('ℹ️ Interesse aceito, mas ainda não é mútuo');
      }
      
    } catch (e) {
      print('❌ Erro ao verificar interesse mútuo: $e');
    }
  }

  /// Retry para resposta de notificação
  static Future<void> _retryRespondNotification(String notificationId, String action, {int attempts = 0}) async {
    if (attempts >= 2) {
      print('❌ Falha ao responder notificação após 2 tentativas');
      return;
    }
    
    try {
      await respondToNotification(notificationId, action);
    } catch (e) {
      print('🔄 Tentativa ${attempts + 1} falhou, tentando novamente...');
      await Future.delayed(Duration(seconds: 1));
      await _retryRespondNotification(notificationId, action, attempts: attempts + 1);
    }
  }

  /// Verifica se uma notificação já foi respondida
  static Future<bool> isNotificationAlreadyResponded(String notificationId) async {
    try {
      final notificationDoc = await _firestore
          .collection('interests')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        return false;
      }
      
      final status = notificationDoc.data()?['status'];
      return status == 'accepted' || status == 'rejected';
      
    } catch (e) {
      print('❌ Erro ao verificar status da notificação: $e');
      return false;
    }
  }
}