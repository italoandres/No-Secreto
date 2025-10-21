import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Serviço para gerenciar status de leitura de mensagens
class MessageReadStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Marcar mensagem como lida
  static Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      EnhancedLogger.info('Marcando mensagem como lida: $messageId', 
        tag: 'MESSAGE_READ_STATUS');
      
      await _firestore
          .collection('chat_messages')
          .doc(messageId)
          .update({
        'readBy.$userId': FieldValue.serverTimestamp(),
        'isRead': true,
      });
      
      EnhancedLogger.info('Mensagem marcada como lida com sucesso', 
        tag: 'MESSAGE_READ_STATUS');
        
    } catch (e) {
      EnhancedLogger.error('Erro ao marcar mensagem como lida: $e', 
        tag: 'MESSAGE_READ_STATUS');
      rethrow;
    }
  }
  
  /// Marcar todas as mensagens de um chat como lidas
  static Future<void> markAllMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      EnhancedLogger.info('Marcando todas as mensagens como lidas para chat: $chatId', 
        tag: 'MESSAGE_READ_STATUS');
      
      // Buscar mensagens não lidas do chat
      final unreadMessages = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId) // Não marcar próprias mensagens
          .where('readBy.$userId', isNull: true)
          .get();
      
      if (unreadMessages.docs.isEmpty) {
        EnhancedLogger.info('Nenhuma mensagem não lida encontrada', 
          tag: 'MESSAGE_READ_STATUS');
        return;
      }
      
      // Criar batch para atualizar todas as mensagens
      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy.$userId': FieldValue.serverTimestamp(),
          'isRead': true,
        });
      }
      
      await batch.commit();
      
      // Atualizar contador no chat
      await _updateUnreadCount(chatId, userId);
      
      EnhancedLogger.info('${unreadMessages.docs.length} mensagens marcadas como lidas', 
        tag: 'MESSAGE_READ_STATUS');
        
    } catch (e) {
      EnhancedLogger.error('Erro ao marcar todas as mensagens como lidas: $e', 
        tag: 'MESSAGE_READ_STATUS');
      rethrow;
    }
  }
  
  /// Atualizar contador de mensagens não lidas
  static Future<void> _updateUnreadCount(String chatId, String userId) async {
    try {
      // Contar mensagens não lidas
      final unreadCount = await getUnreadCount(chatId, userId);
      
      // Atualizar contador no documento do chat
      await _firestore
          .collection('match_chats')
          .doc(chatId)
          .update({
        'unreadCount.$userId': unreadCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      EnhancedLogger.info('Contador atualizado: $unreadCount mensagens não lidas', 
        tag: 'MESSAGE_READ_STATUS');
        
    } catch (e) {
      EnhancedLogger.error('Erro ao atualizar contador: $e', 
        tag: 'MESSAGE_READ_STATUS');
    }
  }
  
  /// Obter número de mensagens não lidas
  static Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('readBy.$userId', isNull: true)
          .get();
      
      return unreadMessages.docs.length;
    } catch (e) {
      EnhancedLogger.error('Erro ao obter contador de não lidas: $e', 
        tag: 'MESSAGE_READ_STATUS');
      return 0;
    }
  }
  
  /// Stream para monitorar mudanças no status de leitura
  static Stream<int> watchUnreadCount(String chatId, String userId) {
    return _firestore
        .collection('chat_messages')
        .where('chatId', isEqualTo: chatId)
        .where('senderId', isNotEqualTo: userId)
        .where('readBy.$userId', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  /// Verificar se mensagem foi lida por usuário específico
  static Future<bool> isMessageReadBy(String messageId, String userId) async {
    try {
      final doc = await _firestore
          .collection('chat_messages')
          .doc(messageId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
      
      return readBy.containsKey(userId);
    } catch (e) {
      EnhancedLogger.error('Erro ao verificar status de leitura: $e', 
        tag: 'MESSAGE_READ_STATUS');
      return false;
    }
  }
  
  /// Marcar mensagem como lida com debounce
  static final Map<String, DateTime> _lastMarkTime = {};
  static const Duration _debounceDelay = Duration(seconds: 2);
  
  static Future<void> markMessageAsReadWithDebounce({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    final key = '$chatId-$messageId-$userId';
    final now = DateTime.now();
    
    // Verificar se já foi marcada recentemente
    if (_lastMarkTime.containsKey(key)) {
      final lastTime = _lastMarkTime[key]!;
      if (now.difference(lastTime) < _debounceDelay) {
        EnhancedLogger.debug('Debounce ativo, ignorando marcação', 
          tag: 'MESSAGE_READ_STATUS');
        return;
      }
    }
    
    _lastMarkTime[key] = now;
    
    // Aguardar delay do debounce
    await Future.delayed(_debounceDelay);
    
    // Verificar se não houve nova tentativa durante o delay
    if (_lastMarkTime[key] == now) {
      await markMessageAsRead(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
      );
    }
  }
  
  /// Limpar cache de debounce
  static void clearDebounceCache() {
    _lastMarkTime.clear();
  }
  
  /// Obter estatísticas de leitura do chat
  static Future<Map<String, dynamic>> getChatReadStats(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chat_messages')
          .where('chatId', isEqualTo: chatId)
          .get();
      
      int totalMessages = messages.docs.length;
      int readMessages = 0;
      
      for (final doc in messages.docs) {
        final data = doc.data();
        final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
        if (readBy.isNotEmpty) {
          readMessages++;
        }
      }
      
      return {
        'totalMessages': totalMessages,
        'readMessages': readMessages,
        'unreadMessages': totalMessages - readMessages,
        'readPercentage': totalMessages > 0 ? (readMessages / totalMessages * 100).round() : 0,
      };
    } catch (e) {
      EnhancedLogger.error('Erro ao obter estatísticas de leitura: $e', 
        tag: 'MESSAGE_READ_STATUS');
      return {
        'totalMessages': 0,
        'readMessages': 0,
        'unreadMessages': 0,
        'readPercentage': 0,
      };
    }
  }
}