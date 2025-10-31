import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/utils/debug_utils.dart';

class StoriesHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Move stories expirados (24h+) para o histórico
  Future<void> moveExpiredStoriesToHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      safePrint(
          '🕒 HISTORY: Verificando stories expirados para usuário ${user.uid}');

      // Data limite: 24 horas atrás
      final cutoffTime = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 24)));

      // Buscar stories expirados em todas as coleções
      final collections = [
        'stories_files',
        'stories_sinais_rebeca',
        'stories_sinais_isaque'
      ];

      for (String collection in collections) {
        await _moveExpiredFromCollection(collection, cutoffTime, user.uid);
      }
    } catch (e) {
      safePrint('❌ HISTORY ERROR: Erro ao mover stories expirados: $e');
    }
  }

  /// Move stories expirados de uma coleção específica
  Future<void> _moveExpiredFromCollection(
      String collection, Timestamp cutoffTime, String userId) async {
    try {
      safePrint('🔍 HISTORY: Verificando coleção $collection');

      final query = await _firestore
          .collection(collection)
          .where('dataCadastro', isLessThan: cutoffTime)
          .get();

      safePrint(
          '📊 HISTORY: Encontrados ${query.docs.length} stories expirados em $collection');

      int movedCount = 0;
      int skippedCount = 0;

      for (var doc in query.docs) {
        final data = doc.data();
        
        // 🔒 PROTEÇÃO: NÃO deletar stories com favoritos
        final hasFavorites = data['hasFavorites'] ?? false;
        
        if (hasFavorites) {
          safePrint('⭐ HISTORY: Story ${doc.id} tem favoritos - PRESERVADO');
          skippedCount++;
          continue;
        }
        
        await moveStoryToHistory(doc.id, collection, data);
        movedCount++;
      }

      safePrint(
          '✅ HISTORY: $collection - Movidos: $movedCount | Preservados (favoritos): $skippedCount');
    } catch (e) {
      safePrint('❌ HISTORY ERROR: Erro ao processar coleção $collection: $e');
    }
  }

  /// Move um story específico para o histórico
  Future<void> moveStoryToHistory(String storyId, String sourceCollection,
      Map<String, dynamic> storyData) async {
    try {
      safePrint(
          '📦 HISTORY: Movendo story $storyId de $sourceCollection para histórico');

      // Adicionar metadados do histórico
      final historyData = {
        ...storyData,
        'originalCollection': sourceCollection,
        'movedToHistoryAt': Timestamp.now(),
        'originalStoryId': storyId,
      };

      // Salvar no histórico
      await _firestore
          .collection('stories_antigos')
          .doc(storyId)
          .set(historyData);

      // Remover da coleção original
      await _firestore.collection(sourceCollection).doc(storyId).delete();

      safePrint('✅ HISTORY: Story $storyId movido com sucesso para o histórico');
    } catch (e) {
      safePrint('❌ HISTORY ERROR: Erro ao mover story $storyId: $e');
      rethrow;
    }
  }

  /// Recupera stories do histórico do usuário
  Future<List<Map<String, dynamic>>> getHistoryStories({
    int limit = 50,
    String? lastDocumentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      safePrint('📚 HISTORY: Carregando histórico de stories para ${user.uid}');

      Query query = _firestore
          .collection('stories_antigos')
          .orderBy('movedToHistoryAt', descending: true)
          .limit(limit);

      // Paginação
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('stories_antigos')
            .doc(lastDocumentId)
            .get();

        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();

      final stories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      safePrint('📊 HISTORY: Carregados ${stories.length} stories do histórico');
      return stories;
    } catch (e) {
      safePrint('❌ HISTORY ERROR: Erro ao carregar histórico: $e');
      return [];
    }
  }

  /// Limpa stories muito antigos do histórico (opcional - manter apenas últimos 30 dias)
  Future<void> cleanOldHistoryStories({int daysToKeep = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      safePrint('🧹 HISTORY: Limpando stories antigos (>${daysToKeep} dias)');

      final cutoffTime = Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: daysToKeep)));

      final query = await _firestore
          .collection('stories_antigos')
          .where('movedToHistoryAt', isLessThan: cutoffTime)
          .get();

      safePrint(
          '🗑️ HISTORY: Encontrados ${query.docs.length} stories para limpeza');

      // Deletar em lotes para performance
      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      safePrint('✅ HISTORY: Limpeza concluída');
    } catch (e) {
      safePrint('❌ HISTORY ERROR: Erro na limpeza: $e');
    }
  }

  /// Restaura um story do histórico (se necessário)
  Future<void> restoreStoryFromHistory(String historyStoryId) async {
    try {
      safePrint('🔄 HISTORY: Restaurando story $historyStoryId do histórico');

      final historyDoc = await _firestore
          .collection('stories_antigos')
          .doc(historyStoryId)
          .get();

      if (!historyDoc.exists) {
        throw Exception('Story não encontrado no histórico');
      }

      final data = historyDoc.data()!;
      final originalCollection = data['originalCollection'] as String;

      // Remover metadados do histórico
      data.remove('originalCollection');
      data.remove('movedToHistoryAt');
      data.remove('originalStoryId');

      // Restaurar na coleção original
      await _firestore
          .collection(originalCollection)
          .doc(historyStoryId)
          .set(data);

      // Remover do histórico
      await _firestore
          .collection('stories_antigos')
          .doc(historyStoryId)
          .delete();

      safePrint('✅ HISTORY: Story restaurado com sucesso');
    } catch (e) {
      safePrint('❌ HISTORY ERROR: Erro ao restaurar story: $e');
      rethrow;
    }
  }
}