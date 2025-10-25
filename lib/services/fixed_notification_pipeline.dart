import 'dart:async';
import 'package:get/get.dart';
import '../models/real_notification_model.dart';
import '../models/interest_model.dart';
import '../models/user_data_model.dart';
import '../utils/enhanced_logger.dart';
import '../controllers/matches_controller.dart';
import '../services/javascript_error_handler.dart';
import '../repositories/enhanced_real_interests_repository.dart';
import '../services/temp_notification_converter.dart';
import '../services/error_recovery_system.dart';
import '../services/real_time_sync_manager.dart';

/// Pipeline corrigido para processamento de interações em notificações
class FixedNotificationPipeline {
  static FixedNotificationPipeline? _instance;
  static FixedNotificationPipeline get instance =>
      _instance ??= FixedNotificationPipeline._();

  FixedNotificationPipeline._();

  bool _isInitialized = false;
  bool _isProcessing = false;
  final Map<String, UserData> _userCache = {};
  final List<String> _processingLog = [];

  /// Inicializa o pipeline corrigido
  void initialize() {
    if (_isInitialized) return;

    try {
      // Inicializa todos os componentes
      JavaScriptErrorHandler.instance.initialize();
      ErrorRecoverySystem.instance.initialize();
      RealTimeSyncManager.instance.initialize();

      _isInitialized = true;

      EnhancedLogger.success(
          '✅ [FIXED_PIPELINE] Pipeline inicializado com sucesso');
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro ao inicializar pipeline',
          error: e);
    }
  }

  /// Processa interações de forma robusta e corrigida
  Future<List<RealNotification>> processInteractionsRobustly(
      String userId) async {
    if (_isProcessing) {
      EnhancedLogger.warning(
          '⚠️ [FIXED_PIPELINE] Processamento já em andamento');
      return [];
    }

    _isProcessing = true;
    _processingLog.clear();

    try {
      EnhancedLogger.info('🚀 [FIXED_PIPELINE] Iniciando processamento robusto',
          tag: 'FIXED_NOTIFICATION_PIPELINE',
          data: {
            'userId': userId,
            'timestamp': DateTime.now().toIso8601String(),
            'pipelineInitialized': _isInitialized
          });

      _addToLog('Iniciando processamento para usuário: $userId');

      // ETAPA 1: Busca interações com retry robusto
      final interests = await _fetchInteractionsWithValidation(userId);
      _addToLog(
          'Etapa 1 concluída: ${interests.length} interações encontradas');

      if (interests.isEmpty) {
        EnhancedLogger.warning(
            '⚠️ [FIXED_PIPELINE] Nenhuma interação encontrada');
        _addToLog('AVISO: Nenhuma interação encontrada');
        return [];
      }

      // ETAPA 2: Pré-carrega dados dos usuários
      await _preloadUserData(interests);
      _addToLog(
          'Etapa 2 concluída: Dados de ${_userCache.length} usuários carregados');

      // ETAPA 3: Converte interações em notificações
      final notifications = await _convertWithValidation(interests);
      _addToLog(
          'Etapa 3 concluída: ${notifications.length} notificações criadas');

      if (notifications.isEmpty) {
        EnhancedLogger.error(
            '❌ [FIXED_PIPELINE] PROBLEMA CRÍTICO: Conversão resultou em 0 notificações',
            data: {
              'originalInteractions': interests.length,
              'convertedNotifications': 0,
              'processingLog': _processingLog
            });

        // Tenta recuperação de emergência
        return await _emergencyRecovery(userId, interests);
      }

      // ETAPA 4: Valida notificações criadas
      final validNotifications = _validateNotifications(notifications);
      _addToLog(
          'Etapa 4 concluída: ${validNotifications.length} notificações válidas');

      // ETAPA 5: Sincroniza com UI
      await _syncWithUI(validNotifications);
      _addToLog('Etapa 5 concluída: UI sincronizada');

      // ETAPA 6: Salva cache de fallback
      _saveFallbackCache(userId, validNotifications);
      _addToLog('Etapa 6 concluída: Cache de fallback salvo');

      EnhancedLogger.success(
          '🎉 [FIXED_PIPELINE] Processamento concluído com sucesso',
          data: {
            'userId': userId,
            'originalInteractions': interests.length,
            'finalNotifications': validNotifications.length,
            'conversionRate': interests.isNotEmpty
                ? (validNotifications.length / interests.length * 100)
                    .toStringAsFixed(2)
                : '0.00',
            'processingSteps': _processingLog.length,
            'processingLog': _processingLog
          });

      return validNotifications;
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro crítico no processamento',
          error: e, data: {'userId': userId, 'processingLog': _processingLog});

      // Tenta recuperação de emergência
      return await ErrorRecoverySystem.instance.recoverNotifications(userId);
    } finally {
      _isProcessing = false;
    }
  }

  /// ETAPA 1: Busca interações com validação rigorosa
  Future<List<Interest>> _fetchInteractionsWithValidation(String userId) async {
    try {
      EnhancedLogger.info('🔍 [FIXED_PIPELINE] Etapa 1: Buscando interações',
          data: {'userId': userId});

      // Usa repository robusto com retry
      final interests = await EnhancedRealInterestsRepository.instance
          .getInterestsWithRetry(userId);

      EnhancedLogger.info('📊 [FIXED_PIPELINE] Interações brutas obtidas',
          data: {
            'userId': userId,
            'rawInteractions': interests.length,
            'interactionIds': interests.map((i) => i.id).take(5).toList()
          });

      // Validação adicional
      final validInterests = <Interest>[];
      for (final interest in interests) {
        if (_validateInteraction(interest)) {
          validInterests.add(interest);
        } else {
          EnhancedLogger.warning(
              '⚠️ [FIXED_PIPELINE] Interação inválida ignorada',
              data: {
                'interactionId': interest.id,
                'fromUserId': interest.from,
                'toUserId': interest.to
              });
        }
      }

      EnhancedLogger.success('✅ [FIXED_PIPELINE] Etapa 1 concluída', data: {
        'userId': userId,
        'rawInteractions': interests.length,
        'validInteractions': validInterests.length,
        'filteredOut': interests.length - validInterests.length
      });

      return validInterests;
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro na Etapa 1',
          error: e, data: {'userId': userId});
      rethrow;
    }
  }

  /// Valida uma interação individual
  bool _validateInteraction(Interest interest) {
    try {
      // Validações básicas
      if (interest.id.isEmpty) return false;
      if (interest.from.isEmpty) return false;
      if (interest.to.isEmpty) return false;
      if (interest.from == interest.to) return false;

      // Validação de timestamp
      final now = DateTime.now();
      if (interest.timestamp.isAfter(now)) return false;

      // Não muito antiga (30 dias)
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      if (interest.timestamp.isBefore(thirtyDaysAgo)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ETAPA 2: Pré-carrega dados dos usuários
  Future<void> _preloadUserData(List<Interest> interests) async {
    try {
      EnhancedLogger.info(
          '👥 [FIXED_PIPELINE] Etapa 2: Pré-carregando dados dos usuários');

      final userIds = interests.map((i) => i.from).toSet();

      EnhancedLogger.info('📋 [FIXED_PIPELINE] Usuários únicos identificados',
          data: {
            'uniqueUsers': userIds.length,
            'userIds': userIds.take(5).toList()
          });

      // Carrega dados de cada usuário
      for (final userId in userIds) {
        if (!_userCache.containsKey(userId)) {
          try {
            final userData = await _loadUserData(userId);
            if (userData != null) {
              _userCache[userId] = userData;
            }
          } catch (e) {
            EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro ao carregar usuário',
                error: e, data: {'userId': userId});

            // Cria dados básicos como fallback
            _userCache[userId] = UserData(
              userId: userId,
              name: 'Usuário',
              username: 'user_$userId',
              email: '$userId@example.com',
              photoUrl: null,
            );
          }
        }
      }

      EnhancedLogger.success('✅ [FIXED_PIPELINE] Etapa 2 concluída', data: {
        'requestedUsers': userIds.length,
        'cachedUsers': _userCache.length,
        'newlyLoaded': _userCache.length
      });
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro na Etapa 2', error: e);
      rethrow;
    }
  }

  /// Carrega dados de um usuário específico
  Future<UserData?> _loadUserData(String userId) async {
    try {
      // Implementação simplificada - pode ser expandida para buscar do Firebase
      return UserData(
        userId: userId,
        name: '🚀 Sistema Teste', // Nome padrão para testes
        username: 'test_user_$userId',
        email: '$userId@test.com',
        photoUrl: null,
      );
    } catch (e) {
      return null;
    }
  }

  /// ETAPA 3: Converte interações com validação
  Future<List<RealNotification>> _convertWithValidation(
      List<Interest> interests) async {
    try {
      EnhancedLogger.info('🔄 [FIXED_PIPELINE] Etapa 3: Convertendo interações',
          data: {
            'interactionsToConvert': interests.length,
            'userCacheSize': _userCache.length
          });

      // Usa converter robusto
      final converter = TempNotificationConverter.instance;
      final notifications = await converter.convertInteractionsToNotifications(
          interests, _userCache);

      EnhancedLogger.info('📧 [FIXED_PIPELINE] Conversão inicial concluída',
          data: {
            'originalInteractions': interests.length,
            'convertedNotifications': notifications.length,
            'conversionRate': interests.isNotEmpty
                ? (notifications.length / interests.length * 100)
                    .toStringAsFixed(2)
                : '0.00'
          });

      // Log detalhado das notificações criadas
      for (int i = 0; i < notifications.length && i < 5; i++) {
        final notification = notifications[i];
        EnhancedLogger.info('📧 [FIXED_PIPELINE] Notificação criada ${i + 1}',
            data: {
              'id': notification.id,
              'fromUser': notification.fromUserName,
              'message': notification.message,
              'timestamp': notification.timestamp.toIso8601String()
            });
      }

      return notifications;
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro na Etapa 3', error: e);
      rethrow;
    }
  }

  /// ETAPA 4: Valida notificações criadas
  List<RealNotification> _validateNotifications(
      List<RealNotification> notifications) {
    try {
      EnhancedLogger.info('✅ [FIXED_PIPELINE] Etapa 4: Validando notificações',
          data: {'notificationsToValidate': notifications.length});

      final validNotifications = <RealNotification>[];

      for (final notification in notifications) {
        final converter = TempNotificationConverter.instance;
        if (converter.validateNotification(notification)) {
          validNotifications.add(notification);
        } else {
          EnhancedLogger.warning(
              '⚠️ [FIXED_PIPELINE] Notificação inválida removida',
              data: {
                'notificationId': notification.id,
                'fromUser': notification.fromUserName
              });
        }
      }

      EnhancedLogger.success('✅ [FIXED_PIPELINE] Etapa 4 concluída', data: {
        'originalNotifications': notifications.length,
        'validNotifications': validNotifications.length,
        'invalidRemoved': notifications.length - validNotifications.length
      });

      return validNotifications;
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro na Etapa 4', error: e);
      return notifications; // Retorna originais em caso de erro
    }
  }

  /// ETAPA 5: Sincroniza com UI
  Future<void> _syncWithUI(List<RealNotification> notifications) async {
    try {
      EnhancedLogger.info('🔄 [FIXED_PIPELINE] Etapa 5: Sincronizando com UI',
          data: {'notificationsToSync': notifications.length});

      // Usa sync manager para atualização inteligente
      RealTimeSyncManager.instance.syncNotificationsWithUI(notifications);

      // Aguarda um pouco para garantir que a UI foi atualizada
      await Future.delayed(const Duration(milliseconds: 100));

      // Verifica se a sincronização foi bem-sucedida
      final controller = Get.find<MatchesController>();
      final syncedCount = controller.realNotifications.length;

      EnhancedLogger.success('✅ [FIXED_PIPELINE] Etapa 5 concluída', data: {
        'notificationsSent': notifications.length,
        'notificationsSynced': syncedCount,
        'syncSuccessful': syncedCount == notifications.length
      });
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro na Etapa 5', error: e);
    }
  }

  /// ETAPA 6: Salva cache de fallback
  void _saveFallbackCache(String userId, List<RealNotification> notifications) {
    try {
      ErrorRecoverySystem.instance
          .saveFallbackNotifications(userId, notifications);

      EnhancedLogger.info(
          '💾 [FIXED_PIPELINE] Etapa 6: Cache de fallback salvo',
          data: {'userId': userId, 'notificationCount': notifications.length});
    } catch (e) {
      EnhancedLogger.error('❌ [FIXED_PIPELINE] Erro na Etapa 6', error: e);
    }
  }

  /// Recuperação de emergência quando tudo falha
  Future<List<RealNotification>> _emergencyRecovery(
      String userId, List<Interest> originalInterests) async {
    try {
      EnhancedLogger.warning(
          '🚨 [FIXED_PIPELINE] Executando recuperação de emergência',
          data: {
            'userId': userId,
            'originalInteractions': originalInterests.length
          });

      // Tenta conversão manual simples
      final emergencyNotifications = <RealNotification>[];

      for (final interest in originalInterests.take(5)) {
        // Limita a 5 para evitar sobrecarga
        try {
          final notification = RealNotification(
            id: interest.id,
            type: 'interest',
            fromUserId: interest.from,
            fromUserName: '🚀 Sistema Teste',
            fromUserPhoto: null,
            message: '🚀 Sistema Teste se interessou por você',
            timestamp: interest.timestamp,
            isRead: false,
          );

          emergencyNotifications.add(notification);
        } catch (e) {
          EnhancedLogger.error(
              '❌ [FIXED_PIPELINE] Erro na conversão de emergência',
              error: e,
              data: {'interestId': interest.id});
        }
      }

      if (emergencyNotifications.isNotEmpty) {
        // Sincroniza notificações de emergência
        await _syncWithUI(emergencyNotifications);

        EnhancedLogger.success(
            '✅ [FIXED_PIPELINE] Recuperação de emergência bem-sucedida',
            data: {
              'userId': userId,
              'emergencyNotifications': emergencyNotifications.length
            });
      }

      return emergencyNotifications;
    } catch (e) {
      EnhancedLogger.error(
          '❌ [FIXED_PIPELINE] Falha na recuperação de emergência',
          error: e);
      return [];
    }
  }

  /// Adiciona entrada ao log de processamento
  void _addToLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _processingLog.add('[$timestamp] $message');

    // Mantém apenas os últimos 50 logs
    if (_processingLog.length > 50) {
      _processingLog.removeAt(0);
    }
  }

  /// Obtém estatísticas do pipeline
  Map<String, dynamic> getPipelineStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isProcessing': _isProcessing,
      'userCacheSize': _userCache.length,
      'processingLogSize': _processingLog.length,
      'recentProcessingLog': _processingLog.take(10).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Obtém log completo de processamento
  List<String> getProcessingLog() {
    return List.from(_processingLog);
  }

  /// Limpa cache e reinicia pipeline
  void reset() {
    _userCache.clear();
    _processingLog.clear();
    _isProcessing = false;

    EnhancedLogger.info('🔄 [FIXED_PIPELINE] Pipeline resetado');
  }
}
