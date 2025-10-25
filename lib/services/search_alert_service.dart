import 'dart:async';
import '../utils/enhanced_logger.dart';
import 'search_analytics_service.dart';

/// Serviço de alertas para monitoramento de busca
/// Detecta anomalias e problemas em tempo real
class SearchAlertService {
  static SearchAlertService? _instance;
  static SearchAlertService get instance =>
      _instance ??= SearchAlertService._();

  SearchAlertService._() {
    _initialize();
  }

  /// Alertas ativos
  final List<SearchAlert> _activeAlerts = [];

  /// Configurações de thresholds
  final Map<String, AlertThreshold> _thresholds = {};

  /// Timer para verificação periódica
  Timer? _monitoringTimer;

  /// Callbacks para notificações
  final List<Function(SearchAlert)> _alertCallbacks = [];

  /// Configurações padrão
  static const Duration monitoringInterval = Duration(minutes: 1);
  static const int maxActiveAlerts = 50;

  /// Inicializa o serviço de alertas
  void _initialize() {
    _setupDefaultThresholds();
    _startMonitoring();

    EnhancedLogger.info('Search alert service initialized',
        tag: 'SEARCH_ALERT_SERVICE',
        data: {
          'monitoringInterval': monitoringInterval.inMinutes,
          'maxActiveAlerts': maxActiveAlerts,
          'thresholdsCount': _thresholds.length,
        });
  }

  /// Para o serviço de alertas
  void dispose() {
    _monitoringTimer?.cancel();
    _activeAlerts.clear();
    _thresholds.clear();
    _alertCallbacks.clear();

    EnhancedLogger.info('Search alert service disposed',
        tag: 'SEARCH_ALERT_SERVICE');
  }

  /// Configura thresholds padrão
  void _setupDefaultThresholds() {
    _thresholds['high_execution_time'] = AlertThreshold(
      name: 'Tempo de Execução Alto',
      description: 'Tempo médio de execução acima do normal',
      threshold: 3000.0, // 3 segundos
      severity: AlertSeverity.warning,
      enabled: true,
    );

    _thresholds['low_success_rate'] = AlertThreshold(
      name: 'Taxa de Sucesso Baixa',
      description: 'Muitas buscas retornando resultados vazios',
      threshold: 0.7, // 70% de sucesso mínimo
      severity: AlertSeverity.critical,
      enabled: true,
    );

    _thresholds['high_fallback_usage'] = AlertThreshold(
      name: 'Uso Excessivo de Fallback',
      description: 'Estratégia de fallback sendo usada frequentemente',
      threshold: 0.3, // 30% máximo de fallback
      severity: AlertSeverity.warning,
      enabled: true,
    );

    _thresholds['low_cache_hit_rate'] = AlertThreshold(
      name: 'Taxa de Cache Baixa',
      description: 'Cache não está sendo efetivo',
      threshold: 0.2, // 20% mínimo de cache hit
      severity: AlertSeverity.info,
      enabled: true,
    );

    _thresholds['high_error_rate'] = AlertThreshold(
      name: 'Taxa de Erro Alta',
      description: 'Muitos erros ocorrendo nas buscas',
      threshold: 0.1, // 10% máximo de erros
      severity: AlertSeverity.critical,
      enabled: true,
    );

    _thresholds['performance_degradation'] = AlertThreshold(
      name: 'Degradação de Performance',
      description: 'Performance piorando ao longo do tempo',
      threshold: 1.5, // 50% de aumento no tempo médio
      severity: AlertSeverity.warning,
      enabled: true,
    );
  }

  /// Inicia monitoramento periódico
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(monitoringInterval, (_) {
      _checkForAlerts();
    });
  }

  /// Verifica se há condições de alerta
  void _checkForAlerts() {
    try {
      // Versão simplificada - não verifica analytics por enquanto
      _cleanupOldAlerts();

      EnhancedLogger.debug('Alert monitoring completed',
          tag: 'SEARCH_ALERT_SERVICE',
          data: {
            'activeAlerts': _activeAlerts.length,
            'thresholdsChecked': _thresholds.length,
          });
    } catch (e) {
      EnhancedLogger.error('Alert monitoring failed',
          tag: 'SEARCH_ALERT_SERVICE', error: e);
    }
  }

  /// Avalia se um threshold foi violado
  bool _evaluateThreshold(
    AlertThreshold threshold,
    Map<String, dynamic> summary,
    List performanceTrends,
  ) {
    switch (threshold.name) {
      case 'Tempo de Execução Alto':
        final avgTime = summary['avgExecutionTime'] as double;
        return avgTime > threshold.threshold;

      case 'Taxa de Sucesso Baixa':
        final successRate = summary['successRate'] as double;
        return successRate < threshold.threshold;

      case 'Uso Excessivo de Fallback':
        // Implementar lógica para detectar uso excessivo de fallback
        return _checkFallbackUsage() > threshold.threshold;

      case 'Taxa de Cache Baixa':
        final cacheHitRate = summary['cacheHitRate'] as double;
        return cacheHitRate < threshold.threshold;

      case 'Taxa de Erro Alta':
        // Implementar lógica para calcular taxa de erro
        return _calculateErrorRate() > threshold.threshold;

      case 'Degradação de Performance':
        return _checkPerformanceDegradation(performanceTrends) >
            threshold.threshold;

      default:
        return false;
    }
  }

  /// Verifica uso de fallback
  double _checkFallbackUsage() {
    final analytics = SearchAnalyticsService.instance.getAnalyticsReport();
    final strategyUsage = analytics['strategyUsage'] as Map<String, dynamic>;

    if (strategyUsage.containsKey('fallback')) {
      final fallbackData = strategyUsage['fallback'] as Map<String, dynamic>;
      return (fallbackData['percentage'] as double) / 100.0;
    }

    return 0.0;
  }

  /// Calcula taxa de erro
  double _calculateErrorRate() {
    // Implementar lógica para calcular taxa de erro baseada nos eventos
    // Por enquanto, retorna 0 como placeholder
    return 0.0;
  }

  /// Verifica degradação de performance
  double _checkPerformanceDegradation(List performanceTrends) {
    if (performanceTrends.length < 2) return 0.0;

    final recent = performanceTrends.last as Map<String, dynamic>;
    final previous =
        performanceTrends[performanceTrends.length - 2] as Map<String, dynamic>;

    final recentTime = recent['avgExecutionTime'] as double;
    final previousTime = previous['avgExecutionTime'] as double;

    if (previousTime == 0) return 0.0;

    return recentTime / previousTime;
  }

  /// Cria um novo alerta
  void _createAlert(AlertThreshold threshold, Map<String, dynamic> summary) {
    // Verificar se já existe alerta similar ativo
    final existingAlert = _activeAlerts.firstWhere(
      (alert) =>
          alert.type == threshold.name &&
          DateTime.now().difference(alert.timestamp).inMinutes < 30,
      orElse: () => SearchAlert(
        id: '',
        type: '',
        message: '',
        severity: AlertSeverity.info,
        timestamp: DateTime.now(),
        data: {},
      ),
    );

    if (existingAlert.id.isNotEmpty) {
      // Alerta similar já existe, não criar duplicado
      return;
    }

    final alert = SearchAlert(
      id: _generateAlertId(),
      type: threshold.name,
      message: _generateAlertMessage(threshold, summary),
      severity: threshold.severity,
      timestamp: DateTime.now(),
      data: {
        'threshold': threshold.threshold,
        'currentValue': _getCurrentValue(threshold.name, summary),
        'summary': summary,
      },
    );

    _activeAlerts.add(alert);

    // Limitar número de alertas ativos
    if (_activeAlerts.length > maxActiveAlerts) {
      _activeAlerts.removeAt(0);
    }

    // Notificar callbacks
    for (final callback in _alertCallbacks) {
      try {
        callback(alert);
      } catch (e) {
        EnhancedLogger.error('Alert callback failed',
            tag: 'SEARCH_ALERT_SERVICE', error: e);
      }
    }

    EnhancedLogger.warning('Search alert created',
        tag: 'SEARCH_ALERT_SERVICE',
        data: {
          'alertId': alert.id,
          'type': alert.type,
          'severity': alert.severity.toString(),
          'message': alert.message,
        });
  }

  /// Gera mensagem de alerta
  String _generateAlertMessage(
      AlertThreshold threshold, Map<String, dynamic> summary) {
    final currentValue = _getCurrentValue(threshold.name, summary);

    switch (threshold.name) {
      case 'Tempo de Execução Alto':
        return 'Tempo médio de execução está em ${currentValue.toStringAsFixed(0)}ms (limite: ${threshold.threshold.toStringAsFixed(0)}ms)';

      case 'Taxa de Sucesso Baixa':
        return 'Taxa de sucesso está em ${(currentValue * 100).toStringAsFixed(1)}% (mínimo: ${(threshold.threshold * 100).toStringAsFixed(1)}%)';

      case 'Uso Excessivo de Fallback':
        return 'Fallback sendo usado em ${(currentValue * 100).toStringAsFixed(1)}% das buscas (máximo: ${(threshold.threshold * 100).toStringAsFixed(1)}%)';

      case 'Taxa de Cache Baixa':
        return 'Taxa de cache hit está em ${(currentValue * 100).toStringAsFixed(1)}% (mínimo: ${(threshold.threshold * 100).toStringAsFixed(1)}%)';

      case 'Taxa de Erro Alta':
        return 'Taxa de erro está em ${(currentValue * 100).toStringAsFixed(1)}% (máximo: ${(threshold.threshold * 100).toStringAsFixed(1)}%)';

      case 'Degradação de Performance':
        return 'Performance degradou ${((currentValue - 1) * 100).toStringAsFixed(1)}% (limite: ${((threshold.threshold - 1) * 100).toStringAsFixed(1)}%)';

      default:
        return threshold.description;
    }
  }

  /// Obtém valor atual para comparação
  double _getCurrentValue(String thresholdName, Map<String, dynamic> summary) {
    switch (thresholdName) {
      case 'Tempo de Execução Alto':
        return summary['avgExecutionTime'] as double;
      case 'Taxa de Sucesso Baixa':
        return summary['successRate'] as double;
      case 'Uso Excessivo de Fallback':
        return _checkFallbackUsage();
      case 'Taxa de Cache Baixa':
        return summary['cacheHitRate'] as double;
      case 'Taxa de Erro Alta':
        return _calculateErrorRate();
      case 'Degradação de Performance':
        final analytics = SearchAnalyticsService.instance.getAnalyticsReport();
        final trends = analytics['performanceTrends'] as List;
        return _checkPerformanceDegradation(trends);
      default:
        return 0.0;
    }
  }

  /// Gera ID único para alerta
  String _generateAlertId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'alert_$timestamp';
  }

  /// Remove alertas antigos
  void _cleanupOldAlerts() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    _activeAlerts.removeWhere((alert) => alert.timestamp.isBefore(cutoffTime));
  }

  /// Adiciona callback para notificações de alerta
  void addAlertCallback(Function(SearchAlert) callback) {
    _alertCallbacks.add(callback);
  }

  /// Remove callback de notificações
  void removeAlertCallback(Function(SearchAlert) callback) {
    _alertCallbacks.remove(callback);
  }

  /// Obtém alertas ativos
  List<SearchAlert> getActiveAlerts() {
    return List.unmodifiable(_activeAlerts);
  }

  /// Obtém alertas por severidade
  List<SearchAlert> getAlertsBySeverity(AlertSeverity severity) {
    return _activeAlerts.where((alert) => alert.severity == severity).toList();
  }

  /// Marca alerta como resolvido
  void resolveAlert(String alertId) {
    _activeAlerts.removeWhere((alert) => alert.id == alertId);

    EnhancedLogger.info('Alert resolved',
        tag: 'SEARCH_ALERT_SERVICE', data: {'alertId': alertId});
  }

  /// Configura threshold personalizado
  void setThreshold(String name, AlertThreshold threshold) {
    _thresholds[name] = threshold;

    EnhancedLogger.info('Alert threshold updated',
        tag: 'SEARCH_ALERT_SERVICE',
        data: {
          'name': name,
          'threshold': threshold.threshold,
          'severity': threshold.severity.toString(),
        });
  }

  /// Obtém configurações de threshold
  Map<String, AlertThreshold> getThresholds() {
    return Map.unmodifiable(_thresholds);
  }

  /// Força verificação de alertas
  void checkAlertsNow() {
    _checkForAlerts();
  }

  /// Limpa todos os alertas
  void clearAllAlerts() {
    _activeAlerts.clear();

    EnhancedLogger.info('All alerts cleared', tag: 'SEARCH_ALERT_SERVICE');
  }
}

/// Modelo de alerta
class SearchAlert {
  final String id;
  final String type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const SearchAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'severity': severity.toString(),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

/// Configuração de threshold para alertas
class AlertThreshold {
  final String name;
  final String description;
  final double threshold;
  final AlertSeverity severity;
  final bool enabled;

  const AlertThreshold({
    required this.name,
    required this.description,
    required this.threshold,
    required this.severity,
    required this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'threshold': threshold,
      'severity': severity.toString(),
      'enabled': enabled,
    };
  }
}

/// Severidade do alerta
enum AlertSeverity {
  info,
  warning,
  critical,
}
