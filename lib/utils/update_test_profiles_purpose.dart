import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enhanced_logger.dart';

/// Script para atualizar perfis de teste com o campo purpose
class UpdateTestProfilesPurpose {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atualiza perfis de teste adicionando o campo purpose
  static Future<void> updateProfiles() async {
    try {
      EnhancedLogger.info(
        'Updating test profiles with purpose field',
        tag: 'UPDATE_PROFILES',
      );

      final updates = {
        'test_maria_001': 'Relacionamento sério com propósito de casamento',
        'test_ana_002': 'Namoro cristão com intenção de casamento',
        'test_juliana_003': 'Conhecer pessoas com os mesmos valores para relacionamento sério',
        'test_beatriz_004': 'Relacionamento sério que leve ao casamento',
        'test_carolina_005': 'Encontrar um parceiro para construir uma família cristã',
        'test_fernanda_006': 'Namoro sério',
      };

      int updated = 0;
      for (final entry in updates.entries) {
        final userId = entry.key;
        final purpose = entry.value;

        final docRef = _firestore.collection('profiles').doc(userId);
        final doc = await docRef.get();

        if (doc.exists) {
          await docRef.update({'purpose': purpose});
          updated++;
          EnhancedLogger.info(
            'Profile updated',
            tag: 'UPDATE_PROFILES',
            data: {'userId': userId},
          );
        }
      }

      EnhancedLogger.success(
        'Test profiles updated successfully',
        tag: 'UPDATE_PROFILES',
        data: {'count': updated},
      );

      print('✅ $updated perfis atualizados com sucesso!');
      print('');
      print('Campo "purpose" adicionado aos perfis:');
      print('1. Maria Silva - Relacionamento sério com propósito de casamento');
      print('2. Ana Costa - Namoro cristão com intenção de casamento');
      print('3. Juliana Santos - Conhecer pessoas com os mesmos valores');
      print('4. Beatriz Oliveira - Relacionamento sério que leve ao casamento');
      print('5. Carolina Ferreira - Encontrar um parceiro para construir uma família');
      print('6. Fernanda Lima - Namoro sério');
      print('');
      print('Agora o campo Propósito deve aparecer nos cards! 🎉');
    } catch (e) {
      EnhancedLogger.error(
        'Failed to update test profiles',
        tag: 'UPDATE_PROFILES',
        error: e,
      );
      print('❌ Erro ao atualizar perfis de teste: $e');
    }
  }
}
