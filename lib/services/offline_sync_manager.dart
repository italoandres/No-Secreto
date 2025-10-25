import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/notification_local_storage.dart';
import '../services/unified_notification_interface.dart';
import '../services/notification_sync_logger.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';

/// Status de conectividade
enum ConnectivityStatus { online, offline, limited }

/// Operação pendente de sincronização
class PendingOperation {
  final String id;
  final String userId;
  final String type; // 'add', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  PendingOperation({
    required this.id,
    required this.userId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'],
        userId: json['userId'],
        type: json['type'],
        data: Map<String, dynamic>.from(json['data']),
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retryCount'] ?? 0,
      );

  PendingOperation copyWith({int? retryCount}) => PendingOperation(
        id: id,
        userId: userId,
        type: type,
        data: data,
        timestamp: timestamp,
        retryCount: retryCount ?? this.retryCount,
      );
}

/// Gerenciador de sincronização offline/online
class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;
  OfflineSyncManager._internal();

  final NotificationLocalStorage _localStorage = NotificationLocalStorage();
  final UnifiedNotificationInterface _unifiedInterface =
      UnifiedNotificationInterface();
  final NotificationSyncLogger _logger = NotificationSyncLogger();
  final Connectivity _connectivity = Connectivity();

  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _retryTimer;

  final Map<String, List<PendingOperation>> _pendingOperations = {};
  final StreamController<ConnectivityStatus> _statusController =
      StreamController.broadcast();
  final StreamController<SyncProgress> _progressController =
      StreamController.broadcast();

  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Stream de status de conectividade
  Stream<ConnectivityStatus> get connectivityStream => _statusController.stream;

  /// Stream de progresso de sincronização
  Stream<SyncProgress> get syncProgressStream => _progressController.stream;

  /// Status atual de conectividade
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Verifica se está online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Verifica se está sincronizando
  bool get isSyncing => _isSyncing;

  /// Inicializa o gerenciador de sincronização
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      EnhancedLogger.log(
          '🔄 [OFFLINE_SYNC] Inicializando gerenciador de sincronização');

      // Inicializa armazenamento local
      await _localStorage.initialize();

      // Verifica conectividade inicial
      await _checkInitialConnectivity();

      // Configura monitoramento de conectividade
      _setupConnectivityMonitoring();

      // Carrega operações pendentes
      await _loadPendingOperations();

      // Inicia sincronização automática
      _startAutomaticSync();

      _isInitialized = true;
      EnhancedLogger.log(
          '✅ [OFFLINE_SYNC] Gerenciador inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.log('❌ [OFFLINE_SYNC] Erro na inicialização: $e');
      throw Exception(
          'Falha na inicialização do gerenciador de sincronização: $e');
    }
  }

  /// Sincroniza notificações para um usuário
  Future<SyncResult> syncNotifications(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    EnhancedLogger.log(
        '🔄 [OFFLINE_SYNC] Iniciando sincronização para: $userId');

    try {
      _isSyncing = true;
      _emitProgress(SyncProgress(
        userId: userId,
        status: SyncProgressStatus.syncing,
        progress: 0.0,
        message: 'Iniciando sincronização...',
      ));

      final result = await _performSync(userId);

      _emitProgress(SyncProgress(
        userId: userId,
        status: result.success
            ? SyncProgressStatus.completed
            : SyncProgressStatus.failed,
        progress: 1.0,
        message: result.message,
      ));

      return result;
    } catch (e) {
      EnhancedLogger.log('❌ [OFFLINE_SYNC] Erro na sincronização: $e');

      _emitProgress(SyncProgress(
        userId: userId,
        status: SyncProgressStatus.failed,
        progress: 0.0,
        message: 'Erro na sincronização: $e',
      ));

      return SyncResult(
        success: false,
        message: 'Erro na sincronização: $e',
        syncedCount: 0,
        failedCount: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Adiciona operação pendente
  Future<void> addPendingOperation(PendingOperation operation) async {
    try {
      if (!_pendingOperations.containsKey(operation.userId)) {
        _pendingOperations[operation.userId] = [];
      }

      _pendingOperations[operation.userId]!.add(operation);
      await _savePendingOperations(operation.userId);

      EnhancedLogger.log(
          '📝 [OFFLINE_SYNC] Operação pendente adicionada: ${operation.type}');

      // Tenta sincronizar se estiver online
      if (isOnline) {
        _scheduleSyncRetry(operation.userId);
      }
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro ao adicionar operação pendente: $e');
    }
  }

  /// Obtém operações pendentes para um usuário
  List<PendingOperation> getPendingOperations(String userId) {
    return _pendingOperations[userId] ?? [];
  }

  /// Limpa operações pendentes para um usuário
  Future<void> clearPendingOperations(String userId) async {
    try {
      _pendingOperations[userId]?.clear();
      await _savePendingOperations(userId);

      EnhancedLogger.log(
          '🧹 [OFFLINE_SYNC] Operações pendentes limpas para: $userId');
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro ao limpar operações pendentes: $e');
    }
  }

  /// Força sincronização imediata
  Future<SyncResult> forceSync(String userId) async {
    EnhancedLogger.log('⚡ [OFFLINE_SYNC] Forçando sincronização para: $userId');

    if (!isOnline) {
      return SyncResult(
        success: false,
        message: 'Sem conexão com a internet',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    return await syncNotifications(userId);
  }

  /// Obtém estatísticas de sincronização
  Future<Map<String, dynamic>> getSyncStats(String userId) async {
    try {
      final pendingOps = getPendingOperations(userId);
      final storageStats = await _localStorage.getStorageStats(userId);
      final syncStatus = _localStorage.getSyncStatus(userId);

      return {
        'connectivityStatus': _currentStatus.toString(),
        'isOnline': isOnline,
        'isSyncing': _isSyncing,
        'pendingOperations': pendingOps.length,
        'lastSync': syncStatus.lastSync.toIso8601String(),
        'syncStatus': syncStatus.status.toString(),
        'storageStats': storageStats,
        'pendingOperationsByType': _groupOperationsByType(pendingOps),
      };
    } catch (e) {
      EnhancedLogger.log('❌ [OFFLINE_SYNC] Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Executa sincronização
  Future<SyncResult> _performSync(String userId) async {
    int syncedCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    try {
      // 1. Sincroniza dados locais com servidor
      _emitProgress(SyncProgress(
        userId: userId,
        status: SyncProgressStatus.syncing,
        progress: 0.2,
        message: 'Sincronizando dados locais...',
      ));

      final localNotifications = await _localStorage.loadNotifications(userId);
      final serverNotifications = await _unifiedInterface.forceSync(userId);

      // 2. Resolve conflitos
      _emitProgress(SyncProgress(
        userId: userId,
        status: SyncProgressStatus.syncing,
        progress: 0.4,
        message: 'Resolvendo conflitos...',
      ));

      final mergedNotifications =
          await _mergeNotifications(localNotifications, serverNotifications);

      // 3. Processa operações pendentes
      _emitProgress(SyncProgress(
        userId: userId,
        status: SyncProgressStatus.syncing,
        progress: 0.6,
        message: 'Processando operações pendentes...',
      ));

      final pendingOps = getPendingOperations(userId);
      for (final operation in pendingOps) {
        try {
          await _processOperation(operation);
          syncedCount++;
        } catch (e) {
          failedCount++;
          errors.add('Operação ${operation.type}: $e');
        }
      }

      // 4. Salva dados sincronizados
      _emitProgress(SyncProgress(
        userId: userId,
        status: SyncProgressStatus.syncing,
        progress: 0.8,
        message: 'Salvando dados sincronizados...',
      ));

      await _localStorage.saveNotifications(userId, mergedNotifications);

      // 5. Atualiza status de sincronização
      await _localStorage.updateSyncStatus(
          userId,
          SyncData(
            lastSync: DateTime.now(),
            status: failedCount == 0 ? SyncStatus.synced : SyncStatus.error,
            pendingChanges: failedCount,
            errorMessage: errors.isNotEmpty ? errors.join('; ') : null,
          ));

      // 6. Remove operações processadas com sucesso
      if (syncedCount > 0) {
        await _removeSyncedOperations(userId, syncedCount);
      }

      final success = failedCount == 0;
      final message = success
          ? 'Sincronização concluída com sucesso'
          : 'Sincronização concluída com $failedCount falhas';

      _logger.logSyncSuccess(userId, syncedCount);

      return SyncResult(
        success: success,
        message: message,
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );
    } catch (e) {
      _logger.logError(userId, 'Sync failed', data: {'error': e.toString()});

      return SyncResult(
        success: false,
        message: 'Erro na sincronização: $e',
        syncedCount: syncedCount,
        failedCount: failedCount + 1,
        errors: [...errors, e.toString()],
      );
    }
  }

  /// Verifica conectividade inicial
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _currentStatus = _mapConnectivityResult(result);

      // Verifica conectividade real com teste de rede
      if (_currentStatus == ConnectivityStatus.online) {
        final hasRealConnection = await _testRealConnectivity();
        if (!hasRealConnection) {
          _currentStatus = ConnectivityStatus.limited;
        }
      }

      _statusController.add(_currentStatus);
      EnhancedLogger.log(
          '📶 [OFFLINE_SYNC] Status inicial de conectividade: $_currentStatus');
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro ao verificar conectividade: $e');
      _currentStatus = ConnectivityStatus.offline;
    }
  }

  /// Configura monitoramento de conectividade
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        final newStatus = _mapConnectivityResult(result);

        // Verifica conectividade real se necessário
        if (newStatus == ConnectivityStatus.online) {
          final hasRealConnection = await _testRealConnectivity();
          _currentStatus = hasRealConnection
              ? ConnectivityStatus.online
              : ConnectivityStatus.limited;
        } else {
          _currentStatus = newStatus;
        }

        _statusController.add(_currentStatus);
        EnhancedLogger.log(
            '📶 [OFFLINE_SYNC] Status de conectividade alterado: $_currentStatus');

        // Inicia sincronização se ficou online
        if (_currentStatus == ConnectivityStatus.online) {
          _scheduleImmediateSync();
        }
      },
      onError: (error) {
        EnhancedLogger.log(
            '❌ [OFFLINE_SYNC] Erro no monitoramento de conectividade: $error');
      },
    );
  }

  /// Mapeia resultado de conectividade
  ConnectivityStatus _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return ConnectivityStatus.online;
      case ConnectivityResult.none:
        return ConnectivityStatus.offline;
      default:
        return ConnectivityStatus.limited;
    }
  }

  /// Testa conectividade real
  Future<bool> _testRealConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Inicia sincronização automática
  void _startAutomaticSync() {
    // Sincronização a cada 5 minutos quando online
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (isOnline && !_isSyncing) {
        await _syncAllUsers();
      }
    });
  }

  /// Sincroniza todos os usuários com operações pendentes
  Future<void> _syncAllUsers() async {
    try {
      final usersWithPendingOps = _pendingOperations.keys.toList();

      for (final userId in usersWithPendingOps) {
        if (_pendingOperations[userId]?.isNotEmpty == true) {
          await syncNotifications(userId);
        }
      }
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro na sincronização automática: $e');
    }
  }

  /// Agenda sincronização imediata
  void _scheduleImmediateSync() {
    Timer(Duration(seconds: 2), () async {
      if (isOnline && !_isSyncing) {
        await _syncAllUsers();
      }
    });
  }

  /// Agenda retry de sincronização
  void _scheduleSyncRetry(String userId) {
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: 30), () async {
      if (isOnline && !_isSyncing) {
        await syncNotifications(userId);
      }
    });
  }

  /// Mescla notificações locais e do servidor
  Future<List<RealNotificationModel>> _mergeNotifications(
    List<RealNotificationModel> local,
    List<RealNotificationModel> server,
  ) async {
    final merged = <String, RealNotificationModel>{};

    // Adiciona notificações do servidor
    for (final notification in server) {
      merged[notification.id] = notification;
    }

    // Mescla com notificações locais (local tem prioridade se mais recente)
    for (final notification in local) {
      final existing = merged[notification.id];
      if (existing == null ||
          notification.timestamp.isAfter(existing.timestamp)) {
        merged[notification.id] = notification;
      }
    }

    return merged.values.toList();
  }

  /// Processa uma operação pendente
  Future<void> _processOperation(PendingOperation operation) async {
    switch (operation.type) {
      case 'add':
        final notification = RealNotificationModel.fromJson(operation.data);
        await _unifiedInterface.addNotification(operation.userId, notification);
        break;

      case 'update':
        final notification = RealNotificationModel.fromJson(operation.data);
        await _unifiedInterface.updateNotification(
            operation.userId, notification);
        break;

      case 'delete':
        final notificationId = operation.data['id'] as String;
        await _unifiedInterface.removeNotification(
            operation.userId, notificationId);
        break;

      default:
        throw Exception('Tipo de operação desconhecido: ${operation.type}');
    }
  }

  /// Remove operações sincronizadas
  Future<void> _removeSyncedOperations(String userId, int count) async {
    try {
      final operations = _pendingOperations[userId];
      if (operations != null && operations.length >= count) {
        operations.removeRange(0, count);
        await _savePendingOperations(userId);
      }
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro ao remover operações sincronizadas: $e');
    }
  }

  /// Carrega operações pendentes
  Future<void> _loadPendingOperations() async {
    try {
      // Implementação simplificada - em produção, carregaria do armazenamento persistente
      EnhancedLogger.log('📂 [OFFLINE_SYNC] Operações pendentes carregadas');
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro ao carregar operações pendentes: $e');
    }
  }

  /// Salva operações pendentes
  Future<void> _savePendingOperations(String userId) async {
    try {
      // Implementação simplificada - em produção, salvaria no armazenamento persistente
      EnhancedLogger.log(
          '💾 [OFFLINE_SYNC] Operações pendentes salvas para: $userId');
    } catch (e) {
      EnhancedLogger.log(
          '❌ [OFFLINE_SYNC] Erro ao salvar operações pendentes: $e');
    }
  }

  /// Agrupa operações por tipo
  Map<String, int> _groupOperationsByType(List<PendingOperation> operations) {
    final grouped = <String, int>{};
    for (final op in operations) {
      grouped[op.type] = (grouped[op.type] ?? 0) + 1;
    }
    return grouped;
  }

  /// Emite progresso de sincronização
  void _emitProgress(SyncProgress progress) {
    _progressController.add(progress);
  }

  /// Dispose dos recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _statusController.close();
    _progressController.close();
    _localStorage.dispose();

    EnhancedLogger.log('🧹 [OFFLINE_SYNC] Recursos liberados');
  }
}

/// Resultado de sincronização
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.errors = const [],
  });
}

/// Progresso de sincronização
class SyncProgress {
  final String userId;
  final SyncProgressStatus status;
  final double progress; // 0.0 a 1.0
  final String message;

  SyncProgress({
    required this.userId,
    required this.status,
    required this.progress,
    required this.message,
  });
}

/// Status do progresso de sincronização
enum SyncProgressStatus { idle, syncing, completed, failed }
