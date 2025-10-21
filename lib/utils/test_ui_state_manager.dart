import 'dart:async';
import '../services/ui_state_manager.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar o gerenciador de estado da interface
class TestUIStateManager {
  static final UIStateManager _uiStateManager = UIStateManager();

  /// Testa o gerenciador de estado completo
  static Future<void> testCompleteUIState(String userId) async {
    EnhancedLogger.log('🧪 [TEST_UI] Iniciando teste completo do UI State Manager para: $userId');
    
    try {
      // 1. Testa stream de estado
      await _testUIStateStream(userId);
      
      // 2. Testa sincronização forçada
      await _testForceSync(userId);
      
      // 3. Testa feedback visual
      await _testVisualFeedback(userId);
      
      // 4. Testa tratamento de erros
      await _testErrorHandling(userId);
      
      // 5. Testa estatísticas
      _testUIStats();
      
      EnhancedLogger.log('✅ [TEST_UI] Todos os testes do UI State Manager passaram!');
      
    } catch (e) {
      EnhancedLogger.log('❌ [TEST_UI] Erro nos testes: $e');
      rethrow;
    }
  }

  /// Testa stream de estado da interface
  static Future<void> _testUIStateStream(String userId) async {
    EnhancedLogger.log('📡 [TEST_UI] Testando stream de estado...');
    
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = _uiStateManager
        .getUIStateStream(userId)
        .timeout(const Duration(seconds: 10))
        .listen(
          (state) {
            EnhancedLogger.log('✅ [TEST_UI] Estado recebido: ${state.syncStatus} | ${state.totalCount} notificações');
            
            // Valida estrutura do estado
            _validateUIState(state);
            
            subscription.cancel();
            completer.complete();
          },
          onError: (error) {
            EnhancedLogger.log('❌ [TEST_UI] Erro no stream: $error');
            subscription.cancel();
            completer.completeError(error);
          },
        );
    
    await completer.future;
  }

  /// Valida estrutura do estado da interface
  static void _validateUIState(NotificationUIState state) {
    assert(state.notifications != null, 'Notificações não podem ser null');
    assert(state.syncStatus != null, 'Status de sync não pode ser null');
    assert(state.lastUpdate != null, 'LastUpdate não pode ser null');
    assert(state.totalCount >= 0, 'TotalCount deve ser >= 0');
    assert(state.totalCount == state.notifications.length, 'TotalCount deve corresponder ao tamanho da lista');
    
    EnhancedLogger.log('✅ [TEST_UI] Estado validado com sucesso');
  }

  /// Testa sincronização forçada
  static Future<void> _testForceSync(String userId) async {
    EnhancedLogger.log('🚀 [TEST_UI] Testando sincronização forçada...');
    
    // Monitora mudanças de estado durante sync
    final stateChanges = <NotificationUIState>[];
    late StreamSubscription subscription;
    
    subscription = _uiStateManager
        .getUIStateStream(userId)
        .listen((state) {
          stateChanges.add(state);
          EnhancedLogger.log('📊 [TEST_UI] Estado durante sync: ${state.syncStatus} | Loading: ${state.isLoading}');
        });
    
    // Executa força sync
    await _uiStateManager.forceSync(userId);
    
    // Aguarda um pouco para capturar mudanças
    await Future.delayed(const Duration(seconds: 2));
    
    subscription.cancel();
    
    // Valida que houve mudanças de estado
    assert(stateChanges.isNotEmpty, 'Deve haver mudanças de estado durante sync');
    
    // Verifica se passou por estado de loading
    final hadLoadingState = stateChanges.any((state) => state.isLoading);
    assert(hadLoadingState, 'Deve ter passado por estado de loading');
    
    EnhancedLogger.log('✅ [TEST_UI] Sincronização forçada testada com sucesso');
  }

  /// Testa feedback visual
  static Future<void> _testVisualFeedback(String userId) async {
    EnhancedLogger.log('✨ [TEST_UI] Testando feedback visual...');
    
    // Testa diferentes status
    final statusesToTest = [
      SyncStatus.syncing,
      SyncStatus.synced,
      SyncStatus.error,
      SyncStatus.conflict,
    ];
    
    for (final status in statusesToTest) {
      _uiStateManager.showSyncStatus(userId, status, message: 'Teste de status: $status');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentState = _uiStateManager.getCurrentState(userId);
      assert(currentState?.syncStatus == status, 'Status deve ser atualizado para $status');
      
      EnhancedLogger.log('✅ [TEST_UI] Status $status testado');
    }
    
    // Testa atualização de notificações
    final testNotifications = [
      RealNotificationModel(
        id: 'test1',
        fromUserId: 'user1',
        fromUserName: 'Usuário Teste 1',
        message: 'Teste de notificação 1',
        timestamp: DateTime.now(),
        isRead: false,
        type: 'interest',
        count: 1,
      ),
      RealNotificationModel(
        id: 'test2',
        fromUserId: 'user2',
        fromUserName: 'Usuário Teste 2',
        message: 'Teste de notificação 2',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        type: 'interest',
        count: 2,
      ),
    ];
    
    _uiStateManager.updateNotificationState(userId, testNotifications);
    
    final updatedState = _uiStateManager.getCurrentState(userId);
    assert(updatedState?.notifications.length == 2, 'Deve ter 2 notificações');
    assert(updatedState?.totalCount == 2, 'TotalCount deve ser 2');
    
    EnhancedLogger.log('✅ [TEST_UI] Feedback visual testado com sucesso');
  }

  /// Testa tratamento de erros
  static Future<void> _testErrorHandling(String userId) async {
    EnhancedLogger.log('⚠️ [TEST_UI] Testando tratamento de erros...');
    
    // Simula erro
    _uiStateManager.showSyncStatus(userId, SyncStatus.error, message: 'Erro de teste');
    
    var currentState = _uiStateManager.getCurrentState(userId);
    assert(currentState?.hasError == true, 'Deve ter erro');
    assert(currentState?.errorMessage == 'Erro de teste', 'Mensagem de erro deve estar correta');
    
    // Testa limpeza de erro
    _uiStateManager.clearError(userId);
    
    currentState = _uiStateManager.getCurrentState(userId);
    assert(currentState?.hasError == false, 'Erro deve ter sido limpo');
    
    EnhancedLogger.log('✅ [TEST_UI] Tratamento de erros testado com sucesso');
  }

  /// Testa estatísticas da interface
  static void _testUIStats() {
    EnhancedLogger.log('📊 [TEST_UI] Testando estatísticas...');
    
    final stats = _uiStateManager.getUIStats();
    
    assert(stats.containsKey('activeStates'), 'Stats deve conter activeStates');
    assert(stats.containsKey('activeStreams'), 'Stats deve conter activeStreams');
    assert(stats.containsKey('loadingUsers'), 'Stats deve conter loadingUsers');
    assert(stats.containsKey('errorUsers'), 'Stats deve conter errorUsers');
    assert(stats.containsKey('syncedUsers'), 'Stats deve conter syncedUsers');
    
    EnhancedLogger.log('📊 [TEST_UI] Estatísticas: $stats');
    EnhancedLogger.log('✅ [TEST_UI] Estatísticas testadas com sucesso');
  }

  /// Testa múltiplos usuários simultaneamente
  static Future<void> testMultipleUsers(List<String> userIds) async {
    EnhancedLogger.log('👥 [TEST_UI] Testando múltiplos usuários: ${userIds.length}');
    
    final futures = userIds.map((userId) => testCompleteUIState(userId)).toList();
    
    await Future.wait(futures);
    
    // Verifica estatísticas finais
    final stats = _uiStateManager.getUIStats();
    assert(stats['activeStates'] >= userIds.length, 'Deve ter pelo menos ${userIds.length} estados ativos');
    
    EnhancedLogger.log('✅ [TEST_UI] Teste de múltiplos usuários concluído');
  }

  /// Testa performance do gerenciador
  static Future<void> testPerformance(String userId, {int iterations = 100}) async {
    EnhancedLogger.log('⚡ [TEST_UI] Testando performance com $iterations iterações...');
    
    final startTime = DateTime.now();
    
    for (int i = 0; i < iterations; i++) {
      // Simula operações rápidas
      _uiStateManager.getCurrentState(userId);
      _uiStateManager.hasNotifications(userId);
      _uiStateManager.isLoading(userId);
      _uiStateManager.hasError(userId);
      
      if (i % 10 == 0) {
        _uiStateManager.triggerUIRefresh(userId);
      }
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    EnhancedLogger.log('⚡ [TEST_UI] Performance: $iterations operações em ${duration.inMilliseconds}ms');
    EnhancedLogger.log('⚡ [TEST_UI] Média: ${duration.inMilliseconds / iterations}ms por operação');
    
    // Verifica se performance está aceitável (< 1ms por operação)
    assert(duration.inMilliseconds / iterations < 1, 'Performance deve ser < 1ms por operação');
    
    EnhancedLogger.log('✅ [TEST_UI] Teste de performance concluído');
  }

  /// Monitora sistema em tempo real
  static StreamSubscription monitorUISystem(String userId, {Duration? duration}) {
    EnhancedLogger.log('👁️ [TEST_UI] Iniciando monitoramento do UI State Manager...');
    
    final subscription = _uiStateManager
        .getUIStateStream(userId)
        .listen(
          (state) {
            final stats = _uiStateManager.getUIStats();
            EnhancedLogger.log('📊 [MONITOR_UI] Estado: ${state.syncStatus} | '
                'Notificações: ${state.totalCount} | '
                'Loading: ${state.isLoading} | '
                'Stats: $stats');
          },
          onError: (error) {
            EnhancedLogger.log('❌ [MONITOR_UI] Erro no monitoramento: $error');
          },
        );
    
    // Auto-cancela após duração especificada
    if (duration != null) {
      Timer(duration, () {
        subscription.cancel();
        EnhancedLogger.log('⏰ [MONITOR_UI] Monitoramento finalizado após ${duration.inSeconds}s');
      });
    }
    
    return subscription;
  }

  /// Executa teste completo do sistema de interface
  static Future<void> runCompleteUITest(String userId) async {
    EnhancedLogger.log('🎯 [TEST_UI] Executando teste completo do UI State Manager...');
    
    try {
      // Teste básico
      await testCompleteUIState(userId);
      
      // Teste de performance
      await testPerformance(userId, iterations: 50);
      
      // Teste com múltiplos usuários
      await testMultipleUsers([userId, '${userId}_2', '${userId}_3']);
      
      EnhancedLogger.log('🎉 [TEST_UI] Teste completo do UI State Manager concluído com sucesso!');
      
    } catch (e) {
      EnhancedLogger.log('💥 [TEST_UI] Falha no teste completo: $e');
      rethrow;
    }
  }
}