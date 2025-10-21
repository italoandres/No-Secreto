import 'dart:async';
import '../services/notification_sync_logger.dart';
import '../services/ui_state_manager.dart';
import '../services/system_validator.dart';
import '../utils/enhanced_logger.dart';

/// Tipos de alerta
enum AlertType {
  performance,    // Problemas de performance
  conflict,       // Conflitos detectados
  error,          // Erros no sistema
  critical,       // Problemas críticos
  validation,     // Falhas de validação
  user            // Alertas para usuário
}

/// Severidade do alerta
enum AlertSeverity {
  low,      // Informativo
  medium,   // Atenção necessária
  high,     // Ação imediata necessária
  critical  // Sistema comprometido
}

/// Alerta do sistema
class NotificationAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final List<String> recommendedActions;
  bool isResolved;
  DateTime? resolvedAt;

  NotificationAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.data,
    this.recommendedActions = const [],
    this.isResolved = false,
    this.resolvedAt,
  });

  void resolve() {
    isResolved = true;
    resolvedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'severity': severity.toString(),
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'recommendedActions': recommendedActions,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}

/// Sistema de alertas para notificações
class NotificationAlertSystem {
  static final NotificationAlertSystem _instance = NotificationAlertSystem._internal();
  factory NotificationAlertSystem() => _instance;
  NotificationAlertSystem._internal();

  final NotificationSyncLogger _logger = NotificationSyncLogger();
  final SystemValidator _validator = SystemValidator();
  
  final List<NotificationAlert> _alerts = [];
  final Map<String, List<NotificationAlert>> _userAlerts = {};
  final StreamController<NotificationAlert> _alertStream = StreamController.broadcast();
  final Map<String, Timer> _monitoringTimers = {};
  
  static const int _maxAlerts = 500;
  static const int _maxUserAlerts = 50;

  /// Stream de alertas em tempo real
  Stream<NotificationAlert> get alertStream => _alertStream.stream;

  /// Inicia monitoramento automático
  void startAutomaticMonitoring(String userId) {
    EnhancedLogger.log('🤖 [ALERT_SYSTEM] Iniciando monitoramento automático para: $userId');
    
    _monitoringTimers[userId]?.cancel();
    
    // Monitora logs em tempo real
    _logger.logStream.listen((logEntry) {
      if (logEntry.userId == userId) {
        _processLogEntry(logEntry);
      }
    });
    
    // Validação periódica
    _monitoringTimers[userId] = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _performPeriodicValidation(userId),
    );
  }

  /// Processa entrada de log para alertas
  void _processLogEntry(NotificationLogEntry logEntry) {
    switch (logEntry.level) {
      case NotificationLogLevel.error:
        _createErrorAlert(logEntry);
        break;
      case NotificationLogLevel.critical:
        _createCriticalAlert(logEntry);
        break;
      case NotificationLogLevel.warning:
        _processWarningLog(logEntry);
        break;
      default:
        break;
    }
  }

  /// Cria alerta de erro
  void _createErrorAlert(NotificationLogEntry logEntry) {
    final alert = NotificationAlert(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.error,
      severity: AlertSeverity.high,
      userId: logEntry.userId,
      title: 'Erro no Sistema de Notificações',
      message: logEntry.message,
      timestamp: logEntry.timestamp,
      data: {
        'logEntry': logEntry.toJson(),
        'error': logEntry.error,
        'category': logEntry.category.toString(),
      },
      recommendedActions: [
        'Verificar conectividade',
        'Forçar sincronização',
        'Reiniciar sistema se necessário',
      ],
    );
    
    _addAlert(alert);
  }

  /// Cria alerta crítico
  void _createCriticalAlert(NotificationLogEntry logEntry) {
    final alert = NotificationAlert(
      id: 'critical_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.critical,
      severity: AlertSeverity.critical,
      userId: logEntry.userId,
      title: 'PROBLEMA CRÍTICO - Sistema Comprometido',
      message: logEntry.message,
      timestamp: logEntry.timestamp,
      data: {
        'logEntry': logEntry.toJson(),
        'error': logEntry.error,
        'stackTrace': logEntry.stackTrace,
      },
      recommendedActions: [
        'AÇÃO IMEDIATA NECESSÁRIA',
        'Reiniciar sistema',
        'Verificar integridade dos dados',
        'Contatar suporte técnico',
      ],
    );
    
    _addAlert(alert);
    _triggerCriticalNotification(alert);
  }

  /// Processa log de warning
  void _processWarningLog(NotificationLogEntry logEntry) {
    // Só cria alerta se for conflito ou performance
    if (logEntry.category == NotificationLogCategory.conflict) {
      _createConflictAlert(logEntry);
    } else if (logEntry.category == NotificationLogCategory.performance) {
      _createPerformanceAlert(logEntry);
    }
  }

  /// Cria alerta de conflito
  void _createConflictAlert(NotificationLogEntry logEntry) {
    final alert = NotificationAlert(
      id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.conflict,
      severity: AlertSeverity.medium,
      userId: logEntry.userId,
      title: 'Conflito de Dados Detectado',
      message: logEntry.message,
      timestamp: logEntry.timestamp,
      data: logEntry.data,
      recommendedActions: [
        'Aguardar resolução automática',
        'Forçar sincronização se persistir',
        'Verificar consistência dos dados',
      ],
    );
    
    _addAlert(alert);
  }

  /// Cria alerta de performance
  void _createPerformanceAlert(NotificationLogEntry logEntry) {
    final duration = logEntry.data?['duration'] as int?;
    if (duration == null || duration < 5000) return; // Só alerta se > 5s
    
    final alert = NotificationAlert(
      id: 'perf_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.performance,
      severity: duration > 10000 ? AlertSeverity.high : AlertSeverity.medium,
      userId: logEntry.userId,
      title: 'Performance Degradada',
      message: 'Operação lenta detectada: ${logEntry.message}',
      timestamp: logEntry.timestamp,
      data: logEntry.data,
      recommendedActions: [
        'Verificar conectividade de rede',
        'Limpar cache se necessário',
        'Monitorar performance contínua',
      ],
    );
    
    _addAlert(alert);
  }

  /// Executa validação periódica
  Future<void> _performPeriodicValidation(String userId) async {
    try {
      final result = await _validator.validateSystem(userId);
      
      if (!result.isHealthy) {
        _createValidationAlert(userId, result);
      } else {
        // Resolve alertas de validação anteriores
        _resolveAlertsByType(userId, AlertType.validation);
      }
      
    } catch (e) {
      EnhancedLogger.log('❌ [ALERT_SYSTEM] Erro na validação periódica: $e');
    }
  }

  /// Cria alerta de validação
  void _createValidationAlert(String userId, ValidationResult result) {
    final severity = result.isCritical 
        ? AlertSeverity.critical 
        : result.hasWarnings 
            ? AlertSeverity.medium 
            : AlertSeverity.low;
    
    final alert = NotificationAlert(
      id: 'validation_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.validation,
      severity: severity,
      userId: userId,
      title: 'Falha na Validação do Sistema',
      message: result.message,
      timestamp: result.timestamp,
      data: result.details,
      recommendedActions: result.recommendations,
    );
    
    _addAlert(alert);
  }

  /// Adiciona alerta ao sistema
  void _addAlert(NotificationAlert alert) {
    // Adiciona ao histórico geral
    _alerts.add(alert);
    if (_alerts.length > _maxAlerts) {
      _alerts.removeAt(0);
    }
    
    // Adiciona ao histórico do usuário
    _userAlerts.putIfAbsent(alert.userId, () => []).add(alert);
    final userAlerts = _userAlerts[alert.userId]!;
    if (userAlerts.length > _maxUserAlerts) {
      userAlerts.removeAt(0);
    }
    
    // Emite no stream
    _alertStream.add(alert);
    
    // Log do alerta
    EnhancedLogger.log('🚨 [ALERT] ${alert.severity.toString().toUpperCase()}: ${alert.title}');
    
    _logger.logUserAction(
      alert.userId,
      'Alert created: ${alert.type}',
      data: {
        'alertId': alert.id,
        'severity': alert.severity.toString(),
        'title': alert.title,
      },
    );
  }

  /// Dispara notificação crítica
  void _triggerCriticalNotification(NotificationAlert alert) {
    EnhancedLogger.log('🚨🚨🚨 [CRITICAL_NOTIFICATION] ${alert.title}: ${alert.message}');
    
    // Aqui pode ser implementado:
    // - Push notification
    // - Email de emergência
    // - SMS para administradores
    // - Webhook para sistemas externos
  }

  /// Resolve alertas por tipo
  void _resolveAlertsByType(String userId, AlertType type) {
    final userAlerts = _userAlerts[userId] ?? [];
    
    for (final alert in userAlerts) {
      if (alert.type == type && !alert.isResolved) {
        alert.resolve();
        
        _logger.logUserAction(
          userId,
          'Alert resolved: ${alert.type}',
          data: {
            'alertId': alert.id,
            'resolvedAt': alert.resolvedAt?.toIso8601String(),
          },
        );
      }
    }
  }

  /// Cria alerta manual
  void createManualAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    List<String>? recommendedActions,
  }) {
    final alert = NotificationAlert(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      severity: severity,
      userId: userId,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data,
      recommendedActions: recommendedActions ?? [],
    );
    
    _addAlert(alert);
  }

  /// Resolve alerta específico
  void resolveAlert(String alertId) {
    final alert = _alerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => throw ArgumentError('Alert not found: $alertId'),
    );
    
    alert.resolve();
    
    _logger.logUserAction(
      alert.userId,
      'Alert manually resolved',
      data: {
        'alertId': alertId,
        'type': alert.type.toString(),
      },
    );
  }

  /// Obtém alertas por usuário
  List<NotificationAlert> getUserAlerts(String userId, {bool includeResolved = false}) {
    final userAlerts = _userAlerts[userId] ?? [];
    
    if (includeResolved) {
      return List.from(userAlerts);
    }
    
    return userAlerts.where((alert) => !alert.isResolved).toList();
  }

  /// Obtém alertas por severidade
  List<NotificationAlert> getAlertsBySeverity(AlertSeverity severity, {bool includeResolved = false}) {
    var alerts = _alerts.where((alert) => alert.severity == severity);
    
    if (!includeResolved) {
      alerts = alerts.where((alert) => !alert.isResolved);
    }
    
    return alerts.toList();
  }

  /// Obtém alertas críticos não resolvidos
  List<NotificationAlert> getCriticalAlerts() {
    return _alerts
        .where((alert) => alert.severity == AlertSeverity.critical && !alert.isResolved)
        .toList();
  }

  /// Obtém estatísticas de alertas
  Map<String, dynamic> getAlertStats() {
    final stats = <String, dynamic>{
      'totalAlerts': _alerts.length,
      'activeUsers': _userAlerts.length,
      'unresolvedAlerts': _alerts.where((a) => !a.isResolved).length,
      'criticalAlerts': getCriticalAlerts().length,
      'severityCounts': <String, int>{},
      'typeCounts': <String, int>{},
      'recentAlerts': 0,
    };
    
    // Conta por severidade
    for (final severity in AlertSeverity.values) {
      stats['severityCounts'][severity.toString()] = 
          _alerts.where((a) => a.severity == severity && !a.isResolved).length;
    }
    
    // Conta por tipo
    for (final type in AlertType.values) {
      stats['typeCounts'][type.toString()] = 
          _alerts.where((a) => a.type == type && !a.isResolved).length;
    }
    
    // Alertas recentes (última hora)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    stats['recentAlerts'] = _alerts
        .where((a) => a.timestamp.isAfter(oneHourAgo))
        .length;
    
    return stats;
  }

  /// Para monitoramento de um usuário
  void stopMonitoring(String userId) {
    EnhancedLogger.log('⏹️ [ALERT_SYSTEM] Parando monitoramento para: $userId');
    
    _monitoringTimers[userId]?.cancel();
    _monitoringTimers.remove(userId);
  }

  /// Limpa alertas antigos
  void cleanupOldAlerts({Duration? olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
    
    _alerts.removeWhere((alert) => alert.timestamp.isBefore(cutoff));
    
    for (final userId in _userAlerts.keys.toList()) {
      _userAlerts[userId]!.removeWhere((alert) => alert.timestamp.isBefore(cutoff));
      if (_userAlerts[userId]!.isEmpty) {
        _userAlerts.remove(userId);
      }
    }
    
    EnhancedLogger.log('🧹 [ALERT_SYSTEM] Alertas antigos limpos. Cutoff: $cutoff');
  }

  /// Dispose do sistema de alertas
  void dispose() {
    for (final timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _monitoringTimers.clear();
    
    _alertStream.close();
    _alerts.clear();
    _userAlerts.clear();
    
    EnhancedLogger.log('🧹 [ALERT_SYSTEM] Sistema de alertas disposed');
  }
}