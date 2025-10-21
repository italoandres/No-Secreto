import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para criar notificações de interesse com status "new" para teste
Future<void> createNewInterestNotifications() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🔧 Iniciando criação de notificações "new"...');
  
  try {
    // Buscar notificações "pending" para converter em "new"
    final pendingSnapshot = await firestore
        .collection('interest_notifications')
        .where('status', isEqualTo: 'pending')
        .limit(2)
        .get();
    
    print('📊 Notificações "pending" encontradas: ${pendingSnapshot.docs.length}');
    
    int updated = 0;
    
    for (var doc in pendingSnapshot.docs) {
      await doc.reference.update({'status': 'new'});
      
      final data = doc.data();
      print('✅ Notificação ${doc.id} → status: new');
      print('   De: ${data['fromUserName']} para: ${data['toUserId']}');
      updated++;
    }
    
    print('\n✅ Processo concluído!');
    print('📊 Notificações convertidas para "new": $updated');
    print('💡 Agora essas notificações devem pulsar!');
    
  } catch (e) {
    print('❌ Erro ao criar notificações "new": $e');
  }
}
