import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp_chat/services/data_sanitizer.dart';

void main() {
  group('DataSanitizer', () {
    group('sanitizeBoolean', () {
      test('should return boolean unchanged', () {
        expect(DataSanitizer.sanitizeBoolean(true, false), true);
        expect(DataSanitizer.sanitizeBoolean(false, true), false);
      });
      
      test('should convert Timestamp to true', () {
        final timestamp = Timestamp.fromDate(DateTime.now());
        expect(DataSanitizer.sanitizeBoolean(timestamp, false), true);
      });
      
      test('should convert string values correctly', () {
        expect(DataSanitizer.sanitizeBoolean('true', false), true);
        expect(DataSanitizer.sanitizeBoolean('TRUE', false), true);
        expect(DataSanitizer.sanitizeBoolean('1', false), true);
        expect(DataSanitizer.sanitizeBoolean('yes', false), true);
        
        expect(DataSanitizer.sanitizeBoolean('false', true), false);
        expect(DataSanitizer.sanitizeBoolean('FALSE', true), false);
        expect(DataSanitizer.sanitizeBoolean('0', true), false);
        expect(DataSanitizer.sanitizeBoolean('no', true), false);
        expect(DataSanitizer.sanitizeBoolean('', true), false);
      });
      
      test('should convert numbers correctly', () {
        expect(DataSanitizer.sanitizeBoolean(1, false), true);
        expect(DataSanitizer.sanitizeBoolean(42, false), true);
        expect(DataSanitizer.sanitizeBoolean(-1, false), true);
        expect(DataSanitizer.sanitizeBoolean(0, true), false);
        expect(DataSanitizer.sanitizeBoolean(0.0, true), false);
      });
      
      test('should use default for null', () {
        expect(DataSanitizer.sanitizeBoolean(null, true), true);
        expect(DataSanitizer.sanitizeBoolean(null, false), false);
      });
      
      test('should use default for unknown types', () {
        expect(DataSanitizer.sanitizeBoolean([], true), true);
        expect(DataSanitizer.sanitizeBoolean({}, false), false);
        expect(DataSanitizer.sanitizeBoolean(DateTime.now(), true), true);
      });
      
      test('should use default for ambiguous strings', () {
        expect(DataSanitizer.sanitizeBoolean('maybe', true), true);
        expect(DataSanitizer.sanitizeBoolean('unknown', false), false);
      });
    });
    
    group('sanitizeCompletionTasks', () {
      test('should return default for null', () {
        final result = DataSanitizer.sanitizeCompletionTasks(null);
        expect(result, {
          'photos': false,
          'identity': false,
          'biography': false,
          'preferences': false,
          'certification': false,
        });
      });
      
      test('should return default for non-Map', () {
        final result = DataSanitizer.sanitizeCompletionTasks('invalid');
        expect(result, {
          'photos': false,
          'identity': false,
          'biography': false,
          'preferences': false,
          'certification': false,
        });
      });
      
      test('should sanitize Map with mixed types', () {
        final input = {
          'photos': true,
          'identity': Timestamp.fromDate(DateTime.now()),
          'biography': 'true',
          'preferences': 0,
          'certification': null,
        };
        
        final result = DataSanitizer.sanitizeCompletionTasks(input);
        
        expect(result['photos'], true);
        expect(result['identity'], true); // Timestamp → true
        expect(result['biography'], true); // 'true' → true
        expect(result['preferences'], false); // 0 → false
        expect(result['certification'], false); // null → false
      });
      
      test('should preserve extra tasks', () {
        final input = {
          'photos': true,
          'customTask': 'yes',
        };
        
        final result = DataSanitizer.sanitizeCompletionTasks(input);
        
        expect(result['photos'], true);
        expect(result['customTask'], true);
        expect(result['identity'], false); // Default for missing
      });
    });
    
    group('sanitizePreferencesData', () {
      test('should sanitize all boolean fields', () {
        final input = {
          'allowInteractions': Timestamp.fromDate(DateTime.now()),
          'isProfileComplete': 'true',
          'isDeusEPaiMember': 1,
          'readyForPurposefulRelationship': null,
          'hasSinaisPreparationSeal': false,
          'otherField': 'preserved',
        };
        
        final result = DataSanitizer.sanitizePreferencesData(input);
        
        expect(result['allowInteractions'], true);
        expect(result['isProfileComplete'], true);
        expect(result['isDeusEPaiMember'], true);
        expect(result['readyForPurposefulRelationship'], false);
        expect(result['hasSinaisPreparationSeal'], false);
        expect(result['otherField'], 'preserved');
        expect(result['lastSanitizedAt'], isA<Timestamp>());
        expect(result['sanitizationVersion'], '2.0.0');
      });
      
      test('should sanitize completionTasks', () {
        final input = {
          'allowInteractions': true,
          'completionTasks': {
            'photos': Timestamp.fromDate(DateTime.now()),
            'identity': 'false',
          },
        };
        
        final result = DataSanitizer.sanitizePreferencesData(input);
        
        expect(result['completionTasks'], isA<Map<String, bool>>());
        final tasks = result['completionTasks'] as Map<String, bool>;
        expect(tasks['photos'], true);
        expect(tasks['identity'], false);
        expect(tasks['biography'], false); // Default
      });
      
      test('should not add metadata if no corrections needed', () {
        final input = {
          'allowInteractions': true,
          'isProfileComplete': false,
        };
        
        final result = DataSanitizer.sanitizePreferencesData(input);
        
        expect(result['lastSanitizedAt'], isNull);
        expect(result['sanitizationVersion'], isNull);
      });
      
      test('should preserve non-boolean fields', () {
        final input = {
          'allowInteractions': true,
          'userId': 'user123',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'customField': {'nested': 'data'},
        };
        
        final result = DataSanitizer.sanitizePreferencesData(input);
        
        expect(result['userId'], 'user123');
        expect(result['updatedAt'], isA<Timestamp>());
        expect(result['customField'], {'nested': 'data'});
      });
    });
    
    group('validateSanitizedData', () {
      test('should validate correct data', () {
        final data = {
          'allowInteractions': true,
          'completionTasks': {
            'photos': true,
            'identity': false,
          },
        };
        
        expect(DataSanitizer.validateSanitizedData(data), true);
      });
      
      test('should fail for missing required boolean', () {
        final data = {
          'otherField': 'value',
        };
        
        expect(DataSanitizer.validateSanitizedData(data), false);
      });
      
      test('should fail for wrong type in required boolean', () {
        final data = {
          'allowInteractions': 'not_boolean',
        };
        
        expect(DataSanitizer.validateSanitizedData(data), false);
      });
      
      test('should fail for wrong completionTasks type', () {
        final data = {
          'allowInteractions': true,
          'completionTasks': 'not_map',
        };
        
        expect(DataSanitizer.validateSanitizedData(data), false);
      });
    });
    
    group('createCleanPreferencesData', () {
      test('should create clean data structure', () {
        final result = DataSanitizer.createCleanPreferencesData(
          allowInteractions: true,
          profileId: 'profile123',
        );
        
        expect(result['allowInteractions'], true);
        expect(result['updatedAt'], isA<Timestamp>());
        expect(result['lastSanitizedAt'], isA<Timestamp>());
        expect(result['sanitizationVersion'], '2.0.0');
        expect(result['dataVersion'], '2.0.0');
      });
    });
  });
}