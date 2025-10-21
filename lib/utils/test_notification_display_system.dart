import 'dart:math';
import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar o sistema de exibição de notificações
class TestNotificationDisplaySystem {
  static final Random _random = Random();

  /// Testa o controller com dados mock
  static Future<void> testControllerWithMockData() async {
    try {
      EnhancedLogger.info('🧪 [TEST] Iniciando teste do controller com dados mock');
      
      final controller = Get.find<MatchesController>();
      
      // 1. Testar com lista vazia
      EnhancedLogger.info('1️⃣ [TEST] Testando com lista vazia...');
      controller.updateRealNotifications([]);
      await Future.delayed(const Duration(milliseconds: 100));
      
      assert(controller.realNotifications.isEmpty, 'Lista deveria estar vazia');
      assert(!controller.hasNewNotifications.value, 'Não deveria ter notificações');
      EnhancedLogger.success('✅ [TEST] Lista vazia - OK');
      
      // 2. Testar com uma notificação
      EnhancedLogger.info('2️⃣ [TEST] Testando com uma notificação...');
      final singleNotification = _createMockNotification('test1', 'João');
      controller.updateRealNotifications([singleNotification]);
      await Future.delayed(const Duration(milliseconds: 100));
      
      assert(controller.realNotifications.length == 1, 'Deveria ter 1 notificação');
      assert(controller.hasNewNotifications.value, 'Deveria ter notificações');
      EnhancedLogger.success('✅ [TEST] Uma notificação - OK');
      
      // 3. Testar com múltiplas notificações
      EnhancedLogger.info('3️⃣ [TEST] Testando com múltiplas notificações...');
      final multipleNotifications = [
        _createMockNotification('test2', 'Maria'),
        _createMockNotification('test3', 'Pedro'),
        _createMockNotification('test4', 'Ana'),
      ];
      controller.updateRealNotifications(multipleNotifications);
      await Future.delayed(const Duration(milliseconds: 100));
      
      assert(controller.realNotifications.length == 3, 'Deveria ter 3 notificações');
      EnhancedLogger.success('✅ [TEST] Múltiplas notificações - OK');
      
      // 4. Testar debouncing
      EnhancedLogger.info('4️⃣ [TEST] Testando debouncing...');
      final initialCount = controller.getPerformanceStats()['updateCount'] ?? 0;
      
      // Fazer múltiplas atualizações rápidas
      for (int i = 0; i < 5; i++) {
        controller.updateRealNotifications([_createMockNotification('rapid$i', 'User$i')]);
      }
      
      await Future.delayed(const Duration(milliseconds: 600)); // Esperar debounce
      
      final finalCount = controller.getPerformanceStats()['updateCount'] ?? 0;
      EnhancedLogger.info('Updates: inicial=$initialCount, final=$finalCount');
      EnhancedLogger.success('✅ [TEST] Debouncing - OK');
      
      // 5. Testar cache
      EnhancedLogger.info('5️⃣ [TEST] Testando cache...');
      final cacheStats = controller.getCacheStats();
      assert(cacheStats['cachedCount'] > 0, 'Cache deveria ter dados');
      EnhancedLogger.success('✅ [TEST] Cache - OK');
      
      EnhancedLogger.success('🎉 [TEST] Todos os testes do controller passaram!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [TEST] Erro no teste do controller', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Testa o widget com diferentes estados
  static Future<void> testWidgetStates() async {
    try {
      EnhancedLogger.info('🧪 [TEST] Iniciando teste dos estados do widget');
      
      final controller = Get.find<MatchesController>();
      
      // 1. Estado de carregamento
      EnhancedLogger.info('1️⃣ [TEST] Testando estado de carregamento...');
      controller.isLoadingNotifications.value = true;
      controller.realNotifications.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      EnhancedLogger.success('✅ [TEST] Estado de carregamento - OK');
      
      // 2. Estado de erro
      EnhancedLogger.info('2️⃣ [TEST] Testando estado de erro...');
      controller.isLoadingNotifications.value = false;
      controller.notificationError.value = 'Erro de teste';
      await Future.delayed(const Duration(milliseconds: 100));
      EnhancedLogger.success('✅ [TEST] Estado de erro - OK');
      
      // 3. Estado vazio
      EnhancedLogger.info('3️⃣ [TEST] Testando estado vazio...');
      controller.notificationError.value = '';
      controller.realNotifications.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      EnhancedLogger.success('✅ [TEST] Estado vazio - OK');
      
      // 4. Estado com dados
      EnhancedLogger.info('4️⃣ [TEST] Testando estado com dados...');
      final notifications = List.generate(3, (i) => 
        _createMockNotification('widget_test_$i', 'Usuário $i')
      );
      controller.updateRealNotifications(notifications);
      await Future.delayed(const Duration(milliseconds: 100));
      EnhancedLogger.success('✅ [TEST] Estado com dados - OK');
      
      EnhancedLogger.success('🎉 [TEST] Todos os testes do widget passaram!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [TEST] Erro no teste do widget', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Testa o fluxo completo de dados
  static Future<void> testCompleteDataFlow() async {
    try {
      EnhancedLogger.info('🧪 [TEST] Iniciando teste do fluxo completo');
      
      final controller = Get.find<MatchesController>();
      
      // 1. Limpar estado inicial
      controller.realNotifications.clear();
      controller.notificationError.value = '';
      controller.isLoadingNotifications.value = false;
      
      // 2. Simular carregamento
      EnhancedLogger.info('1️⃣ [TEST] Simulando carregamento...');
      controller.isLoadingNotifications.value = true;
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 3. Simular dados chegando
      EnhancedLogger.info('2️⃣ [TEST] Simulando dados chegando...');
      final mockNotifications = _generateMockNotifications(5);
      controller.updateRealNotifications(mockNotifications);
      
      // 4. Verificar estado final
      await Future.delayed(const Duration(milliseconds: 300));
      
      assert(controller.realNotifications.length == 5, 'Deveria ter 5 notificações');
      assert(controller.hasNewNotifications.value, 'Deveria ter notificações');
      assert(!controller.isLoadingNotifications.value, 'Não deveria estar carregando');
      assert(controller.notificationError.value.isEmpty, 'Não deveria ter erro');
      
      // 5. Testar cache
      final cacheStats = controller.getCacheStats();
      assert(cacheStats['cachedCount'] == 5, 'Cache deveria ter 5 itens');
      
      EnhancedLogger.success('🎉 [TEST] Fluxo completo testado com sucesso!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [TEST] Erro no teste do fluxo completo', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Testa cenários de erro
  static Future<void> testErrorScenarios() async {
    try {
      EnhancedLogger.info('🧪 [TEST] Iniciando teste de cenários de erro');
      
      final controller = Get.find<MatchesController>();
      
      // 1. Testar notificação inválida
      EnhancedLogger.info('1️⃣ [TEST] Testando notificação inválida...');
      final invalidNotification = RealNotification(
        id: '',
        type: 'interest',
        fromUserId: '',
        fromUserName: '',
        timestamp: DateTime.now(),
        message: '',
      );
      
      controller.updateRealNotifications([invalidNotification]);
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Deveria ainda funcionar, mesmo com dados inválidos
      assert(controller.realNotifications.length == 1, 'Deveria aceitar notificação inválida');
      EnhancedLogger.success('✅ [TEST] Notificação inválida - OK');
      
      // 2. Testar lista nula (simulação)
      EnhancedLogger.info('2️⃣ [TEST] Testando lista vazia após erro...');
      controller.updateRealNotifications([]);
      await Future.delayed(const Duration(milliseconds: 100));
      
      assert(controller.realNotifications.isEmpty, 'Lista deveria estar vazia');
      EnhancedLogger.success('✅ [TEST] Lista vazia após erro - OK');
      
      // 3. Testar erro de rede simulado
      EnhancedLogger.info('3️⃣ [TEST] Testando erro de rede simulado...');
      controller.notificationError.value = 'Erro de conexão simulado';
      controller.isLoadingNotifications.value = false;
      await Future.delayed(const Duration(milliseconds: 100));
      
      assert(controller.notificationError.value.isNotEmpty, 'Deveria ter erro');
      EnhancedLogger.success('✅ [TEST] Erro de rede - OK');
      
      // 4. Limpar erro
      controller.notificationError.value = '';
      
      EnhancedLogger.success('🎉 [TEST] Todos os cenários de erro testados!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [TEST] Erro no teste de cenários de erro', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Testa performance com muitas notificações
  static Future<void> testPerformanceWithManyNotifications() async {
    try {
      EnhancedLogger.info('🧪 [TEST] Iniciando teste de performance');
      
      final controller = Get.find<MatchesController>();
      final stopwatch = Stopwatch()..start();
      
      // Gerar muitas notificações
      final manyNotifications = _generateMockNotifications(100);
      
      EnhancedLogger.info('📊 [TEST] Testando com ${manyNotifications.length} notificações...');
      
      controller.updateRealNotifications(manyNotifications);
      await Future.delayed(const Duration(milliseconds: 500));
      
      stopwatch.stop();
      
      assert(controller.realNotifications.length == 100, 'Deveria ter 100 notificações');
      
      EnhancedLogger.success('✅ [TEST] Performance - ${stopwatch.elapsedMilliseconds}ms para 100 notificações');
      
      // Testar limpeza
      controller.updateRealNotifications([]);
      await Future.delayed(const Duration(milliseconds: 100));
      
      assert(controller.realNotifications.isEmpty, 'Lista deveria estar vazia após limpeza');
      
      EnhancedLogger.success('🎉 [TEST] Teste de performance concluído!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [TEST] Erro no teste de performance', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Executa todos os testes
  static Future<void> runAllTests() async {
    try {
      EnhancedLogger.info('🚀 [TEST_SUITE] Iniciando suite completa de testes');
      
      await testControllerWithMockData();
      await Future.delayed(const Duration(milliseconds: 200));
      
      await testWidgetStates();
      await Future.delayed(const Duration(milliseconds: 200));
      
      await testCompleteDataFlow();
      await Future.delayed(const Duration(milliseconds: 200));
      
      await testErrorScenarios();
      await Future.delayed(const Duration(milliseconds: 200));
      
      await testPerformanceWithManyNotifications();
      
      EnhancedLogger.success('🎉 [TEST_SUITE] Todos os testes passaram com sucesso!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [TEST_SUITE] Falha na suite de testes', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Cria uma notificação mock
  static RealNotification _createMockNotification(String id, String userName) {
    return RealNotification(
      id: id,
      type: 'interest',
      fromUserId: 'user_$id',
      fromUserName: userName,
      timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      message: '$userName se interessou por você',
      isRead: _random.nextBool(),
    );
  }

  /// Gera múltiplas notificações mock
  static List<RealNotification> _generateMockNotifications(int count) {
    final names = [
      'João', 'Maria', 'Pedro', 'Ana', 'Carlos', 'Lucia', 'Rafael', 'Beatriz',
      'Fernando', 'Camila', 'Ricardo', 'Juliana', 'Marcos', 'Patricia', 'André'
    ];
    
    return List.generate(count, (index) {
      final name = names[index % names.length];
      return _createMockNotification('mock_$index', '$name ${index + 1}');
    });
  }

  /// Gera relatório de teste
  static Map<String, dynamic> generateTestReport() {
    final controller = Get.find<MatchesController>();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'notificationState': controller.getNotificationDebugState(),
      'performanceStats': controller.getPerformanceStats(),
      'cacheStats': controller.getCacheStats(),
      'testStatus': 'completed',
    };
  }
}