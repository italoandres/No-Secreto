import '../models/preferences_data.dart';
import '../models/preferences_result.dart';
import '../repositories/preferences_repository.dart';
import '../services/data_sanitizer.dart';
import '../utils/enhanced_logger.dart';

/// Serviço para lógica de negócio de preferências de interação
/// Coordena validação, sanitização e persistência
class PreferencesService {
  static const String _tag = 'PREFERENCES_SERVICE';

  /// Salva preferências com validação e sanitização completas
  static Future<PreferencesResult> savePreferences({
    required String profileId,
    required bool allowInteractions,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      EnhancedLogger.info('Starting preferences save', tag: _tag, data: {
        'profileId': profileId,
        'allowInteractions': allowInteractions,
      });

      // Validação de entrada
      final validationResult = _validateInput(profileId, allowInteractions);
      if (!validationResult.success) {
        return validationResult;
      }

      // Criar dados limpos
      final preferencesData = PreferencesData.defaultValues(
        allowInteractions: allowInteractions,
      );

      // Salvar no repository
      final saveResult = await PreferencesRepository.updatePreferences(
          profileId, preferencesData);

      if (!saveResult.success) {
        return saveResult;
      }

      // Marcar tarefa como completa
      final taskResult = await PreferencesRepository.updateTaskCompletion(
          profileId, 'preferences', true);

      if (!taskResult.success) {
        EnhancedLogger.warning(
            'Failed to mark task as complete, but preferences were saved',
            tag: _tag,
            data: {
              'profileId': profileId,
              'taskError': taskResult.errorMessage,
            });
      }

      // Validar se foi salvo corretamente
      final isValid = await PreferencesRepository.validateUpdate(
          profileId, preferencesData);

      if (!isValid) {
        EnhancedLogger.error('Validation failed after save',
            tag: _tag, data: {'profileId': profileId});

        return PreferencesResult.persistenceError(
            'Data validation failed after save');
      }

      stopwatch.stop();

      EnhancedLogger.success('Preferences saved successfully',
          tag: _tag,
          data: {
            'profileId': profileId,
            'allowInteractions': allowInteractions,
            'duration': stopwatch.elapsedMilliseconds,
            'strategy': saveResult.strategyUsed,
            'corrections': saveResult.appliedCorrections,
          });

      return PreferencesResult.success(
        data: preferencesData,
        appliedCorrections: saveResult.appliedCorrections,
        operationDuration: stopwatch.elapsed,
        strategyUsed: saveResult.strategyUsed,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      EnhancedLogger.error('Unexpected error in preferences save',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {
            'profileId': profileId,
            'allowInteractions': allowInteractions,
            'duration': stopwatch.elapsedMilliseconds,
          });

      return PreferencesResult.unknownError(
          'Unexpected error: ${e.toString()}');
    }
  }

  /// Carrega preferências com sanitização automática
  static Future<PreferencesResult> loadPreferences(String profileId) async {
    try {
      EnhancedLogger.info('Loading preferences',
          tag: _tag, data: {'profileId': profileId});

      // Validação de entrada
      if (profileId.isEmpty) {
        return PreferencesResult.validationError('Profile ID cannot be empty');
      }

      // Carregar do repository
      final preferencesData =
          await PreferencesRepository.getPreferences(profileId);

      if (preferencesData == null) {
        EnhancedLogger.warning('No preferences found, returning defaults',
            tag: _tag, data: {'profileId': profileId});

        return PreferencesResult.success(
          data: PreferencesData.defaultValues(),
          appliedCorrections: ['default_values_used'],
          strategyUsed: 'default_fallback',
        );
      }

      final corrections = <String>[];
      if (preferencesData.wasSanitized) {
        corrections.add('data_was_sanitized');
      }

      EnhancedLogger.success('Preferences loaded successfully',
          tag: _tag,
          data: {
            'profileId': profileId,
            'allowInteractions': preferencesData.allowInteractions,
            'wasSanitized': preferencesData.wasSanitized,
            'version': preferencesData.version,
          });

      return PreferencesResult.success(
        data: preferencesData,
        appliedCorrections: corrections,
        strategyUsed: 'repository_load',
      );
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to load preferences',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'profileId': profileId});

      return PreferencesResult.unknownError(
          'Failed to load preferences: ${e.toString()}');
    }
  }

  /// Marca tarefa como completa
  static Future<PreferencesResult> markTaskComplete(String profileId) async {
    try {
      EnhancedLogger.info('Marking preferences task as complete',
          tag: _tag, data: {'profileId': profileId});

      // Validação de entrada
      if (profileId.isEmpty) {
        return PreferencesResult.validationError('Profile ID cannot be empty');
      }

      // Atualizar no repository
      final result = await PreferencesRepository.updateTaskCompletion(
          profileId, 'preferences', true);

      if (result.success) {
        EnhancedLogger.success('Task marked as complete successfully',
            tag: _tag, data: {'profileId': profileId});
      }

      return result;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to mark task as complete',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'profileId': profileId});

      return PreferencesResult.unknownError(
          'Failed to mark task as complete: ${e.toString()}');
    }
  }

  /// Migra dados existentes para novo formato
  static Future<PreferencesResult> migrateExistingData(String profileId) async {
    try {
      EnhancedLogger.info('Starting data migration',
          tag: _tag, data: {'profileId': profileId});

      // Carregar dados existentes
      final existingData =
          await PreferencesRepository.getPreferences(profileId);

      if (existingData == null) {
        return PreferencesResult.success(
          data: PreferencesData.defaultValues(),
          appliedCorrections: ['no_existing_data'],
          strategyUsed: 'migration_default',
        );
      }

      // Se já está na versão atual, não precisa migrar
      if (existingData.isCurrentVersion && existingData.wasSanitized) {
        EnhancedLogger.info('Data is already current version',
            tag: _tag, data: {'profileId': profileId});

        return PreferencesResult.success(
          data: existingData,
          strategyUsed: 'migration_not_needed',
        );
      }

      // Aplicar migração salvando novamente
      final migrationResult = await savePreferences(
        profileId: profileId,
        allowInteractions: existingData.allowInteractions,
      );

      if (migrationResult.success) {
        final corrections = [
          'data_migrated',
          ...migrationResult.appliedCorrections
        ];

        EnhancedLogger.success('Data migration completed successfully',
            tag: _tag,
            data: {
              'profileId': profileId,
              'corrections': corrections,
            });

        return PreferencesResult.success(
          data: migrationResult.data!,
          appliedCorrections: corrections,
          strategyUsed: 'migration_completed',
        );
      }

      return migrationResult;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Data migration failed',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'profileId': profileId});

      return PreferencesResult.unknownError(
          'Migration failed: ${e.toString()}');
    }
  }

  /// Valida dados de entrada
  static PreferencesResult _validateInput(
      String profileId, bool allowInteractions) {
    if (profileId.isEmpty) {
      return PreferencesResult.validationError('Profile ID cannot be empty');
    }

    if (profileId.length < 10) {
      return PreferencesResult.validationError(
          'Profile ID appears to be invalid');
    }

    // allowInteractions é boolean, então sempre válido

    return PreferencesResult.success(
      data: PreferencesData.defaultValues(),
      strategyUsed: 'validation_passed',
    );
  }

  /// Obtém estatísticas de uso
  static Map<String, dynamic> getUsageStats() {
    // Esta seria implementada com métricas reais em produção
    return {
      'version': '2.0.0',
      'implementation': 'preferences_service_v2',
      'features': [
        'multi_strategy_persistence',
        'automatic_sanitization',
        'data_validation',
        'error_recovery',
      ],
    };
  }
}
