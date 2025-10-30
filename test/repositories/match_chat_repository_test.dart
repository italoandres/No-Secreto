import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/repositories/match_chat_repository.dart';
import '../../lib/models/match_chat_model.dart';
import '../../lib/models/chat_message_model.dart';

// Gerar mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  WriteBatch,
  AggregateQuery,
  AggregateQuerySnapshot,
])
import 'match_chat_repository_test.mocks.dart';

void main() {
  group('MatchChatRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockQuery mockQuery;
    late MockWriteBatch mockBatch;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();
      mockQuery = MockQuery();
      mockBatch = MockWriteBatch();
    });

    group('Chat Operations', () {
      group('createChat', () {
        test('should create chat successfully', () async {
          // Arrange
          final chat = MatchChatModel.create(
            user1Id: 'user1',
            user2Id: 'user2',
          );

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chat.id))
              .thenReturn(mockDocument);
          when(mockDocument.set(any))
              .thenAnswer((_) async => {});

          // Act
          await MatchChatRepository.createChat(chat);

          // Assert
          verify(mockDocument.set(chat.toMap())).called(1);
        });

        test('should throw exception when creation fails', () async {
          // Arrange
          final chat = MatchChatModel.create(
            user1Id: 'user1',
            user2Id: 'user2',
          );

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chat.id))
              .thenReturn(mockDocument);
          when(mockDocument.set(any))
              .thenThrow(Exception('Firebase error'));

          // Act & Assert
          expect(
            () => MatchChatRepository.createChat(chat),
            throwsException,
          );
        });
      });

      group('getChatById', () {
        test('should return chat when it exists', () async {
          // Arrange
          const chatId = 'chat_user1_user2';
          final chatData = MatchChatModel.create(
            user1Id: 'user1',
            user2Id: 'user2',
          );

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chatId))
              .thenReturn(mockDocument);
          when(mockDocument.get())
              .thenAnswer((_) async => mockDocumentSnapshot);
          when(mockDocumentSnapshot.exists).thenReturn(true);
          when(mockDocumentSnapshot.data())
              .thenReturn(chatData.toMap());

          // Act
          final result = await MatchChatRepository.getChatById(chatId);

          // Assert
          expect(result, isNotNull);
          expect(result!.id, equals(chatData.id));
        });

        test('should return null when chat does not exist', () async {
          // Arrange
          const chatId = 'nonexistent_chat';

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chatId))
              .thenReturn(mockDocument);
          when(mockDocument.get())
              .thenAnswer((_) async => mockDocumentSnapshot);
          when(mockDocumentSnapshot.exists).thenReturn(false);

          // Act
          final result = await MatchChatRepository.getChatById(chatId);

          // Assert
          expect(result, isNull);
        });
      });

      group('updateChat', () {
        test('should update chat successfully', () async {
          // Arrange
          final chat = MatchChatModel.create(
            user1Id: 'user1',
            user2Id: 'user2',
          );

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chat.id))
              .thenReturn(mockDocument);
          when(mockDocument.update(any))
              .thenAnswer((_) async => {});

          // Act
          await MatchChatRepository.updateChat(chat);

          // Assert
          verify(mockDocument.update(chat.toMap())).called(1);
        });
      });

      group('updateChatFields', () {
        test('should update specific fields successfully', () async {
          // Arrange
          const chatId = 'chat_user1_user2';
          final fields = {'lastMessage': 'Hello!', 'isExpired': false};

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chatId))
              .thenReturn(mockDocument);
          when(mockDocument.update(any))
              .thenAnswer((_) async => {});

          // Act
          await MatchChatRepository.updateChatFields(chatId, fields);

          // Assert
          verify(mockDocument.update(fields)).called(1);
        });
      });

      group('getUserChats', () {
        test('should return user chats from both queries', () async {
          // Arrange
          const userId = 'user1';
          final chat1 = MatchChatModel.create(user1Id: userId, user2Id: 'user2');
          final chat2 = MatchChatModel.create(user1Id: 'user3', user2Id: userId);

          // Mock para primeira query (user1Id)
          final mockQuery1 = MockQuerySnapshot();
          final mockDoc1 = MockDocumentSnapshot();
          when(mockDoc1.data()).thenReturn(chat1.toMap());

          // Mock para segunda query (user2Id)
          final mockQuery2 = MockQuerySnapshot();
          final mockDoc2 = MockDocumentSnapshot();
          when(mockDoc2.data()).thenReturn(chat2.toMap());

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.where('user1Id', isEqualTo: userId))
              .thenReturn(mockQuery);
          when(mockCollection.where('user2Id', isEqualTo: userId))
              .thenReturn(mockQuery);
          when(mockQuery.get())
              .thenAnswer((_) async => mockQuery1)
              .thenAnswer((_) async => mockQuery2);

          when(mockQuery1.docs).thenReturn([mockDoc1]);
          when(mockQuery2.docs).thenReturn([mockDoc2]);

          // Act
          final result = await MatchChatRepository.getUserChats(userId);

          // Assert
          expect(result.length, equals(2));
        });
      });
    });

    group('Message Operations', () {
      group('sendMessage', () {
        test('should send valid message successfully', () async {
          // Arrange
          final message = ChatMessageModel.create(
            chatId: 'chat_user1_user2',
            senderId: 'user1',
            senderName: 'User 1',
            message: 'Hello!',
          );

          // Mock para salvar mensagem
          when(mockFirestore.collection('chat_messages'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(message.id))
              .thenReturn(mockDocument);
          when(mockDocument.set(any))
              .thenAnswer((_) async => {});

          // Mock para atualizar chat
          final mockChatCollection = MockCollectionReference();
          final mockChatDocument = MockDocumentReference();
          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockChatCollection);
          when(mockChatCollection.doc(message.chatId))
              .thenReturn(mockChatDocument);
          when(mockChatDocument.update(any))
              .thenAnswer((_) async => {});

          // Mock para buscar chat (para incrementar contador)
          final mockChatSnapshot = MockDocumentSnapshot();
          final chatData = MatchChatModel.create(
            user1Id: 'user1',
            user2Id: 'user2',
          );
          when(mockChatDocument.get())
              .thenAnswer((_) async => mockChatSnapshot);
          when(mockChatSnapshot.exists).thenReturn(true);
          when(mockChatSnapshot.data()).thenReturn(chatData.toMap());

          // Act
          await MatchChatRepository.sendMessage(message);

          // Assert
          verify(mockDocument.set(message.toMap())).called(1);
        });

        test('should throw exception for invalid message', () async {
          // Arrange
          final invalidMessage = ChatMessageModel(
            id: 'test',
            chatId: '',
            senderId: '',
            senderName: '',
            message: '',
            timestamp: DateTime.now(),
            isRead: false,
          );

          // Act & Assert
          expect(
            () => MatchChatRepository.sendMessage(invalidMessage),
            throwsException,
          );
        });
      });

      group('getChatMessages', () {
        test('should return messages for chat', () async {
          // Arrange
          const chatId = 'chat_user1_user2';
          final message = ChatMessageModel.create(
            chatId: chatId,
            senderId: 'user1',
            senderName: 'User 1',
            message: 'Hello!',
          );

          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.data()).thenReturn(message.toMap());

          when(mockFirestore.collection('chat_messages'))
              .thenReturn(mockCollection);
          when(mockCollection.where('chatId', isEqualTo: chatId))
              .thenReturn(mockQuery);
          when(mockQuery.orderBy('timestamp', descending: true))
              .thenReturn(mockQuery);
          when(mockQuery.limit(50))
              .thenReturn(mockQuery);
          when(mockQuery.get())
              .thenAnswer((_) async => mockQuerySnapshot);
          when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

          // Act
          final result = await MatchChatRepository.getChatMessages(chatId);

          // Assert
          expect(result.length, equals(1));
          expect(result.first.id, equals(message.id));
        });
      });

      group('markMessagesAsRead', () {
        test('should mark unread messages as read', () async {
          // Arrange
          const chatId = 'chat_user1_user2';
          const userId = 'user1';

          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.reference).thenReturn(mockDocument);

          when(mockFirestore.collection('chat_messages'))
              .thenReturn(mockCollection);
          when(mockCollection.where('chatId', isEqualTo: chatId))
              .thenReturn(mockQuery);
          when(mockQuery.where('isRead', isEqualTo: false))
              .thenReturn(mockQuery);
          when(mockQuery.where('senderId', isNotEqualTo: userId))
              .thenReturn(mockQuery);
          when(mockQuery.get())
              .thenAnswer((_) async => mockQuerySnapshot);
          when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

          when(mockFirestore.batch()).thenReturn(mockBatch);
          when(mockBatch.update(any, any)).thenReturn(mockBatch);
          when(mockBatch.commit()).thenAnswer((_) async => []);

          // Mock para atualizar contador do chat
          final mockChatCollection = MockCollectionReference();
          final mockChatDocument = MockDocumentReference();
          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockChatCollection);
          when(mockChatCollection.doc(chatId))
              .thenReturn(mockChatDocument);
          when(mockChatDocument.update(any))
              .thenAnswer((_) async => {});

          // Act
          await MatchChatRepository.markMessagesAsRead(chatId, userId);

          // Assert
          verify(mockBatch.commit()).called(1);
        });
      });
    });

    group('Statistics', () {
      group('getChatStats', () {
        test('should return stats for existing chat', () async {
          // Arrange
          const chatId = 'chat_user1_user2';
          final chatData = MatchChatModel.create(
            user1Id: 'user1',
            user2Id: 'user2',
          );

          // Mock para buscar chat
          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chatId))
              .thenReturn(mockDocument);
          when(mockDocument.get())
              .thenAnswer((_) async => mockDocumentSnapshot);
          when(mockDocumentSnapshot.exists).thenReturn(true);
          when(mockDocumentSnapshot.data()).thenReturn(chatData.toMap());

          // Mock para contar mensagens
          final mockAggregateQuery = MockAggregateQuery();
          final mockAggregateSnapshot = MockAggregateQuerySnapshot();
          when(mockFirestore.collection('chat_messages'))
              .thenReturn(mockCollection);
          when(mockCollection.where('chatId', isEqualTo: chatId))
              .thenReturn(mockQuery);
          when(mockQuery.count()).thenReturn(mockAggregateQuery);
          when(mockAggregateQuery.get())
              .thenAnswer((_) async => mockAggregateSnapshot);
          when(mockAggregateSnapshot.count).thenReturn(10);

          // Act
          final result = await MatchChatRepository.getChatStats(chatId);

          // Assert
          expect(result['exists'], isTrue);
          expect(result['totalMessages'], equals(10));
        });

        test('should return not found stats for nonexistent chat', () async {
          // Arrange
          const chatId = 'nonexistent_chat';

          when(mockFirestore.collection('match_chats'))
              .thenReturn(mockCollection);
          when(mockCollection.doc(chatId))
              .thenReturn(mockDocument);
          when(mockDocument.get())
              .thenAnswer((_) async => mockDocumentSnapshot);
          when(mockDocumentSnapshot.exists).thenReturn(false);

          // Act
          final result = await MatchChatRepository.getChatStats(chatId);

          // Assert
          expect(result['exists'], isFalse);
          expect(result['totalMessages'], equals(0));
        });
      });
    });

    group('Cleanup Operations', () {
      group('cleanupOldMessages', () {
        test('should remove old messages successfully', () async {
          // Arrange
          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.reference).thenReturn(mockDocument);

          when(mockFirestore.collection('chat_messages'))
              .thenReturn(mockCollection);
          when(mockCollection.where('timestamp', isLessThan: any))
              .thenReturn(mockQuery);
          when(mockQuery.limit(100))
              .thenReturn(mockQuery);
          when(mockQuery.get())
              .thenAnswer((_) async => mockQuerySnapshot);
          when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

          when(mockFirestore.batch()).thenReturn(mockBatch);
          when(mockBatch.delete(any)).thenReturn(mockBatch);
          when(mockBatch.commit()).thenAnswer((_) async => []);

          // Act
          await MatchChatRepository.cleanupOldMessages();

          // Assert
          verify(mockBatch.commit()).called(1);
        });
      });
    });
  });
}