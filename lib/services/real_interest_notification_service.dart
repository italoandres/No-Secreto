import 'dart:async';
import '../models/real_notification_model.dart';
import '../repositories/real_interests_repository.dart';
import '../services/real_user_data_cache.dart';
import '../services/real_notification_converter.dart';
import '../utils/enhanced_logger.dart';

class RealInterestNotificationService {
  static final RealInterestNotificationService _instance = RealInterestNotificationService._internal();
  factory RealInterestNotificationService() => _instance;
  RealInterestNotificationService._internal();

  final RealInterestsRepository _interestsRepository = RealInterestsRepository();
  final RealUserDataCache _userCache = RealUserDataCache();
  final RealNotificationConverter _converter = RealNotificationConverter();

  StreamSubscription? _currentSubscription;
  String? _currentUserId;

  /// Busca notificações reais para um usuário
  Future<List<RealNotification>> getRealInterestNotifications(String userId) async {
    try {
      EnhancedLogger.info('🔍 [REAL_NOTIFICATIONS] Buscando notificações REAIS para: $userId');
      
      // 1. Busca interesses do Firebase
      final interests = await _interestsRepository.getInterestsForUser(userId);
      EnhancedLogger.info('📊 [REAL_NOTIFICATIONS] Encontrados ${interests.length} interesses');
      
      if (interests.isEmpty) {
        EnhancedLogger.info('🎉 [REAL_NOTIFICATIONS] Nenhum interesse encontrado');
        return [];
      }

      // 2. Extrai IDs únicos dos usuários que demonstraram interesse
      final userIds = interests.map((interest) => interest.from).toSet().toList();
      EnhancedLogger.info('👥 [REAL_NOTIFICATIONS] Buscando dados de ${userIds.length} usuários');

      // 3. Busca dados dos usuários (com cache)
      final usersData = await _userCache.preloadUsers(userIds);
      EnhancedLogger.info('✅ [REAL_NOTIFICATIONS] Dados de usuários carregados');

      // 4. Converte interesses em notificações
      final notifications = await _converter.convertInterestsToNotifications(interests, usersData);
      EnhancedLogger.info('🔄 [REAL_NOTIFICATIONS] ${notifications.length} notificações convertidas');

      // 5. Agrupa notificações por usuário (evita spam)
      final groupedNotifications = _converter.groupNotificationsByUser(notifications);
      EnhancedLogger.success('🎉 [REAL_NOTIFICATIONS] ${groupedNotifications.length} notificações REAIS encontradas');

      // Debug das notificações
      _debugLogNotifications(groupedNotifications);

      return groupedNotifications;
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [REAL_NOTIFICATIONS] Erro ao buscar notificações', error: e, stackTrace: stackTrace);
      
      // Fallback: tenta busca simples
      return await _getFallbackNotifications(userId);
    }
  }

  /// Subscreve a atualizações em tempo real
  Stream<List<RealNotification>> subscribeToRealTimeUpdates(String userId) {
    try {
      EnhancedLogger.info('🔄 [REAL_NOTIFICATIONS] Iniciando stream em tempo real para: $userId');
      
      _currentUserId = userId;
      
      return _interestsRepository.streamInterestsForUser(userId).asyncMap((interests) async {
        EnhancedLogger.info('📡 [REAL_NOTIFICATIONS] Stream atualizado: ${interests.length} interesses');
        
        if (interests.isEmpty) return <RealNotification>[];

        // Busca dados dos usuários
        final userIds = interests.map((interest) => interest.from).toSet().toList();
        final usersData = await _userCache.preloadUsers(userIds);

        // Converte em notificações
        final notifications = await _converter.convertInterestsToNotifications(interests, usersData);
        final groupedNotifications = _converter.groupNotificationsByUser(notifications);

        EnhancedLogger.success('🎉 [REAL_NOTIFICATIONS] Stream: ${groupedNotifications.length} notificações');
        return groupedNotifications;
      });
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [REAL_NOTIFICATIONS] Erro no stream', error: e, stackTrace: stackTrace);
      
      // Fallback: stream vazio
      return Stream.value(<RealNotification>[]);
    }
  }

  /// Força atualização das notificações
  Future<List<RealNotification>> refreshNotifications(String userId) async {
    EnhancedLogger.info('🔄 [REAL_NOTIFICATIONS] Forçando atualização para: $userId');
    
    // Limpa cache de usuários
    _userCache.clearCache();
    
    // Busca novamente
    return await getRealInterestNotifications(userId);
  }

  /// Busca notificações recentes (últimas 24h)
  Future<List<RealNotification>> getRecentNotifications(String userId) async {
    try {
      EnhancedLogger.info('⏰ [REAL_NOTIFICATIONS] Buscando notificações recentes para: $userId');
      
      final interests = await _interestsRepository.getRecentInterestsForUser(userId);
      
      if (interests.isEmpty) {
        EnhancedLogger.info('📭 [REAL_NOTIFICATIONS] Nenhuma notificação recente');
        return [];
      }

      final userIds = interests.map((interest) => interest.from).toSet().toList();
      final usersData = await _userCache.preloadUsers(userIds);
      final notifications = await _converter.convertInterestsToNotifications(interests, usersData);

      EnhancedLogger.success('⏰ [REAL_NOTIFICATIONS] ${notifications.length} notificações recentes');
      return notifications;
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [REAL_NOTIFICATIONS] Erro ao buscar notificações recentes', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Para o stream atual
  void stopRealTimeUpdates() {
    EnhancedLogger.info('⏹️ [REAL_NOTIFICATIONS] Parando stream em tempo real');
    _currentSubscription?.cancel();
    _currentSubscription = null;
    _currentUserId = null;
  }

  /// Obtém estatísticas do serviço
  Map<String, dynamic> getServiceStats() {
    return {
      'hasActiveStream': _currentSubscription != null,
      'currentUserId': _currentUserId,
      'cacheStats': _userCache.getCacheStats(),
    };
  }

  /// Fallback para casos de erro
  Future<List<RealNotification>> _getFallbackNotifications(String userId) async {
    try {
      EnhancedLogger.warning('🔄 [REAL_NOTIFICATIONS] Usando fallback para: $userId');
      
      // Tenta busca simples sem ordenação
      final interests = await _interestsRepository.getInterestsForUser(userId);
      
      if (interests.isEmpty) return [];

      // Cria notificações com dados mínimos
      final notifications = <RealNotification>[];
      
      for (final interest in interests) {
        try {
          final userData = await _userCache.getUserData(interest.from);
          final notification = _converter.convertInterestToNotification(interest, userData);
          notifications.add(notification);
        } catch (e) {
          EnhancedLogger.error('Erro no fallback para interesse: ${interest.id}', error: e);
        }
      }

      EnhancedLogger.info('🔄 [REAL_NOTIFICATIONS] Fallback: ${notifications.length} notificações');
      return notifications;
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ [REAL_NOTIFICATIONS] Erro no fallback', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Debug: log das notificações encontradas
  void _debugLogNotifications(List<RealNotification> notifications) {
    EnhancedLogger.debug('=== NOTIFICAÇÕES ENCONTRADAS ===');
    
    for (final notification in notifications) {
      EnhancedLogger.debug('📧 ${notification.fromUserName}: ${notification.message}');
      EnhancedLogger.debug('   ID: ${notification.id}');
      EnhancedLogger.debug('   Timestamp: ${notification.timestamp}');
      EnhancedLogger.debug('   From: ${notification.fromUserId}');
    }
    
    EnhancedLogger.debug('=== TOTAL: ${notifications.length} ===');
  }

  /// Debug: testa busca completa
  Future<void> debugFullSearch(String userId) async {
    EnhancedLogger.debug('=== DEBUG BUSCA COMPLETA ===');
    EnhancedLogger.debug('Usuário: $userId');
    
    try {
      // 1. Testa repository
      EnhancedLogger.debug('1. Testando repository...');
      final interests = await _interestsRepository.getInterestsForUser(userId);
      EnhancedLogger.debug('   Interesses encontrados: ${interests.length}');
      
      for (final interest in interests) {
        EnhancedLogger.debug('   - ${interest.toString()}');
      }

      // 2. Testa cache de usuários
      EnhancedLogger.debug('2. Testando cache de usuários...');
      final userIds = interests.map((e) => e.from).toSet().toList();
      final usersData = await _userCache.preloadUsers(userIds);
      EnhancedLogger.debug('   Usuários carregados: ${usersData.length}');
      
      for (final entry in usersData.entries) {
        EnhancedLogger.debug('   - ${entry.key}: ${entry.value.getDisplayName()}');
      }

      // 3. Testa conversão
      EnhancedLogger.debug('3. Testando conversão...');
      final notifications = await _converter.convertInterestsToNotifications(interests, usersData);
      EnhancedLogger.debug('   Notificações criadas: ${notifications.length}');
      
      _converter.debugValidateNotifications(notifications);

      // 4. Testa agrupamento
      EnhancedLogger.debug('4. Testando agrupamento...');
      final grouped = _converter.groupNotificationsByUser(notifications);
      EnhancedLogger.debug('   Notificações agrupadas: ${grouped.length}');

    } catch (e, stackTrace) {
      EnhancedLogger.error('Erro no debug completo', error: e, stackTrace: stackTrace);
    }
    
    EnhancedLogger.debug('=== FIM DEBUG ===');
  }

  /// Limpa recursos
  void dispose() {
    EnhancedLogger.info('🧹 [REAL_NOTIFICATIONS] Limpando recursos');
    stopRealTimeUpdates();
    _userCache.clearCache();
  }
}