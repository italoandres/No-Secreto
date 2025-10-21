import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';
import '../utils/fix_specific_profile.dart';
import '../services/data_migration_service.dart';

/// Utilitário para testar e corrigir o perfil problemático
class TestProfileFix {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Testa e corrige o perfil FmR7gH3s9Qrj2zbiUG6z
  static Future<void> testAndFixProfile() async {
    const profileId = 'FmR7gH3s9Qrj2zbiUG6z';
    
    try {
      EnhancedLogger.info('Starting profile test and fix', tag: 'PROFILE_TEST', data: {
        'profileId': profileId,
      });
      
      // 1. Verificar estado atual
      await FixSpecificProfile.checkProfileState(profileId);
      
      // 2. Aplicar correção específica
      await FixSpecificProfile.fixProfile(profileId);
      
      // 3. Verificar novamente após correção
      await Future.delayed(const Duration(seconds: 2));
      await FixSpecificProfile.checkProfileState(profileId);
      
      // 4. Testar se a migração geral também detecta
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        final needsMigration = DataMigrationService.needsMigration(data);
        
        EnhancedLogger.info('Migration detection test', tag: 'PROFILE_TEST', data: {
          'profileId': profileId,
          'needsMigration': needsMigration,
        });
        
        if (needsMigration) {
          EnhancedLogger.warning('Profile still needs migration after fix', tag: 'PROFILE_TEST');
          await DataMigrationService.migrateProfileData(profileId, data);
        }
      }
      
      // 5. Verificação final
      await Future.delayed(const Duration(seconds: 1));
      await FixSpecificProfile.checkProfileState(profileId);
      
      EnhancedLogger.success('Profile test and fix completed', tag: 'PROFILE_TEST', data: {
        'profileId': profileId,
      });
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Profile test and fix failed', 
        tag: 'PROFILE_TEST', 
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId}
      );
    }
  }
  
  /// Força a correção direta no Firestore
  static Future<void> forceDirectFix() async {
    const profileId = 'FmR7gH3s9Qrj2zbiUG6z';
    
    try {
      EnhancedLogger.info('Starting direct force fix', tag: 'DIRECT_FIX', data: {
        'profileId': profileId,
      });
      
      // Buscar dados atuais
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (!profileDoc.exists) {
        EnhancedLogger.error('Profile not found for direct fix', tag: 'DIRECT_FIX');
        return;
      }
      
      final rawData = profileDoc.data()!;
      
      // Log do estado atual
      EnhancedLogger.info('Current profile state', tag: 'DIRECT_FIX', data: {
        'allowInteractions': rawData['allowInteractions']?.toString() ?? 'null',
        'allowInteractionsType': rawData['allowInteractions']?.runtimeType.toString() ?? 'null',
      });
      
      // Forçar correção direta
      final directFix = <String, dynamic>{};
      
      // Se allowInteractions não é boolean, corrigir
      if (rawData['allowInteractions'] != null && rawData['allowInteractions'] is! bool) {
        directFix['allowInteractions'] = true; // Forçar como true
        EnhancedLogger.info('Forcing allowInteractions to true', tag: 'DIRECT_FIX');
      }
      
      // Corrigir outros campos boolean se necessário
      final booleanFields = [
        'isProfileComplete',
        'isDeusEPaiMember', 
        'readyForPurposefulRelationship',
        'hasSinaisPreparationSeal'
      ];
      
      for (final field in booleanFields) {
        if (rawData[field] != null && rawData[field] is! bool) {
          directFix[field] = true; // Forçar como true
          EnhancedLogger.info('Forcing $field to true', tag: 'DIRECT_FIX');
        }
      }
      
      // Aplicar correção se necessário
      if (directFix.isNotEmpty) {
        directFix['lastDirectFix'] = Timestamp.fromDate(DateTime.now());
        directFix['directFixVersion'] = '1.0.0';
        
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update(directFix);
        
        EnhancedLogger.success('Direct fix applied successfully', tag: 'DIRECT_FIX', data: {
          'profileId': profileId,
          'fieldsFixed': directFix.keys.toList(),
        });
      } else {
        EnhancedLogger.info('No direct fix needed', tag: 'DIRECT_FIX');
      }
      
    } catch (e, stackTrace) {
      EnhancedLogger.error('Direct fix failed', 
        tag: 'DIRECT_FIX', 
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId}
      );
    }
  }
}