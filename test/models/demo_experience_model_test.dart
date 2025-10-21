import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/models/demo_experience_model.dart';

void main() {
  group('DemoExperienceModel Tests', () {
    group('Constructor', () {
      test('deve criar instância com valores padrão', () {
        // Arrange & Act
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
        );
        
        // Assert
        expect(experience.userId, 'test-user-123');
        expect(experience.startedAt, isA<DateTime>());
        expect(experience.hasViewedVitrine, false);
        expect(experience.hasSharedVitrine, false);
        expect(experience.viewCount, 0);
        expect(experience.shareCount, 0);
        expect(experience.completedAt, isNull);
        expect(experience.lastInteractionAt, isNull);
        expect(experience.shareTypes, isEmpty);
        expect(experience.totalTimeSpent, 0);
      });
      
      test('deve criar instância com todos os valores', () {
        // Arrange
        final startedAt = DateTime.now();
        final completedAt = startedAt.add(Duration(minutes: 5));
        final lastInteractionAt = startedAt.add(Duration(minutes: 3));
        final shareTypes = ['whatsapp', 'instagram'];
        
        // Act
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: startedAt,
          hasViewedVitrine: true,
          hasSharedVitrine: true,
          viewCount: 3,
          shareCount: 2,
          completedAt: completedAt,
          lastInteractionAt: lastInteractionAt,
          shareTypes: shareTypes,
          totalTimeSpent: 300,
        );
        
        // Assert
        expect(experience.userId, 'test-user-123');
        expect(experience.startedAt, startedAt);
        expect(experience.hasViewedVitrine, true);
        expect(experience.hasSharedVitrine, true);
        expect(experience.viewCount, 3);
        expect(experience.shareCount, 2);
        expect(experience.completedAt, completedAt);
        expect(experience.lastInteractionAt, lastInteractionAt);
        expect(experience.shareTypes, shareTypes);
        expect(experience.totalTimeSpent, 300);
      });
    });
    
    group('toFirestore', () {
      test('deve converter para Map corretamente', () {
        // Arrange
        final startedAt = DateTime.now();
        final completedAt = startedAt.add(Duration(minutes: 5));
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: startedAt,
          hasViewedVitrine: true,
          viewCount: 2,
          shareCount: 1,
          completedAt: completedAt,
          shareTypes: ['whatsapp'],
          totalTimeSpent: 300,
        );
        
        // Act
        final result = experience.toFirestore();
        
        // Assert
        expect(result['userId'], 'test-user-123');
        expect(result['startedAt'], isA<Timestamp>());
        expect(result['hasViewedVitrine'], true);
        expect(result['hasSharedVitrine'], false);
        expect(result['viewCount'], 2);
        expect(result['shareCount'], 1);
        expect(result['completedAt'], isA<Timestamp>());
        expect(result['lastInteractionAt'], isNull);
        expect(result['shareTypes'], ['whatsapp']);
        expect(result['totalTimeSpent'], 300);
      });
      
      test('deve lidar com valores nulos', () {
        // Arrange
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
        );
        
        // Act
        final result = experience.toFirestore();
        
        // Assert
        expect(result['completedAt'], isNull);
        expect(result['lastInteractionAt'], isNull);
        expect(result['shareTypes'], isEmpty);
      });
    });
    
    group('fromFirestore', () {
      test('deve criar instância a partir de Map', () {
        // Arrange
        final startedAt = DateTime.now();
        final completedAt = startedAt.add(Duration(minutes: 5));
        final data = {
          'userId': 'test-user-123',
          'startedAt': Timestamp.fromDate(startedAt),
          'hasViewedVitrine': true,
          'hasSharedVitrine': true,
          'viewCount': 3,
          'shareCount': 2,
          'completedAt': Timestamp.fromDate(completedAt),
          'lastInteractionAt': Timestamp.fromDate(startedAt.add(Duration(minutes: 2))),
          'shareTypes': ['whatsapp', 'instagram'],
          'totalTimeSpent': 300,
        };
        
        // Act
        final experience = DemoExperience.fromFirestore(data);
        
        // Assert
        expect(experience.userId, 'test-user-123');
        expect(experience.startedAt.millisecondsSinceEpoch, 
               closeTo(startedAt.millisecondsSinceEpoch, 1000));
        expect(experience.hasViewedVitrine, true);
        expect(experience.hasSharedVitrine, true);
        expect(experience.viewCount, 3);
        expect(experience.shareCount, 2);
        expect(experience.completedAt?.millisecondsSinceEpoch, 
               closeTo(completedAt.millisecondsSinceEpoch, 1000));
        expect(experience.shareTypes, ['whatsapp', 'instagram']);
        expect(experience.totalTimeSpent, 300);
      });
      
      test('deve lidar com campos ausentes', () {
        // Arrange
        final data = {
          'userId': 'test-user-123',
          'startedAt': Timestamp.fromDate(DateTime.now()),
        };
        
        // Act
        final experience = DemoExperience.fromFirestore(data);
        
        // Assert
        expect(experience.userId, 'test-user-123');
        expect(experience.hasViewedVitrine, false);
        expect(experience.hasSharedVitrine, false);
        expect(experience.viewCount, 0);
        expect(experience.shareCount, 0);
        expect(experience.completedAt, isNull);
        expect(experience.lastInteractionAt, isNull);
        expect(experience.shareTypes, isEmpty);
        expect(experience.totalTimeSpent, 0);
      });
      
      test('deve lidar com tipos incorretos graciosamente', () {
        // Arrange
        final data = {
          'userId': 'test-user-123',
          'startedAt': Timestamp.fromDate(DateTime.now()),
          'hasViewedVitrine': 'true', // String ao invés de bool
          'viewCount': '5', // String ao invés de int
          'shareTypes': 'whatsapp', // String ao invés de List
        };
        
        // Act
        final experience = DemoExperience.fromFirestore(data);
        
        // Assert
        expect(experience.userId, 'test-user-123');
        expect(experience.hasViewedVitrine, false); // Valor padrão
        expect(experience.viewCount, 0); // Valor padrão
        expect(experience.shareTypes, isEmpty); // Valor padrão
      });
    });
    
    group('copyWith', () {
      test('deve criar cópia com valores alterados', () {
        // Arrange
        final original = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
          hasViewedVitrine: false,
          viewCount: 1,
        );
        
        // Act
        final copy = original.copyWith(
          hasViewedVitrine: true,
          viewCount: 2,
          shareCount: 1,
        );
        
        // Assert
        expect(copy.userId, original.userId);
        expect(copy.startedAt, original.startedAt);
        expect(copy.hasViewedVitrine, true); // Alterado
        expect(copy.viewCount, 2); // Alterado
        expect(copy.shareCount, 1); // Alterado
        expect(copy.hasSharedVitrine, original.hasSharedVitrine); // Mantido
      });
      
      test('deve manter valores originais quando não especificados', () {
        // Arrange
        final original = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
          hasViewedVitrine: true,
          viewCount: 5,
          shareTypes: ['whatsapp'],
        );
        
        // Act
        final copy = original.copyWith(viewCount: 6);
        
        // Assert
        expect(copy.userId, original.userId);
        expect(copy.hasViewedVitrine, original.hasViewedVitrine);
        expect(copy.viewCount, 6); // Apenas este alterado
        expect(copy.shareTypes, original.shareTypes);
      });
    });
    
    group('Métodos de conveniência', () {
      test('isCompleted deve retornar true quando completedAt não é nulo', () {
        // Arrange
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        
        // Act & Assert
        expect(experience.isCompleted, true);
      });
      
      test('isCompleted deve retornar false quando completedAt é nulo', () {
        // Arrange
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
        );
        
        // Act & Assert
        expect(experience.isCompleted, false);
      });
      
      test('duration deve calcular duração corretamente', () {
        // Arrange
        final startedAt = DateTime.now();
        final completedAt = startedAt.add(Duration(minutes: 5));
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: startedAt,
          completedAt: completedAt,
        );
        
        // Act
        final duration = experience.duration;
        
        // Assert
        expect(duration?.inMinutes, 5);
      });
      
      test('duration deve retornar null quando não completado', () {
        // Arrange
        final experience = DemoExperience(
          userId: 'test-user-123',
          startedAt: DateTime.now(),
        );
        
        // Act
        final duration = experience.duration;
        
        // Assert
        expect(duration, isNull);
      });
    });
    
    group('Validação', () {
      test('deve validar userId obrigatório', () {
        // Act & Assert
        expect(
          () => DemoExperience(
            userId: '',
            startedAt: DateTime.now(),
          ),
          throwsA(isA<AssertionError>()),
        );
      });
      
      test('deve validar startedAt obrigatório', () {
        // Act & Assert
        expect(
          () => DemoExperience(
            userId: 'test-user-123',
            startedAt: null as dynamic,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
      
      test('deve validar viewCount não negativo', () {
        // Act & Assert
        expect(
          () => DemoExperience(
            userId: 'test-user-123',
            startedAt: DateTime.now(),
            viewCount: -1,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
      
      test('deve validar shareCount não negativo', () {
        // Act & Assert
        expect(
          () => DemoExperience(
            userId: 'test-user-123',
            startedAt: DateTime.now(),
            shareCount: -1,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}