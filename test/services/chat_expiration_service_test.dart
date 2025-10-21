import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/chat_expiration_service.dart';

void main() {
  group('ChatExpirationService', () {
    
    group('getDaysRemaining', () {
      test('deve retornar 30 dias para chat recém criado', () {
        final createdAt = DateTime.now();
        final daysRemaining = ChatExpirationService.getDaysRemaining(createdAt);
        
        expect(daysRemaining, equals(30));
      });
      
      test('deve retornar aproximadamente 15 dias para chat de 15 dias atrás', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 15));
        final daysRemaining = ChatExpirationService.getDaysRemaining(createdAt);
        
        expect(daysRemaining, inInclusiveRange(14, 15));
      });
      
      test('deve retornar 0 para chat expirado', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 31));
        final daysRemaining = ChatExpirationService.getDaysRemaining(createdAt);
        
        expect(daysRemaining, equals(0));
      });
      
      test('deve retornar 1 ou 0 para chat que expira em breve', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 29));
        final daysRemaining = ChatExpirationService.getDaysRemaining(createdAt);
        
        expect(daysRemaining, inInclusiveRange(0, 1));
      });
    });
    
    group('isChatExpired', () {
      test('deve retornar false para chat novo', () {
        final createdAt = DateTime.now();
        final isExpired = ChatExpirationService.isChatExpired(createdAt);
        
        expect(isExpired, isFalse);
      });
      
      test('deve retornar true para chat expirado', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 31));
        final isExpired = ChatExpirationService.isChatExpired(createdAt);
        
        expect(isExpired, isTrue);
      });
      
      test('deve retornar true para chat que expirou exatamente há 30 dias', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 30, hours: 1));
        final isExpired = ChatExpirationService.isChatExpired(createdAt);
        
        expect(isExpired, isTrue);
      });
    });
    
    group('getExpirationDate', () {
      test('deve retornar data correta de expiração', () {
        final createdAt = DateTime(2024, 1, 1, 12, 0, 0);
        final expirationDate = ChatExpirationService.getExpirationDate(createdAt);
        
        expect(expirationDate, equals(DateTime(2024, 1, 31, 12, 0, 0)));
      });
    });
    
    group('getTimeRemainingPercentage', () {
      test('deve retornar 100% para chat novo', () {
        final createdAt = DateTime.now();
        final percentage = ChatExpirationService.getTimeRemainingPercentage(createdAt);
        
        expect(percentage, closeTo(100.0, 1.0));
      });
      
      test('deve retornar 50% para chat na metade do tempo', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 15));
        final percentage = ChatExpirationService.getTimeRemainingPercentage(createdAt);
        
        expect(percentage, closeTo(50.0, 5.0));
      });
      
      test('deve retornar 0% para chat expirado', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 31));
        final percentage = ChatExpirationService.getTimeRemainingPercentage(createdAt);
        
        expect(percentage, equals(0.0));
      });
    });
    
    group('getExpirationStatus', () {
      test('deve retornar normal para chat novo', () {
        final createdAt = DateTime.now();
        final status = ChatExpirationService.getExpirationStatus(createdAt);
        
        expect(status, equals(ChatExpirationStatus.normal));
      });
      
      test('deve retornar warning para chat com 5 dias restantes', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 25));
        final status = ChatExpirationService.getExpirationStatus(createdAt);
        
        expect(status, equals(ChatExpirationStatus.warning));
      });
      
      test('deve retornar critical para chat com 2 dias restantes', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 28));
        final status = ChatExpirationService.getExpirationStatus(createdAt);
        
        expect(status, equals(ChatExpirationStatus.critical));
      });
      
      test('deve retornar expired para chat expirado', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 31));
        final status = ChatExpirationService.getExpirationStatus(createdAt);
        
        expect(status, equals(ChatExpirationStatus.expired));
      });
    });
    
    group('canSendMessages', () {
      test('deve permitir envio em chat ativo', () {
        final createdAt = DateTime.now();
        final canSend = ChatExpirationService.canSendMessages(createdAt);
        
        expect(canSend, isTrue);
      });
      
      test('deve bloquear envio em chat expirado', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 31));
        final canSend = ChatExpirationService.canSendMessages(createdAt);
        
        expect(canSend, isFalse);
      });
    });
    
    group('formatTimeRemaining', () {
      test('deve formatar corretamente para chat novo', () {
        final createdAt = DateTime.now();
        final formatted = ChatExpirationService.formatTimeRemaining(createdAt);
        
        expect(formatted, equals('Expira em 30 dias'));
      });
      
      test('deve formatar corretamente para 1 dia restante', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 29));
        final formatted = ChatExpirationService.formatTimeRemaining(createdAt);
        
        expect(formatted, equals('Expira em 1 dia'));
      });
      
      test('deve formatar corretamente para chat expirado', () {
        final createdAt = DateTime.now().subtract(const Duration(days: 31));
        final formatted = ChatExpirationService.formatTimeRemaining(createdAt);
        
        expect(formatted, equals('Chat expirado'));
      });
    });
    
    group('getMotivationalMessage', () {
      test('deve retornar mensagem apropriada para cada status', () {
        // Normal
        final normalCreatedAt = DateTime.now();
        final normalMessage = ChatExpirationService.getMotivationalMessage(normalCreatedAt);
        expect(normalMessage, contains('bastante tempo'));
        
        // Warning
        final warningCreatedAt = DateTime.now().subtract(const Duration(days: 25));
        final warningMessage = ChatExpirationService.getMotivationalMessage(warningCreatedAt);
        expect(warningMessage, contains('tempo está passando'));
        
        // Critical
        final criticalCreatedAt = DateTime.now().subtract(const Duration(days: 28));
        final criticalMessage = ChatExpirationService.getMotivationalMessage(criticalCreatedAt);
        expect(criticalMessage, contains('Últimos dias'));
        
        // Expired
        final expiredCreatedAt = DateTime.now().subtract(const Duration(days: 31));
        final expiredMessage = ChatExpirationService.getMotivationalMessage(expiredCreatedAt);
        expect(expiredMessage, contains('tempo para conversar acabou'));
      });
    });
  });
  
  group('ChatExpirationStatusExtension', () {
    test('deve retornar cores corretas para cada status', () {
      expect(ChatExpirationStatus.normal.colorHex, equals('#4CAF50'));
      expect(ChatExpirationStatus.warning.colorHex, equals('#FF9800'));
      expect(ChatExpirationStatus.critical.colorHex, equals('#F44336'));
      expect(ChatExpirationStatus.expired.colorHex, equals('#9E9E9E'));
    });
    
    test('deve retornar ícones corretos para cada status', () {
      expect(ChatExpirationStatus.normal.iconName, equals('check_circle'));
      expect(ChatExpirationStatus.warning.iconName, equals('warning'));
      expect(ChatExpirationStatus.critical.iconName, equals('error'));
      expect(ChatExpirationStatus.expired.iconName, equals('block'));
    });
    
    test('deve retornar prioridades corretas para cada status', () {
      expect(ChatExpirationStatus.normal.priority, equals(1));
      expect(ChatExpirationStatus.warning.priority, equals(2));
      expect(ChatExpirationStatus.critical.priority, equals(3));
      expect(ChatExpirationStatus.expired.priority, equals(4));
    });
  });
  
  group('Cenários de Edge Cases', () {
    test('deve lidar com data futura corretamente', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final daysRemaining = ChatExpirationService.getDaysRemaining(futureDate);
      
      expect(daysRemaining, equals(30)); // Deve ser limitado ao máximo
    });
    
    test('deve lidar com diferenças de milissegundos', () {
      final createdAt = DateTime.now().subtract(
        const Duration(days: 30, milliseconds: 1),
      );
      final isExpired = ChatExpirationService.isChatExpired(createdAt);
      
      expect(isExpired, isTrue);
    });
    
    test('deve calcular percentual corretamente para valores extremos', () {
      // Chat muito antigo
      final veryOldChat = DateTime.now().subtract(const Duration(days: 100));
      final oldPercentage = ChatExpirationService.getTimeRemainingPercentage(veryOldChat);
      expect(oldPercentage, equals(0.0));
      
      // Chat futuro
      final futureChat = DateTime.now().add(const Duration(days: 10));
      final futurePercentage = ChatExpirationService.getTimeRemainingPercentage(futureChat);
      expect(futurePercentage, equals(100.0));
    });
  });
}