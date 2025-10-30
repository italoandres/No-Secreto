import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchChatService - ID Generation Logic', () {
    // Testes da lógica de geração de IDs sem dependência do Firebase
    
    test('deve gerar ID consistente independente da ordem dos usuários', () {
      final chatId1 = _generateChatId('user1', 'user2');
      final chatId2 = _generateChatId('user2', 'user1');
      
      expect(chatId1, equals(chatId2));
      expect(chatId1, startsWith('match_'));
    });
    
    test('deve gerar IDs diferentes para pares diferentes', () {
      final chatId1 = _generateChatId('user1', 'user2');
      final chatId2 = _generateChatId('user1', 'user3');
      final chatId3 = _generateChatId('user2', 'user3');
      
      expect(chatId1, isNot(equals(chatId2)));
      expect(chatId1, isNot(equals(chatId3)));
      expect(chatId2, isNot(equals(chatId3)));
    });
    
    test('deve gerar ID válido para mesmo usuário', () {
      final chatId = _generateChatId('user1', 'user1');
      
      expect(chatId, equals('match_user1_user1'));
    });
    
    test('deve ordenar IDs alfabeticamente', () {
      final chatId1 = _generateChatId('zebra', 'alpha');
      final chatId2 = _generateChatId('alpha', 'zebra');
      
      expect(chatId1, equals('match_alpha_zebra'));
      expect(chatId2, equals('match_alpha_zebra'));
    });
    
    test('deve lidar com IDs vazios', () {
      final chatId1 = _generateChatId('', 'user2');
      final chatId2 = _generateChatId('user1', '');
      final chatId3 = _generateChatId('', '');
      
      expect(chatId1, startsWith('match_'));
      expect(chatId2, startsWith('match_'));
      expect(chatId3, equals('match__'));
    });
    
    test('deve gerar IDs únicos para diferentes combinações', () {
      final ids = <String>{};
      
      // Gerar vários IDs e verificar unicidade
      for (int i = 0; i < 5; i++) {
        for (int j = i + 1; j < 5; j++) {
          final chatId = _generateChatId('user$i', 'user$j');
          ids.add(chatId);
        }
      }
      
      // Todos os IDs devem ser únicos
      expect(ids.length, equals(10)); // Combinações de 5 usuários tomados 2 a 2
    });
    
    test('deve manter consistência em múltiplas chamadas', () {
      final chatId1 = _generateChatId('alice', 'bob');
      final chatId2 = _generateChatId('bob', 'alice');
      final chatId3 = _generateChatId('alice', 'bob');
      
      expect(chatId1, equals(chatId2));
      expect(chatId2, equals(chatId3));
      expect(chatId1, equals(chatId3));
    });
    
    test('deve funcionar com IDs de usuário complexos', () {
      final complexId1 = 'user_123_abc_xyz';
      final complexId2 = 'user_456_def_uvw';
      
      final chatId = _generateChatId(complexId1, complexId2);
      
      expect(chatId, startsWith('match_'));
      expect(chatId, contains(complexId1));
      expect(chatId, contains(complexId2));
    });
  });
}

/// Função auxiliar que replica a lógica de geração de ID do serviço
String _generateChatId(String userId1, String userId2) {
  final sortedIds = [userId1, userId2]..sort();
  return 'match_${sortedIds[0]}_${sortedIds[1]}';
}