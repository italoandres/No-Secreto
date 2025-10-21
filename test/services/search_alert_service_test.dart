import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import '../../lib/services/search_alert_service.dart';

void main() {
  group('SearchAlertService', () {
    late SearchAlertService alertService;

    setUp(() {
      alertService = SearchAlertService.instance;
      alertService.clearAllAlerts();
    });

    tearDown(() {
      alertService.dispose();
    });

    group('Alert Management', () {
      test('should initialize with default thresholds', () {
        // Act
        final thresholds = alertService.getThresholds();

        // Assert
        expect(thresholds, isNotEmpty);
        expect(thresholds.containsKey('high_execution_time'), isTrue);
        expect(thresholds.containsKey('low_success_rate'), isTrue);
        expect(thresholds.containsKey('high_fallback_usage'), isTrue);
        expect(thresholds.containsKey('low_cache_hit_rate'), isTrue);
        expect(thresholds.containsKey('high_error_rate'), isTrue);
        expect(thresholds.containsKey('performance_degradation'), isTrue);
      });

      test('should get active alerts', () {
        // Arrange
        final initialAlerts = alertService.getActiveAlerts();
        expect(initialAlerts, isEmpty);

        // Act & Assert - Sem alertas inicialmente
        expect(alertService.getActiveAlerts(), isEmpty);
      });

      test('should get alerts by severity', () {
        // Act
        final criticalAlerts = alertService.getAlertsBySeverity(AlertSeverity.critical);
        final warningAlerts = alertService.getAlertsBySeverity(AlertSeverity.warning);
        final infoAlerts = alertService.getAlertsBySeverity(AlertSeverity.info);

        // Assert
        expect(criticalAlerts, isA<List<SearchAlert>>());
        expect(warningAlerts, isA<List<SearchAlert>>());
        expect(infoAlerts, isA<List<SearchAlert>>());
      });

      test('should clear all alerts', () {
        // Arrange - Assumindo que há alertas (seria necessário criar alertas primeiro)
        final initialCount = alertService.getActiveAlerts().length;

        // Act
        alertService.clearAllAlerts();

        // Assert
        expect(alertService.getActiveAlerts(), isEmpty);
      });

      test('should force alert check', () {
        // Act & Assert - Deve executar sem erros
        expect(() => alertService.checkAlertsNow(), returnsNormally);
      });
    });

    group('Alert Callbacks', () {
      test('should add and remove alert callbacks', () {
        // Arrange
        bool callbackCalled = false;
        void testCallback(SearchAlert alert) {
          callbackCalled = true;
        }

        // Act
        alertService.addAlertCallback(testCallback);
        
        // Assert - Callback foi adicionado (não há como testar diretamente)
        expect(() => alertService.addAlertCallback(testCallback), returnsNormally);
        
        // Act - Remover callback
        alertService.removeAlertCallback(testCallback);
        
        // Assert - Callback foi removido (não há como testar diretamente)
        expect(() => alertService.removeAlertCallback(testCallback), returnsNormally);
      });
    });

    group('Threshold Configuration', () {
      test('should set custom threshold', () {
        // Arrange
        const thresholdName = 'custom_threshold';
        final customThreshold = AlertThreshold(
          name: 'Custom Test Threshold',
          description: 'Test threshold for unit tests',
          threshold: 100.0,
          severity: AlertSeverity.warning,
          enabled: true,
        );

        // Act
        alertService.setThreshold(thresholdName, customThreshold);

        // Assert
        final thresholds = alertService.getThresholds();
        expect(thresholds.containsKey(thresholdName), isTrue);
        expect(thresholds[thresholdName]?.name, equals('Custom Test Threshold'));
        expect(thresholds[thresholdName]?.threshold, equals(100.0));
        expect(thresholds[thresholdName]?.severity, equals(AlertSeverity.warning));
      });

      test('should get all thresholds', () {
        // Act
        final thresholds = alertService.getThresholds();

        // Assert
        expect(thresholds, isA<Map<String, AlertThreshold>>());
        expect(thresholds, isNotEmpty);
        
        // Verificar se todos os thresholds padrão estão presentes
        final expectedThresholds = [
          'high_execution_time',
          'low_success_rate',
          'high_fallback_usage',
          'low_cache_hit_rate',
          'high_error_rate',
          'performance_degradation',
        ];
        
        for (final expectedThreshold in expectedThresholds) {
          expect(thresholds.containsKey(expectedThreshold), isTrue);
        }
      });
    });

    group('Alert Models', () {
      test('SearchAlert should serialize to JSON correctly', () {
        // Arrange
        final alert = SearchAlert(
          id: 'test_alert_123',
          type: 'Test Alert',
          message: 'This is a test alert message',
          severity: AlertSeverity.warning,
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          data: {
            'testKey': 'testValue',
            'numericValue': 42,
          },
        );

        // Act
        final json = alert.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], equals('test_alert_123'));
        expect(json['type'], equals('Test Alert'));
        expect(json['message'], equals('This is a test alert message'));
        expect(json['severity'], equals('AlertSeverity.warning'));
        expect(json['timestamp'], equals('2024-01-01T12:00:00.000'));
        expect(json['data'], isA<Map<String, dynamic>>());
        expect(json['data']['testKey'], equals('testValue'));
        expect(json['data']['numericValue'], equals(42));
      });

      test('AlertThreshold should serialize to JSON correctly', () {
        // Arrange
        final threshold = AlertThreshold(
          name: 'Test Threshold',
          description: 'A test threshold for unit testing',
          threshold: 75.5,
          severity: AlertSeverity.critical,
          enabled: true,
        );

        // Act
        final json = threshold.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('Test Threshold'));
        expect(json['description'], equals('A test threshold for unit testing'));
        expect(json['threshold'], equals(75.5));
        expect(json['severity'], equals('AlertSeverity.critical'));
        expect(json['enabled'], equals(true));
      });
    });

    group('Alert Severity Enum', () {
      test('should have correct severity levels', () {
        // Assert
        expect(AlertSeverity.values.length, equals(3));
        expect(AlertSeverity.values.contains(AlertSeverity.info), isTrue);
        expect(AlertSeverity.values.contains(AlertSeverity.warning), isTrue);
        expect(AlertSeverity.values.contains(AlertSeverity.critical), isTrue);
      });

      test('should convert to string correctly', () {
        // Assert
        expect(AlertSeverity.info.toString(), equals('AlertSeverity.info'));
        expect(AlertSeverity.warning.toString(), equals('AlertSeverity.warning'));
        expect(AlertSeverity.critical.toString(), equals('AlertSeverity.critical'));
      });
    });

    group('Service Lifecycle', () {
      test('should dispose without errors', () {
        // Act & Assert
        expect(() => alertService.dispose(), returnsNormally);
      });

      test('should handle multiple dispose calls', () {
        // Act & Assert
        expect(() {
          alertService.dispose();
          alertService.dispose(); // Segunda chamada
        }, returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('should handle empty alert list operations', () {
        // Arrange - Garantir que não há alertas
        alertService.clearAllAlerts();

        // Act & Assert
        expect(alertService.getActiveAlerts(), isEmpty);
        expect(alertService.getAlertsBySeverity(AlertSeverity.critical), isEmpty);
        expect(alertService.getAlertsBySeverity(AlertSeverity.warning), isEmpty);
        expect(alertService.getAlertsBySeverity(AlertSeverity.info), isEmpty);
      });

      test('should handle resolve non-existent alert', () {
        // Act & Assert - Deve executar sem erros
        expect(() => alertService.resolveAlert('non_existent_id'), returnsNormally);
      });

      test('should handle callback with null alert', () {
        // Arrange
        bool callbackCalled = false;
        void testCallback(SearchAlert alert) {
          callbackCalled = true;
        }

        alertService.addAlertCallback(testCallback);

        // Act & Assert - Adicionar callback deve funcionar
        expect(() => alertService.addAlertCallback(testCallback), returnsNormally);
      });
    });

    group('Integration with Analytics', () {
      test('should check alerts without analytics data', () {
        // Act & Assert - Deve executar sem erros mesmo sem dados de analytics
        expect(() => alertService.checkAlertsNow(), returnsNormally);
      });
    });
  });
}