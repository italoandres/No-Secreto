import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/diagnostic_logger.dart';
import '../services/intelligent_cache_manager.dart';
import '../services/query_optimizer.dart';
import '../utils/enhanced_logger.dart';

/// Métricas de performance do sistema
class SystemPerformanceMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkLatency;
  final int activeConnections;
  final DateTime timestamp;

  SystemPerformanceMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.activeConnections,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'cpuUsage': cpuUsage,
        'memoryUsage': memoryUsage,
        'diskUsage': diskUsage,
        'networkLatency': networkLatency,
        'activeConnections': activeConnections,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Métricas de performance da aplicação
class AppPerformanceMetrics {
  final int frameRate;
  final double frameRenderTime;
  final int memoryFootprint;
  final int cacheHitRate;
  final int activeWidgets;
  final int pendingOperations;
  final DateTime timestamp;

  AppPerformanceMetrics({
    required this.frameRate,
    required this.frameRenderTime,
    required this.memoryFootprint,
    required this.cacheHitRate,
    required this.activeWidgets,
    required this.pendingOperations,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'frameRate': frameRate,
        'frameRenderTime': frameRenderTime,
        'memoryFootprint': memoryFootprint,
        'cacheHitRate': cacheHitRate,
        'activeWidgets': activeWidgets,
        'pendingOperations': pendingOperations,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Alerta de performance
class PerformanceAlert {
  final String id;
  final String type;
  final String severity; // low, medium, high, critical
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isResolved;

  PerformanceAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.data,
    required this.timestamp,
    this.isResolved = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'severity': severity,
        'message': message,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'isResolved': isResolved,
      };
}

/// Configuração do monitor de performance
class PerformanceMonitorConfig {
  final Duration monitoringInterval;
  final bool enableSystemMetrics;
  final bool enableAppMetrics;
  final bool enableAlerts;
  final bool enableAutoOptimization;
  final Map<String, double> alertThresholds;

  const PerformanceMonitorConfig({
    this.monitoringInterval = const Duration(seconds: 30),
    this.enableSystemMetrics = true,
    this.enableAppMetrics = true,
    this.enableAlerts = true,
    this.enableAutoOptimization = true,
    this.alertThresholds = const {
      'cpuUsage': 80.0,
      'memoryUsage': 85.0,
      'diskUsage': 90.0,
      'networkLatency': 1000.0,
      'frameRate': 30.0,
      'frameRenderTime': 16.67,
    },
  });
}

/// Monitor de performance e métricas do sistema
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final DiagnosticLogger _logger = DiagnosticLogger();
  final IntelligentCacheManager _cache = IntelligentCacheManager();
  final QueryOptimizer _queryOptimizer = QueryOptimizer();

  final List<SystemPerformanceMetrics> _systemMetricsHistory = [];
  final List<AppPerformanceMetrics> _appMetricsHistory = [];
  final List<PerformanceAlert> _activeAlerts = [];
  final Map<String, Timer> _alertTimers = {};

  Timer? _monitoringTimer;
  PerformanceMonitorConfig _config = const PerformanceMonitorConfig();
  bool _isInitialized = false;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic> _deviceSpecs = {};

  /// Inicializa o monitor de performance
  Future<void> initialize({PerformanceMonitorConfig? config}) async {
    if (_isInitialized) return;

    try {
      _config = config ?? const PerformanceMonitorConfig();

      // Coleta informações do dispositivo
      await _collectDeviceInfo();

      // Inicia monitoramento
      _startMonitoring();

      _isInitialized = true;

      _logger.info(
        DiagnosticLogCategory.performance,
        'Monitor de performance inicializado',
        data: {
          'monitoringInterval': _config.monitoringInterval.inSeconds,
          'enableSystemMetrics': _config.enableSystemMetrics,
          'enableAppMetrics': _config.enableAppMetrics,
          'enableAlerts': _config.enableAlerts,
          'deviceSpecs': _deviceSpecs,
        },
      );

      EnhancedLogger.log('📊 [PERFORMANCE_MONITOR] Monitor inicializado');
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro na inicialização do monitor de performance',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );

      EnhancedLogger.log('❌ [PERFORMANCE_MONITOR] Erro na inicialização: $e');
    }
  }

  /// Coleta métricas atuais do sistema
  Future<SystemPerformanceMetrics> collectSystemMetrics() async {
    try {
      final metrics = SystemPerformanceMetrics(
        cpuUsage: await _getCpuUsage(),
        memoryUsage: await _getMemoryUsage(),
        diskUsage: await _getDiskUsage(),
        networkLatency: await _getNetworkLatency(),
        activeConnections: await _getActiveConnections(),
        timestamp: DateTime.now(),
      );

      if (_config.enableSystemMetrics) {
        _systemMetricsHistory.add(metrics);
        _maintainHistorySize(_systemMetricsHistory, 1000);
      }

      return metrics;
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro ao coletar métricas do sistema',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );

      // Retorna métricas padrão em caso de erro
      return SystemPerformanceMetrics(
        cpuUsage: 0.0,
        memoryUsage: 0.0,
        diskUsage: 0.0,
        networkLatency: 0.0,
        activeConnections: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Coleta métricas atuais da aplicação
  Future<AppPerformanceMetrics> collectAppMetrics() async {
    try {
      final metrics = AppPerformanceMetrics(
        frameRate: await _getFrameRate(),
        frameRenderTime: await _getFrameRenderTime(),
        memoryFootprint: await _getAppMemoryFootprint(),
        cacheHitRate: await _getCacheHitRate(),
        activeWidgets: await _getActiveWidgets(),
        pendingOperations: await _getPendingOperations(),
        timestamp: DateTime.now(),
      );

      if (_config.enableAppMetrics) {
        _appMetricsHistory.add(metrics);
        _maintainHistorySize(_appMetricsHistory, 1000);
      }

      return metrics;
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro ao coletar métricas da aplicação',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );

      // Retorna métricas padrão em caso de erro
      return AppPerformanceMetrics(
        frameRate: 60,
        frameRenderTime: 16.67,
        memoryFootprint: 0,
        cacheHitRate: 0,
        activeWidgets: 0,
        pendingOperations: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Obtém relatório completo de performance
  Map<String, dynamic> getPerformanceReport() {
    final now = DateTime.now();
    final last24h = now.subtract(Duration(hours: 24));
    final lastHour = now.subtract(Duration(hours: 1));

    // Filtra métricas recentes
    final recentSystemMetrics = _systemMetricsHistory
        .where((m) => m.timestamp.isAfter(last24h))
        .toList();

    final recentAppMetrics =
        _appMetricsHistory.where((m) => m.timestamp.isAfter(last24h)).toList();

    final hourlySystemMetrics = _systemMetricsHistory
        .where((m) => m.timestamp.isAfter(lastHour))
        .toList();

    final hourlyAppMetrics =
        _appMetricsHistory.where((m) => m.timestamp.isAfter(lastHour)).toList();

    return {
      'timestamp': now.toIso8601String(),
      'deviceInfo': _deviceSpecs,
      'systemMetrics': {
        'current': recentSystemMetrics.isNotEmpty
            ? recentSystemMetrics.last.toJson()
            : null,
        'last24h': _calculateSystemAverages(recentSystemMetrics),
        'lastHour': _calculateSystemAverages(hourlySystemMetrics),
        'trends': _calculateSystemTrends(recentSystemMetrics),
      },
      'appMetrics': {
        'current':
            recentAppMetrics.isNotEmpty ? recentAppMetrics.last.toJson() : null,
        'last24h': _calculateAppAverages(recentAppMetrics),
        'lastHour': _calculateAppAverages(hourlyAppMetrics),
        'trends': _calculateAppTrends(recentAppMetrics),
      },
      'alerts': {
        'active': _activeAlerts
            .where((a) => !a.isResolved)
            .map((a) => a.toJson())
            .toList(),
        'resolved': _activeAlerts
            .where((a) => a.isResolved)
            .map((a) => a.toJson())
            .toList(),
        'total': _activeAlerts.length,
      },
      'cacheStatistics': _cache.getStatistics(),
      'queryStatistics': _queryOptimizer.getPerformanceStatistics(),
      'recommendations': _generateRecommendations(),
    };
  }

  /// Força otimização do sistema
  Future<void> forceOptimization() async {
    if (!_config.enableAutoOptimization) return;

    try {
      _logger.info(
        DiagnosticLogCategory.performance,
        'Iniciando otimização forçada do sistema',
      );

      // Otimiza cache
      await _cache.forceCleanup();

      // Otimiza queries
      await _queryOptimizer.optimizeConfiguration();

      // Limpa métricas antigas
      _cleanupOldMetrics();

      // Resolve alertas antigos
      _resolveOldAlerts();

      _logger.info(
        DiagnosticLogCategory.performance,
        'Otimização forçada concluída',
        data: {
          'activeAlerts': _activeAlerts.where((a) => !a.isResolved).length,
          'systemMetricsCount': _systemMetricsHistory.length,
          'appMetricsCount': _appMetricsHistory.length,
        },
      );

      EnhancedLogger.log(
          '🚀 [PERFORMANCE_MONITOR] Otimização forçada concluída');
    } catch (e, stackTrace) {
      _logger.error(
        DiagnosticLogCategory.performance,
        'Erro na otimização forçada',
        data: {'error': e.toString()},
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Inicia monitoramento contínuo
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(_config.monitoringInterval, (_) async {
      try {
        // Coleta métricas
        final systemMetrics = await collectSystemMetrics();
        final appMetrics = await collectAppMetrics();

        // Verifica alertas
        if (_config.enableAlerts) {
          await _checkAlerts(systemMetrics, appMetrics);
        }

        // Auto-otimização
        if (_config.enableAutoOptimization) {
          await _performAutoOptimization(systemMetrics, appMetrics);
        }
      } catch (e) {
        _logger.warning(
          DiagnosticLogCategory.performance,
          'Erro no ciclo de monitoramento',
          data: {'error': e.toString()},
        );
      }
    });
  }

  /// Verifica e gera alertas baseados nas métricas
  Future<void> _checkAlerts(
    SystemPerformanceMetrics systemMetrics,
    AppPerformanceMetrics appMetrics,
  ) async {
    final alerts = <PerformanceAlert>[];

    // Alertas de sistema
    if (systemMetrics.cpuUsage > _config.alertThresholds['cpuUsage']!) {
      alerts.add(_createAlert(
        'high_cpu_usage',
        'critical',
        'Uso de CPU alto: ${systemMetrics.cpuUsage.toStringAsFixed(1)}%',
        {'cpuUsage': systemMetrics.cpuUsage},
      ));
    }

    if (systemMetrics.memoryUsage > _config.alertThresholds['memoryUsage']!) {
      alerts.add(_createAlert(
        'high_memory_usage',
        'high',
        'Uso de memória alto: ${systemMetrics.memoryUsage.toStringAsFixed(1)}%',
        {'memoryUsage': systemMetrics.memoryUsage},
      ));
    }

    if (systemMetrics.networkLatency >
        _config.alertThresholds['networkLatency']!) {
      alerts.add(_createAlert(
        'high_network_latency',
        'medium',
        'Latência de rede alta: ${systemMetrics.networkLatency.toStringAsFixed(0)}ms',
        {'networkLatency': systemMetrics.networkLatency},
      ));
    }

    // Alertas de aplicação
    if (appMetrics.frameRate < _config.alertThresholds['frameRate']!) {
      alerts.add(_createAlert(
        'low_frame_rate',
        'high',
        'Frame rate baixo: ${appMetrics.frameRate} FPS',
        {'frameRate': appMetrics.frameRate},
      ));
    }

    if (appMetrics.frameRenderTime >
        _config.alertThresholds['frameRenderTime']!) {
      alerts.add(_createAlert(
        'slow_frame_render',
        'medium',
        'Renderização lenta: ${appMetrics.frameRenderTime.toStringAsFixed(2)}ms',
        {'frameRenderTime': appMetrics.frameRenderTime},
      ));
    }

    // Adiciona novos alertas
    for (final alert in alerts) {
      if (!_hasActiveAlert(alert.type)) {
        _activeAlerts.add(alert);

        _logger.warning(
          DiagnosticLogCategory.performance,
          'Alerta de performance gerado',
          data: alert.toJson(),
        );

        EnhancedLogger.log(
            '⚠️ [PERFORMANCE_MONITOR] ${alert.severity.toUpperCase()}: ${alert.message}');
      }
    }
  }

  /// Executa otimização automática baseada nas métricas
  Future<void> _performAutoOptimization(
    SystemPerformanceMetrics systemMetrics,
    AppPerformanceMetrics appMetrics,
  ) async {
    // Otimização baseada no uso de memória
    if (systemMetrics.memoryUsage > 70.0) {
      await _cache.forceCleanup();

      _logger.debug(
        DiagnosticLogCategory.performance,
        'Auto-otimização: cache limpo devido ao alto uso de memória',
        data: {'memoryUsage': systemMetrics.memoryUsage},
      );
    }

    // Otimização baseada na performance da aplicação
    if (appMetrics.frameRate < 45 || appMetrics.frameRenderTime > 20.0) {
      // Aqui você pode implementar otimizações específicas da UI
      _logger.debug(
        DiagnosticLogCategory.performance,
        'Auto-otimização: performance da UI degradada',
        data: {
          'frameRate': appMetrics.frameRate,
          'frameRenderTime': appMetrics.frameRenderTime,
        },
      );
    }
  }

  /// Coleta informações do dispositivo
  Future<void> _collectDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceSpecs = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceSpecs = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else {
        _deviceSpecs = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      _deviceSpecs = {'platform': 'unknown', 'error': e.toString()};
    }
  }

  // Métodos para coletar métricas específicas (implementações simplificadas)
  Future<double> _getCpuUsage() async {
    // Em uma implementação real, você usaria APIs específicas da plataforma
    return Random().nextDouble() * 100;
  }

  Future<double> _getMemoryUsage() async {
    // Em uma implementação real, você usaria APIs específicas da plataforma
    return Random().nextDouble() * 100;
  }

  Future<double> _getDiskUsage() async {
    // Em uma implementação real, você verificaria o espaço em disco
    return Random().nextDouble() * 100;
  }

  Future<double> _getNetworkLatency() async {
    // Em uma implementação real, você faria ping para um servidor
    return Random().nextDouble() * 1000;
  }

  Future<int> _getActiveConnections() async {
    // Em uma implementação real, você contaria conexões ativas
    return Random().nextInt(10);
  }

  Future<int> _getFrameRate() async {
    // Em uma implementação real, você mediria o FPS atual
    return 60 - Random().nextInt(30);
  }

  Future<double> _getFrameRenderTime() async {
    // Em uma implementação real, você mediria o tempo de renderização
    return 16.67 + Random().nextDouble() * 10;
  }

  Future<int> _getAppMemoryFootprint() async {
    // Em uma implementação real, você mediria o uso de memória da app
    return Random().nextInt(500) * 1024 * 1024; // MB em bytes
  }

  Future<int> _getCacheHitRate() async {
    final stats = _cache.getStatistics();
    return ((stats['hitRate'] as double) * 100).round();
  }

  Future<int> _getActiveWidgets() async {
    // Em uma implementação real, você contaria widgets ativos
    return Random().nextInt(100);
  }

  Future<int> _getPendingOperations() async {
    // Em uma implementação real, você contaria operações pendentes
    return Random().nextInt(20);
  }

  /// Cria um alerta de performance
  PerformanceAlert _createAlert(
    String type,
    String severity,
    String message,
    Map<String, dynamic> data,
  ) {
    return PerformanceAlert(
      id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      severity: severity,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  /// Verifica se já existe um alerta ativo do tipo
  bool _hasActiveAlert(String type) {
    return _activeAlerts
        .any((alert) => alert.type == type && !alert.isResolved);
  }

  /// Calcula médias das métricas do sistema
  Map<String, double> _calculateSystemAverages(
      List<SystemPerformanceMetrics> metrics) {
    if (metrics.isEmpty) return {};

    return {
      'cpuUsage': metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) /
          metrics.length,
      'memoryUsage': metrics.map((m) => m.memoryUsage).reduce((a, b) => a + b) /
          metrics.length,
      'diskUsage': metrics.map((m) => m.diskUsage).reduce((a, b) => a + b) /
          metrics.length,
      'networkLatency':
          metrics.map((m) => m.networkLatency).reduce((a, b) => a + b) /
              metrics.length,
      'activeConnections': metrics
              .map((m) => m.activeConnections.toDouble())
              .reduce((a, b) => a + b) /
          metrics.length,
    };
  }

  /// Calcula médias das métricas da aplicação
  Map<String, double> _calculateAppAverages(
      List<AppPerformanceMetrics> metrics) {
    if (metrics.isEmpty) return {};

    return {
      'frameRate':
          metrics.map((m) => m.frameRate.toDouble()).reduce((a, b) => a + b) /
              metrics.length,
      'frameRenderTime':
          metrics.map((m) => m.frameRenderTime).reduce((a, b) => a + b) /
              metrics.length,
      'memoryFootprint': metrics
              .map((m) => m.memoryFootprint.toDouble())
              .reduce((a, b) => a + b) /
          metrics.length,
      'cacheHitRate': metrics
              .map((m) => m.cacheHitRate.toDouble())
              .reduce((a, b) => a + b) /
          metrics.length,
      'activeWidgets': metrics
              .map((m) => m.activeWidgets.toDouble())
              .reduce((a, b) => a + b) /
          metrics.length,
      'pendingOperations': metrics
              .map((m) => m.pendingOperations.toDouble())
              .reduce((a, b) => a + b) /
          metrics.length,
    };
  }

  /// Calcula tendências das métricas do sistema
  Map<String, String> _calculateSystemTrends(
      List<SystemPerformanceMetrics> metrics) {
    if (metrics.length < 2) return {};

    final recent = metrics.takeLast(10).toList();
    final older = metrics.take(metrics.length - 10).toList();

    if (older.isEmpty) return {};

    final recentAvg = _calculateSystemAverages(recent);
    final olderAvg = _calculateSystemAverages(older);

    return {
      'cpuUsage': _getTrend(olderAvg['cpuUsage']!, recentAvg['cpuUsage']!),
      'memoryUsage':
          _getTrend(olderAvg['memoryUsage']!, recentAvg['memoryUsage']!),
      'networkLatency':
          _getTrend(olderAvg['networkLatency']!, recentAvg['networkLatency']!),
    };
  }

  /// Calcula tendências das métricas da aplicação
  Map<String, String> _calculateAppTrends(List<AppPerformanceMetrics> metrics) {
    if (metrics.length < 2) return {};

    final recent = metrics.takeLast(10).toList();
    final older = metrics.take(metrics.length - 10).toList();

    if (older.isEmpty) return {};

    final recentAvg = _calculateAppAverages(recent);
    final olderAvg = _calculateAppAverages(older);

    return {
      'frameRate': _getTrend(olderAvg['frameRate']!, recentAvg['frameRate']!),
      'frameRenderTime': _getTrend(
          olderAvg['frameRenderTime']!, recentAvg['frameRenderTime']!),
      'memoryFootprint': _getTrend(
          olderAvg['memoryFootprint']!, recentAvg['memoryFootprint']!),
    };
  }

  /// Determina tendência (improving, stable, degrading)
  String _getTrend(double oldValue, double newValue) {
    final change = ((newValue - oldValue) / oldValue * 100).abs();

    if (change < 5) return 'stable';

    // Para métricas onde menor é melhor (latência, uso de recursos)
    return newValue < oldValue ? 'improving' : 'degrading';
  }

  /// Gera recomendações baseadas nas métricas
  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (_systemMetricsHistory.isNotEmpty) {
      final latest = _systemMetricsHistory.last;

      if (latest.memoryUsage > 80) {
        recommendations.add(
            'Considere limpar o cache ou fechar aplicações não utilizadas');
      }

      if (latest.networkLatency > 500) {
        recommendations
            .add('Verifique a conexão de rede ou considere usar cache offline');
      }
    }

    if (_appMetricsHistory.isNotEmpty) {
      final latest = _appMetricsHistory.last;

      if (latest.frameRate < 45) {
        recommendations.add('Otimize a interface para melhorar a fluidez');
      }

      if (latest.cacheHitRate < 50) {
        recommendations
            .add('Ajuste a configuração de cache para melhor performance');
      }
    }

    return recommendations;
  }

  /// Mantém tamanho do histórico
  void _maintainHistorySize<T>(List<T> list, int maxSize) {
    if (list.length > maxSize) {
      list.removeRange(0, list.length - maxSize);
    }
  }

  /// Limpa métricas antigas
  void _cleanupOldMetrics() {
    final cutoff = DateTime.now().subtract(Duration(days: 7));

    _systemMetricsHistory.removeWhere((m) => m.timestamp.isBefore(cutoff));
    _appMetricsHistory.removeWhere((m) => m.timestamp.isBefore(cutoff));
  }

  /// Resolve alertas antigos
  void _resolveOldAlerts() {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));

    for (final alert in _activeAlerts) {
      if (alert.timestamp.isBefore(cutoff) && !alert.isResolved) {
        final index = _activeAlerts.indexOf(alert);
        _activeAlerts[index] = PerformanceAlert(
          id: alert.id,
          type: alert.type,
          severity: alert.severity,
          message: alert.message,
          data: alert.data,
          timestamp: alert.timestamp,
          isResolved: true,
        );
      }
    }
  }

  /// Dispose dos recursos
  void dispose() {
    _monitoringTimer?.cancel();
    _alertTimers.values.forEach((timer) => timer.cancel());

    _systemMetricsHistory.clear();
    _appMetricsHistory.clear();
    _activeAlerts.clear();
    _alertTimers.clear();

    _logger.info(
      DiagnosticLogCategory.performance,
      'Monitor de performance finalizado',
    );

    EnhancedLogger.log('📊 [PERFORMANCE_MONITOR] Monitor finalizado');
  }
}
