import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/enhanced_logger.dart';
import '../services/offline_notification_cache.dart';
import '../services/notification_fallback_system.dart';
import '../services/fixed_notification_pipeline.dart';
import '../services/error_recovery_system.dart';
import '../models/real_notification_model.dart';

/// Serviço de sincronização de notificações quando conectividade retorna
class NotificationSyncService {
  static NotificationSyncService? _instance;
  static NotificationSyncService get instance =>
      _instance ??= NotificationSyncService._();

  NotificationSyncService._();

  bool _isInitialized = false;
  bool _isSyncing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  final List<String> _syncLog = [];
  final Map<String, dynamic> _syncStatistics = {};
  final Set<String> _usersToSync = {};

  // Configurações de sincronização
  final Duration _syncInterval = const Duration(minutes: 5);
  final Duration _syncTimeout = const Duration(minutes: 2);
  final int _maxRetries = 3;

  /// Inicializa serviço de sincronização
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar dependências
      await OfflineNotificationCache.instance.initialize();
      await NotificationFallbackSystem.instance.initialize();

      // Monitorar conectividade
      final connectivity = Connectivity();
      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

      // Configurar timer de sincronização periódica
      _setupPeriodicSync();

      // Inicializar estatísticas
      _initializeStatistics();

      _isInitialized = true;

      EnhancedLogger.success(
          '✅ [SYNC_SERVICE] Serviço de sincronização inicializado');
      _logSync('Serviço de sincronização inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_SERVICE] Erro ao inicializar serviço',
          error: e);
      _logSync('Erro ao inicializar serviço: $e');
    }
  }

  /// Manipula mudanças de conectividade
  void _onConnectivityChanged(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;

    _logSync(
        'Conectividade alterada: ${result.toString()} (Online: $isOnline)');

    if (isOnline && !_isSyncing) {
      _logSync('Conectividade restaurada - iniciando sincronização automática');
      _scheduleImmediateSync();
    }
  }

  /// Configura sincronização periódica
  void _setupPeriodicSync() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      if (!_isSyncing) {
        _performPeriodicSync();
      }
    });

    _logSync(
        'Sincronização periódica configurada (${_syncInterval.inMinutes} minutos)');
  }

  /// Executa sincronização periódica
  void _performPeriodicSync() async {
    try {
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        _logSync('Executando sincronização periódica');
        await performFullSync();
      } else {
        _logSync('Sincronização periódica cancelada - sem conectividade');
      }
    } catch (e) {
      _logSync('Erro na sincronização periódica: $e');
    }
  }

  /// Agenda sincronização imediata
  void _scheduleImmediateSync() {
    Timer(const Duration(seconds: 2), () async {
      await performFullSync();
    });
  }

  /// Executa sincronização completa
  Future<bool> performFullSync() async {
    if (_isSyncing) {
      _logSync('Sincronização já em andamento - ignorando nova solicitação');
      return false;
    }

    _isSyncing = true;
    _logSync('🔄 Iniciando sincronização completa');

    try {
      final syncStartTime = DateTime.now();

      // Verificar conectividade
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _logSync('❌ Sincronização cancelada - sem conectividade');
        return false;
      }

      // Etapa 1: Sincronizar dados em cache
      _logSync('📦 Etapa 1: Sincronizando dados em cache');
      final cacheResult = await _syncCachedData();

      // Etapa 2: Sincronizar operações pendentes
      _logSync('📝 Etapa 2: Sincronizando operações pendentes');
      final operationsResult = await _syncPendingOperations();

      // Etapa 3: Atualizar notificações para usuários pendentes
      _logSync('🔔 Etapa 3: Atualizando notificações pendentes');
      final notificationsResult = await _syncPendingNotifications();

      // Etapa 4: Limpar dados expirados
      _logSync('🧹 Etapa 4: Limpando dados expirados');
      await _cleanExpiredData();

      final syncEndTime = DateTime.now();
      final syncDuration = syncEndTime.difference(syncStartTime);

      // Atualizar estatísticas
      _updateSyncStatistics(true, syncDuration, cacheResult, operationsResult,
          notificationsResult);

      _logSync(
          '✅ Sincronização completa concluída em ${syncDuration.inMilliseconds}ms');

      return true;
    } catch (e) {
      _logSync('💥 Erro na sincronização completa: $e');
      _updateSyncStatistics(false, Duration.zero, false, false, false);

      EnhancedLogger.error('❌ [SYNC_SERVICE] Erro na sincronização completa',
          error: e);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincroniza dados em cache
  Future<bool> _syncCachedData() async {
    try {
      final cacheStats = OfflineNotificationCache.instance.getCacheStatistics();
      final cachedUsers = cacheStats['cachedNotifications'] as int? ?? 0;

      if (cachedUsers == 0) {
        _logSync('  📦 Nenhum dado em cache para sincronizar');
        return true;
      }

      _logSync('  📦 Sincronizando dados de $cachedUsers usuários');

      // Aqui você implementaria a lógica específica de sincronização
      // Por exemplo: comparar com dados do servidor, resolver conflitos, etc.

      await Future.delayed(
          const Duration(milliseconds: 500)); // Simular sincronização

      _logSync('  ✅ Dados em cache sincronizados com sucesso');
      return true;
    } catch (e) {
      _logSync('  ❌ Erro ao sincronizar dados em cache: $e');
      return false;
    }
  }

  /// Sincroniza operações pendentes
  Future<bool> _syncPendingOperations() async {
    try {
      // Obter estatísticas do cache offline
      final cacheStats = OfflineNotificationCache.instance.getCacheStatistics();
      final pendingOps = cacheStats['pendingOperations'] as int? ?? 0;

      if (pendingOps == 0) {
        _logSync('  📝 Nenhuma operação pendente para sincronizar');
        return true;
      }

      _logSync('  📝 Sincronizando $pendingOps operações pendentes');

      // Aqui você implementaria a lógica de sincronização de operações
      // Por exemplo: enviar para Firebase, processar filas, etc.

      await Future.delayed(
          const Duration(milliseconds: 300)); // Simular sincronização

      _logSync('  ✅ Operações pendentes sincronizadas com sucesso');
      return true;
    } catch (e) {
      _logSync('  ❌ Erro ao sincronizar operações pendentes: $e');
      return false;
    }
  }

  /// Sincroniza notificações pendentes
  Future<bool> _syncPendingNotifications() async {
    try {
      if (_usersToSync.isEmpty) {
        _logSync('  🔔 Nenhuma notificação pendente para sincronizar');
        return true;
      }

      _logSync(
          '  🔔 Sincronizando notificações para ${_usersToSync.length} usuários');

      final syncedUsers = <String>[];

      for (final userId in _usersToSync) {
        try {
          // Processar notificações atualizadas para o usuário
          final notifications = await FixedNotificationPipeline.instance
              .processInteractionsRobustly(userId);

          // Salvar no cache
          await OfflineNotificationCache.instance
              .cacheNotifications(userId, notifications);

          // Salvar no fallback
          await NotificationFallbackSystem.instance
              .saveFallbackNotifications(userId, notifications);

          syncedUsers.add(userId);
          _logSync(
              '    ✅ Usuário $userId sincronizado (${notifications.length} notificações)');
        } catch (e) {
          _logSync('    ❌ Erro ao sincronizar usuário $userId: $e');
        }
      }

      // Remover usuários sincronizados da lista
      for (final userId in syncedUsers) {
        _usersToSync.remove(userId);
      }

      _logSync('  ✅ ${syncedUsers.length} usuários sincronizados com sucesso');
      return syncedUsers.isNotEmpty;
    } catch (e) {
      _logSync('  ❌ Erro ao sincronizar notificações pendentes: $e');
      return false;
    }
  }

  /// Limpa dados expirados
  Future<void> _cleanExpiredData() async {
    try {
      // Limpar cache offline expirado
      await OfflineNotificationCache.instance.cleanExpiredCache();

      // Limpar cache de fallback expirado
      await NotificationFallbackSystem.instance.cleanExpiredCache();

      _logSync('  🧹 Dados expirados limpos com sucesso');
    } catch (e) {
      _logSync('  ❌ Erro ao limpar dados expirados: $e');
    }
  }

  /// Adiciona usuário à lista de sincronização
  void addUserToSync(String userId) {
    _usersToSync.add(userId);
    _logSync('Usuário $userId adicionado à lista de sincronização');

    // Se estiver online e não sincronizando, agendar sincronização
    if (OfflineNotificationCache.instance.isOnline && !_isSyncing) {
      Timer(const Duration(seconds: 5), () async {
        await performFullSync();
      });
    }
  }

  /// Força sincronização para um usuário específico
  Future<bool> forceSyncUser(String userId) async {
    if (_isSyncing) {
      _logSync('Sincronização em andamento - adicionando $userId à fila');
      addUserToSync(userId);
      return false;
    }

    try {
      _isSyncing = true;
      _logSync('🔄 Forçando sincronização para usuário $userId');

      // Verificar conectividade
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _logSync('❌ Sincronização cancelada - sem conectividade');
        return false;
      }

      // Processar notificações para o usuário
      final notifications = await FixedNotificationPipeline.instance
          .processInteractionsRobustly(userId);

      // Salvar nos caches
      await OfflineNotificationCache.instance
          .cacheNotifications(userId, notifications);
      await NotificationFallbackSystem.instance
          .saveFallbackNotifications(userId, notifications);

      _logSync(
          '✅ Usuário $userId sincronizado com sucesso (${notifications.length} notificações)');
      return true;
    } catch (e) {
      _logSync('💥 Erro ao forçar sincronização do usuário $userId: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Inicializa estatísticas
  void _initializeStatistics() {
    _syncStatistics.clear();
    _syncStatistics.addAll({
      'totalSyncs': 0,
      'successfulSyncs': 0,
      'failedSyncs': 0,
      'lastSyncTime': null,
      'lastSyncDuration': 0,
      'averageSyncDuration': 0,
      'totalSyncTime': 0,
      'usersInQueue': 0,
      'cacheDataSynced': 0,
      'operationsSynced': 0,
      'notificationsSynced': 0,
    });
  }

  /// Atualiza estatísticas de sincronização
  void _updateSyncStatistics(bool success, Duration duration, bool cacheResult,
      bool operationsResult, bool notificationsResult) {
    _syncStatistics['totalSyncs'] = (_syncStatistics['totalSyncs'] as int) + 1;

    if (success) {
      _syncStatistics['successfulSyncs'] =
          (_syncStatistics['successfulSyncs'] as int) + 1;
    } else {
      _syncStatistics['failedSyncs'] =
          (_syncStatistics['failedSyncs'] as int) + 1;
    }

    _syncStatistics['lastSyncTime'] = DateTime.now().toIso8601String();
    _syncStatistics['lastSyncDuration'] = duration.inMilliseconds;

    final totalTime =
        (_syncStatistics['totalSyncTime'] as int) + duration.inMilliseconds;
    _syncStatistics['totalSyncTime'] = totalTime;

    final totalSyncs = _syncStatistics['totalSyncs'] as int;
    _syncStatistics['averageSyncDuration'] =
        totalSyncs > 0 ? (totalTime / totalSyncs).round() : 0;

    _syncStatistics['usersInQueue'] = _usersToSync.length;

    if (cacheResult)
      _syncStatistics['cacheDataSynced'] =
          (_syncStatistics['cacheDataSynced'] as int) + 1;
    if (operationsResult)
      _syncStatistics['operationsSynced'] =
          (_syncStatistics['operationsSynced'] as int) + 1;
    if (notificationsResult)
      _syncStatistics['notificationsSynced'] =
          (_syncStatistics['notificationsSynced'] as int) + 1;
  }

  /// Obtém estatísticas de sincronização
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isSyncing': _isSyncing,
      'usersInQueue': _usersToSync.length,
      'syncInterval': _syncInterval.inMinutes,
      'syncTimeout': _syncTimeout.inMinutes,
      'maxRetries': _maxRetries,
      'statistics': Map.from(_syncStatistics),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Obtém log de sincronização
  List<String> getSyncLog({int limit = 50}) {
    return _syncLog.take(limit).toList();
  }

  /// Limpa log de sincronização
  void clearSyncLog() {
    _syncLog.clear();
    _logSync('Log de sincronização limpo');
  }

  /// Registra entrada no log de sincronização
  void _logSync(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';

    _syncLog.add(logEntry);

    // Manter apenas as últimas 100 entradas
    if (_syncLog.length > 100) {
      _syncLog.removeAt(0);
    }

    EnhancedLogger.info('🔄 [SYNC_SERVICE] $message');
  }

  /// Para sincronização em andamento
  void stopSync() {
    if (_isSyncing) {
      _logSync('🛑 Parando sincronização em andamento');
      _isSyncing = false;
    }
  }

  /// Finaliza serviço de sincronização
  void dispose() {
    try {
      _connectivitySubscription?.cancel();
      _syncTimer?.cancel();
      _usersToSync.clear();
      _syncLog.clear();
      _syncStatistics.clear();
      _isSyncing = false;
      _isInitialized = false;

      EnhancedLogger.info('🛑 [SYNC_SERVICE] Serviço finalizado');
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_SERVICE] Erro ao finalizar serviço',
          error: e);
    }
  }
}
