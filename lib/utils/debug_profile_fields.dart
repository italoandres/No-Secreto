import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para debugar campos específicos do perfil
class DebugProfileFields {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Debug completo de todos os campos do perfil
  static Future<void> debugAllFields(String profileId) async {
    try {
      EnhancedLogger.info('Starting complete field debug', tag: 'FIELD_DEBUG', data: {
        'profileId': profileId,
      });
      
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (!profileDoc.exists) {
        EnhancedLogger.error('Profile not found for debug', tag: 'FIELD_DEBUG');
        return;
      }
      
      final data = profileDoc.data()!;
      
      // Debug de todos os campos
      for (final entry in data.entries) {
        final fieldName = entry.key;
        final fieldValue = entry.value;
        final fieldType = fieldValue?.runtimeType.toString() ?? 'null';
        
        EnhancedLogger.info('Field debug', tag: 'FIELD_DEBUG', data: {
          'field': fieldName,
          'type': fieldType,
          'value': fieldValue?.toString() ?? 'null',
        });
        
        // Verificar especificamente campos boolean problemáticos
        if (fieldName == 'allowInteractions' || 
            fieldName == 'isProfileComplete' ||
            fieldName == 'isDeusEPaiMember' ||
            fieldName == 'readyForPurposefulRelationship' ||
            fieldName == 'hasSinaisPreparationSeal') {
          
          if (fieldValue != null && fieldValue is! bool) {
            EnhancedLogger.warning('PROBLEMATIC FIELD FOUND', tag: 'FIELD_DEBUG', data: {
              'field': fieldName,
              'expectedType': 'bool',
              'actualType': fieldType,
              'value': fieldValue.toString(),
            });
          }
        }
      }
      
      // Debug específico de completionTasks
      if (data['completionTasks'] != null) {
        final tasks = data['completionTasks'] as Map<String, dynamic>;
        
        EnhancedLogger.info('Debugging completionTasks', tag: 'FIELD_DEBUG', data: {
          'tasksCount': tasks.length,
        });
        
        for (final taskEntry in tasks.entries) {
          final taskName = taskEntry.key;
          final taskValue = taskEntry.value;
          final taskType = taskValue?.runtimeType.toString() ?? 'null';
          
          EnhancedLogger.info('Task debug', tag: 'FIELD_DEBUG', data: {
            'task': taskName,
            'type': taskType,
            'value': taskValue?.toString() ?? 'null',
          });
          
          if (taskValue != null && taskValue is! bool) {
            EnhancedLogger.warning('PROBLEMATIC TASK FOUND', tag: 'FIELD_DEBUG', data: {
              'task': taskName,
              'expectedType': 'bool',
              'actualType': taskType,
              'value': taskValue.toString(),
            });
          }
        }
      }
      
      EnhancedLogger.success('Field debug completed', tag: 'FIELD_DEBUG', data: {
        'profileId': profileId,
        'totalFields': data.length,
      });
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Field debug failed', 
        tag: 'FIELD_DEBUG', 
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId}
      );
    }
  }
  
  /// Testa um update simples para identificar o campo problemático
  static Future<void> testSimpleUpdate(String profileId) async {
    try {
      EnhancedLogger.info('Testing simple update', tag: 'UPDATE_TEST', data: {
        'profileId': profileId,
      });
      
      // Primeiro, debug completo
      await debugAllFields(profileId);
      
      // Tentar update simples
      try {
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update({
              'testField': 'test_value',
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
        
        EnhancedLogger.success('Simple update succeeded', tag: 'UPDATE_TEST');
        
        // Remover campo de teste
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update({
              'testField': FieldValue.delete(),
            });
        
      } catch (updateError) {
        EnhancedLogger.error('Simple update failed', 
          tag: 'UPDATE_TEST', 
          error: updateError,
          data: {'profileId': profileId}
        );
      }
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Update test failed', 
        tag: 'UPDATE_TEST', 
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId}
      );
    }
  }
}