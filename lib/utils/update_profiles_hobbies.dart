import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Script para adicionar hobbies aos perfis de teste existentes
class UpdateProfilesHobbies {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atualiza perfis de teste com hobbies
  static Future<void> updateProfiles() async {
    try {
      EnhancedLogger.info(
        'Updating test profiles with hobbies',
        tag: 'UPDATE_HOBBIES',
      );

      // Mapeamento de perfis e seus hobbies
      final profilesHobbies = {
        'test_maria_001': ['Música', 'Leitura', 'Voluntariado', 'Yoga'],
        'test_joao_002': ['Leitura', 'Cinema', 'Culinária'],
        'test_ana_003': ['Música', 'Dança', 'Voluntariado', 'Natureza'],
        'test_pedro_004': ['Fotografia', 'Viagens', 'Leitura'],
        'test_julia_005': [
          'Voluntariado',
          'Música',
          'Leitura',
          'Natureza',
          'Yoga'
        ],
        'test_lucas_006': ['Cinema', 'Culinária'],
      };

      int updated = 0;
      int notFound = 0;

      for (final entry in profilesHobbies.entries) {
        final userId = entry.key;
        final hobbies = entry.value;

        try {
          final profileRef = _firestore.collection('profiles').doc(userId);
          final profileDoc = await profileRef.get();

          if (profileDoc.exists) {
            await profileRef.update({
              'hobbies': hobbies,
            });

            EnhancedLogger.info(
              'Profile updated with hobbies',
              tag: 'UPDATE_HOBBIES',
              data: {'userId': userId, 'hobbies': hobbies},
            );

            print('✅ Perfil $userId atualizado com ${hobbies.length} hobbies');
            updated++;
          } else {
            print('⚠️ Perfil $userId não encontrado');
            notFound++;
          }
        } catch (e) {
          EnhancedLogger.error(
            'Error updating profile',
            tag: 'UPDATE_HOBBIES',
            error: e,
            data: {'userId': userId},
          );
          print('❌ Erro ao atualizar perfil $userId: $e');
        }
      }

      print('\n📊 Resumo:');
      print('   ✅ Atualizados: $updated');
      print('   ⚠️ Não encontrados: $notFound');

      EnhancedLogger.info(
        'Hobbies update completed',
        tag: 'UPDATE_HOBBIES',
        data: {'updated': updated, 'notFound': notFound},
      );
    } catch (e) {
      EnhancedLogger.error(
        'Error in hobbies update process',
        tag: 'UPDATE_HOBBIES',
        error: e,
      );
      print('❌ Erro no processo de atualização: $e');
      rethrow;
    }
  }
}
