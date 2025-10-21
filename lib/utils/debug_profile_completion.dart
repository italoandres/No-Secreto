import '../services/profile_completion_detector.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para debug da completude do perfil
class DebugProfileCompletion {
  static const String _tag = 'DEBUG_PROFILE_COMPLETION';

  /// Debug completo do status do perfil
  static Future<void> debugProfileStatus(String userId) async {
    try {
      EnhancedLogger.info('=== DEBUG PROFILE COMPLETION ===', tag: _tag);
      
      // 1. Buscar perfil diretamente
      final profile = await SpiritualProfileRepository.getProfileByUserId(userId);
      
      if (profile == null) {
        EnhancedLogger.error('Profile not found', tag: _tag, data: {'userId': userId});
        return;
      }

      // 2. Debug dados básicos
      EnhancedLogger.info('Profile Basic Data', tag: _tag, data: {
        'profileId': profile.id,
        'userId': profile.userId,
        'isProfileComplete': profile.isProfileComplete,
        'completionPercentage': profile.completionPercentage,
      });

      // 3. Debug tarefas
      EnhancedLogger.info('Completion Tasks', tag: _tag, data: profile.completionTasks);

      // 4. Debug campos específicos
      EnhancedLogger.info('Profile Fields', tag: _tag, data: {
        'mainPhotoUrl': profile.mainPhotoUrl?.isNotEmpty ?? false,
        'hasBasicInfo': profile.hasBasicInfo,
        'hasBiography': profile.hasBiography,
        'hasRequiredPhotos': profile.hasRequiredPhotos,
        'canShowPublicProfile': profile.canShowPublicProfile,
      });

      // 5. Debug campos faltantes
      final missingFields = profile.missingRequiredFields;
      EnhancedLogger.info('Missing Fields', tag: _tag, data: {
        'count': missingFields.length,
        'fields': missingFields,
      });

      // 6. Verificar cada tarefa obrigatória
      final requiredTasks = ['photos', 'identity', 'biography', 'preferences'];
      for (final task in requiredTasks) {
        final isComplete = profile.completionTasks[task] == true;
        EnhancedLogger.info('Task Status', tag: _tag, data: {
          'task': task,
          'isComplete': isComplete,
          'value': profile.completionTasks[task],
        });
      }

      // 7. Usar o detector para validar
      final detectorStatus = await ProfileCompletionDetector.getCompletionStatus(userId);
      EnhancedLogger.info('Detector Status', tag: _tag, data: {
        'isComplete': detectorStatus.isComplete,
        'percentage': detectorStatus.completionPercentage,
        'missingTasks': detectorStatus.missingTasks,
      });

      // 8. Verificar validação manual
      final isCompleteManual = await ProfileCompletionDetector.isProfileComplete(userId);
      EnhancedLogger.info('Manual Validation', tag: _tag, data: {
        'isComplete': isCompleteManual,
      });

      EnhancedLogger.info('=== END DEBUG ===', tag: _tag);

    } catch (e, stackTrace) {
      EnhancedLogger.error('Error debugging profile completion', 
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId}
      );
    }
  }

  /// Debug específico de uma tarefa
  static Future<void> debugTask(String userId, String taskKey) async {
    try {
      final profile = await SpiritualProfileRepository.getProfileByUserId(userId);
      
      if (profile == null) {
        EnhancedLogger.error('Profile not found for task debug', tag: _tag);
        return;
      }

      EnhancedLogger.info('Task Debug', tag: _tag, data: {
        'taskKey': taskKey,
        'value': profile.completionTasks[taskKey],
        'isTrue': profile.completionTasks[taskKey] == true,
        'allTasks': profile.completionTasks,
      });

      // Verificações específicas por tarefa
      switch (taskKey) {
        case 'photos':
          EnhancedLogger.info('Photos Task Details', tag: _tag, data: {
            'mainPhotoUrl': profile.mainPhotoUrl,
            'hasMainPhoto': profile.mainPhotoUrl?.isNotEmpty ?? false,
            'hasRequiredPhotos': profile.hasRequiredPhotos,
          });
          break;
        case 'identity':
          EnhancedLogger.info('Identity Task Details', tag: _tag, data: {
            'hasBasicInfo': profile.hasBasicInfo,
            'city': profile.city,
            'age': profile.age,
          });
          break;
        case 'biography':
          EnhancedLogger.info('Biography Task Details', tag: _tag, data: {
            'hasBiography': profile.hasBiography,
            'aboutMe': profile.aboutMe?.isNotEmpty ?? false,
            'purpose': profile.purpose?.isNotEmpty ?? false,
          });
          break;
        case 'preferences':
          EnhancedLogger.info('Preferences Task Details', tag: _tag, data: {
            'allowInteractions': profile.allowInteractions,
          });
          break;
      }

    } catch (e) {
      EnhancedLogger.error('Error debugging task', 
        tag: _tag,
        error: e,
        data: {'userId': userId, 'taskKey': taskKey}
      );
    }
  }
}