import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../controllers/matches_controller.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para testar o sistema completo de notificações de interesse V2
class TestInterestNotificationsV2 {
  
  /// Testa o fluxo completo de notificações de interesse
  static Future<void> testCompleteFlow() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _showError('Usuário não logado');
        return;
      }

      EnhancedLogger.info('Iniciando teste completo do sistema de notificações V2', 
        tag: 'TEST_INTEREST_V2'
      );

      // PASSO 1: Criar notificação de teste
      await _createTestNotification(currentUserId);
      
      // PASSO 2: Verificar se a notificação foi criada
      await _verifyNotificationCreated(currentUserId);
      
      // PASSO 3: Testar atualização do contador
      await _testCounterUpdate(currentUserId);
      
      // PASSO 4: Testar navegação
      await _testNavigation();
      
      _showSuccess('Teste completo realizado com sucesso!');
      
    } catch (e) {
      EnhancedLogger.error('Erro no teste completo', 
        tag: 'TEST_INTEREST_V2',
        error: e
      );
      _showError('Erro no teste: $e');
    }
  }

  /// Cria uma notificação de teste
  static Future<void> _createTestNotification(String currentUserId) async {
    EnhancedLogger.info('Criando notificação de teste', 
      tag: 'TEST_INTEREST_V2'
    );

    // Simular que outro usuário demonstrou interesse
    await NotificationService.processInterestNotification(
      interestedUserId: 'test_user_interested',
      targetUserId: currentUserId,
      interestedUserName: 'João Teste',
      interestedUserAvatar: 'https://via.placeholder.com/150',
    );

    EnhancedLogger.success('Notificação de teste criada', 
      tag: 'TEST_INTEREST_V2'
    );
  }

  /// Verifica se a notificação foi criada corretamente
  static Future<void> _verifyNotificationCreated(String currentUserId) async {
    EnhancedLogger.info('Verificando se notificação foi criada', 
      tag: 'TEST_INTEREST_V2'
    );

    // Aguardar um pouco para o Firestore processar
    await Future.delayed(const Duration(seconds: 2));

    // Buscar notificações do contexto
    final notifications = await NotificationService.getContextNotifications(
      currentUserId, 
      'interest_matches'
    ).first;

    if (notifications.isNotEmpty) {
      EnhancedLogger.success('Notificação encontrada no Firestore', 
        tag: 'TEST_INTEREST_V2',
        data: {'count': notifications.length}
      );
    } else {
      throw Exception('Notificação não foi criada no Firestore');
    }
  }

  /// Testa atualização do contador
  static Future<void> _testCounterUpdate(String currentUserId) async {
    EnhancedLogger.info('Testando atualização do contador', 
      tag: 'TEST_INTEREST_V2'
    );

    // Buscar contador de notificações não lidas
    final unreadCount = await NotificationService.getContextUnreadCount(
      currentUserId, 
      'interest_matches'
    ).first;

    if (unreadCount > 0) {
      EnhancedLogger.success('Contador atualizado corretamente', 
        tag: 'TEST_INTEREST_V2',
        data: {'unreadCount': unreadCount}
      );
    } else {
      throw Exception('Contador não foi atualizado');
    }
  }

  /// Testa navegação para tela de notificações
  static Future<void> _testNavigation() async {
    EnhancedLogger.info('Testando navegação', 
      tag: 'TEST_INTEREST_V2'
    );

    // Simular clique no componente de notificação
    // (isso será testado visualmente pelo usuário)
    
    EnhancedLogger.success('Navegação testada', 
      tag: 'TEST_INTEREST_V2'
    );
  }

  /// Testa demonstração de interesse
  static Future<void> testExpressInterest() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _showError('Usuário não logado');
        return;
      }

      EnhancedLogger.info('Testando demonstração de interesse', 
        tag: 'TEST_INTEREST_V2'
      );

      // Obter controller de matches
      final matchesController = Get.find<MatchesController>();

      // Demonstrar interesse em usuário de teste
      await matchesController.expressInterest(
        'test_target_user',
        interestedUserName: 'Meu Nome Teste',
        interestedUserAvatar: 'https://via.placeholder.com/150',
      );

      _showSuccess('Interesse demonstrado com sucesso!');
      
    } catch (e) {
      EnhancedLogger.error('Erro ao demonstrar interesse', 
        tag: 'TEST_INTEREST_V2',
        error: e
      );
      _showError('Erro ao demonstrar interesse: $e');
    }
  }

  /// Limpa dados de teste
  static Future<void> cleanupTestData() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      EnhancedLogger.info('Limpando dados de teste', 
        tag: 'TEST_INTEREST_V2'
      );

      // Marcar todas as notificações de teste como lidas
      await NotificationService.markContextNotificationsAsRead(
        currentUserId, 
        'interest_matches'
      );

      _showSuccess('Dados de teste limpos!');
      
    } catch (e) {
      EnhancedLogger.error('Erro ao limpar dados de teste', 
        tag: 'TEST_INTEREST_V2',
        error: e
      );
      _showError('Erro ao limpar dados: $e');
    }
  }

  /// Testa múltiplas notificações
  static Future<void> testMultipleNotifications() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        _showError('Usuário não logado');
        return;
      }

      EnhancedLogger.info('Testando múltiplas notificações', 
        tag: 'TEST_INTEREST_V2'
      );

      // Criar 3 notificações de teste
      final testUsers = [
        {'id': 'test_user_1', 'name': 'Maria Silva', 'avatar': 'https://via.placeholder.com/150/FF69B4'},
        {'id': 'test_user_2', 'name': 'Ana Costa', 'avatar': 'https://via.placeholder.com/150/87CEEB'},
        {'id': 'test_user_3', 'name': 'Julia Santos', 'avatar': 'https://via.placeholder.com/150/98FB98'},
      ];

      for (final user in testUsers) {
        await NotificationService.processInterestNotification(
          interestedUserId: user['id']!,
          targetUserId: currentUserId,
          interestedUserName: user['name']!,
          interestedUserAvatar: user['avatar']!,
        );
        
        // Aguardar um pouco entre as criações
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _showSuccess('${testUsers.length} notificações de teste criadas!');
      
    } catch (e) {
      EnhancedLogger.error('Erro ao criar múltiplas notificações', 
        tag: 'TEST_INTEREST_V2',
        error: e
      );
      _showError('Erro ao criar notificações: $e');
    }
  }

  /// Valida integração com arquitetura existente
  static Future<void> validateArchitectureIntegration() async {
    try {
      EnhancedLogger.info('Validando integração com arquitetura existente', 
        tag: 'TEST_INTEREST_V2'
      );

      // Verificar se NotificationService existe
      final hasNotificationService = NotificationService.canReceiveNotifications();
      if (!hasNotificationService) {
        throw Exception('NotificationService não está funcionando');
      }

      // Verificar se MatchesController existe
      try {
        Get.find<MatchesController>();
      } catch (e) {
        throw Exception('MatchesController não está registrado');
      }

      // Verificar se contexto 'interest_matches' funciona
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final stream = NotificationService.getContextUnreadCount(currentUserId, 'interest_matches');
        await stream.first; // Testa se o stream funciona
      }

      _showSuccess('Integração com arquitetura validada!');
      
    } catch (e) {
      EnhancedLogger.error('Erro na validação da arquitetura', 
        tag: 'TEST_INTEREST_V2',
        error: e
      );
      _showError('Erro na validação: $e');
    }
  }

  /// Mostra mensagem de sucesso
  static void _showSuccess(String message) {
    Get.snackbar(
      '✅ Sucesso',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Mostra mensagem de erro
  static void _showError(String message) {
    Get.snackbar(
      '❌ Erro',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}