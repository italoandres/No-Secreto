import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_chat/services/interest_cache_service.dart';
import 'package:whatsapp_chat/models/interest_notification_model.dart';

// Gerar mocks
@GenerateMocks([SharedPreferences])
import 'interest_cache_service_test.mocks.dart';

void main() {
  group('InterestCacheService', () {
    late InterestCacheService cacheService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      cacheService = InterestCacheService();
      mockPrefs = MockSharedPreferences();
    });

    group('cacheNotifications', () {
      test('deve salvar notificações no cache', () async {
        // Arrange
        final notifications = [
          InterestNotificationModel(
            id: 'notification1',
            fromUserId: 'user1',
            fromUserName: 'João',
            fromUserEmail: 'joao@test.com',
            toUserId: 'user2',
            toUserName: 'Maria',
            toUserEmail: 'maria@test.com',
            message: 'Demonstrou interesse',
            timestamp: DateTime.now(),
            isRead: false,
            status: InterestStatus.pending,
          ),
        ];

        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

        // Act
        await cacheService.cacheNotifications(notifications);

        // Assert
        verify(mockPrefs.setString('interest_notifications', any)).called(1);
        verify(mockPrefs.setInt('last_sync_timestamp', any)).called(1);
      });
    });

    group('getCachedNotifications', () {
      test('deve retornar lista vazia se não há cache', () async {
        // Arrange
        when(mockPrefs.getString('interest_notifications')).thenReturn(null);

        // Act
        final result = await cacheService.getCachedNotifications();

        // Assert
        expect(result, isEmpty);
      });

      test('deve retornar notificações do cache', () async {
        // Arrange
        final notificationJson = '''
        [
          {
            "id": "notification1",
            "fromUserId": "user1",
            "fromUserName": "João",
            "fromUserEmail": "joao@test.com",
            "toUserId": "user2",
            "toUserName": "Maria",
            "toUserEmail": "maria@test.com",
            "message": "Demonstrou interesse",
            "timestamp": "2024-01-01T10:00:00.000Z",
            "isRead": false,
            "status": "pending"
          }
        ]
        ''';

        when(mockPrefs.getString('interest_notifications'))
            .thenReturn(notificationJson);

        // Act
        final result = await cacheService.getCachedNotifications();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('notification1'));
        expect(result.first.fromUserName, equals('João'));
      });

      test('deve retornar lista vazia em caso de erro', () async {
        // Arrange
        when(mockPrefs.getString('interest_notifications'))
            .thenReturn('json_inválido');

        // Act
        final result = await cacheService.getCachedNotifications();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('cacheSentInterest', () {
      test('deve salvar interesse enviado no cache', () async {
        // Arrange
        final interest = InterestNotificationModel(
          id: 'interest1',
          fromUserId: 'user1',
          fromUserName: 'João',
          fromUserEmail: 'joao@test.com',
          toUserId: 'user2',
          toUserName: 'Maria',
          toUserEmail: 'maria@test.com',
          message: 'Demonstrou interesse',
          timestamp: DateTime.now(),
          isRead: false,
          status: InterestStatus.pending,
        );

        when(mockPrefs.getString('sent_interests')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await cacheService.cacheSentInterest(interest);

        // Assert
        verify(mockPrefs.setString('sent_interests', any)).called(1);
      });

      test('deve adicionar a interesses existentes', () async {
        // Arrange
        final existingJson = '''
        [
          {
            "id": "existing1",
            "fromUserId": "user1",
            "fromUserName": "João",
            "fromUserEmail": "joao@test.com",
            "toUserId": "user3",
            "toUserName": "Ana",
            "toUserEmail": "ana@test.com",
            "message": "Interesse anterior",
            "timestamp": "2024-01-01T09:00:00.000Z",
            "isRead": false,
            "status": "pending"
          }
        ]
        ''';

        final newInterest = InterestNotificationModel(
          id: 'interest2',
          fromUserId: 'user1',
          fromUserName: 'João',
          fromUserEmail: 'joao@test.com',
          toUserId: 'user2',
          toUserName: 'Maria',
          toUserEmail: 'maria@test.com',
          message: 'Novo interesse',
          timestamp: DateTime.now(),
          isRead: false,
          status: InterestStatus.pending,
        );

        when(mockPrefs.getString('sent_interests')).thenReturn(existingJson);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        await cacheService.cacheSentInterest(newInterest);

        // Assert
        verify(mockPrefs.setString('sent_interests', any)).called(1);
      });
    });

    group('hasSentInterestCached', () {
      test('deve retornar false se não há cache', () async {
        // Arrange
        when(mockPrefs.getString('sent_interests')).thenReturn(null);

        // Act
        final result = await cacheService.hasSentInterestCached('user2');

        // Assert
        expect(result, isFalse);
      });

      test('deve retornar true se interesse existe no cache', () async {
        // Arrange
        final sentInterestsJson = '''
        [
          {
            "id": "interest1",
            "fromUserId": "user1",
            "fromUserName": "João",
            "fromUserEmail": "joao@test.com",
            "toUserId": "user2",
            "toUserName": "Maria",
            "toUserEmail": "maria@test.com",
            "message": "Demonstrou interesse",
            "timestamp": "2024-01-01T10:00:00.000Z",
            "isRead": false,
            "status": "pending"
          }
        ]
        ''';

        when(mockPrefs.getString('sent_interests'))
            .thenReturn(sentInterestsJson);

        // Act
        final result = await cacheService.hasSentInterestCached('user2');

        // Assert
        expect(result, isTrue);
      });

      test('deve retornar false se interesse não existe no cache', () async {
        // Arrange
        final sentInterestsJson = '''
        [
          {
            "id": "interest1",
            "fromUserId": "user1",
            "fromUserName": "João",
            "fromUserEmail": "joao@test.com",
            "toUserId": "user3",
            "toUserName": "Ana",
            "toUserEmail": "ana@test.com",
            "message": "Demonstrou interesse",
            "timestamp": "2024-01-01T10:00:00.000Z",
            "isRead": false,
            "status": "pending"
          }
        ]
        ''';

        when(mockPrefs.getString('sent_interests'))
            .thenReturn(sentInterestsJson);

        // Act
        final result = await cacheService.hasSentInterestCached('user2');

        // Assert
        expect(result, isFalse);
      });
    });

    group('isCacheStale', () {
      test('deve retornar true se nunca sincronizou', () async {
        // Arrange
        when(mockPrefs.getInt('last_sync_timestamp')).thenReturn(null);

        // Act
        final result = await cacheService.isCacheStale();

        // Assert
        expect(result, isTrue);
      });

      test('deve retornar true se cache está desatualizado', () async {
        // Arrange
        final oldTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch;
        
        when(mockPrefs.getInt('last_sync_timestamp')).thenReturn(oldTimestamp);

        // Act
        final result = await cacheService.isCacheStale(
          maxAge: const Duration(minutes: 5),
        );

        // Assert
        expect(result, isTrue);
      });

      test('deve retornar false se cache está atualizado', () async {
        // Arrange
        final recentTimestamp = DateTime.now()
            .subtract(const Duration(minutes: 2))
            .millisecondsSinceEpoch;
        
        when(mockPrefs.getInt('last_sync_timestamp')).thenReturn(recentTimestamp);

        // Act
        final result = await cacheService.isCacheStale(
          maxAge: const Duration(minutes: 5),
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('clearAllCache', () {
      test('deve limpar todo o cache', () async {
        // Arrange
        when(mockPrefs.getKeys()).thenReturn({
          'interest_notifications',
          'sent_interests',
          'last_sync_timestamp',
          'user_stats_user123',
          'other_key',
        });
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Act
        await cacheService.clearAllCache();

        // Assert
        verify(mockPrefs.remove('interest_notifications')).called(1);
        verify(mockPrefs.remove('sent_interests')).called(1);
        verify(mockPrefs.remove('last_sync_timestamp')).called(1);
        verify(mockPrefs.remove('user_stats_user123')).called(1);
        verifyNever(mockPrefs.remove('other_key'));
      });
    });

    group('getCacheInfo', () {
      test('deve retornar informações do cache', () async {
        // Arrange
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        const notificationsJson = '[{"id": "1"}, {"id": "2"}]';
        const sentInterestsJson = '[{"id": "3"}]';

        when(mockPrefs.getInt('last_sync_timestamp')).thenReturn(timestamp);
        when(mockPrefs.getString('interest_notifications'))
            .thenReturn(notificationsJson);
        when(mockPrefs.getString('sent_interests'))
            .thenReturn(sentInterestsJson);

        // Act
        final result = await cacheService.getCacheInfo();

        // Assert
        expect(result['notificationsCount'], equals(2));
        expect(result['sentInterestsCount'], equals(1));
        expect(result['lastSync'], isNotNull);
        expect(result['isStale'], isA<bool>());
      });
    });
  });
}