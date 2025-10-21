import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_migration_service.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para forçar migração de perfis específicos
class ForceProfileMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Força a migração de um perfil específico
  static Future<bool> migrateProfile(String profileId) async {
    try {
      EnhancedLogger.info('Forcing profile migration', tag: 'FORCE_MIGRATION', data: {
        'profileId': profileId,
      });
      
      // Buscar dados atuais do perfil
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (!profileDoc.exists) {
        EnhancedLogger.warning('Profile not found for migration', tag: 'FORCE_MIGRATION', data: {
          'profileId': profileId,
        });
        return false;
      }
      
      final rawData = profileDoc.data()!;
      
      // Verificar se precisa de migração
      if (!DataMigrationService.needsMigration(rawData)) {
        EnhancedLogger.info('Profile does not need migration', tag: 'FORCE_MIGRATION', data: {
          'profileId': profileId,
        });
        return true;
      }
      
      // Aplicar migração
      await DataMigrationService.migrateProfileData(profileId, rawData);
      
      EnhancedLogger.success('Profile migration completed', tag: 'FORCE_MIGRATION', data: {
        'profileId': profileId,
      });
      
      return true;
    } catch (e) {
      EnhancedLogger.error('Profile migration failed', 
        tag: 'FORCE_MIGRATION', 
        error: e,
        data: {'profileId': profileId}
      );
      return false;
    }
  }
  
  /// Força migração de todos os perfis que precisam
  static Future<void> migrateAllProfiles() async {
    try {
      EnhancedLogger.info('Starting batch profile migration', tag: 'FORCE_MIGRATION');
      
      final querySnapshot = await _firestore
          .collection('spiritual_profiles')
          .get();
      
      int totalProfiles = querySnapshot.docs.length;
      int migratedCount = 0;
      int errorCount = 0;
      
      for (final doc in querySnapshot.docs) {
        try {
          final rawData = doc.data();
          
          if (DataMigrationService.needsMigration(rawData)) {
            await DataMigrationService.migrateProfileData(doc.id, rawData);
            migratedCount++;
            
            EnhancedLogger.debug('Profile migrated', tag: 'FORCE_MIGRATION', data: {
              'profileId': doc.id,
            });
          }
        } catch (e) {
          errorCount++;
          EnhancedLogger.error('Failed to migrate profile', 
            tag: 'FORCE_MIGRATION', 
            error: e,
            data: {'profileId': doc.id}
          );
        }
      }
      
      EnhancedLogger.success('Batch migration completed', tag: 'FORCE_MIGRATION', data: {
        'totalProfiles': totalProfiles,
        'migratedCount': migratedCount,
        'errorCount': errorCount,
      });
    } catch (e) {
      EnhancedLogger.error('Batch migration failed', tag: 'FORCE_MIGRATION', error: e);
    }
  }
  
  /// Verifica se um perfil precisa de migração
  static Future<bool> profileNeedsMigration(String profileId) async {
    try {
      final profileDoc = await _firestore
          .collection('spiritual_profiles')
          .doc(profileId)
          .get();
      
      if (!profileDoc.exists) {
        return false;
      }
      
      final rawData = profileDoc.data()!;
      return DataMigrationService.needsMigration(rawData);
    } catch (e) {
      EnhancedLogger.error('Failed to check migration need', 
        tag: 'FORCE_MIGRATION', 
        error: e,
        data: {'profileId': profileId}
      );
      return false;
    }
  }
  
  /// Obtém estatísticas de migração
  static Future<MigrationStats> getMigrationStats() async {
    try {
      final querySnapshot = await _firestore
          .collection('spiritual_profiles')
          .get();
      
      int totalProfiles = querySnapshot.docs.length;
      int needsMigration = 0;
      int alreadyMigrated = 0;
      
      for (final doc in querySnapshot.docs) {
        final rawData = doc.data();
        
        if (DataMigrationService.needsMigration(rawData)) {
          needsMigration++;
        } else {
          alreadyMigrated++;
        }
      }
      
      return MigrationStats(
        totalProfiles: totalProfiles,
        needsMigration: needsMigration,
        alreadyMigrated: alreadyMigrated,
      );
    } catch (e) {
      EnhancedLogger.error('Failed to get migration stats', tag: 'FORCE_MIGRATION', error: e);
      return MigrationStats(
        totalProfiles: 0,
        needsMigration: 0,
        alreadyMigrated: 0,
      );
    }
  }
}

/// Estatísticas de migração
class MigrationStats {
  final int totalProfiles;
  final int needsMigration;
  final int alreadyMigrated;
  
  MigrationStats({
    required this.totalProfiles,
    required this.needsMigration,
    required this.alreadyMigrated,
  });
  
  double get migrationProgress {
    if (totalProfiles == 0) return 1.0;
    return alreadyMigrated / totalProfiles;
  }
  
  String get progressText {
    return '${(migrationProgress * 100).toStringAsFixed(1)}% migrado';
  }
}