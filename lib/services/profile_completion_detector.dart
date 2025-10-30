import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/profile_completion_status.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';

/// Serviço para detectar quando o perfil espiritual está completo
class ProfileCompletionDetector {
  static const String _tag = 'PROFILE_COMPLETION_DETECTOR';

  // Cache para evitar múltiplas consultas
  static final Map<String, ProfileCompletionStatus> _statusCache = {};
  static final Map<String, StreamController<bool>> _completionStreams = {};

  /// Verifica se o perfil está completo
  static Future<bool> isProfileComplete(String userId) async {
    return await ErrorHandler.safeExecute<bool>(
          () async {
            EnhancedLogger.info('Checking profile completion',
                tag: _tag, data: {'userId': userId});

            final profile =
                await SpiritualProfileRepository.getProfileByUserId(userId);

            if (profile == null) {
              EnhancedLogger.warning('Profile not found',
                  tag: _tag, data: {'userId': userId});
              return false;
            }

            final isComplete = _validateProfileCompletion(profile);

            EnhancedLogger.info('Profile completion check result',
                tag: _tag,
                data: {
                  'userId': userId,
                  'isComplete': isComplete,
                  'percentage': (profile.completionPercentage ?? 0) * 100,
                });

            return isComplete;
          },
          context: 'ProfileCompletionDetector.isProfileComplete',
          fallbackValue: false,
        ) ??
        false;
  }

  /// Obtém o status detalhado de completude do perfil
  static Future<ProfileCompletionStatus> getCompletionStatus(
      String userId) async {
    return await ErrorHandler.safeExecute<ProfileCompletionStatus>(
          () async {
            // Verificar cache primeiro
            if (_statusCache.containsKey(userId)) {
              final cachedStatus = _statusCache[userId]!;
              // Cache válido por 30 segundos
              if (DateTime.now()
                      .difference(cachedStatus.completedAt ?? DateTime.now())
                      .inSeconds <
                  30) {
                return cachedStatus;
              }
            }

            EnhancedLogger.info('Getting detailed completion status',
                tag: _tag, data: {'userId': userId});

            final profile =
                await SpiritualProfileRepository.getProfileByUserId(userId);

            if (profile == null) {
              EnhancedLogger.warning('Profile not found for completion status',
                  tag: _tag, data: {'userId': userId});
              return const ProfileCompletionStatus(
                isComplete: false,
                completionPercentage: 0.0,
                missingTasks: ['profile_not_found'],
              );
            }

            // Usar validação real em vez de confiar no campo isProfileComplete
            final isReallyComplete = _validateProfileCompletion(profile);

            // Criar status com resultado da validação real
            final status =
                ProfileCompletionStatus.fromProfile(profile).copyWith(
              isComplete: isReallyComplete,
            );

            // Atualizar cache
            _statusCache[userId] = status;

            EnhancedLogger.success('Completion status retrieved',
                tag: _tag,
                data: {
                  'userId': userId,
                  'status': status.toString(),
                });

            return status;
          },
          context: 'ProfileCompletionDetector.getCompletionStatus',
          fallbackValue: const ProfileCompletionStatus(
            isComplete: false,
            completionPercentage: 0.0,
            missingTasks: ['error_getting_status'],
          ),
        ) ??
        const ProfileCompletionStatus(
          isComplete: false,
          completionPercentage: 0.0,
          missingTasks: ['error_getting_status'],
        );
  }

  /// Cria um stream para monitorar mudanças na completude do perfil
  static Stream<bool> watchProfileCompletion(String userId) {
    if (!_completionStreams.containsKey(userId)) {
      _completionStreams[userId] = StreamController<bool>.broadcast();

      // Iniciar monitoramento
      _startWatching(userId);
    }

    return _completionStreams[userId]!.stream;
  }

  /// Executa callback quando o perfil é completado
  static Future<void> onProfileCompleted(
      String userId, VoidCallback callback) async {
    final stream = watchProfileCompletion(userId);

    StreamSubscription? subscription;
    subscription = stream.listen((isComplete) {
      if (isComplete) {
        EnhancedLogger.info('Profile completion detected, executing callback',
            tag: _tag, data: {'userId': userId});

        callback();
        subscription?.cancel();
      }
    });
  }

  /// Força uma verificação e notifica os listeners se necessário
  static Future<void> checkAndNotify(String userId) async {
    try {
      final isComplete = await isProfileComplete(userId);

      if (_completionStreams.containsKey(userId)) {
        _completionStreams[userId]!.add(isComplete);
      }

      // Limpar cache para forçar nova verificação na próxima consulta
      _statusCache.remove(userId);
    } catch (e, stackTrace) {
      EnhancedLogger.error('Error checking and notifying completion',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});
    }
  }

  /// Valida se o perfil está realmente completo
  static bool _validateProfileCompletion(SpiritualProfileModel profile) {
    try {
      // NOVA LÓGICA: Validar dados reais primeiro (não verificar isProfileComplete primeiro)

      // 1. Verificar se tem foto principal
      if (profile.mainPhotoUrl?.isEmpty ?? true) {
        return false;
      }

      // 2. Verificar se tem informações básicas
      if (!profile.hasBasicInfo) {
        return false;
      }

      // 3. Verificar se tem biografia
      if (!profile.hasBiography) {
        return false;
      }

      // 4. Verificar tarefas obrigatórias
      final tasks = profile.completionTasks;
      final requiredTasks = ['photos', 'identity', 'biography', 'preferences'];

      for (final task in requiredTasks) {
        if (tasks[task] != true) {
          return false;
        }
      }

      // 5. Verificar percentual de completude
      if ((profile.completionPercentage ?? 0.0) < 1.0) {
        return false;
      }

      // RESULTADO: Perfil está completo baseado em dados reais
      final isReallyComplete = true;

      // 6. Verificar inconsistência e corrigir automaticamente
      if (profile.id != null && profile.isProfileComplete != isReallyComplete) {
        // Chamar correção de forma assíncrona sem bloquear o retorno
        _fixProfileCompletionInconsistency(profile.id!, isReallyComplete);
      }

      return isReallyComplete;
    } catch (e) {
      EnhancedLogger.error('Error validating profile completion',
          tag: _tag, error: e, data: {'profileId': profile.id});
      return false;
    }
  }

  /// Corrige inconsistência entre isProfileComplete e dados reais
  static Future<void> _fixProfileCompletionInconsistency(
      String profileId, bool correctValue) async {
    try {
      EnhancedLogger.warning('Fixing profile completion inconsistency',
          tag: _tag,
          data: {
            'profileId': profileId,
            'correctValue': correctValue,
          });

      await SpiritualProfileRepository.updateProfile(profileId, {
        'isProfileComplete': correctValue,
      });

      // Invalidar cache para forçar nova verificação
      _statusCache.clear();

      EnhancedLogger.success('Profile completion inconsistency fixed',
          tag: _tag, data: {'profileId': profileId});
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to fix profile completion inconsistency',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
          data: {'profileId': profileId});
      // Não propagar erro - a validação real ainda é válida
    }
  }

  /// Inicia o monitoramento de um perfil
  static void _startWatching(String userId) {
    // Verificação inicial
    Timer.run(() async {
      final isComplete = await isProfileComplete(userId);
      if (_completionStreams.containsKey(userId)) {
        _completionStreams[userId]!.add(isComplete);
      }
    });

    // Verificação periódica (a cada 10 segundos)
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_completionStreams.containsKey(userId)) {
        timer.cancel();
        return;
      }

      try {
        final isComplete = await isProfileComplete(userId);
        if (_completionStreams.containsKey(userId)) {
          _completionStreams[userId]!.add(isComplete);
        }
      } catch (e) {
        // Silenciar erros periódicos para não spam logs
      }
    });
  }

  /// Limpa recursos para um usuário específico
  static void dispose(String userId) {
    _completionStreams[userId]?.close();
    _completionStreams.remove(userId);
    _statusCache.remove(userId);

    EnhancedLogger.info('Disposed completion detector resources',
        tag: _tag, data: {'userId': userId});
  }

  /// Limpa todos os recursos
  static void disposeAll() {
    for (final controller in _completionStreams.values) {
      controller.close();
    }
    _completionStreams.clear();
    _statusCache.clear();

    EnhancedLogger.info('Disposed all completion detector resources',
        tag: _tag);
  }
}
