import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_local_storage.dart';
import '../services/unified_notification_interface.dart';
import '../services/notification_sync_logger.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Tipo de recuperação
enum RecoveryType { backup, cache, server, hybrid }

/// Status de recuperação
enum RecoveryStatus { notStarted, scanning, recovering, completed, failed }

/// Resultado de recuperação
class RecoveryResult {
  final bool success;
  final String message;
  final int recoveredCount;
  final int totalFound;
  final RecoveryType recoveryType;
  final DateTime timestamp;
  final List<String> errors;

  RecoveryResult({
    required this.success,
    required this.message,
    required this.recoveredCount,
    required this.totalFound,
    required this.recoveryType,
    required this.timestamp,
    this.errors = const [],
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'recoveredCount': recoveredCount,
        'totalFound': totalFound,
        'recoveryType': recoveryType.toString(),
        'timestamp': timestamp.toIso8601String(),
        'errors': errors,
      };
}

/// Dados de recuperação encontrados
class RecoveryData {
  final String source;
  final List<RealNotificationModel> notifications;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  RecoveryData({
    required this.source,
    required this.notifications,
    required this.timestamp,
    required this.metadata,
  });
}

/// Serviço de recuperação de dados perdidos
class DataRecoveryService {
  static final DataRecoveryService _instance = DataRecoveryService._internal();
  factory DataRecoveryService() => _instance;
  DataRecoveryService._internal();

  final NotificationLocalStorage _localStorage = NotificationLocalStorage();
  final UnifiedNotificationInterface _unifiedInterface =
      UnifiedNotificationInterface();
  final NotificationSyncLogger _logger = NotificationSyncLogger();

  final StreamController<RecoveryProgress> _progressController =
      StreamController.broadcast();
  final Map<String, RecoveryResult> _recoveryHistory = {};

  bool _isRecovering = false;

  /// Stream de progresso de recuperação
  Stream<RecoveryProgress> get recoveryProgressStream =>
      _progressController.stream;

  /// Verifica se está em processo de recuperação
  bool get isRecovering => _isRecovering;

  /// Escaneia dados perdidos para um usuário
  Future<List<RecoveryData>> scanForLostData(String userId) async {
    try {
      EnhancedLogger.log(
          '🔍 [DATA_RECOVERY] Escaneando dados perdidos para: $userId');

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.scanning,
        progress: 0.0,
        message: 'Iniciando escaneamento...',
      ));

      final recoveryData = <RecoveryData>[];

      // 1. Verifica backup local
      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.scanning,
        progress: 0.2,
        message: 'Verificando backups locais...',
      ));

      final backupData = await _scanLocalBackups(userId);
      if (backupData != null) {
        recoveryData.add(backupData);
      }

      // 2. Verifica cache em memória
      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.scanning,
        progress: 0.4,
        message: 'Verificando cache em memória...',
      ));

      final cacheData = await _scanMemoryCache(userId);
      if (cacheData != null) {
        recoveryData.add(cacheData);
      }

      // 3. Verifica dados temporários
      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.scanning,
        progress: 0.6,
        message: 'Verificando dados temporários...',
      ));

      final tempData = await _scanTemporaryData(userId);
      if (tempData != null) {
        recoveryData.add(tempData);
      }

      // 4. Verifica servidor (se online)
      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.scanning,
        progress: 0.8,
        message: 'Verificando dados do servidor...',
      ));

      final serverData = await _scanServerData(userId);
      if (serverData != null) {
        recoveryData.add(serverData);
      }

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.completed,
        progress: 1.0,
        message:
            'Escaneamento concluído. ${recoveryData.length} fontes encontradas.',
      ));

      EnhancedLogger.log(
          '✅ [DATA_RECOVERY] Escaneamento concluído: ${recoveryData.length} fontes');
      return recoveryData;
    } catch (e) {
      EnhancedLogger.log('❌ [DATA_RECOVERY] Erro no escaneamento: $e');

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.failed,
        progress: 0.0,
        message: 'Erro no escaneamento: $e',
      ));

      return [];
    }
  }

  /// Recupera dados perdidos automaticamente
  Future<RecoveryResult> recoverLostData(String userId,
      {RecoveryType? preferredType}) async {
    if (_isRecovering) {
      return RecoveryResult(
        success: false,
        message: 'Recuperação já em andamento',
        recoveredCount: 0,
        totalFound: 0,
        recoveryType: RecoveryType.hybrid,
        timestamp: DateTime.now(),
      );
    }

    try {
      _isRecovering = true;
      EnhancedLogger.log(
          '🔄 [DATA_RECOVERY] Iniciando recuperação automática para: $userId');

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.recovering,
        progress: 0.0,
        message: 'Iniciando recuperação...',
      ));

      // 1. Escaneia dados disponíveis
      final availableData = await scanForLostData(userId);

      if (availableData.isEmpty) {
        return RecoveryResult(
          success: false,
          message: 'Nenhum dado de recuperação encontrado',
          recoveredCount: 0,
          totalFound: 0,
          recoveryType: RecoveryType.hybrid,
          timestamp: DateTime.now(),
        );
      }

      // 2. Seleciona melhor fonte de recuperação
      final selectedData =
          _selectBestRecoverySource(availableData, preferredType);

      // 3. Executa recuperação
      final result = await _performRecovery(userId, selectedData);

      // 4. Salva histórico de recuperação
      _recoveryHistory[userId] = result;
      await _saveRecoveryHistory(userId, result);

      _logger.logUserAction(userId, 'Data recovery completed', data: {
        'success': result.success,
        'recoveredCount': result.recoveredCount,
        'recoveryType': result.recoveryType.toString(),
      });

      return result;
    } catch (e) {
      EnhancedLogger.log('❌ [DATA_RECOVERY] Erro na recuperação: $e');

      final result = RecoveryResult(
        success: false,
        message: 'Erro na recuperação: $e',
        recoveredCount: 0,
        totalFound: 0,
        recoveryType: preferredType ?? RecoveryType.hybrid,
        timestamp: DateTime.now(),
        errors: [e.toString()],
      );

      _recoveryHistory[userId] = result;
      return result;
    } finally {
      _isRecovering = false;
    }
  }

  /// Recupera dados de uma fonte específica
  Future<RecoveryResult> recoverFromSource(
      String userId, RecoveryData source) async {
    try {
      EnhancedLogger.log(
          '🔄 [DATA_RECOVERY] Recuperando de fonte: ${source.source}');

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.recovering,
        progress: 0.0,
        message: 'Recuperando de ${source.source}...',
      ));

      return await _performRecovery(userId, source);
    } catch (e) {
      EnhancedLogger.log('❌ [DATA_RECOVERY] Erro na recuperação da fonte: $e');

      return RecoveryResult(
        success: false,
        message: 'Erro na recuperação da fonte: $e',
        recoveredCount: 0,
        totalFound: source.notifications.length,
        recoveryType: _getRecoveryTypeFromSource(source.source),
        timestamp: DateTime.now(),
        errors: [e.toString()],
      );
    }
  }

  /// Cria backup de emergência
  Future<bool> createEmergencyBackup(
      String userId, List<RealNotificationModel> notifications) async {
    try {
      EnhancedLogger.log(
          '💾 [DATA_RECOVERY] Criando backup de emergência para: $userId');

      final prefs = await SharedPreferences.getInstance();

      final backup = {
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'count': notifications.length,
        'type': 'emergency',
        'version': '1.0',
      };

      final key = 'emergency_backup_$userId';
      final success = await prefs.setString(key, jsonEncode(backup));

      if (success) {
        EnhancedLogger.log(
            '✅ [DATA_RECOVERY] Backup de emergência criado: ${notifications.length} notificações');
      }

      return success;
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro ao criar backup de emergência: $e');
      return false;
    }
  }

  /// Restaura backup de emergência
  Future<List<RealNotificationModel>> restoreEmergencyBackup(
      String userId) async {
    try {
      EnhancedLogger.log(
          '🔄 [DATA_RECOVERY] Restaurando backup de emergência para: $userId');

      final prefs = await SharedPreferences.getInstance();
      final key = 'emergency_backup_$userId';
      final backupString = prefs.getString(key);

      if (backupString == null) {
        EnhancedLogger.log(
            '📭 [DATA_RECOVERY] Nenhum backup de emergência encontrado');
        return [];
      }

      final backup = jsonDecode(backupString);
      final notificationsJson = backup['notifications'] as List;

      final notifications = notificationsJson
          .map((json) => RealNotificationModel.fromJson(json))
          .toList();

      EnhancedLogger.log(
          '✅ [DATA_RECOVERY] Backup de emergência restaurado: ${notifications.length} notificações');
      return notifications;
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro ao restaurar backup de emergência: $e');
      return [];
    }
  }

  /// Obtém histórico de recuperação
  RecoveryResult? getRecoveryHistory(String userId) {
    return _recoveryHistory[userId];
  }

  /// Obtém estatísticas de recuperação
  Map<String, dynamic> getRecoveryStats(String userId) {
    final history = _recoveryHistory[userId];

    return {
      'hasHistory': history != null,
      'lastRecovery': history?.timestamp.toIso8601String(),
      'lastRecoverySuccess': history?.success,
      'lastRecoveredCount': history?.recoveredCount ?? 0,
      'lastRecoveryType': history?.recoveryType.toString(),
      'isRecovering': _isRecovering,
      'availableSources': _getAvailableSourcesCount(userId),
    };
  }

  /// Valida integridade dos dados
  Future<bool> validateDataIntegrity(
      String userId, List<RealNotificationModel> notifications) async {
    try {
      EnhancedLogger.log('🔍 [DATA_RECOVERY] Validando integridade dos dados');

      // Verifica se há notificações duplicadas
      final ids = notifications.map((n) => n.id).toSet();
      if (ids.length != notifications.length) {
        EnhancedLogger.log(
            '⚠️ [DATA_RECOVERY] Notificações duplicadas encontradas');
        return false;
      }

      // Verifica se todas as notificações têm dados válidos
      for (final notification in notifications) {
        if (notification.id.isEmpty ||
            notification.userId.isEmpty ||
            notification.message.isEmpty) {
          EnhancedLogger.log(
              '⚠️ [DATA_RECOVERY] Notificação com dados inválidos: ${notification.id}');
          return false;
        }
      }

      // Verifica timestamps
      final now = DateTime.now();
      for (final notification in notifications) {
        if (notification.timestamp.isAfter(now)) {
          EnhancedLogger.log(
              '⚠️ [DATA_RECOVERY] Notificação com timestamp futuro: ${notification.id}');
          return false;
        }
      }

      EnhancedLogger.log('✅ [DATA_RECOVERY] Integridade dos dados validada');
      return true;
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro na validação de integridade: $e');
      return false;
    }
  }

  /// Escaneia backups locais
  Future<RecoveryData?> _scanLocalBackups(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.contains('backup') && key.contains(userId));

      if (keys.isEmpty) return null;

      final allNotifications = <RealNotificationModel>[];
      DateTime? latestTimestamp;

      for (final key in keys) {
        try {
          final backupString = prefs.getString(key);
          if (backupString != null) {
            final backup = jsonDecode(backupString);
            final timestamp = DateTime.parse(backup['timestamp']);

            if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
              latestTimestamp = timestamp;
            }

            final notificationsJson =
                backup['data'] ?? backup['notifications'] ?? [];
            final notifications = (notificationsJson as List)
                .map((json) => RealNotificationModel.fromJson(json))
                .toList();

            allNotifications.addAll(notifications);
          }
        } catch (e) {
          EnhancedLogger.log(
              '⚠️ [DATA_RECOVERY] Erro ao processar backup: $key');
        }
      }

      if (allNotifications.isEmpty) return null;

      // Remove duplicatas
      final uniqueNotifications = _removeDuplicates(allNotifications);

      return RecoveryData(
        source: 'local_backup',
        notifications: uniqueNotifications,
        timestamp: latestTimestamp ?? DateTime.now(),
        metadata: {
          'backupCount': keys.length,
          'totalFound': allNotifications.length,
          'uniqueCount': uniqueNotifications.length,
        },
      );
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro ao escanear backups locais: $e');
      return null;
    }
  }

  /// Escaneia cache em memória
  Future<RecoveryData?> _scanMemoryCache(String userId) async {
    try {
      final cachedNotifications =
          _unifiedInterface.getCachedNotifications(userId);

      if (cachedNotifications.isEmpty) return null;

      return RecoveryData(
        source: 'memory_cache',
        notifications: cachedNotifications,
        timestamp: DateTime.now(),
        metadata: {
          'cacheSize': cachedNotifications.length,
          'source': 'unified_interface_cache',
        },
      );
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro ao escanear cache em memória: $e');
      return null;
    }
  }

  /// Escaneia dados temporários
  Future<RecoveryData?> _scanTemporaryData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempKeys = prefs
          .getKeys()
          .where((key) => key.contains('temp') && key.contains(userId));

      if (tempKeys.isEmpty) return null;

      final tempNotifications = <RealNotificationModel>[];

      for (final key in tempKeys) {
        try {
          final tempString = prefs.getString(key);
          if (tempString != null) {
            final tempData = jsonDecode(tempString);

            if (tempData is List) {
              final notifications = tempData
                  .map((json) => RealNotificationModel.fromJson(json))
                  .toList();
              tempNotifications.addAll(notifications);
            }
          }
        } catch (e) {
          EnhancedLogger.log(
              '⚠️ [DATA_RECOVERY] Erro ao processar dados temporários: $key');
        }
      }

      if (tempNotifications.isEmpty) return null;

      return RecoveryData(
        source: 'temporary_data',
        notifications: _removeDuplicates(tempNotifications),
        timestamp: DateTime.now(),
        metadata: {
          'tempFilesCount': tempKeys.length,
          'totalFound': tempNotifications.length,
        },
      );
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro ao escanear dados temporários: $e');
      return null;
    }
  }

  /// Escaneia dados do servidor
  Future<RecoveryData?> _scanServerData(String userId) async {
    try {
      // Verifica se há conexão
      if (!_unifiedInterface.isOnline()) {
        return null;
      }

      final serverNotifications = await _unifiedInterface.forceSync(userId);

      if (serverNotifications.isEmpty) return null;

      return RecoveryData(
        source: 'server_data',
        notifications: serverNotifications,
        timestamp: DateTime.now(),
        metadata: {
          'serverCount': serverNotifications.length,
          'source': 'unified_interface_server',
        },
      );
    } catch (e) {
      EnhancedLogger.log(
          '❌ [DATA_RECOVERY] Erro ao escanear dados do servidor: $e');
      return null;
    }
  }

  /// Seleciona melhor fonte de recuperação
  RecoveryData _selectBestRecoverySource(
      List<RecoveryData> availableData, RecoveryType? preferredType) {
    if (availableData.length == 1) {
      return availableData.first;
    }

    // Prioriza por tipo preferido
    if (preferredType != null) {
      final preferred = availableData
          .where((data) =>
              _getRecoveryTypeFromSource(data.source) == preferredType)
          .toList();
      if (preferred.isNotEmpty) {
        return preferred.first;
      }
    }

    // Prioriza por quantidade de dados
    availableData.sort(
        (a, b) => b.notifications.length.compareTo(a.notifications.length));

    // Prioriza por timestamp mais recente
    final maxCount = availableData.first.notifications.length;
    final candidates = availableData
        .where((data) => data.notifications.length == maxCount)
        .toList();

    candidates.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return candidates.first;
  }

  /// Executa recuperação
  Future<RecoveryResult> _performRecovery(
      String userId, RecoveryData source) async {
    try {
      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.recovering,
        progress: 0.2,
        message: 'Validando dados de ${source.source}...',
      ));

      // Valida integridade dos dados
      final isValid = await validateDataIntegrity(userId, source.notifications);
      if (!isValid) {
        throw Exception('Dados de recuperação corrompidos');
      }

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.recovering,
        progress: 0.5,
        message: 'Salvando dados recuperados...',
      ));

      // Salva dados recuperados
      final success =
          await _localStorage.saveNotifications(userId, source.notifications);
      if (!success) {
        throw Exception('Falha ao salvar dados recuperados');
      }

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.recovering,
        progress: 0.8,
        message: 'Atualizando cache...',
      ));

      // Atualiza cache unificado
      await _unifiedInterface.updateCache(userId, source.notifications);

      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.completed,
        progress: 1.0,
        message: 'Recuperação concluída com sucesso!',
      ));

      return RecoveryResult(
        success: true,
        message: 'Dados recuperados com sucesso de ${source.source}',
        recoveredCount: source.notifications.length,
        totalFound: source.notifications.length,
        recoveryType: _getRecoveryTypeFromSource(source.source),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _emitProgress(RecoveryProgress(
        userId: userId,
        status: RecoveryStatus.failed,
        progress: 0.0,
        message: 'Erro na recuperação: $e',
      ));

      throw e;
    }
  }

  /// Remove notificações duplicadas
  List<RealNotificationModel> _removeDuplicates(
      List<RealNotificationModel> notifications) {
    final seen = <String>{};
    return notifications
        .where((notification) => seen.add(notification.id))
        .toList();
  }

  /// Obtém tipo de recuperação da fonte
  RecoveryType _getRecoveryTypeFromSource(String source) {
    switch (source) {
      case 'local_backup':
      case 'emergency_backup':
        return RecoveryType.backup;
      case 'memory_cache':
      case 'temporary_data':
        return RecoveryType.cache;
      case 'server_data':
        return RecoveryType.server;
      default:
        return RecoveryType.hybrid;
    }
  }

  /// Obtém contagem de fontes disponíveis
  int _getAvailableSourcesCount(String userId) {
    // Implementação simplificada
    return 0;
  }

  /// Salva histórico de recuperação
  Future<void> _saveRecoveryHistory(
      String userId, RecoveryResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'recovery_history_$userId';
      await prefs.setString(key, jsonEncode(result.toJson()));
    } catch (e) {
      EnhancedLogger.log('⚠️ [DATA_RECOVERY] Erro ao salvar histórico: $e');
    }
  }

  /// Emite progresso de recuperação
  void _emitProgress(RecoveryProgress progress) {
    _progressController.add(progress);
  }

  /// Dispose dos recursos
  void dispose() {
    _progressController.close();
    EnhancedLogger.log('🧹 [DATA_RECOVERY] Recursos liberados');
  }
}

/// Progresso de recuperação
class RecoveryProgress {
  final String userId;
  final RecoveryStatus status;
  final double progress; // 0.0 a 1.0
  final String message;

  RecoveryProgress({
    required this.userId,
    required this.status,
    required this.progress,
    required this.message,
  });
}
