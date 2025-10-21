import 'dart:async';
import 'package:get/get.dart';
import '../utils/enhanced_logger.dart';
import '../controllers/matches_controller.dart';
import '../services/javascript_error_handler.dart';
import '../repositories/enhanced_real_interests_repository.dart';
import '../services/robust_notification_converter.dart';
import '../services/error_recovery_system.dart';
import '../services/real_time_sync_manager.dart';
import '../services/fixed_notification_pipeline.dart';

/// Sistema avançado de diagnóstico e validação
class AdvancedDiagnosticSystem {
  static AdvancedDiagnosticSystem? _instance;
  static AdvancedDiagnosticSystem get instance => 
      _instance ??= AdvancedDiagnosticSystem._();
  
  AdvancedDiagnosticSystem._();
  
  bool _isInitialized = false;
  Timer? _healthMonitorTimer;
  final List<Map<String, dynamic>> _diagnosticHistory = [];
  final Map<String, dynamic> _performanceMetrics = {};
  
  /// Inicializa o sistema de diagnóstico
  void initialize() {
    if (_isInitialized) return;
    
    try {
      _setupHealthMonitoring();
      _setupPerformanceTracking();
      _isInitialized = true;
      
      EnhancedLogger.success('✅ [DIAGNOSTIC_SYSTEM] Sistema inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.error('❌ [DIAGNOSTIC_SYSTEM] Erro ao inicializar sistema', 
        error: e
      );
    }
  }
  
  /// Configura monitoramento de saúde em tempo real
  void _setupHealthMonitoring() {
    _healthMonitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performHealthCheck();
    });
    
    EnhancedLogger.info('🏥 [DIAGNOSTIC_SYSTEM] Monitoramento de saúde configurado');
  }
  
  /// Configura rastreamento de performance
  void _setupPerformanceTracking() {
    _performanceMetrics['systemStartTime'] = DateTime.now();
    _performanceMetrics['totalHealthChecks'] = 0;
    _performanceMetrics['totalDiagnostics'] = 0;
    
    EnhancedLogger.info('📊 [DIAGNOSTIC_SYSTEM] Rastreamento de performance configurado');
  }
  
  /// Executa diagnóstico completo do sistema
  Future<Map<String, dynamic>> runCompleteDiagnostic(String userId) async {
    try {
      EnhancedLogger.info('🔍 [DIAGNOSTIC_SYSTEM] Iniciando diagnóstico completo', 
        tag: 'ADVANCED_DIAGNOSTIC_SYSTEM',
        data: {
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String()
        }
      );
      
      final diagnosticResult = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId,
        'systemHealth': {},
        'componentStatus': {},
        'performanceMetrics': {},
        'dataFlow': {},
        'recommendations': [],
        'criticalIssues': [],
      };
      
      // 1. Verificação de saúde do sistema
      diagnosticResult['systemHealth'] = await _checkSystemHealth();
      
      // 2. Status dos componentes
      diagnosticResult['componentStatus'] = _checkComponentStatus();
      
      // 3. Métricas de performance
      diagnosticResult['performanceMetrics'] = _getPerformanceMetrics();
      
      // 4. Análise do fluxo de dados
      diagnosticResult['dataFlow'] = await _analyzeDataFlow(userId);
      
      // 5. Gerar recomendações
      diagnosticResult['recommendations'] = _generateRecommendations(diagnosticResult);
      
      // 6. Identificar problemas críticos
      diagnosticResult['criticalIssues'] = _identifyCriticalIssues(diagnosticResult);
      
      // Salva no histórico
      _saveDiagnosticToHistory(diagnosticResult);
      
      // Atualiza métricas
      _performanceMetrics['totalDiagnostics'] = 
          (_performanceMetrics['totalDiagnostics'] ?? 0) + 1;
      
      EnhancedLogger.success('✅ [DIAGNOSTIC_SYSTEM] Diagnóstico completo concluído', 
        data: {
          'userId': userId,
          'systemHealthScore': diagnosticResult['systemHealth']['overallScore'],
          'criticalIssuesCount': (diagnosticResult['criticalIssues'] as List).length,
          'recommendationsCount': (diagnosticResult['recommendations'] as List).length
        }
      );
      
      return diagnosticResult;
      
    } catch (e) {
      EnhancedLogger.error('❌ [DIAGNOSTIC_SYSTEM] Erro no diagnóstico completo', 
        error: e,
        data: {'userId': userId}
      );
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userId,
        'error': e.toString(),
        'status': 'failed'
      };
    }
  }
  
  /// Verifica saúde geral do sistema
  Future<Map<String, dynamic>> _checkSystemHealth() async {
    try {
      final healthChecks = <String, dynamic>{};
      
      // JavaScript Error Handler
      healthChecks['jsErrorHandler'] = _checkJavaScriptErrorHandler();
      
      // Enhanced Repository
      healthChecks['repository'] = _checkRepository();
      
      // Notification Converter
      healthChecks['converter'] = _checkConverter();
      
      // Error Recovery System
      healthChecks['errorRecovery'] = _checkErrorRecovery();
      
      // Real-time Sync Manager
      healthChecks['syncManager'] = _checkSyncManager();
      
      // Fixed Pipeline
      healthChecks['fixedPipeline'] = _checkFixedPipeline();
      
      // Matches Controller
      healthChecks['matchesController'] = _checkMatchesController();
      
      // Calcular score geral
      final totalChecks = healthChecks.length;
      final healthyChecks = healthChecks.values.where((check) => 
          check['status'] == 'healthy').length;
      final overallScore = totalChecks > 0 ? (healthyChecks / totalChecks * 100).round() : 0;
      
      return {
        'overallScore': overallScore,
        'status': overallScore >= 80 ? 'healthy' : overallScore >= 60 ? 'warning' : 'critical',
        'checks': healthChecks,
        'summary': {
          'total': totalChecks,
          'healthy': healthyChecks,
          'warning': healthChecks.values.where((check) => check['status'] == 'warning').length,
          'critical': healthChecks.values.where((check) => check['status'] == 'critical').length,
        }
      };
      
    } catch (e) {
      return {
        'overallScore': 0,
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica JavaScript Error Handler
  Map<String, dynamic> _checkJavaScriptErrorHandler() {
    try {
      final stats = JavaScriptErrorHandler.instance.getErrorStatistics();
      final recentErrors = stats['recentErrors'] as int? ?? 0;
      
      String status;
      if (recentErrors == 0) {
        status = 'healthy';
      } else if (recentErrors < 5) {
        status = 'warning';
      } else {
        status = 'critical';
      }
      
      return {
        'status': status,
        'recentErrors': recentErrors,
        'totalErrors': stats['totalErrors'],
        'isInitialized': stats['isInitialized'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica Enhanced Repository
  Map<String, dynamic> _checkRepository() {
    try {
      final stats = EnhancedRealInterestsRepository.instance.getStatistics();
      
      return {
        'status': 'healthy',
        'cacheSize': stats['cacheSize'],
        'maxRetries': stats['maxRetries'],
        'cacheTTL': stats['cacheTTL'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica Notification Converter
  Map<String, dynamic> _checkConverter() {
    try {
      final stats = RobustNotificationConverter.instance.getConversionStatistics();
      final successRate = double.tryParse(
        stats['successRate'].toString().replaceAll('%', '')
      ) ?? 0.0;
      
      String status;
      if (successRate >= 90) {
        status = 'healthy';
      } else if (successRate >= 70) {
        status = 'warning';
      } else {
        status = 'critical';
      }
      
      return {
        'status': status,
        'successRate': stats['successRate'],
        'totalConversions': stats['totalConversions'],
        'failedConversions': stats['failedConversions'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica Error Recovery System
  Map<String, dynamic> _checkErrorRecovery() {
    try {
      final stats = ErrorRecoverySystem.instance.getRecoveryStatistics();
      
      return {
        'status': stats['isInitialized'] ? 'healthy' : 'warning',
        'isInitialized': stats['isInitialized'],
        'fallbackCacheSize': stats['fallbackCacheSize'],
        'healthCheckActive': stats['healthCheckActive'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica Real-time Sync Manager
  Map<String, dynamic> _checkSyncManager() {
    try {
      final stats = RealTimeSyncManager.instance.getSyncStatistics();
      
      String status = 'healthy';
      if (!stats['isInitialized']) {
        status = 'warning';
      }
      
      final timeSinceLastSync = stats['timeSinceLastSync'] as int?;
      if (timeSinceLastSync != null && timeSinceLastSync > 300) { // 5 minutos
        status = 'warning';
      }
      
      return {
        'status': status,
        'isInitialized': stats['isInitialized'],
        'lastSyncTime': stats['lastSyncTime'],
        'timeSinceLastSync': timeSinceLastSync,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica Fixed Pipeline
  Map<String, dynamic> _checkFixedPipeline() {
    try {
      final stats = FixedNotificationPipeline.instance.getPipelineStatistics();
      
      return {
        'status': stats['isInitialized'] ? 'healthy' : 'warning',
        'isInitialized': stats['isInitialized'],
        'isProcessing': stats['isProcessing'],
        'userCacheSize': stats['userCacheSize'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica Matches Controller
  Map<String, dynamic> _checkMatchesController() {
    try {
      if (!Get.isRegistered<MatchesController>()) {
        return {
          'status': 'critical',
          'error': 'Controller não registrado'
        };
      }
      
      final controller = Get.find<MatchesController>();
      final debugState = controller.getNotificationDebugState();
      
      String status = 'healthy';
      if (debugState['notificationError'].toString().isNotEmpty) {
        status = 'warning';
      }
      
      return {
        'status': status,
        'realNotifications': debugState['realNotifications'],
        'hasNewNotifications': debugState['hasNewNotifications'],
        'isLoading': debugState['isLoadingNotifications'],
        'error': debugState['notificationError'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Verifica status dos componentes
  Map<String, dynamic> _checkComponentStatus() {
    return {
      'getxRegistered': Get.isRegistered<MatchesController>(),
      'systemInitialized': _isInitialized,
      'healthMonitorActive': _healthMonitorTimer?.isActive ?? false,
      'diagnosticHistorySize': _diagnosticHistory.length,
    };
  }
  
  /// Obtém métricas de performance
  Map<String, dynamic> _getPerformanceMetrics() {
    final now = DateTime.now();
    final startTime = _performanceMetrics['systemStartTime'] as DateTime?;
    final uptime = startTime != null ? now.difference(startTime) : Duration.zero;
    
    return {
      'systemUptime': uptime.inMinutes,
      'totalHealthChecks': _performanceMetrics['totalHealthChecks'] ?? 0,
      'totalDiagnostics': _performanceMetrics['totalDiagnostics'] ?? 0,
      'diagnosticHistorySize': _diagnosticHistory.length,
      'memoryUsage': _getMemoryUsage(),
    };
  }
  
  /// Obtém uso de memória (estimado)
  Map<String, dynamic> _getMemoryUsage() {
    return {
      'diagnosticHistory': _diagnosticHistory.length,
      'performanceMetrics': _performanceMetrics.length,
      'estimated': 'low', // Implementação simplificada
    };
  }
  
  /// Analisa fluxo de dados
  Future<Map<String, dynamic>> _analyzeDataFlow(String userId) async {
    try {
      final dataFlow = <String, dynamic>{};
      
      // Testa repository
      dataFlow['repository'] = await _testRepository(userId);
      
      // Testa converter
      dataFlow['converter'] = await _testConverter();
      
      // Testa controller
      dataFlow['controller'] = _testController();
      
      // Testa pipeline completo
      dataFlow['pipeline'] = await _testPipeline(userId);
      
      return dataFlow;
      
    } catch (e) {
      return {
        'error': e.toString(),
        'status': 'failed'
      };
    }
  }
  
  /// Testa repository
  Future<Map<String, dynamic>> _testRepository(String userId) async {
    try {
      final startTime = DateTime.now();
      final interests = await EnhancedRealInterestsRepository.instance
          .getInterestsWithRetry(userId);
      final duration = DateTime.now().difference(startTime);
      
      return {
        'status': 'success',
        'interestsFound': interests.length,
        'responseTime': duration.inMilliseconds,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Testa converter
  Future<Map<String, dynamic>> _testConverter() async {
    try {
      final stats = RobustNotificationConverter.instance.getConversionStatistics();
      
      return {
        'status': 'success',
        'conversionStats': stats,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Testa controller
  Map<String, dynamic> _testController() {
    try {
      if (!Get.isRegistered<MatchesController>()) {
        return {
          'status': 'error',
          'error': 'Controller não registrado'
        };
      }
      
      final controller = Get.find<MatchesController>();
      final state = controller.getNotificationDebugState();
      
      return {
        'status': 'success',
        'controllerState': state,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Testa pipeline completo
  Future<Map<String, dynamic>> _testPipeline(String userId) async {
    try {
      final stats = FixedNotificationPipeline.instance.getPipelineStatistics();
      
      return {
        'status': 'success',
        'pipelineStats': stats,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
  
  /// Gera recomendações baseadas no diagnóstico
  List<String> _generateRecommendations(Map<String, dynamic> diagnosticResult) {
    final recommendations = <String>[];
    
    try {
      final systemHealth = diagnosticResult['systemHealth'] as Map<String, dynamic>?;
      final overallScore = systemHealth?['overallScore'] as int? ?? 0;
      
      if (overallScore < 80) {
        recommendations.add('Sistema com problemas de saúde - executar recuperação automática');
      }
      
      final checks = systemHealth?['checks'] as Map<String, dynamic>? ?? {};
      
      // Recomendações específicas por componente
      checks.forEach((component, check) {
        final status = check['status'] as String?;
        if (status == 'critical' || status == 'error') {
          recommendations.add('Componente $component crítico - requer atenção imediata');
        } else if (status == 'warning') {
          recommendations.add('Componente $component com avisos - monitorar de perto');
        }
      });
      
      // Recomendações de performance
      final performanceMetrics = diagnosticResult['performanceMetrics'] as Map<String, dynamic>?;
      final uptime = performanceMetrics?['systemUptime'] as int? ?? 0;
      
      if (uptime > 1440) { // 24 horas
        recommendations.add('Sistema rodando há muito tempo - considerar reinicialização');
      }
      
      if (recommendations.isEmpty) {
        recommendations.add('Sistema funcionando normalmente - nenhuma ação necessária');
      }
      
    } catch (e) {
      recommendations.add('Erro ao gerar recomendações: ${e.toString()}');
    }
    
    return recommendations;
  }
  
  /// Identifica problemas críticos
  List<String> _identifyCriticalIssues(Map<String, dynamic> diagnosticResult) {
    final criticalIssues = <String>[];
    
    try {
      final systemHealth = diagnosticResult['systemHealth'] as Map<String, dynamic>?;
      final checks = systemHealth?['checks'] as Map<String, dynamic>? ?? {};
      
      checks.forEach((component, check) {
        final status = check['status'] as String?;
        if (status == 'critical' || status == 'error') {
          final error = check['error'] as String?;
          criticalIssues.add('$component: ${error ?? 'Status crítico'}');
        }
      });
      
    } catch (e) {
      criticalIssues.add('Erro ao identificar problemas críticos: ${e.toString()}');
    }
    
    return criticalIssues;
  }
  
  /// Salva diagnóstico no histórico
  void _saveDiagnosticToHistory(Map<String, dynamic> diagnostic) {
    _diagnosticHistory.add(diagnostic);
    
    // Mantém apenas os últimos 50 diagnósticos
    if (_diagnosticHistory.length > 50) {
      _diagnosticHistory.removeAt(0);
    }
  }
  
  /// Executa verificação periódica de saúde
  void _performHealthCheck() {
    try {
      _performanceMetrics['totalHealthChecks'] = 
          (_performanceMetrics['totalHealthChecks'] ?? 0) + 1;
      
      // Verificação básica de saúde
      final healthIssues = <String>[];
      
      if (!Get.isRegistered<MatchesController>()) {
        healthIssues.add('MatchesController não registrado');
      }
      
      if (healthIssues.isNotEmpty) {
        EnhancedLogger.warning('⚠️ [DIAGNOSTIC_SYSTEM] Problemas de saúde detectados', 
          data: {'issues': healthIssues}
        );
      }
      
    } catch (e) {
      EnhancedLogger.error('❌ [DIAGNOSTIC_SYSTEM] Erro na verificação de saúde', 
        error: e
      );
    }
  }
  
  /// Obtém histórico de diagnósticos
  List<Map<String, dynamic>> getDiagnosticHistory() {
    return List.from(_diagnosticHistory);
  }
  
  /// Obtém estatísticas do sistema de diagnóstico
  Map<String, dynamic> getSystemStatistics() {
    return {
      'isInitialized': _isInitialized,
      'diagnosticHistorySize': _diagnosticHistory.length,
      'performanceMetrics': Map.from(_performanceMetrics),
      'healthMonitorActive': _healthMonitorTimer?.isActive ?? false,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Para o sistema de diagnóstico
  void dispose() {
    _healthMonitorTimer?.cancel();
    _healthMonitorTimer = null;
    _diagnosticHistory.clear();
    _performanceMetrics.clear();
    _isInitialized = false;
    
    EnhancedLogger.info('🛑 [DIAGNOSTIC_SYSTEM] Sistema finalizado');
  }
}