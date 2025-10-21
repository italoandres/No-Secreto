import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_sync_manager.dart';
import '../utils/enhanced_logger.dart';

/// Status de sincronização da interface
enum SyncStatus {
  idle,
  loading,
  syncing,
  success,
  error,
}

/// Estado da interface de notificações
class NotificationUIState {
  final bool isLoading;
  final SyncStatus syncStatus;
  final List<NotificationModel> notifications;
  final int totalCount;
  final DateTime lastUpdate;
  final String? errorMessage;

  NotificationUIState({
    required this.isLoading,
    required this.syncStatus,
    required this.notifications,
    required this.totalCount,
    required this.lastUpdate,
    this.errorMessage,
  });

  NotificationUIState copyWith({
    bool? isLoading,
    SyncStatus? syncStatus,
    List<NotificationModel>? notifications,
    int? totalCount,
    DateTime? lastUpdate,
    String? errorMessage,
  }) {
    return NotificationUIState(
      isLoading: isLoading ?? this.isLoading,
      syncStatus: syncStatus ?? this.syncStatus,
      notifications: notifications ?? this.notifications,
      totalCount: totalCount ?? this.totalCount,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Gerenciador de estado da interface unificada
class UIStateManager {
  static final UIStateManager _instance = UIStateManager._internal();
  factory UIStateManager() => _instance;
  UIStateManager._internal();

  final Map<String, StreamController<NotificationUIState>> _stateControllers = {};
  final Map<String, NotificationUIState> _currentStates = {};
  final NotificationSyncManager _syncManager = NotificationSyncManager();

  /// Obtém stream de estado para um usuário
  Stream<NotificationUIState> getStateStream(String userId) {
    EnhancedLogger.log('🎨 [UI_STATE] Obtendo stream de estado para: $userId');
    
    if (!_stateControllers.containsKey(userId)) {
      _setupStateStream(userId);
    }
    
    return _stateControllers[userId]!.stream;
  }

  /// Configura stream de estado para um usuário
  void _setupStateStream(String userId) {
    EnhancedLogger.log('⚙️ [UI_STATE] Configurando stream de estado para: $userId');
    
    _stateControllers[userId] = StreamController<NotificationUIState>.broadcast();
    
    // Estado inicial
    final initialState = NotificationUIState(
      isLoading: true,
      syncStatus: SyncStatus.loading,
      notifications: [],
      totalCount: 0,
      lastUpdate: DateTime.now(),
    );
    
    _currentStates[userId] = initialState;
    _stateControllers[userId]!.add(initialState);

    // Escuta mudanças do sync manager
    _syncManager.getNotificationsStream(userId).listen(
      (notifications) => _handleDataUpdate(userId, notifications),
      onError: (error) => _handleError(userId, error),
    );
  }

  /// Manipula atualização de dados
  void _handleDataUpdate(String userId, List<NotificationModel> notifications) {
    EnhancedLogger.log('📨 [UI_STATE] Atualização de dados: ${notifications.length} notificações');
    
    final currentState = _currentStates[userId];
    if (currentState == null) return;

    final newState = currentState.copyWith(
      isLoading: false,
      syncStatus: SyncStatus.success,
      notifications: notifications,
      totalCount: notifications.length,
      lastUpdate: DateTime.now(),
      errorMessage: null,
    );

    _currentStates[userId] = newState;
    _stateControllers[userId]?.add(newState);

    // Feedback visual
    _showUpdateFeedback(notifications.length);
  }

  /// Manipula erros
  void _handleError(String userId, dynamic error) {
    EnhancedLogger.log('❌ [UI_STATE] Erro nos dados: $error');
    
    final currentState = _currentStates[userId];
    if (currentState == null) return;

    final newState = currentState.copyWith(
      isLoading: false,
      syncStatus: SyncStatus.error,
      errorMessage: error.toString(),
      lastUpdate: DateTime.now(),
    );

    _currentStates[userId] = newState;
    _stateControllers[userId]?.add(newState);

    _showErrorFeedback(error.toString());
  }

  /// Atualiza estado com novas notificações
  void _updateState(
    String userId,
    List<NotificationModel> current,
    List<NotificationModel> updated,
  ) {
    final currentState = _currentStates[userId];
    if (currentState == null) return;

    final hasChanges = current.length != updated.length ||
        !_areListsEqual(current, updated);

    if (!hasChanges) return;

    final newState = currentState.copyWith(
      notifications: updated,
      totalCount: updated.length,
      lastUpdate: DateTime.now(),
      syncStatus: SyncStatus.success,
    );

    _currentStates[userId] = newState;
    _stateControllers[userId]?.add(newState);

    EnhancedLogger.log('🎨 [UI_STATE] Estado atualizado: ${newState.syncStatus} | ${newState.totalCount} notificações');
  }

  /// Mostra feedback de atualização
  void _showUpdateFeedback(int count) {
    EnhancedLogger.log('✨ [UI_STATE] Feedback de atualização: $count notificações');
  }

  /// Mostra feedback de erro
  void _showErrorFeedback(String error) {
    EnhancedLogger.log('⚠️ [UI_STATE] Feedback de erro: $error');
  }

  /// Força sincronização
  Future<void> forceSync(String userId) async {
    EnhancedLogger.log('🚀 [UI_STATE] Forçando sincronização para: $userId');
    
    final currentState = _currentStates[userId];
    if (currentState != null) {
      final loadingState = currentState.copyWith(
        isLoading: true,
        syncStatus: SyncStatus.syncing,
      );
      
      _currentStates[userId] = loadingState;
      _stateControllers[userId]?.add(loadingState);
    }

    try {
      await _syncManager.forceSync(userId);
      EnhancedLogger.log('✅ [UI_STATE] Sincronização forçada concluída');
    } catch (e) {
      EnhancedLogger.log('❌ [UI_STATE] Erro na sincronização forçada: $e');
      _handleError(userId, e);
    }
  }

  /// Obtém estado atual
  NotificationUIState? getCurrentState(String userId) {
    return _currentStates[userId];
  }

  /// Mostra status de carregamento
  void showLoadingStatus(String userId, String status) {
    final currentState = _currentStates[userId];
    if (currentState == null) return;

    final loadingState = currentState.copyWith(
      isLoading: true,
      syncStatus: SyncStatus.loading,
    );

    _currentStates[userId] = loadingState;
    _stateControllers[userId]?.add(loadingState);

    EnhancedLogger.log('📊 [UI_STATE] Mostrando status: $status');
  }

  /// Atualiza estado das notificações
  void updateNotificationState(String userId, List<NotificationModel> notifications) {
    EnhancedLogger.log('🔄 [UI_STATE] Atualizando estado das notificações: ${notifications.length}');
    
    final currentState = _currentStates[userId];
    if (currentState == null) return;

    final newState = currentState.copyWith(
      notifications: notifications,
      totalCount: notifications.length,
      lastUpdate: DateTime.now(),
      isLoading: false,
      syncStatus: SyncStatus.success,
    );

    _currentStates[userId] = newState;
    _stateControllers[userId]?.add(newState);
  }

  /// Força atualização da interface
  void forceUIUpdate(String userId) {
    EnhancedLogger.log('🔄 [UI_STATE] Forçando atualização da interface para: $userId');
    
    final currentState = _currentStates[userId];
    if (currentState != null) {
      final updatedState = currentState.copyWith(
        lastUpdate: DateTime.now(),
      );
      
      _currentStates[userId] = updatedState;
      _stateControllers[userId]?.add(updatedState);
    }
  }

  /// Verifica se duas listas são iguais
  bool _areListsEqual(List<NotificationModel> list1, List<NotificationModel> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    
    return true;
  }

  /// Obtém estatísticas do estado
  Map<String, dynamic> getStateStatistics() {
    return {
      'activeStreams': _stateControllers.length,
      'totalStates': _currentStates.length,
      'users': _currentStates.keys.toList(),
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa recursos para um usuário
  void dispose(String userId) {
    EnhancedLogger.log('🧹 [UI_STATE] Limpando recursos para: $userId');
    
    _stateControllers[userId]?.close();
    _stateControllers.remove(userId);
    _currentStates.remove(userId);
  }

  /// Limpa todos os recursos
  void disposeAll() {
    EnhancedLogger.log('🧹 [UI_STATE] Limpando todos os recursos');
    
    for (final controller in _stateControllers.values) {
      controller.close();
    }
    
    _stateControllers.clear();
    _currentStates.clear();
  }
}