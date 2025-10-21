import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/accepted_match_model.dart';

void main() {
  group('AcceptedMatchesRepository', () {
    
    // Testes que não dependem do Firebase
    

    
    group('Model Conversion', () {
      test('deve criar AcceptedMatchModel com dados corretos', () {
        final now = DateTime.now();
        
        final match = AcceptedMatchModel(
          notificationId: 'match1',
          chatId: 'chat1',
          otherUserId: 'user2',
          otherUserName: 'João',
          otherUserPhoto: 'https://example.com/photo.jpg',
          matchDate: now,
          unreadMessages: 2,
          chatExpired: false,
          daysRemaining: 15,
        );
        
        expect(match.notificationId, equals('match1'));
        expect(match.chatId, equals('chat1'));
        expect(match.otherUserId, equals('user2'));
        expect(match.otherUserName, equals('João'));
        expect(match.otherUserPhoto, equals('https://example.com/photo.jpg'));
        expect(match.matchDate, equals(now));
        expect(match.unreadMessages, equals(2));
        expect(match.chatExpired, isFalse);
        expect(match.daysRemaining, equals(15));
      });
      
      test('deve criar AcceptedMatchModel com valores nulos', () {
        final now = DateTime.now();
        
        final match = AcceptedMatchModel(
          notificationId: 'match1',
          chatId: 'chat1',
          otherUserId: 'user2',
          otherUserName: 'João',
          otherUserPhoto: null,
          matchDate: now,
          unreadMessages: 0,
          chatExpired: false,
          daysRemaining: 30,
        );
        
        expect(match.otherUserPhoto, isNull);
        expect(match.unreadMessages, equals(0));
        expect(match.chatExpired, isFalse);
        expect(match.daysRemaining, equals(30));
      });
    });
    
    // Testes de erro serão implementados com mocks em versão futura
    
    group('FirstOrNull Extension', () {
      test('deve retornar primeiro elemento quando existe', () {
        final list = [1, 2, 3];
        expect(list.firstOrNull, equals(1));
      });
      
      test('deve retornar null para lista vazia', () {
        final list = <int>[];
        expect(list.firstOrNull, isNull);
      });
      
      test('deve funcionar com diferentes tipos', () {
        final stringList = ['a', 'b', 'c'];
        expect(stringList.firstOrNull, equals('a'));
        
        final emptyStringList = <String>[];
        expect(emptyStringList.firstOrNull, isNull);
      });
    });
    
    // Testes de integração serão implementados com mocks em versão futura
  });
}