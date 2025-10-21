import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para corrigir perfil específico com dados corrompidos
class FixSpecificProfile {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Corrige o perfil FmR7gH3s9Qrj2zbiUG6z especificamente
  static Future<void> fixProfile(String profileId) async {
    try {
      EnhancedLogger.info('Starting specific profile fix', tag: 'PROFILE_FIX', data: {
        'profileId': profileId,
      });
      
      // Buscar dados atuais
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (!profileDoc.exists) {
        EnhancedLogger.error('Profile not found', tag: 'PROFILE_FIX', data: {
          'profileId': profileId,
        });
        return;
      }
      
      final rawData = profileDoc.data()!;
      final fixedData = <String, dynamic>{};
      bool needsUpdate = false;
      
      // Lista de campos que devem ser boolean
      final booleanFields = [
        'isProfileComplete',
        'isDeusEPaiMember', 
        'readyForPurposefulRelationship',
        'hasSinaisPreparationSeal',
        'allowInteractions'
      ];
      
      // Corrigir cada campo boolean
      for (final field in booleanFields) {
        if (rawData[field] != null && rawData[field] is! bool) {
          final originalValue = rawData[field];
          final originalType = originalValue.runtimeType.toString();
          
          EnhancedLogger.info('Fixing field', tag: 'PROFILE_FIX', data: {
            'field': field,
            'originalType': originalType,
            'originalValue': originalValue.toString(),
          });
          
          // Converter para boolean
          bool convertedValue;
          if (originalValue is Timestamp) {
            // Se é Timestamp, considera como true (dados antigos)
            convertedValue = true;
          } else if (originalValue is String) {
            convertedValue = originalValue.toLowerCase() == 'true';
          } else if (originalValue is num) {
            convertedValue = originalValue != 0;
          } else {
            // Para outros tipos, considera true se não for null
            convertedValue = true;
          }
          
          fixedData[field] = convertedValue;
          needsUpdate = true;
          
          EnhancedLogger.info('Field converted', tag: 'PROFILE_FIX', data: {
            'field': field,
            'newValue': convertedValue,
          });
        }
      }
      
      // Corrigir completionTasks se necessário
      if (rawData['completionTasks'] != null) {
        final tasks = rawData['completionTasks'] as Map<String, dynamic>;
        final fixedTasks = <String, bool>{};
        bool tasksNeedUpdate = false;
        
        for (final entry in tasks.entries) {
          if (entry.value is! bool) {
            final originalValue = entry.value;
            bool convertedValue;
            
            if (originalValue is Timestamp) {
              convertedValue = true;
            } else if (originalValue is String) {
              convertedValue = originalValue.toLowerCase() == 'true';
            } else if (originalValue is num) {
              convertedValue = originalValue != 0;
            } else {
              convertedValue = originalValue != null;
            }
            
            fixedTasks[entry.key] = convertedValue;
            tasksNeedUpdate = true;
            
            EnhancedLogger.info('Task converted', tag: 'PROFILE_FIX', data: {
              'task': entry.key,
              'originalType': originalValue.runtimeType.toString(),
              'newValue': convertedValue,
            });
          } else {
            fixedTasks[entry.key] = entry.value as bool;
          }
        }
        
        if (tasksNeedUpdate) {
          fixedData['completionTasks'] = fixedTasks;
          needsUpdate = true;
        }
      }
      
      // Aplicar correções se necessário
      if (needsUpdate) {
        fixedData['lastMigrationAt'] = Timestamp.fromDate(DateTime.now());
        fixedData['migrationVersion'] = '1.0.1'; // Nova versão para forçar
        
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update(fixedData);
        
        EnhancedLogger.success('Profile fixed successfully', tag: 'PROFILE_FIX', data: {
          'profileId': profileId,
          'fieldsFixed': fixedData.keys.toList(),
        });
        
        // Log da correção para auditoria
        await _firestore.collection('profile_fixes').add({
          'profileId': profileId,
          'fixedFields': fixedData.keys.toList(),
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'version': '1.0.1',
        });
      } else {
        EnhancedLogger.info('Profile does not need fixing', tag: 'PROFILE_FIX', data: {
          'profileId': profileId,
        });
      }
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to fix profile', 
        tag: 'PROFILE_FIX', 
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId}
      );
    }
  }
  
  /// Verifica o estado atual de um perfil
  static Future<void> checkProfileState(String profileId) async {
    try {
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (!profileDoc.exists) {
        EnhancedLogger.error('Profile not found for check', tag: 'PROFILE_CHECK', data: {
          'profileId': profileId,
        });
        return;
      }
      
      final data = profileDoc.data()!;
      
      EnhancedLogger.info('Profile state check', tag: 'PROFILE_CHECK', data: {
        'profileId': profileId,
        'allowInteractions': data['allowInteractions']?.toString() ?? 'null',
        'allowInteractionsType': data['allowInteractions']?.runtimeType.toString() ?? 'null',
        'isProfileComplete': data['isProfileComplete']?.toString() ?? 'null',
        'isProfileCompleteType': data['isProfileComplete']?.runtimeType.toString() ?? 'null',
        'migrationVersion': data['migrationVersion']?.toString() ?? 'null',
        'lastMigrationAt': data['lastMigrationAt']?.toString() ?? 'null',
      });
      
      // Verificar todos os campos boolean
      final booleanFields = [
        'isProfileComplete',
        'isDeusEPaiMember', 
        'readyForPurposefulRelationship',
        'hasSinaisPreparationSeal',
        'allowInteractions'
      ];
      
      for (final field in booleanFields) {
        if (data[field] != null && data[field] is! bool) {
          EnhancedLogger.warning('Field has wrong type', tag: 'PROFILE_CHECK', data: {
            'field': field,
            'value': data[field].toString(),
            'type': data[field].runtimeType.toString(),
          });
        }
      }
    } catch (e) {
      EnhancedLogger.error('Failed to check profile state', 
        tag: 'PROFILE_CHECK', 
        error: e,
        data: {'profileId': profileId}
      );
    }
  }
}