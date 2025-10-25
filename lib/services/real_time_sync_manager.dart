import 'dart:async';
import 'package:get/get.dart';
import '../models/real_notification_model.dart';
import '../utils/enhanced_logger.dart';
import '../controllers/matches_controller.dart';

/// Gerenciador de sincronização em tempo real
class RealTimeSyncManager {
  static RealTimeSyncManager? _instance;
  static RealTimeSyncManager get instance =>
      _instance ??= RealTimeSyncManager._();

  RealTimeSyncManager._();

  Timer? _debounceTimer;
  Timer? _syncTimer;
  List<RealNotification> _lastSyncedData = [];
  DateTime? _lastSyncTime;
  bool _isInitialized = false;

  // Configurações de sincronização
  final Duration _debounceDelay = const Duration(milliseconds: 500);
  final Duration _syncInterval = const Duration(seconds: 2);
  final Duration _maxSyncAge = const Duration(minutes: 1);

  /// Inicializa o gerenciador de sincronização
  void initialize() {
    if (_isInitialized) return;

    try {
      _setupPeriodicSync();
      _isInitialized = true;

      EnhancedLogger.success(
          '✅ [SYNC_MANAGER] Sistema inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro ao inicializar sistema',
          error: e);
    }
  }

  /// Configura sincronização periódica
  void _setupPeriodicSync() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performPeriodicSync();
    });

    EnhancedLogger.info('⏰ [SYNC_MANAGER] Sincronização periódica configurada',
        data: {'intervalSeconds': _syncInterval.inSeconds});
  }

  /// Sincroniza notificações com a UI de forma inteligente
  void syncNotificationsWithUI(List<RealNotification> notifications) {
    try {
      EnhancedLogger.info('🔄 [SYNC_MANAGER] Iniciando sincronização com UI',
          tag: 'REAL_TIME_SYNC_MANAGER',
          data: {
            'newNotificationsCount': notifications.length,
            'lastSyncedCount': _lastSyncedData.length,
            'timestamp': DateTime.now().toIso8601String()
          });

      // Verifica se há mudanças nos dados
      if (!hasDataChanged(notifications)) {
        EnhancedLogger.info(
            '⚡ [SYNC_MANAGER] Dados inalterados - sync ignorado',
            data: {'notificationCount': notifications.length});
        return;
      }

      // Cancela timer anterior se existir
      _debounceTimer?.cancel();

      // Agenda atualização com debouncing
      _debounceTimer = Timer(_debounceDelay, () {
        _executeSyncWithUI(notifications);
      });

      EnhancedLogger.info('⏳ [SYNC_MANAGER] Sync agendado com debouncing',
          data: {
            'delayMs': _debounceDelay.inMilliseconds,
            'notificationCount': notifications.length
          });
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro na sincronização',
          error: e, data: {'notificationCount': notifications.length});
    }
  }

  /// Executa sincronização efetiva com a UI
  void _executeSyncWithUI(List<RealNotification> notifications) {
    try {
      EnhancedLogger.info('🚀 [SYNC_MANAGER] Executando sincronização efetiva',
          data: {
            'notificationCount': notifications.length,
            'timestamp': DateTime.now().toIso8601String()
          });

      // Obtém controller do GetX
      final controller = _getMatchesController();
      if (controller == null) {
        EnhancedLogger.error('❌ [SYNC_MANAGER] Controller não encontrado');
        return;
      }

      // Atualiza dados no controller
      _updateControllerData(controller, notifications);

      // Força atualização da UI
      _forceUIUpdate(controller);

      // Registra sincronização bem-sucedida
      _recordSuccessfulSync(notifications);

      EnhancedLogger.success(
          '✅ [SYNC_MANAGER] Sincronização concluída com sucesso',
          data: {
            'syncedNotifications': notifications.length,
            'controllerUpdated': true,
            'uiForceUpdated': true
          });
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro na execução da sincronização',
          error: e, data: {'notificationCount': notifications.length});
    }
  }

  /// Obtém o controller de matches
  MatchesController? _getMatchesController() {
    try {
      if (Get.isRegistered<MatchesController>()) {
        return Get.find<MatchesController>();
      } else {
        EnhancedLogger.warning(
            '⚠️ [SYNC_MANAGER] MatchesController não registrado');
        return null;
      }
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro ao obter controller',
          error: e);
      return null;
    }
  }

  /// Atualiza dados no controller
  void _updateControllerData(
      MatchesController controller, List<RealNotification> notifications) {
    try {
      // Atualiza lista de notificações reais
      controller.realNotifications.value = notifications;

      // Atualiza flag de novas notificações
      controller.hasNewNotifications.value = notifications.isNotEmpty;

      // Atualiza contador de notificações
      controller.notificationCount.value = notifications.length;

      // Limpa erro se houver
      controller.notificationError.value = '';

      // Atualiza timestamp da última atualização
      controller.lastNotificationUpdate.value = DateTime.now();

      EnhancedLogger.info('📊 [SYNC_MANAGER] Dados do controller atualizados',
          data: {
            'realNotifications': notifications.length,
            'hasNewNotifications': notifications.isNotEmpty,
            'notificationCount': notifications.length,
            'errorCleared': true
          });
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro ao atualizar controller',
          error: e);
    }
  }

  /// Força atualização da UI
  void _forceUIUpdate(MatchesController controller) {
    try {
      // Força refresh dos observables
      controller.realNotifications.refresh();
      controller.hasNewNotifications.refresh();
      controller.notificationCount.refresh();

      // Força update do controller
      controller.update();

      // Força refresh geral
      controller.refresh();

      EnhancedLogger.info('🔄 [SYNC_MANAGER] UI forçada a atualizar', data: {
        'observablesRefreshed': true,
        'controllerUpdated': true,
        'generalRefresh': true
      });
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro ao forçar atualização da UI',
          error: e);
    }
  }

  /// Registra sincronização bem-sucedida
  void _recordSuccessfulSync(List<RealNotification> notifications) {
    _lastSyncedData = List.from(notifications);
    _lastSyncTime = DateTime.now();

    EnhancedLogger.info('📝 [SYNC_MANAGER] Sincronização registrada', data: {
      'syncTime': _lastSyncTime!.toIso8601String(),
      'dataCount': _lastSyncedData.length
    });
  }

  /// Agenda atualização da UI com delay específico
  void scheduleUIUpdate(Duration delay) {
    try {
      _debounceTimer?.cancel();

      _debounceTimer = Timer(delay, () {
        final controller = _getMatchesController();
        if (controller != null) {
          _forceUIUpdate(controller);

          EnhancedLogger.info('⏰ [SYNC_MANAGER] Atualização agendada executada',
              data: {
                'delayMs': delay.inMilliseconds,
                'timestamp': DateTime.now().toIso8601String()
              });
        }
      });

      EnhancedLogger.info('📅 [SYNC_MANAGER] Atualização da UI agendada',
          data: {'delayMs': delay.inMilliseconds});
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro ao agendar atualização',
          error: e);
    }
  }

  /// Verifica se os dados mudaram desde a última sincronização
  bool hasDataChanged(List<RealNotification> newData) {
    try {
      // Se não há dados anteriores, considera como mudança
      if (_lastSyncedData.isEmpty && newData.isNotEmpty) {
        return true;
      }

      // Se tamanhos diferentes, houve mudança
      if (_lastSyncedData.length != newData.length) {
        EnhancedLogger.info(
            '📊 [SYNC_MANAGER] Mudança detectada - tamanho diferente',
            data: {
              'previousCount': _lastSyncedData.length,
              'newCount': newData.length
            });
        return true;
      }

      // Verifica mudanças nos IDs das notificações
      final previousIds = _lastSyncedData.map((n) => n.id).toSet();
      final newIds = newData.map((n) => n.id).toSet();

      if (!previousIds.containsAll(newIds) ||
          !newIds.containsAll(previousIds)) {
        EnhancedLogger.info(
            '📊 [SYNC_MANAGER] Mudança detectada - IDs diferentes',
            data: {
              'previousIds': previousIds.length,
              'newIds': newIds.length,
              'difference': newIds.difference(previousIds).toList()
            });
        return true;
      }

      // Verifica mudanças nos timestamps (notificações atualizadas)
      for (int i = 0; i < newData.length; i++) {
        final previous =
            _lastSyncedData.firstWhereOrNull((n) => n.id == newData[i].id);
        if (previous != null && previous.timestamp != newData[i].timestamp) {
          EnhancedLogger.info(
              '📊 [SYNC_MANAGER] Mudança detectada - timestamp atualizado',
              data: {
                'notificationId': newData[i].id,
                'previousTimestamp': previous.timestamp.toIso8601String(),
                'newTimestamp': newData[i].timestamp.toIso8601String()
              });
          return true;
        }
      }

      return false;
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro ao verificar mudanças',
          error: e);
      // Em caso de erro, assume que houve mudança para garantir atualização
      return true;
    }
  }

  /// Atualiza UI de forma incremental
  void updateUIIncrementally(List<RealNotification> changes) {
    try {
      EnhancedLogger.info('🔄 [SYNC_MANAGER] Atualização incremental iniciada',
          data: {'changesCount': changes.length});

      final controller = _getMatchesController();
      if (controller == null) return;

      // Aplica mudanças incrementais
      for (final change in changes) {
        _applyIncrementalChange(controller, change);
      }

      // Força refresh apenas dos observables afetados
      controller.realNotifications.refresh();
      controller.hasNewNotifications.refresh();

      EnhancedLogger.success(
          '✅ [SYNC_MANAGER] Atualização incremental concluída',
          data: {'appliedChanges': changes.length});
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro na atualização incremental',
          error: e);
    }
  }

  /// Aplica uma mudança incremental específica
  void _applyIncrementalChange(
      MatchesController controller, RealNotification change) {
    try {
      final currentNotifications = controller.realNotifications.value;
      final existingIndex =
          currentNotifications.indexWhere((n) => n.id == change.id);

      if (existingIndex >= 0) {
        // Atualiza notificação existente
        currentNotifications[existingIndex] = change;
        EnhancedLogger.info('🔄 [SYNC_MANAGER] Notificação atualizada',
            data: {'notificationId': change.id});
      } else {
        // Adiciona nova notificação
        currentNotifications.insert(0, change); // Adiciona no início
        EnhancedLogger.info('➕ [SYNC_MANAGER] Nova notificação adicionada',
            data: {'notificationId': change.id});
      }

      // Atualiza contador
      controller.notificationCount.value = currentNotifications.length;
      controller.hasNewNotifications.value = currentNotifications.isNotEmpty;
    } catch (e) {
      EnhancedLogger.error(
          '❌ [SYNC_MANAGER] Erro ao aplicar mudança incremental',
          error: e,
          data: {'changeId': change.id});
    }
  }

  /// Executa sincronização periódica
  void _performPeriodicSync() {
    try {
      // Verifica se a última sincronização não é muito antiga
      if (_lastSyncTime != null) {
        final age = DateTime.now().difference(_lastSyncTime!);
        if (age < _maxSyncAge) {
          return; // Sincronização recente, não precisa fazer nada
        }
      }

      EnhancedLogger.info(
          '⏰ [SYNC_MANAGER] Executando sincronização periódica');

      final controller = _getMatchesController();
      if (controller != null) {
        // Força refresh dos dados
        _forceUIUpdate(controller);

        // Atualiza timestamp
        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro na sincronização periódica',
          error: e);
    }
  }

  /// Força sincronização imediata
  void forceSyncNow() {
    try {
      EnhancedLogger.info('⚡ [SYNC_MANAGER] Sincronização forçada iniciada');

      _debounceTimer?.cancel();

      final controller = _getMatchesController();
      if (controller != null) {
        _forceUIUpdate(controller);
        _lastSyncTime = DateTime.now();

        EnhancedLogger.success(
            '✅ [SYNC_MANAGER] Sincronização forçada concluída');
      }
    } catch (e) {
      EnhancedLogger.error('❌ [SYNC_MANAGER] Erro na sincronização forçada',
          error: e);
    }
  }

  /// Obtém estatísticas de sincronização
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isInitialized': _isInitialized,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastSyncedDataCount': _lastSyncedData.length,
      'debounceDelayMs': _debounceDelay.inMilliseconds,
      'syncIntervalSeconds': _syncInterval.inSeconds,
      'maxSyncAgeMinutes': _maxSyncAge.inMinutes,
      'hasActiveDebounceTimer': _debounceTimer?.isActive ?? false,
      'hasActiveSyncTimer': _syncTimer?.isActive ?? false,
      'timeSinceLastSync': _lastSyncTime != null
          ? DateTime.now().difference(_lastSyncTime!).inSeconds
          : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Para o gerenciador de sincronização
  void dispose() {
    _debounceTimer?.cancel();
    _syncTimer?.cancel();
    _debounceTimer = null;
    _syncTimer = null;
    _lastSyncedData.clear();
    _lastSyncTime = null;
    _isInitialized = false;

    EnhancedLogger.info('🛑 [SYNC_MANAGER] Sistema finalizado');
  }
}
