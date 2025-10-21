import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/context_validator.dart';

/// Função simples para diagnosticar e corrigir favoritos
class FixFavoritesContext {
  
  /// Executa diagnóstico e correção dos favoritos
  static Future<void> runFix() async {
    print('🔧 INICIANDO CORREÇÃO DE FAVORITOS...');
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ ERRO: Usuário não logado');
      return;
    }
    
    try {
      // Buscar TODOS os favoritos do usuário
      final allFavorites = await FirebaseFirestore.instance
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 Total de favoritos encontrados: ${allFavorites.docs.length}');
      
      if (allFavorites.docs.isEmpty) {
        print('ℹ️ Nenhum favorito encontrado para corrigir');
        return;
      }
      
      // Analisar e corrigir cada favorito
      int correctedCount = 0;
      int validCount = 0;
      
      for (final doc in allFavorites.docs) {
        final data = doc.data();
        final currentContext = data['contexto'] as String?;
        final storyId = data['storyId'] as String?;
        
        print('🔍 Analisando favorito: Doc=${doc.id}, Story=$storyId, Contexto="$currentContext"');
        
        // Verificar se o contexto é válido
        if (currentContext != null && ContextValidator.isValidContext(currentContext)) {
          validCount++;
          print('   ✅ Contexto válido: "$currentContext"');
          continue;
        }
        
        // Contexto inválido - tentar corrigir
        print('   ❌ Contexto inválido: "$currentContext" - tentando corrigir...');
        
        if (storyId == null) {
          print('   ⚠️ StoryId é nulo - pulando');
          continue;
        }
        
        // Tentar determinar contexto correto
        String? correctContext = await _findStoryContext(storyId);
        
        if (correctContext == null) {
          correctContext = 'principal'; // Fallback
          print('   ⚠️ Não foi possível determinar contexto - usando "principal"');
        } else {
          print('   🎯 Contexto correto determinado: "$correctContext"');
        }
        
        // Atualizar o documento
        try {
          await doc.reference.update({'contexto': correctContext});
          correctedCount++;
          print('   ✅ Favorito corrigido para contexto "$correctContext"');
        } catch (e) {
          print('   ❌ Erro ao corrigir favorito: $e');
        }
      }
      
      print('\n📋 RESUMO DA CORREÇÃO:');
      print('   📊 Total analisado: ${allFavorites.docs.length}');
      print('   ✅ Já válidos: $validCount');
      print('   🔧 Corrigidos: $correctedCount');
      print('   ❌ Falhas: ${allFavorites.docs.length - validCount - correctedCount}');
      
      if (correctedCount > 0) {
        print('\n🎉 CORREÇÃO CONCLUÍDA! $correctedCount favoritos foram corrigidos.');
        print('💡 Agora teste novamente o isolamento de contextos.');
      } else {
        print('\n✅ Nenhuma correção necessária - todos os favoritos já estão corretos.');
      }
      
    } catch (e) {
      print('❌ ERRO durante correção: $e');
    }
  }
  
  /// Tenta encontrar o contexto correto do story
  static Future<String?> _findStoryContext(String storyId) async {
    try {
      // Lista de coleções para verificar
      final collections = [
        {'name': 'stories_files', 'context': 'principal'},
        {'name': 'stories_sinais_rebeca', 'context': 'sinais_rebeca'},
        {'name': 'stories_sinais_isaque', 'context': 'sinais_isaque'},
      ];
      
      for (final collection in collections) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(collection['name']!)
              .doc(storyId)
              .get();
          
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            final storyContext = data?['contexto'] as String?;
            
            print('     📍 Story encontrado na coleção "${collection['name']}" com contexto "$storyContext"');
            
            // Se o story tem contexto válido, usar ele
            if (storyContext != null && ContextValidator.isValidContext(storyContext)) {
              return storyContext;
            }
            
            // Senão, usar o contexto padrão da coleção
            return collection['context'];
          }
        } catch (e) {
          print('     ⚠️ Erro ao verificar coleção ${collection['name']}: $e');
        }
      }
      
      print('     ❌ Story não encontrado em nenhuma coleção');
      return null;
      
    } catch (e) {
      print('     ❌ Erro ao buscar story: $e');
      return null;
    }
  }
  
  /// Diagnóstico rápido sem correção
  static Future<void> diagnose() async {
    print('🔍 DIAGNÓSTICO DE FAVORITOS...');
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ ERRO: Usuário não logado');
      return;
    }
    
    try {
      final allFavorites = await FirebaseFirestore.instance
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📊 Total de favoritos: ${allFavorites.docs.length}');
      
      // Agrupar por contexto
      final contextGroups = <String, int>{};
      final invalidFavorites = <String>[];
      
      for (final doc in allFavorites.docs) {
        final data = doc.data();
        final context = data['contexto'] as String?;
        final storyId = data['storyId'] as String?;
        
        if (context == null || !ContextValidator.isValidContext(context)) {
          invalidFavorites.add('Doc: ${doc.id}, Story: $storyId, Contexto: "$context"');
        } else {
          contextGroups[context] = (contextGroups[context] ?? 0) + 1;
        }
      }
      
      print('\n📊 DISTRIBUIÇÃO POR CONTEXTO:');
      contextGroups.forEach((context, count) {
        print('   - $context: $count favoritos');
      });
      
      if (invalidFavorites.isNotEmpty) {
        print('\n❌ FAVORITOS INVÁLIDOS (${invalidFavorites.length}):');
        for (final invalid in invalidFavorites) {
          print('   - $invalid');
        }
        print('\n💡 Execute FixFavoritesContext.runFix() para corrigir');
      } else {
        print('\n✅ Todos os favoritos estão com contexto válido!');
      }
      
    } catch (e) {
      print('❌ ERRO durante diagnóstico: $e');
    }
  }
}