import 'dart:async';
import 'dart:convert';
import '../services/notification_sync_logger.dart';
import '../services/notification_alert_system.dart';
import '../services/unified_notification_interface.dart';
import '../services/ui_state_manager.dart';
import '../services/system_validator.dart';
import '../services/conflict_resolver.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Ferramentas de debugging para sistema de notificações
class NotificationDebugTools {
  static final NotificationSyncLogger _logger = NotificationSyncLogger();
  static final NotificationAlertSystem _alertSystem = NotificationAlertSystem();
  static final UnifiedNotificationInterface _unifiedInterface = UnifiedNotificationInterface();
  static final UIStateManager _uiStateManager = UIStateManager();
  static final SystemValidator _validator = SystemValidator();
  static final ConflictResolver _conflictResolver = ConflictResolver();

  /// Executa diagnóstico completo do sistema
  static Future<Map<String, dynamic>> runCompleteDiagnostic(String userId) async {
    EnhancedLogger.log('🔍 [DEBUG_TOOLS] Executando diagnóstico completo para: $userId');
    
    final diagnostic = <String, dynamic>{
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'systemHealth': {},
      'performance': {},
      'logs': {},
      'alerts': {},
      'conflicts': {},
      'recommendations': [],
    };
    
    try {
      // 1. Validação do sistema
      diagnostic['systemHealth'] = await _diagnoseSystemHealth(userId);
      
      // 2. Análise de performance
      diagnostic['performance'] = await _analyzePerformance(userId);
      
      // 3. Análise de logs
      diagnostic['logs'] = _analyzeLogs(userId);
      
      // 4. Análise de alertas
      diagnostic['alerts'] = _analyzeAlerts(userId);
      
      // 5. Análise de conflitos
      diagnostic['conflicts'] = _analyzeConflicts(userId);
      
      // 6. Gera recomendações
      diagnostic['recommendations'] = _generateRecommendations(diagnostic);
      
      EnhancedLogger.log('✅ [DEBUG_TOOLS] Diagnóstico completo concluído');
      return diagnostic;
      
    } catch (e) {
      EnhancedLogger.log('❌ [DEBUG_TOOLS] Erro no diagnóstico: $e');
      diagnostic['error'] = e.toString();
      return diagnostic;
    }
  }

  /// Diagnóstica saúde do sistema
  static Future<Map<String, dynamic>> _diagnoseSystemHealth(String userId) async {
    final validationResult = await _validator.validateSystem(userId);
    final systemStats = _unifiedInterface.getSystemStats();
    final uiStats = _uiStateManager.getUIStats();
    
    return {
      'validation': {
        'status': validationResult.status.toString(),
        'message': validationResult.message,
        'isHealthy': validationResult.isHealthy,
        'details': validationResult.details,
        'recommendations': validationResult.recommendations,
      },
      'systemStats': systemStats,
      'uiStats': uiStats,
      'hasCache': _unifiedInterface.hasCachedData(userId),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Analisa performance do sistema
  static Future<Map<String, dynamic>> _analyzePerformance(String userId) async {
    final startTime = DateTime.now();
    
    // Testa operações básicas
    final operations = <String, int>{};
    
    // Teste de cache
    var opStart = DateTime.now();
    _unifiedInterface.getCachedNotifications(userId);
    operations['cache_read'] = DateTime.now().difference(opStart).inMilliseconds;
    
    // Teste de força sync
    opStart = DateTime.now();
    try {
      await _unifiedInterface.forceSync(userId);
      operations['force_sync'] = DateTime.now().difference(opStart).inMilliseconds;
    } catch (e) {
      operations['force_sync'] = -1; // Indica erro
    }
    
    // Teste de validação
    opStart = DateTime.now();
    await _validator.validateSystem(userId);
    operations['validation'] = DateTime.now().difference(opStart).inMilliseconds;
    
    final totalTime = DateTime.now().difference(startTime).inMilliseconds;
    
    return {
      'totalTime': totalTime,
      'operations': operations,
      'performance': _classifyPerformance(operations),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Classifica performance
  static String _classifyPerformance(Map<String, int> operations) {
    final avgTime = operations.values.where((t) => t > 0).fold<int>(0, (sum, t) => sum + t) / 
                   operations.values.where((t) => t > 0).length;
    
    if (avgTime < 1000) return 'excellent';
    if (avgTime < 3000) return 'good';
    if (avgTime < 5000) return 'fair';
    return 'poor';
  }

  /// Analisa logs do sistema
  static Map<String, dynamic> _analyzeLogs(String userId) {
    final userLogs = _logger.getUserLogs(userId);
    final recentLogs = userLogs.where(
      (log) => DateTime.now().difference(log.timestamp).inHours < 1
    ).toList();
    
    final logStats = <String, int>{};
    for (final level in NotificationLogLevel.values) {
      logStats[level.toString()] = userLogs.where((log) => log.level == level).length;
    }
    
    final categoryStats = <String, int>{};
    for (final category in NotificationLogCategory.values) {
      categoryStats[category.toString()] = userLogs.where((log) => log.category == category).length;
    }
    
    return {
      'totalLogs': userLogs.length,
      'recentLogs': recentLogs.length,
      'levelStats': logStats,
      'categoryStats': categoryStats,
      'hasErrors': logStats['NotificationLogLevel.error'] ?? 0 > 0,
      'hasCritical': logStats['NotificationLogLevel.critical'] ?? 0 > 0,
      'lastLogTime': userLogs.isNotEmpty ? userLogs.last.timestamp.toIso8601String() : null,
    };
  }

  /// Analisa alertas do sistema
  static Map<String, dynamic> _analyzeAlerts(String userId) {
    final userAlerts = _alertSystem.getUserAlerts(userId, includeResolved: true);
    final activeAlerts = _alertSystem.getUserAlerts(userId, includeResolved: false);
    
    final severityStats = <String, int>{};
    for (final severity in AlertSeverity.values) {
      severityStats[severity.toString()] = activeAlerts.where((alert) => alert.severity == severity).length;
    }
    
    final typeStats = <String, int>{};
    for (final type in AlertType.values) {
      typeStats[type.toString()] = activeAlerts.where((alert) => alert.type == type).length;
    }
    
    return {
      'totalAlerts': userAlerts.length,
      'activeAlerts': activeAlerts.length,
      'resolvedAlerts': userAlerts.length - activeAlerts.length,
      'severityStats': severityStats,
      'typeStats': typeStats,
      'hasCritical': severityStats['AlertSeverity.critical'] ?? 0 > 0,
      'lastAlertTime': userAlerts.isNotEmpty ? userAlerts.last.timestamp.toIso8601String() : null,
    };
  }

  /// Analisa conflitos do sistema
  static Map<String, dynamic> _analyzeConflicts(String userId) {
    final resolutionHistory = _conflictResolver.getResolutionHistory(userId);
    final conflictStats = _conflictResolver.getConflictStats();
    
    return {
      'resolutionHistory': resolutionHistory.length,
      'systemStats': conflictStats,
      'hasRecentConflicts': resolutionHistory.any(
        (resolution) => DateTime.now().difference(resolution.resolvedAt).inHours < 1
      ),
      'lastResolutionTime': resolutionHistory.isNotEmpty 
          ? resolutionHistory.last.resolvedAt.toIso8601String() 
          : null,
    };
  }

  /// Gera recomendações baseadas no diagnóstico
  static List<String> _generateRecommendations(Map<String, dynamic> diagnostic) {
    final recommendations = <String>[];
    
    // Recomendações de saúde do sistema
    final systemHealth = diagnostic['systemHealth'] as Map<String, dynamic>;
    if (!(systemHealth['validation']['isHealthy'] as bool)) {
      recommendations.addAll(systemHealth['validation']['recommendations'] as List<String>);
    }
    
    // Recomendações de performance
    final performance = diagnostic['performance'] as Map<String, dynamic>;
    final perfClass = performance['performance'] as String;
    if (perfClass == 'poor') {
      recommendations.addAll([
        'Performance crítica - verificar conectividade',
        'Considerar limpeza de cache',
        'Verificar recursos do sistema',
      ]);
    } else if (perfClass == 'fair') {
      recommendations.add('Performance degradada - monitorar sistema');
    }
    
    // Recomendações de logs
    final logs = diagnostic['logs'] as Map<String, dynamic>;
    if (logs['hasErrors'] as bool) {
      recommendations.add('Erros detectados nos logs - investigar causas');
    }
    if (logs['hasCritical'] as bool) {
      recommendations.add('CRÍTICO: Problemas graves detectados - ação imediata necessária');
    }
    
    // Recomendações de alertas
    final alerts = diagnostic['alerts'] as Map<String, dynamic>;
    if (alerts['hasCritical'] as bool) {
      recommendations.add('Alertas críticos ativos - resolver imediatamente');
    }
    if ((alerts['activeAlerts'] as int) > 5) {
      recommendations.add('Muitos alertas ativos - revisar sistema');
    }
    
    // Recomendações de conflitos
    final conflicts = diagnostic['conflicts'] as Map<String, dynamic>;
    if (conflicts['hasRecentConflicts'] as bool) {
      recommendations.add('Conflitos recentes detectados - monitorar estabilidade');
    }
    
    // Recomendação padrão se tudo estiver bem
    if (recommendations.isEmpty) {
      recommendations.add('Sistema funcionando normalmente');
    }
    
    return recommendations;
  }

  /// Cria snapshot do estado atual do sistema
  static Map<String, dynamic> createSystemSnapshot(String userId) {
    EnhancedLogger.log('📸 [DEBUG_TOOLS] Criando snapshot do sistema para: $userId');
    
    return {
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'unifiedInterface': _unifiedInterface.getSystemStats(),
      'uiState': _uiStateManager.getCurrentState(userId)?.copyWith().toString(),
      'logs': _logger.getLogStats(),
      'alerts': _alertSystem.getAlertStats(),
      'conflicts': _conflictResolver.getConflictStats(),
      'validation': _validator.getValidationStats(),
    };
  }

  /// Simula cenário de teste
  static Future<void> simulateTestScenario(String userId, String scenario) async {
    EnhancedLogger.log('🎭 [DEBUG_TOOLS] Simulando cenário: $scenario para: $userId');
    
    switch (scenario) {
      case 'force_sync':
        await _unifiedInterface.forceSync(userId);
        break;
        
      case 'create_conflict':
        // Simula conflito forçando dados inconsistentes
        await _conflictResolver.detectConflict(userId, []);
        break;
        
      case 'trigger_error':
        _logger.logError(userId, 'Erro simulado para teste');
        break;
        
      case 'performance_issue':
        _logger.logPerformanceMetric(userId, 'operação_lenta_simulada', const Duration(seconds: 10));
        break;
        
      case 'critical_alert':
        _alertSystem.createManualAlert(
          type: AlertType.critical,
          severity: AlertSeverity.critical,
          userId: userId,
          title: 'Alerta Crítico Simulado',
          message: 'Este é um teste de alerta crítico',
          recommendedActions: ['Verificar sistema', 'Contatar suporte'],
        );
        break;
        
      default:
        EnhancedLogger.log('❌ [DEBUG_TOOLS] Cenário desconhecido: $scenario');
    }
  }

  /// Exporta dados de debug
  static String exportDebugData(String userId, {bool includeFullLogs = false}) {
    EnhancedLogger.log('📤 [DEBUG_TOOLS] Exportando dados de debug para: $userId');
    
    final debugData = {
      'userId': userId,
      'exportedAt': DateTime.now().toIso8601String(),
      'systemSnapshot': createSystemSnapshot(userId),
      'userLogs': includeFullLogs 
          ? _logger.getUserLogs(userId).map((log) => log.toJson()).toList()
          : _logger.getUserLogs(userId, minLevel: NotificationLogLevel.warning)
              .map((log) => log.toJson()).toList(),
      'userAlerts': _alertSystem.getUserAlerts(userId, includeResolved: true)
          .map((alert) => alert.toJson()).toList(),
      'conflictHistory': _conflictResolver.getResolutionHistory(userId)
          .map((resolution) => {
            'resolvedNotifications': resolution.resolvedNotifications.length,
            'conflictSources': resolution.conflictSources,
            'strategy': resolution.strategy.toString(),
            'resolvedAt': resolution.resolvedAt.toIso8601String(),
          }).toList(),
    };
    
    return jsonEncode(debugData);
  }

  /// Monitora sistema em tempo real para debug
  static StreamSubscription monitorSystemForDebug(String userId, {Duration? duration}) {
    EnhancedLogger.log('👁️ [DEBUG_TOOLS] Iniciando monitoramento de debug para: $userId');
    
    final subscription = _uiStateManager
        .getUIStateStream(userId)
        .listen(
          (state) {
            final snapshot = createSystemSnapshot(userId);
            EnhancedLogger.log('📊 [DEBUG_MONITOR] Estado: ${state.syncStatus} | '
                'Notificações: ${state.totalCount} | '
                'Snapshot: ${jsonEncode(snapshot)}');
          },
          onError: (error) {
            EnhancedLogger.log('❌ [DEBUG_MONITOR] Erro no monitoramento: $error');
          },
        );
    
    // Auto-cancela após duração especificada
    if (duration != null) {
      Timer(duration, () {
        subscription.cancel();
        EnhancedLogger.log('⏰ [DEBUG_MONITOR] Monitoramento finalizado após ${duration.inSeconds}s');
      });
    }
    
    return subscription;
  }

  /// Executa bateria completa de testes de debug
  static Future<Map<String, dynamic>> runDebugTestSuite(String userId) async {
    EnhancedLogger.log('🧪 [DEBUG_TOOLS] Executando bateria de testes de debug para: $userId');
    
    final results = <String, dynamic>{
      'userId': userId,
      'startTime': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'summary': <String, dynamic>{},
    };
    
    try {
      // Teste 1: Diagnóstico completo
      final diagnostic = await runCompleteDiagnostic(userId);
      results['tests']['diagnostic'] = {
        'status': 'completed',
        'result': diagnostic,
      };
      
      // Teste 2: Simulação de cenários
      final scenarios = ['force_sync', 'create_conflict', 'performance_issue'];
      for (final scenario in scenarios) {
        try {
          await simulateTestScenario(userId, scenario);
          results['tests']['scenario_$scenario'] = {'status': 'completed'};
        } catch (e) {
          results['tests']['scenario_$scenario'] = {
            'status': 'failed',
            'error': e.toString(),
          };
        }
      }
      
      // Teste 3: Snapshot do sistema
      results['tests']['snapshot'] = {
        'status': 'completed',
        'result': createSystemSnapshot(userId),
      };
      
      // Resumo
      final completedTests = results['tests'].values
          .where((test) => test['status'] == 'completed')
          .length;
      final totalTests = results['tests'].length;
      
      results['summary'] = {
        'totalTests': totalTests,
        'completedTests': completedTests,
        'failedTests': totalTests - completedTests,
        'successRate': (completedTests / totalTests * 100).toStringAsFixed(1),
        'endTime': DateTime.now().toIso8601String(),
      };
      
      EnhancedLogger.log('✅ [DEBUG_TOOLS] Bateria de testes concluída: ${results['summary']['successRate']}% sucesso');
      return results;
      
    } catch (e) {
      results['error'] = e.toString();
      results['summary'] = {
        'status': 'failed',
        'error': e.toString(),
        'endTime': DateTime.now().toIso8601String(),
      };
      
      EnhancedLogger.log('❌ [DEBUG_TOOLS] Falha na bateria de testes: $e');
      return results;
    }
  }
}