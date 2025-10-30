import 'dart:async';
import 'dart:convert';
import '../models/real_notification_model.dart';
import '../services/ui_state_manager.dart';
import '../utils/enhanced_logger.dart';

/// Níveis de log específicos para notificações
enum NotificationLogLevel {
  debug, // Informações detalhadas de debug
  info, // Informações gerais
  warning, // Avisos que precisam atenção
  error, // Erros que impedem funcionamento
  critical // Erros críticos que quebram o sistema
}

/// Categoria de logs de notificação
enum NotificationLogCategory {
  sync, // Sincronização de dados
  conflict, // Resolução de conflitos
  ui, // Interface do usuário
  cache, // Operações de cache
  performance, // Métricas de performance
  validation, // Validação de sistema
  user // Ações do usuário
}

/// Entrada de log estruturada
class NotificationLogEntry {
  final DateTime timestamp;
  final NotificationLogLevel level;
  final NotificationLogCategory category;
  final String userId;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;
  final String? stackTrace;

  NotificationLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.userId,
    required this.message,
    this.data,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString(),
      'category': category.toString(),
      'userId': userId,
      'message': message,
      'data': data,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.toString().toUpperCase()}] ');
    buffer.write('[${category.toString().toUpperCase()}] ');
    buffer.write('[$userId] ');
    buffer.write(message);

    if (data != null) {
      buffer.write(' | Data: ${jsonEncode(data)}');
    }

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    return buffer.toString();
  }
}

/// Logger estruturado para sistema de notificações
class NotificationSyncLogger {
  static final NotificationSyncLogger _instance =
      NotificationSyncLogger._internal();
  factory NotificationSyncLogger() => _instance;
  NotificationSyncLogger._internal();

  final List<NotificationLogEntry> _logHistory = [];
  final Map<String, List<NotificationLogEntry>> _userLogs = {};
  final StreamController<NotificationLogEntry> _logStream =
      StreamController.broadcast();

  static const int _maxLogHistory = 1000;
  static const int _maxUserLogs = 100;

  /// Stream de logs em tempo real
  Stream<NotificationLogEntry> get logStream => _logStream.stream;

  /// Log de conflito detectado
  void logConflictDetected(String userId, List<String> sources,
      {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.warning,
      category: NotificationLogCategory.conflict,
      userId: userId,
      message: 'Conflito detectado entre fontes: ${sources.join(", ")}',
      data: {
        'sources': sources,
        'sourceCount': sources.length,
        ...?data,
      },
    );
  }

  /// Log de tentativa de resolução
  void logResolutionAttempt(String userId, String strategy,
      {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.info,
      category: NotificationLogCategory.conflict,
      userId: userId,
      message: 'Tentando resolução com estratégia: $strategy',
      data: {
        'strategy': strategy,
        ...?data,
      },
    );
  }

  /// Log de sucesso na sincronização
  void logSyncSuccess(String userId, int notificationCount,
      {Duration? duration}) {
    _log(
      level: NotificationLogLevel.info,
      category: NotificationLogCategory.sync,
      userId: userId,
      message: 'Sincronização concluída com sucesso',
      data: {
        'notificationCount': notificationCount,
        'duration': duration?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log de sincronização forçada
  void logForceSync(String userId, String reason,
      {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.info,
      category: NotificationLogCategory.sync,
      userId: userId,
      message: 'Sincronização forçada iniciada: $reason',
      data: {
        'reason': reason,
        'forced': true,
        ...?data,
      },
    );
  }

  /// Log de operação de cache
  void logCacheOperation(String userId, String operation,
      {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.debug,
      category: NotificationLogCategory.cache,
      userId: userId,
      message: 'Operação de cache: $operation',
      data: {
        'operation': operation,
        ...?data,
      },
    );
  }

  /// Log de mudança de estado da UI
  void logUIStateChange(
      String userId, SyncStatus oldStatus, SyncStatus newStatus,
      {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.debug,
      category: NotificationLogCategory.ui,
      userId: userId,
      message: 'Estado da UI alterado: $oldStatus → $newStatus',
      data: {
        'oldStatus': oldStatus.toString(),
        'newStatus': newStatus.toString(),
        'stateChange': true,
        ...?data,
      },
    );
  }

  /// Log de métricas de performance
  void logPerformanceMetric(String userId, String operation, Duration duration,
      {Map<String, dynamic>? data}) {
    final level = duration.inMilliseconds > 5000
        ? NotificationLogLevel.warning
        : NotificationLogLevel.debug;

    _log(
      level: level,
      category: NotificationLogCategory.performance,
      userId: userId,
      message: 'Performance: $operation levou ${duration.inMilliseconds}ms',
      data: {
        'operation': operation,
        'duration': duration.inMilliseconds,
        'slow': duration.inMilliseconds > 5000,
        ...?data,
      },
    );
  }

  /// Log de validação de sistema
  void logValidationResult(String userId, bool isValid, String details,
      {Map<String, dynamic>? data}) {
    _log(
      level: isValid ? NotificationLogLevel.info : NotificationLogLevel.warning,
      category: NotificationLogCategory.validation,
      userId: userId,
      message:
          'Validação do sistema: ${isValid ? "PASSOU" : "FALHOU"} - $details',
      data: {
        'isValid': isValid,
        'details': details,
        ...?data,
      },
    );
  }

  /// Log de ação do usuário
  void logUserAction(String userId, String action,
      {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.info,
      category: NotificationLogCategory.user,
      userId: userId,
      message: 'Ação do usuário: $action',
      data: {
        'action': action,
        'userInitiated': true,
        ...?data,
      },
    );
  }

  /// Log de erro
  void logError(String userId, String error,
      {String? stackTrace, Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.error,
      category: NotificationLogCategory.sync,
      userId: userId,
      message: 'Erro no sistema de notificações',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log crítico
  void logCritical(String userId, String message,
      {String? error, String? stackTrace, Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.critical,
      category: NotificationLogCategory.sync,
      userId: userId,
      message: message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log de fluxo completo de sincronização
  void logSyncFlow(String userId, String step, {Map<String, dynamic>? data}) {
    _log(
      level: NotificationLogLevel.debug,
      category: NotificationLogCategory.sync,
      userId: userId,
      message: 'Fluxo de sincronização: $step',
      data: {
        'step': step,
        'flowTracking': true,
        ...?data,
      },
    );
  }

  /// Método interno de log
  void _log({
    required NotificationLogLevel level,
    required NotificationLogCategory category,
    required String userId,
    required String message,
    Map<String, dynamic>? data,
    String? error,
    String? stackTrace,
  }) {
    final entry = NotificationLogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      userId: userId,
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // Adiciona ao histórico geral
    _logHistory.add(entry);
    if (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }

    // Adiciona ao histórico do usuário
    _userLogs.putIfAbsent(userId, () => []).add(entry);
    final userHistory = _userLogs[userId]!;
    if (userHistory.length > _maxUserLogs) {
      userHistory.removeAt(0);
    }

    // Emite no stream
    _logStream.add(entry);

    // Log no sistema padrão também
    EnhancedLogger.log(entry.toString());

    // Alerta automático para erros críticos
    if (level == NotificationLogLevel.critical) {
      _triggerCriticalAlert(entry);
    }
  }

  /// Dispara alerta para erros críticos
  void _triggerCriticalAlert(NotificationLogEntry entry) {
    EnhancedLogger.log('🚨 [CRITICAL_ALERT] ${entry.message}');
    // Aqui pode ser implementado sistema de alertas (email, push, etc.)
  }

  /// Obtém logs por usuário
  List<NotificationLogEntry> getUserLogs(String userId,
      {NotificationLogLevel? minLevel}) {
    final userLogs = _userLogs[userId] ?? [];

    if (minLevel == null) return List.from(userLogs);

    return userLogs.where((log) => log.level.index >= minLevel.index).toList();
  }

  /// Obtém logs por categoria
  List<NotificationLogEntry> getLogsByCategory(NotificationLogCategory category,
      {int? limit}) {
    var logs = _logHistory.where((log) => log.category == category).toList();

    if (limit != null && logs.length > limit) {
      logs = logs.sublist(logs.length - limit);
    }

    return logs;
  }

  /// Obtém logs por nível
  List<NotificationLogEntry> getLogsByLevel(NotificationLogLevel level,
      {int? limit}) {
    var logs = _logHistory.where((log) => log.level == level).toList();

    if (limit != null && logs.length > limit) {
      logs = logs.sublist(logs.length - limit);
    }

    return logs;
  }

  /// Obtém estatísticas de logs
  Map<String, dynamic> getLogStats() {
    final stats = <String, dynamic>{
      'totalLogs': _logHistory.length,
      'activeUsers': _userLogs.length,
      'levelCounts': <String, int>{},
      'categoryCounts': <String, int>{},
      'recentErrors': 0,
      'criticalCount': 0,
    };

    // Conta por nível
    for (final level in NotificationLogLevel.values) {
      stats['levelCounts'][level.toString()] =
          _logHistory.where((log) => log.level == level).length;
    }

    // Conta por categoria
    for (final category in NotificationLogCategory.values) {
      stats['categoryCounts'][category.toString()] =
          _logHistory.where((log) => log.category == category).length;
    }

    // Erros recentes (última hora)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    stats['recentErrors'] = _logHistory
        .where((log) =>
            log.level == NotificationLogLevel.error &&
            log.timestamp.isAfter(oneHourAgo))
        .length;

    // Críticos totais
    stats['criticalCount'] = _logHistory
        .where((log) => log.level == NotificationLogLevel.critical)
        .length;

    return stats;
  }

  /// Exporta logs em JSON
  String exportLogsAsJson({String? userId, int? limit}) {
    List<NotificationLogEntry> logsToExport;

    if (userId != null) {
      logsToExport = getUserLogs(userId);
    } else {
      logsToExport = List.from(_logHistory);
    }

    if (limit != null && logsToExport.length > limit) {
      logsToExport = logsToExport.sublist(logsToExport.length - limit);
    }

    final jsonData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
      'totalLogs': logsToExport.length,
      'logs': logsToExport.map((log) => log.toJson()).toList(),
    };

    return jsonEncode(jsonData);
  }

  /// Limpa logs antigos
  void cleanupOldLogs({Duration? olderThan}) {
    final cutoff =
        DateTime.now().subtract(olderThan ?? const Duration(days: 7));

    _logHistory.removeWhere((log) => log.timestamp.isBefore(cutoff));

    for (final userId in _userLogs.keys.toList()) {
      _userLogs[userId]!.removeWhere((log) => log.timestamp.isBefore(cutoff));
      if (_userLogs[userId]!.isEmpty) {
        _userLogs.remove(userId);
      }
    }

    EnhancedLogger.log('🧹 [LOGGER] Logs antigos limpos. Cutoff: $cutoff');
  }

  /// Limpa logs de um usuário
  void clearUserLogs(String userId) {
    _userLogs.remove(userId);
    _logHistory.removeWhere((log) => log.userId == userId);

    EnhancedLogger.log('🧹 [LOGGER] Logs do usuário $userId limpos');
  }

  /// Limpa todos os logs
  void clearAllLogs() {
    _logHistory.clear();
    _userLogs.clear();

    EnhancedLogger.log('🧹 [LOGGER] Todos os logs limpos');
  }

  /// Dispose do logger
  void dispose() {
    _logStream.close();
    _logHistory.clear();
    _userLogs.clear();

    EnhancedLogger.log('🧹 [LOGGER] Logger disposed');
  }
}
