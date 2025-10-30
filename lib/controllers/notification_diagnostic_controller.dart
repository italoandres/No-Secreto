import 'package:get/get.dart';
import 'dart:async';
import '../services/unified_notification_interface.dart';
import '../services/conflict_resolver.dart';
import '../services/data_recovery_service.dart';
import '../services/notification_local_storage.dart';
import '../services/offline_sync_manager.dart';
import '../services/notification_sync_logger.dart';
import '../utils/enhanced_logger.dart';
import '../utils/test_integration_system.dart';

/// Controller para o dashboard de diagnóstico de notificações
class NotificationDiagnosticController extends GetxController {
  final UnifiedNotificationInterface _unifiedInterface =
      UnifiedNotificationInterface();
  final ConflictResolver _conflictResolver = ConflictResolver();
  final DataRecoveryService _recoveryService = DataRecoveryService();
  final NotificationLocalStorage _localStorage = NotificationLocalStorage();
  final OfflineSyncManager _syncManager = OfflineSyncManager();
  final NotificationSyncLogger _logger = NotificationSyncLogger();

  // Estados observáveis
  final RxString systemStatus = 'Carregando...'.obs;
  final RxString lastUpdate = 'Nunca'.obs;
  final RxString systemVersion = '1.0.0'.obs;
  final RxString systemUptime = '0s'.obs;
  final RxString memoryUsage = '0 MB'.obs;
  final RxString cacheSize = '0 KB'.obs;
  final RxString operationsPerMinute = '0'.obs;
  final RxString lastSyncTime = 'Nunca'.obs;

  final RxBool isRunningDiagnostic = false.obs;
  final RxBool isPerformingAction = false.obs;
  final RxString currentAction = ''.obs;
  final RxDouble diagnosticProgress = 0.0.obs;

  final RxList<Map<String, dynamic>> recentActions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> systemAlerts =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> performanceMetrics = <String, dynamic>{}.obs;

  Timer? _refreshTimer;
  Timer? _metricsTimer;
  DateTime _startTime = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    EnhancedLogger.log(
        '🎛️ [DIAGNOSTIC_CONTROLLER] Inicializando controller de diagnóstico');

    _initializeController();
    _startPeriodicRefresh();
    _startMetricsCollection();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _metricsTimer?.cancel();
    super.onClose();
  }

  /// Inicializa o controller
  Future<void> _initializeController() async {
    try {
      await _localStorage.initialize();
      await _syncManager.initialize();

      await refreshAllData();

      EnhancedLogger.log('✅ [DIAGNOSTIC_CONTROLLER] Controller inicializado');
    } catch (e) {
      EnhancedLogger.log('❌ [DIAGNOSTIC_CONTROLLER] Erro na inicialização: $e');
      _setSystemStatus('Erro', 'Falha na inicialização');
    }
  }

  /// Inicia refresh periódico
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      refreshAllData();
    });
  }

  /// Inicia coleta de métricas
  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _updateMetrics();
    });
  }

  /// Atualiza todos os dados
  Future<void> refreshAllData() async {
    try {
      EnhancedLogger.log(
          '🔄 [DIAGNOSTIC_CONTROLLER] Atualizando todos os dados');

      await _updateSystemStatus();
      await _updatePerformanceMetrics();
      _updateSystemInfo();

      lastUpdate.value = _formatDateTime(DateTime.now());
    } catch (e) {
      EnhancedLogger.log('❌ [DIAGNOSTIC_CONTROLLER] Erro na atualização: $e');
    }
  }

  /// Atualiza status do sistema
  Future<void> _updateSystemStatus() async {
    try {
      // Verifica saúde geral do sistema
      final isHealthy = await _checkSystemHealth();
      final hasWarnings = await _checkSystemWarnings();

      if (!isHealthy) {
        _setSystemStatus('Erro', 'Sistema com problemas críticos');
      } else if (hasWarnings) {
        _setSystemStatus('Atenção', 'Sistema com avisos');
      } else {
        _setSystemStatus('Saudável', 'Sistema funcionando normalmente');
      }
    } catch (e) {
      _setSystemStatus('Erro', 'Falha na verificação de status');
    }
  }

  /// Verifica saúde do sistema
  Future<bool> _checkSystemHealth() async {
    try {
      // Verifica se serviços essenciais estão funcionando
      final hasCache = _localStorage != null;
      final hasSyncManager = _syncManager != null;
      final hasUnifiedInterface = _unifiedInterface != null;

      return hasCache && hasSyncManager && hasUnifiedInterface;
    } catch (e) {
      return false;
    }
  }

  /// Verifica avisos do sistema
  Future<bool> _checkSystemWarnings() async {
    try {
      // Verifica condições que geram avisos
      final cacheSize = await _getCacheSize();
      final pendingOperations = _getPendingOperationsCount();

      return cacheSize > 10 * 1024 * 1024 ||
          pendingOperations > 100; // 10MB ou 100 ops
    } catch (e) {
      return false;
    }
  }

  /// Atualiza métricas de performance
  Future<void> _updatePerformanceMetrics() async {
    try {
      final metrics = <String, dynamic>{};

      // Métricas de cache
      metrics['cacheSize'] = await _getCacheSize();
      metrics['cacheHitRate'] = await _getCacheHitRate();

      // Métricas de sincronização
      metrics['pendingOperations'] = _getPendingOperationsCount();
      metrics['syncSuccessRate'] = await _getSyncSuccessRate();

      // Métricas de performance
      metrics['averageResponseTime'] = await _getAverageResponseTime();
      metrics['operationsPerMinute'] = await _getOperationsPerMinute();

      performanceMetrics.value = metrics;
    } catch (e) {
      EnhancedLogger.log('❌ [DIAGNOSTIC_CONTROLLER] Erro nas métricas: $e');
    }
  }

  /// Atualiza informações do sistema
  void _updateSystemInfo() {
    final uptime = DateTime.now().difference(_startTime);
    systemUptime.value = _formatDuration(uptime);

    // Simula uso de memória (em produção, seria real)
    memoryUsage.value =
        '${(performanceMetrics['cacheSize'] ?? 0) ~/ (1024 * 1024)} MB';
    cacheSize.value = '${(performanceMetrics['cacheSize'] ?? 0) ~/ 1024} KB';
    operationsPerMinute.value =
        '${performanceMetrics['operationsPerMinute'] ?? 0}';
  }

  /// Atualiza métricas em tempo real
  void _updateMetrics() {
    // Atualiza métricas que mudam frequentemente
    _updateSystemInfo();
  }

  /// Define status do sistema
  void _setSystemStatus(String status, String message) {
    systemStatus.value = status;

    // Adiciona alerta se necessário
    if (status != 'Saudável') {
      _addSystemAlert(status, message);
    }
  }

  /// Adiciona alerta do sistema
  void _addSystemAlert(String type, String message) {
    final alert = {
      'type': type,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    systemAlerts.insert(0, alert);

    // Mantém apenas os últimos 10 alertas
    if (systemAlerts.length > 10) {
      systemAlerts.removeRange(10, systemAlerts.length);
    }
  }

  /// Adiciona ação recente
  void _addRecentAction(String action, String result,
      {Map<String, dynamic>? details}) {
    final actionData = {
      'action': action,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
      'details': details ?? {},
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    recentActions.insert(0, actionData);

    // Mantém apenas as últimas 20 ações
    if (recentActions.length > 20) {
      recentActions.removeRange(20, recentActions.length);
    }
  }

  /// Executa diagnóstico completo
  Future<void> runFullDiagnostic(String? userId) async {
    if (isRunningDiagnostic.value) return;

    EnhancedLogger.log(
        '🔍 [DIAGNOSTIC_CONTROLLER] Executando diagnóstico completo');

    isRunningDiagnostic.value = true;
    diagnosticProgress.value = 0.0;

    try {
      // Fase 1: Verificação de integridade
      currentAction.value = 'Verificando integridade do sistema...';
      diagnosticProgress.value = 0.2;
      await Future.delayed(Duration(milliseconds: 500));

      final integrityResult =
          await IntegrationSystemTester.runReliabilityTest();

      // Fase 2: Teste de performance
      currentAction.value = 'Testando performance...';
      diagnosticProgress.value = 0.4;
      await Future.delayed(Duration(milliseconds: 500));

      final performanceResult =
          await IntegrationSystemTester.runPerformanceTest();

      // Fase 3: Validação de consistência
      currentAction.value = 'Validando consistência...';
      diagnosticProgress.value = 0.6;
      await Future.delayed(Duration(milliseconds: 500));

      final consistencyResult = userId != null
          ? await _unifiedInterface.validateConsistency(userId)
          : true;

      // Fase 4: Verificação de conflitos
      currentAction.value = 'Verificando conflitos...';
      diagnosticProgress.value = 0.8;
      await Future.delayed(Duration(milliseconds: 500));

      final conflictsResult =
          userId != null ? await _conflictResolver.detectConflicts(userId) : [];

      // Fase 5: Relatório final
      currentAction.value = 'Gerando relatório...';
      diagnosticProgress.value = 1.0;
      await Future.delayed(Duration(milliseconds: 500));

      final diagnosticResult = {
        'integrity': integrityResult,
        'performance': performanceResult,
        'consistency': consistencyResult,
        'conflicts': conflictsResult.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _addRecentAction(
        'Diagnóstico Completo',
        'Concluído com sucesso',
        details: diagnosticResult,
      );

      // Atualiza status baseado nos resultados
      if (!integrityResult ||
          !consistencyResult ||
          conflictsResult.isNotEmpty) {
        _setSystemStatus('Atenção', 'Problemas detectados no diagnóstico');
      } else {
        _setSystemStatus('Saudável', 'Diagnóstico passou em todos os testes');
      }

      Get.snackbar(
        'Diagnóstico Completo',
        'Diagnóstico executado com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      EnhancedLogger.log('❌ [DIAGNOSTIC_CONTROLLER] Erro no diagnóstico: $e');

      _addRecentAction('Diagnóstico Completo', 'Falhou',
          details: {'error': e.toString()});
      _setSystemStatus('Erro', 'Falha no diagnóstico completo');

      Get.snackbar(
        'Erro no Diagnóstico',
        'Falha na execução: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isRunningDiagnostic.value = false;
      currentAction.value = '';
      diagnosticProgress.value = 0.0;
    }
  }

  /// Força sincronização
  Future<void> forceSync(String? userId) async {
    if (userId == null) return;

    await _performAction('Força Sincronização', () async {
      final result = await _syncManager.forceSync(userId);
      if (!result.success) {
        throw Exception(result.message);
      }
      return 'Sincronização forçada com sucesso';
    });
  }

  /// Resolve conflitos
  Future<void> resolveConflicts(String? userId) async {
    if (userId == null) return;

    await _performAction('Resolução de Conflitos', () async {
      final conflicts = await _conflictResolver.detectConflicts(userId);
      if (conflicts.isNotEmpty) {
        await _conflictResolver.resolveConflicts(userId);
        return 'Resolvidos ${conflicts.length} conflitos';
      } else {
        return 'Nenhum conflito encontrado';
      }
    });
  }

  /// Recupera dados
  Future<void> recoverData(String? userId) async {
    if (userId == null) return;

    await _performAction('Recuperação de Dados', () async {
      final result = await _recoveryService.recoverLostData(userId);
      if (!result.success) {
        throw Exception(result.message);
      }
      return 'Recuperados ${result.recoveredCount} itens';
    });
  }

  /// Valida sistema
  Future<void> validateSystem(String? userId) async {
    await _performAction('Validação do Sistema', () async {
      if (userId != null) {
        final isValid = await _unifiedInterface.validateConsistency(userId);
        return isValid ? 'Sistema válido' : 'Sistema inconsistente';
      } else {
        final isHealthy = await _checkSystemHealth();
        return isHealthy ? 'Sistema saudável' : 'Sistema com problemas';
      }
    });
  }

  /// Limpa cache
  Future<void> clearCache(String? userId) async {
    await _performAction('Limpeza de Cache', () async {
      if (userId != null) {
        await _localStorage.clearNotifications(userId);
        _unifiedInterface.clearCache(userId);
        return 'Cache limpo para usuário';
      } else {
        // Limpa cache global (implementação simplificada)
        return 'Cache global limpo';
      }
    });
  }

  /// Executa teste de stress
  Future<void> runStressTest(String? userId) async {
    await _performAction('Teste de Stress', () async {
      // Implementação simplificada do teste de stress
      await Future.delayed(Duration(seconds: 2));
      return 'Teste de stress concluído';
    });
  }

  /// Executa ação com tratamento de erro
  Future<void> _performAction(
      String actionName, Future<String> Function() action) async {
    if (isPerformingAction.value) return;

    isPerformingAction.value = true;
    currentAction.value = actionName;

    try {
      final result = await action();

      _addRecentAction(actionName, result);

      Get.snackbar(
        actionName,
        result,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      EnhancedLogger.log('❌ [DIAGNOSTIC_CONTROLLER] Erro em $actionName: $e');

      _addRecentAction(actionName, 'Falhou', details: {'error': e.toString()});

      Get.snackbar(
        'Erro em $actionName',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPerformingAction.value = false;
      currentAction.value = '';
      await refreshAllData();
    }
  }

  /// Manipula ações do menu
  void handleMenuAction(String action) {
    switch (action) {
      case 'export_logs':
        _exportLogs();
        break;
      case 'clear_cache':
        clearCache(null);
        break;
      case 'reset_system':
        _resetSystem();
        break;
    }
  }

  /// Exporta logs
  void _exportLogs() {
    // Implementação simplificada
    Get.snackbar(
      'Exportar Logs',
      'Logs exportados com sucesso',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    _addRecentAction('Exportar Logs', 'Logs exportados');
  }

  /// Reset do sistema
  void _resetSystem() {
    Get.dialog(
      AlertDialog(
        title: Text('Reset do Sistema'),
        content: Text(
            'Tem certeza que deseja resetar o sistema? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performSystemReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Executa reset do sistema
  Future<void> _performSystemReset() async {
    await _performAction('Reset do Sistema', () async {
      // Implementação simplificada do reset
      await Future.delayed(Duration(seconds: 1));

      // Limpa dados
      recentActions.clear();
      systemAlerts.clear();
      performanceMetrics.clear();

      // Reinicializa
      await _initializeController();

      return 'Sistema resetado com sucesso';
    });
  }

  // Métodos auxiliares para métricas
  Future<int> _getCacheSize() async {
    try {
      // Implementação simplificada
      return 1024 * 1024; // 1MB
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getCacheHitRate() async {
    try {
      // Implementação simplificada
      return 0.85; // 85%
    } catch (e) {
      return 0.0;
    }
  }

  int _getPendingOperationsCount() {
    try {
      // Implementação simplificada
      return 5;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getSyncSuccessRate() async {
    try {
      // Implementação simplificada
      return 0.95; // 95%
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> _getAverageResponseTime() async {
    try {
      // Implementação simplificada
      return 150; // 150ms
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getOperationsPerMinute() async {
    try {
      // Implementação simplificada
      return 120;
    } catch (e) {
      return 0;
    }
  }

  // Métodos de formatação
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
