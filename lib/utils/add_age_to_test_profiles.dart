import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Script para adicionar idades aos perfis de teste
Future<void> addAgeToTestProfiles() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();
  
  print('🔧 Iniciando adição de idades aos perfis de teste...');
  
  try {
    // Buscar todos os usuários
    final usersSnapshot = await firestore.collection('usuarios').get();
    
    print('📊 Total de usuários encontrados: ${usersSnapshot.docs.length}');
    
    int updated = 0;
    int skipped = 0;
    
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final currentAge = data['idade'];
      
      // Se já tem idade, pular
      if (currentAge != null) {
        skipped++;
        continue;
      }
      
      // Gerar idade aleatória entre 18 e 35
      final age = 18 + random.nextInt(18); // 18 a 35
      
      await doc.reference.update({'idade': age});
      
      print('✅ Usuário ${doc.id} (${data['nome']}) → idade: $age');
      updated++;
    }
    
    print('\n✅ Processo concluído!');
    print('📊 Perfis atualizados: $updated');
    print('⏭️ Perfis pulados (já tinham idade): $skipped');
    
  } catch (e) {
    print('❌ Erro ao adicionar idades: $e');
  }
}
