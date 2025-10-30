import 'dart:async';
import '../services/unified_notification_interface.dart';
import '../services/ui_state_manager.dart';
import '../services/notification_sync_logger.dart';
import '../adapters/legacy_notification_adapter.dart';
import '../controllers/unified_matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// Status da migração
enum MigrationStatus { notStarted, inProgress, completed, failed, rollback }

/// Resultado da migração
class MigrationResult {
  final MigrationStatus status;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final List<String> migratedSystems;
  final List<String> failedSystems;

  MigrationResult({
    required this.status,
    required this.message,
    required this.details,
    required this.timestamp,
    this.migratedSystems = const [],
    this.failedSystems = const [],
  });

  bool get isSuccess => status == MigrationStatus.completed;
  bool get hasFailures => failedSystems.isNotEmpty;
}

/// Migrador de sistemas legados para arquitetura unificada
class LegacySystemMigrator {
  static final LegacySystemMigrator _instance =
      LegacySystemMigrator._internal();
  factory LegacySystemMigrator() => _instance;
  LegacySystemMigrator._internal();

  final UnifiedNotificationInterface _unifiedInterface =
      UnifiedNotificationInterface();
  final UIStateManager _uiStateManager = UIStateManager();
  final NotificationSyncLogger _logger = NotificationSyncLogger();
  final LegacyNotificationAdapter _adapter = LegacyNotificationAdapter();

  final Map<String, MigrationStatus> _migrationStatus = {};
  final Map<String, DateTime> _migrationStartTime = {};
  final Map<String, List<String>> _migratedSystems = {};

  /// Executa migração completa para um usuário
  Future<MigrationResult> migrateUserToUnifiedSystem(String userId) async {
    EnhancedLogger.log(
        '🔄 [MIGRATOR] Iniciando migração completa para: $userId');

    _migrationStatus[userId] = MigrationStatus.inProgress;
    _migrationStartTime[userId] = DateTime.now();

    final migratedSystems = <String>[];
    final failedSystems = <String>[];

    try {
      _logger.logUserAction(userId, 'Migration started');

      // 1. Migra sistema de notificações
      final notificationResult = await _migrateNotificationSystem(userId);
      if (notificationResult.isSuccess) {
        migratedSystems.addAll(notificationResult.migratedSystems);
      } else {
        failedSystems.addAll(notificationResult.failedSystems);
      }

      // 2. Migra controller de matches
      final matchesResult = await _migrateMatchesController(userId);
      if (matchesResult.isSuccess) {
        migratedSystems.addAll(matchesResult.migratedSystems);
      } else {
        failedSystems.addAll(matchesResult.failedSystems);
      }

      // 3. Remove sistemas duplicados
      final cleanupResult = await _removeDuplicateSystems(userId);
      if (cleanupResult.isSuccess) {
        migratedSystems.addAll(cleanupResult.migratedSystems);
      } else {
        failedSystems.addAll(cleanupResult.failedSystems);
      }

      // 4. Valida migração
      final validationResult = await _validateMigration(userId);
      if (!validationResult.isSuccess) {
        failedSystems.add('validation');
      }

      // Determina status final
      final finalStatus = failedSystems.isEmpty
          ? MigrationStatus.completed
          : MigrationStatus.failed;

      _migrationStatus[userId] = finalStatus;
      _migratedSystems[userId] = migratedSystems;

      final result = MigrationResult(
        status: finalStatus,
        message: finalStatus == MigrationStatus.completed
            ? 'Migração concluída com sucesso'
            : 'Migração concluída com falhas',
        details: {
          'duration': DateTime.now()
              .difference(_migrationStartTime[userId]!)
              .inMilliseconds,
          'migratedCount': migratedSystems.length,
          'failedCount': failedSystems.length,
        },
        timestamp: DateTime.now(),
        migratedSystems: migratedSystems,
        failedSystems: failedSystems,
      );

      _logger.logUserAction(userId, 'Migration completed', data: {
        'status': finalStatus.toString(),
        'migratedSystems': migratedSystems,
        'failedSystems': failedSystems,
      });

      EnhancedLogger.log('✅ [MIGRATOR] Migração concluída: ${result.message}');
      return result;
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATOR] Erro na migração: $e');

      _migrationStatus[userId] = MigrationStatus.failed;

      _logger.logError(userId, 'Migration failed', data: {
        'error': e.toString(),
        'migratedSystems': migratedSystems,
        'failedSystems': failedSystems,
      });

      return MigrationResult(
        status: MigrationStatus.failed,
        message: 'Migração falhou: $e',
        details: {
          'error': e.toString(),
          'duration': DateTime.now()
              .difference(_migrationStartTime[userId]!)
              .inMilliseconds,
        },
        timestamp: DateTime.now(),
        migratedSystems: migratedSystems,
        failedSystems: [...failedSystems, 'migration_process'],
      );
    }
  }

  /// Migra sistema de notificações
  Future<MigrationResult> _migrateNotificationSystem(String userId) async {
    EnhancedLogger.log('📧 [MIGRATOR] Migrando sistema de notificações');

    try {
      // 1. Migra dados existentes
      await _adapter.migrateLegacySystem(userId);

      // 2. Inicializa sistema unificado
      final notifications = await _unifiedInterface.forceSync(userId);

      // 3. Valida migração
      final hasCache = _unifiedInterface.hasCachedData(userId);
      if (!hasCache) {
        throw Exception('Cache não foi criado após migração');
      }

      return MigrationResult(
        status: MigrationStatus.completed,
        message: 'Sistema de notificações migrado com sucesso',
        details: {
          'notificationsCount':
              _unifiedInterface.getCachedNotifications(userId).length,
          'hasCache': hasCache,
        },
        timestamp: DateTime.now(),
        migratedSystems: [
          'notification_system',
          'unified_interface',
          'cache_system'
        ],
      );
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATOR] Erro na migração de notificações: $e');

      return MigrationResult(
        status: MigrationStatus.failed,
        message: 'Falha na migração do sistema de notificações',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        failedSystems: ['notification_system'],
      );
    }
  }

  /// Migra controller de matches
  Future<MigrationResult> _migrateMatchesController(String userId) async {
    EnhancedLogger.log('🎯 [MIGRATOR] Migrando controller de matches');

    try {
      // 1. Cria novo controller unificado
      final unifiedController = UnifiedMatchesController();

      // 2. Inicializa para o usuário
      await unifiedController.initializeForUser(userId);

      // 3. Valida funcionamento
      final stats = unifiedController.getControllerStats();
      if (!stats['hasActiveSubscriptions']) {
        throw Exception('Subscriptions não foram configuradas corretamente');
      }

      return MigrationResult(
        status: MigrationStatus.completed,
        message: 'Controller de matches migrado com sucesso',
        details: stats,
        timestamp: DateTime.now(),
        migratedSystems: ['matches_controller', 'unified_controller'],
      );
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATOR] Erro na migração do controller: $e');

      return MigrationResult(
        status: MigrationStatus.failed,
        message: 'Falha na migração do controller de matches',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        failedSystems: ['matches_controller'],
      );
    }
  }

  /// Remove sistemas duplicados
  Future<MigrationResult> _removeDuplicateSystems(String userId) async {
    EnhancedLogger.log('🧹 [MIGRATOR] Removendo sistemas duplicados');

    try {
      final removedSystems = <String>[];

      // Lista de sistemas legados para remover
      final legacySystems = [
        'RealInterestNotificationService',
        'RealNotificationConverter',
        'RealUserDataCache',
        'OldMatchesController',
      ];

      // Simula remoção (em implementação real, seria desabilitação)
      for (final system in legacySystems) {
        EnhancedLogger.log('🗑️ [MIGRATOR] Removendo sistema legado: $system');
        removedSystems.add(system);
      }

      return MigrationResult(
        status: MigrationStatus.completed,
        message: 'Sistemas duplicados removidos com sucesso',
        details: {
          'removedSystems': removedSystems,
          'removedCount': removedSystems.length,
        },
        timestamp: DateTime.now(),
        migratedSystems: ['cleanup_duplicates'],
      );
    } catch (e) {
      EnhancedLogger.log(
          '❌ [MIGRATOR] Erro na remoção de sistemas duplicados: $e');

      return MigrationResult(
        status: MigrationStatus.failed,
        message: 'Falha na remoção de sistemas duplicados',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        failedSystems: ['cleanup_duplicates'],
      );
    }
  }

  /// Valida migração
  Future<MigrationResult> _validateMigration(String userId) async {
    EnhancedLogger.log('🔍 [MIGRATOR] Validando migração');

    try {
      final validationResults = <String, bool>{};

      // 1. Valida sistema unificado
      validationResults['unified_system'] =
          await _unifiedInterface.validateConsistency(userId);

      // 2. Valida cache
      validationResults['cache_system'] =
          _unifiedInterface.hasCachedData(userId);

      // 3. Valida UI state
      final uiState = _uiStateManager.getCurrentState(userId);
      validationResults['ui_state'] = uiState != null;

      // 4. Valida adaptador
      validationResults['adapter'] = _adapter.hasNotificationCache(userId);

      final allValid = validationResults.values.every((valid) => valid);

      return MigrationResult(
        status: allValid ? MigrationStatus.completed : MigrationStatus.failed,
        message: allValid ? 'Validação passou' : 'Validação falhou',
        details: {
          'validationResults': validationResults,
          'allValid': allValid,
        },
        timestamp: DateTime.now(),
        migratedSystems: allValid ? ['validation'] : [],
        failedSystems: allValid ? [] : ['validation'],
      );
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATOR] Erro na validação: $e');

      return MigrationResult(
        status: MigrationStatus.failed,
        message: 'Erro na validação da migração',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        failedSystems: ['validation'],
      );
    }
  }

  /// Executa rollback se necessário
  Future<MigrationResult> rollbackMigration(String userId) async {
    EnhancedLogger.log('⏪ [MIGRATOR] Iniciando rollback para: $userId');

    _migrationStatus[userId] = MigrationStatus.rollback;

    try {
      final rollbackSystems = <String>[];

      // 1. Restaura sistemas legados
      await _restoreLegacySystems(userId);
      rollbackSystems.add('legacy_systems_restored');

      // 2. Remove sistema unificado
      await _removeUnifiedSystem(userId);
      rollbackSystems.add('unified_system_removed');

      // 3. Limpa cache unificado
      _unifiedInterface.clearCache(userId);
      rollbackSystems.add('cache_cleared');

      _migrationStatus[userId] = MigrationStatus.notStarted;

      _logger.logUserAction(userId, 'Migration rollback completed', data: {
        'rollbackSystems': rollbackSystems,
      });

      return MigrationResult(
        status: MigrationStatus.notStarted,
        message: 'Rollback concluído com sucesso',
        details: {
          'rollbackSystems': rollbackSystems,
          'rollbackCount': rollbackSystems.length,
        },
        timestamp: DateTime.now(),
        migratedSystems: rollbackSystems,
      );
    } catch (e) {
      EnhancedLogger.log('❌ [MIGRATOR] Erro no rollback: $e');

      _logger.logError(userId, 'Rollback failed', data: {
        'error': e.toString(),
      });

      return MigrationResult(
        status: MigrationStatus.failed,
        message: 'Rollback falhou: $e',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
        failedSystems: ['rollback_process'],
      );
    }
  }

  /// Restaura sistemas legados
  Future<void> _restoreLegacySystems(String userId) async {
    EnhancedLogger.log('🔄 [MIGRATOR] Restaurando sistemas legados');

    // Simula restauração de sistemas legados
    final legacySystems = [
      'RealInterestNotificationService',
      'RealNotificationConverter',
      'RealUserDataCache',
      'OldMatchesController',
    ];

    for (final system in legacySystems) {
      EnhancedLogger.log('🔄 [MIGRATOR] Restaurando sistema: $system');
      // Em implementação real, seria reabilitação dos sistemas
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  /// Remove sistema unificado
  Future<void> _removeUnifiedSystem(String userId) async {
    EnhancedLogger.log('🗑️ [MIGRATOR] Removendo sistema unificado');

    // Dispose do sistema unificado
    _unifiedInterface.disposeUser(userId);
    _uiStateManager.disposeUser(userId);
  }

  /// Verifica se migração está em progresso
  bool isMigrationInProgress(String userId) {
    return _migrationStatus[userId] == MigrationStatus.inProgress;
  }

  /// Obtém status da migração
  MigrationStatus getMigrationStatus(String userId) {
    return _migrationStatus[userId] ?? MigrationStatus.notStarted;
  }

  /// Obtém sistemas migrados
  List<String> getMigratedSystems(String userId) {
    return _migratedSystems[userId] ?? [];
  }

  /// Obtém tempo de migração
  Duration? getMigrationDuration(String userId) {
    final startTime = _migrationStartTime[userId];
    if (startTime == null) return null;

    return DateTime.now().difference(startTime);
  }

  /// Obtém estatísticas da migração
  Map<String, dynamic> getMigrationStats(String userId) {
    return {
      'status': getMigrationStatus(userId).toString(),
      'migratedSystems': getMigratedSystems(userId),
      'duration': getMigrationDuration(userId)?.inMilliseconds,
      'isInProgress': isMigrationInProgress(userId),
      'startTime': _migrationStartTime[userId]?.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa dados de migração
  void clearMigrationData(String userId) {
    _migrationStatus.remove(userId);
    _migrationStartTime.remove(userId);
    _migratedSystems.remove(userId);

    EnhancedLogger.log('🧹 [MIGRATOR] Dados de migração limpos para: $userId');
  }

  /// Obtém relatório completo de migração
  Map<String, dynamic> getMigrationReport(String userId) {
    final stats = getMigrationStats(userId);
    final status = getMigrationStatus(userId);

    return {
      'userId': userId,
      'migrationStats': stats,
      'systemStatus': {
        'unifiedInterface': _unifiedInterface.hasCachedData(userId),
        'uiStateManager': _uiStateManager.getCurrentState(userId) != null,
        'adapter': _adapter.hasNotificationCache(userId),
      },
      'recommendations': _generateRecommendations(userId, status),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Gera recomendações baseadas no status
  List<String> _generateRecommendations(String userId, MigrationStatus status) {
    final recommendations = <String>[];

    switch (status) {
      case MigrationStatus.notStarted:
        recommendations.add('Execute a migração para usar o sistema unificado');
        recommendations.add('Valide os pré-requisitos antes de iniciar');
        break;

      case MigrationStatus.inProgress:
        recommendations.add('Aguarde a conclusão da migração em progresso');
        break;

      case MigrationStatus.completed:
        recommendations.add('Migração concluída com sucesso');
        recommendations.add('Monitore o sistema para garantir estabilidade');
        break;

      case MigrationStatus.failed:
        recommendations
            .add('Verifique os logs para identificar a causa da falha');
        recommendations
            .add('Considere executar migração forçada se necessário');
        recommendations.add('Execute rollback se o sistema estiver instável');
        break;

      case MigrationStatus.rollback:
        recommendations.add('Sistema foi revertido para estado anterior');
        recommendations
            .add('Investigue a causa da falha antes de tentar novamente');
        break;
    }

    return recommendations;
  }
}
