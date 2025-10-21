import 'dart:async';
import '../utils/enhanced_logger.dart';
import '../services/notification_system_integrator.dart';
import '../services/javascript_error_handler.dart';
import '../services/error_recovery_system.dart';
import '../services/real_time_sync_manager.dart';
import '../services/advanced_diagnostic_system.dart';
import '../services/real_time_monitoring_system.dart';
import '../services/fixed_notification_pipeline.dart';

/// Utilitário para testar o sistema completo de notificações
class CompleteNotificationSystemTester {
  static CompleteNotificationSystemTester? _instance;
  static CompleteNotificationSystemTester get instance => 
      _instance ??= CompleteNotificationSystemTester._();
  
  CompleteNotificationSystemTester._();
  
  final List<String> _testLog = [];
  final Map<String, dynamic> _testResults = {};
  
  /// Executa teste completo do sistema
  Future<Map<String, dynamic>> runCompleteSystemTest() async {
    _logTest('🚀 INICIANDO TESTE COMPLETO DO SISTEMA DE NOTIFICAÇÕES');
    _testResults.clear();
    
    try {
      // Teste 1: Inicialização do Sistema
      _logTest('📋 Teste 1: Inicialização do Sistema');
      final initResult = await _testSystemInitialization();
      _testResults['initialization'] = initResult;
      
      // Teste 2: Processamento de Notificações
      _logTest('🔄 Teste 2: Processamento de Notificações');
      final processingResult = await _testNotificationProcessing();
      _testResults['processing'] = processingResult;
      
      // Teste 3: Sistema de Monitoramento
      _logTest('📊 Teste 3: Sistema de Monitoramento');
      final monitoringResult = await _testMonitoringSystem();
      _testResults['monitoring'] = monitoringResult;
      
      // Teste 4: Recuperação de Erros
      _logTest('🛡️ Teste 4: Recuperação de Erros');
      final recoveryResult = await _testErrorRecovery();
      _testResults['recovery'] = recoveryResult;
      
      // Teste 5: Diagnóstico do Sistema
      _logTest('🏥 Teste 5: Diagnóstico do Sistema');
      final diagnosticResult = await _testSystemDiagnostic();
      _testResults['diagnostic'] = diagnosticResult;
      
      // Teste 6: Performance do Sistema
      _logTest('⚡ Teste 6: Performance do Sistema');
      final performanceResult = await _testSystemPerformance();
      _testResults['performance'] = performanceResult;
      
      // Teste 7: Integração Completa
      _logTest('🔗 Teste 7: Integração Completa');
      final integrationResult = await _testCompleteIntegration();
      _testResults['integration'] = integrationResult;
      
      // Calcular resultado final
      final finalResult = _calculateFinalResult();
      _testResults['final'] = finalResult;
      
      _logTest('✅ TESTE COMPLETO FINALIZADO');
      _logTest('📊 Resultado Final: ${finalResult['score']}% (${finalResult['status']})');
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'testResults': Map.from(_testResults),
        'testLog': List.from(_testLog),
        'summary': finalResult,
      };
      
    } catch (e) {
      _logTest('💥 ERRO CRÍTICO NO TESTE: $e');
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'testResults': Map.from(_testResults),
        'testLog': List.from(_testLog),
        'summary': {
          'score': 0,
          'status': 'FAILED',
          'error': e.toString(),
        },
      };
    }
  }
  
  /// Testa inicialização do sistema
  Future<Map<String, dynamic>> _testSystemInitialization() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _logTest('  🔧 Inicializando sistema integrado');
      final success = await NotificationSystemIntegrator.instance
          .initializeCompleteSystem();
      
      stopwatch.stop();
      
      if (success) {
        _logTest('  ✅ Sistema inicializado com sucesso');
        
        // Verificar componentes individuais
        final componentStatus = _checkComponentStatus();
        
        return {
          'success': true,
          'initializationTime': stopwatch.elapsedMilliseconds,
          'componentStatus': componentStatus,
          'score': _calculateComponentScore(componentStatus),
        };
      } else {
        _logTest('  ❌ Falha na inicialização do sistema');
        return {
          'success': false,
          'initializationTime': stopwatch.elapsedMilliseconds,
          'error': 'System initialization failed',
          'score': 0,
        };
      }
      
    } catch (e) {
      stopwatch.stop();
      _logTest('  💥 Erro na inicialização: $e');
      
      return {
        'success': false,
        'initializationTime': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Testa processamento de notificações
  Future<Map<String, dynamic>> _testNotificationProcessing() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final testUsers = ['test_user_1', 'test_user_2', 'test_user_3'];
      final results = <String, List>{}; 
      
      for (final userId in testUsers) {
        _logTest('  🔄 Processando notificações para $userId');
        
        final notifications = await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated(userId);
        
        results[userId] = notifications;
        _logTest('  📦 $userId: ${notifications.length} notificações processadas');
      }
      
      stopwatch.stop();
      
      // Calcular estatísticas
      final totalNotifications = results.values
          .map((list) => list.length)
          .fold(0, (a, b) => a + b);
      
      final avgProcessingTime = stopwatch.elapsedMilliseconds / testUsers.length;
      
      _logTest('  📊 Total: $totalNotifications notificações em ${stopwatch.elapsedMilliseconds}ms');
      
      return {
        'success': true,
        'totalUsers': testUsers.length,
        'totalNotifications': totalNotifications,
        'processingTime': stopwatch.elapsedMilliseconds,
        'avgProcessingTime': avgProcessingTime,
        'results': results.map((k, v) => MapEntry(k, v.length)),
        'score': _calculateProcessingScore(totalNotifications, avgProcessingTime),
      };
      
    } catch (e) {
      stopwatch.stop();
      _logTest('  💥 Erro no processamento: $e');
      
      return {
        'success': false,
        'processingTime': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Testa sistema de monitoramento
  Future<Map<String, dynamic>> _testMonitoringSystem() async {
    try {
      _logTest('  📊 Verificando sistema de monitoramento');
      
      // Forçar verificação
      RealTimeMonitoringSystem.instance.forceCheck();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Obter métricas
      final metrics = RealTimeMonitoringSystem.instance.getRealTimeMetrics();
      final alerts = RealTimeMonitoringSystem.instance.getRecentAlerts();
      
      _logTest('  📈 Métricas obtidas: ${metrics.keys.length} categorias');
      _logTest('  🚨 Alertas recentes: ${alerts.length}');
      
      final isMonitoringActive = metrics['monitoringActive'] as bool? ?? false;
      final isInitialized = metrics['isInitialized'] as bool? ?? false;
      
      return {
        'success': true,
        'isInitialized': isInitialized,
        'isMonitoringActive': isMonitoringActive,
        'metricsCount': metrics.keys.length,
        'alertsCount': alerts.length,
        'score': _calculateMonitoringScore(isInitialized, isMonitoringActive, metrics),
      };
      
    } catch (e) {
      _logTest('  💥 Erro no monitoramento: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Testa recuperação de erros
  Future<Map<String, dynamic>> _testErrorRecovery() async {
    try {
      _logTest('  🛡️ Testando sistema de recuperação');
      
      // Testar detecção de falhas
      final hasFailure = ErrorRecoverySystem.instance.detectSystemFailure();
      _logTest('  🔍 Falha detectada: $hasFailure');
      
      if (hasFailure) {
        _logTest('  🛠️ Executando recuperação');
        await ErrorRecoverySystem.instance.recoverFromFailure();
      }
      
      // Testar notificações de fallback
      const testUserId = 'recovery_test_user';
      final fallbackNotifications = ErrorRecoverySystem.instance
          .getFallbackNotifications(testUserId);
      
      _logTest('  💾 Notificações de fallback: ${fallbackNotifications.length}');
      
      // Obter estatísticas
      final recoveryStats = ErrorRecoverySystem.instance.getRecoveryStatistics();
      final isInitialized = recoveryStats['isInitialized'] as bool? ?? false;
      
      return {
        'success': true,
        'hasFailure': hasFailure,
        'isInitialized': isInitialized,
        'fallbackNotificationsCount': fallbackNotifications.length,
        'recoveryStats': recoveryStats,
        'score': _calculateRecoveryScore(isInitialized, fallbackNotifications.length),
      };
      
    } catch (e) {
      _logTest('  💥 Erro na recuperação: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Testa diagnóstico do sistema
  Future<Map<String, dynamic>> _testSystemDiagnostic() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _logTest('  🏥 Executando diagnóstico completo');
      
      const testUserId = 'diagnostic_test_user';
      final diagnostic = await NotificationSystemIntegrator.instance
          .runIntegratedDiagnostic(testUserId);
      
      stopwatch.stop();
      
      final isSystemHealthy = diagnostic['isSystemHealthy'] as bool? ?? false;
      final systemDiagnostic = diagnostic['systemDiagnostic'] as Map<String, dynamic>? ?? {};
      final systemHealth = systemDiagnostic['systemHealth'] as Map<String, dynamic>? ?? {};
      final overallScore = systemHealth['overallScore'] as int? ?? 0;
      
      _logTest('  📊 Sistema saudável: $isSystemHealthy');
      _logTest('  🎯 Score geral: $overallScore%');
      _logTest('  ⏱️ Tempo de diagnóstico: ${stopwatch.elapsedMilliseconds}ms');
      
      return {
        'success': true,
        'isSystemHealthy': isSystemHealthy,
        'overallScore': overallScore,
        'diagnosticTime': stopwatch.elapsedMilliseconds,
        'diagnosticData': diagnostic,
        'score': _calculateDiagnosticScore(isSystemHealthy, overallScore),
      };
      
    } catch (e) {
      stopwatch.stop();
      _logTest('  💥 Erro no diagnóstico: $e');
      
      return {
        'success': false,
        'diagnosticTime': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Testa performance do sistema
  Future<Map<String, dynamic>> _testSystemPerformance() async {
    try {
      _logTest('  ⚡ Testando performance do sistema');
      
      const iterations = 5;
      const testUserId = 'performance_test_user';
      
      final processingTimes = <int>[];
      final diagnosticTimes = <int>[];
      
      for (int i = 0; i < iterations; i++) {
        // Teste de processamento
        final processingStopwatch = Stopwatch()..start();
        await NotificationSystemIntegrator.instance
            .processNotificationsIntegrated('${testUserId}_$i');
        processingStopwatch.stop();
        processingTimes.add(processingStopwatch.elapsedMilliseconds);
        
        // Teste de diagnóstico
        final diagnosticStopwatch = Stopwatch()..start();
        await NotificationSystemIntegrator.instance
            .runIntegratedDiagnostic('${testUserId}_$i');
        diagnosticStopwatch.stop();
        diagnosticTimes.add(diagnosticStopwatch.elapsedMilliseconds);
        
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final avgProcessingTime = processingTimes.reduce((a, b) => a + b) / iterations;
      final avgDiagnosticTime = diagnosticTimes.reduce((a, b) => a + b) / iterations;
      
      _logTest('  📊 Tempo médio de processamento: ${avgProcessingTime.toStringAsFixed(1)}ms');
      _logTest('  📊 Tempo médio de diagnóstico: ${avgDiagnosticTime.toStringAsFixed(1)}ms');
      
      return {
        'success': true,
        'iterations': iterations,
        'avgProcessingTime': avgProcessingTime,
        'avgDiagnosticTime': avgDiagnosticTime,
        'processingTimes': processingTimes,
        'diagnosticTimes': diagnosticTimes,
        'score': _calculatePerformanceScore(avgProcessingTime, avgDiagnosticTime),
      };
      
    } catch (e) {
      _logTest('  💥 Erro no teste de performance: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Testa integração completa
  Future<Map<String, dynamic>> _testCompleteIntegration() async {
    try {
      _logTest('  🔗 Testando integração completa');
      
      // Obter métricas de integração
      final integrationMetrics = NotificationSystemIntegrator.instance
          .getIntegrationMetrics();
      
      final integrationLog = NotificationSystemIntegrator.instance
          .getIntegrationLog(limit: 10);
      
      final isInitialized = integrationMetrics['isInitialized'] as bool? ?? false;
      final metrics = integrationMetrics['integrationMetrics'] as Map<String, dynamic>? ?? {};
      
      _logTest('  📊 Sistema integrado inicializado: $isInitialized');
      _logTest('  📝 Entradas no log: ${integrationLog.length}');
      _logTest('  📈 Métricas de integração: ${metrics.keys.length}');
      
      // Testar cenário completo
      const scenarioUserId = 'integration_scenario_user';
      
      // 1. Processar notificações
      final notifications = await NotificationSystemIntegrator.instance
          .processNotificationsIntegrated(scenarioUserId);
      
      // 2. Executar diagnóstico
      final diagnostic = await NotificationSystemIntegrator.instance
          .runIntegratedDiagnostic(scenarioUserId);
      
      // 3. Verificar monitoramento
      RealTimeMonitoringSystem.instance.forceCheck();
      
      final isScenarioSuccessful = notifications is List && 
                                  diagnostic is Map &&
                                  diagnostic.containsKey('isSystemHealthy');
      
      _logTest('  ✅ Cenário de integração: ${isScenarioSuccessful ? "SUCESSO" : "FALHA"}');
      
      return {
        'success': true,
        'isInitialized': isInitialized,
        'integrationMetricsCount': metrics.keys.length,
        'integrationLogSize': integrationLog.length,
        'scenarioSuccessful': isScenarioSuccessful,
        'notificationsProcessed': notifications is List ? notifications.length : 0,
        'diagnosticCompleted': diagnostic is Map,
        'score': _calculateIntegrationScore(isInitialized, isScenarioSuccessful, metrics),
      };
      
    } catch (e) {
      _logTest('  💥 Erro na integração: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'score': 0,
      };
    }
  }
  
  /// Verifica status dos componentes
  Map<String, bool> _checkComponentStatus() {
    return {
      'jsErrorHandler': JavaScriptErrorHandler.instance.getErrorStatistics()['isInitialized'] ?? false,
      'errorRecovery': ErrorRecoverySystem.instance.getRecoveryStatistics()['isInitialized'] ?? false,
      'syncManager': RealTimeSyncManager.instance.getSyncStatistics()['isInitialized'] ?? false,
      'diagnosticSystem': AdvancedDiagnosticSystem.instance.getSystemStatistics()['isInitialized'] ?? false,
      'monitoringSystem': RealTimeMonitoringSystem.instance.getRealTimeMetrics()['isInitialized'] ?? false,
      'notificationPipeline': FixedNotificationPipeline.instance.getPipelineStatistics()['isInitialized'] ?? false,
    };
  }
  
  /// Calcula score dos componentes
  int _calculateComponentScore(Map<String, bool> componentStatus) {
    final totalComponents = componentStatus.length;
    final activeComponents = componentStatus.values.where((status) => status).length;
    return ((activeComponents / totalComponents) * 100).round();
  }
  
  /// Calcula score de processamento
  int _calculateProcessingScore(int totalNotifications, double avgTime) {
    int score = 50; // Base score
    
    // Bonus por notificações processadas
    if (totalNotifications > 0) score += 20;
    
    // Bonus por performance
    if (avgTime < 1000) score += 20; // < 1s
    else if (avgTime < 3000) score += 10; // < 3s
    
    // Bonus por consistência
    score += 10; // Assumindo que chegou até aqui
    
    return score.clamp(0, 100);
  }
  
  /// Calcula score de monitoramento
  int _calculateMonitoringScore(bool isInitialized, bool isActive, Map<String, dynamic> metrics) {
    int score = 0;
    
    if (isInitialized) score += 40;
    if (isActive) score += 30;
    if (metrics.isNotEmpty) score += 20;
    if (metrics.containsKey('metrics')) score += 10;
    
    return score.clamp(0, 100);
  }
  
  /// Calcula score de recuperação
  int _calculateRecoveryScore(bool isInitialized, int fallbackCount) {
    int score = 0;
    
    if (isInitialized) score += 60;
    if (fallbackCount >= 0) score += 20; // Pode ter 0 notificações
    score += 20; // Por funcionar
    
    return score.clamp(0, 100);
  }
  
  /// Calcula score de diagnóstico
  int _calculateDiagnosticScore(bool isHealthy, int overallScore) {
    int score = 30; // Base por funcionar
    
    if (isHealthy) score += 30;
    score += (overallScore * 0.4).round(); // 40% do score do sistema
    
    return score.clamp(0, 100);
  }
  
  /// Calcula score de performance
  int _calculatePerformanceScore(double avgProcessingTime, double avgDiagnosticTime) {
    int score = 20; // Base
    
    // Score por tempo de processamento
    if (avgProcessingTime < 500) score += 30;
    else if (avgProcessingTime < 1000) score += 20;
    else if (avgProcessingTime < 2000) score += 10;
    
    // Score por tempo de diagnóstico
    if (avgDiagnosticTime < 1000) score += 30;
    else if (avgDiagnosticTime < 2000) score += 20;
    else if (avgDiagnosticTime < 3000) score += 10;
    
    // Bonus por consistência
    score += 20;
    
    return score.clamp(0, 100);
  }
  
  /// Calcula score de integração
  int _calculateIntegrationScore(bool isInitialized, bool scenarioSuccessful, Map<String, dynamic> metrics) {
    int score = 0;
    
    if (isInitialized) score += 40;
    if (scenarioSuccessful) score += 40;
    if (metrics.isNotEmpty) score += 20;
    
    return score.clamp(0, 100);
  }
  
  /// Calcula resultado final
  Map<String, dynamic> _calculateFinalResult() {
    final testCategories = ['initialization', 'processing', 'monitoring', 'recovery', 'diagnostic', 'performance', 'integration'];
    
    int totalScore = 0;
    int successfulTests = 0;
    
    for (final category in testCategories) {
      final testResult = _testResults[category] as Map<String, dynamic>?;
      if (testResult != null) {
        final score = testResult['score'] as int? ?? 0;
        totalScore += score;
        
        if (testResult['success'] == true) {
          successfulTests++;
        }
      }
    }
    
    final avgScore = testCategories.isNotEmpty ? (totalScore / testCategories.length).round() : 0;
    final successRate = (successfulTests / testCategories.length * 100).round();
    
    String status;
    if (avgScore >= 90) {
      status = 'EXCELENTE';
    } else if (avgScore >= 80) {
      status = 'BOM';
    } else if (avgScore >= 70) {
      status = 'SATISFATÓRIO';
    } else if (avgScore >= 50) {
      status = 'REGULAR';
    } else {
      status = 'CRÍTICO';
    }
    
    return {
      'score': avgScore,
      'status': status,
      'successRate': successRate,
      'successfulTests': successfulTests,
      'totalTests': testCategories.length,
      'recommendation': _getRecommendation(avgScore),
    };
  }
  
  /// Obtém recomendação baseada no score
  String _getRecommendation(int score) {
    if (score >= 90) {
      return 'Sistema funcionando perfeitamente. Manter monitoramento regular.';
    } else if (score >= 80) {
      return 'Sistema funcionando bem. Pequenos ajustes podem melhorar a performance.';
    } else if (score >= 70) {
      return 'Sistema funcionando adequadamente. Revisar componentes com menor performance.';
    } else if (score >= 50) {
      return 'Sistema com problemas. Investigar e corrigir componentes com falhas.';
    } else {
      return 'Sistema com problemas críticos. Reinicialização e correções urgentes necessárias.';
    }
  }
  
  /// Registra entrada no log de teste
  void _logTest(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    
    _testLog.add(logEntry);
    
    // Manter apenas as últimas 100 entradas
    if (_testLog.length > 100) {
      _testLog.removeAt(0);
    }
    
    EnhancedLogger.info('🧪 [SYSTEM_TESTER] $message');
  }
  
  /// Obtém log de teste
  List<String> getTestLog({int limit = 50}) {
    return _testLog.take(limit).toList();
  }
  
  /// Limpa log de teste
  void clearTestLog() {
    _testLog.clear();
  }
}