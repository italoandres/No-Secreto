import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preferences_data.dart';
import '../models/preferences_result.dart';
import '../services/data_sanitizer.dart';
import '../utils/enhanced_logger.dart';

/// Repository específico para operações de preferências
/// Implementa múltiplas estratégias de persistência para robustez
class PreferencesRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'spiritual_profiles';
  static const String _tag = 'PREFERENCES_REPO';

  /// Atualiza preferências com múltiplas estratégias de fallback
  static Future<PreferencesResult> updatePreferences(
      String profileId, PreferencesData data) async {
    final stopwatch = Stopwatch()..start();
    final corrections = <String>[];

    try {
      EnhancedLogger.info('Starting preferences update', tag: _tag, data: {
        'profileId': profileId,
        'allowInteractions': data.allowInteractions,
        'version': data.version,
      });

      // Preparar dados para Firestore
      final firestoreData = data.toFirestore();

      // Estratégia 1: Update normal
      try {
        await _firestore
            .collection(_collection)
            .doc(profileId)
            .update(firestoreData);

        stopwatch.stop();

        EnhancedLogger.success(
            'Preferences updated successfully (strategy: normal update)',
            tag: _tag,
            data: {
              'profileId': profileId,
              'duration': stopwatch.elapsedMilliseconds,
            });

        return PreferencesResult.success(
          data: data,
          appliedCorrections: corrections,
          operationDuration: stopwatch.elapsed,
          strategyUsed: 'normal_update',
        );
      } catch (updateError) {
        EnhancedLogger.warning('Normal update failed, trying field-by-field',
            tag: _tag,
            data: {
              'error': updateError.toString(),
              'profileId': profileId,
            });

        // Estratégia 2: Update campo por campo
        try {
          await _updateFieldByField(profileId, firestoreData);
          corrections.add('field_by_field_update');

          stopwatch.stop();

          EnhancedLogger.success(
              'Preferences updated successfully (strategy: field-by-field)',
              tag: _tag,
              data: {
                'profileId': profileId,
                'duration': stopwatch.elapsedMilliseconds,
              });

          return PreferencesResult.success(
            data: data,
            appliedCorrections: corrections,
            operationDuration: stopwatch.elapsed,
            strategyUsed: 'field_by_field',
          );
        } catch (fieldError) {
          EnhancedLogger.warning(
              'Field-by-field update failed, trying set with merge',
              tag: _tag,
              data: {
                'error': fieldError.toString(),
                'profileId': profileId,
              });

          // Estratégia 3: Set com merge
          try {
            await _firestore
                .collection(_collection)
                .doc(profileId)
                .set(firestoreData, SetOptions(merge: true));

            corrections.add('set_with_merge');

            stopwatch.stop();

            EnhancedLogger.success(
                'Preferences updated successfully (strategy: set with merge)',
                tag: _tag,
                data: {
                  'profileId': profileId,
                  'duration': stopwatch.elapsedMilliseconds,
                });

            return PreferencesResult.success(
              data: data,
              appliedCorrections: corrections,
              operationDuration: stopwatch.elapsed,
              strategyUsed: 'set_with_merge',
            );
          } catch (setError) {
            EnhancedLogger.warning(
                'Set with merge failed, trying complete replacement',
                tag: _tag,
                data: {
                  'error': setError.toString(),
                  'profileId': profileId,
                });

            // Estratégia 4: Substituição completa (último recurso)
            try {
              // Primeiro, buscar dados existentes
              final existingDoc =
                  await _firestore.collection(_collection).doc(profileId).get();

              if (existingDoc.exists) {
                final existingData = existingDoc.data()!;
                final sanitizedExisting =
                    DataSanitizer.sanitizePreferencesData(existingData);

                // Mesclar com novos dados
                final mergedData = {...sanitizedExisting, ...firestoreData};

                // Substituir documento completo
                await _firestore
                    .collection(_collection)
                    .doc(profileId)
                    .set(mergedData);

                corrections.add('complete_replacement');

                stopwatch.stop();

                EnhancedLogger.success(
                    'Preferences updated successfully (strategy: complete replacement)',
                    tag: _tag,
                    data: {
                      'profileId': profileId,
                      'duration': stopwatch.elapsedMilliseconds,
                    });

                return PreferencesResult.success(
                  data: data,
                  appliedCorrections: corrections,
                  operationDuration: stopwatch.elapsed,
                  strategyUsed: 'complete_replacement',
                );
              } else {
                throw Exception('Profile document not found');
              }
            } catch (replacementError) {
              stopwatch.stop();

              EnhancedLogger.error('All update strategies failed',
                  tag: _tag,
                  error: replacementError,
                  data: {
                    'profileId': profileId,
                    'duration': stopwatch.elapsedMilliseconds,
                    'originalError': updateError.toString(),
                    'fieldError': fieldError.toString(),
                    'setError': setError.toString(),
                  });

              return PreferencesResult.persistenceError(
                  'Failed to update preferences after trying all strategies: ${replacementError.toString()}');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      stopwatch.stop();

      EnhancedLogger.error('Unexpected error in preferences update',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {
            'profileId': profileId,
            'duration': stopwatch.elapsedMilliseconds,
          });

      // Determinar tipo de erro
      final errorType = _determineErrorType(e);

      return PreferencesResult.error(
        errorMessage: e.toString(),
        errorType: errorType,
        appliedCorrections: corrections,
        operationDuration: stopwatch.elapsed,
      );
    }
  }

  /// Busca preferências com sanitização automática
  static Future<PreferencesData?> getPreferences(String profileId) async {
    try {
      EnhancedLogger.info('Loading preferences',
          tag: _tag, data: {'profileId': profileId});

      final doc = await _firestore.collection(_collection).doc(profileId).get();

      if (!doc.exists) {
        EnhancedLogger.warning('Profile document not found',
            tag: _tag, data: {'profileId': profileId});
        return null;
      }

      final data = doc.data()!;
      final preferences = PreferencesData.fromFirestore(data);

      EnhancedLogger.success('Preferences loaded successfully',
          tag: _tag,
          data: {
            'profileId': profileId,
            'allowInteractions': preferences.allowInteractions,
            'wasSanitized': preferences.wasSanitized,
          });

      return preferences;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to load preferences',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'profileId': profileId});

      return null;
    }
  }

  /// Atualiza status de completude da tarefa
  static Future<PreferencesResult> updateTaskCompletion(
      String profileId, String taskName, bool completed) async {
    try {
      EnhancedLogger.info('Updating task completion', tag: _tag, data: {
        'profileId': profileId,
        'task': taskName,
        'completed': completed,
      });

      final updateData = {
        'completionTasks.$taskName': completed,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore
          .collection(_collection)
          .doc(profileId)
          .update(updateData);

      EnhancedLogger.success('Task completion updated successfully',
          tag: _tag,
          data: {
            'profileId': profileId,
            'task': taskName,
            'completed': completed,
          });

      return PreferencesResult.success(
        data: PreferencesData.defaultValues(),
        strategyUsed: 'task_completion_update',
      );
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to update task completion',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {
            'profileId': profileId,
            'task': taskName,
            'completed': completed,
          });

      final errorType = _determineErrorType(e);

      return PreferencesResult.error(
        errorMessage: 'Failed to update task completion: ${e.toString()}',
        errorType: errorType,
      );
    }
  }

  /// Atualiza campos individualmente com delay
  static Future<void> _updateFieldByField(
      String profileId, Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      try {
        await _firestore
            .collection(_collection)
            .doc(profileId)
            .update({entry.key: entry.value});

        EnhancedLogger.info('Field updated individually', tag: _tag, data: {
          'profileId': profileId,
          'field': entry.key,
          'type': entry.value.runtimeType.toString(),
        });

        // Pequeno delay entre updates para evitar conflitos
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        EnhancedLogger.error('Failed to update individual field',
            tag: _tag,
            error: e,
            data: {
              'profileId': profileId,
              'field': entry.key,
              'value': entry.value,
            });
        rethrow;
      }
    }
  }

  /// Determina o tipo de erro baseado na exceção
  static PreferencesError _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return PreferencesError.networkError;
    }

    if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return PreferencesError.persistenceError;
    }

    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return PreferencesError.validationError;
    }

    return PreferencesError.unknownError;
  }

  /// Valida se o documento foi atualizado corretamente
  static Future<bool> validateUpdate(
      String profileId, PreferencesData expectedData) async {
    try {
      // Aguardar um pouco para garantir consistência
      await Future.delayed(const Duration(milliseconds: 500));

      final doc = await _firestore.collection(_collection).doc(profileId).get();

      if (!doc.exists) {
        return false;
      }

      final actualData = PreferencesData.fromFirestore(doc.data()!);

      final isValid =
          actualData.allowInteractions == expectedData.allowInteractions;

      EnhancedLogger.info('Update validation result', tag: _tag, data: {
        'profileId': profileId,
        'isValid': isValid,
        'expected': expectedData.allowInteractions,
        'actual': actualData.allowInteractions,
      });

      return isValid;
    } catch (e) {
      EnhancedLogger.error('Failed to validate update',
          tag: _tag, error: e, data: {'profileId': profileId});

      return false;
    }
  }
}
