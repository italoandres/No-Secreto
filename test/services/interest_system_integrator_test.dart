import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/services/interest_system_integrator.dart';
import 'package:whatsapp_chat/repositories/interest_notification_repository.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';

// Gerar mocks
@GenerateMocks([
  FirebaseAuth,
  User,
  InterestNotificationRepository,
])
import 'interest_system_integrator_test.mocks.dart';

void main() {
  group('InterestSystemIntegrator', () {
    late InterestSystemIntegrator integrator;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockInterestNotificationRepository mockRepository;

    setUp(() {
      integrator = InterestSystemIntegrator();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockRepository = MockInterestNotificationRepository();
    });

    group('sendInterest', () {
      test('deve enviar interesse com sucesso', () async {
        // Arrange
        const targetUserId = 'target123';
        const targetUserName = 'João';
        const targetUserEmail = 'joao@test.com';
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('user123');
        when(mockUser.displayName).thenReturn('Maria');
        when(mockUser.email).thenReturn('maria@test.com');
        
        when(mockRepository.checkExistingInterest(
          fromUserId: 'user123',
          toUserId: targetUserId,
        )).thenAnswer((_) async => null);
        
        when(mockRepository.createInterestNotification(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await integrator.sendInterest(
          targetUserId: targetUserId,
          targetUserName: targetUserName,
          targetUserEmail: targetUserEmail,
        );

        // Assert
        expect(result, isTrue);
        verify(mockRepository.checkExistingInterest(
          fromUserId: 'user123',
          toUserId: targetUserId,
        )).called(1);
        verify(mockRepository.createInterestNotification(any)).called(1);
      });

      test('deve falhar se usuário não estiver autenticado', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await integrator.sendInterest(
          targetUserId: 'target123',
          targetUserName: 'João',
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockRepository.checkExistingInterest(
          fromUserId: anyNamed('fromUserId'),
          toUserId: anyNamed('toUserId'),
        ));
      });

      test('deve falhar se já existe interesse', () async {
        // Arrange
        const targetUserId = 'target123';
        final existingInterest = InterestNotificationModel(
          id: 'existing123',
          fromUserId: 'user123',
          fromUserName: 'Maria',
          fromUserEmail: 'maria@test.com',
          toUserId: targetUserId,
          toUserName: 'João',
          toUserEmail: 'joao@test.com',
          message: 'Interesse existente',
          timestamp: DateTime.now(),
          isRead: false,
          status: InterestStatus.pending,
        );
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('user123');
        
        when(mockRepository.checkExistingInterest(
          fromUserId: 'user123',
          toUserId: targetUserId,
        )).thenAnswer((_) async => existingInterest);

        // Act
        final result = await integrator.sendInterest(
          targetUserId: targetUserId,
          targetUserName: 'João',
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockRepository.createInterestNotification(any));
      });
    });

    group('respondToInterest', () {
      test('deve responder interesse com sucesso', () async {
        // Arrange
        const notificationId = 'notification123';
        const response = InterestStatus.accepted;
        
        when(mockRepository.updateInterestStatus(notificationId, response))
            .thenAnswer((_) async => {});

        // Act
        final result = await integrator.respondToInterest(
          notificationId: notificationId,
          response: response,
        );

        // Assert
        expect(result, isTrue);
        verify(mockRepository.updateInterestStatus(notificationId, response))
            .called(1);
      });

      test('deve falhar em caso de erro', () async {
        // Arrange
        const notificationId = 'notification123';
        const response = InterestStatus.accepted;
        
        when(mockRepository.updateInterestStatus(notificationId, response))
            .thenThrow(Exception('Erro de rede'));

        // Act
        final result = await integrator.respondToInterest(
          notificationId: notificationId,
          response: response,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('getMyInterestNotifications', () {
      test('deve retornar stream vazio se usuário não autenticado', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final stream = integrator.getMyInterestNotifications();

        // Assert
        expect(stream, emits(isEmpty));
      });

      test('deve retornar stream de notificações', () async {
        // Arrange
        final notifications = [
          InterestNotificationModel(
            id: 'notification1',
            fromUserId: 'user1',
            fromUserName: 'João',
            fromUserEmail: 'joao@test.com',
            toUserId: 'currentUser',
            toUserName: 'Maria',
            toUserEmail: 'maria@test.com',
            message: 'Demonstrou interesse',
            timestamp: DateTime.now(),
            isRead: false,
            status: InterestStatus.pending,
          ),
        ];
        
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('currentUser');
        
        when(mockRepository.getInterestNotificationsStream('currentUser'))
            .thenAnswer((_) => Stream.value(notifications));

        // Act
        final stream = integrator.getMyInterestNotifications();

        // Assert
        expect(stream, emits(notifications));
      });
    });

    group('checkMutualInterest', () {
      test('deve verificar interesse mútuo', () async {
        // Arrange
        const userId1 = 'user1';
        const userId2 = 'user2';
        final interest = InterestNotificationModel(
          id: 'interest123',
          fromUserId: userId1,
          fromUserName: 'João',
          fromUserEmail: 'joao@test.com',
          toUserId: userId2,
          toUserName: 'Maria',
          toUserEmail: 'maria@test.com',
          message: 'Interesse mútuo',
          timestamp: DateTime.now(),
          isRead: false,
          status: InterestStatus.accepted,
        );
        
        when(mockRepository.checkExistingInterest(
          fromUserId: userId1,
          toUserId: userId2,
        )).thenAnswer((_) async => interest);

        // Act
        final result = await integrator.checkMutualInterest(
          userId1: userId1,
          userId2: userId2,
        );

        // Assert
        expect(result, equals(interest));
        verify(mockRepository.checkExistingInterest(
          fromUserId: userId1,
          toUserId: userId2,
        )).called(1);
      });

      test('deve retornar null se não há interesse', () async {
        // Arrange
        const userId1 = 'user1';
        const userId2 = 'user2';
        
        when(mockRepository.checkExistingInterest(
          fromUserId: userId1,
          toUserId: userId2,
        )).thenAnswer((_) async => null);

        // Act
        final result = await integrator.checkMutualInterest(
          userId1: userId1,
          userId2: userId2,
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('getInterestStats', () {
      test('deve retornar estatísticas do usuário', () async {
        // Arrange
        const userId = 'user123';
        const expectedStats = {
          'sent': 5,
          'received': 3,
          'accepted': 2,
        };
        
        when(mockRepository.getInterestsSentCount(userId))
            .thenAnswer((_) async => 5);
        when(mockRepository.getInterestsReceivedCount(userId))
            .thenAnswer((_) async => 3);
        when(mockRepository.getInterestsAcceptedCount(userId))
            .thenAnswer((_) async => 2);

        // Act
        final result = await integrator.getInterestStats(userId);

        // Assert
        expect(result, equals(expectedStats));
        verify(mockRepository.getInterestsSentCount(userId)).called(1);
        verify(mockRepository.getInterestsReceivedCount(userId)).called(1);
        verify(mockRepository.getInterestsAcceptedCount(userId)).called(1);
      });

      test('deve retornar zeros em caso de erro', () async {
        // Arrange
        const userId = 'user123';
        const expectedStats = {
          'sent': 0,
          'received': 0,
          'accepted': 0,
        };
        
        when(mockRepository.getInterestsSentCount(userId))
            .thenThrow(Exception('Erro'));
        when(mockRepository.getInterestsReceivedCount(userId))
            .thenThrow(Exception('Erro'));
        when(mockRepository.getInterestsAcceptedCount(userId))
            .thenThrow(Exception('Erro'));

        // Act
        final result = await integrator.getInterestStats(userId);

        // Assert
        expect(result, equals(expectedStats));
      });
    });
  });
}