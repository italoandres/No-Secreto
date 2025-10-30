import '../utils/enhanced_logger.dart';
import '../services/profile_completion_detector.dart';

/// Status da vitrine
class VitrineStatus {
  final bool isPubliclyVisible;
  final String displayName;

  const VitrineStatus({
    required this.isPubliclyVisible,
    required this.displayName,
  });
}

/// Gerenciador de status da vitrine (stub temporário)
class VitrineStatusManager {
  static const String _tag = 'VITRINE_STATUS_MANAGER';

  /// Verifica se pode ativar a vitrine
  Future<bool> canActivateVitrine(String userId) async {
    try {
      EnhancedLogger.info('Checking if can activate vitrine',
          tag: _tag, data: {'userId': userId});

      // Usar o detector de completude como validação principal
      final isComplete =
          await ProfileCompletionDetector.isProfileComplete(userId);

      EnhancedLogger.info('Vitrine activation check result',
          tag: _tag, data: {'userId': userId, 'canActivate': isComplete});

      return isComplete;
    } catch (e) {
      EnhancedLogger.error('Error checking vitrine activation',
          tag: _tag, error: e, data: {'userId': userId});
      return false;
    }
  }

  /// Obtém o status da vitrine
  Future<VitrineStatus> getVitrineStatus(String userId) async {
    try {
      final canActivate = await canActivateVitrine(userId);

      return VitrineStatus(
        isPubliclyVisible: canActivate,
        displayName: canActivate ? 'Ativa' : 'Inativa',
      );
    } catch (e) {
      EnhancedLogger.error('Error getting vitrine status',
          tag: _tag, error: e, data: {'userId': userId});

      return const VitrineStatus(
        isPubliclyVisible: false,
        displayName: 'Erro',
      );
    }
  }

  /// Obtém campos faltantes para ativar a vitrine
  Future<List<String>> getMissingRequiredFields(String userId) async {
    try {
      final status =
          await ProfileCompletionDetector.getCompletionStatus(userId);

      if (status.isComplete) {
        return [];
      }

      // Retornar campos faltantes baseado no status
      final missingFields = <String>[];

      if (status.missingTasks.contains('photos')) {
        missingFields.add('Foto principal');
      }
      if (status.missingTasks.contains('identity')) {
        missingFields.add('Informações básicas');
      }
      if (status.missingTasks.contains('biography')) {
        missingFields.add('Biografia espiritual');
      }
      if (status.missingTasks.contains('preferences')) {
        missingFields.add('Preferências de interação');
      }

      return missingFields.isEmpty ? ['Perfil incompleto'] : missingFields;
    } catch (e) {
      EnhancedLogger.error('Error getting missing fields',
          tag: _tag, error: e, data: {'userId': userId});
      return ['Erro ao verificar campos'];
    }
  }
}
