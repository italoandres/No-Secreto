import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Script para corrigir perfis que estão 100% completos mas com isProfileComplete: false
/// 
/// Este problema ocorreu porque a lógica antiga verificava TODAS as tarefas incluindo
/// a certificação que é OPCIONAL. Perfis com todas as tarefas obrigatórias completas
/// mas sem certificação ficavam com isProfileComplete: false.
class FixCompletedProfiles {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'spiritual_profiles';

  /// Corrige todos os perfis que estão completos mas marcados como incompletos
  static Future<Map<String, dynamic>> fixAllProfiles() async {
    try {
      debugPrint('🔧 Iniciando correção de perfis completos...');
      
      // Buscar perfis marcados como incompletos
      final snapshot = await _firestore
          .collection(_collection)
          .where('isProfileComplete', isEqualTo: false)
          .get();
      
      debugPrint('📊 Total de perfis incompletos encontrados: ${snapshot.docs.length}');
      
      int fixed = 0;
      int alreadyIncomplete = 0;
      final List<String> fixedProfileIds = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tasks = data['completionTasks'] as Map<String, dynamic>?;
        
        if (tasks != null) {
          // Verificar apenas tarefas obrigatórias
          final requiredTasks = ['photos', 'identity', 'biography', 'preferences'];
          final allCompleted = requiredTasks.every((task) => tasks[task] == true);
          
          if (allCompleted) {
            // Perfil está completo mas marcado como incompleto - CORRIGIR
            await doc.reference.update({
              'isProfileComplete': true,
              'profileCompletedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            fixed++;
            fixedProfileIds.add(doc.id);
            
            debugPrint('✅ Perfil corrigido: ${doc.id}');
            debugPrint('   - userId: ${data['userId']}');
            debugPrint('   - Tarefas: $tasks');
          } else {
            // Perfil realmente está incompleto
            alreadyIncomplete++;
            
            final missingTasks = requiredTasks.where((task) => tasks[task] != true).toList();
            debugPrint('⚪ Perfil incompleto (correto): ${doc.id}');
            debugPrint('   - Tarefas faltando: $missingTasks');
          }
        }
      }
      
      final result = {
        'success': true,
        'totalChecked': snapshot.docs.length,
        'fixed': fixed,
        'alreadyIncomplete': alreadyIncomplete,
        'fixedProfileIds': fixedProfileIds,
      };
      
      debugPrint('');
      debugPrint('🎉 Correção finalizada!');
      debugPrint('📊 Resumo:');
      debugPrint('   - Total verificados: ${snapshot.docs.length}');
      debugPrint('   - Perfis corrigidos: $fixed');
      debugPrint('   - Perfis realmente incompletos: $alreadyIncomplete');
      
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao corrigir perfis: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return {
        'success': false,
        'error': e.toString(),
        'fixed': 0,
      };
    }
  }

  /// Corrige um perfil específico por userId
  static Future<bool> fixProfileByUserId(String userId) async {
    try {
      debugPrint('🔧 Corrigindo perfil do usuário: $userId');
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('❌ Perfil não encontrado para userId: $userId');
        return false;
      }
      
      final doc = snapshot.docs.first;
      final data = doc.data();
      final tasks = data['completionTasks'] as Map<String, dynamic>?;
      
      if (tasks == null) {
        debugPrint('❌ Perfil sem tarefas: $userId');
        return false;
      }
      
      // Verificar apenas tarefas obrigatórias
      final requiredTasks = ['photos', 'identity', 'biography', 'preferences'];
      final allCompleted = requiredTasks.every((task) => tasks[task] == true);
      
      if (!allCompleted) {
        final missingTasks = requiredTasks.where((task) => tasks[task] != true).toList();
        debugPrint('⚪ Perfil realmente incompleto');
        debugPrint('   - Tarefas faltando: $missingTasks');
        return false;
      }
      
      // Verificar se já está marcado como completo
      if (data['isProfileComplete'] == true) {
        debugPrint('✅ Perfil já está marcado como completo');
        return true;
      }
      
      // Corrigir perfil
      await doc.reference.update({
        'isProfileComplete': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Perfil corrigido com sucesso!');
      debugPrint('   - profileId: ${doc.id}');
      debugPrint('   - userId: $userId');
      
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao corrigir perfil: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Verifica quantos perfis precisam ser corrigidos (sem fazer correção)
  static Future<Map<String, dynamic>> checkProfilesNeedingFix() async {
    try {
      debugPrint('🔍 Verificando perfis que precisam de correção...');
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('isProfileComplete', isEqualTo: false)
          .get();
      
      int needsFix = 0;
      int reallyIncomplete = 0;
      final List<Map<String, dynamic>> profilesNeedingFix = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tasks = data['completionTasks'] as Map<String, dynamic>?;
        
        if (tasks != null) {
          final requiredTasks = ['photos', 'identity', 'biography', 'preferences'];
          final allCompleted = requiredTasks.every((task) => tasks[task] == true);
          
          if (allCompleted) {
            needsFix++;
            profilesNeedingFix.add({
              'profileId': doc.id,
              'userId': data['userId'],
              'tasks': tasks,
            });
          } else {
            reallyIncomplete++;
          }
        }
      }
      
      final result = {
        'totalIncomplete': snapshot.docs.length,
        'needsFix': needsFix,
        'reallyIncomplete': reallyIncomplete,
        'profiles': profilesNeedingFix,
      };
      
      debugPrint('📊 Resultado da verificação:');
      debugPrint('   - Total de perfis incompletos: ${snapshot.docs.length}');
      debugPrint('   - Precisam de correção: $needsFix');
      debugPrint('   - Realmente incompletos: $reallyIncomplete');
      
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao verificar perfis: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return {
        'error': e.toString(),
        'needsFix': 0,
      };
    }
  }
}
