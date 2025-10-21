import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/models/vitrine_status_model.dart';

void main() {
  group('VitrineStatus Enum Tests', () {
    test('deve ter valores corretos', () {
      expect(VitrineStatus.active.value, 'active');
      expect(VitrineStatus.inactive.value, 'inactive');
      expect(VitrineStatus.suspended.value, 'suspended');
    });
    
    test('fromString deve retornar enum correto', () {
      expect(VitrineStatus.fromString('active'), VitrineStatus.active);
      expect(VitrineStatus.fromString('inactive'), VitrineStatus.inactive);
      expect(VitrineStatus.fromString('suspended'), VitrineStatus.suspended);
    });
    
    test('fromString deve retornar active para valor inválido', () {
      expect(VitrineStatus.fromString('invalid'), VitrineStatus.active);
      expect(VitrineStatus.fromString(''), VitrineStatus.active);
      expect(VitrineStatus.fromString(null), VitrineStatus.active);
    });
    
    test('isPubliclyVisible deve retornar true apenas para active', () {
      expect(VitrineStatus.active.isPubliclyVisible, true);
      expect(VitrineStatus.inactive.isPubliclyVisible, false);
      expect(VitrineStatus.suspended.isPubliclyVisible, false);
    });
    
    test('displayName deve retornar nomes corretos', () {
      expect(VitrineStatus.active.displayName, 'Ativa');
      expect(VitrineStatus.inactive.displayName, 'Inativa');
      expect(VitrineStatus.suspended.displayName, 'Suspensa');
    });
  });
  
  group('VitrineStatusInfo Tests', () {
    group('Constructor', () {
      test('deve criar instância com valores obrigatórios', () {
        // Arrange & Act
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: DateTime.now(),
          reason: 'Initial creation',
        );
        
        // Assert
        expect(statusInfo.userId, 'test-user-123');
        expect(statusInfo.status, VitrineStatus.active);
        expect(statusInfo.lastUpdated, isA<DateTime>());
        expect(statusInfo.reason, 'Initial creation');
        expect(statusInfo.isPubliclyVisible, true);
        expect(statusInfo.updatedBy, isNull);
        expect(statusInfo.metadata, isEmpty);
      });
      
      test('deve criar instância com todos os valores', () {
        // Arrange
        final lastUpdated = DateTime.now();
        final metadata = {'source': 'user_action', 'version': '1.0'};
        
        // Act
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.inactive,
          lastUpdated: lastUpdated,
          reason: 'User deactivated',
          updatedBy: 'user-456',
          metadata: metadata,
        );
        
        // Assert
        expect(statusInfo.userId, 'test-user-123');
        expect(statusInfo.status, VitrineStatus.inactive);
        expect(statusInfo.lastUpdated, lastUpdated);
        expect(statusInfo.reason, 'User deactivated');
        expect(statusInfo.updatedBy, 'user-456');
        expect(statusInfo.metadata, metadata);
        expect(statusInfo.isPubliclyVisible, false);
      });
    });
    
    group('isPubliclyVisible', () {
      test('deve retornar true quando status é active', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.isPubliclyVisible, true);
      });
      
      test('deve retornar false quando status é inactive', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.inactive,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.isPubliclyVisible, false);
      });
      
      test('deve retornar false quando status é suspended', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.suspended,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.isPubliclyVisible, false);
      });
    });
    
    group('toFirestore', () {
      test('deve converter para Map corretamente', () {
        // Arrange
        final lastUpdated = DateTime.now();
        final metadata = {'source': 'user_action'};
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: lastUpdated,
          reason: 'User activated',
          updatedBy: 'user-456',
          metadata: metadata,
        );
        
        // Act
        final result = statusInfo.toFirestore();
        
        // Assert
        expect(result['userId'], 'test-user-123');
        expect(result['status'], 'active');
        expect(result['lastUpdated'], isA<Timestamp>());
        expect(result['reason'], 'User activated');
        expect(result['updatedBy'], 'user-456');
        expect(result['metadata'], metadata);
        expect(result['isPubliclyVisible'], true);
      });
      
      test('deve lidar com valores nulos', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.inactive,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act
        final result = statusInfo.toFirestore();
        
        // Assert
        expect(result['updatedBy'], isNull);
        expect(result['metadata'], isEmpty);
        expect(result['isPubliclyVisible'], false);
      });
    });
    
    group('fromFirestore', () {
      test('deve criar instância a partir de Map', () {
        // Arrange
        final lastUpdated = DateTime.now();
        final metadata = {'source': 'admin_action', 'version': '2.0'};
        final data = {
          'userId': 'test-user-123',
          'status': 'suspended',
          'lastUpdated': Timestamp.fromDate(lastUpdated),
          'reason': 'Policy violation',
          'updatedBy': 'admin-789',
          'metadata': metadata,
        };
        
        // Act
        final statusInfo = VitrineStatusInfo.fromFirestore(data);
        
        // Assert
        expect(statusInfo.userId, 'test-user-123');
        expect(statusInfo.status, VitrineStatus.suspended);
        expect(statusInfo.lastUpdated.millisecondsSinceEpoch, 
               closeTo(lastUpdated.millisecondsSinceEpoch, 1000));
        expect(statusInfo.reason, 'Policy violation');
        expect(statusInfo.updatedBy, 'admin-789');
        expect(statusInfo.metadata, metadata);
        expect(statusInfo.isPubliclyVisible, false);
      });
      
      test('deve lidar com campos ausentes', () {
        // Arrange
        final data = {
          'userId': 'test-user-123',
          'status': 'active',
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
          'reason': 'Test',
        };
        
        // Act
        final statusInfo = VitrineStatusInfo.fromFirestore(data);
        
        // Assert
        expect(statusInfo.userId, 'test-user-123');
        expect(statusInfo.status, VitrineStatus.active);
        expect(statusInfo.reason, 'Test');
        expect(statusInfo.updatedBy, isNull);
        expect(statusInfo.metadata, isEmpty);
      });
      
      test('deve lidar com status inválido', () {
        // Arrange
        final data = {
          'userId': 'test-user-123',
          'status': 'invalid_status',
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
          'reason': 'Test',
        };
        
        // Act
        final statusInfo = VitrineStatusInfo.fromFirestore(data);
        
        // Assert
        expect(statusInfo.status, VitrineStatus.active); // Valor padrão
      });
      
      test('deve lidar com tipos incorretos graciosamente', () {
        // Arrange
        final data = {
          'userId': 'test-user-123',
          'status': 'active',
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
          'reason': 'Test',
          'metadata': 'invalid_metadata', // String ao invés de Map
        };
        
        // Act
        final statusInfo = VitrineStatusInfo.fromFirestore(data);
        
        // Assert
        expect(statusInfo.metadata, isEmpty); // Valor padrão
      });
    });
    
    group('copyWith', () {
      test('deve criar cópia com valores alterados', () {
        // Arrange
        final original = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: DateTime.now(),
          reason: 'Original reason',
          updatedBy: 'user-456',
        );
        
        // Act
        final copy = original.copyWith(
          status: VitrineStatus.inactive,
          reason: 'New reason',
          updatedBy: 'user-789',
        );
        
        // Assert
        expect(copy.userId, original.userId); // Mantido
        expect(copy.status, VitrineStatus.inactive); // Alterado
        expect(copy.reason, 'New reason'); // Alterado
        expect(copy.updatedBy, 'user-789'); // Alterado
        expect(copy.lastUpdated, original.lastUpdated); // Mantido
      });
      
      test('deve manter valores originais quando não especificados', () {
        // Arrange
        final metadata = {'key': 'value'};
        final original = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: DateTime.now(),
          reason: 'Original reason',
          metadata: metadata,
        );
        
        // Act
        final copy = original.copyWith(reason: 'New reason');
        
        // Assert
        expect(copy.userId, original.userId);
        expect(copy.status, original.status);
        expect(copy.reason, 'New reason'); // Apenas este alterado
        expect(copy.metadata, original.metadata);
      });
    });
    
    group('Validação', () {
      test('deve validar userId obrigatório', () {
        // Act & Assert
        expect(
          () => VitrineStatusInfo(
            userId: '',
            status: VitrineStatus.active,
            lastUpdated: DateTime.now(),
            reason: 'Test',
          ),
          throwsA(isA<AssertionError>()),
        );
      });
      
      test('deve validar reason obrigatório', () {
        // Act & Assert
        expect(
          () => VitrineStatusInfo(
            userId: 'test-user-123',
            status: VitrineStatus.active,
            lastUpdated: DateTime.now(),
            reason: '',
          ),
          throwsA(isA<AssertionError>()),
        );
      });
      
      test('deve validar lastUpdated obrigatório', () {
        // Act & Assert
        expect(
          () => VitrineStatusInfo(
            userId: 'test-user-123',
            status: VitrineStatus.active,
            lastUpdated: null as dynamic,
            reason: 'Test',
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
    
    group('Métodos de conveniência', () {
      test('canBeActivated deve retornar true para inactive', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.inactive,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.canBeActivated, true);
      });
      
      test('canBeActivated deve retornar false para active', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.canBeActivated, false);
      });
      
      test('canBeActivated deve retornar false para suspended', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.suspended,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.canBeActivated, false);
      });
      
      test('canBeDeactivated deve retornar true para active', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.active,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.canBeDeactivated, true);
      });
      
      test('canBeDeactivated deve retornar false para inactive', () {
        // Arrange
        final statusInfo = VitrineStatusInfo(
          userId: 'test-user-123',
          status: VitrineStatus.inactive,
          lastUpdated: DateTime.now(),
          reason: 'Test',
        );
        
        // Act & Assert
        expect(statusInfo.canBeDeactivated, false);
      });
    });
  });
}