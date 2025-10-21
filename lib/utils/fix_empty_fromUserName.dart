import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para corrigir notificações de interesse com fromUserName vazio
/// 
/// Uso:
/// 1. Importe este arquivo onde precisar
/// 2. Chame: await fixEmptyFromUserName();
/// 3. Verifique os logs no console
Future<void> fixEmptyFromUserName() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🔧 [FIX] Iniciando correção de fromUserName vazio...');
  
  try {
    // Buscar TODAS as notificações (não podemos filtrar por string vazia diretamente)
    final notifications = await firestore
        .collection('interest_notifications')
        .get();
    
    print('📊 [FIX] Total de notificações encontradas: ${notifications.docs.length}');
    
    int fixed = 0;
    int skipped = 0;
    int errors = 0;
    
    for (var doc in notifications.docs) {
      try {
        final data = doc.data();
        final fromUserName = data['fromUserName'] as String?;
        final fromUserId = data['fromUserId'] as String?;
        
        // Pular se já tem nome ou não tem userId
        if (fromUserName != null && fromUserName.trim().isNotEmpty) {
          skipped++;
          continue;
        }
        
        if (fromUserId == null || fromUserId.isEmpty) {
          print('⚠️ [FIX] Notificação ${doc.id} sem fromUserId, pulando...');
          skipped++;
          continue;
        }
        
        print('🔍 [FIX] Corrigindo notificação ${doc.id}...');
        print('   fromUserId: $fromUserId');
        print('   fromUserName atual: "${fromUserName ?? ""}"');
        
        // Buscar nome do usuário no Firestore
        final userDoc = await firestore
            .collection('usuarios')
            .doc(fromUserId)
            .get();
        
        if (!userDoc.exists) {
          print('❌ [FIX] Usuário não encontrado: $fromUserId');
          errors++;
          continue;
        }
        
        final userData = userDoc.data()!;
        final userName = userData['nome'] ?? userData['username'] ?? 'Usuário';
        
        if (userName.isEmpty || userName == 'Usuário') {
          print('⚠️ [FIX] Nome do usuário está vazio ou genérico: "$userName"');
        }
        
        // Atualizar notificação
        await doc.reference.update({
          'fromUserName': userName,
        });
        
        print('✅ [FIX] Notificação ${doc.id} atualizada!');
        print('   Novo fromUserName: "$userName"');
        fixed++;
        
      } catch (e) {
        print('❌ [FIX] Erro ao processar notificação ${doc.id}: $e');
        errors++;
      }
    }
    
    print('');
    print('🎉 [FIX] Correção concluída!');
    print('   ✅ Corrigidas: $fixed');
    print('   ⏭️ Puladas: $skipped');
    print('   ❌ Erros: $errors');
    
  } catch (e) {
    print('❌ [FIX] Erro fatal: $e');
    rethrow;
  }
}

/// Corrigir uma notificação específica por ID
Future<void> fixSpecificNotification(String notificationId) async {
  final firestore = FirebaseFirestore.instance;
  
  print('🔧 [FIX] Corrigindo notificação específica: $notificationId');
  
  try {
    final doc = await firestore
        .collection('interest_notifications')
        .doc(notificationId)
        .get();
    
    if (!doc.exists) {
      print('❌ [FIX] Notificação não encontrada: $notificationId');
      return;
    }
    
    final data = doc.data()!;
    final fromUserId = data['fromUserId'] as String?;
    
    if (fromUserId == null || fromUserId.isEmpty) {
      print('❌ [FIX] Notificação sem fromUserId');
      return;
    }
    
    // Buscar nome do usuário
    final userDoc = await firestore
        .collection('usuarios')
        .doc(fromUserId)
        .get();
    
    if (!userDoc.exists) {
      print('❌ [FIX] Usuário não encontrado: $fromUserId');
      return;
    }
    
    final userData = userDoc.data()!;
    final userName = userData['nome'] ?? userData['username'] ?? 'Usuário';
    
    // Atualizar notificação
    await doc.reference.update({
      'fromUserName': userName,
    });
    
    print('✅ [FIX] Notificação atualizada!');
    print('   ID: $notificationId');
    print('   fromUserId: $fromUserId');
    print('   Novo fromUserName: "$userName"');
    
  } catch (e) {
    print('❌ [FIX] Erro: $e');
    rethrow;
  }
}
