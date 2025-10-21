import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utilitário para debugar favoritos em tempo real
class DebugFavorites {
  
  /// Mostra todos os favoritos do usuário atual com detalhes
  static Future<void> showAllFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ DEBUG: Usuário não logado');
      return;
    }
    
    print('\n' + '🔍' * 50);
    print('📋 DEBUG: TODOS OS FAVORITOS DO USUÁRIO');
    print('👤 User ID: $userId');
    print('🔍' * 50);
    
    try {
      final allFavorites = await FirebaseFirestore.instance
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 Total de favoritos encontrados: ${allFavorites.docs.length}');
      
      if (allFavorites.docs.isEmpty) {
        print('ℹ️ Nenhum favorito encontrado');
        return;
      }
      
      // Agrupar por contexto
      final contextGroups = <String, List<Map<String, dynamic>>>{};
      
      for (int i = 0; i < allFavorites.docs.length; i++) {
        final doc = allFavorites.docs[i];
        final data = doc.data();
        
        final context = data['contexto'] as String? ?? 'NULL';
        final storyId = data['storyId'] as String? ?? 'NULL';
        final dataCadastro = data['dataCadastro'] as Timestamp?;
        
        final favoriteInfo = {
          'index': i + 1,
          'docId': doc.id,
          'storyId': storyId,
          'contexto': context,
          'data': dataCadastro?.toDate().toString() ?? 'NULL',
        };
        
        contextGroups[context] ??= [];
        contextGroups[context]!.add(favoriteInfo);
        
        print('${i + 1}. Doc: ${doc.id}');
        print('   📖 Story: $storyId');
        print('   🏷️ Contexto: "$context"');
        print('   📅 Data: ${dataCadastro?.toDate().toString() ?? 'NULL'}');
        print('');
      }
      
      print('📊 RESUMO POR CONTEXTO:');
      contextGroups.forEach((context, favorites) {
        print('   🏷️ "$context": ${favorites.length} favoritos');
        for (final fav in favorites) {
          print('      - Story: ${fav['storyId']} (Doc: ${fav['docId']})');
        }
      });
      
      print('🔍' * 50 + '\n');
      
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar favoritos: $e');
    }
  }
  
  /// Mostra favoritos de um contexto específico
  static Future<void> showFavoritesByContext(String contexto) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ DEBUG: Usuário não logado');
      return;
    }
    
    print('\n' + '🔍' * 50);
    print('📋 DEBUG: FAVORITOS DO CONTEXTO "$contexto"');
    print('👤 User ID: $userId');
    print('🔍' * 50);
    
    try {
      final contextFavorites = await FirebaseFirestore.instance
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .where('contexto', isEqualTo: contexto)
          .get();
      
      print('📊 Favoritos encontrados para "$contexto": ${contextFavorites.docs.length}');
      
      if (contextFavorites.docs.isEmpty) {
        print('ℹ️ Nenhum favorito encontrado para este contexto');
        
        // Verificar se há favoritos com contexto similar
        print('\n🔍 Verificando contextos similares...');
        await _checkSimilarContexts(userId, contexto);
        
        return;
      }
      
      for (int i = 0; i < contextFavorites.docs.length; i++) {
        final doc = contextFavorites.docs[i];
        final data = doc.data();
        
        print('${i + 1}. Doc: ${doc.id}');
        print('   📖 Story: ${data['storyId']}');
        print('   🏷️ Contexto: "${data['contexto']}"');
        print('   📅 Data: ${(data['dataCadastro'] as Timestamp?)?.toDate().toString() ?? 'NULL'}');
        print('');
      }
      
      print('🔍' * 50 + '\n');
      
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar favoritos por contexto: $e');
    }
  }
  
  /// Verifica contextos similares
  static Future<void> _checkSimilarContexts(String userId, String targetContext) async {
    try {
      final allFavorites = await FirebaseFirestore.instance
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      final foundContexts = <String>{};
      
      for (final doc in allFavorites.docs) {
        final data = doc.data();
        final context = data['contexto'] as String? ?? 'NULL';
        foundContexts.add(context);
      }
      
      print('🏷️ Contextos encontrados: ${foundContexts.toList()}');
      
      // Verificar se há contextos que deveriam ser o target
      for (final context in foundContexts) {
        if (context.toLowerCase().contains(targetContext.toLowerCase()) ||
            targetContext.toLowerCase().contains(context.toLowerCase())) {
          print('⚠️ POSSÍVEL PROBLEMA: Contexto "$context" pode ser relacionado a "$targetContext"');
        }
      }
      
    } catch (e) {
      print('❌ DEBUG: Erro ao verificar contextos similares: $e');
    }
  }
  
  /// Monitora favoritos em tempo real
  static void monitorFavorites() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ DEBUG: Usuário não logado');
      return;
    }
    
    print('🔄 DEBUG: Iniciando monitoramento de favoritos...');
    
    FirebaseFirestore.instance
        .collection('story_favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      
      print('\n📡 MONITOR: Mudança detectada nos favoritos');
      print('📊 Total atual: ${snapshot.docs.length} favoritos');
      
      final contextCounts = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final context = data['contexto'] as String? ?? 'NULL';
        contextCounts[context] = (contextCounts[context] ?? 0) + 1;
      }
      
      print('📊 Por contexto:');
      contextCounts.forEach((context, count) {
        print('   - "$context": $count');
      });
      
      print('⏰ ${DateTime.now().toString()}\n');
    });
  }
  
  /// Força limpeza de favoritos duplicados ou inválidos
  static Future<void> cleanupFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ DEBUG: Usuário não logado');
      return;
    }
    
    print('🧹 DEBUG: Iniciando limpeza de favoritos...');
    
    try {
      final allFavorites = await FirebaseFirestore.instance
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      final validContexts = ['principal', 'sinais_rebeca', 'sinais_isaque'];
      int cleanedCount = 0;
      
      for (final doc in allFavorites.docs) {
        final data = doc.data();
        final context = data['contexto'] as String?;
        final storyId = data['storyId'] as String?;
        
        bool shouldDelete = false;
        String reason = '';
        
        if (context == null || context.isEmpty) {
          shouldDelete = true;
          reason = 'Contexto nulo ou vazio';
        } else if (!validContexts.contains(context)) {
          shouldDelete = true;
          reason = 'Contexto inválido: "$context"';
        } else if (storyId == null || storyId.isEmpty) {
          shouldDelete = true;
          reason = 'StoryId nulo ou vazio';
        }
        
        if (shouldDelete) {
          print('🗑️ Removendo favorito inválido: ${doc.id} - $reason');
          await doc.reference.delete();
          cleanedCount++;
        }
      }
      
      print('✅ Limpeza concluída: $cleanedCount favoritos removidos');
      
    } catch (e) {
      print('❌ DEBUG: Erro durante limpeza: $e');
    }
  }
}