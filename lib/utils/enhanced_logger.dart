import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

/// Sistema de logging aprimorado para debug e monitoramento
class EnhancedLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isDebugMode = kDebugMode;

  /// Configura o modo debug
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }

  /// Log geral (compatibilidade)
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    safePrint('[$timestamp] $message');
  }

  /// Log de informação geral
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage('INFO', message, tag);
    safePrint(logMessage);

    if (_isDebugMode && data != null) {
      safePrint('📊 Data: ${data.toString()}');
    }

    _saveToFirestore('info', message, tag, data);
  }

  /// Log de erro
  static void error(String message,
      {String? tag,
      dynamic error,
      StackTrace? stackTrace,
      Map<String, dynamic>? data}) {
    final logMessage = _formatMessage('ERROR', message, tag);
    safePrint('❌ $logMessage');

    if (error != null) {
      safePrint('🔍 Error Details: $error');
    }

    if (stackTrace != null && _isDebugMode) {
      safePrint('📍 Stack Trace: $stackTrace');
    }

    if (data != null) {
      safePrint('📊 Error Data: ${data.toString()}');
    }

    _saveToFirestore('error', message, tag, {
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      ...?data,
    });
  }

  /// Log de warning
  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage('WARNING', message, tag);
    safePrint('⚠️ $logMessage');

    if (_isDebugMode && data != null) {
      safePrint('📊 Warning Data: ${data.toString()}');
    }

    _saveToFirestore('warning', message, tag, data);
  }

  /// Log de debug (apenas em modo debug)
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (!_isDebugMode) return;

    final logMessage = _formatMessage('DEBUG', message, tag);
    safePrint('🔍 $logMessage');

    if (data != null) {
      safePrint('📊 Debug Data: ${data.toString()}');
    }
  }

  /// Log de sucesso
  static void success(String message,
      {String? tag, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage('SUCCESS', message, tag);
    safePrint('✅ $logMessage');

    if (_isDebugMode && data != null) {
      safePrint('📊 Success Data: ${data.toString()}');
    }

    _saveToFirestore('success', message, tag, data);
  }

  /// Log de operação em progresso
  static void progress(String message,
      {String? tag, double? percentage, Map<String, dynamic>? data}) {
    final progressInfo = percentage != null
        ? ' (${(percentage * 100).toStringAsFixed(1)}%)'
        : '';
    final logMessage = _formatMessage('PROGRESS', '$message$progressInfo', tag);
    safePrint('🔄 $logMessage');

    if (_isDebugMode && data != null) {
      safePrint('📊 Progress Data: ${data.toString()}');
    }
  }

  /// Log específico para operações de perfil
  static void profile(String operation, String userId,
      {String? profileId, Map<String, dynamic>? data}) {
    final message =
        'Profile $operation for user $userId${profileId != null ? ' (profile: $profileId)' : ''}';
    info(message, tag: 'PROFILE', data: data);
  }

  /// Log específico para sincronização de dados
  static void sync(String message, String userId,
      {Map<String, dynamic>? data}) {
    info(message, tag: 'SYNC', data: {'userId': userId, ...?data});
  }

  /// Log específico para migração de dados
  static void migration(String message,
      {String? profileId, String? userId, List<String>? changes}) {
    info(message, tag: 'MIGRATION', data: {
      if (profileId != null) 'profileId': profileId,
      if (userId != null) 'userId': userId,
      if (changes != null) 'changes': changes,
    });
  }

  /// Log específico para upload de imagens
  static void image(String message,
      {String? userId, String? imageUrl, Map<String, dynamic>? data}) {
    info(message, tag: 'IMAGE', data: {
      if (userId != null) 'userId': userId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      ...?data,
    });
  }

  /// Formata a mensagem de log
  static String _formatMessage(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final tagInfo = tag != null ? '[$tag] ' : '';
    return '$timestamp [$level] $tagInfo$message';
  }

  /// Salva log no Firestore (apenas para logs importantes)
  static Future<void> _saveToFirestore(String level, String message,
      String? tag, Map<String, dynamic>? data) async {
    // Só salva logs importantes no Firestore para não sobrecarregar
    if (!['error', 'warning'].contains(level)) return;

    try {
      await _firestore.collection('app_logs').add({
        'level': level,
        'message': message,
        'tag': tag,
        'data': data,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'platform': 'flutter',
      });
    } catch (e) {
      // Não queremos que o logging cause erros no app
      safePrint('⚠️ Failed to save log to Firestore: $e');
    }
  }

  /// Limpa logs antigos do Firestore
  static Future<void> cleanOldLogs({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final query = await _firestore
          .collection('app_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      info('Cleaned ${query.docs.length} old log entries', tag: 'MAINTENANCE');
    } catch (e) {
      error('Failed to clean old logs', error: e, tag: 'MAINTENANCE');
    }
  }

  /// Obtém estatísticas de logs
  static Future<Map<String, int>> getLogStats() async {
    try {
      final query = await _firestore.collection('app_logs').get();
      final stats = <String, int>{};

      for (final doc in query.docs) {
        final level = doc.data()['level'] as String;
        stats[level] = (stats[level] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      error('Failed to get log stats', error: e, tag: 'MAINTENANCE');
      return {};
    }
  }
}
