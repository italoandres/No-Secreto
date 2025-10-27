import 'package:cloud_firestore/cloud_firestore.dart';
import 'debug_utils.dart';

/// Script para adicionar o campo lastSeen a todos os usuários existentes
class AddLastSeenToUsers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adiciona o campo lastSeen a todos os usuários que não têm
  static Future<void> addLastSeenToAllUsers() async {
    try {
      safePrint('🔄 Iniciando atualização de lastSeen para todos os usuários...');

      // Buscar todos os usuários
      final usersQuery = await _firestore.collection('usuarios').get();

      int updated = 0;
      int skipped = 0;

      final batch = _firestore.batch();

      for (final userDoc in usersQuery.docs) {
        final userData = userDoc.data();

        // Verifica se já tem o campo lastSeen
        if (!userData.containsKey('lastSeen') || userData['lastSeen'] == null) {
          // Adiciona lastSeen como agora (para usuários existentes)
          batch.update(userDoc.reference, {
            'lastSeen': FieldValue.serverTimestamp(),
          });
          updated++;
          safePrint('✅ Adicionando lastSeen para usuário: ${userDoc.id}');
        } else {
          skipped++;
          safePrint('⏭️ Usuário ${userDoc.id} já tem lastSeen');
        }
      }

      // Executa todas as atualizações
      if (updated > 0) {
        await batch.commit();
        safePrint('🎉 Atualização concluída!');
        safePrint('📊 Usuários atualizados: $updated');
        safePrint('📊 Usuários ignorados: $skipped');
      } else {
        safePrint('ℹ️ Nenhum usuário precisava de atualização');
      }
    } catch (e) {
      safePrint('❌ Erro ao atualizar usuários: $e');
    }
  }

  /// Versão para executar em lote pequeno (para evitar timeout)
  static Future<void> addLastSeenToUsersBatch({int batchSize = 50}) async {
    try {
      safePrint('🔄 Iniciando atualização em lotes de $batchSize usuários...');

      DocumentSnapshot? lastDoc;
      bool hasMore = true;
      int totalUpdated = 0;

      while (hasMore) {
        Query query = _firestore.collection('usuarios').limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final querySnapshot = await query.get();

        safePrint('📋 Lote recebido: ${querySnapshot.docs.length} documentos');

        if (querySnapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        int batchUpdated = 0;

        for (final userDoc in querySnapshot.docs) {
          try {
            final userData = userDoc.data() as Map<String, dynamic>?;

            if (userData == null) {
              safePrint('⚠️ Documento ${userDoc.id} sem dados');
              continue;
            }

            if (!userData.containsKey('lastSeen') ||
                userData['lastSeen'] == null) {
              batch.update(userDoc.reference, {
                'lastSeen': FieldValue.serverTimestamp(),
              });
              batchUpdated++;
              safePrint('✅ Lote: Adicionando lastSeen para ${userDoc.id}');
            } else {
              safePrint('⏭️ Usuário ${userDoc.id} já tem lastSeen');
            }
          } catch (e) {
            safePrint('❌ Erro ao processar usuário ${userDoc.id}: $e');
          }
        }

        if (batchUpdated > 0) {
          try {
            await batch.commit();
            totalUpdated += batchUpdated;
            safePrint('📦 Lote processado: $batchUpdated usuários atualizados');
          } catch (e) {
            safePrint('❌ Erro ao commitar lote: $e');
          }
        } else {
          safePrint('ℹ️ Nenhum usuário neste lote precisava de atualização');
        }

        lastDoc = querySnapshot.docs.last;

        // Pequena pausa entre lotes
        await Future.delayed(const Duration(milliseconds: 500));
      }

      safePrint('🎉 Atualização em lotes concluída!');
      safePrint('📊 Total de usuários atualizados: $totalUpdated');
    } catch (e, stackTrace) {
      safePrint('❌ Erro ao atualizar usuários em lotes: $e');
      safePrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
