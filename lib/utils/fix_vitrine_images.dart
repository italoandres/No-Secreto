import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/enhanced_logger.dart';

/// Utilitário para diagnosticar e corrigir problemas de imagens na vitrine
class FixVitrineImages {
  static const String _spiritualProfilesCollection = 'spiritual_profiles';
  static const String _usuariosCollection = 'usuarios';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Diagnosticar problemas de imagens na vitrine
  static Future<Map<String, dynamic>> diagnoseImageProblems() async {
    try {
      EnhancedLogger.info('Starting vitrine image diagnosis', tag: 'VITRINE_IMAGES');
      
      final results = <String, dynamic>{
        'totalProfiles': 0,
        'profilesWithoutImages': 0,
        'profilesWithBrokenImages': 0,
        'profilesFixed': 0,
        'errors': <String>[],
        'details': <Map<String, dynamic>>[],
      };

      // Buscar todos os perfis espirituais
      final spiritualProfiles = await _firestore
          .collection(_spiritualProfilesCollection)
          .get();

      results['totalProfiles'] = spiritualProfiles.docs.length;

      for (final doc in spiritualProfiles.docs) {
        try {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final mainPhotoUrl = data['mainPhotoUrl'] as String?;
          final photoUrl = data['photoUrl'] as String?; // Campo alternativo
          final displayName = data['displayName'] as String? ?? 'Usuário';

          final issues = <String>[];
          final profileInfo = <String, dynamic>{
            'profileId': doc.id,
            'userId': userId,
            'displayName': displayName,
            'mainPhotoUrl': mainPhotoUrl,
            'photoUrl': photoUrl,
            'hasMainPhoto': mainPhotoUrl?.isNotEmpty == true,
            'hasPhotoUrl': photoUrl?.isNotEmpty == true,
            'issues': issues,
          };

          // Verificar se não tem imagem principal
          if (mainPhotoUrl?.isEmpty != false) {
            results['profilesWithoutImages']++;
            issues.add('Sem foto principal (mainPhotoUrl)');
            
            // Tentar buscar foto do usuário na coleção usuarios
            if (userId != null) {
              final userDoc = await _firestore
                  .collection(_usuariosCollection)
                  .doc(userId)
                  .get();
              
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                final userPhotoUrl = userData['photoUrl'] as String?;
                final userImgUrl = userData['imgUrl'] as String?;
                
                if (userPhotoUrl?.isNotEmpty == true || userImgUrl?.isNotEmpty == true) {
                  profileInfo['userPhotoUrl'] = userPhotoUrl;
                  profileInfo['userImgUrl'] = userImgUrl;
                  profileInfo['canFix'] = true;
                  issues.add('Foto disponível na coleção usuarios');
                }
              }
            }
          }

          // Verificar se photoUrl está diferente de mainPhotoUrl
          if (photoUrl != mainPhotoUrl && photoUrl?.isNotEmpty == true) {
            issues.add('photoUrl diferente de mainPhotoUrl');
          }

          results['details'].add(profileInfo);

        } catch (e) {
          results['errors'].add('Erro ao processar perfil ${doc.id}: $e');
          EnhancedLogger.error('Error processing profile', 
            tag: 'VITRINE_IMAGES',
            error: e,
            data: {'profileId': doc.id}
          );
        }
      }

      EnhancedLogger.success('Vitrine image diagnosis completed', 
        tag: 'VITRINE_IMAGES',
        data: {
          'totalProfiles': results['totalProfiles'],
          'profilesWithoutImages': results['profilesWithoutImages'],
          'errors': (results['errors'] as List).length,
        }
      );

      return results;

    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to diagnose vitrine images', 
        tag: 'VITRINE_IMAGES',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Corrigir imagens da vitrine sincronizando com a coleção usuarios
  static Future<Map<String, dynamic>> fixVitrineImages() async {
    try {
      EnhancedLogger.info('Starting vitrine image fix', tag: 'VITRINE_IMAGES');
      
      final results = <String, dynamic>{
        'totalProcessed': 0,
        'profilesFixed': 0,
        'profilesSkipped': 0,
        'errors': <String>[],
        'fixedProfiles': <Map<String, dynamic>>[],
      };

      // Primeiro, fazer diagnóstico
      final diagnosis = await diagnoseImageProblems();
      final profilesWithIssues = (diagnosis['details'] as List<Map<String, dynamic>>)
          .where((profile) => (profile['issues'] as List<String>).isNotEmpty)
          .toList();

      results['totalProcessed'] = profilesWithIssues.length;

      for (final profileInfo in profilesWithIssues) {
        try {
          final profileId = profileInfo['profileId'] as String;
          final userId = profileInfo['userId'] as String?;
          final canFix = profileInfo['canFix'] as bool? ?? false;

          if (!canFix || userId == null) {
            results['profilesSkipped']++;
            continue;
          }

          // Buscar dados do usuário
          final userDoc = await _firestore
              .collection(_usuariosCollection)
              .doc(userId)
              .get();

          if (!userDoc.exists) {
            results['profilesSkipped']++;
            continue;
          }

          final userData = userDoc.data()!;
          final userPhotoUrl = userData['photoUrl'] as String?;
          final userImgUrl = userData['imgUrl'] as String?;
          final displayName = userData['nome'] as String?;
          final username = userData['username'] as String?;

          // Determinar qual foto usar
          String? photoToUse;
          if (userPhotoUrl?.isNotEmpty == true) {
            photoToUse = userPhotoUrl;
          } else if (userImgUrl?.isNotEmpty == true) {
            photoToUse = userImgUrl;
          }

          if (photoToUse == null) {
            results['profilesSkipped']++;
            continue;
          }

          // Atualizar perfil espiritual
          final updates = <String, dynamic>{
            'mainPhotoUrl': photoToUse,
            'photoUrl': photoToUse, // Manter sincronizado
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            'lastImageSync': Timestamp.fromDate(DateTime.now()),
          };

          // Sincronizar também displayName e username se necessário
          if (displayName?.isNotEmpty == true) {
            updates['displayName'] = displayName;
          }
          if (username?.isNotEmpty == true) {
            updates['username'] = username;
          }

          await _firestore
              .collection(_spiritualProfilesCollection)
              .doc(profileId)
              .update(updates);

          results['profilesFixed']++;
          results['fixedProfiles'].add({
            'profileId': profileId,
            'userId': userId,
            'displayName': displayName,
            'photoUrl': photoToUse,
            'updatedFields': updates.keys.toList(),
          });

          EnhancedLogger.info('Profile image fixed', 
            tag: 'VITRINE_IMAGES',
            data: {
              'profileId': profileId,
              'userId': userId,
              'photoUrl': photoToUse,
            }
          );

        } catch (e) {
          results['errors'].add('Erro ao corrigir perfil ${profileInfo['profileId']}: $e');
          EnhancedLogger.error('Error fixing profile image', 
            tag: 'VITRINE_IMAGES',
            error: e,
            data: {'profileInfo': profileInfo}
          );
        }
      }

      EnhancedLogger.success('Vitrine image fix completed', 
        tag: 'VITRINE_IMAGES',
        data: {
          'totalProcessed': results['totalProcessed'],
          'profilesFixed': results['profilesFixed'],
          'profilesSkipped': results['profilesSkipped'],
          'errors': (results['errors'] as List).length,
        }
      );

      return results;

    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to fix vitrine images', 
        tag: 'VITRINE_IMAGES',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  /// Sincronizar dados específicos de um usuário
  static Future<bool> syncUserProfileData(String userId) async {
    try {
      EnhancedLogger.info('Syncing user profile data', 
        tag: 'VITRINE_IMAGES',
        data: {'userId': userId}
      );

      // Buscar dados do usuário
      final userDoc = await _firestore
          .collection(_usuariosCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        EnhancedLogger.warning('User document not found', 
          tag: 'VITRINE_IMAGES',
          data: {'userId': userId}
        );
        return false;
      }

      final userData = userDoc.data()!;

      // Buscar perfil espiritual
      final spiritualProfileQuery = await _firestore
          .collection(_spiritualProfilesCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (spiritualProfileQuery.docs.isEmpty) {
        EnhancedLogger.warning('Spiritual profile not found', 
          tag: 'VITRINE_IMAGES',
          data: {'userId': userId}
        );
        return false;
      }

      final profileDoc = spiritualProfileQuery.docs.first;
      final profileData = profileDoc.data();

      // Preparar atualizações
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'lastSync': Timestamp.fromDate(DateTime.now()),
      };

      // Sincronizar foto
      final userPhotoUrl = userData['photoUrl'] as String?;
      final userImgUrl = userData['imgUrl'] as String?;
      final currentMainPhoto = profileData['mainPhotoUrl'] as String?;

      String? photoToUse;
      if (userPhotoUrl?.isNotEmpty == true) {
        photoToUse = userPhotoUrl;
      } else if (userImgUrl?.isNotEmpty == true) {
        photoToUse = userImgUrl;
      }

      if (photoToUse != null && photoToUse != currentMainPhoto) {
        updates['mainPhotoUrl'] = photoToUse;
        updates['photoUrl'] = photoToUse;
      }

      // Sincronizar nome
      final displayName = userData['nome'] as String?;
      if (displayName?.isNotEmpty == true && displayName != profileData['displayName']) {
        updates['displayName'] = displayName;
      }

      // Sincronizar username
      final username = userData['username'] as String?;
      if (username?.isNotEmpty == true && username != profileData['username']) {
        updates['username'] = username;
      }

      // Aplicar atualizações se houver mudanças
      if (updates.length > 2) { // Mais que apenas updatedAt e lastSync
        await _firestore
            .collection(_spiritualProfilesCollection)
            .doc(profileDoc.id)
            .update(updates);

        EnhancedLogger.success('User profile data synced', 
          tag: 'VITRINE_IMAGES',
          data: {
            'userId': userId,
            'profileId': profileDoc.id,
            'updatedFields': updates.keys.toList(),
          }
        );

        return true;
      }

      EnhancedLogger.info('No sync needed for user', 
        tag: 'VITRINE_IMAGES',
        data: {'userId': userId}
      );

      return false;

    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to sync user profile data', 
        tag: 'VITRINE_IMAGES',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId}
      );
      return false;
    }
  }

  /// Verificar e corrigir um perfil específico
  static Future<Map<String, dynamic>> checkAndFixProfile(String profileId) async {
    try {
      final issues = <String>[];
      final actions = <String>[];
      final result = <String, dynamic>{
        'profileId': profileId,
        'found': false,
        'hadIssues': false,
        'fixed': false,
        'issues': issues,
        'actions': actions,
      };

      final profileDoc = await _firestore
          .collection(_spiritualProfilesCollection)
          .doc(profileId)
          .get();

      if (!profileDoc.exists) {
        result['issues'].add('Perfil não encontrado');
        return result;
      }

      result['found'] = true;
      final data = profileDoc.data()!;
      final userId = data['userId'] as String?;
      final mainPhotoUrl = data['mainPhotoUrl'] as String?;

      // Verificar se tem foto
      if (mainPhotoUrl?.isEmpty != false) {
        result['hadIssues'] = true;
        issues.add('Sem foto principal');

        if (userId != null) {
          final synced = await syncUserProfileData(userId);
          if (synced) {
            result['fixed'] = true;
            actions.add('Foto sincronizada da coleção usuarios');
          }
        }
      }

      return result;

    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to check and fix profile', 
        tag: 'VITRINE_IMAGES',
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId}
      );
      rethrow;
    }
  }

  /// Executar correção completa do sistema de imagens
  static Future<void> runCompleteImageFix() async {
    try {
      EnhancedLogger.info('Starting complete image fix', tag: 'VITRINE_IMAGES');

      if (kDebugMode) {
        print('🔧 INICIANDO CORREÇÃO COMPLETA DE IMAGENS DA VITRINE');
        print('=' * 60);
      }

      // 1. Diagnóstico
      if (kDebugMode) print('📊 Executando diagnóstico...');
      final diagnosis = await diagnoseImageProblems();
      
      if (kDebugMode) {
        print('📊 DIAGNÓSTICO COMPLETO:');
        print('   Total de perfis: ${diagnosis['totalProfiles']}');
        print('   Perfis sem imagem: ${diagnosis['profilesWithoutImages']}');
        print('   Erros encontrados: ${(diagnosis['errors'] as List).length}');
      }

      // 2. Correção
      if (kDebugMode) print('🔧 Executando correções...');
      final fixResults = await fixVitrineImages();
      
      if (kDebugMode) {
        print('🔧 CORREÇÕES APLICADAS:');
        print('   Perfis processados: ${fixResults['totalProcessed']}');
        print('   Perfis corrigidos: ${fixResults['profilesFixed']}');
        print('   Perfis ignorados: ${fixResults['profilesSkipped']}');
        print('   Erros: ${(fixResults['errors'] as List).length}');
      }

      // 3. Verificação final
      if (kDebugMode) print('✅ Executando verificação final...');
      final finalDiagnosis = await diagnoseImageProblems();
      
      if (kDebugMode) {
        print('✅ VERIFICAÇÃO FINAL:');
        print('   Perfis sem imagem restantes: ${finalDiagnosis['profilesWithoutImages']}');
        print('=' * 60);
        print('🎉 CORREÇÃO COMPLETA FINALIZADA!');
      }

      EnhancedLogger.success('Complete image fix finished', 
        tag: 'VITRINE_IMAGES',
        data: {
          'initialIssues': diagnosis['profilesWithoutImages'],
          'fixed': fixResults['profilesFixed'],
          'remainingIssues': finalDiagnosis['profilesWithoutImages'],
        }
      );

    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to run complete image fix', 
        tag: 'VITRINE_IMAGES',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
}