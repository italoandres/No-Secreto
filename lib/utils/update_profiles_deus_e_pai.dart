import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para atualizar perfis de teste com campo isDeusEPaiMember
/// 
/// Este script adiciona o campo isDeusEPaiMember aos perfis de teste
/// que foram criados antes deste campo existir.
class UpdateProfilesDeusEPai {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atualiza todos os perfis de teste com isDeusEPaiMember
  static Future<void> updateAllTestProfiles() async {
    print('🔄 Iniciando atualização de perfis...');

    try {
      // Perfis que devem ter isDeusEPaiMember: true
      final profilesWithDeusEPai = [
        'ana.silva@teste.com',
        'mariana.costa@teste.com',
        'juliana.alves@teste.com',
      ];

      // Perfis que devem ter isDeusEPaiMember: false
      final profilesWithoutDeusEPai = [
        'carlos.santos@teste.com',
        'pedro.oliveira@teste.com',
        'lucas.ferreira@teste.com',
      ];

      int updated = 0;
      int errors = 0;

      // Atualizar perfis COM Deus é Pai
      for (final email in profilesWithDeusEPai) {
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final docId = querySnapshot.docs.first.id;
            await _firestore.collection('users').doc(docId).update({
              'isDeusEPaiMember': true,
            });
            print('✅ Atualizado: $email (isDeusEPaiMember: true)');
            updated++;
          } else {
            print('⚠️  Perfil não encontrado: $email');
          }
        } catch (e) {
          print('❌ Erro ao atualizar $email: $e');
          errors++;
        }
      }

      // Atualizar perfis SEM Deus é Pai
      for (final email in profilesWithoutDeusEPai) {
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final docId = querySnapshot.docs.first.id;
            await _firestore.collection('users').doc(docId).update({
              'isDeusEPaiMember': false,
            });
            print('✅ Atualizado: $email (isDeusEPaiMember: false)');
            updated++;
          } else {
            print('⚠️  Perfil não encontrado: $email');
          }
        } catch (e) {
          print('❌ Erro ao atualizar $email: $e');
          errors++;
        }
      }

      print('\n📊 Resumo:');
      print('   ✅ Perfis atualizados: $updated');
      print('   ❌ Erros: $errors');
      print('   📝 Total processado: ${profilesWithDeusEPai.length + profilesWithoutDeusEPai.length}');

      if (errors == 0) {
        print('\n🎉 Atualização concluída com sucesso!');
      } else {
        print('\n⚠️  Atualização concluída com alguns erros.');
      }
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  /// Verifica quais perfis têm ou não o campo isDeusEPaiMember
  static Future<void> checkProfiles() async {
    print('🔍 Verificando perfis...\n');

    try {
      final testEmails = [
        'ana.silva@teste.com',
        'carlos.santos@teste.com',
        'mariana.costa@teste.com',
        'pedro.oliveira@teste.com',
        'juliana.alves@teste.com',
        'lucas.ferreira@teste.com',
      ];

      for (final email in testEmails) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          final hasField = data.containsKey('isDeusEPaiMember');
          final value = data['isDeusEPaiMember'];

          if (hasField) {
            print('✅ $email: isDeusEPaiMember = $value');
          } else {
            print('❌ $email: Campo isDeusEPaiMember NÃO EXISTE');
          }
        } else {
          print('⚠️  $email: Perfil não encontrado');
        }
      }

      print('\n✅ Verificação concluída!');
    } catch (e) {
      print('❌ Erro ao verificar perfis: $e');
      rethrow;
    }
  }
}
