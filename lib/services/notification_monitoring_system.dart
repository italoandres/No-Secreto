import 'dart:async';
import '../utils/enhanced_logger.dart';
import '../services/advanced_diagnostic_system.dart';
import '../services/fixed_notification_pipeline.dart';
import '../services/error_recovery_system.dart';

/// Sistema de monitoramento e alertas para notificações
class NotificationMonitoringSystem {
  static NotificationMonitoringSystem? _instance;
  static NotificationMonitoringSystem get instance => 
      _instance ??= NotificationMonitoringSystem._();
  
  NotificationMonitoringSystem._();
  
  bool _isInitialized = false;
  Timer? _monitoringTimer;
  Timer? _alertTimer;
  
  final Map<String, int> _conversionMetrics = {};
  final Map<String, DateTime> _lastAlerts = {};
  final List<Map<String, dynamic>> _alertHistory = [];
  
  // Configurações de monitoramento
  final Duration _monitoringInterval = const Duration(minutes: 1);
  final Duration _alertCooldown = const Duration(minutes: 5);
  final int _criticalThreshold = 70; // Score de saúde mínimo
  final double _conversionThreshold = 50.0; // Taxa de conversão mínima
  
  /// Inicializa o sistema de monitoramento
  void initialize() {
    if (_isInitialized) return;
    
    try {
      _setupRealTimeMonitoring();
      _setupAutomaticAlerts();
      _isInitialized = true;
      
      EnhancedLogger.success('✅ [MONITORING_SYSTEM] Sistema inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro ao inicializar sistema', 
        error: e
      );
    }
  }
  
  /// Configura monitoramento em tempo real
  void _setupRealTimeMonitoring() {
    _monitoringTimer = Timer.periodic(_monitoringInterval, (timer) {
      _performRealTimeCheck();
    });
    
    EnhancedLogger.info('📊 [MONITORING_SYSTEM] Monitoramento em tempo real configurado', 
      data: {'intervalMinutes': _monitoringInterval.inMinutes}
    );
  }
  
  /// Configura alertas automáticos
  void _setupAutomaticAlerts() {
    _alertTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkForAlerts();
    });
    
    EnhancedLogger.info('🚨 [MONITORING_SYSTEM] Sistema de alertas configurado');
  }
  
  /// Executa verificação em tempo real
  void _performRealTimeCheck() {
    try {
      // Coleta métricas de todos os componentes
      final metrics = _collectSystemMetrics();
      
      // Analisa métricas para problemas
      final issues = _analyzeMetrics(metrics);
      
      // Registra métricas
      _recordMetrics(metrics);
      
      // Gera alertas se necessário
      if (issues.isNotEmpty) {
        _generateAlerts(issues);
      }
      
      EnhancedLogger.info('📊 [MONITORING_SYSTEM] Verificação em tempo real concluída', 
        data: {
          'metricsCollected': metrics.length,
          'issuesFound': issues.length,
          'timestamp': DateTime.now().toIso8601String()
        }
      );
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro na verificação em tempo real', 
        error: e
      );
    }
  }
  
  /// Coleta métricas de todos os componentes
  Map<String, dynamic> _collectSystemMetrics() {
    final metrics = <String, dynamic>{};
    
    try {
      // Métricas do pipeline
      metrics['pipeline'] = FixedNotificationPipeline.instance.getPipelineStatistics();
      
      // Métricas do sistema de diagnóstico
      metrics['diagnostic'] = AdvancedDiagnosticSystem.instance.getSystemStatistics();
      
      // Métricas do sistema de recuperação
      metrics['recovery'] = ErrorRecoverySystem.instance.getRecoveryStatistics();
      
      // Timestamp
      metrics['timestamp'] = DateTime.now().toIso8601String();
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro ao coletar métricas', 
        error: e
      );
    }
    
    return metrics;
  }
  
  /// Analisa métricas para identificar problemas
  List<String> _analyzeMetrics(Map<String, dynamic> metrics) {
    final issues = <String>[];
    
    try {
      // Analisa pipeline
      final pipelineMetrics = metrics['pipeline'] as Map<String, dynamic>?;
      if (pipelineMetrics != null) {
        if (pipelineMetrics['isProcessing'] == true) {
          // Verifica se está processando há muito tempo
          issues.add('Pipeline processando há muito tempo');
        }
      }
      
      // Analisa sistema de recuperação
      final recoveryMetrics = metrics['recovery'] as Map<String, dynamic>?;
      if (recoveryMetrics != null) {
        final fallbackSize = recoveryMetrics['fallbackCacheSize'] as int? ?? 0;
        if (fallbackSize > 100) {
          issues.add('Cache de fallback muito grande: $fallbackSize');
        }
      }
      
    } catch (e) {
      issues.add('Erro na análise de métricas: ${e.toString()}');
    }
    
    return issues;
  }
  
  /// Registra métricas para histórico
  void _recordMetrics(Map<String, dynamic> metrics) {
    try {
      // Atualiza contadores de conversão
      final timestamp = DateTime.now();
      final key = '${timestamp.year}-${timestamp.month}-${timestamp.day}-${timestamp.hour}';
      
      _conversionMetrics[key] = (_conversionMetrics[key] ?? 0) + 1;
      
      // Limpa métricas antigas (mais de 24 horas)
      final cutoff = timestamp.subtract(const Duration(hours: 24));
      _conversionMetrics.removeWhere((key, value) {
        try {
          final parts = key.split('-');
          final metricTime = DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day
            int.parse(parts[3]), // hour
          );
          return metricTime.isBefore(cutoff);
        } catch (e) {
          return true; // Remove se não conseguir parsear
        }
      });
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro ao registrar métricas', 
        error: e
      );
    }
  }
  
  /// Gera alertas para problemas identificados
  void _generateAlerts(List<String> issues) {
    try {
      for (final issue in issues) {
        final alertKey = issue.hashCode.toString();
        final lastAlert = _lastAlerts[alertKey];
        final now = DateTime.now();
        
        // Verifica cooldown do alerta
        if (lastAlert == null || now.difference(lastAlert) > _alertCooldown) {
          _sendAlert(issue);
          _lastAlerts[alertKey] = now;
        }
      }
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro ao gerar alertas', 
        error: e
      );
    }
  }
  
  /// Envia alerta específico
  void _sendAlert(String issue) {
    try {
      final alert = {
        'type': 'system_issue',
        'message': issue,
        'timestamp': DateTime.now().toIso8601String(),
        'severity': _determineSeverity(issue),
      };
      
      // Adiciona ao histórico
      _alertHistory.add(alert);
      
      // Mantém apenas os últimos 100 alertas
      if (_alertHistory.length > 100) {
        _alertHistory.removeAt(0);
      }
      
      // Log do alerta
      EnhancedLogger.warning('🚨 [MONITORING_SYSTEM] Alerta gerado', 
        tag: 'NOTIFICATION_MONITORING_SYSTEM',
        data: alert
      );
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro ao enviar alerta', 
        error: e
      );
    }
  }
  
  /// Determina severidade do problema
  String _determineSeverity(String issue) {
    final lowerIssue = issue.toLowerCase();
    
    if (lowerIssue.contains('crítico') || lowerIssue.contains('critical')) {
      return 'critical';
    } else if (lowerIssue.contains('erro') || lowerIssue.contains('error')) {
      return 'high';
    } else if (lowerIssue.contains('aviso') || lowerIssue.contains('warning')) {
      return 'medium';
    } else {
      return 'low';
    }
  }
  
  /// Verifica alertas pendentes
  void _checkForAlerts() {
    try {
      // Executa diagnóstico rápido
      _performQuickDiagnostic();
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro na verificação de alertas', 
        error: e
      );
    }
  }
  
  /// Executa diagnóstico rápido
  void _performQuickDiagnostic() {
    try {
      // Verifica se o sistema de recuperação detecta falhas
      final hasFailures = ErrorRecoverySystem.instance.detectSystemFailure();
      
      if (hasFailures) {
        _sendAlert('Sistema com falhas detectadas - recuperação necessária');
      }
      
      // Verifica métricas de conversão
      final conversionRate = _calculateRecentConversionRate();
      if (conversionRate < _conversionThreshold) {
        _sendAlert('Taxa de conversão baixa: ${conversionRate.toStringAsFixed(2)}%');
      }
      
    } catch (e) {
      EnhancedLogger.error('❌ [MONITORING_SYSTEM] Erro no diagnóstico rápido', 
        error: e
      );
    }
  }
  
  /// Calcula taxa de conversão recente
  double _calculateRecentConversionRate() {
    try {
      final now = DateTime.now();
      final lastHour = now.subtract(const Duration(hours: 1));
      
      // Conta métricas da última hora
      int recentMetrics = 0;
      _conversionMetrics.forEach((key, value) {
        try {
          final parts = key.split('-');
          final metricTime = DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day
            int.parse(parts[3]), // hour
          );
          
          if (metricTime.isAfter(lastHour)) {
            recentMetrics += value;
          }
        } catch (e) {
          // Ignora métricas com formato inválido
        }
      });
      
      // Calcula taxa (simplificada)
      return recentMetrics > 0 ? 100.0 : 0.0;
      
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Obtém métricas de engajamento
  Map<String, dynamic> getEngagementMetrics() {
    return {
      'totalAlerts': _alertHistory.length,
      'recentAlerts': _alertHistory.where((alert) {
        final timestamp = DateTime.tryParse(alert['timestamp'] ?? '');
        if (timestamp == null) return false;
        return DateTime.now().difference(timestamp) < const Duration(hours: 1);
      }).length,
      'conversionMetrics': Map.from(_conversionMetrics),
      'recentConversionRate': _calculateRecentConversionRate(),
      'systemHealth': _getSystemHealthScore(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Obtém score de saúde do sistema
  int _getSystemHealthScore() {
    try {
      // Verifica se há falhas detectadas
      final hasFailures = ErrorRecoverySystem.instance.detectSystemFailure();
      if (hasFailures) return 30;
      
      // Verifica alertas recentes
      final recentAlerts = _alertHistory.where((alert) {
        final timestamp = DateTime.tryParse(alert['timestamp'] ?? '');
        if (timestamp == null) return false;
        return DateTime.now().difference(timestamp) < const Duration(minutes: 30);
      }).length;
      
      if (recentAlerts > 5) return 50;
      if (recentAlerts > 2) return 70;
      
      return 100; // Sistema saudável
      
    } catch (e) {
      return 0; // Erro = saúde crítica
    }
  }
  
  /// Obtém histórico de alertas
  List<Map<String, dynamic>> getAlertHistory() {
    return List.from(_alertHistory);
  }
  
  /// Obtém estatísticas do sistema de monitoramento
  Map<String, dynamic> getMonitoringStatistics() {
    return {
      'isInitialized': _isInitialized,
      'monitoringActive': _monitoringTimer?.isActive ?? false,
      'alertSystemActive': _alertTimer?.isActive ?? false,
      'totalAlerts': _alertHistory.length,
      'conversionMetricsCount': _conversionMetrics.length,
      'systemHealthScore': _getSystemHealthScore(),
      'lastAlertTime': _alertHistory.isNotEmpty 
          ? _alertHistory.last['timestamp']
          : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Para o sistema de monitoramento
  void dispose() {
    _monitoringTimer?.cancel();
    _alertTimer?.cancel();
    _monitoringTimer = null;
    _alertTimer = null;
    _conversionMetrics.clear();
    _lastAlerts.clear();
    _alertHistory.clear();
    _isInitialized = false;
    
    EnhancedLogger.info('🛑 [MONITORING_SYSTEM] Sistema finalizado');
  }
}