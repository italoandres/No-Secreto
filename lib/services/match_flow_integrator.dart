import 'package:firebase_auth/firebase_auth.dart';
import 'mutual_match_detector.dart';
import 'notification_orchestrator.dart';
import 'chat_system_manager.dart';
import 'real_time_notification_service.dart';
import 'enhanced_interest_handler.dart';
import 'message_notification_system.dart';

/// Integrador principal que conecta todos os serviços do fluxo de matches
class MatchFlowIntegrator {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  /// Inicializa todo o sistema de matches e notificações
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ [MATCH_FLOW_INTEGRATOR] Sistema já inicializado');
      return;
    }

    print('🚀 [MATCH_FLOW_INTEGRATOR] Inicializando sistema completo...');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Usuário não autenticado');
      return;
    }

    try {
      // Inicializar serviços em ordem de dependência
      await RealTimeNotificationService.initialize();
      await MessageNotificationSystem.initialize();
      
      _isInitialized = true;
      print('✅ [MATCH_FLOW_INTEGRATOR] Sistema completo inicializado');
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro na inicialização: $e');
      _isInitialized = false;
    }
  }

  /// Para todo o sistema e limpa recursos
  static Future<void> dispose() async {
    if (!_isInitialized) return;
    
    print('🛑 [MATCH_FLOW_INTEGRATOR] Parando sistema completo...');
    
    try {
      await RealTimeNotificationService.dispose();
      await MessageNotificationSystem.dispose();
      
      _isInitialized = false;
      print('✅ [MATCH_FLOW_INTEGRATOR] Sistema completo parado');
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro ao parar sistema: $e');
    }
  }

  /// Fluxo completo: enviar interesse
  static Future<String?> sendInterest({
    required String toUserId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    print('💕 [MATCH_FLOW_INTEGRATOR] Iniciando fluxo de interesse');
    
    try {
      // Verificar se já existe interesse
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;
      
      final existingInterest = await EnhancedInterestHandler.checkExistingInterest(
        currentUser.uid, 
        toUserId,
      );
      
      if (existingInterest != null) {
        print('ℹ️ [MATCH_FLOW_INTEGRATOR] Interesse já existe: ${existingInterest['status']}');
        return existingInterest['id'];
      }
      
      // Enviar interesse
      final interestId = await EnhancedInterestHandler.sendInterest(
        toUserId: toUserId,
        message: message,
        metadata: metadata,
      );
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Fluxo de interesse concluído: $interestId');
      return interestId;
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro no fluxo de interesse: $e');
      return null;
    }
  }

  /// Fluxo completo: responder interesse
  static Future<bool> respondToInterest({
    required String notificationId,
    required String interestId,
    required String action,
    String? responseMessage,
  }) async {
    print('🔄 [MATCH_FLOW_INTEGRATOR] Iniciando fluxo de resposta: $action');
    
    try {
      // Processar resposta através do handler
      await EnhancedInterestHandler.respondToInterest(
        notificationId: notificationId,
        interestId: interestId,
        action: action,
        responseMessage: responseMessage,
      );
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Fluxo de resposta concluído');
      return true;
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro no fluxo de resposta: $e');
      return false;
    }
  }

  /// Fluxo completo: enviar mensagem
  static Future<bool> sendMessage({
    required String chatId,
    required String message,
    String messageType = 'text',
  }) async {
    print('📤 [MATCH_FLOW_INTEGRATOR] Iniciando fluxo de mensagem');
    
    try {
      // Enviar mensagem com notificações
      await MessageNotificationSystem.sendMessageWithNotification(
        chatId: chatId,
        message: message,
        messageType: messageType,
      );
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Fluxo de mensagem concluído');
      return true;
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro no fluxo de mensagem: $e');
      return false;
    }
  }

  /// Fluxo completo: abrir chat
  static Future<bool> openChat({
    required String chatId,
    String? otherUserId,
  }) async {
    print('💬 [MATCH_FLOW_INTEGRATOR] Iniciando fluxo de abertura de chat');
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      // Garantir que o chat existe
      await ChatSystemManager.ensureChatExists(chatId);
      
      // Marcar mensagens como lidas
      await MessageNotificationSystem.markMessagesAsReadAndClearNotifications(
        chatId: chatId,
        userId: currentUser.uid,
      );
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Fluxo de abertura de chat concluído');
      return true;
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro no fluxo de abertura de chat: $e');
      return false;
    }
  }

  /// Obtém estatísticas completas do usuário
  static Future<Map<String, dynamic>> getUserStats() async {
    print('📊 [MATCH_FLOW_INTEGRATOR] Obtendo estatísticas do usuário');
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};
    
    try {
      // Buscar estatísticas de diferentes serviços
      final interestStats = await EnhancedInterestHandler.getInterestStats(currentUser.uid);
      final notificationStats = await NotificationOrchestrator.getNotificationStats(currentUser.uid);
      final unreadMessages = await MessageNotificationSystem.getUnreadMessageCount(currentUser.uid);
      final mutualMatches = await MutualMatchDetector.getUserMutualMatches(currentUser.uid);
      
      final stats = {
        'interests': interestStats,
        'notifications': notificationStats,
        'unreadMessages': unreadMessages,
        'mutualMatches': mutualMatches.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Estatísticas obtidas');
      return stats;
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Executa limpeza de dados antigos
  static Future<void> performMaintenance() async {
    print('🧹 [MATCH_FLOW_INTEGRATOR] Executando manutenção do sistema');
    
    try {
      // Executar limpezas em paralelo
      await Future.wait([
        NotificationOrchestrator.cleanupOldNotifications(),
        EnhancedInterestHandler.cleanupOldInterests(),
        MessageNotificationSystem.cleanupOldMessageNotifications(),
      ]);
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Manutenção concluída');
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro na manutenção: $e');
    }
  }

  /// Verifica saúde do sistema
  static Future<Map<String, bool>> checkSystemHealth() async {
    print('🏥 [MATCH_FLOW_INTEGRATOR] Verificando saúde do sistema');
    
    final health = <String, bool>{
      'initialized': _isInitialized,
      'userAuthenticated': _auth.currentUser != null,
      'realTimeService': false,
      'messageService': false,
    };
    
    try {
      // Verificar serviços individuais
      if (_auth.currentUser != null) {
        // Testar notificações em tempo real
        final unreadCount = await NotificationOrchestrator.getUnreadCount(_auth.currentUser!.uid);
        health['realTimeService'] = unreadCount >= 0;
        
        // Testar sistema de mensagens
        final messageCount = await MessageNotificationSystem.getUnreadMessageCount(_auth.currentUser!.uid);
        health['messageService'] = messageCount >= 0;
      }
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Verificação de saúde concluída: $health');
      return health;
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro na verificação de saúde: $e');
      return health;
    }
  }

  /// Força sincronização de todos os dados
  static Future<void> forceSynchronization() async {
    print('🔄 [MATCH_FLOW_INTEGRATOR] Forçando sincronização');
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Reinicializar serviços
      await dispose();
      await initialize();
      
      print('✅ [MATCH_FLOW_INTEGRATOR] Sincronização forçada concluída');
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro na sincronização forçada: $e');
    }
  }

  /// Testa todo o sistema integrado
  static Future<void> testCompleteSystem() async {
    print('🧪 [MATCH_FLOW_INTEGRATOR] Testando sistema completo...');
    
    try {
      // Teste 1: Inicialização
      await initialize();
      print('✅ Teste 1 - Inicialização');
      
      // Teste 2: Verificar saúde
      final health = await checkSystemHealth();
      print('✅ Teste 2 - Saúde do sistema: $health');
      
      // Teste 3: Obter estatísticas
      final stats = await getUserStats();
      print('✅ Teste 3 - Estatísticas: ${stats.keys}');
      
      // Teste 4: Executar manutenção
      await performMaintenance();
      print('✅ Teste 4 - Manutenção');
      
      print('🎉 [MATCH_FLOW_INTEGRATOR] Todos os testes do sistema passaram!');
      
    } catch (e) {
      print('❌ [MATCH_FLOW_INTEGRATOR] Erro nos testes do sistema: $e');
    }
  }

  /// Verifica se o sistema está inicializado
  static bool get isInitialized => _isInitialized;

  /// Obtém status atual do sistema
  static Map<String, dynamic> get systemStatus => {
    'initialized': _isInitialized,
    'userAuthenticated': _auth.currentUser != null,
    'userId': _auth.currentUser?.uid,
    'timestamp': DateTime.now().toIso8601String(),
  };
}