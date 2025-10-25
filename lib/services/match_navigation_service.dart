import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/accepted_match_model.dart';
import '../utils/enhanced_logger.dart';

/// Serviço de navegação para o sistema de matches aceitos
class MatchNavigationService {
  static final MatchNavigationService _instance =
      MatchNavigationService._internal();
  factory MatchNavigationService() => _instance;
  MatchNavigationService._internal();

  /// Navegar para a lista de matches aceitos
  ///
  /// Esta função abre a tela principal onde o usuário pode ver
  /// todos os seus matches aceitos e iniciar conversas
  static Future<void> navigateToAcceptedMatches() async {
    try {
      EnhancedLogger.info('🧭 Navegando para matches aceitos',
          tag: 'MATCH_NAVIGATION');

      await Get.toNamed('/accepted-matches');

      EnhancedLogger.info('✅ Navegação para matches aceitos concluída',
          tag: 'MATCH_NAVIGATION');
    } catch (e) {
      EnhancedLogger.error('Erro ao navegar para matches aceitos: $e',
          tag: 'MATCH_NAVIGATION');

      _showNavigationError('Erro ao abrir matches aceitos');
    }
  }

  /// Navegar para um chat específico
  ///
  /// [chatId] - ID único do chat
  /// [otherUserId] - ID do outro usuário
  /// [otherUserName] - Nome do outro usuário
  /// [otherUserPhoto] - URL da foto do outro usuário (opcional)
  /// [matchDate] - Data do match para calcular expiração
  static Future<void> navigateToMatchChat({
    required String chatId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    required DateTime matchDate,
  }) async {
    try {
      EnhancedLogger.info('🧭 Navegando para chat',
          tag: 'MATCH_NAVIGATION',
          data: {
            'chatId': chatId,
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
          });

      await Get.toNamed('/match-chat', arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserPhoto': otherUserPhoto,
        'matchDate': matchDate,
      });

      EnhancedLogger.info('✅ Navegação para chat concluída',
          tag: 'MATCH_NAVIGATION', data: {'chatId': chatId});
    } catch (e) {
      EnhancedLogger.error('Erro ao navegar para chat: $e',
          tag: 'MATCH_NAVIGATION');

      _showNavigationError('Erro ao abrir chat');
    }
  }

  /// Navegar para chat a partir de um AcceptedMatchModel
  ///
  /// [match] - Modelo do match aceito
  static Future<void> navigateToMatchChatFromModel(
      AcceptedMatchModel match) async {
    await navigateToMatchChat(
      chatId: match.chatId,
      otherUserId: match.otherUserId,
      otherUserName: match.otherUserName,
      otherUserPhoto: match.otherUserPhoto,
      matchDate: match.matchDate,
    );
  }

  /// Voltar para a tela anterior
  ///
  /// Função auxiliar para voltar na navegação com animação
  static void goBack() {
    try {
      EnhancedLogger.info('🧭 Voltando para tela anterior',
          tag: 'MATCH_NAVIGATION');

      Get.back();
    } catch (e) {
      EnhancedLogger.error('Erro ao voltar: $e', tag: 'MATCH_NAVIGATION');
    }
  }

  /// Navegar para o dashboard de interesse (fallback)
  ///
  /// Usado como fallback quando há problemas com matches aceitos
  static Future<void> navigateToInterestDashboard() async {
    try {
      EnhancedLogger.info('🧭 Navegando para dashboard de interesse',
          tag: 'MATCH_NAVIGATION');

      await Get.toNamed('/interest-dashboard');
    } catch (e) {
      EnhancedLogger.error('Erro ao navegar para dashboard: $e',
          tag: 'MATCH_NAVIGATION');

      _showNavigationError('Erro ao abrir dashboard');
    }
  }

  /// Navegar para perfil de usuário
  ///
  /// [userId] - ID do usuário para visualizar o perfil
  static Future<void> navigateToProfile(String userId) async {
    try {
      EnhancedLogger.info('🧭 Navegando para perfil',
          tag: 'MATCH_NAVIGATION', data: {'userId': userId});

      await Get.toNamed('/profile-display', arguments: {
        'profileId': userId,
      });
    } catch (e) {
      EnhancedLogger.error('Erro ao navegar para perfil: $e',
          tag: 'MATCH_NAVIGATION');

      _showNavigationError('Erro ao abrir perfil');
    }
  }

  /// Verificar se pode navegar (se há rotas na pilha)
  static bool canGoBack() {
    return Get.routing.previous.isNotEmpty;
  }

  /// Obter rota atual
  static String getCurrentRoute() {
    return Get.currentRoute;
  }

  /// Limpar pilha de navegação e ir para rota específica
  ///
  /// [routeName] - Nome da rota de destino
  static Future<void> navigateAndClearStack(String routeName) async {
    try {
      EnhancedLogger.info('🧭 Navegando e limpando pilha',
          tag: 'MATCH_NAVIGATION', data: {'routeName': routeName});

      await Get.offAllNamed(routeName);
    } catch (e) {
      EnhancedLogger.error('Erro ao navegar e limpar pilha: $e',
          tag: 'MATCH_NAVIGATION');
    }
  }

  /// Navegar com animação personalizada
  ///
  /// [page] - Widget da página de destino
  /// [transition] - Tipo de transição
  /// [duration] - Duração da animação
  static Future<void> navigateWithCustomTransition({
    required Widget page,
    Transition transition = Transition.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    try {
      EnhancedLogger.info('🧭 Navegando com transição personalizada',
          tag: 'MATCH_NAVIGATION');

      await Get.to(
        () => page,
        transition: transition,
        duration: duration,
      );
    } catch (e) {
      EnhancedLogger.error('Erro na navegação personalizada: $e',
          tag: 'MATCH_NAVIGATION');
    }
  }

  /// Mostrar diálogo de confirmação antes de navegar
  ///
  /// [title] - Título do diálogo
  /// [message] - Mensagem do diálogo
  /// [onConfirm] - Função a executar se confirmado
  static Future<void> showNavigationConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    try {
      await Get.dialog(
        AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                onConfirm();
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } catch (e) {
      EnhancedLogger.error('Erro ao mostrar diálogo de confirmação: $e',
          tag: 'MATCH_NAVIGATION');
    }
  }

  /// Mostrar erro de navegação para o usuário
  static void _showNavigationError(String message) {
    try {
      Get.snackbar(
        'Erro de Navegação',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } catch (e) {
      EnhancedLogger.error('Erro ao mostrar snackbar de erro: $e',
          tag: 'MATCH_NAVIGATION');
    }
  }

  /// Obter estatísticas de navegação
  static Map<String, dynamic> getNavigationStats() {
    try {
      return {
        'currentRoute': getCurrentRoute(),
        'canGoBack': canGoBack(),
        'routeStackSize': Get.routing.previous.length,
        'lastRoute':
            Get.routing.previous.isNotEmpty ? Get.routing.previous : null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      EnhancedLogger.error('Erro ao obter estatísticas de navegação: $e',
          tag: 'MATCH_NAVIGATION');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Registrar listener de mudanças de rota
  static void registerRouteObserver() {
    try {
      // GetX já tem observadores internos, mas podemos adicionar logs
      EnhancedLogger.info('🧭 Observador de rotas registrado',
          tag: 'MATCH_NAVIGATION');
    } catch (e) {
      EnhancedLogger.error('Erro ao registrar observador de rotas: $e',
          tag: 'MATCH_NAVIGATION');
    }
  }
}
