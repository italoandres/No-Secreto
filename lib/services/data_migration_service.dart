import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

/// Serviço responsável por migrar e corrigir dados corrompidos no Firestore
class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migra dados de perfil espiritual corrigindo tipos incorretos
  static Future<Map<String, dynamic>> migrateProfileData(
      String profileId, Map<String, dynamic> rawData) async {
    try {
      safePrint(
          '🔄 [DataMigration] Iniciando migração para perfil: $profileId');

      bool needsUpdate = false;
      final migratedData = Map<String, dynamic>.from(rawData);
      final migrationLog = <String>[];

      // Lista de campos que devem ser boolean
      final booleanFields = [
        'isProfileComplete',
        'isDeusEPaiMember',
        'readyForPurposefulRelationship',
        'hasSinaisPreparationSeal',
        'allowInteractions'
      ];

      // Migrar campos boolean
      for (final field in booleanFields) {
        if (rawData[field] != null && rawData[field] is! bool) {
          final originalValue = rawData[field];
          final originalType = originalValue.runtimeType.toString();

          safePrint(
              '🔄 [DataMigration] Migrando campo $field de $originalType para bool');
          migrationLog.add('$field: $originalType → bool');

          // Converter para boolean baseado no tipo e valor
          bool convertedValue = _convertToBoolean(originalValue);
          migratedData[field] = convertedValue;
          needsUpdate = true;

          safePrint(
              '✅ [DataMigration] $field: $originalValue → $convertedValue');
        }
      }

      // Migrar completionTasks se necessário
      if (rawData['completionTasks'] != null) {
        final tasks = rawData['completionTasks'] as Map<String, dynamic>;
        final migratedTasks = <String, bool>{};
        bool tasksNeedUpdate = false;

        for (final entry in tasks.entries) {
          if (entry.value is! bool) {
            final originalValue = entry.value;
            final convertedValue = _convertToBoolean(originalValue);
            migratedTasks[entry.key] = convertedValue;
            tasksNeedUpdate = true;

            migrationLog.add(
                'completionTasks.${entry.key}: ${originalValue.runtimeType} → bool');
            safePrint(
                '🔄 [DataMigration] Task ${entry.key}: $originalValue → $convertedValue');
          } else {
            migratedTasks[entry.key] = entry.value as bool;
          }
        }

        if (tasksNeedUpdate) {
          migratedData['completionTasks'] = migratedTasks;
          needsUpdate = true;
        }
      }

      // Validar e corrigir campos de string vazios
      final stringFields = [
        'purpose',
        'nonNegotiableValue',
        'faithPhrase',
        'aboutMe',
        'city'
      ];
      for (final field in stringFields) {
        if (rawData[field] != null && rawData[field] is! String) {
          safePrint(
              '⚠️ [DataMigration] Campo $field tem tipo incorreto: ${rawData[field].runtimeType}');
          migratedData[field] = rawData[field].toString();
          needsUpdate = true;
          migrationLog.add('$field: ${rawData[field].runtimeType} → String');
        }
      }

      // Validar e corrigir campos numéricos
      if (rawData['age'] != null &&
          rawData['age'] is! int &&
          rawData['age'] is! double) {
        try {
          final ageValue = int.tryParse(rawData['age'].toString());
          if (ageValue != null) {
            migratedData['age'] = ageValue;
            needsUpdate = true;
            migrationLog.add('age: ${rawData['age'].runtimeType} → int');
          }
        } catch (e) {
          safePrint('⚠️ [DataMigration] Não foi possível converter age: $e');
          migratedData['age'] = null;
          needsUpdate = true;
        }
      }

      // Adicionar timestamp de migração
      if (needsUpdate) {
        migratedData['lastMigrationAt'] = Timestamp.fromDate(DateTime.now());
        migratedData['migrationVersion'] = '1.0.0';

        // Atualizar no Firestore
        await _firestore
            .collection('spiritual_profiles')
            .doc(profileId)
            .update(migratedData);

        safePrint(
            '✅ [DataMigration] Migração concluída para perfil: $profileId');
        safePrint(
            '📊 [DataMigration] Campos migrados: ${migrationLog.join(', ')}');

        // Log da migração para auditoria
        await _logMigration(profileId, migrationLog);
      } else {
        safePrint(
            'ℹ️ [DataMigration] Nenhuma migração necessária para perfil: $profileId');
      }

      return migratedData;
    } catch (e) {
      safePrint('❌ [DataMigration] Erro na migração de dados: $e');
      // Em caso de erro, retorna os dados originais para não quebrar o sistema
      return rawData;
    }
  }

  /// Converte um valor para boolean de forma inteligente
  static bool _convertToBoolean(dynamic value) {
    if (value == null) return false;

    // Se já é boolean, retorna como está
    if (value is bool) return value;

    // Se é Timestamp, considera como true (dados antigos que eram salvos como timestamp)
    if (value is Timestamp) return true;

    // Se é número
    if (value is num) return value != 0;

    // Se é string
    if (value is String) {
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes';
    }

    // Para outros tipos, considera true se não for null
    return true;
  }

  /// Registra a migração para auditoria
  static Future<void> _logMigration(
      String profileId, List<String> changes) async {
    try {
      await _firestore.collection('migration_logs').add({
        'profileId': profileId,
        'changes': changes,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'version': '1.0.0',
        'type': 'profile_data_migration'
      });
    } catch (e) {
      safePrint('⚠️ [DataMigration] Erro ao registrar log de migração: $e');
    }
  }

  /// Valida se um perfil precisa de migração
  static bool needsMigration(Map<String, dynamic> data) {
    // SEMPRE verificar campos críticos, ignorando migrationVersion
    // porque alguns dados podem ter sido corrompidos após a migração

    // Lista de campos que devem ser boolean
    final booleanFields = [
      'isProfileComplete',
      'isDeusEPaiMember',
      'readyForPurposefulRelationship',
      'hasSinaisPreparationSeal',
      'allowInteractions'
    ];

    // Verifica se algum campo boolean tem tipo incorreto
    for (final field in booleanFields) {
      if (data[field] != null && data[field] is! bool) {
        safePrint(
            '🔍 [DataMigration] Campo $field precisa migração: ${data[field].runtimeType}');
        return true;
      }
    }

    // Verifica completionTasks
    if (data['completionTasks'] != null) {
      final tasks = data['completionTasks'] as Map<String, dynamic>;
      for (final entry in tasks.entries) {
        if (entry.value is! bool) {
          safePrint(
              '🔍 [DataMigration] Task ${entry.key} precisa migração: ${entry.value.runtimeType}');
          return true;
        }
      }
    }

    return false;
  }

  /// Migra dados de usuário se necessário
  static Future<Map<String, dynamic>> migrateUserData(
      String userId, Map<String, dynamic> rawData) async {
    try {
      safePrint('🔄 [DataMigration] Verificando dados do usuário: $userId');

      bool needsUpdate = false;
      final migratedData = Map<String, dynamic>.from(rawData);
      final migrationLog = <String>[];

      // Validar campo perfilIsComplete
      if (rawData['perfilIsComplete'] != null &&
          rawData['perfilIsComplete'] is! bool) {
        final originalValue = rawData['perfilIsComplete'];
        migratedData['perfilIsComplete'] = _convertToBoolean(originalValue);
        needsUpdate = true;
        migrationLog
            .add('perfilIsComplete: ${originalValue.runtimeType} → bool');
      }

      // Validar campo isAdmin
      if (rawData['isAdmin'] != null && rawData['isAdmin'] is! bool) {
        final originalValue = rawData['isAdmin'];
        migratedData['isAdmin'] = _convertToBoolean(originalValue);
        needsUpdate = true;
        migrationLog.add('isAdmin: ${originalValue.runtimeType} → bool');
      }

      // Validar campos de string
      final stringFields = ['nome', 'username', 'email'];
      for (final field in stringFields) {
        if (rawData[field] != null && rawData[field] is! String) {
          migratedData[field] = rawData[field].toString();
          needsUpdate = true;
          migrationLog.add('$field: ${rawData[field].runtimeType} → String');
        }
      }

      if (needsUpdate) {
        migratedData['lastMigrationAt'] = Timestamp.fromDate(DateTime.now());

        await _firestore
            .collection('usuarios')
            .doc(userId)
            .update(migratedData);

        safePrint('✅ [DataMigration] Dados do usuário migrados: $userId');
        safePrint(
            '📊 [DataMigration] Campos migrados: ${migrationLog.join(', ')}');

        await _logUserMigration(userId, migrationLog);
      }

      return migratedData;
    } catch (e) {
      safePrint('❌ [DataMigration] Erro na migração de dados do usuário: $e');
      return rawData;
    }
  }

  /// Registra migração de usuário
  static Future<void> _logUserMigration(
      String userId, List<String> changes) async {
    try {
      await _firestore.collection('migration_logs').add({
        'userId': userId,
        'changes': changes,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'version': '1.0.0',
        'type': 'user_data_migration'
      });
    } catch (e) {
      safePrint(
          '⚠️ [DataMigration] Erro ao registrar log de migração do usuário: $e');
    }
  }

  /// Executa migração em lote para múltiplos perfis
  static Future<void> batchMigrateProfiles({int limit = 50}) async {
    try {
      safePrint('🔄 [DataMigration] Iniciando migração em lote...');

      final querySnapshot =
          await _firestore.collection('spiritual_profiles').limit(limit).get();

      int migratedCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (needsMigration(data)) {
          await migrateProfileData(doc.id, data);
          migratedCount++;
        }
      }

      safePrint(
          '✅ [DataMigration] Migração em lote concluída. $migratedCount perfis migrados.');
    } catch (e) {
      safePrint('❌ [DataMigration] Erro na migração em lote: $e');
    }
  }
}
