import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Script para forçar atualização do status de admin do deusepaimovement@gmail.com
/// 
/// COMO USAR:
/// 1. Importe este arquivo em alguma view (ex: fix_button_screen.dart)
/// 2. Chame: await fixAdminDeusePaiFinal();
/// 3. Aguarde a mensagem de sucesso
Future<void> fixAdminDeusePaiFinal() async {
  debugPrint('🔧 INICIANDO CORREÇÃO FINAL DO ADMIN DEUSEPAI');
  
  try {
    // Buscar usuário pelo email
    final querySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: 'deusepaimovement@gmail.com')
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      debugPrint('❌ Usuário deusepaimovement@gmail.com não encontrado!');
      return;
    }
    
    final userDoc = querySnapshot.docs.first;
    final userId = userDoc.id;
    final currentData = userDoc.data();
    
    debugPrint('📊 Dados atuais:');
    debugPrint('   - ID: $userId');
    debugPrint('   - Email: ${currentData['email']}');
    debugPrint('   - isAdmin atual: ${currentData['isAdmin']}');
    
    // Forçar atualização para admin = true
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .update({
      'isAdmin': true,
    });
    
    debugPrint('✅ STATUS DE ADMIN ATUALIZADO COM SUCESSO!');
    
    // Verificar se foi atualizado
    final updatedDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    
    final updatedData = updatedDoc.data();
    debugPrint('📊 Dados após atualização:');
    debugPrint('   - isAdmin: ${updatedData?['isAdmin']}');
    
    if (updatedData?['isAdmin'] == true) {
      debugPrint('🎉 SUCESSO! deusepaimovement@gmail.com agora é ADMIN!');
    } else {
      debugPrint('⚠️ Atualização não refletiu. Verifique as regras do Firestore.');
    }
    
  } catch (e) {
    debugPrint('❌ ERRO ao atualizar admin: $e');
  }
}
