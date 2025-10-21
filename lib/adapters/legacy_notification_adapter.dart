import 'dart:async';
import '../models/real_notification_model.dart';
import '../repositories/single_source_notification_repository.dart';
import '../services/unified_notification_interface.dart';
import '../utils/enhanced_logger.dart';

/// Adaptador para sistemas legados de notificação
/// Mantém compatibilidade durante a migração
class LegacyNotificationAdapter {
  static final LegacyNotificationAdapter _instance = LegacyNotificationAdapter._internal();
  factory LegacyNotificationAdapter() => _instance;
  LegacyNotificationAdapter._internal();

  final SingleSourceNotificationRepository _repository = SingleSourceNotificationRepository();
  final UnifiedNotificationInterface _unifiedInterface = UnifiedNotificationInterface();

  /// Adaptador para RealInterestNotificationService
  Future<List<RealNotificationModel>> getRealNotifications(String userId) async {
    EnhancedLogger.log('🔄 [ADAPTER] Adaptando getRealNotifications para: $userId');
    
    try {
      return await _repository.getNotifications(userId);
    } catch (e) {
      EnhancedLogger.log('❌ [ADAPTER] Erro no adaptador getRealNotifications: $e');
      return [];
    }
  }

  /// Adaptador para stream de notificações reais
  Stream<List<RealNotificationModel>> getRealNotificationsStream(String userId) {
    EnhancedLogger.log('📡 [ADAPTER] Adaptando stream para: $userId');
    return _unifiedInterface.getUnifiedNotificationStream(userId);
  }

  /// Adaptador para MatchesController
  Stream<List<RealNotificationModel>> getMatchesNotificationStream(String userId) {
    EnhancedLogger.log('🎯 [ADAPTER] Adaptando stream do MatchesController para: $userId');
    return _unifiedInterface.getUnifiedNotificationStream(userId);
  }

  /// Adaptador para busca simples de notificações
  Future<List<RealNotificationModel>> getSimpleNotifications(String userId) async {
    EnhancedLogger.log('⚡ [ADAPTER] Adaptando busca simples para: $userId');
    
    // Tenta cache primeiro para performance
    if (_unifiedInterface.hasCachedData(userId)) {
      return _unifiedInterface.getCachedNotifications(userId);
    }
    
    // Busca do repositório se não há cache
    return await _repository.getNotifications(userId);
  }

  /// Adaptador para força de sincronização
  Future<void> forceNotificationSync(String userId) async {
    EnhancedLogger.log('🚀 [ADAPTER] Adaptando força de sincronização para: $userId');
    await _unifiedInterface.forceSync(userId);
  }

  /// Adaptador para invalidação de cache
  Future<void> invalidateNotificationCache(String userId) async {
    EnhancedLogger.log('🗑️ [ADAPTER] Adaptando invalidação de cache para: $userId');
    await _unifiedInterface.invalidateAndRefresh(userId);
  }

  /// Adaptador para verificação de cache
  bool hasNotificationCache(String userId) {
    return _unifiedInterface.hasCachedData(userId);
  }

  /// Adaptador para resolução de conflitos
  Future<void> resolveNotificationConflicts(String userId) async {
    EnhancedLogger.log('⚡ [ADAPTER] Adaptando resolução de conflitos para: $userId');
    await _unifiedInterface.resolveConflicts(userId);
  }

  /// Adaptador para validação de consistência
  Future<bool> validateNotificationConsistency(String userId) async {
    EnhancedLogger.log('🔍 [ADAPTER] Adaptando validação de consistência para: $userId');
    return await _unifiedInterface.validateConsistency(userId);
  }

  /// Adaptador para estatísticas
  Map<String, dynamic> getNotificationStats() {
    return _unifiedInterface.getSystemStats();
  }

  /// Migra sistema legado para unificado
  Future<void> migrateLegacySystem(String userId) async {
    EnhancedLogger.log('🔄 [ADAPTER] Migrando sistema legado para: $userId');
    
    try {
      // Força sincronização inicial
      await _unifiedInterface.forceSync(userId);
      
      // Valida consistência
      final isConsistent = await _unifiedInterface.validateConsistency(userId);
      
      if (isConsistent) {
        EnhancedLogger.log('✅ [ADAPTER] Migração concluída com sucesso para: $userId');
      } else {
        EnhancedLogger.log('⚠️ [ADAPTER] Migração com inconsistências para: $userId');
        await _unifiedInterface.resolveConflicts(userId);
      }
      
    } catch (e) {
      EnhancedLogger.log('❌ [ADAPTER] Erro na migração: $e');
      rethrow;
    }
  }

  /// Limpa recursos do adaptador
  void dispose(String userId) {
    EnhancedLogger.log('🧹 [ADAPTER] Limpando recursos do adaptador para: $userId');
    _unifiedInterface.disposeUser(userId);
  }
}