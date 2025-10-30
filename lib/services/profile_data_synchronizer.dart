import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario_model.dart';
import '../models/spiritual_profile_model.dart';
import '../repositories/usuario_repository.dart';
import '../repositories/spiritual_profile_repository.dart';
import '../utils/enhanced_logger.dart';
import '../utils/error_handler.dart';

/// Serviço responsável por sincronizar dados entre usuarios e spiritual_profiles
class ProfileDataSynchronizer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sincroniza dados do usuário com o perfil espiritual
  static Future<void> syncUserData(String userId) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.sync('Starting user data synchronization', userId);

        // Carregar dados do usuário
        final user = await UsuarioRepository.getUserById(userId);
        if (user == null) {
          EnhancedLogger.warning('User not found for sync',
              tag: 'SYNC', data: {'userId': userId});
          return;
        }

        // Carregar perfil espiritual
        final profile =
            await SpiritualProfileRepository.getProfileByUserId(userId);
        if (profile == null) {
          EnhancedLogger.info('No spiritual profile found, skipping sync',
              tag: 'SYNC', data: {'userId': userId});
          return;
        }

        // Verificar se precisa sincronizar
        final syncNeeded = _needsSync(user, profile);
        if (!syncNeeded.needsSync) {
          EnhancedLogger.debug('No sync needed',
              tag: 'SYNC', data: {'userId': userId});
          return;
        }

        // Executar sincronização
        await _performSync(user, profile, syncNeeded.conflictedFields);

        EnhancedLogger.success('User data synchronized successfully',
            tag: 'SYNC',
            data: {
              'userId': userId,
              'syncedFields': syncNeeded.conflictedFields,
            });
      },
      context: 'ProfileDataSynchronizer.syncUserData',
      maxRetries: 2,
    );
  }

  /// Resolve conflitos de dados entre usuario e perfil espiritual
  static Future<void> resolveDataConflicts(String userId) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.sync('Resolving data conflicts', userId);

        final user = await UsuarioRepository.getUserById(userId);
        final profile =
            await SpiritualProfileRepository.getProfileByUserId(userId);

        if (user == null || profile == null) {
          EnhancedLogger.warning('Cannot resolve conflicts - missing data',
              tag: 'SYNC',
              data: {
                'userId': userId,
                'hasUser': user != null,
                'hasProfile': profile != null,
              });
          return;
        }

        // Determinar fonte de verdade baseada em timestamps
        final userLastUpdate =
            user.lastSyncAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final profileLastUpdate =
            profile.lastSyncAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final useUserAsSource = userLastUpdate.isAfter(profileLastUpdate);

        EnhancedLogger.info('Resolving conflicts using source',
            tag: 'SYNC',
            data: {
              'userId': userId,
              'source': useUserAsSource ? 'user' : 'profile',
              'userLastUpdate': userLastUpdate.toIso8601String(),
              'profileLastUpdate': profileLastUpdate.toIso8601String(),
            });

        if (useUserAsSource) {
          await _syncFromUserToProfile(user, profile);
        } else {
          await _syncFromProfileToUser(user, profile);
        }

        EnhancedLogger.success('Data conflicts resolved',
            tag: 'SYNC', data: {'userId': userId});
      },
      context: 'ProfileDataSynchronizer.resolveDataConflicts',
      maxRetries: 1,
    );
  }

  /// Atualiza username em ambas as collections
  static Future<void> updateUsername(String userId, String newUsername) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.sync('Updating username across collections', userId,
            data: {
              'newUsername': newUsername,
            });

        final now = Timestamp.fromDate(DateTime.now());

        // Atualizar na collection usuarios
        await _firestore.collection('usuarios').doc(userId).update({
          'username': newUsername,
          'lastSyncAt': now,
        });

        // Atualizar na collection spiritual_profiles
        final profileQuery = await _firestore
            .collection('spiritual_profiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (profileQuery.docs.isNotEmpty) {
          await profileQuery.docs.first.reference.update({
            'username': newUsername,
            'lastSyncAt': now,
          });
        }

        EnhancedLogger.success('Username updated in both collections',
            tag: 'SYNC',
            data: {
              'userId': userId,
              'username': newUsername,
            });
      },
      context: 'ProfileDataSynchronizer.updateUsername',
      maxRetries: 2,
    );
  }

  /// Atualiza foto de perfil em ambas as collections
  static Future<void> updateProfileImage(
      String userId, String? imageUrl) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.sync('Updating profile image across collections', userId,
            data: {
              'hasImage': imageUrl != null,
            });

        final now = Timestamp.fromDate(DateTime.now());

        // Atualizar na collection usuarios
        await _firestore.collection('usuarios').doc(userId).update({
          'imgUrl': imageUrl,
          'lastSyncAt': now,
        });

        // Atualizar na collection spiritual_profiles
        final profileQuery = await _firestore
            .collection('spiritual_profiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (profileQuery.docs.isNotEmpty) {
          await profileQuery.docs.first.reference.update({
            'mainPhotoUrl': imageUrl,
            'lastSyncAt': now,
          });
        }

        EnhancedLogger.success('Profile image updated in both collections',
            tag: 'SYNC',
            data: {
              'userId': userId,
            });
      },
      context: 'ProfileDataSynchronizer.updateProfileImage',
      maxRetries: 2,
    );
  }

  /// Atualiza nome em ambas as collections
  static Future<void> updateDisplayName(String userId, String newName) async {
    await ErrorHandler.safeExecute(
      () async {
        EnhancedLogger.sync('Updating display name across collections', userId,
            data: {
              'newName': newName,
            });

        final now = Timestamp.fromDate(DateTime.now());

        // Atualizar na collection usuarios
        await _firestore.collection('usuarios').doc(userId).update({
          'nome': newName,
          'lastSyncAt': now,
        });

        // Atualizar na collection spiritual_profiles
        final profileQuery = await _firestore
            .collection('spiritual_profiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (profileQuery.docs.isNotEmpty) {
          await profileQuery.docs.first.reference.update({
            'displayName': newName,
            'lastSyncAt': now,
          });
        }

        EnhancedLogger.success('Display name updated in both collections',
            tag: 'SYNC',
            data: {
              'userId': userId,
              'name': newName,
            });
      },
      context: 'ProfileDataSynchronizer.updateDisplayName',
      maxRetries: 2,
    );
  }

  /// Verifica se os dados precisam ser sincronizados
  static SyncNeeded _needsSync(
      UsuarioModel user, SpiritualProfileModel profile) {
    final conflictedFields = <String>[];

    // Verificar nome
    if (user.nome != profile.displayName) {
      conflictedFields.add('displayName');
    }

    // Verificar username
    if (user.username != profile.username) {
      conflictedFields.add('username');
    }

    // Verificar foto de perfil
    if (user.imgUrl != profile.mainPhotoUrl) {
      conflictedFields.add('profileImage');
    }

    return SyncNeeded(
      needsSync: conflictedFields.isNotEmpty,
      conflictedFields: conflictedFields,
    );
  }

  /// Executa a sincronização dos dados
  static Future<void> _performSync(UsuarioModel user,
      SpiritualProfileModel profile, List<String> fieldsToSync) async {
    // Usar dados do usuário como fonte de verdade (mais recente)
    final updates = <String, dynamic>{};
    final now = Timestamp.fromDate(DateTime.now());

    for (final field in fieldsToSync) {
      switch (field) {
        case 'displayName':
          updates['displayName'] = user.nome;
          break;
        case 'username':
          updates['username'] = user.username;
          break;
        case 'profileImage':
          updates['mainPhotoUrl'] = user.imgUrl;
          break;
      }
    }

    if (updates.isNotEmpty) {
      updates['lastSyncAt'] = now;

      await _firestore
          .collection('spiritual_profiles')
          .doc(profile.id!)
          .update(updates);

      // Também atualizar o timestamp no usuário
      await _firestore
          .collection('usuarios')
          .doc(user.id!)
          .update({'lastSyncAt': now});
    }
  }

  /// Sincroniza do usuário para o perfil espiritual
  static Future<void> _syncFromUserToProfile(
      UsuarioModel user, SpiritualProfileModel profile) async {
    final updates = <String, dynamic>{
      'displayName': user.nome,
      'username': user.username,
      'mainPhotoUrl': user.imgUrl,
      'lastSyncAt': Timestamp.fromDate(DateTime.now()),
    };

    await _firestore
        .collection('spiritual_profiles')
        .doc(profile.id!)
        .update(updates);
  }

  /// Sincroniza do perfil espiritual para o usuário
  static Future<void> _syncFromProfileToUser(
      UsuarioModel user, SpiritualProfileModel profile) async {
    final updates = <String, dynamic>{
      'nome': profile.displayName ?? user.nome,
      'username': profile.username ?? user.username,
      'imgUrl': profile.mainPhotoUrl ?? user.imgUrl,
      'lastSyncAt': Timestamp.fromDate(DateTime.now()),
    };

    await _firestore.collection('usuarios').doc(user.id!).update(updates);
  }

  /// Obtém status de sincronização para um usuário
  static Future<SyncStatus> getSyncStatus(String userId) async {
    try {
      final user = await UsuarioRepository.getUserById(userId);
      final profile =
          await SpiritualProfileRepository.getProfileByUserId(userId);

      if (user == null) {
        return SyncStatus(
          userId: userId,
          status: SyncStatusType.failed,
          lastSyncAt: null,
          conflictedFields: [],
          errorMessage: 'User not found',
        );
      }

      if (profile == null) {
        return SyncStatus(
          userId: userId,
          status: SyncStatusType.synced,
          lastSyncAt: user.lastSyncAt,
          conflictedFields: [],
          errorMessage: null,
        );
      }

      final syncNeeded = _needsSync(user, profile);

      return SyncStatus(
        userId: userId,
        status: syncNeeded.needsSync
            ? SyncStatusType.conflicted
            : SyncStatusType.synced,
        lastSyncAt: user.lastSyncAt ?? profile.lastSyncAt,
        conflictedFields: syncNeeded.conflictedFields,
        errorMessage: null,
      );
    } catch (e) {
      return SyncStatus(
        userId: userId,
        status: SyncStatusType.failed,
        lastSyncAt: null,
        conflictedFields: [],
        errorMessage: e.toString(),
      );
    }
  }

  /// Executa sincronização em lote para múltiplos usuários
  static Future<void> batchSyncUsers({int limit = 50}) async {
    try {
      EnhancedLogger.info('Starting batch user synchronization',
          tag: 'SYNC', data: {'limit': limit});

      final usersQuery =
          await _firestore.collection('usuarios').limit(limit).get();

      int syncedCount = 0;
      int errorCount = 0;

      for (final userDoc in usersQuery.docs) {
        try {
          await syncUserData(userDoc.id);
          syncedCount++;
        } catch (e) {
          errorCount++;
          EnhancedLogger.error('Failed to sync user in batch',
              tag: 'SYNC', error: e, data: {'userId': userDoc.id});
        }
      }

      EnhancedLogger.success('Batch synchronization completed',
          tag: 'SYNC',
          data: {
            'total': usersQuery.docs.length,
            'synced': syncedCount,
            'errors': errorCount,
          });
    } catch (e) {
      EnhancedLogger.error('Batch synchronization failed',
          tag: 'SYNC', error: e);
    }
  }
}

/// Resultado da verificação de sincronização
class SyncNeeded {
  final bool needsSync;
  final List<String> conflictedFields;

  SyncNeeded({
    required this.needsSync,
    required this.conflictedFields,
  });
}

/// Status de sincronização
enum SyncStatusType { synced, syncing, conflicted, failed }

/// Informações de status de sincronização
class SyncStatus {
  final String userId;
  final SyncStatusType status;
  final DateTime? lastSyncAt;
  final List<String> conflictedFields;
  final String? errorMessage;

  SyncStatus({
    required this.userId,
    required this.status,
    required this.lastSyncAt,
    required this.conflictedFields,
    required this.errorMessage,
  });
}
