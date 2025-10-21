import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// FORÇA NOTIFICAÇÕES REAIS - VERSÃO SIMPLES
class ForceNotificationsNow {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// FORÇA as notificações a aparecerem AGORA
  static Future<void> execute(String userId) async {
    EnhancedLogger.info('🚀 FORÇANDO NOTIFICAÇÕES PARA: $userId');
    
    try {
      // 1. Cria usuário de teste primeiro
      await _firestore.collection('usuarios').doc('test_user_force').set({
        'nome': '🚀 Sistema Teste',
        'username': 'sistema_teste',
        'email': 'teste@sistema.com',
        'createdAt': Timestamp.now(),
      });
      
      // 2. Cria interesse no formato correto para o componente
      await _firestore.collection('interests').add({
        'fromUserId': 'test_user_force',
        'targetUserId': userId,
        'from': 'test_user_force',
        'to': userId,
        'timestamp': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'message': 'NOTIFICAÇÃO FORÇADA - TESTE',
        'type': 'forced_test',
        'isTest': true,
      });
      
      // 3. Cria like no formato correto
      await _firestore.collection('likes').add({
        'fromUserId': 'test_user_force',
        'targetUserId': userId,
        'userId': 'test_user_force',
        'timestamp': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'type': 'like',
        'isTest': true,
      });
      
      // 4. Cria user_interaction no formato correto
      await _firestore.collection('user_interactions').add({
        'fromUserId': 'test_user_force',
        'targetUserId': userId,
        'sourceUserId': 'test_user_force',
        'timestamp': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'type': 'interest',
        'action': 'show_interest',
        'isTest': true,
      });
      
      EnhancedLogger.success('✅ NOTIFICAÇÕES FORÇADAS CRIADAS NO FORMATO CORRETO!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro ao forçar notificações', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Limpa notificações de teste
  static Future<void> clean() async {
    try {
      // Remove interests de teste
      final interests = await _firestore
          .collection('interests')
          .where('isTest', isEqualTo: true)
          .get();
          
      for (final doc in interests.docs) {
        await doc.reference.delete();
      }
      
      // Remove notificações de teste
      final notifications = await _firestore
          .collection('real_notifications')
          .where('isTest', isEqualTo: true)
          .get();
          
      for (final doc in notifications.docs) {
        await doc.reference.delete();
      }
      
      EnhancedLogger.success('🧹 Notificações de teste removidas');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro na limpeza', error: e, stackTrace: stackTrace);
    }
  }
}