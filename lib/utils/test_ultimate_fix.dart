import '../utils/ultimate_real_notifications_fix.dart';
import '../utils/enhanced_logger.dart';

/// TESTE IMEDIATO DA SOLUÇÃO DEFINITIVA
class TestUltimateFix {
  
  /// Execute esta função para testar AGORA
  static Future<void> executeNow() async {
    const userId = 'St2kw3cgX2MMPxlLRmBDjYm2nO22'; // ID da Itala
    
    EnhancedLogger.info('🚀 EXECUTANDO TESTE DEFINITIVO AGORA!');
    EnhancedLogger.info('=' * 50);
    
    try {
      // 1. Diagnóstico completo
      await UltimateRealNotificationsFix.fullDiagnostic(userId);
      
      // 2. Aguarda um pouco
      await Future.delayed(const Duration(seconds: 3));
      
      // 3. Força novamente para garantir
      await UltimateRealNotificationsFix.forceRealNotificationsToShow(userId);
      
      EnhancedLogger.success('🎉 TESTE DEFINITIVO CONCLUÍDO!');
      EnhancedLogger.success('✅ As notificações reais devem aparecer agora!');
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('❌ Erro no teste definitivo', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Versão ainda mais agressiva - FORÇA TUDO
  static Future<void> forceEverything() async {
    const userId = 'St2kw3cgX2MMPxlLRmBDjYm2nO22';
    
    EnhancedLogger.info('💥 FORÇANDO TUDO - MODO AGRESSIVO!');
    
    for (int i = 0; i < 3; i++) {
      EnhancedLogger.info('🔄 Tentativa ${i + 1}/3');
      
      await UltimateRealNotificationsFix.forceRealNotificationsToShow(userId);
      await Future.delayed(const Duration(seconds: 2));
    }
    
    EnhancedLogger.success('💥 MODO AGRESSIVO CONCLUÍDO!');
  }
}