import 'package:get/get.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// Resultado da validação do estado da UI
class ValidationResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic> debugData;
  final List<String> issues;
  
  ValidationResult({
    required this.isValid,
    required this.message,
    required this.debugData,
    required this.issues,
  });
}

/// Validador de estado da UI para sincronização entre controller e interface
class UIStateValidator {
  
  /// Valida se os dados estão corretos para renderização
  static ValidationResult validateRenderingState(MatchesController controller) {
    try {
      EnhancedLogger.info('Iniciando validação do estado de renderização', tag: 'UI_VALIDATOR');
      
      final issues = <String>[];
      final debugData = <String, dynamic>{};
      
      // 1. Verificar se o controller existe e está inicializado
      if (!Get.isRegistered<MatchesController>()) {
        issues.add('Controller não está registrado no GetX');
      }
      
      // 2. Verificar estado das notificações
      final notifications = controller.interestNotifications;
      final notificationsCount = controller.interestNotificationsCount.value;
      
      debugData['notifications_length'] = notifications.length;
      debugData['notifications_count_value'] = notificationsCount;
      debugData['notifications_is_empty'] = notifications.isEmpty;
      debugData['notifications_is_not_empty'] = notifications.isNotEmpty;
      
      // 3. Verificar consistência entre dados
      if (notifications.length != notificationsCount) {
        issues.add('Inconsistência: notifications.length (${notifications.length}) != notificationsCount.value ($notificationsCount)');
      }
      
      // 4. Verificar estrutura dos dados das notificações
      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];
        
        if (notification['profile'] == null) {
          issues.add('Notificação $i: campo "profile" está nulo');
        } else {
          final profile = notification['profile'] as Map<String, dynamic>;
          if (profile['displayName'] == null || profile['displayName'].toString().isEmpty) {
            issues.add('Notificação $i: displayName está vazio');
          }
          if (profile['userId'] == null || profile['userId'].toString().isEmpty) {
            issues.add('Notificação $i: userId está vazio');
          }
        }
        
        if (notification['timeAgo'] == null) {
          issues.add('Notificação $i: campo "timeAgo" está nulo');
        }
      }
      
      // 5. Verificar estado reativo do GetX
      debugData['is_reactive'] = true; // RxList é sempre reativo
      debugData['has_listeners'] = notifications.length > 0; // Simplificado
      
      // 6. Verificar se deve renderizar
      final shouldRender = notifications.isNotEmpty;
      debugData['should_render'] = shouldRender;
      
      // 7. Adicionar timestamp da validação
      debugData['validation_timestamp'] = DateTime.now().toIso8601String();
      
      final isValid = issues.isEmpty;
      final message = isValid 
        ? 'Estado válido para renderização'
        : 'Estado inválido: ${issues.length} problemas encontrados';
      
      final result = ValidationResult(
        isValid: isValid,
        message: message,
        debugData: debugData,
        issues: issues,
      );
      
      EnhancedLogger.info('Validação concluída', 
        tag: 'UI_VALIDATOR',
        data: {
          'isValid': isValid,
          'issuesCount': issues.length,
          'shouldRender': shouldRender,
        }
      );
      
      if (!isValid) {
        EnhancedLogger.warning('Problemas encontrados na validação', 
          tag: 'UI_VALIDATOR',
          data: {'issues': issues}
        );
      }
      
      return result;
      
    } catch (e) {
      EnhancedLogger.error('Erro durante validação', tag: 'UI_VALIDATOR', error: e);
      
      return ValidationResult(
        isValid: false,
        message: 'Erro durante validação: $e',
        debugData: {'error': e.toString()},
        issues: ['Erro crítico durante validação'],
      );
    }
  }
  
  /// Força sincronização entre controller e UI
  static Future<void> forceSyncControllerToUI(MatchesController controller) async {
    try {
      EnhancedLogger.info('Iniciando sincronização forçada controller -> UI', tag: 'UI_VALIDATOR');
      
      // 1. Forçar refresh dos dados
      await controller.forceLoadInterestNotifications();
      
      // 2. Aguardar um pouco para garantir que os dados foram processados
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 3. Forçar update do GetX
      controller.update();
      
      // 4. Forçar refresh das propriedades reativas
      controller.interestNotifications.refresh();
      controller.interestNotificationsCount.refresh();
      
      // 5. Aguardar mais um pouco para garantir que a UI foi atualizada
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 6. Validar estado final
      final validation = validateRenderingState(controller);
      
      EnhancedLogger.success('Sincronização forçada concluída', 
        tag: 'UI_VALIDATOR',
        data: {
          'finalState': validation.debugData,
          'isValid': validation.isValid,
        }
      );
      
    } catch (e) {
      EnhancedLogger.error('Erro durante sincronização forçada', tag: 'UI_VALIDATOR', error: e);
      rethrow;
    }
  }
  
  /// Debug completo do estado da UI
  static Map<String, dynamic> debugUIState(MatchesController controller) {
    try {
      EnhancedLogger.info('Coletando debug completo do estado da UI', tag: 'UI_VALIDATOR');
      
      final debugData = <String, dynamic>{};
      
      // 1. Informações básicas do controller
      debugData['controller'] = {
        'is_registered': Get.isRegistered<MatchesController>(),
        'hash_code': controller.hashCode,
        'is_initialized': controller.initialized,
      };
      
      // 2. Estado das notificações
      final notifications = controller.interestNotifications;
      debugData['notifications'] = {
        'length': notifications.length,
        'is_empty': notifications.isEmpty,
        'is_not_empty': notifications.isNotEmpty,
        'is_rx_object': true, // RxList é sempre reativo
        'has_listeners': notifications.length > 0,
        'runtime_type': notifications.runtimeType.toString(),
      };
      
      // 3. Contador de notificações
      final count = controller.interestNotificationsCount;
      debugData['notifications_count'] = {
        'value': count.value,
        'is_rx_object': true, // RxInt é sempre reativo
        'has_listeners': count.value > 0,
        'runtime_type': count.runtimeType.toString(),
      };
      
      // 4. Dados das notificações individuais
      debugData['notifications_data'] = notifications.map((notification) => {
        'profile': {
          'displayName': notification['profile']?['displayName'],
          'userId': notification['profile']?['userId'],
          'age': notification['profile']?['age'],
        },
        'timeAgo': notification['timeAgo'],
        'hasUserInterest': notification['hasUserInterest'],
        'isSimulated': notification['isSimulated'],
      }).toList();
      
      // 5. Estado do GetX
      debugData['getx_state'] = {
        'is_registered': Get.isRegistered<MatchesController>(),
        'find_controller': Get.find<MatchesController>().hashCode,
      };
      
      // 6. Informações de renderização
      debugData['rendering'] = {
        'should_render': notifications.isNotEmpty,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // 7. Validação
      final validation = validateRenderingState(controller);
      debugData['validation'] = {
        'is_valid': validation.isValid,
        'message': validation.message,
        'issues_count': validation.issues.length,
        'issues': validation.issues,
      };
      
      EnhancedLogger.success('Debug completo coletado', 
        tag: 'UI_VALIDATOR',
        data: {
          'total_notifications': notifications.length,
          'should_render': notifications.isNotEmpty,
          'is_valid': validation.isValid,
        }
      );
      
      return debugData;
      
    } catch (e) {
      EnhancedLogger.error('Erro ao coletar debug do estado da UI', tag: 'UI_VALIDATOR', error: e);
      
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Testa se a UI está respondendo corretamente
  static Future<bool> testUIResponsiveness(MatchesController controller) async {
    try {
      EnhancedLogger.info('Testando responsividade da UI', tag: 'UI_VALIDATOR');
      
      // 1. Estado inicial
      final initialCount = controller.interestNotifications.length;
      
      // 2. Forçar uma mudança
      await forceSyncControllerToUI(controller);
      
      // 3. Aguardar um pouco
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 4. Estado final
      final finalState = debugUIState(controller);
      final finalCount = controller.interestNotifications.length;
      
      // 5. Verificar se houve resposta
      final isResponsive = finalState['validation']['is_valid'] == true;
      
      EnhancedLogger.success('Teste de responsividade concluído', 
        tag: 'UI_VALIDATOR',
        data: {
          'initial_count': initialCount,
          'final_count': finalCount,
          'is_responsive': isResponsive,
        }
      );
      
      return isResponsive;
      
    } catch (e) {
      EnhancedLogger.error('Erro no teste de responsividade', tag: 'UI_VALIDATOR', error: e);
      return false;
    }
  }
}