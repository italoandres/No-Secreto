import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para adicionar o campo lastSeen a todos os usuários existentes
class AddLastSeenToUsers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adiciona o campo lastSeen a todos os usuários que não têm
  static Future<void> addLastSeenToAllUsers() async {
    try {
      print('🔄 Iniciando atualização de lastSeen para todos os usuários...');

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
          print('✅ Adicionando lastSeen para usuário: ${userDoc.id}');
        } else {
          skipped++;
          print('⏭️ Usuário ${userDoc.id} já tem lastSeen');
        }
      }

      // Executa todas as atualizações
      if (updated > 0) {
        await batch.commit();
        print('🎉 Atualização concluída!');
        print('📊 Usuários atualizados: $updated');
        print('📊 Usuários ignorados: $skipped');
      } else {
        print('ℹ️ Nenhum usuário precisava de atualização');
      }
    } catch (e) {
      print('❌ Erro ao atualizar usuários: $e');
    }
  }

  /// Versão para executar em lote pequeno (para evitar timeout)
  static Future<void> addLastSeenToUsersBatch({int batchSize = 50}) async {
    try {
      print('🔄 Iniciando atualização em lotes de $batchSize usuários...');

      DocumentSnapshot? lastDoc;
      bool hasMore = true;
      int totalUpdated = 0;

      while (hasMore) {
        Query query = _firestore.collection('usuarios').limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final querySnapshot = await query.get();

        print('📋 Lote recebido: ${querySnapshot.docs.length} documentos');

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
              print('⚠️ Documento ${userDoc.id} sem dados');
              continue;
            }

            if (!userData.containsKey('lastSeen') ||
                userData['lastSeen'] == null) {
              batch.update(userDoc.reference, {
                'lastSeen': FieldValue.serverTimestamp(),
              });
              batchUpdated++;
              print('✅ Lote: Adicionando lastSeen para ${userDoc.id}');
            } else {
              print('⏭️ Usuário ${userDoc.id} já tem lastSeen');
            }
          } catch (e) {
            print('❌ Erro ao processar usuário ${userDoc.id}: $e');
          }
        }

        if (batchUpdated > 0) {
          try {
            await batch.commit();
            totalUpdated += batchUpdated;
            print('📦 Lote processado: $batchUpdated usuários atualizados');
          } catch (e) {
            print('❌ Erro ao commitar lote: $e');
          }
        } else {
          print('ℹ️ Nenhum usuário neste lote precisava de atualização');
        }

        lastDoc = querySnapshot.docs.last;

        // Pequena pausa entre lotes
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('🎉 Atualização em lotes concluída!');
      print('📊 Total de usuários atualizados: $totalUpdated');
    } catch (e, stackTrace) {
      print('❌ Erro ao atualizar usuários em lotes: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
