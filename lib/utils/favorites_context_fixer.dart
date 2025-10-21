import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/context_validator.dart';
import '../utils/context_debug.dart';

/// Utilitário para diagnosticar e corrigir problemas de contexto nos favoritos
class FavoritesContextFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Diagnostica problemas de contexto nos favoritos do usuário atual
  static Future<Map<String, dynamic>> diagnoseFavoritesContext() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return {
        'error': 'Usuário não logado',
        'canProceed': false,
      };
    }
    
    print('🔍 DIAGNÓSTICO: Iniciando análise de favoritos para usuário $userId');
    
    try {
      // Buscar TODOS os favoritos do usuário (sem filtro de contexto)
      final allFavoritesQuery = await _firestore
          .collection('story_favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      final report = <String, dynamic>{};
      report['userId'] = userId;
      report['totalFavorites'] = allFavoritesQuery.docs.length;
      report['timestamp'] = DateTime.now().toIso8601String();
      
      // Analisar favoritos por contexto
      final contextDistribution = <String, List<Map<String, dynamic>>>{};
      final invalidFavorites = <Map<String, dynamic>>[];
      
      for (final doc in allFavoritesQuery.docs) {
        final data = doc.data();
        final docContext = data['contexto'] as String?;
        final storyId = data['storyId'] as String?;
        final dataCadastro = data['dataCadastro'] as Timestamp?;
        
        final favoriteInfo = {
          'docId': doc.id,
          'storyId': storyId,
          'contexto': docContext,
          'dataCadastro': dataCadastro?.toDate().toIso8601String(),
        };
        
        // Validar contexto
        if (docContext == null || !ContextValidator.isValidContext(docContext)) {
          invalidFavorites.add({
            ...favoriteInfo,
            'problem': 'Contexto inválido ou nulo: "$docContext"',
          });
        } else {
          // Agrupar por contexto
          contextDistribution[docContext] ??= [];
          contextDistribution[docContext]!.add(favoriteInfo);
        }
      }
      
      report['contextDistribution'] = contextDistribution;
      report['invalidFavorites'] = invalidFavorites;
      
      // Estatísticas
      report['validFavorites'] = allFavoritesQuery.docs.length - invalidFavorites.length;
      report['invalidCount'] = invalidFavorites.length;
      
      // Análise por contexto específico
      final contextAnalysis = <String, dynamic>{};
      for (final context in ContextValidator.getValidContexts()) {
        final contextFavorites = contextDistribution[context] ?? [];
        contextAnalysis[context] = {
          'count': contextFavorites.length,
          'favorites': contextFavorites,
        };
      }
      report['contextAnalysis'] = contextAnalysis;
      
      // Recomendações
      final recommendations = <String>[];
      
      if (invalidFavorites.isNotEmpty) {
        recommendations.add('🚨 CRÍTICO: ${invalidFavorites.length} favoritos com contexto inválido encontrados');
        recommendations.add('🔧 AÇÃO: Execute fixInvalidFavorites() para corrigir');
      }
      
      // Verificar vazamentos entre contextos
      for (final context in ContextValidator.getValidContexts()) {
        final contextFavorites = contextDistribution[context] ?? [];
        if (contextFavorites.isNotEmpty) {
          recommendations.add('ℹ️ INFO: ${contextFavorites.length} favoritos encontrados para contexto "$context"');
        }
      }
      
      if (recommendations.isEmpty) {
        recommendations.add('✅ OK: Nenhum problema detectado nos favoritos');
      }
      
      report['recommendations'] = recommendations;
      report['canProceed'] = true;
      
      return report;
      
    } catch (e) {
      return {
        'error': 'Erro durante diagnóstico: $e',
        'canProceed': false,
      };
    }
  }
  
  /// Corrige favoritos com contexto inválido
  static Future<Map<String, dynamic>> fixInvalidFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return {
        'error': 'Usuário não logado',
        'success': false,
      };
    }
    
    print('🔧 CORREÇÃO: Iniciando correção de favoritos inválidos');
    
    try {
      // Primeiro, diagnosticar
      final diagnosis = await diagnoseFavoritesContext();
      if (diagnosis['error'] != null) {
        return diagnosis;
      }
      
      final invalidFavorites = diagnosis['invalidFavorites'] as List<Map<String, dynamic>>;
      
      if (invalidFavorites.isEmpty) {
        return {
          'message': 'Nenhum favorito inválido encontrado',
          'success': true,
          'fixedCount': 0,
        };
      }
      
      int fixedCount = 0;
      final fixedFavorites = <Map<String, dynamic>>[];
      final failedFixes = <Map<String, dynamic>>[];
      
      for (final favorite in invalidFavorites) {
        try {
          final docId = favorite['docId'] as String;
          final storyId = favorite['storyId'] as String?;
          
          if (storyId == null) {
            failedFixes.add({
              ...favorite,
              'reason': 'StoryId é nulo',
            });
            continue;
          }
          
          // Tentar determinar o contexto correto baseado no story
          String? correctContext = await _determineCorrectContext(storyId);
          
          if (correctContext == null) {
            // Se não conseguir determinar, usar contexto padrão
            correctContext = 'principal';
          }
          
          // Atualizar o documento
          await _firestore
              .collection('story_favorites')
              .doc(docId)
              .update({'contexto': correctContext});
          
          fixedFavorites.add({
            ...favorite,
            'newContext': correctContext,
          });
          
          fixedCount++;
          
          print('✅ CORREÇÃO: Favorito $docId corrigido para contexto "$correctContext"');
          
        } catch (e) {
          failedFixes.add({
            ...favorite,
            'reason': 'Erro ao corrigir: $e',
          });
          print('❌ CORREÇÃO: Erro ao corrigir favorito ${favorite['docId']}: $e');
        }
      }
      
      return {
        'success': true,
        'fixedCount': fixedCount,
        'totalInvalid': invalidFavorites.length,
        'fixedFavorites': fixedFavorites,
        'failedFixes': failedFixes,
        'message': 'Correção concluída: $fixedCount de ${invalidFavorites.length} favoritos corrigidos',
      };
      
    } catch (e) {
      return {
        'error': 'Erro durante correção: $e',
        'success': false,
      };
    }
  }
  
  /// Tenta determinar o contexto correto baseado no story
  static Future<String?> _determineCorrectContext(String storyId) async {
    try {
      // Tentar encontrar o story nas diferentes coleções
      final collections = [
        {'name': 'stories_files', 'context': 'principal'},
        {'name': 'stories_sinais_rebeca', 'context': 'sinais_rebeca'},
        {'name': 'stories_sinais_isaque', 'context': 'sinais_isaque'},
      ];
      
      for (final collection in collections) {
        try {
          final doc = await _firestore
              .collection(collection['name']!)
              .doc(storyId)
              .get();
          
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            final storyContext = data?['contexto'] as String?;
            
            // Se o story tem contexto definido, usar ele
            if (storyContext != null && ContextValidator.isValidContext(storyContext)) {
              return storyContext;
            }
            
            // Senão, usar o contexto da coleção
            return collection['context'];
          }
        } catch (e) {
          print('⚠️ CORREÇÃO: Erro ao buscar story $storyId na coleção ${collection['name']}: $e');
        }
      }
      
      return null; // Não encontrou o story
      
    } catch (e) {
      print('❌ CORREÇÃO: Erro ao determinar contexto para story $storyId: $e');
      return null;
    }
  }
  
  /// Imprime relatório de diagnóstico formatado
  static void printDiagnosisReport(Map<String, dynamic> report) {
    print('\n' + '🔍' * 20);
    print('📋 RELATÓRIO DE DIAGNÓSTICO DE FAVORITOS');
    print('🔍' * 20);
    
    if (report['error'] != null) {
      print('❌ ERRO: ${report['error']}');
      return;
    }
    
    print('👤 Usuário: ${report['userId']}');
    print('📊 Total de favoritos: ${report['totalFavorites']}');
    print('✅ Favoritos válidos: ${report['validFavorites']}');
    print('❌ Favoritos inválidos: ${report['invalidCount']}');
    
    print('\n📊 DISTRIBUIÇÃO POR CONTEXTO:');
    final contextAnalysis = report['contextAnalysis'] as Map<String, dynamic>;
    contextAnalysis.forEach((context, data) {
      final count = data['count'] as int;
      print('   - $context: $count favoritos');
    });
    
    if (report['invalidCount'] > 0) {
      print('\n❌ FAVORITOS INVÁLIDOS:');
      final invalidFavorites = report['invalidFavorites'] as List<dynamic>;
      for (final favorite in invalidFavorites) {
        print('   - Doc: ${favorite['docId']}, Story: ${favorite['storyId']}, Problema: ${favorite['problem']}');
      }
    }
    
    print('\n💡 RECOMENDAÇÕES:');
    final recommendations = report['recommendations'] as List<dynamic>;
    for (final rec in recommendations) {
      print('   $rec');
    }
    
    print('🔍' * 20 + '\n');
  }
}