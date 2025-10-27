import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/spiritual_profile_model.dart';
import '../services/data_migration_service.dart';
import '../utils/enhanced_logger.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class SpiritualProfileRepository {
  static const String _collection = 'spiritual_profiles';
  static const String _interestsCollection = 'user_interests';
  static const String _mutualInterestsCollection = 'mutual_interests';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CRUD Operations for Spiritual Profiles

  /// Create a new spiritual profile for the current user
  static Future<String> createProfile(SpiritualProfileModel profile) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      profile = profile.copyWith(
        userId: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      safePrint(
          '🔄 Criando perfil espiritual para usuário: ${currentUser.uid}');

      final docRef =
          await _firestore.collection(_collection).add(profile.toJson());

      safePrint('✅ Perfil espiritual criado com ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      safePrint('❌ Erro ao criar perfil espiritual: $e');
      rethrow;
    }
  }

  /// Get spiritual profile by user ID
  static Future<SpiritualProfileModel?> getProfileByUserId(
      String userId) async {
    try {
      EnhancedLogger.profile('Loading profile', userId);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        EnhancedLogger.info('No spiritual profile found for user',
            tag: 'PROFILE', data: {'userId': userId});
        return null;
      }

      final doc = querySnapshot.docs.first;
      final rawData = doc.data();

      // Migração automática usando o novo serviço
      final migratedData =
          await DataMigrationService.migrateProfileData(doc.id, rawData);

      final profile = SpiritualProfileModel.fromJson(migratedData);
      profile.id = doc.id;

      EnhancedLogger.success('Profile loaded successfully',
          tag: 'PROFILE',
          data: {
            'userId': userId,
            'profileId': profile.id,
            'isComplete': profile.isProfileComplete,
          });

      return profile;
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to load spiritual profile',
          tag: 'PROFILE',
          error: e,
          stackTrace: stackTrace,
          data: {'userId': userId});
      return null;
    }
  }

  /// Get current user's spiritual profile
  static Future<SpiritualProfileModel?> getCurrentUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    return await getProfileByUserId(currentUser.uid);
  }

  /// Update spiritual profile
  static Future<void> updateProfile(
      String profileId, Map<String, dynamic> updates) async {
    try {
      EnhancedLogger.info('Updating spiritual profile', tag: 'PROFILE', data: {
        'profileId': profileId,
        'fields': updates.keys.toList(),
      });

      // FORÇA correção de TODOS os campos boolean antes de qualquer update
      try {
        final profileDoc =
            await _firestore.collection(_collection).doc(profileId).get();
        if (profileDoc.exists) {
          final rawData = profileDoc.data()!;
          final forceUpdates = <String, dynamic>{};
          bool needsForceUpdate = false;

          // Lista de todos os campos que devem ser boolean
          final booleanFields = [
            'isProfileComplete',
            'isDeusEPaiMember',
            'readyForPurposefulRelationship',
            'hasSinaisPreparationSeal',
            'allowInteractions'
          ];

          // Verificar e corrigir cada campo boolean
          for (final field in booleanFields) {
            if (rawData[field] != null && rawData[field] is! bool) {
              final originalValue = rawData[field];

              EnhancedLogger.warning('Forcing correction for field',
                  tag: 'PROFILE',
                  data: {
                    'profileId': profileId,
                    'field': field,
                    'originalType': originalValue.runtimeType.toString(),
                    'originalValue': originalValue.toString(),
                  });

              // Converter para boolean
              bool convertedValue;
              if (originalValue is Timestamp) {
                convertedValue = true; // Dados antigos considerados como true
              } else if (originalValue is String) {
                convertedValue = originalValue.toLowerCase() == 'true';
              } else if (originalValue is num) {
                convertedValue = originalValue != 0;
              } else {
                convertedValue = true; // Padrão seguro
              }

              forceUpdates[field] = convertedValue;
              needsForceUpdate = true;

              EnhancedLogger.info('Field will be corrected',
                  tag: 'PROFILE',
                  data: {
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

                EnhancedLogger.info('Task will be corrected',
                    tag: 'PROFILE',
                    data: {
                      'task': entry.key,
                      'originalType': originalValue.runtimeType.toString(),
                      'newValue': convertedValue,
                    });
              } else {
                fixedTasks[entry.key] = entry.value as bool;
              }
            }

            if (tasksNeedUpdate) {
              forceUpdates['completionTasks'] = fixedTasks;
              needsForceUpdate = true;
            }
          }

          // Aplicar correções se necessário
          if (needsForceUpdate) {
            forceUpdates['lastForceUpdate'] =
                Timestamp.fromDate(DateTime.now());

            await _firestore
                .collection(_collection)
                .doc(profileId)
                .update(forceUpdates);

            EnhancedLogger.success('Force correction applied successfully',
                tag: 'PROFILE',
                data: {
                  'profileId': profileId,
                  'fieldsFixed': forceUpdates.keys.toList(),
                });

            // Aguardar para garantir que a correção foi aplicada
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        }
      } catch (migrationError) {
        EnhancedLogger.warning(
            'Force correction failed, proceeding with update',
            tag: 'PROFILE',
            data: {'error': migrationError.toString()});
      }

      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      // FORÇA substituição completa para evitar conflitos de tipo
      try {
        // Primeiro, tentar update normal
        await _firestore.collection(_collection).doc(profileId).update(updates);
      } catch (updateError) {
        EnhancedLogger.warning(
            'Normal update failed, forcing field replacement',
            tag: 'PROFILE',
            data: {
              'error': updateError.toString(),
              'updates': updates,
            });

        // Se falhar, fazer substituição forçada campo por campo
        for (final entry in updates.entries) {
          try {
            await _firestore.collection(_collection).doc(profileId).update({
              entry.key: entry.value,
            });

            EnhancedLogger.info('Field updated individually',
                tag: 'PROFILE',
                data: {
                  'field': entry.key,
                  'value': entry.value,
                  'type': entry.value.runtimeType.toString(),
                });

            // Aguardar um pouco entre updates
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (fieldError) {
            EnhancedLogger.error('Failed to update field individually',
                tag: 'PROFILE',
                error: fieldError,
                data: {
                  'field': entry.key,
                  'value': entry.value,
                });

            // Como último recurso, usar set com merge
            try {
              await _firestore.collection(_collection).doc(profileId).set({
                entry.key: entry.value,
              }, SetOptions(merge: true));

              EnhancedLogger.success('Field set with merge',
                  tag: 'PROFILE',
                  data: {
                    'field': entry.key,
                  });
            } catch (setError) {
              EnhancedLogger.error('All update methods failed for field',
                  tag: 'PROFILE', error: setError, data: {'field': entry.key});
            }
          }
        }
      }

      EnhancedLogger.success('Spiritual profile updated successfully',
          tag: 'PROFILE',
          data: {
            'profileId': profileId,
          });
    } catch (e, stackTrace) {
      EnhancedLogger.error('Failed to update spiritual profile',
          tag: 'PROFILE',
          error: e,
          stackTrace: stackTrace,
          data: {'profileId': profileId, 'updates': updates});
      rethrow;
    }
  }

  /// Update task completion status
  static Future<void> updateTaskCompletion(
      String profileId, String taskName, bool isCompleted) async {
    try {
      safePrint('🔄 Atualizando tarefa "$taskName": $isCompleted');

      await _firestore.collection(_collection).doc(profileId).update({
        'completionTasks.$taskName': isCompleted,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Check if all REQUIRED tasks are completed (certification is optional)
      final profile =
          await getProfileByUserId(FirebaseAuth.instance.currentUser!.uid);
      if (profile != null) {
        // Verificar apenas tarefas obrigatórias (certificação é opcional)
        final requiredTasks = [
          'photos',
          'identity',
          'biography',
          'preferences'
        ];
        final allCompleted = requiredTasks
            .every((task) => profile.completionTasks[task] == true);

        if (allCompleted && !profile.isProfileComplete) {
          await updateProfile(profileId, {
            'isProfileComplete': true,
            'profileCompletedAt': Timestamp.fromDate(DateTime.now()),
          });
          safePrint(
              '🎉 Perfil espiritual completado! Todas as tarefas obrigatórias foram concluídas.');
        }
      }

      safePrint('✅ Tarefa atualizada: $taskName');
    } catch (e) {
      safePrint('❌ Erro ao atualizar tarefa: $e');
      rethrow;
    }
  }

  /// Get or create profile for current user
  static Future<SpiritualProfileModel> getOrCreateCurrentUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    // Try to get existing profile
    SpiritualProfileModel? profile = await getProfileByUserId(currentUser.uid);

    if (profile == null) {
      // Create new profile
      safePrint(
          '📝 Criando novo perfil espiritual para usuário: ${currentUser.uid}');
      final newProfile = SpiritualProfileModel(userId: currentUser.uid);
      final profileId = await createProfile(newProfile);

      profile = newProfile.copyWith(id: profileId);
    }

    return profile;
  }

  // Interest Management

  /// Express interest in another user
  static Future<bool> expressInterest(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      if (currentUser.uid == targetUserId) {
        throw Exception('Não é possível demonstrar interesse em si mesmo');
      }

      safePrint(
          '💝 Expressando interesse: ${currentUser.uid} → $targetUserId');

      // Check if interest already exists
      final existingInterest = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: targetUserId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingInterest.docs.isNotEmpty) {
        safePrint('⚠️ Interesse já existe');
        return false;
      }

      // Create interest record
      final interest = InterestModel(
        fromUserId: currentUser.uid,
        toUserId: targetUserId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_interestsCollection).add(interest.toJson());

      // Check for mutual interest
      final mutualInterest = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (mutualInterest.docs.isNotEmpty) {
        // Create mutual interest record
        await _createMutualInterest(currentUser.uid, targetUserId);
        safePrint('💕 Interesse mútuo detectado!');
      }

      safePrint('✅ Interesse expressado com sucesso');
      return true;
    } catch (e) {
      safePrint('❌ Erro ao expressar interesse: $e');
      rethrow;
    }
  }

  /// Create mutual interest record
  static Future<void> _createMutualInterest(
      String user1Id, String user2Id) async {
    try {
      final mutualInterest = MutualInterestModel(
        user1Id: user1Id,
        user2Id: user2Id,
        matchedAt: DateTime.now(),
        chatExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _firestore
          .collection(_mutualInterestsCollection)
          .add(mutualInterest.toJson());

      safePrint('✅ Interesse mútuo criado: $user1Id ↔ $user2Id');
    } catch (e) {
      safePrint('❌ Erro ao criar interesse mútuo: $e');
      rethrow;
    }
  }

  /// Check if current user has expressed interest in target user
  static Future<bool> hasExpressedInterest(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final query = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: targetUserId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      safePrint('❌ Erro ao verificar interesse: $e');
      return false;
    }
  }

  /// Get pending interests for a specific user (convites recebidos)
  static Future<List<InterestModel>> getPendingInterestsForUser(
      String userId) async {
    try {
      EnhancedLogger.info('Loading pending interests for user',
          tag: 'VITRINE_INVITES', data: {'userId': userId});

      final querySnapshot = await _firestore
          .collection(_interestsCollection)
          .where('toUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final interests = <InterestModel>[];
      final processedFromUsers = <String>{};

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;

          EnhancedLogger.info('Processing interest document',
              tag: 'VITRINE_INVITES',
              data: {
                'docId': doc.id,
                'fromUserId': data['fromUserId'],
                'toUserId': data['toUserId'],
                'isActive': data['isActive'],
              });

          final interest = InterestModel.fromJson(data);

          // Validar se os dados essenciais estão presentes
          if (interest.fromUserId.isEmpty) {
            EnhancedLogger.error('Interest has empty fromUserId',
                tag: 'VITRINE_INVITES', data: {'docId': doc.id, 'data': data});
            continue;
          }

          // Evitar duplicatas do mesmo usuário (manter apenas o mais recente)
          if (processedFromUsers.contains(interest.fromUserId)) {
            EnhancedLogger.info('Skipping duplicate interest',
                tag: 'VITRINE_INVITES',
                data: {'fromUserId': interest.fromUserId, 'docId': doc.id});
            continue;
          }

          // Verificar se ainda não foi processado (não existe interesse mútuo)
          final mutualExists =
              await _checkMutualInterestExists(interest.fromUserId, userId);
          if (!mutualExists) {
            interests.add(interest);
            processedFromUsers.add(interest.fromUserId);

            EnhancedLogger.info('Added valid interest',
                tag: 'VITRINE_INVITES',
                data: {
                  'fromUserId': interest.fromUserId,
                  'toUserId': interest.toUserId,
                  'docId': doc.id
                });
          } else {
            EnhancedLogger.info('Skipping processed interest (mutual exists)',
                tag: 'VITRINE_INVITES',
                data: {'fromUserId': interest.fromUserId, 'docId': doc.id});
          }
        } catch (e) {
          EnhancedLogger.error('Failed to parse interest',
              tag: 'VITRINE_INVITES',
              error: e,
              data: {'docId': doc.id, 'rawData': doc.data()});
        }
      }

      EnhancedLogger.success('Pending interests loaded',
          tag: 'VITRINE_INVITES',
          data: {
            'userId': userId,
            'count': interests.length,
            'uniqueUsers': processedFromUsers.length
          });

      return interests;
    } catch (e) {
      EnhancedLogger.error('Failed to get pending interests',
          tag: 'VITRINE_INVITES', error: e, data: {'userId': userId});
      return [];
    }
  }

  /// Check if mutual interest exists between two users
  static Future<bool> _checkMutualInterestExists(
      String user1Id, String user2Id) async {
    try {
      final query1 = await _firestore
          .collection(_mutualInterestsCollection)
          .where('user1Id', isEqualTo: user1Id)
          .where('user2Id', isEqualTo: user2Id)
          .get();

      if (query1.docs.isNotEmpty) return true;

      final query2 = await _firestore
          .collection(_mutualInterestsCollection)
          .where('user1Id', isEqualTo: user2Id)
          .where('user2Id', isEqualTo: user1Id)
          .get();

      return query2.docs.isNotEmpty;
    } catch (e) {
      EnhancedLogger.error('Failed to check mutual interest',
          tag: 'VITRINE_INVITES',
          error: e,
          data: {'user1': user1Id, 'user2': user2Id});
      return false;
    }
  }

  /// Decline an interest (mark as inactive)
  static Future<void> declineInterest(String interestId) async {
    try {
      EnhancedLogger.info('Declining interest',
          tag: 'VITRINE_INVITES', data: {'interestId': interestId});

      await _firestore.collection(_interestsCollection).doc(interestId).update({
        'isActive': false,
        'declinedAt': Timestamp.fromDate(DateTime.now()),
      });

      EnhancedLogger.success('Interest declined',
          tag: 'VITRINE_INVITES', data: {'interestId': interestId});
    } catch (e) {
      EnhancedLogger.error('Failed to decline interest',
          tag: 'VITRINE_INVITES', error: e, data: {'interestId': interestId});
      rethrow;
    }
  }

  /// Create mutual interest (match) between two users
  static Future<void> createMutualInterest(
      String user1Id, String user2Id) async {
    try {
      EnhancedLogger.info('Creating mutual interest (match)',
          tag: 'VITRINE_INVITES', data: {'user1': user1Id, 'user2': user2Id});

      // Verificar se já existe interesse mútuo
      final existingMutual = await _checkMutualInterestExists(user1Id, user2Id);
      if (existingMutual) {
        EnhancedLogger.info('Mutual interest already exists',
            tag: 'VITRINE_INVITES', data: {'user1': user1Id, 'user2': user2Id});
        return;
      }

      // Criar interesse mútuo
      final mutualInterest = MutualInterestModel(
        user1Id: user1Id,
        user2Id: user2Id,
        matchedAt: DateTime.now(),
        chatEnabled: true,
        chatExpiresAt: DateTime.now().add(const Duration(days: 7)),
        movedToNossoProposito: false,
      );

      await _firestore
          .collection(_mutualInterestsCollection)
          .add(mutualInterest.toJson());

      // Marcar os interesses originais como processados
      await _markInterestsAsProcessed(user1Id, user2Id);

      EnhancedLogger.success('Mutual interest created successfully',
          tag: 'VITRINE_INVITES', data: {'user1': user1Id, 'user2': user2Id});
    } catch (e) {
      EnhancedLogger.error('Failed to create mutual interest',
          tag: 'VITRINE_INVITES',
          error: e,
          data: {'user1': user1Id, 'user2': user2Id});
      rethrow;
    }
  }

  /// Mark interests as processed after creating mutual interest
  static Future<void> _markInterestsAsProcessed(
      String user1Id, String user2Id) async {
    try {
      // Marcar interesse de user1 para user2
      final query1 = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: user1Id)
          .where('toUserId', isEqualTo: user2Id)
          .where('isActive', isEqualTo: true)
          .get();

      // Marcar interesse de user2 para user1
      final query2 = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: user2Id)
          .where('toUserId', isEqualTo: user1Id)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      final now = Timestamp.fromDate(DateTime.now());

      for (final doc in query1.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'processedAt': now,
          'processedReason': 'mutual_interest_created',
        });
      }

      for (final doc in query2.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'processedAt': now,
          'processedReason': 'mutual_interest_created',
        });
      }

      await batch.commit();

      EnhancedLogger.info('Interests marked as processed',
          tag: 'VITRINE_INVITES',
          data: {
            'user1': user1Id,
            'user2': user2Id,
            'processedCount': query1.docs.length + query2.docs.length
          });
    } catch (e) {
      EnhancedLogger.error('Failed to mark interests as processed',
          tag: 'VITRINE_INVITES',
          error: e,
          data: {'user1': user1Id, 'user2': user2Id});
    }
  }

  /// Get all profiles with spiritual certification seal
  static Future<List<SpiritualProfileModel>> getProfilesWithSeal() async {
    try {
      safePrint('🏆 Buscando perfis com selo espiritual');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('hasSinaisPreparationSeal', isEqualTo: true)
          .where('isProfileComplete', isEqualTo: true)
          .orderBy('sealObtainedAt', descending: true)
          .get();

      final profiles = querySnapshot.docs.map((doc) {
        final profile = SpiritualProfileModel.fromJson(doc.data());
        profile.id = doc.id;
        return profile;
      }).toList();

      safePrint('✅ Encontrados ${profiles.length} perfis com selo');
      return profiles;
    } catch (e) {
      safePrint('❌ Erro ao buscar perfis com selo: $e');
      return [];
    }
  }

  /// Get profiles by relationship status
  static Future<List<SpiritualProfileModel>> getProfilesByRelationshipStatus(
      RelationshipStatus status) async {
    try {
      safePrint('💑 Buscando perfis com status: ${status.name}');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('relationshipStatus', isEqualTo: status.name)
          .where('isProfileComplete', isEqualTo: true)
          .where('allowInteractions', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();

      final profiles = querySnapshot.docs.map((doc) {
        final profile = SpiritualProfileModel.fromJson(doc.data());
        profile.id = doc.id;
        return profile;
      }).toList();

      safePrint(
          '✅ Encontrados ${profiles.length} perfis com status ${status.name}');
      return profiles;
    } catch (e) {
      safePrint('❌ Erro ao buscar perfis por status: $e');
      return [];
    }
  }

  /// Block a user
  static Future<void> blockUser(String userIdToBlock) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      final updatedBlockedUsers = List<String>.from(profile.blockedUsers);
      if (!updatedBlockedUsers.contains(userIdToBlock)) {
        updatedBlockedUsers.add(userIdToBlock);

        await updateProfile(profile.id!, {
          'blockedUsers': updatedBlockedUsers,
        });

        safePrint('🚫 Usuário bloqueado: $userIdToBlock');
      }
    } catch (e) {
      safePrint('❌ Erro ao bloquear usuário: $e');
      rethrow;
    }
  }

  /// Unblock a user
  static Future<void> unblockUser(String userIdToUnblock) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      final updatedBlockedUsers = List<String>.from(profile.blockedUsers);
      updatedBlockedUsers.remove(userIdToUnblock);

      await updateProfile(profile.id!, {
        'blockedUsers': updatedBlockedUsers,
      });

      safePrint('✅ Usuário desbloqueado: $userIdToUnblock');
    } catch (e) {
      safePrint('❌ Erro ao desbloquear usuário: $e');
      rethrow;
    }
  }

  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final profile = await getCurrentUserProfile();
      if (profile == null) return false;

      return profile.blockedUsers.contains(userId);
    } catch (e) {
      safePrint('❌ Erro ao verificar bloqueio: $e');
      return false;
    }
  }

  /// Delete spiritual profile
  static Future<void> deleteProfile(String profileId) async {
    try {
      safePrint('🗑️ Deletando perfil espiritual: $profileId');

      await _firestore.collection(_collection).doc(profileId).delete();

      safePrint('✅ Perfil espiritual deletado: $profileId');
    } catch (e) {
      safePrint('❌ Erro ao deletar perfil espiritual: $e');
      rethrow;
    }
  }

  /// Get completion statistics
  static Future<Map<String, int>> getCompletionStatistics() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();

      int totalProfiles = querySnapshot.docs.length;
      int completedProfiles = 0;
      int profilesWithSeal = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['isProfileComplete'] == true) {
          completedProfiles++;
        }
        if (data['hasSinaisPreparationSeal'] == true) {
          profilesWithSeal++;
        }
      }

      return {
        'total': totalProfiles,
        'completed': completedProfiles,
        'withSeal': profilesWithSeal,
      };
    } catch (e) {
      safePrint('❌ Erro ao obter estatísticas: $e');
      return {'total': 0, 'completed': 0, 'withSeal': 0};
    }
  }

  // Interest Management Methods

  /// Add interest from one user to another
  static Future<InterestModel> addInterest(
      String fromUserId, String toUserId) async {
    try {
      final interest = InterestModel(
        fromUserId: fromUserId,
        toUserId: toUserId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      final docRef = await _firestore
          .collection(_interestsCollection)
          .add(interest.toJson());

      final createdInterest = interest.copyWith(id: docRef.id);

      // Check if this creates mutual interest
      await _checkAndCreateMutualInterest(fromUserId, toUserId);

      EnhancedLogger.info('Interest added',
          tag: 'INTEREST',
          data: {'from': fromUserId, 'to': toUserId, 'id': docRef.id});

      return createdInterest;
    } catch (e) {
      EnhancedLogger.error('Failed to add interest',
          tag: 'INTEREST',
          error: e,
          data: {'from': fromUserId, 'to': toUserId});
      rethrow;
    }
  }

  /// Remove interest from one user to another
  static Future<void> removeInterest(String fromUserId, String toUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({'isActive': false});
      }

      // Remove mutual interest if it exists
      await _removeMutualInterest(fromUserId, toUserId);

      EnhancedLogger.info('Interest removed',
          tag: 'INTEREST', data: {'from': fromUserId, 'to': toUserId});
    } catch (e) {
      EnhancedLogger.error('Failed to remove interest',
          tag: 'INTEREST',
          error: e,
          data: {'from': fromUserId, 'to': toUserId});
      rethrow;
    }
  }

  /// Get interest between two users
  static Future<InterestModel?> getInterest(
      String fromUserId, String toUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_interestsCollection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return InterestModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    } catch (e) {
      EnhancedLogger.error('Failed to get interest',
          tag: 'INTEREST',
          error: e,
          data: {'from': fromUserId, 'to': toUserId});
      return null;
    }
  }

  /// Get mutual interest between two users
  static Future<MutualInterestModel?> getMutualInterest(
      String user1Id, String user2Id) async {
    try {
      // Try both combinations since mutual interest can be stored either way
      final querySnapshot1 = await _firestore
          .collection(_mutualInterestsCollection)
          .where('user1Id', isEqualTo: user1Id)
          .where('user2Id', isEqualTo: user2Id)
          .limit(1)
          .get();

      if (querySnapshot1.docs.isNotEmpty) {
        final doc = querySnapshot1.docs.first;
        return MutualInterestModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }

      final querySnapshot2 = await _firestore
          .collection(_mutualInterestsCollection)
          .where('user1Id', isEqualTo: user2Id)
          .where('user2Id', isEqualTo: user1Id)
          .limit(1)
          .get();

      if (querySnapshot2.docs.isNotEmpty) {
        final doc = querySnapshot2.docs.first;
        return MutualInterestModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return null;
    } catch (e) {
      EnhancedLogger.error('Failed to get mutual interest',
          tag: 'MUTUAL_INTEREST',
          error: e,
          data: {'user1': user1Id, 'user2': user2Id});
      return null;
    }
  }

  /// Check and create mutual interest if both users are interested
  static Future<void> _checkAndCreateMutualInterest(
      String user1Id, String user2Id) async {
    try {
      // Check if user2 also has interest in user1
      final reverseInterest = await getInterest(user2Id, user1Id);

      if (reverseInterest != null) {
        // Create mutual interest
        final mutualInterest = MutualInterestModel(
          user1Id: user1Id,
          user2Id: user2Id,
          matchedAt: DateTime.now(),
          chatEnabled: true,
          chatExpiresAt: DateTime.now().add(const Duration(days: 7)),
          movedToNossoProposito: false,
        );

        await _firestore
            .collection(_mutualInterestsCollection)
            .add(mutualInterest.toJson());

        EnhancedLogger.success('Mutual interest created',
            tag: 'MUTUAL_INTEREST', data: {'user1': user1Id, 'user2': user2Id});
      }
    } catch (e) {
      EnhancedLogger.error('Failed to check/create mutual interest',
          tag: 'MUTUAL_INTEREST',
          error: e,
          data: {'user1': user1Id, 'user2': user2Id});
    }
  }

  /// Remove mutual interest
  static Future<void> _removeMutualInterest(
      String user1Id, String user2Id) async {
    try {
      // Try both combinations
      final querySnapshot1 = await _firestore
          .collection(_mutualInterestsCollection)
          .where('user1Id', isEqualTo: user1Id)
          .where('user2Id', isEqualTo: user2Id)
          .get();

      for (final doc in querySnapshot1.docs) {
        await doc.reference.delete();
      }

      final querySnapshot2 = await _firestore
          .collection(_mutualInterestsCollection)
          .where('user1Id', isEqualTo: user2Id)
          .where('user2Id', isEqualTo: user1Id)
          .get();

      for (final doc in querySnapshot2.docs) {
        await doc.reference.delete();
      }

      EnhancedLogger.info('Mutual interest removed',
          tag: 'MUTUAL_INTEREST', data: {'user1': user1Id, 'user2': user2Id});
    } catch (e) {
      EnhancedLogger.error('Failed to remove mutual interest',
          tag: 'MUTUAL_INTEREST',
          error: e,
          data: {'user1': user1Id, 'user2': user2Id});
    }
  }
}
