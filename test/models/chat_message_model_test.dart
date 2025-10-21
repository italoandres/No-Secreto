import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    const chatId = 'chat_123';
    const senderId = 'sender_123';
    const senderName = 'João';
    const message = 'Olá, como você está?';
    
    test('should create new message with correct properties', () {
      final chatMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      expect(chatMessage.chatId, equals(chatId));
      expect(chatMessage.senderId, equals(senderId));
      expect(chatMessage.senderName, equals(senderName));
      expect(chatMessage.message, equals(message));
      expect(chatMessage.isRead, isFalse);
      expect(chatMessage.id.startsWith('msg_'), isTrue);
    });
    
    test('should validate message correctly', () {
      final validMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      final emptyMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: '',
      );
      
      final tooLongMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: 'a' * 1001, // Mais que 1000 caracteres
      );
      
      expect(validMessage.isValid, isTrue);
      expect(emptyMessage.isValid, isFalse);
      expect(tooLongMessage.isValid, isFalse);
    });
    
    test('should identify sender correctly', () {
      final chatMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      expect(chatMessage.isSentByUser(senderId), isTrue);
      expect(chatMessage.isSentByUser('other_user'), isFalse);
    });
    
    test('should format message correctly', () {
      final messageWithSpaces = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: '  Mensagem com espaços  ',
      );
      
      expect(messageWithSpaces.formattedMessage, equals('Mensagem com espaços'));
    });
    
    test('should format time correctly', () {
      final now = DateTime.now();
      
      // Mensagem de 2 horas atrás
      final oldMessage = ChatMessageModel(
        id: 'test',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
      );
      
      expect(oldMessage.formattedTime, equals('2h'));
      
      // Mensagem de 3 dias atrás
      final veryOldMessage = ChatMessageModel(
        id: 'test2',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: false,
      );
      
      expect(veryOldMessage.formattedTime, equals('3d'));
    });
    
    test('should mark as read correctly', () {
      final unreadMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      final readMessage = unreadMessage.markAsRead();
      
      expect(unreadMessage.isRead, isFalse);
      expect(readMessage.isRead, isTrue);
      expect(readMessage.id, equals(unreadMessage.id)); // Outros campos iguais
    });
    
    test('should serialize to and from Map correctly', () {
      final originalMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      final map = originalMessage.toMap();
      expect(map['id'], equals(originalMessage.id));
      expect(map['chatId'], equals(chatId));
      expect(map['senderId'], equals(senderId));
      expect(map['senderName'], equals(senderName));
      expect(map['message'], equals(message));
      expect(map['isRead'], isFalse);
    });
    
    test('should create copy with updated fields', () {
      final originalMessage = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      const newMessage = 'Mensagem atualizada';
      final updatedMessage = originalMessage.copyWith(
        message: newMessage,
        isRead: true,
      );
      
      expect(updatedMessage.message, equals(newMessage));
      expect(updatedMessage.isRead, isTrue);
      expect(updatedMessage.id, equals(originalMessage.id)); // Unchanged
    });
    
    test('should generate unique IDs', () {
      final message1 = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: 'Primeira mensagem',
      );
      
      // Pequeno delay para garantir timestamp diferente
      await Future.delayed(const Duration(milliseconds: 1));
      
      final message2 = ChatMessageModel.create(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: 'Segunda mensagem',
      );
      
      expect(message1.id, isNot(equals(message2.id)));
    });
  });
}